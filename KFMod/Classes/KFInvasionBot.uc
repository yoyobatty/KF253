class KFInvasionBot extends InvasionBot;

var float LastShopTime;
var float LastShopCash;

var float LastHealTime;

struct FWeldedPath
{
	var KFDoorMover Door;
	var ReachSpec Path;
};
var array<FWeldedPath> DoorPaths;

var float NextTargetCheck,NextKnifeTime,NextMedicFireTime,NextNadeTimer,NextPipebombTimer,NextAssistTimer,NextGroupTimer,BotSupportTimer,WeldAssistTimer,NextSquadRetreatTime;

var byte HealState,OldMovesCount;
var float RetreatTime,LastEnemyEncounter;
var NavigationPoint CurrentMov,OldMoves[4],PreviousNavPath,LastBestGroup;
var array<NavigationPoint> TempBlockedPaths;

// Internal to state
var WeaponLocker TargetLocker;
var NavigationPoint ShoppingPath;
var vector MeLoc, LockLoc;
var float LockerDist;
var float LockerHeight;
var KFDoorMover TargetDoor;

var Syringe MySyringe;
var Welder ActiveWelder;
var Frag MyGrenades;
var Actor ShopVolumeActor;
var Pickup PickupTarget;
var float LastDeathRecordTime;
var array<class<KFWeaponPickup> > LastDroppedWeaponClasses;
var bool bTriedRecoverLastDrop;

var KFHumanPawn InjuredAlly;
var bool bHasChecked;

var KFInvasionBot BeggingTarget,AnswerBegger;
var PlayerController DonatePlayer;
var Pawn FollowingPawn,BotSupportActor;

var byte Personality,AssistWeldMode;

var rotator LastViewRotation;
var() float SmoothTurnSpeed;

var vector CachedRetreatDest;
var float NextRetreatDestUpdate;

function AssignPersonality()
{
	// Randomize personality.
	Accuracy = FRand();
	BaseAggressiveness = FRand();
	StrafingAbility = -1 + FRand()*2.f;
	CombatStyle = -1 + FRand()*2.f;
	Tactics = FRand();
	ReactionTime = FRand();
	Personality = 1; //Follow group
	Jumpiness = 0.f;
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	AssignPersonality();
}

event MayDodgeToMoveTarget()
{
}

function SetBotSprinting(bool bSprint)
{
    local KFHumanPawn KFP;
    KFP = KFHumanPawn(Pawn);
    if (KFP != None)
        KFP.bIsSprinting = bSprint;
}

function NotifyAddInventory(inventory NewItem)
{
	local byte i;
	local KFMeleeFire F;

	Super.NotifyAddInventory(NewItem);
	
	// HACK: Give extra melee range.
	if( KFWeapon(NewItem)!=None && KFWeapon(NewItem).bMeleeWeapon )
	{
		for( i=0; i<2; ++i )
		{
			F = KFMeleeFire(Weapon(NewItem).GetFireMode(i));
			if( F!=None )
				F.WeaponRange = F.Default.WeaponRange * 2.f;
		}
	}
	if( Syringe(NewItem)!=none )
		MySyringe = Syringe(NewItem);
	else if( Frag(NewItem)!=None )
		MyGrenades = Frag(NewItem);
	else if( Welder(NewItem)!=None )
		ActiveWelder = Welder(NewItem);
}

function TimedFireWeaponAtEnemy()
{
	// debugf;
	if ( Enemy != None )
		FireWeaponAt(Enemy);
	SetTimer(0.1f, True);
}

// added CanAttack() check to calm trigger-happy bots
function bool FireWeaponAt(Actor A)
{
	if ( A == None )
		A = Enemy;
	if ( A == None || !Pawn.CanAttack(A) )
	{
		//log("FireWeaponAt: Can attack: " $Pawn.CanAttack(A)$ " for " $Pawn.GetHumanReadableName()$ " at " $A.GetHumanReadableName());
		return false;
	}
	Target = A;
	if ( Pawn.Weapon != None )
	{
		if ( Pawn.Weapon.HasAmmo() )
			return WeaponFireAgain(Pawn.Weapon.RefireRate(),false);
	}
	else
		return WeaponFireAgain(Pawn.RefireRate(),false);

	return false;
}

final function TossCash( int Amount, vector TossDir )
{
	local CashPickup CashPickup;

	PlayerReplicationInfo.Score = int(PlayerReplicationInfo.Score);
	if( PlayerReplicationInfo.Score<=0 || Amount<=0 )
		return;
	Amount = Min(Amount,int(PlayerReplicationInfo.Score));

	TossDir = Normal(TossDir-Pawn.Location)*500.f + Vect(0,0,200);
	CashPickup = Spawn(class'CashPickup',,, Pawn.Location + Pawn.CollisionRadius * vector(Pawn.Rotation));

	if(CashPickup != none)
	{
		CashPickup.CashAmount = Amount;
		CashPickup.bDroppedCash = true;
		CashPickup.RespawnTime = 0;   // Dropped cash doesnt respawn. For obvious reasons.
		CashPickup.Velocity = TossDir;
		CashPickup.InitDroppedPickupFor(None);
		PlayerReplicationInfo.Score -= Amount;
	}
}

function EnemyAquired()
{
	WhatToDoNext(2);
}

// There was so much cruft in the UT2K version function that isn't
// relevant to KF. Lets lighten the load
function Actor FaceActor(float StrafingModifier)
{
	local actor SquadFace; //, N;

	//TODO - do we need this?
	SquadFace = Squad.SetFacingActor(self);
	if ( SquadFace != None )
		return SquadFace;

	bRecommendFastMove = false;

	if ( Enemy == none || Level.TimeSeconds - LastSeenTime > 4 - StrafingModifier)
		return FaceMoveTarget();

	// Gibber - trimmed this one down to happen regardless of skill level
	if ( (Pawn.Weapon != None && Pawn.Weapon.bMeleeWeapon ) )
		return FaceMoveTarget();

	return Enemy;
}

function bool DefendMelee(float Dist)
{
    return (Super.DefendMelee(Dist) || (KFMonster(Enemy) != None && Dist <800));
}

function bool ShouldGoShopping()
{
	// Can't shop if the shop ain't open
	if( KFGameType(Level.Game).bWaveInProgress )
		return false;
	// Can't shop if we don't have enough cash
    if( PlayerReplicationInfo.Score < 50 )
        return false;
	// Did we suddenly get a cash injection?
    if( PlayerReplicationInfo.Score >= LastShopCash + 150.f )
	{
		LastShopCash = PlayerReplicationInfo.Score;
		log(GetHumanReadableName()$" ShouldGoShopping: Cash injection detected. Current cash: " $PlayerReplicationInfo.Score $ " LastShopCash: " $LastShopCash);
        return true;
	}
	//log(GetHumanReadableName()$" ShouldGoShopping: LastShopTime: " $LastShopTime $ " Level.TimeSeconds: " $Level.TimeSeconds);
    return (LastShopTime < Level.TimeSeconds);
}

final function bool ShouldBegForCash()
{
	local Controller C;
	local array<PlayerController> PC;
	local byte i;

	if( KFGameType(Level.Game).bWaveInProgress || AnswerBegger!=None )
		return false;

	if( PlayerReplicationInfo.Score<300 && LastShopTime<Level.TimeSeconds ) // Beg if low on dosh and needs to go shop yet.
	{
		for( C=Level.ControllerList; C!=None; C=C.nextController )
			if( KFInvasionBot(C)!=None && KFInvasionBot(C).AnswerBeg(Pawn,PlayerReplicationInfo.Score) && ActorReachable(C.Pawn) )
			{
				BeggingTarget = KFInvasionBot(C);
				BeggingTarget.AnswerBegger = Self;
				SendChatMsg("I need some money!");
				GoToState('BeggingCash','Begin');
				return true;
			}
	}
	else if( PlayerReplicationInfo.Score>900 )
	{
		for( C=Level.ControllerList; C!=None; C=C.nextController )
			if( PlayerController(C)!=None && KFPawn(C.Pawn)!=None && C.PlayerReplicationInfo.Score<250 && ActorReachable(C.Pawn) )
				PC[PC.Length] = PlayerController(C);

		while( PC.Length>0 )
		{
			i = Rand(PC.Length);
			DonatePlayer = PC[i];
			PC.Remove(i,1);
			for( C=Level.ControllerList; C!=None; C=C.nextController )
				if( C!=Self && KFInvasionBot(C)!=None && KFInvasionBot(C).DonatePlayer==DonatePlayer )
				{
					DonatePlayer = None;
					break;
				}
			if( DonatePlayer!=None )
			{
				SendMessage(DonatePlayer.PlayerReplicationInfo, 'ACK', 2, 0.25f, 'TEAM');
				SendChatMsg("Let me give you some dosh, "$DonatePlayer.PlayerReplicationInfo.PlayerName$"!");
				GoToState('GivePoorPlayerCash','Begin');
				return true;
			}
		}
	}
	return false;
}
final function bool AnswerBeg( Pawn Other, int OtherCash )
{
	if( BeggingTarget!=None || AnswerBegger!=None || (PlayerReplicationInfo.Score-OtherCash)<800 || Pawn==None || VSize(Pawn.Location-Other.Location)>1000.f || Enemy!=None )
		return false;
	return true;
}
function AnswerBeggerNow()
{
	if( AnswerBegger==None || AnswerBegger.Pawn==None || !ActorReachable(AnswerBegger.Pawn) )
	{
		if( AnswerBegger!=None )
		{
			SendChatMsg("No can do.");
			AnswerBegger = None;
		}
		return;
	}
	SendMessage(AnswerBegger.PlayerReplicationInfo, 'ACK', 3, 1.5f, 'TEAM');
	SendChatMsg("Sure thing.");
	GoToState('RespondToBeg');
}


final function int FillAllAmmo( Class<Ammunition> AClass, float PriceScale )
{
    local Inventory I;
    local float Price;
    local Ammunition AM;
    local KFWeapon KW;
    local int c,ol,mxam;
    local float UsedMagCapacity;
    local Boomstick DBShotty;

    if ( AClass == None )
        return 0;

    for ( I=Pawn.Inventory; I != none; I=I.Inventory )
    {
        if ( I.Class == AClass )
            AM = Ammunition(I);
        else if ( KW == None && KFWeapon(I) != None && (Weapon(I).AmmoClass[0] == AClass || Weapon(I).AmmoClass[1] == AClass) )
            KW = KFWeapon(I);
    }

    if ( KW == none || AM == none )
        return 0;

    DBShotty = Boomstick(KW);

    AM.MaxAmmo = AM.default.MaxAmmo;
	//log(GetHumanReadableName()$" Bot bought ammo amount, max ammo is: " $AM.MaxAmmo);
    if ( KFPlayerReplicationInfo(PlayerReplicationInfo) != none && KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none )
	{
		AM.MaxAmmo = int(float(AM.MaxAmmo) * KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.AddExtraAmmoFor(AClass));
		//log(GetHumanReadableName()$" Checked perk, Bot bought ammo amount, max ammo is: " $AM.MaxAmmo);
	}

	mxam = AM.MaxAmmo;
	//log(GetHumanReadableName()$" Bot bought ammo amount, max ammo (mxam) is: " $AM.MaxAmmo);
	if( KW==MyGrenades )
		mxam = Min(mxam,5); // Never get more than 5 grenades.

    if ( AM.AmmoAmount >= mxam )
	{
		//log(GetHumanReadableName()$" AmmoAmount was greater than or equal to maxammo");
        return 0;
	}

    //Price = class<KFWeaponPickup>(KW.PickupClass).default.AmmoCost * KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetAmmoCostScaling(KFPlayerReplicationInfo(PlayerReplicationInfo), KW.PickupClass) * Mute.BotAmmoCostScale * PriceScale; // Clip price.

    UsedMagCapacity = KW.default.ClipCount;

	UsedMagCapacity = Max(UsedMagCapacity,1);

	c = (mxam-AM.AmmoAmount);

	if( Price>0.001f )
		Price = int(float(c) / UsedMagCapacity * Price);
	else Price = 0;

    if ( PlayerReplicationInfo.Score < Price ) // Not enough CASH (so buy the amount you CAN buy).
    {
		c *= (PlayerReplicationInfo.Score/Price);

		if ( c == 0 )
		{
			//log(GetHumanReadableName()$" bought coudln't afford ammo "$AM$ " and had no money: " $PlayerReplicationInfo.Score);
			return 0; // Couldn't even afford 1 bullet.
		}

        AM.AddAmmo(c);

		ol = PlayerReplicationInfo.Score;
		PlayerReplicationInfo.Score = Max(PlayerReplicationInfo.Score - (float(c) / UsedMagCapacity * Price), 0);
		//log(GetHumanReadableName()$" bought coudln't afford ammo "$AM$ " and had money: " $PlayerReplicationInfo.Score);
        return (ol-PlayerReplicationInfo.Score);
    }

    PlayerReplicationInfo.Score = int(PlayerReplicationInfo.Score-Price);
    AM.AddAmmo(c);
	//log(GetHumanReadableName()$" Bot bought ammo amount: " $c$ " out of max ammo: " $AM.MaxAmmo$ " with max ammo: " $mxam$ " for ammunition type: " $AM$ " for weapon: " $KW$ " and AM ammoamount was " $AM.AmmoAmount);
    return Price;
}

function bool FindInjuredAlly()
{
	local controller c;
	local KFHumanPawn aKFHPawn;
	local float AllyDist;
	local float BestDist;

	InjuredAlly = None;
	if( ManyEnemiesAround(3) )
		return false;
	if( MySyringe==none || MySyringe.ChargeBar()<0.6f )
		return false;

	for( c=level.ControllerList; c!=none; c=c.nextController )
	{
		if( C==Self )
			continue;

		aKFHPawn = KFHumanPawn(c.pawn);

		// If he's dead. dont bother.
		if( aKFHPawn==none || aKFHPawn.Health<=0 || (aKFHPawn.Health+aKFHPawn.HealthToGive)>=GetMinHealingValue() || VSize(aKFHPawn.Location-Pawn.Location)>1000.f )
			continue;

		if( !ActorReachable(aKFHPawn) )
			continue;
		AllyDist = VSize(Pawn.Location - aKFHPawn.Location);
		if( AKFHPawn.Health<40 )
			AllyDist*=0.5f;
		if( InjuredAlly==none || (AllyDist<BestDist) )
		{
			InjuredAlly = aKFHPawn;
			BestDist = AllyDist;
		}
	}
	if( InjuredAlly!=None )
	{
		if( InjuredAlly.Health<60 && KFInvasionBot(InjuredAlly.Controller)!=None && FRand()<0.5 )
			KFInvasionBot(InjuredAlly.Controller).SendMessage(None, 'OTHER', 30, 4.f, 'TEAM'); // Need healing!
		return true;
	}
	return false;
}

//-------------------------------------------------------------------------------------
// EnemyReallyScary:
// Returns true if the current enemy is considered really scary to this bot
// Breakdown:
// Bosses - always scary if shooting, or close
// Fleshpounds - very scary if close or enraged
// Scrakes have a factor of 2 danger score if within 300 units
// Sirens have a factor of 2 danger score if within 500 units
// All other enemies have a 0.5 danger score if within 150 units and targetting us
// Zerkers with armour have a threshold of 20, otherwise it's 10
//-------------------------------------------------------------------------------------
function bool EnemyReallyScary()
{
    local Controller C;
    local KFMonster M;
    local float D;
	local float DangerScore, ScaryThreshold;
	local bool bBerserker;

	bBerserker = KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.default.VeterancyName == "Berserker";

    for (C = Level.ControllerList; C != None; C = C.nextController)
    {
        M = KFMonster(C.Pawn);
        if (M == None || M.Health <= 0 || !LineOfSightTo(M))
            continue;

        D = VSize(M.Location - Pawn.Location);
        // Boss is always scary if shooting bullets/rockets
        if (M.IsA('ZombieBoss'))
        {
            if (D < 600.f || M.IsInState('FireChaingun') || M.IsInState('FireMissile'))
                return true;
			//if (D < 1000.f)
            //    DangerScore += 5.0;
        }
        // Fleshpound: very scary if close
        else if (M.IsA('ZombieFleshPound'))
        {
			if(!bBerserker)
				if (C.Enemy==Pawn && (D < 200.f || (D < 600.f && M.GroundSpeed > M.default.GroundSpeed))) //if he's too close or enraged and closing in
					return true;
			else if (M.GroundSpeed > M.default.GroundSpeed) // Berserker less scared, only if enraged
				return true;
            //if (D < 1000.f)
            //    DangerScore += 3.0;
        }
        // Scrake: scary if close
        else if (M.IsA('ZombieScrake'))
        {
            //if (C.Enemy==Pawn && D < 200.f)
            //    return true;
            if (D < 300.f)
                DangerScore += 2.0;
        }
        // Siren: scary in groups or close
        else if (M.IsA('ZombieSiren'))
        {
            if (D < 500.f)
                DangerScore += 2.0;
        }
        else if (D < 150.f && C.Enemy==Pawn)
            DangerScore += 0.5;
    }
	// Berserkers are less scared, especially with shields
	if (bBerserker && Pawn.ShieldStrength > 0.0)
		ScaryThreshold = 20.f;
	else ScaryThreshold = 10.f;

	return (DangerScore >= ScaryThreshold);

    //return false;
}

final function RequestAssist()
{
	local Controller C;
	
	BotSupportActor = None;
	BotSupportTimer = Level.TimeSeconds+5.f;
	for( C=Level.ControllerList; C!=None; C=C.nextController )
		if( C.bIsPlayer && C!=Self && KFInvasionBot(C)!=None && C.Pawn!=None && C.Pawn.Health>0 && VSize(C.Pawn.Location-Pawn.Location)<3000.f )
		{
			KFInvasionBot(C).BotSupportActor = Pawn;
			KFInvasionBot(C).BotSupportTimer = Level.TimeSeconds+4.f+FRand()*4.f;
		}
}

function bool SetEnemy( Pawn NewEnemy )
{
	if( Enemy==NewEnemy || KFMonster(NewEnemy)==None || NewEnemy.Health<=0 || (Enemy!=None && GetEnemyDesire(KFMonster(Enemy),false)<GetEnemyDesire(KFMonster(NewEnemy),false)) )
		return false;
	Enemy = NewEnemy;
	EnemyChanged(LineOfSightTo(Enemy));
	if( BotSupportTimer<Level.TimeSeconds )
		RequestAssist();

	LastEnemyEncounter = Level.TimeSeconds;
	return true;
}

// Gibber - stripping out vehicle stuff, adding shopping, better item scavaging
//          using the syringe and all the other little tweaks
function ExecuteWhatToDoNext()
{
	//SetTimer(0.1,true);
	//SwitchToBestWeapon();
	bHasFired = false;
	GoalString = "WhatToDoNext at "$Level.TimeSeconds;
	if ( Pawn == None )
	{
		warn(GetHumanReadableName()$" WhatToDoNext with no pawn");
		return;
	}
	if ( Enemy == None )
	{
		if ( Level.Game.TooManyBots(self) )
		{
			if ( Pawn != None )
			{
				Pawn.Health = 0;
				Pawn.Died( self, class'Suicided', Pawn.Location );
			}
			Destroy();
			return;
		}
		if( Pawn.Health<=80 && TryToHealSelf() )
			return;

		BlockedPath = None;
		bFrustrated = false;
		if (Target == None || (Pawn(Target) != None && Pawn(Target).Health <= 0))
			StopFiring();
	}

	if ( ScriptingOverridesAI() && ShouldPerformScript() )
		return;
	if (Pawn.Physics == PHYS_None)
		Pawn.SetMovementPhysics();
	if ( Pawn.FindAnchorFailedTime == Level.TimeSeconds && Pawn.LastValidAnchorTime > 10.f && TeleportBackIn() ) // Unstuck ourselves because maps are buggy
		return;
	if ( (Pawn.Physics == PHYS_Falling) && DoWaitForLanding() )
		return;
	if ( (StartleActor != None) && !StartleActor.bDeleteMe && (VSize(StartleActor.Location - Pawn.Location) < StartleActor.CollisionRadius)  )
	{
		Startle(StartleActor);
		return;
	}
	bIgnoreEnemyChange = true;
	if ( (Enemy != None) && ((Enemy.Health <= 0) || (Enemy.Controller == None)) )
		LoseEnemy();
	if ( Enemy == None )
		Squad.FindNewEnemyFor(self,false);
	else if ( !Squad.MustKeepEnemy(Enemy) && !EnemyVisible() )
	{
		// decide if should lose enemy
		if ( Squad.IsDefending(self) )
		{
			if ( LostContact(4) )
				LoseEnemy();
		}
		else if ( LostContact(7) )
			LoseEnemy();
	}
	bIgnoreEnemyChange = false;

	if( Enemy==none && ((ShouldGoShopping() && GoShopping()) || ShouldBegForCash()) ) 
		Return; 
	if( LastHealTime<Level.TimeSeconds && FindInjuredAlly() && (!EnemyReallyScary() && StartleActor==None) && GoHealing() )
		return;
	else
	{
		if ( AssignSquadResponsibility() )
		{
			if ( Pawn == None )
				return;
			SwitchToBestWeapon();
			if(ThrowAwayBadWeaponForBetterPickup()) // While going to squad objective, throw away bad weapon for better pickup
				GoalString = "WhatToDoNext Throwing away bad weapon for pickup";
			return;
		}
		if ( ShouldPerformScript() )
			return;
		if ( Enemy != None )
			ChooseAttackMode();
		else
		{
			GoalString = "WhatToDoNext Wander or Camp at "$Level.TimeSeconds;
			WanderOrCamp(true);
		}
		SwitchToBestWeapon();
	}
}

event bool NotifyBump(actor Other)
{
	local Pawn P;
    local KActor KA;
	local KFGlassMover GM;
    local vector ThrowDir;

	Disable('NotifyBump');
	P = Pawn(Other);
	if ( (P == None) || (P.Controller == None) || (Enemy == P) )
		return false;
	if ( Squad.SetEnemy(self,P) )
	{
		WhatToDoNext(4);
		return false;
	}

	if ( Enemy == P )
		return false;

	if ( CheckPathToGoalAround(P) )
		return false;

	if ( !AdjustAround(P) )
		CancelCampFor(P.Controller);

    KA = KActor(Other);
    if (KA != None)
    {
        ThrowDir = vector(Pawn.Rotation);
        ThrowDir.Z = 0.5; // Add some upward force
        ThrowDir = Normal(ThrowDir);
        KA.KAddImpulse(ThrowDir * 1500, KA.Location);
		//Pawn.DoJump(false);
		return true;
        //log(GetHumanReadableName()$" threw NetActor: "$KA);
    }
	GM = KFGlassMover(Other);
	if( GM!=None )
	{
		GM.TakeDamage(50.f, Pawn, Pawn.Location, vect(0,0,0), class'DamageType');
		return true;
	}
	return false;
}

State BeggingCash
{
Ignores SwitchToBestWeapon;

	function BeginState()
	{
		SetTimer(2,true);
	}
	function EndState()
	{
		local bool bSaidThanks; // Prevent spamming thanks message.

		if( PlayerReplicationInfo.Score>500 && !bSaidThanks )
		{
			SendChatMsg("Thanks!");
			bSaidThanks = true;
		}
		if( BeggingTarget!=None )
		{
			BeggingTarget.AnswerBegger = None;
			BeggingTarget = None;
		}
	}
	function Timer()
	{
		if( BeggingTarget==None || BeggingTarget.Pawn==None || BeggingTarget.AnswerBegger!=Self )
		{
			EndState();
			WhatToDoNext(35);
			return;
		}
		BeggingTarget.AnswerBeggerNow();
	}
Begin:
	Pawn.Acceleration = vect(0,0,0);
	Focus = BeggingTarget.Pawn;
	Stop;
}
State RespondToBeg
{
Ignores AnswerBeggerNow;

	function BeginState()
	{
		SetTimer(0,false);
	}
	function EndState()
	{
		AnswerBegger = None;
	}
	final function vector GetMoveDest( Actor T )
	{
		local vector D;

		D = (T.Location-Pawn.Location);
		return Pawn.Location+Normal(D)*(VSize(D)-(Pawn.CollisionRadius+T.CollisionRadius+50.f));
	}
	function Timer()
	{
		if( AnswerBegger==None || AnswerBegger.Pawn==None || !CanSee(AnswerBegger.Pawn) || AnswerBegger.PlayerReplicationInfo.Score>600 )
			WhatToDoNext(38);
		else TossCash(50,AnswerBegger.Pawn.Location);
	}
Begin:
	MoveTo(GetMoveDest(AnswerBegger.Pawn),AnswerBegger.Pawn,false);
	Pawn.Acceleration = vect(0,0,0);
	Focus = AnswerBegger.Pawn;
	FinishRotation();
	SetTimer(0.2,true);
	Sleep(2.f);
	WhatToDoNext(39);
}

State GivePoorPlayerCash extends RespondToBeg
{
	function BeginState()
	{
		SetTimer(0.2,true);
	}
	function EndState()
	{
		DonatePlayer = None;
	}
	function Timer()
	{
		if( DonatePlayer==None || DonatePlayer.Pawn==None || !ActorReachable(DonatePlayer.Pawn) || DonatePlayer.PlayerReplicationInfo.Score>600 )
			WhatToDoNext(38);
		else if( VSize(DonatePlayer.Pawn.Location-Pawn.Location)<200 )
		{
			if( MoveTimer>0.f )
			{
				MoveTimer = -1;
				GoToState(,'Done');
			}
			TossCash(50,DonatePlayer.Pawn.Location);
		}
		else if( MoveTimer<=0.f )
			GoToState(,'Begin');
	}
Begin:
	while( true )
		MoveToward(DonatePlayer.Pawn,DonatePlayer.Pawn);
Done:
	Pawn.Acceleration = vect(0,0,0);
	Focus = DonatePlayer.Pawn;
	FinishRotation();
	SetTimer(0.2,true);
	Sleep(2.25f);
	WhatToDoNext(39);
}

//Tosses out the worst weapon in our inventory, or the specified weapon
final function bool ThrowAwayBadWeapon(KFWeapon WeapToThrow)
{
	local vector TossVel, X,Y,Z;

	if( WeapToThrow!=none )
	{
		while(Pawn.Weapon != WeapToThrow)
		{
			Pawn.PendingWeapon = WeapToThrow;
			Pawn.ChangedWeapon();
		}
		Pawn.SetRotation(Pawn.GetViewRotation() + rot(0,7000,0));
		TossVel = Vector(Pawn.GetViewRotation());
		TossVel = TossVel * ((Velocity Dot TossVel) + 500) + Vect(0,0,200);
		WeapToThrow.Velocity = TossVel;
		GetAxes(GetViewRotation(),X,Y,Z);
		WeapToThrow.DropFrom(Pawn.Location + 0.8 * Pawn.CollisionRadius * X - 0.5 * Pawn.CollisionRadius * Y);
		SwitchToBestWeapon();
		return true;
	}
  	return false;
}

// Compare a nearby KFWeaponPickup against ALL droppable weapons in our inventory.
// If the pickup is clearly better than at least one inventory weapon and we can
// carry it after dropping that weapon, toss the chosen worse weapon so the bot
// can pick up the better one.
// Returns true if a weapon was tossed, false otherwise.
final function bool ThrowAwayBadWeaponForBetterPickup()
{
    local KFHumanPawn      HP;
	local Inventory 	   Inv;
    local KFWeapon         W, BestDrop, CurBestDrop;
	local KFWeaponPickup   GroundPk, BestPk;
    local float            NewWWeight;
	local float 		   GroundRating, CurWRating, BestWRating, CurBestDropRating;
	local bool 		   	   bAlreadyOwn;

    HP = KFHumanPawn(Pawn);
    if (HP == None)
        return false;

	foreach DynamicActors(class'KFWeaponPickup',GroundPk) //Look for ground pickups
	{
        if (GroundPk == None || GroundPk.InventoryType == None || !GroundPk.ReadyToPickup(0) || !ActorReachable(GroundPk) || VSize(GroundPk.Location - Pawn.Location) > 400.f)
            continue;

		NewWWeight = GroundPk.Default.Weight;
		if(HP.CanCarry(NewWWeight)) //If we can already carry it, no need to drop anything
			continue;

		GroundRating = class<KFWeapon>(GroundPk.InventoryType).default.AIRating;
		if(WeaponIsForPerk(GroundPk.Class)) //If it's a perk weapon, upgrade its rating
			GroundRating *= 1.5;

        bAlreadyOwn        = false;
        CurBestDrop        = None;
        CurBestDropRating  = 0.0;

		for (Inv = Pawn.Inventory; Inv != None; Inv = Inv.Inventory) //Now compare against our inventory
		{
			W = KFWeapon(Inv);
			if (W == None || W.bKFNeverThrow) //Make sure it's real and actually throwable
				continue;

			//SendChatMsg("Considering dropping my "$W.GetHumanReadableName()$" for pickup "$GroundPk.GetHumanReadableName()$".");

            if (W.Class == class<KFWeapon>(GroundPk.InventoryType))
            {
                bAlreadyOwn = true;
                break;
            }

			CurWRating = W.default.AIRating;
			if(WeaponIsForPerk(class<KFWeaponPickup>(W.PickupClass))) //If it's a perk weapon, upgrade its rating
				CurWRating *= 1.5; 

			if ( GroundRating <= CurWRating ) // Pickup not better than this weapon? Skip!
				continue;

			if ((HP.CurrentWeight - W.Weight) + NewWWeight > HP.MaxCarryWeight) // Can't carry pickup after dropping this one? Skip!
				continue;

            if (!bAlreadyOwn && (CurBestDrop == None || CurWRating < CurBestDropRating))
            {
                CurBestDrop       = W;
                CurBestDropRating = CurWRating;
            }
		}
		if (bAlreadyOwn) //Already have this weapon, skip it!
            continue; 

		// If this pickup beats our current global best, remember it
        if (CurBestDrop != None && (BestPk == None || GroundRating - CurBestDropRating > GroundRating - BestWRating))
        {
            BestPk      = GroundPk;
            BestDrop    = CurBestDrop;
            BestWRating = CurBestDropRating;
        }
	}
    if (BestPk != None && BestDrop != None)
    {
		FindBestPathToward(BestPk,true,false); 
		if(MoveTarget != None && VSize(MoveTarget.Location - Pawn.Location) < 60.f)
		{
			SetAttractionState();
			if (BestDrop != None && ThrowAwayBadWeapon(BestDrop))
			{	
				GoalString = "WhatToDoNext - Dropping bad weapon for better pickup";
				return true;
			}
		}
    }
    return false;
}

function array<class<Pickup> > GetLegalPurchases()
{
	local int i;
	local KFLevelRules KFLR;
	local array<class<Pickup> > RetList;

	RetList.Length = 0;
	KFLR = KFGameType(Level.game).KFLRules;

	for(i=0; i<KFLR.ItemForSale.Length; i++ )
	{
		//log("Looping through legal purchase:"@i);
		if( KFLR.ItemForSale[i]!=none /*&& CanAfford(KFLR.ItemForSale[i] )*/ )
		{
			//BuyWeapon = class<KFWeaponPickup>(KFLR.ItemForSale[i]);
			RetList[RetList.Length] = KFLR.ItemForSale[i];
			//j++;
			//log("Ret List:"@RetList[RetList.Length]);
			//log("Ret List:"@RetList[j]);
		}
	}
	return RetList;
}

function bool CanAfford(class<Pickup> aItem)
{
	local class<kfWeaponPickup> aWeapon;
	local actor InvIt;
	local KFWeapon Weap;
	local bool bFoundInInventory;

	aWeapon = class<kfWeaponPickup>(aItem);

	if(aWeapon!=none)
	{
		bFoundInInventory=false;
		for(InvIt=pawn; InvIt!=none; InvIt=InvIt.Inventory)
		{
			Weap = KFWeapon(InvIt);
			if(Weap!=none)
			{
				bFoundInInventory=true;
				if(Weap.AmmoClass[0]!=none && Weap.Class==aWeapon.default.InventoryType)
				{
					if( PlayerReplicationInfo.score>aWeapon.default.ammocost )
						return true;
				}
			}
		}

		// if we didn't find it above, we need to see if we can buy the whole gun, not just ammo
		if(!bFoundInInventory && aWeapon.default.Cost < self.PlayerReplicationInfo.score && aWeapon.default.weight < (KFHumanPawn(pawn).MaxCarryWeight - KFHumanPawn(pawn).CurrentWeight) )
			return true;
	}
	return false;
}

function KFWeapon FindWeaponInInv(Class<KFWeaponPickup> TargetClass)
{
	local actor InvIt;
	local KFWeapon Weap;

	if( TargetClass==None )
		Return None;
	for( InvIt=pawn; InvIt!=none; InvIt=InvIt.Inventory)
	{
		Weap = KFWeapon(InvIt);
		if(Weap!=none && Weap.Class==TargetClass.default.InventoryType )
			return Weap;
	}
	return none;
}

final function bool SellWeapon( KFWeapon W )
{
	if( W==None || W.bKFNeverThrow )
		return false;
	PlayerReplicationInfo.Score+=GetWeaponWorth(W);
	log(PlayerReplicationInfo.PlayerName$" Sold weapon: " $ W.GetHumanReadableName() $ " for " $ GetWeaponWorth(W));
	W.Destroy();
	return true;
}
final function int GetWeaponWorth( KFWeapon W )
{
	return class<KFWeaponPickup>(W.PickupClass).Default.Cost*0.75; //*GetVet().Static.GetCostScaling(KFPlayerReplicationInfo(PlayerReplicationInfo),W.PickupClass);
}

final function Actor GetRandomDest()
{
	local int i;
	local Actor Result;
	
	// Setup special path finding.
	for( i=0; i<TempBlockedPaths.Length; ++i )
		TempBlockedPaths[i].bBlocked = true;
	for( i=0; i<DoorPaths.Length; ++i )
	{
		if( DoorPaths[i].Door.bSealed && !DoorPaths[i].Door.bHidden )
			DoorPaths[i].Path.CollisionRadius -= 10000; // Pretend that no pawn is small enough to use this.
		else DoorPaths.Remove(i--,1); // Remove opened paths.
	}

	Result = FindRandomDest();
	if( Result!=None )
	{
		PreviousNavPath = NavigationPoint(RouteCache[0]);
		if( PreviousNavPath!=None && PreviousNavPath.bBlocked ) // Shouldn't be possible, but just in case.
			PreviousNavPath = None;
	}

	// Un-setup path finding.
	for( i=0; i<TempBlockedPaths.Length; ++i )
		TempBlockedPaths[i].bBlocked = false;
	for( i=0; i<DoorPaths.Length; ++i )
		DoorPaths[i].Path.CollisionRadius += 10000;

	return Result;
}

function bool FindBestPathToward(Actor A, bool bCheckedReach, bool bAllowDetour)
{
	local int i;

	if ( !bCheckedReach && ActorReachable(A) )
	{
		MoveTarget = A;
		return true;
	}

	// Setup special path finding.
	for( i=0; i<TempBlockedPaths.Length; ++i )
		TempBlockedPaths[i].bBlocked = true;
	for( i=0; i<DoorPaths.Length; ++i )
	{
		if( DoorPaths[i].Door.bSealed && !DoorPaths[i].Door.bHidden )
			DoorPaths[i].Path.CollisionRadius -= 10000; // Pretend that no pawn is small enough to use this.
		else DoorPaths.Remove(i--,1); // Remove opened paths.
	}

	MoveTarget = FindPathToward(A,(bAllowDetour && Pawn.bCanPickupInventory  && (Vehicle(Pawn) == None) && (NavigationPoint(A) != None)));
	PreviousNavPath = NavigationPoint(MoveTarget);
	if( PreviousNavPath!=None && PreviousNavPath.bBlocked ) // Shouldn't be possible, but just in case.
		PreviousNavPath = None;

	// Un-setup path finding.
	for( i=0; i<TempBlockedPaths.Length; ++i )
		TempBlockedPaths[i].bBlocked = false;
	for( i=0; i<DoorPaths.Length; ++i )
		DoorPaths[i].Path.CollisionRadius += 10000;

	return (MoveTarget!=None);
}

function bool FindBestPathTo( vector Dest )
{
	local int i;

	// Setup special path finding.
	for( i=0; i<TempBlockedPaths.Length; ++i )
		TempBlockedPaths[i].bBlocked = true;
	for( i=0; i<DoorPaths.Length; ++i )
	{
		if( DoorPaths[i].Door.bSealed && !DoorPaths[i].Door.bHidden )
			DoorPaths[i].Path.CollisionRadius -= 10000; // Pretend that no pawn is small enough to use this.
		else DoorPaths.Remove(i--,1); // Remove opened paths.
	}

	MoveTarget = FindPathTo(Dest);
	PreviousNavPath = NavigationPoint(MoveTarget);
	if( PreviousNavPath!=None && PreviousNavPath.bBlocked ) // Shouldn't be possible, but just in case.
		PreviousNavPath = None;

	// Un-setup path finding.
	for( i=0; i<TempBlockedPaths.Length; ++i )
		TempBlockedPaths[i].bBlocked = false;
	for( i=0; i<DoorPaths.Length; ++i )
		DoorPaths[i].Path.CollisionRadius += 10000;

	return (MoveTarget!=None);
}

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
				if ( (NumRandomJumps > 4) || PhysicsVolume.bWaterVolume ) // Sometimes they get stuck behind doors
				{
					if (TeleportBackIn())
						return true;
					else
					{
							// If no nav point found, fallback to old behavior (kill the bot)
							Pawn.Health = 0;
							Pawn.Died( self, class'Suicided', Pawn.Location );
							return true;
						}
					}
				else
				{
					// jump
					NumRandomJumps++;
					if ( (Vehicle(Pawn) == None) && (Pawn.Physics != PHYS_Falling) )
					{
						Pawn.SetPhysics(PHYS_Falling);
						Pawn.Velocity = 0.5 * Pawn.GroundSpeed * VRand();
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
		// first look for a scripted sequence
		Squad.SetFreelanceScriptFor(self);
		if ( GoalScript != None )
		{
			RouteGoal = GoalScript.GetMoveTarget();
			BestPath = None;
		}
		else
		{
			RouteGoal = GetRandomDest();
			BestPath = RouteCache[0];
		}
		if ( RouteGoal == None )
		{
			if ( bSoaking && (Physics != PHYS_Falling) )
				SoakStop("COULDN'T FIND ROAM DESTINATION");
			return false;
		}
	}
	if ( BestPath == None && FindBestPathToward(RouteGoal,true,false) )
		BestPath = MoveTarget;
	if ( BestPath != None )
	{
		MoveTarget = BestPath;
		SetAttractionState();
		return true;
	}
	if ( bSoaking && (Physics != PHYS_Falling) )
		SoakStop("COULDN'T FIND ROAM PATH TO "$RouteGoal);
	RouteGoal = None;
	FreeScript();
	return false;
}

function bool TeleportBackIn()
{
	local NavigationPoint N, TeleNav;

	if(Pawn.LastAnchor != None)
		TeleNav = Pawn.LastAnchor;
	else 
	{
		for (N = Level.NavigationPointList; N != None; N = N.nextNavigationPoint)
		{
			if(PlayerStart(N)!= None)
				TeleNav = N;
		}
	}
	if (TeleNav != None)
	{
		Pawn.SetLocation(TeleNav.Location);
		GoalString = "Teleported to location: "$TeleNav$" after being stuck.";
		NumRandomJumps = 0;
		return true;
	}

}

final function BuyKevlar()
{
	local int Cost;
	local int UnitsAffordable;

	if ( UnrealPawn(Pawn).ShieldStrength>=100 )
		Return;

	Cost = class'Vest'.default.ItemCost * ((100.0 - UnrealPawn(Pawn).ShieldStrength) / 100.0);

	if ( PlayerReplicationInfo.Score >= Cost )
	{
		PlayerReplicationInfo.Score -= Cost;
		UnrealPawn(Pawn).ShieldStrength = 100;
	}
	else if ( UnrealPawn(Pawn).ShieldStrength>0 )
	{
		Cost = class'Vest'.default.ItemCost/100.f;

		UnitsAffordable = PlayerReplicationInfo.Score / Cost;
		PlayerReplicationInfo.Score -= Cost * UnitsAffordable;
		UnrealPawn(Pawn).ShieldStrength += UnitsAffordable;
	}
	PlayerReplicationInfo.Score = PlayerReplicationInfo.Score;
}

function DoTrading()
{
	local KFWeapon Weap;
	local class<KFWeaponPickup> BuyWeapClass;
	local int OldCash;
	local int Cost;
	local byte LCount, LCountB, LCountC;
	local KFHumanPawn P;

	P = KFHumanPawn(Pawn);
	if( P==None )
		return;
	log(PlayerReplicationInfo.PlayerName$" Starting Trading. Cash available: " $PlayerReplicationInfo.Score);
	LastShopTime = Level.TimeSeconds+60+60*FRand();
	OldCash = PlayerReplicationInfo.Score + 1;

	while ( (PlayerReplicationInfo.Score > 20) && PlayerReplicationInfo.Score!=OldCash && LCount++<10 )
	{
		OldCash = PlayerReplicationInfo.Score;

		BuyWeapClass = class<KFWeaponPickup>(GetBestPurchase());
		if( BuyWeapClass==None )
			Continue;
		Cost = BuyWeapClass.default.Cost;
		Weap = FindWeaponInInv(BuyWeapClass);
		if(Weap!=none) // already own gun, buy ammo
		{
			FillAllAmmo(Weap.GetAmmoClass(0),1.f);
			// debugf;
		}
		else // buy that gun
		{
			// Must sell off inventory to get a perk weapon
			if( WeaponIsForPerk(BuyWeapClass) )
			{
				//log(GetHumanReadableName()$" Bot WeaponIsForPerk check for sellmostundesired " $BuyWeapClass);
				while( !P.CanCarry(BuyWeapClass.default.Weight) && ++LCountB<10 && SellMostUndesired() )
				{}
				if( !P.CanCarry(BuyWeapClass.default.Weight) ) // Could not get perk weapon, no matter what.
				{
					++OldCash;
					//log(GetHumanReadableName()$" could not get perk weapon no matter what " $BuyWeapClass);
					continue;
				}
				if( Cost > PlayerReplicationInfo.Score && P.CanCarry(BuyWeapClass.default.weight) ) // Can't afford, try selling.
				{
					while( Cost > PlayerReplicationInfo.Score && ++LCountC<5 && SellMostUndesired() ) // Sell up to 5 non-perk weapons to afford.
					{
						//SendChatMsg("Selling unwanted weapon to afford perk weapon: " $ BuyWeapClass);
						log(PlayerReplicationInfo.PlayerName$" Selling unwanted weapon to afford perk weapon: " $ BuyWeapClass);
					}
				}
			}
			if( Cost <= PlayerReplicationInfo.Score && P.CanCarry(BuyWeapClass.default.weight) )
			{
				//Cost *= (GetVet().Static.GetCostScaling(KFPlayerReplicationInfo(PlayerReplicationInfo),BuyWeapClass) * Mute.BotWeaponCostScale);
				Weap = KFWeapon(Spawn(BuyWeapClass.default.InventoryType));
				//SendChatMsg("Buying weapon: " $ BuyWeapClass $ " for " $ Cost);
				log(PlayerReplicationInfo.PlayerName@"of perk"@KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.Default.VeterancyName@"Buying weapon: " $ BuyWeapClass $ " for " $ Cost);
				//log(GetHumanReadableName()$" Tried to buy a weapon: "$Weap);
				if( Weap!=None )
				{
					Weap.UpdateMagCapacity(PlayerReplicationInfo);
					Weap.FillToInitialAmmo();
					Weap.GiveTo(Pawn);
					FillAllAmmo(Weap.GetAmmoClass(0),1.f); //buy ammo too
					PlayerReplicationInfo.Score -= Cost;
					log(GetHumanReadableName()$" Purchased weapon: "$Weap$" New Cash: " $PlayerReplicationInfo.Score);
					continue;
				}
			} 
		}
	}
	PlayerReplicationInfo.Score = Max(PlayerReplicationInfo.Score,0); // Make sure we don't fall to negative now.
	if( PlayerReplicationInfo.Score>0 ) // Also purchase armor.
	{
		// debugf;
		BuyKevlar();
	}
	SwitchToBestWeapon();
	LastShopCash = PlayerReplicationInfo.Score;
	log(PlayerReplicationInfo.PlayerName$" Finished Trading. Cash left: " $PlayerReplicationInfo.Score);
}

final function class<Pickup> GetBestPurchase()
{
	local int i;
	local class<Pickup> BestBuy;
	local class<KFWeaponPickup> AmmoWeapClass;
	local KFWeapon WeapAmmo;
	local float Des,BestDes;
	local array<class<Pickup> > ShoppingList;

	if( ShoppingList.Length==0 )
		ShoppingList = GetLegalPurchases();
	for(i=0; i<ShoppingList.Length; i++ )
	{
		if( GetBuyDesire(ShoppingList[i],Des) && (BestBuy==None || BestDes<Des) )
		{
			//log(PlayerReplicationInfo.PlayerName@"Considering purchase of: "$ShoppingList[i]$" with desire: "$Des);
			BestBuy = ShoppingList[i];
			BestDes = Des;

		}
		AmmoWeapClass = class<KFWeaponPickup>(ShoppingList[i]);
		WeapAmmo = FindWeaponInInv(AmmoWeapClass);
		if(WeapAmmo!=none) // already own gun, buy ammo
		{
			FillAllAmmo(WeapAmmo.GetAmmoClass(0),1.f);
		}
	}
	return BestBuy;
}

final function bool GetBuyDesire( class<Pickup> aItem, out float Desire )
{
	local class<kfWeaponPickup> aWeapon;
	local Inventory InvIt;
	local int Cost;

	aWeapon = class<KFWeaponPickup>(aItem);
	if (aWeapon != None)
	{
		for(InvIt=Pawn.Inventory; InvIt!=none; InvIt=InvIt.Inventory)
		{
			if( InvIt.PickupClass==aWeapon )
			{
				Desire = 0.f; // Already have it
				//log(PlayerReplicationInfo.PlayerName@"Desire is 0, already have it: "$aWeapon);
				return false;
			}
		}
		Desire = aWeapon.Default.MaxDesireability;
		//log(PlayerReplicationInfo.PlayerName@"Base Desire for: "$aWeapon$" is: " $ Desire);
		Desire*=(FRand()*0.5+1.f); 
		//log(PlayerReplicationInfo.PlayerName@"Desire after random factor: " $ Desire);
		if( WeaponIsForPerk(aWeapon) )
			Desire *= 4.f; // More desire for perk weapons
		//SendChatMsg("Considering purchase of: "$aWeapon$" with desire: "$Desire);
		//log(PlayerReplicationInfo.PlayerName$"Considering purchase of: "$aWeapon$" with desire: "$Desire);
		Cost = aWeapon.default.Cost;
		if( Cost<=PlayerReplicationInfo.Score && (KFHumanPawn(Pawn).CanCarry(aWeapon.default.weight)) || WeaponIsForPerk(aWeapon) )
			return true;
	}
	return false;
}

final function bool SellMostUndesired()
{
	local Inventory I;
	local KFWeapon W,Best;
	local class<KFWeaponPickup> WP;
	local float Score,BestScore;
	
	for( I=Pawn.Inventory; I!=none; I=I.Inventory )
	{
		W = KFWeapon(I);
		if( W!=None && !W.bKFNeverThrow )
		{
			WP = class<KFWeaponPickup>(W.PickupClass);
			Score = 5.f + (WP.Default.Weight * 0.1f) + (FRand()*2.f) * (1.5f - FClamp(float(WP.Default.PowerValue) * 0.0025f,0.f,1.f));
			if( Best==None || Score>BestScore )
			{
				Best = W;
				BestScore = Score;
				//log(PlayerReplicationInfo.PlayerName$" Considering selling weapon: " $ W.GetHumanReadableName() $ " with score: " $ Score);
			}
		}
	}
	if( Best==None || WeaponIsForPerk(class<KFWeaponPickup>(Best.PickupClass)) )
	{
		return false;
	}
	SellWeapon(Best);
	return true;
}

function bool GoShopping()
{
    if (ShouldRecoverDroppedWeapon())
    {
        GotoState('RecoverDroppedWeapons');
		GoalString = "RECOVER_DROP";
        return true;
    }
	if( !GetNearestShop() )
		Return false;
	GoalString = "SHOPPING";
	GotoState('Shopping');
	LastDroppedWeaponClasses.Length = 0; // Clear out the last dropped weapon list after shopping
	return true;
}

function bool GetNearestShop()
{
	local KFGameType KFGT;
	local int i,l;
	local float Dist,BDist;
	local ShopVolume Sp;

	KFGT = KFGameType(Level.Game);
	if( KFGT==None )
		return false;
	l = KFGT.ShopList.Length;
	for( i=0; i<l; i++ )
	{
		//if( !KFGT.ShopList[i].bCurrentlyOpen )
		//	continue;
		if( !KFGT.ShopList[i].bTelsInit )
			KFGT.ShopList[i].InitTeleports();
		Dist = VSize(KFGT.ShopList[i].Location-Pawn.Location);
		if( Dist<BDist || Sp==None )
		{
			Sp = KFGT.ShopList[i];
			BDist = Dist;
		}
	}
	if( Sp==None )
		return false;
	if( Sp.TelList.Length>0 )
		ShoppingPath = Sp.TelList[Rand(Sp.TelList.Length)];
	else
	{
		if( Sp.BotPoint==None )
		{
			Sp.BotPoint = FindShopPoint(Sp);
			if( Sp.BotPoint==None )
				return false;
		}
		ShoppingPath = Sp.BotPoint;
	}
	if( Sp.MyTrader!=None )
		ShopVolumeActor = Sp.MyTrader;
	else ShopVolumeActor = Sp;

	return true;
}
final function NavigationPoint FindShopPoint( ShopVolume S )
{
	local NavigationPoint N,BN;
	local float Dist,BDist;

	for( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
	{
		Dist = VSize(N.Location-S.Location);
		if( BN==None || BDist>Dist )
		{
			BN = N;
			BDist = Dist;
		}
	}
	return BN;
}

function Pickup FindBestDroppedPickupNear()
{
    local KFWeaponPickup Pk;

    foreach DynamicActors(class'KFWeaponPickup', Pk)
    {
        if (Pk == None || Pk.bHidden || Pk.bDeleteMe)
            continue;

		if (Pk.BotDesireability(Pawn) <= 0.0)
			continue; 

		if(Pk.Owner == Self)
		{
			//SendChatMsg("Found dropped weapon pickup matching last dropped: " $ Pk);
			return Pk;
		}
	}
	return none;
}

function bool ShouldRecoverDroppedWeapon()
{
    PickupTarget = FindBestDroppedPickupNear();
    // Only try once per shopping session and only if wave is not ending soon, unless really close and approx on the same floor as us
    if (bTriedRecoverLastDrop || (KFGameReplicationInfo(Level.Game.GameReplicationInfo).TimeToNextWave < 25 && (PickupTarget != None && ((VSize(Pawn.Location - PickupTarget.Location) > 800) || (Pawn.Location.Z - PickupTarget.Location.Z) > 500))))
        return false;

    return (PickupTarget != None);
}

state RecoverDroppedWeapons extends MoveToGoalNoEnemy
{
    function EndState()
    {
		Super.EndState();
        bTriedRecoverLastDrop = true;
        PickupTarget = None;
    }

Begin:
    WaitForLanding();
KeepMoving:
    // If pickup disappeared or not enough time, just shop
    if (PickupTarget == None || PickupTarget.bDeleteMe || PickupTarget.bHidden || KFGameReplicationInfo(Level.Game.GameReplicationInfo).TimeToNextWave < 20)
        WhatToDoNext(37);
    if (ActorReachable(PickupTarget))
        MoveToward(PickupTarget, MoveTarget,, true);
    else if (FindBestPathToward(PickupTarget, true, true))
    {
        MoveToward(MoveTarget, MoveTarget,, false);
		Goto('KeepMoving');
    }
	else 
	{
		bTriedRecoverLastDrop = true;
		WhatToDoNext(38);
	}
    Sleep(0.5);
	bTriedRecoverLastDrop = true;
    WhatToDoNext(39);
	if(bSoaking)
		SoakStop("RECOVER DROPPED WEAPON FAILED");
}

function bool GoHealing()
{
	if( InjuredAlly!=none && LastHealTime<Level.TimeSeconds )
	{
		LastHealTime = Level.TimeSeconds+2.f;
		GoalString = "HEALING";
		GotoState('Healing');
		return true;
	}
	else return false;
}

function SetCombatTimer()
{
	SetTimer(0.16f, True);
}
function PawnDied(Pawn P)
{
	TempBlockedPaths.Length = 0; // Reset blocked paths list.
	DoorPaths.Length = 0;
	Super.PawnDied(P);
}

function float RateWeapon(Weapon W)
{
	local float R;

	R = (W.GetAIRating() + FRand() * 0.2);
	if( Class<KFWeaponPickup>(W.PickupClass)!=None && WeaponIsForPerk(Class<KFWeaponPickup>(W.PickupClass)) )
		R*=1.5;
	if( !W.bMeleeWeapon && Enemy!=None && VSize(Enemy.Location-Pawn.Location)>W.GetFireMode(0).MaxRange() )
		R*=0.15;
	if( Pawn.Health <= 25 && Knife(W)!=None ) // Try not to use knife when low on health
		return 0.05; 
	if ( Single(W) != None && Single(W).AmmoAmount(0) < 15 ) // Try to spare our last mag 
		return 0.1;
	return R;
}

function float AdjustDesireFor(Pickup P)
{
	if( KFWeaponPickup(P)!=None )
	{
		if( !WeaponIsForPerk(Class<KFWeaponPickup>(P.Class)) )
			return -0.5f; // Try not to get weapons that are not for the perk.
	}
	return 0.5f;
}

final function bool WeaponIsForPerk( class<KFWeaponPickup> Wep )
{
	if( KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill==None )
		return true;
	if (KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.Default.VeterancyName == "Field Medic" || KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.Default.VeterancyName == "Sergeant") //no perk weapons for these guys
		return true;
	return (Wep.Default.CorrespondingVeterancyName==KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.Default.VeterancyName);
}

// AdjustView() called if Controller's pawn is viewtarget of a player
function AdjustView(float DeltaTime)
{
    Super(Controller).AdjustView(DeltaTime);
    SmoothBotRotation(DeltaTime);
}

final function SmoothBotRotation(float DeltaTime)
{
    local float Alpha;
    local rotator TargetRotation, ViewRotation;
    local vector TargetPoint;

    TargetRotation = Rotation;
    if( Pawn != None )
    {
        if( NavigationPoint(Focus) != None )
            TargetPoint = Focus.Location + FClamp(Pawn.CollisionHeight - Focus.CollisionHeight,-32,32)*vect(0,0,1);
        else if( Focus != None )
            TargetPoint = Focus.Location;
        else
            TargetPoint = FocalPoint;

        TargetRotation.Pitch = rotator(TargetPoint - Pawn.Location).Pitch;
    }

    Alpha = FClamp((SmoothTurnSpeed * DeltaTime) / (acos(vector(TargetRotation) dot vector(LastViewRotation))/PI),0,1);
    if( Alpha == Alpha && Alpha + 1.0 != Alpha ) // NaN & Inf check
    {
        ViewRotation = QuatToRotator(QuatSlerp( QuatFromRotator(LastViewRotation), QuatFromRotator(TargetRotation), Alpha ));
        ViewRotation.Roll = 0;

        //Log("SmoothBotRotation" #DeltaTime #Angle #FAngle #Alpha #GON(Focus) #Rotation.Pitch #TargetRotation.Pitch #ViewRotation.Pitch);
        SetRotation( ViewRotation );
    }
    LastViewRotation = ViewRotation;
}

state Healing
{
ignores WaitForMover;

	function BeginState()
	{
		SetBotSprinting(true);
	}
	function EndState()
	{
		SetBotSprinting(false);
	}
	final function bool TryToHealthTarget() // Healing hack, because syringe acts up for bots.
	{
		local vector V;
		local WeaponFire F;
		local int MedicReward,HealSum;
		local KFPlayerReplicationInfo PRI;

		if( InjuredAlly==None || InjuredAlly.Health<=0 )
			return false;

		// First reject if out of ammo, distance or not visible.
		F = MySyringe.GetFireMode(0);
		V = (InjuredAlly.Location-Pawn.Location);
		if( NextMedicFireTime>Level.TimeSeconds || InjuredAlly.Health<=0 || !F.AllowFire() || Abs(V.Z)>(Pawn.CollisionHeight+InjuredAlly.CollisionHeight+20.f)
		|| (Square(V.X)+Square(V.Y))>Square(Pawn.CollisionRadius+InjuredAlly.CollisionRadius+50.f) || !FastTrace(InjuredAlly.Location,Pawn.Location) )
			return false;
		
		NextMedicFireTime = Level.TimeSeconds+F.FireRate;
		PRI = KFPlayerReplicationInfo(PlayerReplicationInfo);
		MySyringe.ConsumeAmmo(0, F.AmmoPerFire);
		MedicReward = MySyringe.HealBoostAmount;

		if ( PRI!=None && PRI.ClientVeteranSkill!=none )
			MedicReward *= PRI.ClientVeteranSkill.Static.GetHealPotency();
			
		HealSum = MedicReward;

		if ( (InjuredAlly.Health + InjuredAlly.healthToGive + MedicReward) > InjuredAlly.HealthMax )
			MedicReward = Max(InjuredAlly.HealthMax - (InjuredAlly.Health + InjuredAlly.healthToGive),0);

		InjuredAlly.GiveHealth(HealSum, InjuredAlly.HealthMax);

		if ( PRI != None )
		{
            // Give the medic reward money as a percentage of how much of the person's health they healed
			MedicReward = int((FMin(float(MedicReward),InjuredAlly.HealthMax)/InjuredAlly.HealthMax) * 60); // Increased to 80 in Balance Round 6, reduced to 60 in Round 7
		}
		MySyringe.PlayOwnedSound(Sound'KFWeaponSound.SyringeFire',SLOT_Interact,F.TransientSoundVolume,,F.TransientSoundRadius,,false);
		MySyringe.IncrementFlashCount(0);
		return true;
	}
	function Timer()
	{
		if( InjuredAlly==None || InjuredAlly.Health<=0 || (InjuredAlly.Health+InjuredAlly.HealthToGive)>=GetMinHealingValue() )
		{
			InjuredAlly = None;
			LastHealTime = level.TimeSeconds+1;
			WhatToDoNext(162);
			return;
		}
		if ( Pawn.Weapon==MySyringe )
			TryToHealthTarget();
	}
	final function SelectSyringe()
	{
		if( Pawn.Weapon==MySyringe )
			return;
		Pawn.PendingWeapon = MySyringe;
		if ( Pawn.Weapon==None )
			Pawn.ChangedWeapon();
		else if( !Pawn.Weapon.HasAmmo() ) // Most likely weapon is stuck here.
		{
			Pawn.Weapon.PutDown();
			Pawn.Weapon.ClientState = WS_PutDown;
			Pawn.Weapon.Timer();
		}
		else Pawn.Weapon.PutDown();
	}
Begin:
	SwitchToBestWeapon();
	WaitForLanding();
	SetTimer(0.1+FRand()*0.2, True);

	while( InjuredAlly!=None && InjuredAlly.Health>0 && VSize(InjuredAlly.Location-Pawn.Location)<1000.f )
	{
		SelectSyringe();

		if( FindBestPathToward(InjuredAlly,false,false) )
			MoveToward(MoveTarget,InjuredAlly,,true);
		else break;
	}

	LastHealTime = level.TimeSeconds+4;
	WhatToDoNext(163);
	if ( bSoaking )
		SoakStop("STUCK IN HEALING!");
}

final function bool VerifyBlockingVolume( BlockingVolume V )
{
	local bool bPlayers,bMonsters;
	local int i;

	if( V==None || !V.bClassBlocker )
		return false;
	for( i=0; i<V.BlockedClasses.Length; ++i )
	{
		bPlayers = bPlayers || ClassIsChildOf(V.BlockedClasses[i],class'KFHumanPawn');
		bMonsters = bMonsters || ClassIsChildOf(V.BlockedClasses[i],class'KFMonster');
	}
	return (bPlayers && !bMonsters);
}

event bool NotifyHitWall(vector HitNormal, actor Wall)
{
	if( PreviousNavPath!=None )
	{
		if( VerifyBlockingVolume(BlockingVolume(Wall)) )
		{
			// debugf;
			TempBlockedPaths.Insert(0,1);
			TempBlockedPaths[0] = PreviousNavPath;
			if( TempBlockedPaths.Length>4 )
				TempBlockedPaths.Length = 4;
			PreviousNavPath = None;
		}
	}
	if( CurrentPath!=None && KFDoorMover(Wall)!=None && KFDoorMover(Wall).bSealed && !KFDoorMover(Wall).bDisallowWeld )
	{
		AddSealPath(CurrentPath,KFDoorMover(Wall));
		MoveTarget = Pawn.Anchor;
	}
	return Super.NotifyHitWall(HitNormal, Wall);
}

final function AddSealPath( ReachSpec Spec, KFDoorMover Door )
{
	local int i;
	
	for( i=0; i<DoorPaths.Length; ++i )
		if( DoorPaths[i].Door==Door && DoorPaths[i].Path==Spec )
			return;

	// debugf;
	i = DoorPaths.Length;
	DoorPaths.Length = i+1;
	DoorPaths[i].Door = Door;
	DoorPaths[i].Path = Spec;
}

function Possess(Pawn aPawn)
{
	Super.Possess(aPawn);
	if( Vehicle(Pawn)==none && Pawn!=None )
	{
		Pawn.MaxFallSpeed = FMax(Pawn.MaxFallSpeed,2000.f); // Hack, but to prevent bots from keep dying at offices.
		if( xPawn(Pawn)!=None )
		{
			xPawn(Pawn).bCanDoubleJump = true; // To stop them from getting stuck at jumps only zeds can make.
			xPawn(Pawn).MaxMultiJump = 1;
			xPawn(Pawn).MultiJumpRemaining = 1;
			xPawn(Pawn).JumpZ += 30.f;
		}
	}
}

function SetPawnClass(string inClass, string inCharacter);


/* ChooseAttackMode()
Handles tactical attacking state selection - choose which type of attack to do from here
*/
function ChooseAttackMode()
{
    GoalString = " ChooseAttackMode last seen "$(Level.TimeSeconds - LastSeenTime);
    // should I run away?
    if ( (Squad == None) || (Enemy == None) || (Pawn == None) )
        log("HERE 1 Squad "$Squad$" Enemy "$Enemy$" pawn "$Pawn);

	if ( (Pawn.Health / Pawn.HealthMax) <= 0.25 || VSize(Location - Enemy.Location) < 50.f && Pawn.Weapon != none && !Pawn.Weapon.bMeleeWeapon)
		DoRetreat();

	if(ThrowAwayBadWeaponForBetterPickup()) // While fighting, throw away bad weapon for better pickup
		GoalString = "ChooseAttackMode - Throwing away bad weapon for pickup";
	
    if ( (Squad.PriorityObjective(self) == 0) && (Pawn.Weapon.CurrentRating < 0.5) )
    {
        // fallback to better pickup?   No.  you're in a combat sitatuion. 
        // being choosy about pickups should only come at round end. (for bots)
        if ( FindInventoryGoal(0) )
        {
			//SendChatMsg("Falling back to pickup better weapon.");
            if ( InventorySpot(RouteGoal) == None )
                GoalString = "fallback - inventory goal is not pickup but "$RouteGoal;
            else
                GoalString = "Fallback to better pickup "$InventorySpot(RouteGoal).markedItem$" hidden "$InventorySpot(RouteGoal).markedItem.bHidden;
            GotoState('FallBack');
            return;
        } 
    }

    GoalString = "ChooseAttackMode FightEnemy";
    FightEnemy(true, RelativeStrength(Enemy));
}

function bool FindSuperPickup(float MaxDist)
{
	return false;
}

function rotator AdjustAim(FireProperties FiredAmmunition, vector projStart, int aimerror)
{
	local rotator FireRotation, TargetLook;
	local float FireDist, TargetDist, ProjSpeed,TravelTime, TossedZ;
	local actor HitActor;
	local vector FireSpot, FireDir, TargetVel, HitLocation, HitNormal;
	local int realYaw;
	local bool bDefendMelee, bClean, bLeadTargetNow;

	if ( FiredAmmunition.ProjectileClass != None )
	{
		TossedZ = FiredAmmunition.ProjectileClass.default.TossZ;
		projspeed = FiredAmmunition.ProjectileClass.default.speed;
	}

	// make sure bot has a valid target
	if ( Target == None )
	{
		Target = Enemy;
		if ( Target == None )
			return Rotation;
	}

	if ( Pawn(Target) != None )
		Target = Pawn(Target).GetAimTarget();

	FireSpot = Target.Location;
	TargetDist = VSize(Target.Location - Pawn.Location);

	// perfect aim at stationary objects
	if ( Pawn(Target) == None )
	{
		if ( !FiredAmmunition.bTossed )
			return rotator(Target.Location - projstart);
		else
		{
			FireDir = AdjustToss(projspeed,ProjStart,Target.Location-(vect(0,0,1)*TossedZ),true);
			SetRotation(Rotator(FireDir));
			return Rotation;
		}
	}

	bLeadTargetNow = FiredAmmunition.bLeadTarget && bLeadTarget;
	bDefendMelee = ( (Target == Enemy) && DefendMelee(TargetDist) );
	aimerror = AdjustAimError(aimerror,TargetDist,bDefendMelee,FiredAmmunition.bInstantHit, bLeadTargetNow);

	// lead target with non instant hit projectiles
	if ( bLeadTargetNow )
	{
		TargetVel = Target.Velocity;
		TravelTime = TargetDist/projSpeed;
		// hack guess at projecting falling velocity of target
		if ( Target.Physics == PHYS_Falling )
		{
			if ( Target.PhysicsVolume.Gravity.Z <= Target.PhysicsVolume.Default.Gravity.Z )
				TargetVel.Z = FMin(TargetVel.Z + FMax(-400, Target.PhysicsVolume.Gravity.Z * FMin(1,TargetDist/projSpeed)),0);
			else
			{
				TargetVel.Z = TargetVel.Z + 0.5 * TravelTime * Target.PhysicsVolume.Gravity.Z;
				FireSpot = Target.Location + TravelTime*TargetVel;
			 	HitActor = Trace(HitLocation, HitNormal, FireSpot, Target.Location, false);
			 	bLeadTargetNow = false;
			 	if ( HitActor != None )
			 		FireSpot = HitLocation + vect(0,0,2);
			}
		}

		if ( bLeadTargetNow )
		{
			// more or less lead target (with some random variation)
			FireSpot += FMin(1, 0.7 + 0.6 * FRand()) * TargetVel * TravelTime;
			FireSpot.Z = FMin(Target.Location.Z, FireSpot.Z);
		}
		if ( (Target.Physics != PHYS_Falling) && (FRand() < 0.55) && (VSize(FireSpot - ProjStart) > 1000) )
		{
			// don't always lead far away targets, especially if they are moving sideways with respect to the bot
			TargetLook = Target.Rotation;
			if ( Target.Physics == PHYS_Walking )
				TargetLook.Pitch = 0;
			bClean = ( ((Vector(TargetLook) Dot Normal(Target.Velocity)) >= 0.71) && FastTrace(FireSpot, ProjStart) );
		}
		else // make sure that bot isn't leading into a wall
			bClean = FastTrace(FireSpot, ProjStart);
		if ( !bClean)
		{
			// reduce amount of leading
			if ( FRand() < 0.3 )
				FireSpot = Target.Location;
			else
				FireSpot = 0.5 * (FireSpot + Target.Location);
		}
	}

	bClean = false; //so will fail first check unless shooting at feet
	if ( FiredAmmunition.bTrySplash && (Pawn(Target) != None) && ((Skill >=4) || bDefendMelee)
		&& (((Target.Physics == PHYS_Falling) && (Pawn.Location.Z + 80 >= Target.Location.Z))
			|| ((Pawn.Location.Z + 19 >= Target.Location.Z) && (bDefendMelee || (skill > 6.5 * FRand() - 0.5)))) )
	{
	 	HitActor = Trace(HitLocation, HitNormal, FireSpot - vect(0,0,1) * (Target.CollisionHeight + 6), FireSpot, false);
 		bClean = (HitActor == None);
		if ( !bClean )
		{
			FireSpot = HitLocation + vect(0,0,3);
			bClean = FastTrace(FireSpot, ProjStart);
		}
		else
			bClean = ( (Target.Physics == PHYS_Falling) && FastTrace(FireSpot, ProjStart) );
	}
	if ( Pawn.Weapon != None && Pawn.Weapon.bSniping && Stopped() )
	{
		// try head
 		FireSpot.Z = Target.Location.Z + 0.9 * Target.CollisionHeight;
 		bClean = FastTrace(FireSpot, ProjStart);
	}

	if ( !bClean )
	{
		//try middle
		FireSpot.Z = Target.Location.Z;
 		bClean = FastTrace(FireSpot, ProjStart);
	}
	if ( FiredAmmunition.bTossed && !bClean && bEnemyInfoValid )
	{
		FireSpot = LastSeenPos;
	 	HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
		if ( HitActor != None )
		{
			bCanFire = false;
			FireSpot += 2 * Target.CollisionHeight * HitNormal;
		}
		bClean = true;
	}

	if( !bClean )
	{
		// try head
 		FireSpot.Z = Target.Location.Z + 0.9 * Target.CollisionHeight;
 		bClean = FastTrace(FireSpot, ProjStart);
	}
	if ( !bClean && (Target == Enemy) && bEnemyInfoValid )
	{
		FireSpot = LastSeenPos;
		if ( Pawn.Location.Z >= LastSeenPos.Z )
			FireSpot.Z -= 0.4 * Enemy.CollisionHeight;
	 	HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
		if ( HitActor != None )
		{
			FireSpot = LastSeenPos + 2 * Enemy.CollisionHeight * HitNormal;
			if ( Pawn.Weapon != None && Pawn.Weapon.SplashDamage() && (Skill >= 4) )
			{
			 	HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
				if ( HitActor != None )
					FireSpot += 2 * Enemy.CollisionHeight * HitNormal;
			}
			if ( Pawn.Weapon != None && Pawn.Weapon.RefireRate() < 0.99 )
				bCanFire = false;
		}
	}

	// adjust for toss distance
	if ( FiredAmmunition.bTossed )
		FireDir = AdjustToss(projspeed,ProjStart,FireSpot-(vect(0,0,1)*TossedZ),true);
	else
	{
		FireDir = FireSpot - ProjStart;
		if ( Pawn(Target) != None )
			FireDir = FireDir + Pawn(Target).GetTargetLocation() - Target.Location;
	}

	FireRotation = Rotator(FireDir);
	realYaw = FireRotation.Yaw;

	FireRotation.Yaw = SetFireYaw(FireRotation.Yaw + aimerror);
	FireDir = vector(FireRotation);
	// avoid shooting into wall
	FireDist = FMin(VSize(FireSpot-ProjStart), 400);
	FireSpot = ProjStart + FireDist * FireDir;
	HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
	if ( HitActor != None )
	{
		if ( HitNormal.Z < 0.7 )
		{
			FireRotation.Yaw = SetFireYaw(realYaw - aimerror);
			FireDir = vector(FireRotation);
			FireSpot = ProjStart + FireDist * FireDir;
			HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
		}
		if ( HitActor != None )
		{
			FireSpot += HitNormal * 2 * Target.CollisionHeight;
			if ( Skill >= 4 )
			{
				HitActor = Trace(HitLocation, HitNormal, FireSpot, ProjStart, false);
				if ( HitActor != None )
					FireSpot += Target.CollisionHeight * HitNormal;
			}
			FireDir = Normal(FireSpot - ProjStart);
			FireRotation = rotator(FireDir);
		}
	}
	InstantWarnTarget(Target,FiredAmmunition,vector(FireRotation));
	ShotTarget = Pawn(Target);

	SetRotation(FireRotation);
	return FireRotation;
}

final function SendChatMsg( string S )
{
	if(Pawn.Health > 0)
		Level.Game.Broadcast(self, "["$PlayerReplicationInfo.GetCallSign()$"] "$S, 'TeamSayQuiet');
}

final function bool TryToHealSelf()
{
	if ( MySyringe==none || MySyringe.ChargeBar() < 0.99f )
		return false;
	GoToState('GoHealSelf');
	return true;
}

final function int GetMinHealingValue()
{
	if(KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.default.VeterancyName == "Berserker") // Berserkers heal less
		return 20;
	else if( (Level.TimeSeconds-LastEnemyEncounter)>10.f )
		return 99;
	else if( (Level.TimeSeconds-LastEnemyEncounter)>3.f )
		return 75;
	return 50;
}

final function bool ManyEnemiesAround(int MinEnemies)
{
    local Controller C;
    local int NearbyEnemies;

    for (C = Level.ControllerList; C != None; C = C.nextController)
    {
        if (KFMonster(C.Pawn) != None && KFMonster(C.Pawn).Health > 0)
        {
            if (VSize(C.Pawn.Location - Pawn.Location) < 800.f && FastTrace(Pawn.Location, C.Pawn.Location))
            {
                ++NearbyEnemies;
                if (NearbyEnemies >= MinEnemies)
                    return true;
            }
        }
    }
    return false;
}

function KFHumanPawn NearbyAllyNeedsHealing()
{
	local Controller C;
	local KFHumanPawn Ally;

	// Check if the bot is a Field Medic
	if (KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.default.VeterancyName == "Field Medic")
	{
		// Find the nearest injured ally
		for (C = Level.ControllerList; C != None; C = C.nextController)
		{
			Ally = KFHumanPawn(C.Pawn);
			if (Ally != None && Ally.Health > 0 && Ally.Health < 55 && VSize(Ally.Location - Pawn.Location) < 300.f)
			{
				return Ally;
			}
		}
	}
	return None;
}

//Better to rewrite this, make it more suited for KF shit
function FightEnemy(bool bCanCharge, float EnemyStrength)
{
	local vector X,Y,Z;
	local float enemyDist;
	local float AdjustedCombatStyle;
	local bool bFarAway, bOldForcedCharge;

	if ( (Squad == None) || (Enemy == None) || (Pawn == None) )
		log("HERE 3 Squad "$Squad$" Enemy "$Enemy$" pawn "$Pawn);

	if( NextTargetCheck<Level.TimeSeconds )
	{
		FindBetterTarget();	
		NextTargetCheck = Level.TimeSeconds+1.f;
	}
	if( Enemy!=None )
		LastEnemyEncounter = Level.TimeSeconds;
	if (Pawn.Health < GetMinHealingValue() && !ManyEnemiesAround(2) && StartleActor == None && TryToHealSelf() ) // 5% to 55% chance based on how low health is)
		return;
	if( NextNadeTimer<Level.TimeSeconds && MyGrenades!=None && MyGrenades.HasAmmo() && (Rand(2)==0 || ManyEnemiesAround(5)) && ShouldNadeEnemy() )
	{
		NextNadeTimer = Level.TimeSeconds+6.f+FRand()*5.f;
		GoalString = "NadeEnemy";
		GoToState('NadeTarget');
		return;
	}
	else NextNadeTimer = Level.TimeSeconds+1.f+FRand()*4.f;

	if( EnemyReallyScary() )
	{
		GoalString = "Retreat from scary during fight";
		SendMessage(None, 'OTHER', GetMessageIndex('NEEDBACKUP'), 12, 'TEAM');
		DoRetreat();
		return;
	}

	bOldForcedCharge = bMustCharge;
	bMustCharge = false;
	enemyDist = VSize(Pawn.Location - Enemy.Location);
	AdjustedCombatStyle = CombatStyle + Pawn.Weapon.SuggestAttackStyle();
	Aggression = 1.5 * FRand() - 0.8 + 2 * AdjustedCombatStyle - 0.5 * EnemyStrength
				+ FRand() * (Normal(Enemy.Velocity - Pawn.Velocity) Dot Normal(Enemy.Location - Pawn.Location));
	if ( Enemy.Weapon != None )
		Aggression += 2 * Enemy.Weapon.SuggestDefenseStyle();
	if ( enemyDist > MAXSTAKEOUTDIST )
		Aggression += 0.5;
	if ( (Pawn.Physics == PHYS_Walking) || (Pawn.Physics == PHYS_Falling) )
	{
		if (Pawn.Location.Z > Enemy.Location.Z + TACTICALHEIGHTADVANTAGE)
			Aggression = FMax(0.0, Aggression - 1.0 + AdjustedCombatStyle);
		else if ( (Skill < 4) && (enemyDist > 0.65 * MAXSTAKEOUTDIST) )
		{
			bFarAway = true;
			Aggression += 0.5;
		}
		else if (Pawn.Location.Z < Enemy.Location.Z - Pawn.CollisionHeight) // below enemy
			Aggression += CombatStyle;
	}

	if ( !EnemyVisible() )
	{
		if ( Squad.MustKeepEnemy(Enemy) )
		{
			GoalString = "Hunt priority enemy";
			GotoState('Hunting');
			return;
		}
		GoalString = "Enemy not visible";
		if ( !bCanCharge )
		{
			GoalString = "Stake Out - no charge";
			DoStakeOut();
		}

		else if ( Squad.IsDefending(self) && LostContact(4) && ClearShot(LastSeenPos, false) )
		{
			GoalString = "Stake Out "$LastSeenPos;
			DoStakeOut();
		}
		else if ( (((Aggression < 1) && !LostContact(3+2*FRand())) || IsSniping()) && CanStakeOut() )
		{
			GoalString = "Stake Out2";
			DoStakeOut();
		}
		else
		{
			GoalString = "Hunt";
			GotoState('Hunting');
		}
		return;
	}

	// see enemy - decide whether to charge it or strafe around/stand and fire
	BlockedPath = None;
	Target = Enemy;

	if( (Pawn.Weapon.bMeleeWeapon || (bCanCharge && bOldForcedCharge)) )
	{
		GoalString = "Charge";
		DoCharge();
		return;
	}
	if ( Pawn.RecommendLongRangedAttack() )
	{
		GoalString = "Long Ranged Attack";
		DoRangedAttackOn(Enemy);
		return;
	}

	if ( bCanCharge && (Skill < 5) && bFarAway && (Aggression > 1) && (FRand() < 0.5) )
	{
		GoalString = "Charge closer";
		DoCharge();
		return;
	}

	if ( Pawn.Weapon.RecommendRangedAttack() || IsSniping() || ((FRand() > 0.17 * (skill + Tactics - 1)) && !DefendMelee(enemyDist)) )
	{
		GoalString = "Ranged Attack";
		DoRangedAttackOn(Enemy);
		return;
	}

	if ( bCanCharge )
	{
		if ( Aggression > 1 )
		{
			GoalString = "Charge 2";
			DoCharge();
			return;
		}
	}
	GoalString = "Do tactical move";
	if ( !Pawn.Weapon.RecommendSplashDamage() && (FRand() < 0.7) && (3*Jumpiness + FRand()*Skill > 3) )
	{
		GetAxes(Pawn.Rotation,X,Y,Z);
		GoalString = "Try to Duck ";
		if ( FRand() < 0.5 )
		{
			Y *= -1;
			TryToDuck(Y, true);
		}
		else
			TryToDuck(Y, false);
	}
	DoTacticalMove();
}

function NotifyKilled(Controller Killer, Controller Killed, pawn KilledPawn)
{
	if( Killer==Self && FRand()<0.4 )
		SendMessage(None, 'INSULT', 0, 15, 'TEAM'); // Insult Specimen
	Super.NotifyKilled(Killer,Killed,KilledPawn);
}

//Basically replaced with TryStrafe
function bool TryToDuck(vector duckDir, bool bReversed)
{
	local vector extent, HitLocation, HitNormal;
	local actor HitActor;

	Extent = Pawn.GetCollisionExtent();
	HitActor = Trace(HitLocation, HitNormal, Pawn.Location + MINSTRAFEDIST * duckDir, Pawn.Location, false, Extent);
	if (HitActor != None)
	{
		duckDir *= -1;
		HitActor = Trace(HitLocation, HitNormal, Pawn.Location + MINSTRAFEDIST * duckDir, Pawn.Location, false, Extent);
	}
	if (HitActor != None)
		return false;

	if ( Pawn.Physics == PHYS_Walking )
	{
		HitActor = Trace(HitLocation, HitNormal, Pawn.Location + MINSTRAFEDIST * duckDir - MAXSTEPHEIGHT * vect(0,0,1), Pawn.Location + MINSTRAFEDIST * duckDir, false, Extent);
		if ( HitActor == None )
			return false;
	}
	Destination = Pawn.Location + 2 * MINSTRAFEDIST * duckDir;
	GotoState('TacticalMove', 'DoStrafeMove');
	return true;
}

state MoveToGoalNoEnemy
{
    function BeginState()
    {
        Super.BeginState();
        SetBotSprinting(true);
    }
	event bool NotifyHitWall(vector HitNormal, actor Wall)
	{
		if( KFDoorMover(Wall)!=None && KFDoorMover(Wall).bSealed && !KFDoorMover(Wall).bDisallowWeld )
			UnWeldFromRoom(KFDoorMover(Wall));
		return Super.NotifyHitWall(HitNormal,Wall);
	}
    function EndState()
    {
		Super.EndState();
        SetBotSprinting(false);
    }
}

state RangedAttack
{
	final function PickMoveDest()
	{
		local bool bScary;
		
		bScary = EnemyReallyScary();
		if ( (Pawn.Weapon != None) && Pawn.Weapon.bMeleeWeapon && !bScary )
		{
			//log("RangedAttack: Melee weapon, picking next move");
			MoveTarget = Target;
			return;
		}
		if( bScary )
			PickNextRetMove();
		Destination = Pawn.Location+VRand()*200.f;
	}
Begin:
	bHasFired = false;
	if ( (Pawn.Weapon != None) && Pawn.Weapon.bMeleeWeapon )
		SwitchToBestWeapon();
	GoalString = GoalString@"Ranged attack";
	Focus = Target;
	Sleep(0.0);
	if ( Target == None )
		WhatToDoNext(335);

	Pawn.bWantsToCrouch = false;
	if ( NeedToTurn(Target.Location) )
	{
		Focus = Target;
		FinishRotation();
	}
	bHasFired = true;
	if ( Target == Enemy )
		TimedFireWeaponAtEnemy();
	else
		FireWeaponAt(Target);
	Sleep(0.1);
	if ( (Target == None) || ((Target != Enemy) && (GameObjective(Target) == None) && (Enemy != None) && EnemyVisible()) )
		WhatToDoNext(35);
	Focus = Target;
	PickMoveDest();
	if( MoveTarget!=None )
		MoveToward(MoveTarget,Target);
	else MoveTo(Destination,Target);
	
	WhatToDoNext(36);
	if ( bSoaking )
		SoakStop("STUCK IN RANGEDATTACK!");
}
state NadeTarget
{
	ignores	SetEnemy,NotifyBump;

	final function TossNade()
	{
		if (MyGrenades != None)
		{
			FragFire(MyGrenades.GetFireMode(0)).mHoldSpeedMax = VSize(Target.Location - Pawn.Location);
			MyGrenades.ServerThrow();
		}
		else
		{
			SendChatMsg("No grenades available to throw!");
		}
	}
	function EndState()
	{
		if( KFPawn(Pawn)!=none )
			KFPawn(Pawn).bThrowingNade = false;
	}
Begin:
	Target = NearbyAllyNeedsHealing();
	if (Target != None)
	{
		if(Target != Pawn)
			SendChatMsg("Let me toss you a heal, "$Pawn(Target).PlayerReplicationInfo.PlayerName$"!");
		else 
			SendChatMsg("I need to heal myself!");
	}
	else if (Enemy != None)
	{
		Target = Enemy; // Default behavior: toss grenade at the enemy
	}
	else
	{
		// No valid target found
		//SendChatMsg("No valid target for grenade!");
		WhatToDoNext(153);
	}
	if ( NeedToTurn(Target.Location) )
	{
		Focus = Target;
		FinishRotation();
	}
	Sleep(0.1f);
	if( KFPawn(Pawn) != none )
		KFPawn(Pawn).SetAnimAction('NadeToss');
	Sleep(0.2);
	TossNade();
	Sleep(0.4);
	if(rand(1)==0 && ManyEnemiesAround(5) && MyGrenades.HasAmmo())
		GoTo'Begin';
	WhatToDoNext(153);
	if ( bSoaking )
		SoakStop("STUCK IN NADES!");
}

function bool PickRetreatDestination()
{
	local actor BestPath;

	if ( FindInventoryGoal(0) )
		return true;

	if ( (RouteGoal == None) || (Pawn.Anchor == RouteGoal) || Pawn.ReachedDestination(RouteGoal) )
	{
		RouteGoal = GetRandomDest();
		BestPath = RouteCache[0];
		if ( RouteGoal == None )
			return false;
	}
	if ( BestPath!=None )
		MoveTarget = BestPath;
	else if( !FindBestPathToward(RouteGoal,true,true) )
	{
		RouteGoal = None;
		return false;
	}
	return true;
}

final function PickNextRetMove()
{
	local NavigationPoint N;
	local float Dist,BestDist;
	local int i;
	local vector EnemyDir;
    local Controller C;
    local KFMonster M;
    local float Weight, TotalWeight;
    local bool bAnyMonsterHasLOS;

	if( CurrentMov==None )
	{
		for( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
		{
			Dist = VSize(N.Location-Pawn.Location);
			if( Dist<100.f )
			{
				CurrentMov = N;
				GoTo'MoveFound';
			}
			else if( CurrentMov==None || Dist<BestDist )
			{
				CurrentMov = N;
				BestDist = Dist;
			}
		}
		if( CurrentMov==None || !ActorReachable(CurrentMov) )
			return;
		MoveTarget = CurrentMov;
		return;
	}
	if( VSize(CurrentMov.Location-Pawn.Location)>100.f )
	{
		if( ActorReachable(CurrentMov) )
		{
			MoveTarget = CurrentMov;
			return;
		}
		if( OldMovesCount>0 )
		{
			MoveTarget = OldMoves[0];
			CurrentMov = OldMoves[0];
		}
		else MoveTarget = None;
		return;
	}
MoveFound:
	MoveTarget = None;
	//EnemyDir = Normal(Enemy.Location-Pawn.Location);
	for( i=0; i<TempBlockedPaths.Length; ++i )
		TempBlockedPaths[i].bBlocked = true;
	for( i=0; i<CurrentMov.PathList.Length; i++ )
	{
		N = CurrentMov.PathList[i].End;
		if( N==CurrentMov || N.bBlocked || !ActorReachable(N) )
			continue;
		EnemyDir = vect(0,0,0);
        TotalWeight = 0.0;
        bAnyMonsterHasLOS = false;
        for( C = Level.ControllerList; C != None; C = C.nextController )
        {
            M = KFMonster(C.Pawn);
            if( M == None || M.Health <= 0 || !LineOfSightTo(M) || VSize(M.Location - Pawn.Location) > 600.f )
                continue;

            // Weight closer / focused monsters more
            Weight = 1.0 / FMax(VSize(M.Location - Pawn.Location), 1.0);
            if( C.Enemy == Pawn )
                Weight *= 1.5;

            EnemyDir    += Weight * Normal(M.Location - Pawn.Location);
            TotalWeight += Weight;

            if( C.LineOfSightTo(N) )
                bAnyMonsterHasLOS = true;
        }
        EnemyDir = Normal(EnemyDir / TotalWeight);
		Dist = (EnemyDir dot Normal(N.Location-Pawn.Location));
		if( SpecIsOldMove(N) )
			Dist+=0.35f;
		if ( bAnyMonsterHasLOS )
			Dist += 0.15f;
		else
			Dist -= 0.35f;
        if ( Squad != None )
        {
            if ( Squad.SquadLeader != None && Squad.SquadLeader.Pawn != None && Squad.SquadLeader.Pawn != Pawn )
                Dist -= Normal(Squad.SquadLeader.Pawn.Location - Pawn.Location) dot Normal(N.Location - Pawn.Location) * 0.4f;
            else
                if ( NextSquadMember != None && NextSquadMember.Pawn != None )
                    Dist -= Normal(NextSquadMember.Pawn.Location - Pawn.Location) dot Normal(N.Location - Pawn.Location) * 0.3f; // slightly weaker bias than leader‑following
        }
		if( MoveTarget==None || Dist<BestDist )
		{
			MoveTarget = N;
			BestDist = Dist;
		}
	}
	for( i=0; i<TempBlockedPaths.Length; ++i )
		TempBlockedPaths[i].bBlocked = false;
	if( MoveTarget!=None )
	{
		PreviousNavPath = NavigationPoint(MoveTarget);
		AddOldMove(CurrentMov);
		CurrentMov = PreviousNavPath;
	}
}

final function bool SpecIsOldMove( NavigationPoint N )
{
	local byte i;

	for( i=0; i<OldMovesCount; i++ )
	{
		if( OldMoves[i]==N )
			return true;
	}
	return false;
}

final function AddOldMove( NavigationPoint N )
{
	local byte i;

	if( OldMovesCount<ArrayCount(OldMoves) )
		OldMoves[OldMovesCount++] = N;
	else
	{
		for( i=1; i<ArrayCount(OldMoves); i++ )
			OldMoves[i-1] = OldMoves[i];
		OldMoves[ArrayCount(OldMoves)-1] = N;
	}
}
 
function DoRetreat()
{
	GotoState('Retreating');
}

state Retreating
{
Ignores EnemyNotVisible,NotifyBump,EnemyAquired,WaitForMover;

	function BeginState()
	{
		SetBotSprinting(true);
		Pawn.bWantsToCrouch = false;
		SetTimer(0.1,true);
	}
	function Timer()
	{
		TimedFireWeaponAtEnemy();
	}
	function EndState()
	{
		SetBotSprinting(false);
		//ClearStayingDebugLines();
	}
Begin:
	RetreatTime = Level.TimeSeconds+5.f+FRand()*5.f;
	CurrentMov = None;
	OldMovesCount = 0;
	while( RetreatTime>Level.TimeSeconds )
	{
		WaitForLanding();
Moving:
		if( Enemy==None )
		{
			MoveTo(VRand()*300.f+Pawn.Location,None);
			break;
		}
		Timer();
		PickNextRetMove();
		if( MoveTarget==None )
		{
			if ( PointReachable(Destination) )
                MoveTo(Destination, Enemy);
            else
				MoveTo(Normal(Pawn.Location-Enemy.Location)*400.f+VRand()*200.f+Pawn.Location);
			break;
		}
		else
			MoveToward(MoveTarget,Enemy,,ShouldStrafeTo(MoveTarget));
	}
	WhatToDoNext(44);
	if ( bSoaking )
		SoakStop("STUCK IN RETREAT!");
	goalstring = goalstring$" STUCK IN RETREAT!";
}

state Fallback2 extends Fallback
{
	function bool FireWeaponAt(Actor A)
	{
		return Global.FireWeaponAt(A);
	}
Begin:
	WaitForLanding();

Moving:
    // If we’re in serious danger, behave like a short retreat step first,
    // using the same enemy‑avoidance logic as state Retreating.
    if ( Enemy != None && ( EnemyReallyScary() || ManyEnemiesAround(3) ) )
    {
        // Keep shooting while backing off
        Timer(); // MoveToGoalWithEnemy.Timer() -> TimedFireWeaponAtEnemy()

        PickNextRetMove();

        if ( MoveTarget == None )
        {
            // Same fallback as in state Retreating
            if ( PointReachable(Destination) )
                MoveTo(Destination, Enemy);
            else
                MoveTo(Normal(Pawn.Location - Enemy.Location) * 400.f + VRand() * 200.f + Pawn.Location);
        }
        else
        {
            MoveToward(MoveTarget, Enemy,, ShouldStrafeTo(MoveTarget));
        }
    }
    else
    {
        // Original fallback behaviour: go for the inventory spot,
        // but still fire at the enemy while moving.
        if ( Pawn.bCanPickupInventory && (InventorySpot(MoveTarget) != None) && (Vehicle(Pawn) == None) )
            MoveTarget = InventorySpot(MoveTarget).GetMoveTargetFor(self,0);

        MoveToward(MoveTarget, Enemy, GetDesiredOffset(), ShouldStrafeTo(MoveTarget));
        Timer(); // keep firing as we advance
    }
    WhatToDoNext(14);
    if ( bSoaking )
        SoakStop("STUCK IN FALLBACK!");
    goalstring = goalstring$" STUCK IN FALLBACK!";
}

function Startle(Actor Feared);

function FearThisSpot(AvoidMarker aSpot)
{
    local int i;

    if( Pawn == None )
        return;
	if ( !LineOfSightTo(aSpot) )
		return;
    for( i=0; i<ArrayCount(FearSpots); ++i )
    {
        if( FearSpots[i] == None )
        {
            FearSpots[i] = aSpot;
            return;
        }
    }
    for( i=0; i<ArrayCount(FearSpots); ++i )
    {
        if( VSize(Pawn.Location - FearSpots[i].Location) > VSize(Pawn.Location - aSpot.Location) )
        {
            FearSpots[i] = aSpot;
            return;
        }
    }
}

state StakeOut
{
	ignores EnemyNotVisible;

	event SeePlayer(Pawn SeenPlayer)
	{
		if ( SeenPlayer == Enemy )
		{
			VisibleEnemy = Enemy;
			EnemyVisibilityTime = Level.TimeSeconds;
			bEnemyIsVisible = true;
			if ( ((Pawn.Weapon == None) || !Pawn.Weapon.FocusOnLeader(false)) && (FRand() < 0.5) )
			{
				Focus = Enemy;
				FireWeaponAt(Enemy);
			}
			WhatToDoNext(28);
		}
		else if ( Squad.SetEnemy(self,SeenPlayer) )
		{
			if ( Enemy == SeenPlayer )
			{
				VisibleEnemy = Enemy;
				EnemyVisibilityTime = Level.TimeSeconds;
				bEnemyIsVisible = true;
			}
			WhatToDoNext(29);
		}
	}
}

function bool WeaponFireAgain(float RefireRate, bool bFinishedFire)
{
	LastFireAttempt = Level.TimeSeconds;
	if ( Target == None )
		Target = Enemy;
	if ( Target != None )
	{
		if( !bFinishedFire && Pawn.Weapon.GetFireMode(0).bIsFiring && Pawn.Weapon.GetFireMode(0).bWaitForRelease )
		{
			// Hack: Unstuck shotguns and husk gun.
			if( !Pawn.Weapon.GetFireMode(0).bFireOnRelease || (Pawn.Weapon.GetFireMode(0).NextFireTime-Level.TimeSeconds)<(-1) )
			{
				// debugf;
				Pawn.Weapon.ServerStopFire(0);
			}
			// else DEBUGF(Pawn.Weapon.GetFireMode(0).bWaitForRelease@Pawn.Weapon.GetFireMode(0).bFireOnRelease@(Pawn.Weapon.GetFireMode(0).NextFireTime-Level.TimeSeconds));
			return false;
		}

		if ( !Pawn.IsFiring() )
		{
			if ( (Pawn.Weapon != None && Pawn.Weapon.bMeleeWeapon) || (!NeedToTurn(Target.Location) && LineOfSightTo(Target)) )
			{
				Focus = Target;
				bCanFire = true;
				bStoppedFiring = false;
				if (Pawn.Weapon != None)
				{
					bFireSuccess = Pawn.Weapon.BotFire(bFinishedFire);
// #if DEBUG_MODE
					// DEBUGF(PlayerReplicationInfo.PlayerName@bFireSuccess);
					// if( !bFireSuccess )
						// DEBUGF("Ready:"@Pawn.Weapon.ReadyToFire(0)@(Pawn.Weapon.ClientState==WS_ReadyToFire)@Pawn.Weapon.GetFireMode(0).AllowFire());
// #endif
				}
				else
				{
					Pawn.ChooseFireAt(Target);
					bFireSuccess = true;
				}
				return bFireSuccess;
			}
			else
			{
				bCanFire = false;
			}
		}
		else if ( bCanFire && ShouldFireAgain(RefireRate))
		{
			if ( (Target != None) && !NeedToTurn(Target.Location) && !Target.bDeleteMe )
			{
				bStoppedFiring = false;
				if (Pawn.Weapon != None)
				{
					bFireSuccess = Pawn.Weapon.BotFire(bFinishedFire);
// #if DEBUG_MODE
					// DEBUGF(PlayerReplicationInfo.PlayerName@bFireSuccess@"1");
					// if( !bFireSuccess )
						// DEBUGF("Ready:"@Pawn.Weapon.ReadyToFire(0)@(Pawn.Weapon.ClientState==WS_ReadyToFire)@Pawn.Weapon.GetFireMode(0).AllowFire());
// #endif
				}
				else
				{
					Pawn.ChooseFireAt(Target);
					bFireSuccess = true;
				}
				return bFireSuccess;
			}
		}
	}
	StopFiring();
	return false;
}
/* 
function DamageAttitudeTo(Pawn Other, float Damage)
{
	if ( (Pawn.health > 0) && (Damage > 0) && SetEnemy(Other) )
		EnemyAquired();
}
*/
state GoHealSelf
{
	ignores SeePlayer,HearNoise,NotifyBump,FireWeaponAt,EnemyAquired,WaitForMover;

	function BeginState()
	{
		StopFiring();
		HealState = 0;
		SetTimer(0.25f,true);
	}
	function Timer()
	{
		if( Syringe(Pawn.Weapon)==None )
		{
			Pawn.PendingWeapon = MySyringe;
			if( Pawn.Weapon!=None )
				Pawn.Weapon.PutDown();
			else Pawn.ChangedWeapon();
			return;
		}
		if( HealState==0 )
		{
			Pawn.Weapon.StartFire(1);
			HealState++;
		}
		else
		{
			Global.SwitchToBestWeapon();
			WhatToDoNext(8);
		}
	}
	exec function SwitchToBestWeapon();
Begin:
	PickNextRetMove();
	if( MoveTarget==None )
		MoveTo(Normal(Pawn.Location-Enemy.Location)*400.f+VRand()*200.f+Pawn.Location);
	else MoveToward(MoveTarget,Enemy,,ShouldStrafeTo(MoveTarget));
	Pawn.Acceleration = vect(0,0,0);
}

final function bool ShouldNadeEnemy()
{
	local Controller C;
	local KFMonster M,MM,Best;
	local float D,Score,BestScore;

	// Bots who are medics always want to throw heal nades
	if (NearbyAllyNeedsHealing() != None)	
		return true;

	for( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		M = KFMonster(C.Pawn);
		if( M == None || M.Health <= 0 )
			continue;

		D = VSize(M.Location-Pawn.Location);
		if( D>1000.f || !LineOfSightTo(M) ) // Skip enemies too far away or not visible
			continue;
		if( D<300.f && (KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.default.VeterancyName != "Firebug"
		&& KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.default.VeterancyName != "Field Medic" && !bGodMode) ) // Avoid nading too close unless Firebug or Field Medic or god mode!
			continue;
		
		Score = 0.f;
		foreach VisibleCollidingActors(class'KFMonster',MM,600.f,M.Location)
		{
			Score += FMin(MM.Health,200.f) * (1.25f - (VSize(MM.Location-M.Location) / 600.f));
		}
		if( Score>450.f && (Best == None || BestScore < Score) )
		{
			Best = M;
			BestScore = Score;

			// Early exit if a high-priority target is found
            if (BestScore > 600.f)
                break;
		}
	}
	if( Best!=None )
	{
		Enemy = Best;
		return true;
	}
	return false;
}
final function float GetEnemyDesire( KFMonster M, bool bCheckedSight )
{
	local float Cost;

	Cost = VSize(M.Location-Pawn.Location);
	if( Cost<100 )
		Cost*=0.5f; // Close range, much bigger threat.
	Cost*=(1.f/FMax(float(M.ScoringValue)*0.001f,0.7f));
	if( M.Health<50 )
		Cost*=0.75f; // Weaklings...
	if( Enemy==M )
		Cost*=0.85f;
	if( !bCheckedSight && !LineOfSightTo(M) )
		Cost*=2.f;
	if( M.Controller!=None && M.Controller.Enemy==Self )
		Cost*=0.85f;
	return Cost;
}
/* 
function HearNoise(float Loudness, Actor NoiseMaker)
{
	if ( ((ChooseAttackCounter < 2) || (ChooseAttackTime != Level.TimeSeconds)) && NoiseMaker!=None && NoiseMaker.instigator!=None
	 && FastTrace(NoiseMaker.instigator.Location,Pawn.Location) && SetEnemy(NoiseMaker.instigator) )
		EnemyAquired();
}
*/
event SeePlayer(Pawn SeenPlayer)
{
	if ( ((ChooseAttackCounter < 2) || (ChooseAttackTime != Level.TimeSeconds)) && Squad.SetEnemy(self,SeenPlayer) )
		WhatToDoNext(3);
	if ( Enemy == SeenPlayer )
	{
		VisibleEnemy = Enemy;
		EnemyVisibilityTime = Level.TimeSeconds;
		bEnemyIsVisible = true;
	}
	else if( Enemy==None && WeldAssistTimer<Level.TimeSeconds && KFPawn(SeenPlayer)!=None && SeenPlayer.Health>0 && SeenPlayer.IsHumanControlled() && VSize(SeenPlayer.Location-Pawn.Location)<800.f && Welder(SeenPlayer.Weapon)!=None && ActiveWelder!=None && !IsInState('Shopping') )
		CheckWelderAssist(SeenPlayer,Welder(SeenPlayer.Weapon));
}

final function FindBetterTarget()
{
	local Controller C;
	local KFMonster P,BP;
	local float Cost,Best;

	for( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		P = KFMonster(C.Pawn);
		if( P==None || P.Health<=0 || !LineOfSightTo(P) || P.bDecapitated )
			continue;
		Cost = GetEnemyDesire(P,true);
		if( BP==None || Best>Cost )
		{
			BP = P;
			Best = Cost;
		}
	}
	if( BP!=None && BP!=Enemy )
	{
		Enemy = BP;
		Target = BP;
	}
}

function bool NeedWeapon()
{
	local inventory Inv;

	if ( Pawn.Weapon.AIRating > 0.5 )
		return ( !Pawn.Weapon.HasAmmo() );

	// see if have some other good weapon, currently not in use
	for ( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
		if ( (Weapon(Inv) != None) && (Weapon(Inv).AIRating > 0.5) && Weapon(Inv).HasAmmo() )
			return false;

	if(KFHumanPawn(Pawn)!=None && KFHumanPawn(Pawn).CanCarry(0)) //Do we have some space to pick up a weapon?
		return true;

	return true;
}

// Check if should help player weld a door.
final function CheckWelderAssist( Pawn Other, Welder Weld )
{
	local byte i;
	local WeldFire WF;
	
	for( i=0; i<2; ++i )
	{
		WF = WeldFire(Weld.GetFireMode(i));
		if( WF!=None && WF.bIsFiring && KFDoorMover(WF.LastHitActor)!=None )
		{
			if( !ActorReachable(Other) )
				return;
			TargetDoor = KFDoorMover(WF.LastHitActor);
			AssistWeldMode = i;
			GoToState('WeldAssist');
			return;
		}
	}
}

final function UnWeldFromRoom( KFDoorMover WeldedDoor ) // Free us from a sealed room.
{
	TargetDoor = WeldedDoor;
	AssistWeldMode = 1;
	GoToState('WeldAssist');
	return;
}

function SealUpDoor( KFDoorMover Door ) // Called from door whenever bot should unseal this.
{
	if( Enemy!=None && LineOfSightTo(Enemy) && ActiveWelder!=None )
		Return;
	TargetDoor = Door;
	GoToState('UnWeldDoor');
}

State UnWeldDoor
{
	ignores NotifyBump;

	function SwitchToBestWeapon()
	{
		if ( Pawn==None || Pawn.Inventory==None || Pawn.Weapon==ActiveWelder )
			return;
		Pawn.PendingWeapon = ActiveWelder;
		StopFiring();
		if ( Pawn.Weapon == None )
			Pawn.ChangedWeapon();
		else Pawn.Weapon.PutDown();
	}
	function Timer()
	{
		if( Pawn.Weapon==ActiveWelder )
			FireWeaponAt(TargetDoor);
	}
	function bool FireWeaponAt(Actor A)
	{
		Target = A;
		if ( Pawn.Weapon==ActiveWelder )
			return WeaponFireAgain(Pawn.Weapon.RefireRate(),false);
		else return False;
	}
	function bool WeaponFireAgain(float RefireRate, bool bFinishedFire)
	{
		LastFireAttempt = Level.TimeSeconds;
		Target = TargetDoor;
		if( Pawn.Weapon==ActiveWelder )
		{
			Focus = Target;
			bCanFire = true;
			bStoppedFiring = false;
			return Pawn.Weapon.BotFire(bFinishedFire);
		}
		StopFiring();
		return false;
	}
	function vector PickUnWeldOffset()
	{
		local vector V;

		V.Y = FRand()-0.5f;
		return Pawn.Location+Normal(V)*(Pawn.CollisionRadius+10+20*FRand()); // Random offset around door.
	}
Begin:
	Destination = PickUnWeldOffset(); //Move away from door a little so we have space for others
	Sleep(1.0);
UnWeld:
	Acceleration = vect(0,0,0);
	Focus = TargetDoor;
	Target = TargetDoor;
	While( Pawn.Weapon!=ActiveWelder )
	{
		SwitchToBestWeapon();
		Sleep(0.25);
	}
	FireWeaponAt(TargetDoor);
	Sleep(0.5);
	if( TargetDoor.bSealed )
		GoTo'UnWeld';
	Global.SwitchToBestWeapon();
	WhatToDoNext(12);
}

state WeldAssist
{
	function BeginState()
	{
		WeldAssistTimer = Level.TimeSeconds+6.f;
		SetTimer(0,false);
		StopFiring();
	}
	function EndState()
	{
		SetTimer(0.15,true);
		StopFiring();
	}
	function SwitchToBestWeapon()
	{
		if ( Pawn==None || Pawn.Inventory==None || Pawn.Weapon==ActiveWelder )
			return;
		Pawn.PendingWeapon = ActiveWelder;
		StopFiring();
		if ( Pawn.Weapon == None )
			Pawn.ChangedWeapon();
		else Pawn.Weapon.PutDown();
	}
	function Timer()
	{
		if( TargetDoor.bHidden || !TargetDoor.bClosed 
		|| !FastTrace(Pawn.Location,TargetDoor.Location) 
		|| VSize(Pawn.Location-TargetDoor.Location)>ActiveWelder.MeleeWeaponRange )
		{
			WhatToDoNext(45);
			return;
		}
		if( (AssistWeldMode==1 && !TargetDoor.bSealed) || (AssistWeldMode==0 && TargetDoor.WeldStrength>=TargetDoor.MaxWeld) )
		{
			if( !TargetDoor.bSealed && TargetDoor.MyTrigger!=None )
				TargetDoor.MyTrigger.UsedBy(Pawn); // Make bot open door once unwelding is finished.
			WhatToDoNext(46);
			return;
		}
		if( Pawn.Weapon==ActiveWelder )
		{
			Target = TargetDoor;
			ActiveWelder.StartFire(AssistWeldMode);
		}
		else SwitchToBestWeapon();
	}
	event bool NotifyHitWall(vector HitNormal, actor Wall)
	{
		if( Wall==TargetDoor )
		{
			GoToState(,'WeldDoor');
			SetTimer(0.15,true);
		}
		return true;
	}
	function bool WeaponFireAgain(float RefireRate, bool bFinishedFire)
	{
		if( Pawn.Weapon!=ActiveWelder )
		{
			StopFiring();
			return false;
		}
		return true; // Keep welding.
	}
Begin:
	SwitchToBestWeapon();
	MoveToward(TargetDoor);
	WhatToDoNext(43);
    // If we are close enough to the door and can see it, start welding
    if ( TargetDoor != None 
	&& VSize(Pawn.Location - TargetDoor.Location) <= ActiveWelder.MeleeWeaponRange 
	&& FastTrace(TargetDoor.Location, Pawn.Location) )
    {
        GoToState(,'WeldDoor');
        SetTimer(0.15, true);
    }
    else
    {
        WhatToDoNext(43);
    }
WeldDoor:
	WeldAssistTimer = Level.TimeSeconds+12.f;
	Pawn.Acceleration = vect(0,0,0);
	Sleep(10.f);
	WhatToDoNext(44);
}

state TacticalMove
{
ignores SeePlayer, HearNoise;

	function DoTacticalMove()
	{
		TimedFireWeaponAtEnemy();
		GotoState('TacticalMove','Begin');
	}
	function EnemyNotVisible()
	{
		StopFiring();
		if ( aggressiveness > relativestrength(enemy) )
		{
			if ( FastTrace(Enemy.Location, LastSeeingPos) )
				GotoState('TacticalMove','RecoverEnemy');
			else
				WhatToDoNext(20);
		}
		Disable('EnemyNotVisible');
	}
	function Timer()
	{
		enable('NotifyBump');
		TimedFireWeaponAtEnemy();
	}
	event NotifyJumpApex()
	{
		if ( bTacticalDoubleJump && !bPendingDoubleJump && (FRand() < 0.4) && (Skill > 2 + 5 * FRand()) )
		{
			bTacticalDoubleJump = false;
			bNotifyApex = true;
			bPendingDoubleJump = true;
		}
		else TimedFireWeaponAtEnemy();
		Global.NotifyJumpApex();
	}
	function PickDestination()
	{
		local vector pickdir, enemydir, enemyPart, Y, LookDir;
		local float strafeSize;
		local bool bFollowingPlayer;

		if ( Pawn == None )
		{
			warn(self$" Tactical move pick destination with no pawn");
			return;
		}
		bChangeDir = false;
		if ( Pawn.PhysicsVolume.bWaterVolume && !Pawn.bCanSwim && Pawn.bCanFly)
		{
			Destination = Pawn.Location + 75 * (VRand() + vect(0,0,1));
			Destination.Z += 100;
			return;
		}

		enemydir = Normal(Enemy.Location - Pawn.Location);
		Y = (enemydir Cross vect(0,0,1));
		if ( Pawn.Physics == PHYS_Walking )
		{
			Y.Z = 0;
			enemydir.Z = 0;
		}
		else
			enemydir.Z = FMax(0,enemydir.Z);

		if( (Pawn.Weapon!=None && !Pawn.Weapon.bMeleeWeapon && VSize(Enemy.Location-Pawn.Location)<600.f)) // Back off if enemy is closer than 600 or really scary
			if ( EngageDirection(-enemydir, false) )
				return;

		bFollowingPlayer = ( (PlayerController(Squad.SquadLeader) != None) && (Squad.SquadLeader.Pawn != None)
							&& (VSize(Pawn.Location - Squad.SquadLeader.Pawn.Location) < 1600) );

		strafeSize = FClamp(((2 * Aggression + 1) * FRand() - 0.65),-0.7,0.7);
		if ( Squad.MustKeepEnemy(Enemy) )
			strafeSize = FMax(0.4 * FRand() - 0.2,strafeSize);

		enemyPart = enemydir * strafeSize;
		strafeSize = FMax(0.0, 1 - Abs(strafeSize));
		pickdir = strafeSize * Y;
		if ( bStrafeDir )
			pickdir *= -1;
		if ( bFollowingPlayer )
		{
			// try not to get in front of squad leader
			LookDir = vector(Squad.SquadLeader.Rotation);
			if ( (LookDir dot (Pawn.Location + (enemypart + pickdir)*MINSTRAFEDIST - Squad.SquadLeader.Pawn.Location))
				> FMax(0,(LookDir dot (Pawn.Location + (enemypart - pickdir)*MINSTRAFEDIST - Squad.SquadLeader.Pawn.Location))) )
			{
				bStrafeDir = !bStrafeDir;
				pickdir *= -1;
			}

		}

		bStrafeDir = !bStrafeDir;

		if ( EngageDirection(enemyPart + pickdir, false) )
			return;

		if ( EngageDirection(enemyPart - pickdir,false) )
			return;

		bForcedDirection = true;
		StartTacticalTime = Level.TimeSeconds;
		EngageDirection(EnemyPart + PickDir, true);
	}

TacticalTick:
	Sleep(0.02);
Begin:
	if ( Enemy == None )
	{
		sleep(0.01);
		Goto('FinishedStrafe');
	}
	if (Pawn.Physics == PHYS_Falling)
	{
		Focus = Enemy;
		Destination = Enemy.Location;
		WaitForLanding();
	}
	if ( Enemy == None )
		Goto('FinishedStrafe');
	PickDestination();

DoMove:
	if( MoveTarget!=None )
		MoveToward(MoveTarget, Enemy);
	else if ( (Pawn.Weapon != None) && Pawn.Weapon.FocusOnLeader(false) )
		MoveTo(Destination, Focus);
	else if ( !Pawn.bCanStrafe )
	{
		StopFiring();
		MoveTo(Destination);
	}
	else
	{
DoStrafeMove:
		MoveTo(Destination, Enemy);
	}
	if ( bForcedDirection && (Level.TimeSeconds - StartTacticalTime < 0.2) )
	{
		if ( !Pawn.HasWeapon() || Skill > 2 + 3 * FRand() )
		{
			bMustCharge = true;
			WhatToDoNext(51);
		}
		GoalString = "RangedAttack from failed tactical";
		DoRangedAttackOn(Enemy);
	}
	if ( (Enemy == None) || EnemyVisible() || !FastTrace(Enemy.Location, LastSeeingPos) || (Pawn.Weapon != None && Pawn.Weapon.bMeleeWeapon) )
		Goto('FinishedStrafe');

RecoverEnemy:
	GoalString = "Recover Enemy";
	HidingSpot = Pawn.Location;
	StopFiring();
	Sleep(0.1 + 0.2 * FRand());
	Destination = LastSeeingPos + 4 * Pawn.CollisionRadius * Normal(LastSeeingPos - Pawn.Location);
	MoveTo(Destination, Enemy);

	if ( FireWeaponAt(Enemy) )
	{
		Pawn.Acceleration = vect(0,0,0);
		if ( (Pawn.Weapon != None) && Pawn.Weapon.SplashDamage() )
		{
			StopFiring();
			Sleep(0.05);
		}
		else
			Sleep(0.1 + 0.3 * FRand() + 0.06 * (7 - FMin(7,Skill)));
		if ( (FRand() + 0.3 > Aggression) )
		{
			Enable('EnemyNotVisible');
			Destination = HidingSpot + 4 * Pawn.CollisionRadius * Normal(HidingSpot - Pawn.Location);
			Goto('DoMove');
		}
	}
FinishedStrafe:
	WhatToDoNext(21);
	if ( bSoaking )
		SoakStop("STUCK IN TACTICAL MOVE!");
}

state Shopping extends MoveToGoalNoEnemy
{
	ignores EnemyNotVisible;

	function float RateWeapon(Weapon W)
	{
		if( KFWeapon(W)==None )
			return Global.RateWeapon(W);
		return FMax(10.f-KFWeapon(W).Weight,0.f)*0.75*int(KFWeapon(W).bMeleeWeapon);
	}
	function EndState()
	{
		Super.EndState();
		bTriedRecoverLastDrop = false;
	}
Begin:
	WaitForLanding();
	AssignPersonality(); // Gain new personality on new wave.
	bHasChecked = False;
	SwitchToBestWeapon();

KeepMoving:
	if( KFGameType(Level.Game).bWaveInProgress )
	{
		LastShopTime = level.TimeSeconds+15+FRand()*15;
		WhatToDoNext(152);
	}
	if( ActorReachable(ShoppingPath) )
		MoveToward(ShoppingPath,ShopVolumeActor,,true);
	else if( FindBestPathToward(ShoppingPath,true,false) )
	{
		MoveToward(MoveTarget,FaceActor(1),,false );
		Goto('KeepMoving');
	}
	else
	{
		LastShopTime = level.TimeSeconds+8+FRand()*10;
		WhatToDoNext(151);
	}
	Focus = ShopVolumeActor;
	Pawn.Acceleration = vect(0,0,0);
	DoTrading();
	Sleep(0.5);
	MoveToward(ShoppingPath,ShoppingPath,,ShouldStrafeTo(MoveTarget));
	WhatToDoNext(152);
	if ( bSoaking )
		SoakStop("STUCK IN SHOPPING!");
}

function MoverFinished()
{
	if ( ProceedWithMove() )
	{
		//SendChatMsg("Elevator finished, proceeding.");
		PendingMover = None;
		bPreparingMove = false;
	}
}

function bool ProceedWithMove()
{
    local LiftExit Start, DestExit;
    local Mover Lift;
    local float dist2D;
    local vector dir;

    if ( Pawn == None || Pawn.Controller == None )
        return false;

    Lift = PendingMover;
    if ( Lift == None )
        return true; // no mover to worry about

    // Already standing on the lift?
    if ( Pawn.Base == Lift )
        return true;

    // Anchor is a LiftExit we reached, and lift is at the right keyframe
    Start = LiftExit(Pawn.Anchor);
    if ( (Start != None) && (Start.KeyFrame != 255) && Pawn.ReachedDestination(Start) )
    {
        if ( Lift.KeyNum == Start.KeyFrame )
            return true;
    }

    // MoveTarget is a LiftExit, we’re near the lift: ask exit if it’s reachable
    DestExit = LiftExit(Pawn.Controller.MoveTarget);
    if ( DestExit != None )
    {
        dir = Lift.Location - Pawn.Location;
        dir.Z = 0;
        dist2D = VSize(dir);
        if ( dist2D < 400.0 )
            return (Lift.Location.Z < Pawn.Location.Z + Pawn.CollisionHeight);
    }

    // Fallback: close enough to the mover in 2D & Z
    dir = Lift.Location - Pawn.Location;
    dir.Z = 0;
    dist2D = VSize(dir);
    if ( (dist2D < 400.0)
         && (Lift.Location.Z - Lift.CollisionHeight
             < Pawn.Location.Z - Pawn.CollisionHeight + MAXSTEPHEIGHT)
         && (Lift.Location.Z - Lift.CollisionHeight
             > Pawn.Location.Z - Pawn.CollisionHeight - 1200.0) )
    {
        return true;
    }

    // If lift is closed, treat move as allowed (doors should be open by now)
    if ( Lift.bClosed )
	{
		Pawn.SetMoveTarget(LiftCenter(Lift.MyMarker).SpecialHandling(Pawn));
        return true;
	}

    return false;
}

function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
	Super.DisplayDebug(Canvas,YL, YPos);

	Canvas.DrawText("Perk: "@KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.default.VeterancyName);
	YPos += YL;
	Canvas.SetPos(4,YPos);
}

defaultproperties
{
	Aggressiveness=1.000000
	BaseAlertness=1.000000
	Accuracy=1.000000
	CombatStyle=-1.000000
	ReactionTime=1.000000
	Skill=9.000000
	FovAngle=360.000000
	bAdrenalineEnabled=False
	PawnClass=Class'KFMod.KFHumanPawn'
	SmoothTurnSpeed=1.000000
}
