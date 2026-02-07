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
<<<<<<< HEAD
		ThreatValue += 10;
	if (KFMonster(NewThreat).bDecapitated)
		ThreatValue -= 0.10;
	if( VSize(B.Pawn.Location-NewThreat.Location)<400 ) // Consider close range zombies as much bigger threat.
		ThreatValue += 15;
	Return Super.AssessThreat(B,NewThreat,bThreatVisible);
}

// gibber - the squadAI version is a monster. Lets lighten it for KF
function bool CheckSquadObjectives(Bot B)
{
	B.Skill = 9; // Best skill.
=======
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
		if ( ((B == SquadLeader) && bRoamingSquad) || (GetOrders() == 'Freelance') )
			return B.FindRoamDest();
	}
	return false;
}

function bool CheckSquadObjectives(Bot B)
{
	local Actor DesiredPosition;
	local bool bInPosition;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	// might have gotten out of vehicle and been killed
	if ( B.Pawn == None )
		return true;

<<<<<<< HEAD
	if( !bFreelance && Team!=None && Team.AI!=None )
		Team.AI.PutOnFreelance(B);
	if ( B.Enemy != None )
	{
=======
	if ( !KFInvasionBot(B).EnemyReallyScary() && !KFInvasionBot(B).ManyEnemiesAround(4) && B.NeedWeapon() && B.FindInventoryGoal(0) )
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		if ( B.LostContact(5) )
			B.LoseEnemy();
		if ( B.Enemy != None )
		{
<<<<<<< HEAD
			if ( B.EnemyVisible() || (Level.TimeSeconds - B.LastSeenTime < 3) )
=======
			if ( B.EnemyVisible() || (Level.TimeSeconds - B.LastSeenTime < 3 && (SquadObjective == None || !SquadObjective.TeamLink(Team.TeamIndex))) )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
			{
				B.FightEnemy(false, 0);
				return true;
			}
		}
	}
<<<<<<< HEAD

	return false;
}

=======
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

//So bots stop trying to follow players when they are charging
function bool TellBotToFollow(Bot B, Controller C)
{
    if( B == None || B.Pawn == None )
        return false;

    if( (B.IsInState('Charging') || B.IsInState('Hunting')) && B.Pawn.Weapon.AIRating >= 0.4 ) //This will work with bats/axe but not knife
        return false;

	//KFInvasionBot(B).SendChatMsg("Following leader: "$C.PlayerReplicationInfo.PlayerName);

    return Super.TellBotToFollow(B, C);
}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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

<<<<<<< HEAD
defaultproperties
{
=======
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
		NetUpdateTime = Level.Timeseconds - 1;
	}
}

defaultproperties
{
	MaxSquadSize=32
	bRoamingSquad=False
	RestingFormationClass=Class'KFMod.KFRestingFormation'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
