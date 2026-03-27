//-----------------------------------------------------------
//
//-----------------------------------------------------------
class MonsterFPAI extends FleshpoundZombieController;

var vector HeardNoiseSpot,HuntingDestination;
var transient float RageTimeLeft,NextDisappearTime,StuckTimer;
var transient Actor RepeatMoves[3];
var transient byte RepeatCounter;
var bool bMoveFinished,bHeardNoise,bKeepHuntingNow;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	NextDisappearTime = Level.TimeSeconds + FRand()*120.f;
}
function bool FindNewEnemy()
{
	return false;
}
function bool FindRoamDest()
{
	WanderOrCamp(false);
	return true;
}
function WanderOrCamp(bool bMayCrouch)
{
	if( RageTimeLeft>Level.TimeSeconds )
		GotoState('ZombieHunt');
	else GotoState('ZombieRestFormation');
}

final function bool CanDisappear()
{
	local Controller C;
	
	for( C=Level.ControllerList; C!=None; C=C.nextController )
		if( C.bIsPlayer && KFPawn(C.Pawn)!=None && C.Pawn.Health>0
		&& (VSize(C.Pawn.Location-Pawn.Location)<800.f || C.LineOfSightTo(Pawn)) )
			return false;
	return true;
}
final function bool IsRepeatMove( Actor A )
{
	local byte i;
	
	for( i=0; i<ArrayCount(RepeatMoves); ++i )
		if( RepeatMoves[i]==A )
		{
			if( ++RepeatCounter>20 && StuckTimer<Level.TimeSeconds )
			{
				RepeatCounter = 0;
				MakeVisible();
				GoToState('ZombieRestFormation','Camping');
				return true;
			}
			else if( RepeatCounter==1 )
				StuckTimer = Level.TimeSeconds+5.f;
			else RepeatCounter = Min(RepeatCounter,25);
			return false;
		}
	RepeatCounter = 0;
	for( i=(ArrayCount(RepeatMoves)-1); i>0; --i )
		RepeatMoves[i] = RepeatMoves[i-1];
	RepeatMoves[0] = A;
	return false;
}

function bool SetEnemy( Pawn NewEnemy, optional bool bHateMonster )
{
	if( KFM.Intelligence>=BRAINS_Mammal && Enemy!=None && NewEnemy!=None && NewEnemy!=Enemy && NewEnemy.Controller!=None && NewEnemy.Controller.bIsPlayer )
	{
		if( LineOfSightTo(Enemy) && VSize(Enemy.Location-Pawn.Location)<VSize(NewEnemy.Location-Pawn.Location) )
			Return False;
		Enemy = None;
	}
	if( bHateMonster && KFMonster(NewEnemy)!=None && NewEnemy.Controller!=None && (NewEnemy.Controller.Target==Self || FRand()<0.15)
	 && NewEnemy.Health>0 && VSize(NewEnemy.Location-Pawn.Location)<1500 && LineOfSightTo(NewEnemy) ) // Get pissed at this fucker..
	{
		ChangeEnemy(NewEnemy,CanSee(NewEnemy));
		return true;
	}
	if( Super(MonsterController).SetEnemy(NewEnemy,bHateMonster) )
	{
		if( KFPawn(NewEnemy)!=None && MonsterFP(Pawn).Manager!=None )
			MonsterFP(Pawn).Manager.SetMonsterRage(true);
		Return True;
	}
	Return False;
}
final function NavigationPoint PickRouteGoal( vector NearSpot )
{
	local NavigationPoint N,Best;
	local float Dist,BestDist;
	
	for( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
	{
		Dist = VSize(N.Location-NearSpot);
		if( Dist<800.f && FastTrace(N.Location,NearSpot) )
			Dist*=0.25;
		if( Best==None || Dist<BestDist )
		{
			Best = N;
			BestDist = Dist;
		}
	}
	return Best;
}
function MakeVisible()
{
	local Controller C;
	local NavigationPoint N,Best;
	local float Des,BDes,D;
	local rotator R;
	
	for( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
	{
		Des = 1000.f + FRand()*50.f;
		for( C=Level.ControllerList; C!=None; C=C.nextController )
		{
			if( C.bIsPlayer && KFPawn(C.Pawn)!=None && C.Pawn.Health>0 )
			{
				D = VSize(C.Pawn.Location-N.Location);
				if( D<800.f )
					Des-=100;
				if( D>2000.f )
					Des-=25;
				else if( FastTrace(C.Pawn.Location,N.Location) )
					Des-=800;
			}
		}
		if( Best==None || Des>BDes )
		{
			Best = N;
			BDes = Des;
		}
	}
	Pawn.bMovable = true;
	Pawn.SetLocation(Best.Location);
	R.Yaw = Rand(65536);
	Pawn.SetRotation(R);
}

state ZombieRestFormation
{
ignores EnemyNotVisible;

	function BeginState()
	{
		MinHitWall += 0.15;
		Enable('SeePlayer');
		if( MonsterFP(Pawn).Manager!=None )
			MonsterFP(Pawn).Manager.SetMonsterRage(false);
	}
	function HearNoise(float Loudness, Actor NoiseMaker)
	{
		if( NoiseMaker!=none )
		{
			HeardNoiseSpot = NoiseMaker.Location;
			bHeardNoise = true;
			if( Pawn.Acceleration==vect(0,0,0) )
				GoToState(,'Moving');
			else GoToState(,'AlertNoise');
		}
	}
	function Timer()
	{
		SetCombatTimer();
	}
	function PickDestination()
	{
		Focus = None;
		bMoveFinished = false;
		if( bHeardNoise )
		{
			if( PointReachable(HeardNoiseSpot) )
			{
				MoveTarget = None;
				if( VSize(HeardNoiseSpot-Pawn.Location)>200.f )
					Destination = HeardNoiseSpot - Normal(HeardNoiseSpot-Pawn.Location)*100.f;
				else Destination = Pawn.Location + Normal(HeardNoiseSpot-Pawn.Location)*10.f;
				bHeardNoise = false;
				bMoveFinished = true;
				return;
			}
			MoveTarget = FindPathTo(HeardNoiseSpot);
			if( MoveTarget==None )
			{
				RouteGoal = PickRouteGoal(HeardNoiseSpot);
				Destination = Pawn.Location + Normal(HeardNoiseSpot-Pawn.Location)*100.f;
				bHeardNoise = false;
				bMoveFinished = true;
			}
			else IsRepeatMove(MoveTarget);
			return;
		}
		if( RouteGoal==None )
		{
			RouteGoal = FindRandomDest();
			if( RouteGoal==None )
			{
				MoveTarget = None;
				Destination = Pawn.Location+VRand()*800.f;
				return;
			}
		}
		if( ActorReachable(RouteGoal) )
		{
			MoveTarget = RouteGoal;
			RouteGoal = None;
			bMoveFinished = true;
			if( NextDisappearTime<Level.TimeSeconds && CanDisappear() )
				GoToState('Disappeared');
			return;
		}
		MoveTarget = FindPathToward(RouteGoal);
		if( MoveTarget==None )
		{
			RouteGoal = None;
			Destination = Pawn.Location+VRand()*400.f;
		}
		else IsRepeatMove(MoveTarget);
	}
Begin:
    WaitForLanding();
	GoTo'Moving';
Camping:
	Pawn.Acceleration = vect(0,0,0);
	Focus = None;
	FocalPoint = vector(Pawn.Rotation)*800.f + Pawn.Location;
	Sleep(1.f+FRand()*5.f);
Moving:
    PickDestination();
WaitForAnim:
    while( KFM.bShotAnim )
        Sleep(0.25);
	if( MoveTarget!=None )
		MoveToward(MoveTarget,MoveTarget);
	else MoveTo(Destination,None);
	if( bMoveFinished )
		GoTo'Camping';
    Goto('Begin');
AlertNoise:
	Pawn.Acceleration = vect(0,0,0);
	Focus = None;
	FocalPoint = HeardNoiseSpot;
	Sleep(0.5f+FRand()*2.f);
	GoTo'Moving';
}

state ZombieHunt
{
	function BeginState()
	{
		Pawn.SightRadius = Pawn.Default.SightRadius*2.f;
		Pawn.HearingThreshold = Pawn.Default.HearingThreshold*0.4;
		if( Enemy!=None )
		{
			RageTimeLeft = Level.TimeSeconds + 5.f + FRand()*8.f;
			bKeepHuntingNow = true;
			HuntingDestination = Enemy.Location;
			RouteGoal = PickRouteGoal(Enemy.Location);
			Enemy = None;
		}
		else
		{
			bKeepHuntingNow = false;
			RouteGoal = None;
		}
	}
	function EndState()
	{
		Pawn.SightRadius = Pawn.Default.SightRadius;
		Pawn.HearingThreshold = Pawn.Default.HearingThreshold;
		RouteGoal = None;
	}
	function HearNoise(float Loudness, Actor NoiseMaker)
	{
		if( !bKeepHuntingNow && NoiseMaker!=none )
		{
			RageTimeLeft = Level.TimeSeconds + 5.f + FRand()*8.f;
			HuntingDestination = NoiseMaker.Location;
			RouteGoal = PickRouteGoal(NoiseMaker.Location);
			bKeepHuntingNow = true;
		}
	}
	function Timer()
	{
		SetCombatTimer();
		StopFiring();
	}
	function bool DoWaitForLanding()
	{
		return false;
	}
	function PickDestination()
	{
		MoveTarget = None;
		if( bKeepHuntingNow )
		{
			if( PointReachable(HuntingDestination) )
			{
				Destination = HuntingDestination;
				bKeepHuntingNow = false;
				RouteGoal = None;
				return;
			}
			MoveTarget = FindPathTo(HuntingDestination);
			if( MoveTarget==None )
			{
				if( RouteGoal!=None )
				{
					if( ActorReachable(RouteGoal) )
					{
						MoveTarget = RouteGoal;
						RouteGoal = None;
						bKeepHuntingNow = false;
						return;
					}
					MoveTarget = FindPathToward(RouteGoal);
					if( MoveTarget!=None )
					{
						IsRepeatMove(MoveTarget);
						return;
					}
				}
				Destination = HuntingDestination;
				bKeepHuntingNow = false;
			}
			return;
		}
		if( RageTimeLeft<Level.TimeSeconds )
		{
			WhatToDoNext(23);
			return;
		}
		if( RouteGoal==None )
		{
			RouteGoal = FindRandomDest();
			if( RouteGoal==None )
			{
				Destination = Pawn.Location+VRand()*800.f;
				return;
			}
		}
		MoveTarget = FindPathToward(RouteGoal);
		if( MoveTarget==None )
		{
			RouteGoal = None;
			Destination = Pawn.Location+VRand()*400.f;
		}
		else IsRepeatMove(MoveTarget);
    }

Begin:
	WaitForLanding();
WaitForAnim:
	MonsterFP(Pawn).StartCharging();
	while( Monster(Pawn).bShotAnim )
		Sleep(0.35);
	PickDestination();
SpecialNavig:
	Focus = None;
	if (MoveTarget == None)
		MoveTo(Destination,None);
	else
		MoveToward(MoveTarget,MoveTarget);
	GoTo'Begin';
}

state Disappeared
{
Ignores SeePlayer,HearNoise,DamageAttitudeTo,Timer,NotifyPhysicsVolumeChange,NotifyHeadVolumeChange,NotifyLanded,NotifyPostLanded,NotifyHitWall,NotifyFallingHitWall,NotifyBump,NotifyHitMover,NotifyJumpApex,NotifyMissedJump,NotifyTakeHit,SeeMonster,SetEnemy;

	function BeginState()
	{
		Pawn.bHidden = true;
		Pawn.bMovable = false;
		Pawn.bAlwaysRelevant = false;
		Pawn.SetPhysics(PHYS_None);
		Pawn.SetCollision(false);
		Pawn.StopAnimating();
		if( KFM.MyExtCollision!=None )
			KFM.MyExtCollision.SetCollision(false);
	}
	function EndState()
	{
		NextDisappearTime = Level.TimeSeconds + 30.f + FRand()*80.f;
		if( Pawn!=None )
		{
			Pawn.bHidden = false;
			Pawn.bMovable = true;
			Pawn.bAlwaysRelevant = true;
			Pawn.SetPhysics(PHYS_Falling);
			Pawn.SetCollision(true);
			if( KFM.MyExtCollision!=None )
				KFM.MyExtCollision.SetCollision(true);
		}
	}
Begin:
	Sleep(30.f+FRand()*60.f);
	MakeVisible();
	WanderOrCamp(false);
}

defaultproperties
{
     RageFrustrationThreshhold=0.100000
}
