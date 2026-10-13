//-----------------------------------------------------------
//
//-----------------------------------------------------------
class KFSquad extends InvasionSquad;

function float AssessThreat( Bot B, Pawn NewThreat, bool bThreatVisible )
{
	local float ThreatValue, NewStrength, Dist;
	local KFMonster KFM;

	NewStrength = B.RelativeStrength(NewThreat);
	ThreatValue = FClamp(NewStrength, 0, 1);
	Dist = VSize(NewThreat.Location - B.Pawn.Location);
	if ( Dist < 2000 )
	{
		ThreatValue += 0.2;
		if ( Dist < 1500 )
			ThreatValue += 0.2;
		if ( Dist < 1000 )
			ThreatValue += 0.2;
		if ( Dist < 500 )
			ThreatValue += 0.2;
	}

	if ( bThreatVisible )
		ThreatValue += 1;
	if ( (NewThreat != B.Enemy) && (B.Enemy != None) )
	{
		if ( !bThreatVisible )
			ThreatValue -= 5;
		else if ( Level.TimeSeconds - B.LastSeenTime > 2 )
			ThreatValue += 1;
		if ( Dist > 0.7 * VSize(B.Enemy.Location - B.Pawn.Location) )
			ThreatValue -= 0.25;
		ThreatValue -= 0.2;

		if ( B.IsHunting() && (NewStrength < 0.2)
			&& (Level.TimeSeconds - FMax(B.LastSeenTime,B.AcquireTime) < 2.5) )
			ThreatValue -= 0.3;
	}

	KFM = KFMonster(NewThreat);
	if ( KFM != None )
	{
		if ( KFM.bCloaked )
			ThreatValue += 0.2f;
		if ( KFM.bDecapitated )
			ThreatValue -= 0.1;
		if ( KFM.bBoss )
			ThreatValue += 0.4f;
	}

	ThreatValue = ModifyThreat(ThreatValue, NewThreat, bThreatVisible, B);
	return ThreatValue;
}

function bool ShouldDeferTo(Controller C)
{
	return true;
}

function bool ClearPathFor(Controller C)
{
	local Bot B;
	local vector Dir, MoveDir;
	local float Dist;
	local bool bHasVelocity;

	if ( C.Pawn == None )
		return false;

	bHasVelocity = VSize(C.Pawn.Velocity) > 10.0;
	if ( bHasVelocity )
		MoveDir = Normal(C.Pawn.Velocity);

	// First pass: idle bots (no enemy) - safe to displace without interrupting combat
	for ( B=SquadMembers; B!=None; B=B.NextSquadMember )
	{
		if ( B == C || B.Pawn == None || B.Enemy != None )
			continue;
		Dir = B.Pawn.Location - C.Pawn.Location;
		if ( Abs(Dir.Z) >= B.Pawn.CollisionHeight + C.Pawn.CollisionHeight )
			continue;
		Dir.Z = 0;
		Dist = VSize(Dir);
		if ( Dist >= 8.0 * B.Pawn.CollisionRadius )
			continue;
		// When C is moving, skip bots that aren't roughly ahead in its path
		if ( bHasVelocity && Dist > C.Pawn.CollisionRadius * 2.0 && (Normal(Dir) Dot MoveDir) < 0.3 )
			continue;
		B.ClearPathFor(C);
	}

	// Second pass: bots in combat that are still in the way
	for ( B=SquadMembers; B!=None; B=B.NextSquadMember )
	{
		if ( B == C || B.Pawn == None || B.Enemy == None )
			continue;
		Dir = B.Pawn.Location - C.Pawn.Location;
		if ( Abs(Dir.Z) >= B.Pawn.CollisionHeight + C.Pawn.CollisionHeight )
			continue;
		Dir.Z = 0;
		Dist = VSize(Dir);
		if ( Dist >= 8.0 * B.Pawn.CollisionRadius )
			continue;
		if ( bHasVelocity && Dist > C.Pawn.CollisionRadius * 2.0 && (Normal(Dir) Dot MoveDir) < 0.3 )
			continue;
		B.ClearPathFor(C);
		// Fallback: Bot.ClearPathFor leaves planted combat bots untouched; wander them away from C.
		if ( B.Stopped() && !B.Pawn.bStationary )
			B.DirectedWander(Normal(Dir));
	}

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
			B.GoalString = "Hunting for inventory, no objectives or enemies";
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
	if ( KFInvasionBot(B) != None && KFInvasionBot(B).NextPickupSearchTime < Level.TimeSeconds
		&& !KFInvasionBot(B).EnemyReallyScary() && !KFInvasionBot(B).ManyEnemiesAround(5, B.Pawn.Location)
		&& B.NeedWeapon() && B.FindInventoryGoal(0) )
	{
		B.GoalString = "Need weapon or ammo";
		KFInvasionBot(B).NextPickupSearchTime = Level.TimeSeconds + 8.0;
		B.SetAttractionState();
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

	if ( (C == None) || (C.Pawn == None) )
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

			if ( KFInvasionBot(B) != None && KFInvasionBot(B).NextPickupSearchTime < Level.TimeSeconds
				&& !KFInvasionBot(B).EnemyReallyScary() && !KFInvasionBot(B).ManyEnemiesAround(5, B.Pawn.Location)
				&& B.FindInventoryGoal(0.0004) )
			{
				B.GoalString = "Going for inventory near leader";
				KFInvasionBot(B).NextPickupSearchTime = Level.TimeSeconds + 12.0;
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
	distZ = Abs(P.Location.Z - SquadLeader.Pawn.Location.Z);
    FormSize = GetRestingFormation().FormationSize;

    if ( dist > FormSize )
        return false;

    if ( distZ > 150 )
        return false;

    if ( dist < FormSize * 0.75 )
        return P.Controller.LineOfSightTo(SquadLeader.Pawn);

    if ( VSize(SquadLeader.Pawn.Velocity) > SquadLeader.Pawn.WalkingPct * SquadLeader.Pawn.GroundSpeed )
        return false;

    return P.Controller.LineOfSightTo(SquadLeader.Pawn);
}

/* LostEnemy()
Bot lost track of enemy.  Change enemy for this bot, clear from list if no one can see it
*/
function bool LostEnemy(Bot B)
{
	local pawn Lost;
	local bool bFound;
	local Bot M;

	if ( (B.Enemy.Health <= 0) || (B.Enemy.Controller == None) )
	{
		RemoveEnemy(B.Enemy);
		return true;
	}

	if ( MustKeepEnemy(B.Enemy) )
		return false;
	Lost = B.Enemy;
	B.Enemy = None;

	for	( M=SquadMembers; M!=None; M=M.NextSquadMember )
		if ( (M != B) && (M.Enemy == Lost) && !M.LostContact(5) )
		{
			bFound = true;
			break;
		}

	if ( bFound )
		B.Enemy = Lost;
	else
	{
		RemoveEnemy(Lost);
		FindNewEnemyFor(B,false);
	}
	return (B.Enemy != Lost);
}

function bool FindNewEnemyFor(Bot B, bool bSeeEnemy)
{
	local int i;
	local Pawn BestEnemy, OldEnemy;
	local bool bSeeNew;
	local float BestThreat,NewThreat;

	if ( B==None || B.Pawn == None )
		return false;
	if ( (B.Enemy != None) && MustKeepEnemy(B.Enemy) && B.EnemyVisible() )
		return false;

	BestEnemy = B.Enemy;
	OldEnemy = B.Enemy;
	if ( BestEnemy != None )
	{
		if ( (BestEnemy.Health <= 0) || (BestEnemy.Controller == None) )
		{
			B.Enemy = None;
			BestEnemy = None;
		}
		else
		{
			if ( ModifyThreat(0,BestEnemy,bSeeEnemy,B) > 5 )
				return false;
			BestThreat = AssessThreat(B,BestEnemy,bSeeEnemy);
		}
	}
	for ( i=0; i<ArrayCount(Enemies); i++ )
	{
		if ( (Enemies[i] != None) && (Enemies[i].Health > 0) && (Enemies[i].Controller != None) )
		{
			if ( BestEnemy == None )
			{
				BestEnemy = Enemies[i];
				bSeeEnemy = B.CanSee(Enemies[i]);
				BestThreat = AssessThreat(B,BestEnemy,bSeeEnemy);
			}
			else if ( Enemies[i] != BestEnemy )
			{
				if ( VSize(Enemies[i].Location - B.Pawn.Location) < 1500 )
					bSeeNew = B.LineOfSightTo(Enemies[i]);
				else
					bSeeNew = B.CanSee(Enemies[i]);	// only if looking at him
				NewThreat = AssessThreat(B,Enemies[i],bSeeNew);
				if ( NewThreat > BestThreat )
				{
					BestEnemy = Enemies[i];
					BestThreat = NewThreat;
					bSeeEnemy = bSeeNew;
				}
			}
		}
		else
			Enemies[i] = None;
	}
	B.Enemy = BestEnemy;
	if ( (B.Enemy != OldEnemy) && (B.Enemy != None) )
	{
		B.EnemyChanged(bSeeEnemy);
		return true;
	}
	return false;
}

function bool SetEnemy( Bot B, Pawn NewEnemy )
{
	local Bot M;
	local bool bResult;

	if ( (NewEnemy == B.Enemy) || !ValidEnemy(NewEnemy) )
		return false;

	// add new enemy to enemy list - ignore if already there, still reassess B
	AddEnemy(NewEnemy);

	// reassess squad member enemies
	if ( MustKeepEnemy(NewEnemy) )
	{
		for ( M=SquadMembers; M!=None; M=M.NextSquadMember )
		{
			if ( (M != B) && (M.Enemy != NewEnemy) )
				FindNewEnemyFor(M,(M.Enemy != None) && M.EnemyVisible());
		}
	}
	bResult = FindNewEnemyFor(B,(B.Enemy != None) && B.EnemyVisible());
	if ( bResult && (B.Enemy == NewEnemy) )
		B.AcquireTime = Level.TimeSeconds;
	return bResult;
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
		if ( !B.PlayerReplicationInfo.bOutOfLives && (B.Pawn != None || !B.Pawn.bStationary || B.Pawn.GetVehicleBase() == None || B.LineOfSightTo(SquadLeader.Pawn)) )
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

function SetFreelanceScriptFor(Bot B)
{
	B.FreeScript();
}

defaultproperties
{
	MaxSquadSize=32
	bRoamingSquad=False
	RestingFormationClass=Class'KFMod.KFRestingFormation'
}
