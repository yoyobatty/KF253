//-----------------------------------------------------------
//
//-----------------------------------------------------------
class KFSquad extends InvasionSquad;

// Let's put some hacks in here to account for how Bots judge Specimen threat priorities.

function float AssessThreat( Bot B, Pawn NewThreat, bool bThreatVisible )
{
	local float ThreatValue;

	if ( KFMonster(NewThreat) != none )
		ThreatValue += 0.25;
	if (KFMonster(NewThreat).bCloaked)
		ThreatValue += 5.f;
	if (KFMonster(NewThreat).bDecapitated)
		ThreatValue -= 0.10;
	if( VSize(B.Pawn.Location-NewThreat.Location)<400.f ) // Consider close range zombies as much bigger threat.
		ThreatValue += 10.f;
	if ( KFMonster(NewThreat).bBoss )
		ThreatValue += 15.f;
	Return Super.AssessThreat(B,NewThreat,bThreatVisible);
}

function bool ShouldDeferTo(Controller C)
{
	return true;
}

function bool AssignSquadResponsibility(Bot B)
{
	// set new defense script
	if ( (GetOrders() == 'Defend') && !B.Pawn.bStationary )
		SetDefenseScriptFor(B);

	if ( bAddTransientCosts )
		AddTransientCosts(B,1);
	// check for major game objective responsibility
	if ( CheckSquadObjectives(B) )
		return true;

	if ( B.Enemy == None && !B.Pawn.bStationary )
	{
		// suggest inventory hunt
		if ( B.FindInventoryGoal(0) )
		{
			B.SetAttractionState();
			return true;
		}

		// roam around level?
		if ( ((B == SquadLeader) && bRoamingSquad) || (GetOrders() == 'Freelance') || (B.Pawn.Anchor == None) )
			return B.FindRoamDest();
	}
	return false;
}

function bool CheckSquadObjectives(Bot B)
{
	local Actor DesiredPosition;
	local bool bInPosition;

	// might have gotten out of vehicle and been killed
	if ( B.Pawn == None )
		return true;

	//Get a weapon if no scary enemies, no enemies around and I need a weapon
	if ( !KFInvasionBot(B).EnemyReallyScary() && !KFInvasionBot(B).ManyEnemiesAround(5, B.Pawn.Location) && B.NeedWeapon() && B.FindInventoryGoal(0) )
	{
		B.GoalString = "Need weapon or ammo";
		B.SetAttractionState();
		//Set me as the squad leader so others follow me to get weapons too
		//SquadLeader = B;
		return true;
	}		

	if ( (PlayerController(SquadLeader) != None) && (SquadLeader.Pawn != None) )
	{
		if ( HoldSpot(B.GoalScript) == None )
		{
			// attack objective if close by
			if ( OverrideFollowPlayer(B) )
				return true;

			// follow human leader
			return TellBotToFollow(B,SquadLeader);
		}
		// hold position as ordered (position specified by goalscript)
	}

	if ( B.GoalScript != None )
	{
		DesiredPosition = B.GoalScript.GetMoveTarget();
		bInPosition = (B.Pawn == DesiredPosition) || B.Pawn.ReachedDestination(DesiredPosition);
		if ( bInPosition && B.GoalScript.bRoamingScript && (GetOrders() == 'Freelance') )
			return false;
		if ( !bInPosition )
			B.ClearScript();
	}
	else if ( SquadObjective == None )
		return TellBotToFollow(B,SquadLeader);
	else if ( GetOrders() == 'Freelance' )
		return false;
	else
	{
		if ( SquadObjective.DefenderTeamIndex != Team.TeamIndex )
		{
			if ( SquadObjective.bDisabled || !SquadObjective.bActive )
			{
				B.GoalString = "Objective already disabled";
				return false;
			}
			B.GoalString = "Disable Objective "$SquadObjective;
			return SquadObjective.TellBotHowToDisable(B);
		}
		DesiredPosition = SquadObjective;
		bInPosition = ( (VSize(SquadObjective.Location - B.Pawn.Location) < 1200) && B.LineOfSightTo(SquadObjective) );
	}

	if ( B.Enemy != None )
	{
		if ( (B.GoalScript != None) && B.GoalScript.bRoamingScript )
		{
			B.GoalString = "Attack enemy freely";
			return false;
		}
		if ( B.LostContact(5) )
			B.LoseEnemy();
		if ( B.Enemy != None )
		{
			if ( B.EnemyVisible() || (Level.TimeSeconds - B.LastSeenTime < 3 && (SquadObjective == None || !SquadObjective.TeamLink(Team.TeamIndex))) )
			{
				B.FightEnemy(false, 0);
				return true;
			}
		}
	}
	if ( bInPosition )
	{
		B.GoalString = "Near "$DesiredPosition;
		if ( !B.bInitLifeMessage )
		{
			B.bInitLifeMessage = true;
			B.SendMessage(None, 'OTHER', B.GetMessageIndex('INPOSITION'), 10, 'TEAM');
		}

		if ( B.GoalScript != None )
			B.GoalScript.TakeOver(B.Pawn);
		else
		{
			if (DestroyableObjective(SquadObjective) != None && DestroyableObjective(SquadObjective).TellBotHowToHeal(B))
				return true;

			if (B.Enemy != None && (B.EnemyVisible() || Level.TimeSeconds - B.LastSeenTime < 3))
			{
				B.FightEnemy(false, 0);
				return true;
			}

			B.WanderOrCamp(true);
		}
		return true;
	}

	if (B.Pawn.bStationary)
		return false;

	B.GoalString = "Follow path to "$DesiredPosition;
	B.FindBestPathToward(DesiredPosition,false,true);
	if ( B.StartMoveToward(DesiredPosition) )
		return true;

	if ( (B.GoalScript != None) && (DesiredPosition == B.GoalScript) )
	{
		if ( (B.Pawn.Anchor != None) && B.Pawn.ReachedDestination(B.Pawn.Anchor) )
			log(B.PlayerReplicationInfo.PlayerName$" had no path to "$B.GoalScript$" from "$B.Pawn.Anchor);
		else
			log(B.PlayerReplicationInfo.PlayerName$" had no path to "$B.GoalScript);

		B.GoalScript.bAvoid = true;
		B.FreeScript();
		if ( (SquadObjective != None) && (VSize(B.Pawn.Location - SquadObjective.Location) > 1200) )
		{
			B.FindBestPathToward(SquadObjective,false,true);
			if ( B.StartMoveToward(SquadObjective) )
				return true;
		}
	}
	return false;
}

function bool TellBotToFollow(Bot B, Controller C)
{
	local Pawn Leader;
	local GameObjective O, Best;
	local float NewDist, BestDist;

	if ( (C == None) || C.bDeleteMe )
	{
		PickNewLeader();
		C = SquadLeader;
	}

	if ( B == C )
		return false;

	B.GoalString = "Follow Leader";
	Leader = C.Pawn;
	if ( Leader == None )
		return false;

	if ( CloseToLeader(B.Pawn) )
	{
		if ( !B.bInitLifeMessage )
		{
			B.bInitLifeMessage = true;
		  	B.SendMessage(SquadLeader.PlayerReplicationInfo, 'OTHER', B.GetMessageIndex('GOTYOURBACK'), 10, 'TEAM');
		}
		if ( B.Enemy == None )
		{
			// look for destroyable objective
			for ( O=Team.AI.Objectives; O!=None; O=O.NextObjective )
			{
				if ( !O.bDisabled && (DestroyableObjective(O) != None)
					&& ((Best == None) || (Best.DefensePriority < O.DefensePriority)) )
				{
					NewDist = VSize(B.Pawn.Location - O.Location);
					if ( ((Best == None) || (NewDist < BestDist)) && B.LineOfSightTo(O) )
					{
						Best = O;
						BestDist = NewDist;
					}
				}
			}
			if ( Best != None )
			{
				if (Best.DefenderTeamIndex != Team.TeamIndex)
				{
					if (Best.TellBotHowToDisable(B))
						return true;
				}
				else if (BestDist < 1600 && DestroyableObjective(Best).TellBotHowToHeal(B))
				return true;
			}

			if ( B.FindInventoryGoal(0.0004) )
			{
				B.SetAttractionState();
				return true;
			}
			B.WanderOrCamp(true);
			return true;
		}
		else if ( (B.Pawn.Weapon != None) && (B.Pawn.Weapon.FocusOnLeader(false) || B.Pawn.Weapon.bMeleeWeapon) )
		{
			B.FightEnemy(false,0);
			return true;
		}
		return false;
	}
	else if ( B.SetRouteToGoal(Leader) )
		return true;
	else
	{
		B.GoalString = "Roaming toward leader";
		if (B.FindRoamDest())
			return true;
		B.RouteGoal = None;
		B.GotoState('Roaming');
		return true;
	}
}

/* CloseToLeader()
Called by bot to see if his pawn is in an acceptable position relative to the squad leader
*/
function bool CloseToLeader(Pawn P)
{
    local float dist, distZ, FormSize;

    if ( (P == None) || (SquadLeader.Pawn == None) )
        return true;

    // for certain games, have bots wait for leader for a while
    if ( (P.Base != None) && (SquadLeader.Pawn.Base != None) && (SquadLeader.Pawn.Base != P.Base) )
        return false;

    if ( Mover(P.Base) != None && Mover(SquadLeader.Pawn.Base) == None )
        return false;
    if ( Mover(SquadLeader.Pawn.Base) != None && Mover(P.Base) == None )
        return false;

    dist = VSize(P.Location - SquadLeader.Pawn.Location);
	distZ = P.Location.Z - SquadLeader.Pawn.Location.Z;
    FormSize = GetRestingFormation().FormationSize;

    // Well within formation range — always considered close
    if ( dist < FormSize * 0.75 && distZ < 150 )
        return true;

    // Beyond formation range — not close
    if ( dist > FormSize )
        return false;

    // Outer 25% of formation range: only fail if leader is running AWAY from us.
    // This prevents bots near the edge from being constantly recalled just because
    // the player is sprinting around nearby.
    if ( PhysicsVolume.bWaterVolume )
    {
        if ( VSize(SquadLeader.Pawn.Velocity) > 0 )
            return false;
    }
    else if ( VSize(SquadLeader.Pawn.Velocity) > SquadLeader.Pawn.WalkingPct * SquadLeader.Pawn.GroundSpeed )
    {
        if ( (Normal(SquadLeader.Pawn.Velocity) dot Normal(SquadLeader.Pawn.Location - P.Location)) > 0.5 )
            return false;
    }

	return ( P.Controller.LineOfSightTo(SquadLeader.Pawn) );
}

function bool SetEnemy( Bot B, Pawn NewEnemy )
{
	local Bot M;
	local bool bResult;

	if ( (NewEnemy == B.Enemy) || !ValidEnemy(NewEnemy) )
		return false;

	AddEnemy(NewEnemy);

	// reassess squad member enemies
	if ( MustKeepEnemy(NewEnemy) )
	{
		for	( M=SquadMembers; M!=None; M=M.NextSquadMember )
		{
			if ( (M != B) && (M.Enemy != NewEnemy) )
				FindNewEnemyFor(M,(M.Enemy !=None) && M.EnemyVisible());
		}
	}

	bResult = CheckSwapEnemy(B, NewEnemy);
	if ( bResult && (B.Enemy == NewEnemy) )
		B.AcquireTime = Level.TimeSeconds;
	return bResult;
}

function bool CheckSwapEnemy(Bot B, Pawn NewEnemy)
{
	local bool bSeeOld, bSeeNew;
	local float OldThreat,NewThreat;

	bSeeOld = B.EnemyVisible();

	if ( B.Pawn == None )
		return true;

	if(B.Enemy == NewEnemy)
		return false;

	if ( B.Enemy != None )
	{
		if ( (B.Enemy.Health < 0) || (B.Enemy.Controller == None) )
		{
			B.Enemy = None;
			//BestEnemy = None;
			//OldThreat = 0;
		}
		else
		{
			if ( ModifyThreat(0,B.Enemy,bSeeOld,B) > 5 )
				return false;
			OldThreat = AssessThreat(B,B.Enemy,bSeeOld);
		}
	}

	bSeeNew = B.LineOfSightTo(NewEnemy);

	NewThreat = AssessThreat(B,NewEnemy,bSeeNew);

	if ( NewThreat > OldThreat )
	{
		B.Enemy = NewEnemy;
		B.EnemyChanged(bSeeNew);
		return true;
	}
	return false;
}

function NotifyKilled(Controller Killer, Controller Killed, pawn KilledPawn)
{
	local Bot B;
	local int i;
	local Monster P;

	if ( Killed == None )
		return;
		
	// if teammate killed, no need to update enemy list
	if ( (Team != None) && (Killed.PlayerReplicationInfo != None)
		&& (Killed.PlayerReplicationInfo.Team == Team) )
	{
		if ( IsOnSquad(Killed) )
		{
			if(SquadLeader == Killed)
				PickNewLeader();
			for	( B=SquadMembers; B!=None; B=B.NextSquadMember )
				if ( (B != Killed) && (B.Pawn != None) )
				{
					B.SendMessage(None, 'OTHER', B.GetMessageIndex('MANDOWN'), 4, 'TEAM'); 
					break;
				}
		}
		return;
	}
	RemoveEnemy(KilledPawn);

	B = Bot(Killer);
	if ( (B != None) && (B.Squad == self) && (B.Enemy == None) && (B.Pawn != None) )
	{
		// if no enemies left, area secure
		for ( i=0; i<8; i++ )
			if ( Enemies[i] != None )
				return;
		IncomingWave = 0;
		ForEach DynamicActors(class'Monster',P)
			if ( (P.Health > 0) && VSize(B.Pawn.Location - P.Location) < 3000 )
				return;
		B.SendMessage(None, 'OTHER', 11, 12, 'TEAM');
	}
}

function PickNewLeader()
{
	local Bot B;

	// pick a leader that isn't out of the game or in a vehicle turret and can see the old leader
	for ( B=SquadMembers; B!=None; B=B.NextSquadMember )
		if ( !B.PlayerReplicationInfo.bOutOfLives && (B.Pawn == None || !B.Pawn.bStationary || B.Pawn.GetVehicleBase() == None || !B.LineOfSightTo(SquadLeader.Pawn)) )
			break;

	if ( B == None )
	{
		for ( B=SquadMembers; B!=None; B=B.NextSquadMember )
			if ( !B.PlayerReplicationInfo.bOutOfLives )
				break;
	}
		
	if ( SquadLeader != B )
	{
		SquadLeader = B;
		if ( SquadLeader == None )
			LeaderPRI = None;
		else
			LeaderPRI = TeamPlayerReplicationInfo(SquadLeader.PlayerReplicationInfo);
		NetUpdateTime = Level.TimeSeconds - 1;
	}
}

defaultproperties
{
	MaxSquadSize=32
	bRoamingSquad=False
	RestingFormationClass=Class'KFMod.KFRestingFormation'
}
