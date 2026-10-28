class KFMonsterController extends MonsterController;
// Custom Zombie Thinkerating
// By : Alex

var KFMonster KFM;

var int ThreatTime;
var float MoanTime;
var() float MoanGapMin, MoanGapMax;	// seconds between one specimen's moans, picked afresh each time
var bool ItsSet,bUseFreezeHack,bAboutToGetDoor,bTriggeredFirstEvent,bHuntSqueezed;
var int TimeToSet;
var int EvaluateTime;
var float ChargeStart,LastCorpseTime;
var byte NumAttmpts;
var byte CorpseBiteCount;

var KFDoorMover TargetDoor;
var KFBarricadePlank TargetPlank;
var float NextClimbTry;
var PlayerDeathMark TargetCorpse;
var() bool bWarnShotTarget;		// projectiles warn their target, as bots' do (AdjustAim)
var KActor KickTarget;

var Actor InitialPathGoal;
var byte PathFindState;
var() bool bStallDropsFirstStop;	// one that stalls on its way to its first stop gives it up and makes for its victim

// Used for alternative pathing:
var Actor LastResult;
var NavigationPoint BlockedWay,ExtraCostWay;
var float BlockedWayTime;

var KFSwarm Swarm;		// None when the swarm is switched off

const NOFLOOR = 255;
var byte MyFloor;
var bool bLiftPass;
var float NextFloorCheck,StrandedTime;
var() float StrandedDelay;

var vector WedgeSpot;
var float WedgeSince, NextWedgeCheck;
var byte WedgeHops;
var() float WedgeDelay;		// this long held in one spot while falling, or while its velocity says it moves, it hops loose (0: never)
var float AnchorlessSince;
var() float AnchorlessDelay;	// this long finding no way onto the paths, a specimen nobody sees is recycled (0: never)

// Riot: one of a row of specimens let loose side by side (KFEndlessGameType). It keeps its place across the way,
// as far as there is room at each path node, until it is near its victim; one ahead of its row eases off.
var int RiotRow;				// its row, -1 when in none
var float RiotLane;				// its place across the way: units right of the row's middle, negative to the left
var NavigationPoint LaneNode, LanePrevNode;
var vector LanePoint, LaneDir;
var bool bLane, bEased;
var bool bRiotRush;				// its row rushes in: nobody eases off to keep the row together
var float LaneOffUntil, LaneStuck, NextDirectLane;
var() float RiotReleaseDist;	// this near its victim it leaves the row, and the swarm takes over
var() float RiotAheadSlack;		// this much nearer its victim than its row's average, it eases off
var() float RiotEaseSpeed;		// share of full speed while easing off

function Restart()
{
	KFM = KFMonster(Pawn);
	if( KFGameType(Level.Game)!=None )
		Swarm = KFGameType(Level.Game).Swarm;
	// (the harder the game and the stronger the swarm, the more of them make for their victim at once and not
	// first for a random place)
	if( Swarm!=None && FRand()<Swarm.StraightShare*Swarm.Strength )
		PathFindState = 2;
	// (one of a river of specimens: no detour, so that they come on in a column)
	if( KFGameType(Level.Game)!=None && KFGameType(Level.Game).bStraightSpawn )
		PathFindState = 2;
	if( !KFM.bStartUpDisabled )
		Super.Restart();
}

function bool AdjustAround(Pawn Other)
{
	local float speed;
	local vector VelDir, OtherDir, SideDir;

	speed = VSize(Pawn.Acceleration);
	if ( speed < Pawn.WalkingPct * Pawn.GroundSpeed )
		return false;

	VelDir = Pawn.Acceleration/speed;
	VelDir.Z = 0;
	OtherDir = Other.Location - Pawn.Location;
	OtherDir.Z = 0;
	OtherDir = Normal(OtherDir);
	if ( (VelDir Dot OtherDir) > 0.8 )
	{
		bAdjusting = true;
		SideDir.X = VelDir.Y;
		SideDir.Y = -1 * VelDir.X;
		if ( (SideDir Dot OtherDir) > 0 )
			SideDir *= -1;
		AdjustLoc = Pawn.Location + 1.5 * Other.CollisionRadius * (0.5 * VelDir + SideDir);
		return true;
	}
}

event bool NotifyBump(actor Other)
{
	local Pawn P;

	Disable('NotifyBump');
	P = Pawn(Other);
	if ( (P == None) || (P.Controller == None) || (Enemy == P) )
		return false;
	if ( SetEnemy(P) )
	{
		WhatToDoNext(4);
		return false;
	}

	if ( Enemy == P )
		return false;

	// one of its own kind in the way: a free place round the victim, or round the one in front
	if ( Swarm != None && Swarm.bStepRound && KFMonster(P) != None && Swarm.StepRound(Self, P) )
		return false;
	if ( !AdjustAround(P) )
		CancelCampFor(P.Controller);
	return false;
}


// Randomly plays a different moan sound for the Zombie each time it is called. Gruesome!
function ZombieMoan()
{
	if( Pawn==None || Pawn.Health<=0 )
		Destroy();
	else if( !KFM.bDecapitated ) // Headless zombies can't moan.
		KFM.ZombieMoan();
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetCombatTimer();
	if ( UnrealMPGameInfo(Level.Game).bSoaking )
		bSoaking = true;
	// the first moan falls anywhere in a gap, so a squad that came in together does not moan as one
	MoanTime = Level.TimeSeconds + FRand() * MoanGapMax;
	EvaluateTime = Level.TimeSeconds;
	TimeToSet = Level.TimeSeconds;
	ItsSet=false;
}

function MoverFinished()
{
	if (PendingMover == None)
		return;

	if (LiftCenter(PendingMover.MyMarker) != None && !PendingMover.bInterpolating)
	{
		PendingMover = None;
		bPreparingMove = false;
		return;
	}

	if (PendingMover.MyMarker == None || PendingMover.MyMarker.ProceedWithMove(Pawn))
	{
		PendingMover = None;
		bPreparingMove = false;
	}
}

event SeePlayer(Pawn SeenPlayer)
{
	if ( ((ChooseAttackCounter < 2) || (ChooseAttackTime != Level.TimeSeconds)) && SetEnemy(SeenPlayer) )
		WhatToDoNext(3);
	if ( Enemy == SeenPlayer )
	{
		VisibleEnemy = Enemy;
		EnemyVisibilityTime = Level.TimeSeconds;
		bEnemyIsVisible = true;
	}
}

// Overridden because we want our Zeds to be a bit more scared of fear spots
function FearThisSpot(AvoidMarker aSpot)
{
	if ( Skill > 1 + 2.0 * FRand() )
        super(Controller).FearThisSpot(aSpot);
}

// A table or a crate head-on in the way, low enough: climbed onto (KFMonster.StartClimb), not walked around. Not a door
// nor a window's planks, which are broken through, nor a mover, a prop or another pawn
event bool NotifyHitWall( vector HitNormal, actor Wall )
{
	local vector Dir;

	// (climbing, the edge it goes up is touched all the way: the engine would put it back down a step each time)
	if ( KFM != None && KFM.ClimbStage > 0 )
		return true;
	if ( KFM != None && KFM.bClimbs && Pawn.Physics == PHYS_Walking && Level.TimeSeconds >= NextClimbTry && Abs(HitNormal.Z) < 0.5
		&& Wall != None && (Wall.bWorldGeometry || Wall == Level) && Mover(Wall) == None
		&& !IsInState('DoorBashing') && !IsInState('BarricadeBashing') )
	{
		NextClimbTry = Level.TimeSeconds + 0.4;
		if ( MoveTarget != None )
			Dir = MoveTarget.Location - Pawn.Location;
		else
			Dir = Destination - Pawn.Location;
		Dir.Z = 0;
		if ( VSize(Dir) > 1.0 && (Normal(Dir) Dot HitNormal) < -0.5 && KFM.StartClimb(-HitNormal) )
			return true;
	}
	return Super.NotifyHitWall(HitNormal, Wall);
}

function BreakUpDoor( KFDoorMover Other ) // I have came up to a door, break it!
{
	TargetDoor = Other;
	GoalString = "DOORBASHING";
	GotoState('DoorBashing');
}

function BreakUpBarricade( KFBarricadePlank Other ) 
{
	if( IsInState('BarricadeBashing') && TargetPlank==Other )
		Return;

	TargetPlank = Other;
	GoalString = "BARRICADEBASHING";
	GotoState('BarricadeBashing');
}

// The Times between each call of the ZombieMoan function ...
function tick(float DeltaTime)
{
	if( Level.TimeSeconds >= MoanTime )
	{
		ZombieMoan();
		MoanTime = Level.TimeSeconds + MoanGapMin + FRand() * (MoanGapMax - MoanGapMin);
	}
	if( bAboutToGetDoor )
	{
		bAboutToGetDoor = False;
		if( TargetDoor!=None )
			BreakUpDoor(TargetDoor);
	}
	if( Level.TimeSeconds >= NextFloorCheck )
		CheckFloor();
	if( Level.TimeSeconds >= NextWedgeCheck )
	{
		CheckWedged();
		CheckAnchorless();
	}
}

// One whose path searches find no way onto the paths (spawned off them, or fallen into a pocket) is recycled when
// nobody sees it; the stock random jumps in FindRoamDest only start for one that once had a way on
function CheckAnchorless()
{
	if( AnchorlessDelay<=0 || Pawn==None || Pawn.Health<=0 || KFM==None )
		Return;
	if( Pawn.FindAnchorFailedTime<=Pawn.LastValidAnchorTime )
	{
		AnchorlessSince = 0;
		Return;
	}
	if( AnchorlessSince==0 )
		AnchorlessSince = Level.TimeSeconds;
	else if( Level.TimeSeconds-AnchorlessSince>=AnchorlessDelay && !Pawn.PlayerCanSeeMe() && KFGameType(Level.Game)!=None )
		KFGameType(Level.Game).RecycleMonster(KFM);
}

// Held in one spot while falling or while its velocity says it moves (caught on a ledge, or on a blocking volume's edge):
// a hop towards where it is going, then one back the other way, then random ones; after three, unseen, it is recycled
function CheckWedged()
{
	local vector Dir;

	NextWedgeCheck = Level.TimeSeconds + 1.0;
	if( WedgeDelay<=0 || Pawn==None || Pawn.Health<=0 || KFM==None )
		Return;
	if( VSize(Pawn.Location-WedgeSpot)>8 || (VSize(Pawn.Velocity)<100 && Pawn.Physics!=PHYS_Falling) || KFM.bShotAnim )
	{
		WedgeSpot = Pawn.Location;
		WedgeSince = Level.TimeSeconds;
		WedgeHops = 0;
		Return;
	}
	if( Level.TimeSeconds-WedgeSince<WedgeDelay )
		Return;
	WedgeSince = Level.TimeSeconds;
	if( WedgeHops>=3 && !Pawn.PlayerCanSeeMe() && KFGameType(Level.Game)!=None && KFGameType(Level.Game).RecycleMonster(KFM) )
		Return;
	if( MoveTarget!=None )
		Dir = MoveTarget.Location - Pawn.Location;
	else Dir = Destination - Pawn.Location;
	WedgeHops++;
	if( WedgeHops==2 )
		Dir = -Dir;
	else if( WedgeHops>2 )
		Dir = VRand();
	Dir.Z = 0;
	if( VSize(Dir)<1 )
		Dir = vect(1,0,0);
	Pawn.Velocity = Normal(Dir) * Pawn.GroundSpeed * 0.5;
	Pawn.Velocity.Z = 300;
	Pawn.SetPhysics(PHYS_Falling);
}

function CheckFloor()
{
	local KFGameType G;
	local byte EnemyFloor;
	local bool bStranded;

	NextFloorCheck = Level.TimeSeconds + 0.9 + 0.2 * FRand();
	G = KFGameType(Level.Game);
	if( G==None || G.FloorMap==None || G.FloorMap.NumFloors<2 || Pawn==None || Pawn.Health<=0 )
		Return;
	MyFloor = G.FloorMap.FloorAt(Pawn.Location);
	if( MyFloor==NOFLOOR )
		Return;
	EnemyFloor = NOFLOOR;
	if( Enemy!=None )
	{
		EnemyFloor = G.FloorMap.FloorOf(Enemy);
		if( EnemyFloor==NOFLOOR )
			Return;
		bStranded = (EnemyFloor!=MyFloor);
	}
	if( !bStranded && (Level.TimeSeconds-Pawn.FindAnchorFailedTime)<1.5 && (Level.TimeSeconds-Pawn.LastValidAnchorTime)>5 )
	{
		bStranded = True;
		EnemyFloor = NOFLOOR;
	}
	if( !bStranded )
	{
		StrandedTime = 0;
		bLiftPass = False;
		Return;
	}
	if( StrandedTime==0 )
		StrandedTime = Level.TimeSeconds;
	if( (Level.TimeSeconds-StrandedTime)<StrandedDelay || KFElevator(Pawn.Base)!=None )
		Return;
	if( !Pawn.PlayerCanSeeMe() && G.CanSpawnOnFloor(EnemyFloor) && G.RecycleMonster(KFM) )
		Return;
	bLiftPass = True;
}

function bool MayUseLift()
{
	local KFGameType G;

	G = KFGameType(Level.Game);
	Return (bLiftPass || G==None || G.FloorMap==None || G.FloorMap.NumFloors<2);
}

function float EnemyDistance( Pawn Other )
{
	local KFGameType G;
	local float Dist;

	Dist = VSize(Other.Location - Pawn.Location);
	G = KFGameType(Level.Game);
	if( G!=None && G.FloorMap!=None && G.FloorMap.OtherFloor(MyFloor,G.FloorMap.FloorOf(Other)) )
		Dist += 100000.f;
	Return Dist;
}

// If we're not dead, and we can see our target, and we still have a head. lets go eat it.
function bool FindFreshBody()
{
	local KFGameType K;
	local int i;
	local PlayerDeathMark Best;
	local float Dist,BDist;

	K = KFGameType(Level.Game);
	if( K==None || KFM.bDecapitated || !KFM.bCannibal || (!Level.Game.bGameEnded && Pawn.Health>=(Pawn.Default.Health*1.5)) )
		Return False;
	for( i=0; i<K.DeathMarkers.Length; i++ )
	{
		if( K.DeathMarkers[i]==None )
			Continue;
		Dist = VSize(K.DeathMarkers[i].Location-Pawn.Location);
		if( Dist<800 && (Best==None || Dist<BDist) )
		{
			Best = K.DeathMarkers[i];
			BDist = Dist;
		}
	}
	// Only do expensive reachability check on the best candidate
	if( Best==None || !ActorReachable(Best) )
		Return False;
	TargetCorpse = Best;
	GoToState('CorpseFeeding');
	Return True;
}

function bool FindNewEnemy()
{
	local Pawn BestEnemy;
	local bool bSeeNew, bSeeBest;
	local float BestDist, NewDist;
	local Controller PC;
	local KFHumanPawn C;

	if( KFM.bNoAutoHuntEnemies )
		Return False;

	if( Enemy!=None && KFHumanPawnZombies(Enemy)!=None && KFHumanPawnZombies(Enemy).bIsDowned )
		Enemy = None;

	if ( KFM.bCannibal && pawn.Health < (1.0-KFM.FeedThreshold)*pawn.HealthMax || Level.Game.bGameEnded )
	{
		for ( PC=Level.ControllerList; PC!=None; PC=PC.NextController )
		{
			C = KFHumanPawn(PC.Pawn);
			if( C==None || C.Health<=0 )
				Continue;
			if( KFHumanPawnZombies(C)!=None && KFHumanPawnZombies(C).bIsDowned )
				Continue;
			NewDist = PreyDistance(C);
			if ( BestEnemy == None )
			{
				BestEnemy = C;
				BestDist = NewDist;
				bSeeBest = CanSee(C);
			}
			else if ( NewDist < BestDist )
			{
				bSeeNew = CanSee(C);
				BestEnemy = C;
				BestDist = NewDist;
				bSeeBest = bSeeNew;
			}
		}
	}
	else
	{
		for ( PC=Level.ControllerList; PC!=None; PC=PC.NextController )
		{
			// (not a player's specimen in Versus)
			if ( PC.bIsPlayer && (PC.Pawn!=None) && PC.Pawn.Health>0 && KFMonster(PC.Pawn)==None
			 && (KFHumanPawnZombies(PC.Pawn)==None || !KFHumanPawnZombies(PC.Pawn).bIsDowned) )
			{
				NewDist = PreyDistance(PC.Pawn);
				if ( BestEnemy == None )
				{
					BestEnemy = PC.Pawn;
					BestDist = NewDist;
					bSeeBest = CanSee(BestEnemy);
				}
				else if ( NewDist < BestDist )
				{
					bSeeNew = CanSee(PC.Pawn);
					BestEnemy = PC.Pawn;
					BestDist = NewDist;
					bSeeBest = bSeeNew;
				}
			}
		}
	}

	if ( BestEnemy == Enemy )
		return false;

	if ( BestEnemy != None )
	{
		ChangeEnemy(BestEnemy,bSeeBest);
		return true;
	}
	return false;
}

// TODO - Is this the best way to deal with enemies we can't see?
function EnemyNotVisible();

function Timer();

function DoCharge()
{
	if(pawn != none)
	{
		if ( Enemy.PhysicsVolume.bWaterVolume )
		{
			if ( !Pawn.bCanSwim )
			{
				DoTacticalMove();
				return;
			}
		}
		else
		{
			if (KFM.MeleeRange != KFM.default.MeleeRange)
				KFM.MeleeRange = KFM.default.MeleeRange;
			GotoState('ZombieCharge');
		}
	}
}

function DoTacticalMove();

function bool TestDirection( vector dir, out vector pick )
{
	local int	FearRadius;
	local vector HitLocation, HitNormal, dist, avoid, flee;
	local actor HitActor;

	if ( Pawn == None || Pawn.Health < 1 )
		return false;

	// Actually avoid FearSpots.  (was never implemented)
	if ( FearSpots[0] != None || FearSpots[1] != None )
	{
		if ( FearSpots[1] != None && ( FearSpots[0] == None || VSize( Pawn.Location - FearSpots[0].Location ) > VSize( Pawn.Location - FearSpots[1].Location ) ) )
		{
			avoid = FearSpots[1].Location;
			FearRadius = FearSpots[1].CollisionRadius;
		}
		else
		{
			avoid = FearSpots[0].Location;
			FearRadius = FearSpots[0].CollisionRadius;
		}
		// NOTE: Instead of testing random picks for a good destination away from the fearspot,
		//        assign a destination well out of the fearspot collision radius.
		flee = Normal( Pawn.Location - avoid );
		pick = flee * ( Pawn.CollisionRadius + MINSTRAFEDIST + ( MINSTRAFEDIST * FRand() ) );
		// TODO: Force avoidance maneuver, jump or move to location toward goal but away from spot.
		Destination = Pawn.Location + pick;
		FocalPoint = Destination;
		return true;
	}
	else
		pick = dir * (MINSTRAFEDIST + 2 * MINSTRAFEDIST * FRand());

	HitActor = Trace( HitLocation, HitNormal, Pawn.Location + pick + 1.5 * Pawn.CollisionRadius * dir , Pawn.Location, false );
	if ( HitActor != None )
	{
		pick = HitLocation + ( HitNormal - dir ) * 2 * Pawn.CollisionRadius;
		if ( !FastTrace( pick, Pawn.Location ) )
			return false;
	}
	else
		pick = Pawn.Location + pick;

	// TODO: Use pick itself (z zeroed out) as dist
	dist = pick - Pawn.Location;
	if (Pawn.Physics == PHYS_Walking)
		dist.Z = 0;

	return (VSize(dist) > MINSTRAFEDIST);
}
// How far a player seems when a victim is chosen: the swarm spreads itself over the players
function float PreyDistance( Pawn Other )
{
	if( Swarm==None )
		Return EnemyDistance(Other);
	Return EnemyDistance(Other) + Swarm.PreyBias(Other,Other==Enemy);
}
// A holdout specimen's route search sees the ways the crowd has lately taken as dearer (KFGameType traffic)
function bool FindBestPathToward(Actor A, bool bCheckedReach, bool bAllowDetour)
{
	if( !bCheckedReach && ActorReachable(A) )
	{
		MoveTarget = A;
		return true;
	}
	if( KFM!=None && KFM.bFixedPace && KFGameType(Level.Game)!=None )
		KFGameType(Level.Game).AddTrafficCosts();
	return Super.FindBestPathToward(A, true, bAllowDetour);
}

// Called by a riot specimen's pawn every tick, after this controller has steered it at its path node
function RiotSteer( float DeltaTime )
{
	local NavigationPoint N;
	local vector Want;
	local float D;

	if( Enemy==None || Pawn.Physics!=PHYS_Walking || KFM==None || KFM.bShotAnim )
		return;
	D = VSize(Enemy.Location - Pawn.Location);
	if( D<RiotReleaseDist )
	{
		RiotRow = -1;
		if( bEased )
			Pawn.DesiredSpeed = Pawn.MaxDesiredSpeed;
		bEased = false;
		return;
	}
	HoldRow(D);

	if( bAdjusting || Level.TimeSeconds<LaneOffUntil || VSize(Pawn.Acceleration)<1 )
		return;
	N = NavigationPoint(MoveTarget);
	if( N==None )
	{
		// straight at its victim, or at a spot: its place across the way from here to there
		if( MoveTarget==Enemy )
			DirectLane(Enemy.Location);
		else if( MoveTarget==None )
			DirectLane(Destination);
		else return;
		if( !bLane )
			return;
		Want = LanePoint - Pawn.Location;
		Want.Z = 0;
	}
	else
	{
		if( !PlainNode(N) )
			return;
		if( N!=LaneNode )
			LayLane(N);
		if( !bLane )
			return;
		Want = LanePoint - Pawn.Location;
		Want.Z = 0;
		// level with the node: on to the next one of the route, from the side
		if( VSize(Want)<1.5*Pawn.CollisionRadius || ((N.Location - Pawn.Location) Dot LaneDir)<Pawn.CollisionRadius )
		{
			NextLegNode();
			return;
		}
	}
	Pawn.Acceleration = Normal(Want) * VSize(Pawn.Acceleration);
	// pressed against something: the plain way for a while
	if( VSize(Pawn.Velocity)<40 )
	{
		LaneStuck += DeltaTime;
		if( LaneStuck>0.75 )
		{
			LaneStuck = 0;
			bLane = false;
			LaneOffUntil = Level.TimeSeconds + 3.0;
		}
	}
	else LaneStuck = 0;
}

// One well ahead of its row's average eases off till the rest come up
function HoldRow( float D )
{
	local float Avg;

	if( KFGameType(Level.Game)==None || bRiotRush )
		return;
	Avg = KFGameType(Level.Game).RiotRowDist[RiotRow % 32];
	if( Avg>0 && D<Avg-RiotAheadSlack )
	{
		Pawn.DesiredSpeed = RiotEaseSpeed * Pawn.MaxDesiredSpeed;
		bEased = true;
	}
	else if( bEased )
	{
		Pawn.DesiredSpeed = Pawn.MaxDesiredSpeed;
		bEased = false;
	}
}

// A node a lane may pass beside: not a lift, ladder, door or special move
function bool PlainNode( NavigationPoint N )
{
	return !N.bSpecialMove && LiftCenter(N)==None && LiftExit(N)==None && Ladder(N)==None && Door(N)==None;
}

// This specimen's lane past node N: its place across the way from the last node to N, narrowed to the room there
// (a wall on that side, no floor, or no clear way from here narrow it by half, then to the middle)
function LayLane( NavigationPoint N )
{
	local vector From, Right, HitL, HitN, Spot;
	local float Off, R;
	local int i;

	LanePrevNode = LaneNode;
	LaneNode = N;
	bLane = false;
	if( LanePrevNode!=None )
		From = LanePrevNode.Location;
	else From = Pawn.Location;
	LaneDir = N.Location - From;
	LaneDir.Z = 0;
	if( VSize(LaneDir)<1 )
		Return;
	LaneDir = Normal(LaneDir);
	Right.X = -LaneDir.Y;
	Right.Y = LaneDir.X;
	R = Pawn.CollisionRadius;
	Off = RiotLane;
	if( Abs(Off)<0.5*R )
		Return;
	if( Off>0 )
		Spot = N.Location + Right * (Off + R + 8);
	else Spot = N.Location + Right * (Off - R - 8);
	if( Trace(HitL, HitN, Spot, N.Location, false)!=None )
	{
		if( Off>0 )
			Off = FMax(0, VSize(HitL - N.Location) - R - 8);
		else Off = -FMax(0, VSize(HitL - N.Location) - R - 8);
	}
	for( i=0; i<2 && Abs(Off)>=0.5*R; i++ )
	{
		Spot = N.Location + Right * Off;
		if( FloorUnder(Spot) && FastTrace(Spot, Pawn.Location) )
		{
			LanePoint = Spot;
			bLane = true;
			Return;
		}
		Off *= 0.5;
	}
}

// Its lane on the way straight to Goal, looked at afresh every quarter second: Goal moved across by its place,
// if the way there is clear
function DirectLane( vector Goal )
{
	local vector Dir, Right, Spot;

	if( LaneNode==None && Level.TimeSeconds<NextDirectLane )
		return;
	LaneNode = None;
	NextDirectLane = Level.TimeSeconds + 0.25;
	bLane = false;
	if( Abs(RiotLane)<0.5*Pawn.CollisionRadius )
		return;
	Dir = Goal - Pawn.Location;
	Dir.Z = 0;
	if( VSize(Dir)<1 )
		return;
	Dir = Normal(Dir);
	Right.X = -Dir.Y;
	Right.Y = Dir.X;
	Spot = Goal + Right * RiotLane;
	if( FastTrace(Spot, Pawn.Location) )
	{
		LanePoint = Spot;
		bLane = true;
	}
}

function bool FloorUnder( vector Spot )
{
	local vector HitL, HitN;

	return Trace(HitL, HitN, Spot - vect(0,0,150), Spot, false)!=None;
}

// Level with its node: the next node of its route becomes its goal, if it is in a straight line from here,
// else it goes to the node itself
function NextLegNode()
{
	local int i;
	local NavigationPoint Next;

	for( i=0; i<ArrayCount(RouteCache)-1; i++ )
		if( RouteCache[i]==MoveTarget )
			break;
	if( i<ArrayCount(RouteCache)-1 )
		Next = NavigationPoint(RouteCache[i+1]);
	if( Next!=None && PlainNode(Next) && Abs(Next.Location.Z - Pawn.Location.Z)<150 && FastTrace(Next.Location, Pawn.Location) )
	{
		MoveTarget = Next;
		MoveTimer = VSize(Next.Location - Pawn.Location) / FMax(Pawn.GroundSpeed, 1) + 1.0;
	}
	else bLane = false;
}

// Where E will be when this specimen, moving at Speed, gets there: E's ground velocity times the time to get there
// (worked out twice, the second time to the first answer), scaled by Share, the time at most MaxTime seconds.
// E's own place when a wall stands in E's way or this specimen's.
final function vector InterceptSpot( Pawn E, float Speed, float MaxTime, float Share )
{
	local vector Flat, Gap, Spot;
	local float T;
	local int i;

	Spot = E.Location;
	Flat = E.Velocity;
	Flat.Z = 0;
	if( Speed<=0 || Share<=0 || VSize(Flat)<10 )
		Return Spot;
	for( i=0; i<2; i++ )
	{
		Gap = Spot - Pawn.Location;
		Gap.Z = 0;
		T = FMin(MaxTime, VSize(Gap)/Speed);
		Spot = E.Location + Flat*(T*Share);
	}
	if( !FastTrace(Spot,E.Location) || !FastTrace(Spot,Pawn.Location) )
		Return E.Location;
	Return Spot;
}
function FightEnemy(bool bCanCharge)
{
	if( KFM.bShotAnim )
	{
		GoToState('WaitForAnim');
		Return;
	}
	if (KFM.MeleeRange != KFM.default.MeleeRange)
		KFM.MeleeRange = KFM.default.MeleeRange;

	if ( Enemy == none || Enemy.Health <= 0 )
		FindNewEnemy();

	if ( (Enemy == FailedHuntEnemy) && (Level.TimeSeconds == FailedHuntTime) )
	{
	//	if ( Enemy.Controller.bIsPlayer )
		//	FindNewEnemy();

		if ( Enemy == FailedHuntEnemy )
		{
                        GoalString = "FAILED HUNT - HANG OUT";
			if ( EnemyVisible() )
				bCanCharge = false;
		}
	}
	if ( !EnemyVisible() )
	{
		GoalString = "Hunt";
		GotoState('ZombieHunt');
		return;
	}

	// see enemy - decide whether to charge it or strafe around/stand and fire
	Target = Enemy;
	GoalString = "Charge";
	PathFindState = 2;
	DoCharge();
}

state ZombieRoam extends Roaming
{
	function Timer()
	{
		if(Pawn.Velocity == vect(0,0,0))
			GotoState('ZombieRestFormation','Moving');
	}
}

state ZombieHunt extends Hunting
{
	function BeginState()
	{
		local float ZDif;

		if( Pawn.CollisionRadius>27 || Pawn.CollisionHeight>46 )
		{
			ZDif = Pawn.CollisionHeight-44;
			Pawn.SetCollisionSize(24,44);
			Pawn.MoveSmooth(vect(0,0,-1)*ZDif);
			bHuntSqueezed = True;
		}
	}
	function EndState()
	{
		local float ZDif;

		// Only what BeginState did is undone. (This used to put any specimen that had squeezed itself for a
		// crowd back to full width there and then, so into whoever stood next to it; and it took the height
		// to move by from the radius.)
		if( bHuntSqueezed && Pawn!=None )
		{
			ZDif = Pawn.Default.CollisionHeight-Pawn.CollisionHeight;
			Pawn.MoveSmooth(vect(0,0,1)*ZDif);
			Pawn.SetCollisionSize(Pawn.Default.CollisionRadius,Pawn.Default.CollisionHeight);
		}
		bHuntSqueezed = False;
	}
	function Timer()
	{
		if(Pawn.Velocity == vect(0,0,0))
		{
			if( bStallDropsFirstStop && PathFindState==1 )
				PathFindState = 2;
			GotoState('ZombieRestFormation','Moving');
		}
		SetCombatTimer();
		StopFiring();
	}
	function PickDestination()
	{
		local vector nextSpot, ViewSpot,Dir;
		local float posZ;
		local bool bCanSeeLastSeen;

		if( FindFreshBody() )
			Return;
		if ( (Enemy != None) && !KFM.bCannibal && (Enemy.Health <= 0) )
		{
			Enemy = None;
			WhatToDoNext(23);
			return;
		}
		if( PathFindState==0 )
		{
			InitialPathGoal = FindRandomDest();
			PathFindState = 1;
		}
		if( PathFindState==1 )
		{
			if( InitialPathGoal==None )
				PathFindState = 2;
			else if( ActorReachable(InitialPathGoal) )
			{
				MoveTarget = InitialPathGoal;
				PathFindState = 2;
				Return;
			}
			else if( FindBestPathToward(InitialPathGoal, true,true) )
				Return;
			else PathFindState = 2;
		}

		if( KFM.Intelligence==BRAINS_Retarded && FRand()<0.25 )
		{
			Destination = Pawn.Location+VRand()*200;
			Return;
		}
		// (no enemy left to hunt: the rest of this reads where it was)
		if ( Enemy == None )
		{
			WanderOrCamp(false);
			return;
		}
		if ( ActorReachable(Enemy) )
		{
			Destination = Enemy.Location;
			if( KFM.Intelligence==BRAINS_Retarded && FRand()<0.5 )
			{
				Destination+=VRand()*50;
				Return;
			}
			MoveTarget = None;
			return;
		}

        ViewSpot = Pawn.Location + Pawn.BaseEyeHeight * vect(0,0,1);
        bCanSeeLastSeen = bEnemyInfoValid && FastTrace(LastSeenPos, ViewSpot);

        if ( FindBestPathToward(Enemy, true,true) )
            return;

        if ( bSoaking && (Physics != PHYS_Falling) )
            SoakStop("COULDN'T FIND PATH TO ENEMY "$Enemy);

        MoveTarget = None;
        if ( !bEnemyInfoValid )
        {
            Enemy = None;
			WanderOrCamp(false);
            //GotoState('StakeOut');
            return;
        }

        Destination = LastSeeingPos;
        bEnemyInfoValid = false;
        if ( FastTrace(Enemy.Location, ViewSpot)
            && VSize(Pawn.Location - Destination) > Pawn.CollisionRadius )
            {
                SeePlayer(Enemy);
                return;
            }

        posZ = LastSeenPos.Z + Pawn.CollisionHeight - Enemy.CollisionHeight;
        nextSpot = LastSeenPos - Normal(Enemy.Velocity) * Pawn.CollisionRadius;
        nextSpot.Z = posZ;
        if ( FastTrace(nextSpot, ViewSpot) )
            Destination = nextSpot;
        else if ( bCanSeeLastSeen )
        {
            Dir = Pawn.Location - LastSeenPos;
            Dir.Z = 0;
            if ( VSize(Dir) < Pawn.CollisionRadius )
            {
                Destination = Pawn.Location+VRand()*500;
                return;
            }
            Destination = LastSeenPos;
        }
        else
        {
            Destination = LastSeenPos;
            if ( !FastTrace(LastSeenPos, ViewSpot) )
            {
                // check if could adjust and see it
                if ( PickWallAdjust(Normal(LastSeenPos - ViewSpot)) || FindViewSpot() )
                {
                    if ( Pawn.Physics == PHYS_Falling )
                        SetFall();
                    else
                        GotoState('Hunting', 'AdjustFromWall');
                }
                else
                {
                    Destination = Pawn.Location+VRand()*500;
                    return;
                }
            }
        }
    }
}

state ZombieCharge extends Charging
{
ignores SeePlayer, HearNoise;

	function DamageAttitudeTo(Pawn Other, float Damage)
	{
		if( KFM.Intelligence>=BRAINS_Mammal && Other!=None && SetEnemy(Other) )
			SetEnemy(Other);
	}
	function bool StrafeFromDamage(float Damage, class<DamageType> DamageType, bool bFindDest)
	{
		return false;
	}

	// I suspect this function causes bloats to get confused
	function bool TryStrafe(vector sideDir)
	{
		return false;
	}

Begin:
	if (Pawn.Physics == PHYS_Falling)
	{
		Focus = Enemy;
		Destination = Enemy.Location;
		WaitForLanding();
	}
	if ( Enemy == None )
		WhatToDoNext(16);
WaitForAnim:
	While( KFM.bShotAnim )
		Sleep(0.35);
	if ( !FindBestPathToward(Enemy, false,true) )
		GotoState('TacticalMove');
Moving:
	if( KFM.Intelligence==BRAINS_Retarded )
	{
		if( FRand()<0.3 )
			MoveTo(Pawn.Location+VRand()*200,None);
		else if( MoveTarget==Enemy && FRand()<0.5 )
			MoveTo(MoveTarget.Location+VRand()*50,None);
		else MoveToward(MoveTarget,FaceActor(1),,ShouldStrafeTo(MoveTarget));
	}
	else MoveToward(MoveTarget,FaceActor(1),,ShouldStrafeTo(MoveTarget));
	WhatToDoNext(17);
	if ( bSoaking )
		SoakStop("STUCK IN CHARGING!");
}


function CheckIfShouldCrouch(vector StartPosition, vector TargetPosition, float probability);

//function InitializeSkill(float InSkill);

//function ResetSkill();

// Randomize their speeds a bit.
function SetMaxDesiredSpeed()
{
	Pawn.MaxDesiredSpeed = 0.9+FRand()*0.2;
}

function SetPeripheralVision();

// Add to BossZombieController — helper to teleport boss to a random ZombieVolume
function bool TeleportBackIn()
{
    local array<ZombieVolume> Volumes;
    local ZombieVolume ZV;
    local int i;
    local vector TeleLoc;

    // Gather all valid zombie volumes
    foreach AllActors(class'ZombieVolume', ZV)
    {
        if ( ZV != None && !ZV.PhysicsVolume.bWaterVolume
             && VSize(ZV.Location - Pawn.Location) > 500 )
            Volumes[Volumes.Length] = ZV;
    }
    if ( Volumes.Length == 0 )
        return false;

    // Try a few random ones until we find one that works
    for ( i = 0; i < 5; i++ )
    {
        ZV = Volumes[Rand(Volumes.Length)];
        TeleLoc = ZV.Location;
        TeleLoc.Z += Pawn.CollisionHeight;
        if ( Pawn.SetLocation(TeleLoc) )
            return true;
    }
    return false;
}

// TODO: zombies commit suicide. Is this right that they do so?
function bool FindRoamDest()
{
	local actor BestPath;

	if ( Pawn.FindAnchorFailedTime == Level.TimeSeconds )
	{
		// couldn't find an anchor.
		GoalString = "No anchor "$Level.TimeSeconds;
		if ( Pawn.LastValidAnchorTime > 5 )
		{
			if ( bSoaking )
				SoakStop("NO PATH AVAILABLE!!!");
			else
			{
				if ( NumRandomJumps > 10 || PhysicsVolume.bWaterVolume )
				{
					if(TeleportBackIn() && KFMonster(Pawn).bBoss)
						return true;
					else 
					{
						Pawn.Health = 0;
						Pawn.Died( self, class'Suicided', Pawn.Location );
						return true;
					}
				}
                else
                {
                    // jump
                    NumRandomJumps++;
                    if ( Physics != PHYS_Falling )
                    {
                        Pawn.SetPhysics(PHYS_Falling);
                       // Pawn.Velocity = 0.5 * Pawn.GroundSpeed * VRand();
                        Pawn.Velocity.Z = Pawn.JumpZ;
                    }
                }
            }
        }
        //log(self$" Find Anchor failed!");
        return false;
    }
    NumRandomJumps = 0;
    GoalString = "Find roam dest "$Level.TimeSeconds;
    // find random NavigationPoint to roam to
    if ( (RouteGoal == None) || (Pawn.Anchor == RouteGoal)
        || Pawn.ReachedDestination(RouteGoal) )
    {
        RouteGoal = FindRandomDest();
        BestPath = RouteCache[0];
        if ( RouteGoal == None )
        {
            if ( bSoaking && (Physics != PHYS_Falling) )
                SoakStop("COULDN'T FIND ROAM DESTINATION");
            return false;
        }
    }
    if ( BestPath == None )
        BestPath = FindPathToward(RouteGoal,false);
    if ( BestPath != None )
    {
        MoveTarget = BestPath;
        GotoState('ZombieRoam');
        return true;
    }
    if ( bSoaking && (Physics != PHYS_Falling) )
        SoakStop("COULDN'T FIND ROAM PATH TO "$RouteGoal);
    RouteGoal = None;
    return false;
}

function DirectedWander(vector WanderDir)
{
	GoalString = "DIRECTED WANDER "$GoalString;
	if ( TestDirection(WanderDir,Destination) )
		GotoState('ZombieRestFormation', 'Moving');
	else GotoState('ZombieRestFormation', 'Begin');
}

function WanderOrCamp(bool bMayCrouch)
{
	if( KFM.bNoAutoHuntEnemies )
		GoToState('WaitToStart');
	else FindRoamDest();
}

state ZombieRestFormation extends RestFormation
{
ignores EnemyNotVisible;

	function CancelCampFor(Controller C)
	{
		DirectedWander(Normal(Pawn.Location - C.Pawn.Location));
	}

	function bool Formation()
	{
		return true;
	}
	function Timer()
	{
		if(VSize(Pawn.Velocity) <= 0.f)
			Gotostate('ZombieRestFormation','Moving');
		SetCombatTimer();
		disable('NotifyBump');
	}
	function PickDestination()
	{
		local vector nextSpot, ViewSpot,Dir;
		local float posZ;
		local bool bCanSeeLastSeen;

		if ( TestDirection(VRand(),Destination) )
		{
			// If we're not a cannibal.  dont munch
			if ( (Enemy != None) && !KFM.bCannibal && (Enemy.Health <= 0) )
			{
				Enemy = None;
				WhatToDoNext(23);
				return;
			}

			if ( Enemy!=None && ActorReachable(Enemy) )
			{
				Destination = Enemy.Location;
				MoveTarget = None;
				return;
			}

			ViewSpot = Pawn.Location + Pawn.BaseEyeHeight * vect(0,0,1);
			bCanSeeLastSeen = bEnemyInfoValid && FastTrace(LastSeenPos, ViewSpot);

			if ( Enemy!=None && FindBestPathToward(Enemy, true,true) )
				return;

			if ( bSoaking && (Physics != PHYS_Falling) )
				SoakStop("COULDN'T FIND PATH TO ENEMY "$Enemy);

			MoveTarget = None;
			if ( Enemy==None || !bEnemyInfoValid )
			{
				Enemy = None;
				WhatToDoNext(26);
				return;
			}

			Destination = LastSeeingPos;
			bEnemyInfoValid = false;
			if ( FastTrace(Enemy.Location, ViewSpot) && VSize(Pawn.Location - Destination) > Pawn.CollisionRadius )
			{
				SeePlayer(Enemy);
				return;
			}

			posZ = LastSeenPos.Z + Pawn.CollisionHeight - Enemy.CollisionHeight;
			nextSpot = LastSeenPos - Normal(Enemy.Velocity) * Pawn.CollisionRadius;
			nextSpot.Z = posZ;
			if ( FastTrace(nextSpot, ViewSpot) )
				Destination = nextSpot;
			else if ( bCanSeeLastSeen )
			{
				Dir = Pawn.Location - LastSeenPos;
				Dir.Z = 0;
				if ( VSize(Dir) < Pawn.CollisionRadius )
				{
					GoalString = "Stakeout 3 from hunt";
					GotoState('StakeOut');
					return;
				}
				Destination = LastSeenPos;
			}
			else
			{
				Destination = LastSeenPos;
				if ( !FastTrace(LastSeenPos, ViewSpot) )
				{
					// check if could adjust and see it
					if ( PickWallAdjust(Normal(LastSeenPos - ViewSpot)) || FindViewSpot() )
					{
						if ( Pawn.Physics == PHYS_Falling )
							SetFall();
						else
							GotoState('Hunting', 'AdjustFromWall');
					}
					else
					{
						GoalString = "Stakeout 2 from hunt";
						GotoState('StakeOut');
						return;
					}
				}
			}
		}
		else TestDirection(VRand(),Destination);
	}

    function BeginState()
    {
       // Enemy = None;
        //Pawn.bAvoidLedges = true;
        //Pawn.bStopAtLedges = true;
        //Pawn.SetWalking(true);
        MinHitWall += 0.15;
    }



    function EndState()
    {
        //MonitoredPawn = None;
        MinHitWall -= 0.15;
    }

	function bool FindViewSpot()
	{
		local vector X,Y,Z;

		GetAxes(Rotation,X,Y,Z);

		// try left and right

		if ( Enemy!=None && FastTrace(Enemy.Location, Pawn.Location + 2 * Y * Pawn.CollisionRadius) )
		{
			Destination = Pawn.Location + 2.5 * Y * Pawn.CollisionRadius;
			return true;
		}

		if ( Enemy!=None && FastTrace(Enemy.Location, Pawn.Location - 2 * Y * Pawn.CollisionRadius) )
		{
			Destination = Pawn.Location - 2.5 * Y * Pawn.CollisionRadius;
			return true;
		}
		if ( FRand() < 0.5 )
			Destination = Pawn.Location - 2.5 * Y * Pawn.CollisionRadius;
		else
			Destination = Pawn.Location + 2.5 * Y * Pawn.CollisionRadius;
		return true;
	}

    event MonitoredPawnAlert()
    {
        WhatToDoNext(6);
    }

Begin:
    WaitForLanding();
Camping:
    //Pawn.Acceleration = vect(0,0,0);
    Focus = None;
    FocalPoint = VRand();
    NearWall(MINVIEWDIST);
    FinishRotation();
    Sleep(3 + FRand());
Moving:
//    WaitForLanding();
    PickDestination();
WaitForAnim:
    if ( KFM.bShotAnim )
    {
        Sleep(0.5);
        Goto('WaitForAnim');
    }
    MoveTo(Destination,,true);
    if ( Pawn.bCanFly && (Physics == PHYS_Walking) )
        SetPhysics(PHYS_Flying);
    WhatToDoNext(8);
    Goto('Begin');
}

state DoorBashing extends MoveToGoalNoEnemy
{
ignores EnemyNotVisible,SeeMonster;

	function Timer()
	{
		Disable('NotifyBump');
	}

	function AttackDoor()
	{
		Target = TargetDoor;
		KFM.DoorAttack(Target);
	}
	function SeePlayer( Pawn Seen )
	{
		if( KFM.Intelligence==BRAINS_Human && ActorReachable(Seen) && SetEnemy(Seen) )
			WhatToDoNext(23);
	}
	function DamageAttitudeTo(Pawn Other, float Damage)
	{
		if( KFM.Intelligence>=BRAINS_Mammal && Other!=None && ActorReachable(Other) && SetEnemy(Other) )
			WhatToDoNext(32);
	}
	function HearNoise(float Loudness, Actor NoiseMaker)
	{
		if( KFM.Intelligence==BRAINS_Human && NoiseMaker!=None && NoiseMaker.Instigator!=None
		 && ActorReachable(NoiseMaker.Instigator) && SetEnemy(NoiseMaker.Instigator) )
			WhatToDoNext(32);
	}

Begin:
	WaitForLanding();

KeepMoving:
	//MoveTarget = TargetDoor;
	//if(MoveTarget!=none)
	//	MoveToward(MoveTarget,FaceActor(1),,false ); //,GetDesiredOffset(),ShouldStrafeTo(MoveTarget));

	While( KFM.bShotAnim )
		Sleep(0.25);
	While( TargetDoor!=none && !TargetDoor.bHidden && TargetDoor.bSealed && !TargetDoor.bZombiesIgnore )
	{
		AttackDoor();
		While( KFM.bShotAnim )
			Sleep(0.25);
		Sleep(0.1);
		if( KFM.Intelligence>=BRAINS_Mammal && Enemy!=None && ActorReachable(Enemy) )
			WhatToDoNext(14);
	}
	WhatToDoNext(152);

Moving:
	MoveToward(TargetDoor);
	WhatToDoNext(17);
	if ( bSoaking )
		SoakStop("STUCK IN CHARGING!");
}


state BarricadeBashing extends MoveToGoalNoEnemy
{
ignores EnemyNotVisible,SeeMonster;

	function BeginState()
	{
		Disable('NotifyBump');
		Focus = TargetPlank;
		Pawn.Acceleration = Vect(0,0,0);
	}

	function Timer()
	{
		Disable('NotifyBump');
	}

	function AttackPlank()
	{
		Target = TargetPlank;
		KFM.DoorAttack(Target);
	}
	function SeePlayer( Pawn Seen )
	{
		if( KFM.Intelligence==BRAINS_Human && ActorReachable(Seen) && SetEnemy(Seen) )
			WhatToDoNext(23);
	}
	function DamageAttitudeTo(Pawn Other, float Damage)
	{
		if( KFM.Intelligence>=BRAINS_Mammal && Other!=None && ActorReachable(Other) && SetEnemy(Other) )
			WhatToDoNext(32);
	}
	function HearNoise(float Loudness, Actor NoiseMaker)
	{
		if( KFM.Intelligence==BRAINS_Human && NoiseMaker!=None && NoiseMaker.Instigator!=None
		 && ActorReachable(NoiseMaker.Instigator) && SetEnemy(NoiseMaker.Instigator) )
			WhatToDoNext(32);
	}

Begin:
	WaitForLanding();

KeepMoving:
	MoveTarget = None;
	While( KFM.bShotAnim )
	{
		Pawn.Acceleration = Vect(0,0,0);
		Sleep(0.25);
	}
	While( TargetPlank!=none && !TargetPlank.bHidden && !TargetPlank.bDestroyed )
	{
		AttackPlank();
		While( KFM.bShotAnim )
		{
			Pawn.Acceleration = Vect(0,0,0);
			Sleep(0.25);
		}
		Pawn.Acceleration = Vect(0,0,0);
		Sleep(0.1);
		if( KFM.Intelligence>=BRAINS_Mammal && Enemy!=None && ActorReachable(Enemy) )
			WhatToDoNext(14);
	}
	WhatToDoNext(152);

Moving:
	MoveToward(TargetPlank);
	WhatToDoNext(17);
	if ( bSoaking )
		SoakStop("STUCK IN CHARGING!");
}


state CorpseFeeding
{
ignores EnemyNotVisible,SeePlayer,HearNoise,NotifyBump;

	function Timer()
	{
		Target = TargetCorpse;
		if(Target == none)
			WhatToDoNext(38);
	}
	function AttackCorpse()
	{
		Target = TargetCorpse;
		KFM.CorpseAttack(Target);
	}

Begin:
	WaitForLanding();
	While( TargetCorpse!=None && !ActorReachable(TargetCorpse) )
	{
		if( !FindBestPathToward(TargetCorpse,True,False) )
			WhatToDoNext(33);
		MoveToward(MoveTarget,MoveTarget);
	}
	if( TargetCorpse==None )
		WhatToDoNext(32);
	MoveTo(TargetCorpse.Location+Normal(Pawn.Location-TargetCorpse.Location)*(20+FRand()*20),TargetCorpse);
	if( TargetCorpse==None )
		WhatToDoNext(31);
	Focus = TargetCorpse;
	While( TargetCorpse!=None && (Pawn.Health<(Pawn.Default.Health*1.5) || Level.Game.bGameEnded) )
	{
		AttackCorpse();
		While( KFM.bShotAnim )
			Sleep(0.1);
		if( Enemy!=None && VSize(Enemy.Location-Pawn.Location)<500 && CanSee(Enemy) )
			WhatToDoNext(37); // Can't look, eating.
	}
	WhatToDoNext(30);
}

function HearNoise(float Loudness, Actor NoiseMaker)
{
	if( NoiseMaker!=none && FastTrace(NoiseMaker.Location,Pawn.Location) )
	{
		if ( ((ChooseAttackCounter < 2) || (ChooseAttackTime != Level.TimeSeconds)) && SetEnemy(NoiseMaker.instigator) )
			WhatToDoNext(2);
	}
}

state Kicking
{
  ignores EnemyNotVisible;

  Begin:


  WaitForAnim:
	if ( KFM.bShotAnim )
	{
	      if(KickTarget!=none)
              {
               //MoveToward(KickTarget,FaceActor(1),,false ); //,GetDesiredOffset(),ShouldStrafeTo(MoveTarget));
               Sleep(0.1);
	       Goto('WaitForAnim');
	      }
	}


	WhatToDoNext(152);
	if ( bSoaking )
		SoakStop("STUCK IN KICKING!!!");
}

state KnockDown
{
  ignores EnemyNotVisible;

  Begin:
  Pawn.ShouldCrouch(True);


  WaitForAnim:
	if ( KFM.bShotAnim )
	{
               Sleep(0.1);

	       Goto('WaitForAnim');
	}


	WhatToDoNext(152);
	if ( bSoaking )
		SoakStop("STUCK IN STAGGERED!!!");
		
 End:
  Pawn.ShouldCrouch(False);

}


function ExecuteWhatToDoNext()
{
	if (PendingMover != None && Pawn != None && Pawn.Base == PendingMover && !PendingMover.bInterpolating)
	{
		PendingMover = None;
		bPreparingMove = false;
	}

	bHasFired = false;
	GoalString = "WhatToDoNext at "$Level.TimeSeconds;
	if ( Pawn == None )
	{
		warn(GetHumanReadableName()$" WhatToDoNext with no pawn");
		return;
	}
	if( KFM.bStartUpDisabled )
	{
		KFM.bStartUpDisabled = False;
		GoToState('WaitToStart');
		Return;
	}
	if( KFM.bShotAnim )
	{
		GoToState('WaitForAnim');
		Return;
	}
	if( Level.Game.bGameEnded && FindFreshBody() )
		Return;
	if (Pawn.Physics == PHYS_None)
		Pawn.SetMovementPhysics();
	if ( (Pawn.Physics == PHYS_Falling) && DoWaitForLanding() )
		return;
	if ( (Enemy != None) && ((Enemy.Health <= 0) || (Enemy.Controller == None)) )
		Enemy = None;

	if ( (Enemy == None) || !EnemyVisible() )
		FindNewEnemy();

	if ( Enemy != None )
		ChooseAttackMode();
	else
	{
		GoalString = "WhatToDoNext Wander or Camp at "$Level.TimeSeconds;
		WanderOrCamp(true);
	}
}

// (bWarnShotTarget) As a bot's shots do, a specimen's projectile warns the pawn it is aimed at: Projectile.PostBeginPlay warns
// its shooter's ShotTarget, which the stock monster aim never set, so no bot ever sidestepped a Patriarch's rocket
function rotator AdjustAim(FireProperties FiredAmmunition, vector projStart, int aimerror)
{
	// (only a living pawn its controller still has: a body left behind, or a campaign soldier's AI after its death, is not warned)
	if ( bWarnShotTarget && Pawn(Target)!=None && Pawn(Target).Health>0 && Pawn(Target).Controller!=None && Pawn(Target).Controller.Pawn==Target )
		ShotTarget = Pawn(Target);
	else if ( bWarnShotTarget )
		ShotTarget = None;
	return Super.AdjustAim(FiredAmmunition, projStart, aimerror);
}

state StakeOut
{
ignores EnemyNotVisible;

	/* DoStakeOut()
	called by ChooseAttackMode - if called in this state, means stake out twice in a row
	*/
	function DoStakeOut()
	{
		SetFocus();
		if ( Enemy!=None && ((FRand() < 0.3) || !FastTrace(FocalPoint + vect(0,0,0.9) * Enemy.CollisionHeight, Pawn.Location + vect(0,0,0.8) * Pawn.CollisionHeight)) )
			FindNewStakeOutDir();
		GotoState('StakeOut','Begin');
	}

	function rotator AdjustAim(FireProperties FiredAmmunition, vector projStart, int aimerror)
	{
		local vector FireSpot;
		local actor HitActor;
		local vector HitLocation, HitNormal;

		if( Enemy==None )
			Return Pawn.Rotation;

		FireSpot = FocalPoint;

		HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
		if( HitActor != None )
		{
			FireSpot += 2 * Enemy.CollisionHeight * HitNormal;
			if ( !FastTrace(FireSpot, ProjStart) )
			{
				FireSpot = FocalPoint;
				StopFiring();
			}
		}

		SetRotation(Rotator(FireSpot - ProjStart));
		return Rotation;
	}
	function BeginState()
	{
		StopStartTime = Level.TimeSeconds;
		Pawn.Acceleration = vect(0,0,0);
		Pawn.bCanJump = false;
		SetFocus();
		if ( Enemy!=None && (!bEnemyInfoValid || !ClearShot(FocalPoint,false) || ((Level.TimeSeconds - LastSeenTime > 6) && (FRand() < 0.5))) )
			FindNewStakeOutDir();
	}
	function SetFocus()
	{
		if ( bEnemyInfoValid )
			FocalPoint = LastSeenPos;
		else if( Enemy!=None )
			FocalPoint = Enemy.Location;
	}

Begin:
	Pawn.Acceleration = vect(0,0,0);
	Focus = None;
	CheckIfShouldCrouch(Pawn.Location,FocalPoint, 1);
	FinishRotation();
	if ( Enemy!=None && KFM.HasRangedAttack() && (FRand() < 0.5) && (VSize(Enemy.Location - FocalPoint) < 150)
		 && (Level.TimeSeconds - LastSeenTime < 4) && ClearShot(FocalPoint,true) )
		FireWeaponAt(Enemy);
	else StopFiring();
	Sleep(0.4 + FRand()*0.4);
	// check if uncrouching would help
	if ( Pawn.bIsCrouched
		&& !FastTrace(FocalPoint, Pawn.Location + Pawn.EyeHeight * vect(0,0,1))
		&& FastTrace(FocalPoint, Pawn.Location + (Pawn.Default.EyeHeight + Pawn.Default.CollisionHeight - Pawn.CollisionHeight) * vect(0,0,1)) )
	{
		Pawn.bWantsToCrouch = false;
		Sleep(0.4 + FRand()*0.4);
	}
	WhatToDoNext(31);
	if ( bSoaking )
		SoakStop("STUCK IN STAKEOUT!");
}

State WaitForAnim
{
Ignores SeePlayer,HearNoise,Timer,EnemyNotVisible,NotifyBump;

	function BeginState()
	{
		bUseFreezeHack = False;
	}
	function Tick( float Delta )
	{
		Global.Tick(Delta);
		if( bUseFreezeHack )
		{
			MoveTarget = None;
			MoveTimer = -1;
			Pawn.Acceleration = vect(0,0,0);
			Pawn.GroundSpeed = 1;
			Pawn.AccelRate = 0;
		}
	}
	function EndState()
	{
		if( Pawn!=None )
		{
			Pawn.AccelRate = Pawn.Default.AccelRate;
			if( KFMonster(Pawn)!=None )
				Pawn.GroundSpeed = KFMonster(Pawn).OriginalGroundSpeed;
			else
				Pawn.GroundSpeed = Pawn.Default.GroundSpeed;
		}
		bUseFreezeHack = False;
	}

Begin:
	While( KFM.bShotAnim )
		Sleep(0.15);
	WhatToDoNext(99);
}

function bool SetEnemy( Pawn NewEnemy, optional bool bHateMonster )
{
	if( KFHumanPawnZombies(NewEnemy)!=None && KFHumanPawnZombies(NewEnemy).bIsDowned )
		Return False; // Ignore downed players waiting on a revive.
	if( !bHateMonster && KFMonster(NewEnemy)!=None )
		Return False; // A player's specimen in Versus is one of us.
	if( !bHateMonster && KFHumanPawnEnemy(NewEnemy)!=None && KFHumanPawnEnemy(NewEnemy).AttitudeToSpecimen<=ATTITUDE_Ignore )
		Return False; // In other words, dont attack human pawns as long as they dont damage me or hates me.
	if( KFM.Intelligence>=BRAINS_Mammal && Enemy!=None && NewEnemy!=None && NewEnemy!=Enemy && NewEnemy.Controller!=None && NewEnemy.Controller.bIsPlayer )
	{
		if( LineOfSightTo(Enemy) && VSize(Enemy.Location-Pawn.Location)<VSize(NewEnemy.Location-Pawn.Location) )
			Return False;
		Enemy = None;
	}
	if( bHateMonster && KFMonster(NewEnemy)!=None && NewEnemy.Controller!=None && (NewEnemy.Controller.Target==Self || FRand()<0.35)
	 && NewEnemy.Health>0 && VSize(NewEnemy.Location-Pawn.Location)<1500 && LineOfSightTo(NewEnemy) ) // Get pissed at this fucker..
	{
		ChangeEnemy(NewEnemy,CanSee(NewEnemy));
		return true;
	}
	if( Super.SetEnemy(NewEnemy,bHateMonster) )
	{
		if( !bTriggeredFirstEvent )
		{
			bTriggeredFirstEvent = True;
			if( KFM.FirstSeePlayerEvent!='' )
				TriggerEvent(KFM.FirstSeePlayerEvent,Pawn,Pawn);
		}
		Return True;
	}
	Return False;
}
function Celebrate();

State WaitToStart
{
Ignores Tick,Timer,FindNewEnemy,NotifyLanded,DoWaitForLanding;

	function Trigger( actor Other, pawn EventInstigator )
	{
		SetEnemy(EventInstigator,True);
		WhatToDoNext(56);
	}
	function bool SetEnemy( Pawn NewEnemy, optional bool bHateMonster )
	{
		if( Level.TimeSeconds<1 )
			Return False;
		Return Global.SetEnemy(NewEnemy,bHateMonster);
	}
	function EndState()
	{
		if( Pawn.Health>0 )
		{
			if( !bTriggeredFirstEvent )
			{
				bTriggeredFirstEvent = True;
				if( KFM.FirstSeePlayerEvent!='' )
					TriggerEvent(KFM.FirstSeePlayerEvent,Pawn,Pawn);
			}
			Pawn.AmbientSound = Pawn.Default.AmbientSound;
		}
	}
Begin:
	Pawn.AmbientSound = None;
	Enemy = None;
	Focus = None;
	FocalPoint = Pawn.Location+vector(Pawn.Rotation)*5000;
	Pawn.Acceleration = vect(0,0,0);
}

function Trigger( actor Other, pawn EventInstigator )
{
	if( SetEnemy(EventInstigator,True) )
		WhatToDoNext(54);
}

defaultproperties
{
	bWarnShotTarget=True
	bStallDropsFirstStop=True
	RiotRow=-1
	RiotReleaseDist=700.000000
	RiotAheadSlack=60.000000
	RiotEaseSpeed=0.600000
	MoanGapMin=8.000000
	MoanGapMax=18.000000
	StrafingAbility=0.000000
	CombatStyle=1.000000
	ReactionTime=1.000000
	MyFloor=255
	StrandedDelay=10.000000
	WedgeDelay=4.000000
	AnchorlessDelay=10.000000
}
