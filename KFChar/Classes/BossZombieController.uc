//-----------------------------------------------------------
//
//-----------------------------------------------------------
class BossZombieController extends KFMonsterController;

var NavigationPoint HidingSpots;
var NavigationPoint MidGoals[2];
var byte ReachOffset;
var Actor OldPathsCheck[3];

function TimedFireWeaponAtEnemy()
{
	if ( (Enemy == None) || FireWeaponAt(Enemy) )
		SetCombatTimer();
	else
		SetTimer(0.01, True);
}
state ZombieCharge
{
	function bool StrafeFromDamage(float Damage, class<DamageType> DamageType, bool bFindDest)
	{
		return false;
	}

	// I suspect this function causes bloats to get confused
	function bool TryStrafe(vector sideDir)
	{
		return false;
	}

	function Timer()
	{
		Disable('NotifyBump');
		Target = Enemy;
		TimedFireWeaponAtEnemy();
	}

WaitForAnim:

	if ( Monster(Pawn).bShotAnim )
	{
		Goto('Moving');
	}
	if ( !FindBestPathToward(Enemy, false,true) )
		GotoState('ZombieRestFormation');
Moving:
	MoveToward(Enemy);
	WhatToDoNext(17);
	if ( bSoaking )
		SoakStop("STUCK IN CHARGING!");
}

State RunSomewhere
{
Ignores HearNoise,DamageAttitudeTo,Tick,EnemyChanged,Startle,WaitForMover;

	function BeginState()
	{
		HidingSpots = None;
		Enemy = None;
		SetTimer(0.1,True);
	}
	event SeePlayer(Pawn SeenPlayer)
	{
		SetEnemy(SeenPlayer);
	}
	function Timer()
	{
		if( Enemy==None )
			Return;
		Target = Enemy;
		KFM.RangedAttack(Target);
	}
Begin:
	if( Pawn.Physics==PHYS_Falling )
		WaitForLanding();
	While( KFM.bShotAnim )
		Sleep(0.25);
	if( HidingSpots==None )
		HidingSpots = FindRandomDest();
	if( HidingSpots==None )
		ZombieBoss(Pawn).BeginHealing();
	if( ActorReachable(HidingSpots) )
	{
		MoveTarget = HidingSpots;
		HidingSpots = None;
	}
	else FindBestPathToward(HidingSpots,True,False);
	if( MoveTarget==None )
		ZombieBoss(Pawn).BeginHealing();
	if( Enemy!=None && VSize(Enemy.Location-Pawn.Location)<100 )
		MoveToward(MoveTarget,Enemy,,False);
	else MoveToward(MoveTarget,MoveTarget,,False);
	if( HidingSpots==None || !PlayerSeesMe() )
		ZombieBoss(Pawn).BeginHealing();
	GoTo'Begin';
}
State SyrRetreat
{
Ignores HearNoise,DamageAttitudeTo,Tick,EnemyChanged,Startle,WaitForMover;

	function BeginState()
	{
		HidingSpots = None;
		Enemy = None;
		SetTimer(0.1,True);
	}
	event SeePlayer(Pawn SeenPlayer)
	{
		SetEnemy(SeenPlayer);
	}
	function Timer()
	{
		if( Enemy==None )
			Return;
		Target = Enemy;
		KFM.RangedAttack(Target);
	}
	function FindHideSpot()
	{
		local NavigationPoint N,BN;
		local float Dist,BDist,MDist;
		local vector EnemyDir;

		if( Enemy==None )
		{
			HidingSpots = FindRandomDest();
			Return;
		}
		EnemyDir = Normal(Enemy.Location-Pawn.Location);
		For( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
		{
			MDist = VSize(N.Location-Pawn.Location);
			if( MDist<2500 && !FastTrace(N.Location,Enemy.Location) && FindPathToward(N)!=None )
			{
				Dist = VSize(N.Location-Enemy.Location)/FMax(MDist/800.f,1.5);
				if( (EnemyDir Dot Normal(Enemy.Location-N.Location))<0.2 )
					Dist/=10;
				if( BN==None || BDist<Dist )
				{
					BN = N;
					BDist = Dist;
				}
			}
		}
		if( BN==None )
			HidingSpots = FindRandomDest();
		else HidingSpots = BN;
	}
Begin:
	if( Pawn.Physics==PHYS_Falling )
		WaitForLanding();
	While( KFM.bShotAnim )
		Sleep(0.25);
	if( HidingSpots==None )
		FindHideSpot();
	if( HidingSpots==None )
		ZombieBoss(Pawn).BeginHealing();
	if( ActorReachable(HidingSpots) )
	{
		MoveTarget = HidingSpots;
		HidingSpots = None;
	}
	else FindBestPathToward(HidingSpots,True,False);
	if( MoveTarget==None )
		ZombieBoss(Pawn).BeginHealing();
	if( Enemy!=None && VSize(Enemy.Location-Pawn.Location)<100 )
		MoveToward(MoveTarget,Enemy,,False);
	else MoveToward(MoveTarget,MoveTarget,,False);
	if( HidingSpots==None )
		ZombieBoss(Pawn).BeginHealing();
	GoTo'Begin';
}
function bool PlayerSeesMe()
{
	local Controller C;

	For( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( C.bIsPlayer && C.Pawn!=None && C.Pawn!=Pawn && LineOfSightTo(C.Pawn) )
			Return True;
	}
	Return False;
}

final function FindPathAround()
{
	local Actor Res;
	local NavigationPoint N;
	local NavigationPoint OldPts[12];
	local byte i;
	local bool bResult;

	if( Enemy==None || VSize(Enemy.Location-Pawn.Location)<600 )
		return; // No can do this.

	// Attempt to find an alternative path to enemy.
	/* This works by:
		- finding shortest path to enemy
		- block middle path point
		- if the path is still about same to enemy, try block the new path and repeat up to 6 times.
	*/
	for( i=0; i<ArrayCount(OldPts); ++i )
	{
		Res = FindPathToward(Enemy);
		if( Res==None )
			break;
		if( i>0 && CompareOldPaths() )
		{
			bResult = true;
			break;
		}
		N = GetMidPoint();
		if( N==None )
			break;
		N.bBlocked = true;
		OldPts[i] = N;
		if( i==0 )
			SetOldPaths();
	}

	// Unblock temp blocked paths.
	for( i=0; i<ArrayCount(OldPts); ++i )
		if( OldPts[i]!=None )
			OldPts[i].bBlocked = false;
	if( !bResult )
		return;

	// Fetch results and switch state.
	GetMidGoals();
	if( ReachOffset<2 )
		GoToState('PatFindWay');
}
final function NavigationPoint GetMidPoint()
{
	local byte n;

	for( n=0; n<ArrayCount(RouteCache); ++n )
		if( RouteCache[n]==None )
			break;
	if( n==0 )
		return None;
	return NavigationPoint(RouteCache[(n-1)*0.5]);
}
final function bool CompareOldPaths()
{
	local byte n,i;

	for( i=0; i<6; ++i )
	{
		if( RouteCache[i]==None )
			break;
		for( n=0; n<ArrayCount(OldPathsCheck); ++n )
			if( RouteCache[i]==OldPathsCheck[n] )
				return false;
	}
	return true;
}
final function SetOldPaths()
{
	local byte n;

	for( n=0; n<ArrayCount(OldPathsCheck); ++n )
		OldPathsCheck[n] = RouteCache[n+1];
	if( RouteCache[1]==None )
		OldPathsCheck[0] = RouteCache[0];
}
final function GetMidGoals()
{
	local byte n;

	for( n=0; n<ArrayCount(RouteCache); ++n )
		if( RouteCache[n]==None )
			break;
	if( n==0 )
	{
		ReachOffset = 2;
		return;
	}
	--n;
	MidGoals[0] = NavigationPoint(RouteCache[n*0.5]);
	MidGoals[1] = NavigationPoint(RouteCache[n]);
	if( MidGoals[0]==MidGoals[1] )
		ReachOffset = 1;
	else ReachOffset = 0;
}

state PatFindWay
{
Ignores Timer,SeePlayer,HearNoise,DamageAttitudeTo,EnemyChanged,Startle,Tick;

	final function PickDestination()
	{
		if( ReachOffset>=2 )
		{
			GotoState('ZombieHunt');
			return;
		}
		if( ActorReachable(MidGoals[ReachOffset]) )
		{
			MoveTarget = MidGoals[ReachOffset];
			++ReachOffset;
		}
		else
		{
			MoveTarget = FindPathToward(MidGoals[ReachOffset]);
			if( MoveTarget==None )
				++ReachOffset;
		}
	}
	function BreakUpDoor( KFDoorMover Other)
	{
		Global.BreakUpDoor(Other);
		Pawn.GoToState('');
	}
Begin:
	PickDestination();
	if( MoveTarget==None )
		Sleep(0.5f);
	else MoveToward(MoveTarget,MoveTarget,,False);
	GoTo'Begin';
}

defaultproperties
{
}
