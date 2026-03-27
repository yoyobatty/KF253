class KFMonsterController extends MonsterController;
// Custom Zombie Thinkerating
// By : Alex

var int MoanTime,ThreatTime;
var bool ItsSet,bUseFreezeHack;
var int TimeToSet;
var int EvaluateTime;
var float ChargeStart,LastCorpseTime;
var byte NumAttmpts;

var KFDoorMover TargetDoor;
var KFHumanPawn TargetCorpse;
var KActor KickTarget;

// Used for alternative pathing:
var Actor LastResult;
var NavigationPoint BlockedWay,ExtraCostWay;

// Randomly plays a different moan sound for the Zombie each time it is called. Gruesome!
function ZombieMoan()
{
	if( Pawn==None || Pawn.Health<=0 )
		Destroy();
	else if( !KFMonster(Pawn).bDecapitated ) // Headless zombies can't moan.
		KFMonster(Pawn).ZombieMoan();
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

function FearThisSpot(AvoidMarker aSpot);

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
}

// If we're not dead, and we can see our target, and we still have a head. lets go eat it.
function bool FindFreshBody()
{
	local KFHumanPawn KF;

	if( LastCorpseTime>Level.TimeSeconds )
		Return False;
	if( KFMonster(pawn).bDecapitated || !KFMonster(pawn).bCannibal || Pawn.Health>=(Pawn.Default.Health*1.5) || (Enemy!=None && LineOfSightTo(Enemy)) )
	{
		LastCorpseTime = Level.TimeSeconds+0.5;
		Return False;
	}
	LastCorpseTime = Level.TimeSeconds+1+FRand()*2;
	ForEach VisibleCollidingActors(Class'KFHumanPawn',KF,800)
	{
		if( KF.Health>0 )
		{
			if( ActorReachable(KF) )
			{
				Enemy = KF;
				Return False;
			}
			else Continue;
		}
		else if( !ActorReachable(KF) )
			Continue;
		TargetCorpse = KF;
		GoalString = "CORPSEFEEDING";
		GotoState('CorpseFeeding');
		Return True;
	}
	Return False;
}

function bool FindNewEnemy()
{
	local Pawn BestEnemy;
	local bool bSeeNew, bSeeBest;
	local float BestDist, NewDist;
	local Controller PC;
	local KFHumanPawn C;

	if ( KFMonster(pawn).bCannibal && pawn.Health < (1.0-KFMonster(pawn).FeedThreshold)*pawn.HealthMax || Level.Game.bGameEnded )
	{
		for ( PC=Level.ControllerList; PC!=None; PC=PC.NextController )
		{
			C = KFHumanPawn(PC.Pawn);
			if( C==None || C.Health<=0 )
				Continue;
			if ( BestEnemy == None )
			{
				BestEnemy = C;
				BestDist = VSize(BestEnemy.Location - Pawn.Location);
				bSeeBest = CanSee(C);
			}
			else
			{
				NewDist = VSize(C.Location - Pawn.Location);
				if ( !bSeeBest || (NewDist < BestDist) )
				{
					bSeeNew = CanSee(C);
					if ( NewDist < BestDist)
					{
						BestEnemy = C;
						BestDist = NewDist;
						bSeeBest = bSeeNew;
					}
				}
			}
		}
	}
	else
	{
		for ( PC=Level.ControllerList; PC!=None; PC=PC.NextController )
		{
			if ( PC.bIsPlayer && (PC.Pawn!=None) && PC.Pawn.Health>0 )
			{
				if ( BestEnemy == None )
				{
					BestEnemy = PC.Pawn;
					if(BestEnemy != none)
					{
						BestDist = VSize(BestEnemy.Location - Pawn.Location);
						bSeeBest = CanSee(BestEnemy);
					}
				}
				else
				{
					NewDist = VSize(PC.Pawn.Location - Pawn.Location);
					if ( !bSeeBest || (NewDist < BestDist) )
					{
						bSeeNew = CanSee(PC.Pawn);
						if ( NewDist < BestDist)
						{
							BestEnemy = PC.Pawn;
							BestDist = NewDist;
							bSeeBest = bSeeNew;
						}
					}
				}
			}
		}
	}

	if ( BestEnemy == Enemy )
		return false;

	if ( BestEnemy != None )
	{
		ChangeEnemy(BestEnemy,CanSee(BestEnemy));
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
			if (KFMonster(Pawn).MeleeRange != KFMonster(Pawn).default.MeleeRange)
				KFMonster(Pawn).MeleeRange = KFMonster(Pawn).default.MeleeRange;
			GotoState('ZombieCharge');
		}
	}
}

function DoTacticalMove();

function bool FindBestPathToward(Actor A, bool bCheckedReach, bool bAllowDetour)
{
	local vector Dummy;

	if( A==None )
		Return False; // Shouldn't get to this, but just in case.
	if ( !bCheckedReach && ActorReachable(A) )
		MoveTarget = A;
	else
	{
		// Sometimes they may attempt to find another way around if this way leads to i.e. a welded door.
		if( ExtraCostWay!=None )
			ExtraCostWay.ExtraCost+=200;
		if( BlockedWay!=None )
		{
			BlockedWay.ExtraCost+=10000;
			MoveTarget = FindPathToward(A);
			BlockedWay.ExtraCost-=10000;
		}
		else MoveTarget = FindPathToward(A);
		if( ExtraCostWay!=None )
			ExtraCostWay.ExtraCost-=200;
		if( MoveTarget!=None )
		{
			if( LastResult==MoveTarget && NavigationPoint(MoveTarget)!=None && NumAttmpts>3 && FRand()<0.6 )
			{
				BlockedWay = NavigationPoint(MoveTarget);
				LastResult = None;
				NumAttmpts = 0;
				return FindBestPathToward(A,True,bAllowDetour);
			}
			else if( LastResult==MoveTarget )
				NumAttmpts++;
			else NumAttmpts = 0;
			LastResult = MoveTarget;
			if( NavigationPoint(MoveTarget)!=None && KFMonster(Trace(Dummy,Dummy,MoveTarget.Location,Pawn.Location,True))!=None )
			{
				ExtraCostWay = NavigationPoint(MoveTarget);
				ExtraCostWay.ExtraCost+=200;
				MoveTarget = FindPathToward(A); // Might consider taking another path if zombie is blocking this one.
				ExtraCostWay.ExtraCost-=200;
			}
		}
	}
	if ( MoveTarget!=None )
		return true;
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
	if( FindFreshBody() )
		Return;
	if (KFMonster(Pawn).MeleeRange != KFMonster(Pawn).default.MeleeRange)
		KFMonster(Pawn).MeleeRange = KFMonster(Pawn).default.MeleeRange;

	if ( Enemy == none || Enemy.Health <= 0 )
		FindNewEnemy();

	if ( (Enemy == FailedHuntEnemy) && (Level.TimeSeconds == FailedHuntTime) )
	{
		if ( !Enemy.Controller.bIsPlayer )
			FindNewEnemy();

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

		if( Pawn.CollisionRadius!=Pawn.Default.CollisionRadius || Pawn.CollisionHeight!=Pawn.Default.CollisionHeight )
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
        if ( (Enemy != None) && !KFMonster(pawn).bCannibal && (Enemy.Health <= 0) )
        {
            Enemy = None;
            WhatToDoNext(23);
            return;
        }

        if ( Pawn.JumpZ > 0 )
            Pawn.bCanJump = true;

        if ( ActorReachable(Enemy) )
        {
            Destination = Enemy.Location;
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
            GotoState('StakeOut');
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
	function bool StrafeFromDamage(float Damage, class<DamageType> DamageType, bool bFindDest)
	{
		return false;
	}

	// I suspect this function causes bloats to get confused
	function bool TryStrafe(vector sideDir)
	{
		return false;
	}
}


function CheckIfShouldCrouch(vector StartPosition, vector TargetPosition, float probability);

function InitializeSkill(float InSkill);

function ResetSkill();

// Randomize their speeds a bit.
function SetMaxDesiredSpeed()
{
	Pawn.MaxDesiredSpeed = 0.9+FRand()*0.2;
}

function SetPeripheralVision();

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
				if ( NumRandomJumps > 5 )
				{
					Pawn.Health = 0;
					Pawn.Died( self, class'Suicided', Pawn.Location );
					return true;
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
	FindRoamDest();
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
		if(Pawn.Velocity == vect(0,0,0))
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
			if ( (Enemy != None) && !KFMonster(pawn).bCannibal && (Enemy.Health <= 0) )
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
    if ( Monster(Pawn).bShotAnim )
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
ignores EnemyNotVisible;

	function Timer()
	{
		Disable('NotifyBump');
		Target = TargetDoor;
		if(Target.bhidden || !KFDoorMover(Target).bSealed )    // if it's dead, or someone's unwelded it,  find something else to maul.
			gotoState('Zombiehunt');
	}

	function AttackDoor()
	{
		Target = TargetDoor;
		KFMonster(Pawn).DoorAttack(Target);
	}

Begin:
	WaitForLanding();

KeepMoving:
	MoveTarget = TargetDoor;
	if(MoveTarget!=none)
		MoveToward(MoveTarget,FaceActor(1),,false ); //,GetDesiredOffset(),ShouldStrafeTo(MoveTarget));

	While( Monster(Pawn).bShotAnim )
		Sleep(0.25);
	While( TargetDoor!=none && !TargetDoor.bHidden && TargetDoor.bSealed && !TargetDoor.bZombiesIgnore )
	{
		AttackDoor();
		While( Monster(Pawn).bShotAnim )
			Sleep(0.25);
		if( Enemy!=None && ActorReachable(Enemy) )
			WhatToDoNext(14);
	}
	if ( !FindBestPathToward(TargetDoor, false,true) )
		GotoState('ZombieRestFormation','Moving');

	WhatToDoNext(152);
	if ( bSoaking )
		SoakStop("STUCK IN DOORBASHING!");

Moving:
	MoveToward(TargetDoor);
	WhatToDoNext(17);
	if ( bSoaking )
		SoakStop("STUCK IN CHARGING!");
}


state CorpseFeeding extends MoveToGoalNoEnemy
{
ignores EnemyNotVisible;

	function Timer()
	{
		Disable('NotifyBump');
		Target = TargetCorpse;
		if(Target == none)
			gotoState('Zombiehunt');
	}
	function AttackCorpse()
	{
		Target = TargetCorpse;
		KFMonster(Pawn).CorpseAttack(Target);
	}

Begin:
	//SwitchToBestWeapon();
	WaitForLanding();

KeepMoving:
	if( TargetCorpse!=none )
		MoveToward(TargetCorpse,TargetCorpse,,false );

	While( Monster(Pawn).bShotAnim )
		Sleep(0.5);

	if(TargetCorpse!=none && Monster(Pawn).CanAttack(TargetCorpse) )
	{
		While( TargetCorpse!=None && Monster(Pawn).CanAttack(TargetCorpse) && Pawn.Health<(Pawn.Default.Health*1.5) )
		{
			Target = TargetCorpse;
			Focus = TargetCorpse;
			AttackCorpse();
			Sleep(0.1);
			While( Monster(Pawn).bShotAnim )
				Sleep(0.5);
			if( Enemy!=None && CanSee(Enemy) )
				WhatToDoNext(35);
		}
	}
	if ( TargetCorpse==None || !FindBestPathToward(TargetCorpse, false,true) )
		GotoState('ZombieRestFormation','Moving');

	MoveToward(MoveTarget);
	GoTo'KeepMoving';
}


function Celebrate()
{
    Pawn.PlayVictoryAnimation();
}


function WaitForMover(Mover M)
{
    if ( (Enemy != None) && (Level.TimeSeconds - LastSeenTime < M.MoveTime) )
        Focus = Enemy;
    PendingMover = M;
    bPreparingMove = true;
    Pawn.Acceleration = vect(0,0,0);

    StopStartTime = Level.TimeSeconds;
}


function HearNoise(float Loudness, Actor NoiseMaker)
{
  if (NoiseMaker != none)
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
	if ( Monster(Pawn).bShotAnim )
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
	if ( Monster(Pawn).bShotAnim )
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
    bHasFired = false;
    GoalString = "WhatToDoNext at "$Level.TimeSeconds;
    if ( Pawn == None )
    {
        warn(GetHumanReadableName()$" WhatToDoNext with no pawn");
        return;
    }

    if ( bPreparingMove && Monster(Pawn).bShotAnim )
    {
        Pawn.Acceleration = vect(0,0,0);
        GotoState('WaitForAnim');
        return;
    }
    if (Pawn.Physics == PHYS_None)
        Pawn.SetMovementPhysics();
    if ( (Pawn.Physics == PHYS_Falling) && DoWaitForLanding() )
        return;
    if ( (Enemy != None) && ((Enemy.Health <= 0) || (Enemy.Controller == None)) )
        Enemy = None;

   // if ( Level.Game.bGameEnded && (Enemy != None) && Enemy.Controller.bIsPlayer )
    //    Enemy = None;

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
	if ( Enemy!=None && Monster(Pawn).HasRangedAttack() && (FRand() < 0.5) && (VSize(Enemy.Location - FocalPoint) < 150)
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
		}
	}
	function EndState()
	{
		if( Pawn!=None )
			Pawn.GroundSpeed = Pawn.Default.GroundSpeed;
		bUseFreezeHack = False;
	}

Begin:
	While( Monster(Pawn).bShotAnim )
		Sleep(0.15);
	WhatToDoNext(99);
}

defaultproperties
{
     StrafingAbility=-1.000000
     CombatStyle=1.000000
     ReactionTime=1.000000
}
