//-----------------------------------------------------------
//
//-----------------------------------------------------------
class BossZombieController extends KFMonsterController;

var NavigationPoint HidingSpots;

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
Ignores HearNoise,DamageAttitudeTo,Tick,EnemyChanged;

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
Ignores HearNoise,DamageAttitudeTo,Tick,EnemyChanged;

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

defaultproperties
{
}
