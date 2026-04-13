class KFMonsterController extends MonsterController;
// Custom Zombie Thinkerating
// By : Alex

var KFMonster KFM;

var int MoanTime,ThreatTime;
var bool ItsSet,bUseFreezeHack,bAboutToGetDoor,bTriggeredFirstEvent;
var int TimeToSet;
var int EvaluateTime;
var float ChargeStart,LastCorpseTime;
var byte NumAttmpts;
var byte CorpseBiteCount;

var KFDoorMover TargetDoor;
var PlayerDeathMark TargetCorpse;
var KActor KickTarget;

var Actor InitialPathGoal;
var byte PathFindState;

// Used for alternative pathing:
var Actor LastResult;
var NavigationPoint BlockedWay,ExtraCostWay;
var float BlockedWayTime;

function Restart()
{
	KFM = KFMonster(Pawn);
	if( !KFM.bStartUpDisabled )
		Super.Restart();
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
	MoanTime = Level.TimeSeconds;
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

function BreakUpDoor( KFDoorMover Other ) // I have came up to a door, break it!
{
	TargetDoor = Other;
	GoalString = "DOORBASHING";
	GotoState('DoorBashing');
}

// The Times between each call of the ZombieMoan function ...
function tick(float DeltaTime)
{
	if( Level.TimeSeconds >= MoanTime )
	{
		ZombieMoan();
		MoanTime += (12 + (fRand() * 3));
	}
	if( bAboutToGetDoor )
	{
		bAboutToGetDoor = False;
		if( TargetDoor!=None )
			BreakUpDoor(TargetDoor);
	}
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
	if ( KFM.bCannibal && pawn.Health < (1.0-KFM.FeedThreshold)*pawn.HealthMax || Level.Game.bGameEnded )
	{
		for ( PC=Level.ControllerList; PC!=None; PC=PC.NextController )
		{
			C = KFHumanPawn(PC.Pawn);
			if( C==None || C.Health<=0 )
				Continue;
			NewDist = VSize(C.Location - Pawn.Location);
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
			if ( PC.bIsPlayer && (PC.Pawn!=None) && PC.Pawn.Health>0 )
			{
				NewDist = VSize(PC.Pawn.Location - Pawn.Location);
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

function bool FindBestPathToward(Actor A, bool bCheckedReach, bool bAllowDetour)
{
	local vector Dummy;
	local NavigationPoint CrowdedNode;
	local KFMonster M;
	local int NearbyZeds, CrowdCost;

	RouteCache[1] = None;
	if( A==None )
		Return False; // Shouldn't get to this, but just in case.
	if ( !bCheckedReach && ActorReachable(A) )
		MoveTarget = A;
	else
	{
		// Expire stale blocked node after 5 seconds
		if( BlockedWay!=None && Level.TimeSeconds - BlockedWayTime > 5.0 )
			BlockedWay = None;

		if( BlockedWay!=None )
		{
			BlockedWay.ExtraCost += 10000;
			MoveTarget = FindPathToward(A);
			BlockedWay.ExtraCost -= 10000;
		}
		else MoveTarget = FindPathToward(A);

		if( MoveTarget!=None )
		{
			// Stuck detection: same nav point too many times in a row, mark it blocked
			if( LastResult==MoveTarget && NavigationPoint(MoveTarget)!=None && NumAttmpts > 3 )
			{
				BlockedWay = NavigationPoint(MoveTarget);
				BlockedWayTime = Level.TimeSeconds;
				LastResult = None;
				NumAttmpts = 0;
				return FindBestPathToward(A, True, bAllowDetour);
			}
			else if( LastResult==MoveTarget )
				NumAttmpts++;
			else NumAttmpts = 0;
			LastResult = MoveTarget;

			// Horde avoidance: count zombies near the next nav point
			if( NavigationPoint(MoveTarget)!=None )
			{
				NearbyZeds = 0;
				foreach Pawn.CollidingActors(class'KFMonster', M, 200, MoveTarget.Location)
				{
					if( M != Pawn )
						NearbyZeds++;
				}
				if( NearbyZeds > 3 )
				{
					CrowdedNode = NavigationPoint(MoveTarget);
					CrowdCost = NearbyZeds * 500;
					CrowdedNode.ExtraCost += CrowdCost;
					MoveTarget = FindPathToward(A);
					CrowdedNode.ExtraCost -= CrowdCost;
				}
			}
		}
	}
	if ( MoveTarget!=None )
	{
		if( RouteCache[1]!=None && ActorReachable(RouteCache[1]) )
			MoveTarget = RouteCache[1];
		if( KFM.bCanDistanceAttackDoors )
		{
			A = Trace(Dummy,Dummy,MoveTarget.Location,Pawn.Location,False);
			if( KFDoorMover(A)!=None && KFDoorMover(A).bSealed )
			{
				TargetDoor = KFDoorMover(A);
				bAboutToGetDoor = True;
			}
		}
		return true;
	}
	else
	{
		if ( (A == Enemy) && (A != None) )
		{
			FailedHuntTime = Level.TimeSeconds;
			FailedHuntEnemy = Enemy;
		}
		if ( bSoaking && (Physics != PHYS_Falling) )
			SoakStop("COULDN'T FIND BEST PATH TO "$A);
	}
	return false;
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
		}
	}
	function EndState()
	{
		local float ZDif;

		if( Pawn != none && Pawn.CollisionRadius!=Pawn.Default.CollisionRadius || Pawn.CollisionHeight!=Pawn.Default.CollisionHeight )
		{
			ZDif = Pawn.Default.CollisionRadius-44;
			Pawn.MoveSmooth(vect(0,0,1)*ZDif);
			Pawn.SetCollisionSize(Pawn.Default.CollisionRadius,Pawn.Default.CollisionHeight);
		}
	}
	function Timer()
	{
		if(Pawn.Velocity == vect(0,0,0))
			GotoState('ZombieRestFormation','Moving');
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

		if ( Pawn.JumpZ > 0 )
			Pawn.bCanJump = true;

		if( KFM.Intelligence==BRAINS_Retarded && FRand()<0.25 )
		{
			Destination = Pawn.Location+VRand()*200;
			Return;
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
	function SeePlayer( Pawn Seen )
	{
		if( KFM.Intelligence==BRAINS_Human )
			SetEnemy(Seen);
	}
	function DamageAttitudeTo(Pawn Other, float Damage)
	{
		if( KFM.Intelligence>=BRAINS_Mammal && Other!=None && SetEnemy(Other) )
			SetEnemy(Other);
	}
	function HearNoise(float Loudness, Actor NoiseMaker)
	{
		if( KFM.Intelligence==BRAINS_Human && NoiseMaker.Instigator!=None && FastTrace(NoiseMaker.Location,Pawn.Location) )
			SetEnemy(NoiseMaker.Instigator);
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
				if ( NumRandomJumps > 5 || PhysicsVolume.bWaterVolume )
				{
					if(TeleportBackIn())
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

			if ( Pawn.JumpZ > 0 )
				Pawn.bCanJump = true;

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
        if ( Pawn != None )
        {
            if (Pawn.JumpZ > 0)
                Pawn.bCanJump = true;
        }
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
			Destination = Pawn.Location - 2.5 * Y * Pawn.CollisionRadius;
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
     StrafingAbility=0.000000
     CombatStyle=1.000000
     ReactionTime=1.000000
}
