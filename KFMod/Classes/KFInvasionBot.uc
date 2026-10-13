// A lot of this code is combination of the default KFInvasionBot code from KF2.5 and Marco's KF1 bots mutator
// I didn't like the behavior of Marco's bots so I ended up mostly using the UT2004 bot behaviour and tweaking it to be way more tailored to KFMod.
class KFInvasionBot extends InvasionBot;

var float LastShopTime, LastShopCash, LastHealTime;

struct FWeldedPath
{
	var KFDoorMover Door;
	var ReachSpec Path;
};
var array<FWeldedPath> DoorPaths;

var float NextTargetCheck,NextMedicFireTime,NextNadeTimer,WeldAssistTimer;

var byte HealState,OldMovesCount;
var float RetreatTime,LastEnemyEncounter,LastChatTime,LastCalloutTime;
var float LastFallbackMoveTime;
var NavigationPoint CurrentMov,OldMoves[4],PreviousNavPath;
var array<NavigationPoint> TempBlockedPaths;

// Internal to state
var NavigationPoint ShoppingPath;
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
var KFHumanPawnZombies ReviveTarget;
var float NextReviveTime;
var() float ReviveSearchDist;
var KFInvasionBot BeggingTarget,AnswerBegger;
var PlayerController DonatePlayer, BeggingPlayer;

var byte AssistWeldMode;

var rotator LastViewRotation;
var() float SmoothTurnSpeed;

var int ShoppingAttempts, RoamingAttempts;
var float ShopDist, BestShopDist;
var bool bWasWaveInProgress;
var float NextPickupSearchTime;

var KFNadeHealingExplosion NearbyHealCloud;

// Where our own grenade is about to go off, and until when to stay away from it.
var vector NadeDangerSpot;
var float NadeDangerTime;
var Nade MyLiveNade;
// When a rocket shot was last held back as unsafe.
var float RocketUnsafeTime;
var float NextHuntCheckTime;

// Roaming: restarts within one tick, and progress towards the goal.
var float RoamLoopTime, BestRoamDist;
var int RoamLoopCount;
var Actor RoamGoal;

// Getting out of Bloat bile.
var float BileLeaveTime, NextBileAvoidTime;
var float NextDangerCheckTime;

// Stuck in mid-air on one spot ("falling", not moving).
var vector WedgeSpot;
var float WedgeTime, NextWedgeCheckTime;
var int WedgeTries;

var float NextLiftCheckTime, WaitLiftUntil;
var NavigationPoint LiftLeaveSpot, WaitLiftExit;
var KFElevator WaitLift;

function AssignPersonality()
{
	Accuracy = FRand();
	BaseAggressiveness = FRand();
	StrafingAbility = -1 + FRand()*2.f;
	CombatStyle = -1 + FRand()*2.f;
	Tactics = FRand();
	ReactionTime = FRand();
	Jumpiness = 0.f;
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	AssignPersonality();
}

simulated function rotator GetViewRotation()
{
    local rotator ViewRot;
    local vector AimDir;

    ViewRot = Rotation;

    if (Pawn != None && Pawn(Focus) != None)
    {
        AimDir = Focus.Location - Pawn.Location;

        if (AimDir != vect(0,0,0))
            ViewRot.Pitch = rotator(AimDir).Pitch;
    }

    return ViewRot;
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
	
	// HACK give extra melee range
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
	local actor SquadFace;

	//TODO do we need this?
	SquadFace = Squad.SetFacingActor(self);
	if ( SquadFace != None )
		return SquadFace;

	bRecommendFastMove = false;

	if ( Enemy == none || Level.TimeSeconds - LastSeenTime > 4 - StrafingModifier)
		return FaceMoveTarget();

	// Gibber trimmed this one down to happen regardless of skill level
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
	// Shop's closed during waves.
	if( KFGameType(Level.Game).bWaveInProgress )
	{
		bWasWaveInProgress = true;
		return false;
	}
	// Wave just ended, let bots shop right away
	if (bWasWaveInProgress)
	{
		bWasWaveInProgress = false;
		LastShopTime = Level.TimeSeconds;
	}
    if( PlayerReplicationInfo.Score < 50 )
        return false;
	// Got a cash injection, go spend it
    if( PlayerReplicationInfo.Score >= LastShopCash + 150.f )
	{
		LastShopCash = PlayerReplicationInfo.Score;
        return true;
	}
    return (LastShopTime < Level.TimeSeconds);
}

final function bool ShouldBegForCash()
{
	local Controller C;
	local array<PlayerController> PC;
	local array<PlayerController> ClaimedPlayers;
	local byte i, j;

	if( KFGameType(Level.Game).bWaveInProgress || AnswerBegger!=None )
		return false;

	if( PlayerReplicationInfo.Score<300 && LastShopTime<Level.TimeSeconds ) // Broke and the shop's open
	{
		// Bots first
		for( C=Level.ControllerList; C!=None; C=C.nextController )
			if( KFInvasionBot(C)!=None && KFInvasionBot(C).AnswerBeg(Pawn,PlayerReplicationInfo.Score) && ActorReachable(C.Pawn) )
			{
				BeggingTarget = KFInvasionBot(C);
				BeggingTarget.AnswerBegger = Self;
				SendChatMsg("I need some money!");
				GoToState('BeggingCash','Begin');
				return true;
			}

		// Then try rich humans — pre-collect claimed and candidate targets in one pass
		for( C=Level.ControllerList; C!=None; C=C.nextController )
		{
			if( C!=Self && KFInvasionBot(C)!=None && KFInvasionBot(C).BeggingPlayer!=None )
				ClaimedPlayers[ClaimedPlayers.Length] = KFInvasionBot(C).BeggingPlayer;
			if( PlayerController(C)!=None && KFPawn(C.Pawn)!=None && C.PlayerReplicationInfo.Score>500 && ActorReachable(C.Pawn) )
				PC[PC.Length] = PlayerController(C);
		}

		while( PC.Length>0 )
		{
			i = Rand(PC.Length);
			BeggingPlayer = PC[i];
			PC.Remove(i,1);
			for( j=0; j<ClaimedPlayers.Length; j++ )
				if( ClaimedPlayers[j]==BeggingPlayer )
				{
					BeggingPlayer = None;
					break;
				}
			if( BeggingPlayer!=None )
			{
				SendChatMsg("Hey "$BeggingPlayer.PlayerReplicationInfo.PlayerName$", can you spare some dosh?");
				GoToState('BeggingPlayerCash','Begin');
				return true;
			}
		}
	}
	else if( PlayerReplicationInfo.Score>900 )
	{
		// Pre-collect claimed and candidate targets in one pass
		for( C=Level.ControllerList; C!=None; C=C.nextController )
		{
			if( C!=Self && KFInvasionBot(C)!=None && KFInvasionBot(C).DonatePlayer!=None )
				ClaimedPlayers[ClaimedPlayers.Length] = KFInvasionBot(C).DonatePlayer;
			if( PlayerController(C)!=None && KFPawn(C.Pawn)!=None && C.PlayerReplicationInfo.Score<250 && ActorReachable(C.Pawn) )
				PC[PC.Length] = PlayerController(C);
		}

		while( PC.Length>0 )
		{
			i = Rand(PC.Length);
			DonatePlayer = PC[i];
			PC.Remove(i,1);
			for( j=0; j<ClaimedPlayers.Length; j++ )
				if( ClaimedPlayers[j]==DonatePlayer )
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
    if ( KFPlayerReplicationInfo(PlayerReplicationInfo) != none && KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none )
		AM.MaxAmmo = int(float(AM.MaxAmmo) * KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.AddExtraAmmoFor(AClass));

	mxam = AM.MaxAmmo;
	if( KW==MyGrenades )
		mxam = Min(mxam,5); // Cap grenades

    if ( AM.AmmoAmount >= mxam )
        return 0;

    // Use secondary cost/clip for secondary ammo (e.g. explosive shells)
    if (KW.AmmoClass[1] == AClass && class<KFWeaponPickup>(KW.PickupClass).default.SecondaryAmmoCost > 0)
    {
        Price = int(class<KFWeaponPickup>(KW.PickupClass).default.SecondaryAmmoCost * class'KFPawn'.static.GetCostScaling(Level.Game.GameDifficulty));
        UsedMagCapacity = class<KFWeaponPickup>(KW.PickupClass).default.SecondaryClipCount;
        if (UsedMagCapacity <= 0)
            UsedMagCapacity = KW.default.ClipCount;
    }
    else
    {
        Price = int(class<KFWeaponPickup>(KW.PickupClass).default.AmmoCost * class'KFPawn'.static.GetCostScaling(Level.Game.GameDifficulty));
        UsedMagCapacity = KW.default.ClipCount;
    }

	UsedMagCapacity = Max(UsedMagCapacity,1);

	c = (mxam-AM.AmmoAmount);

	if( Price>0.001f )
		Price = int(float(c) / UsedMagCapacity * Price);
	else Price = 0;

    if ( PlayerReplicationInfo.Score < Price ) // Can't afford a full top-up, buy what we can
    {
		c *= (PlayerReplicationInfo.Score/Price);

		if ( c == 0 )
			return 0; // Can't even afford one bullet

        AM.AddAmmo(c);

		ol = PlayerReplicationInfo.Score;
		PlayerReplicationInfo.Score = Max(PlayerReplicationInfo.Score - (float(c) / UsedMagCapacity * Price), 0);
        return (ol-PlayerReplicationInfo.Score);
    }

    PlayerReplicationInfo.Score = int(PlayerReplicationInfo.Score-Price);
    AM.AddAmmo(c);
    return Price;
}

function bool FindInjuredAlly()
{
	local controller c;
	local KFHumanPawn aKFHPawn;
	local float AllyDist;
	local float BestDist;

	InjuredAlly = None;
	if( ManyEnemiesAround(3, Pawn.Location) )
		return false;
	// not with a specimen about to reach us either: the syringe leaves us defenceless
	if( FindNearestThreat(AllyDist, BestDist)!=None && BestDist<200.f )
		return false;
	BestDist = 0;
	if( MySyringe==none || MySyringe.ChargeBar()<0.6f )
		return false;

	for( c=level.ControllerList; c!=none; c=c.nextController )
	{
		if( C==Self )
			continue;

		aKFHPawn = KFHumanPawn(c.pawn);

		if( aKFHPawn==none || aKFHPawn.Health<=0 || aKFHPawn.bIsDowned || (aKFHPawn.Health+aKFHPawn.HealthToGive)>=GetMinHealingValue() || VSize(aKFHPawn.Location-Pawn.Location)>1000.f )
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
			KFInvasionBot(InjuredAlly.Controller).SendMessage(None, 'OTHER', 30, 4.f, 'TEAM'); // "Need healing!"
		return true;
	}
	return false;
}

function bool EnemyReallyScary()
{
    local Controller C;
    local KFMonster M;
    local float D, HPFactor;
	local float DangerScore, ScaryThreshold;
	local bool bBerserker;

	bBerserker = GetPerkName() == "Berserker";

    for (C = Level.ControllerList; C != None; C = C.nextController)
    {
        M = KFMonster(C.Pawn);
        if (M == None || M.Health <= 0)
            continue;

        D = VSize(M.Location - Pawn.Location);
        if (D > 1200.f || !LineOfSightTo(M))
            continue;
        // Dying enemies are less of a threat
        HPFactor = FMin(1.0, float(M.Health) / (M.HealthMax * 0.3));

        if (M.IsA('ZombieBoss'))
        {
            if (D < 600.f || M.IsInState('FireChaingun') || M.IsInState('FireMissile') || M.IsInState('DriveByAttack') )
                return true;
        }
		else if (M.IsA('ZombieFleshPound'))
		{
			if (HPFactor > 0.5 && C.Enemy==Pawn && (D < 600.f || (D < 1000.f && M.GroundSpeed > M.default.GroundSpeed)))
				return true;
			DangerScore += 5.0 * HPFactor;
		}
        else if (M.IsA('ZombieScrake'))
        {
            if (D < 400.f)
                DangerScore += 2.0 * HPFactor;
        }
        else if (M.IsA('ZombieSiren'))
        {
            if (D < 600.f)
                DangerScore += 2.0 * HPFactor;
        }
        else if (D < 150.f && C.Enemy==Pawn)
            DangerScore += 0.5 * HPFactor;
    }
	// Berserkers shrug it off, especially with armor
	if (bBerserker && Pawn.ShieldStrength > 20.0)
		ScaryThreshold = 20.f;
	else ScaryThreshold = 10.f;

	return (DangerScore >= ScaryThreshold);
}

// The bot's perk name, "" if it has none (perks disabled).
final function string GetPerkName()
{
	local KFPlayerReplicationInfo PRI;

	PRI = KFPlayerReplicationInfo(PlayerReplicationInfo);
	if ( PRI == None || PRI.ClientVeteranSkill == None )
		return "";
	return PRI.ClientVeteranSkill.default.VeterancyName;
}

// How close a specimen may get before a bot with a gun stops standing still and backs away from it.
final function float KiteDistanceFor(KFMonster M)
{
	if ( M.IsA('ZombieBloat') )
		return 400.f;	// its bile reaches about 250
	if ( M.IsA('ZombieFleshPound') || M.IsA('ZombieScrake') || M.IsA('ZombieBoss') || M.IsA('ZombieSiren') )
		return 500.f;
	if ( M.IsA('ZombieClot') )
		return 200.f;	// slow, short reach
	return 250.f;
}

// The live specimen on our floor that is furthest inside (or nearest to) its kite distance.
// Margin = its distance minus its kite distance: negative means it is too close.
final function KFMonster FindNearestThreat(out float Dist, out float Margin)
{
	local Controller C;
	local KFMonster M, Best;
	local float D, Mg;

	Margin = 100000.f;
	Dist = 100000.f;
	for ( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		M = KFMonster(C.Pawn);
		if ( M == None || M.Health <= 0 || Abs(M.Location.Z - Pawn.Location.Z) > 250.f )
			continue;
		D = VSize(M.Location - Pawn.Location);
		if ( D > 900.f )
			continue;
		Mg = D - KiteDistanceFor(M);
		if ( Mg < Margin && (D < 200.f || FastTrace(M.Location, Pawn.Location)) )
		{
			Best = M;
			Margin = Mg;
			Dist = D;
		}
	}
	return Best;
}

final function int CountThreatsWithin(float Radius)
{
	local Controller C;
	local int N;

	for ( C=Level.ControllerList; C!=None; C=C.nextController )
		if ( KFMonster(C.Pawn) != None && C.Pawn.Health > 0 && VSize(C.Pawn.Location - Pawn.Location) < Radius
			&& Abs(C.Pawn.Location.Z - Pawn.Location.Z) < 250.f )
			N++;
	return N;
}

// True while we are inside the blast of the grenade we just threw.
final function bool NadeDanger()
{
	return ( NadeDangerTime > Level.TimeSeconds && VSize(NadeDangerSpot - Pawn.Location) < 520.f );
}

// Flat direction that leads away from the specimens close to us (and from our own live grenade and from bile).
// Zero if nothing is close.
final function vector GetThreatAwayDir()
{
	local Controller C;
	local KFMonster M;
	local KFBloatVomit V;
	local BileJet J;
	local vector Dir, Away;
	local float D, K;

	for ( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		M = KFMonster(C.Pawn);
		if ( M == None || M.Health <= 0 )
			continue;
		Away = Pawn.Location - M.Location;
		if ( Abs(Away.Z) > 250.f )
			continue;
		Away.Z = 0;
		D = VSize(Away);
		K = KiteDistanceFor(M);
		if ( D > K + 250.f || D < 1.f )
			continue;
		Dir += (Away / D) * (K / (D + 60.f));
	}
	if ( NadeDangerTime > Level.TimeSeconds )
	{
		Away = Pawn.Location - NadeDangerSpot;
		Away.Z = 0;
		D = VSize(Away);
		if ( D < 560.f && D > 1.f )
			Dir += (Away / D) * 4.f;
	}
	foreach DynamicActors(class'KFBloatVomit', V)
	{
		Away = Pawn.Location - V.Location;
		if ( Abs(Away.Z) > 150.f )
			continue;
		Away.Z = 0;
		D = VSize(Away);
		if ( D < 320.f && D > 1.f )
			Dir += (Away / D) * (160.f / (D + 40.f));
	}
	// a Bloat that has just died sprays bile for a couple of seconds
	foreach DynamicActors(class'BileJet', J)
	{
		Away = Pawn.Location - J.Location;
		if ( Abs(Away.Z) > 200.f )
			continue;
		Away.Z = 0;
		D = VSize(Away);
		if ( D < 450.f && D > 1.f )
			Dir += (Away / D) * 3.f;
	}
	if ( VSize(Dir) < 0.05 )
		return vect(0,0,0);
	return Normal(Dir);
}

// Away from the team-mates we are standing with: bile that lands on one of a group hurts all of it.
final function vector GetScatterDir()
{
	local Controller C;
	local vector Sum;
	local int N;

	for ( C=Level.ControllerList; C!=None; C=C.nextController )
		if ( C != self && KFHumanPawn(C.Pawn) != None && C.Pawn.Health > 0 && VSize(C.Pawn.Location - Pawn.Location) < 300.f )
		{
			Sum += C.Pawn.Location;
			N++;
		}
	if ( N == 0 )
		return vect(0,0,0);
	Sum = Pawn.Location - Sum / N;
	Sum.Z = 0;
	if ( VSize(Sum) < 1.f )
	{
		Sum = VRand();
		Sum.Z = 0;
	}
	return Normal(Sum);
}

// Where to go to get away from what is close (specimens, bile, our own grenade): a straight step if there is room
// for it, else one of the two diagonals, else the path node that leads away. Sets Destination and clears MoveTarget,
// or sets MoveTarget to the path node. False if there is nothing to get away from, or nowhere to go.
final function bool PickAwayMove(float StepSize)
{
	local vector Away, Side, Ext, Dir, HitLocation, HitNormal;
	local int i;

	Away = GetThreatAwayDir();
	if ( Away == vect(0,0,0) )
		Away = GetScatterDir();
	if ( Away == vect(0,0,0) )
		return false;
	Ext = Pawn.GetCollisionExtent();
	Ext.Z = FMax(6, Pawn.CollisionHeight - MAXSTEPHEIGHT);
	Side = Away Cross vect(0,0,1);
	if ( bStrafeDir )
		Side *= -1;
	for ( i=0; i<6; i++ )
	{
		if ( i == 3 )
		{
			// no room for a full step: a path node that leads away is better than a short step
			if ( PickPathAway(Away) )
				return true;
			StepSize *= 0.45f;
		}
		if ( i % 3 == 0 )
			Dir = Away;
		else if ( i % 3 == 1 )
			Dir = Normal(Away + Side);
		else
			Dir = Normal(Away - Side);
		if ( Trace(HitLocation, HitNormal, Pawn.Location + Dir * StepSize, Pawn.Location, false, Ext) == None )
		{
			Destination = Pawn.Location + Dir * StepSize;
			MoveTarget = None;
			return true;
		}
	}
	return false;
}

// The nearby path node that lies best in direction Away and that we can walk straight to. Sets MoveTarget.
final function bool PickPathAway(vector Away)
{
	local NavigationPoint N, Cand[3];
	local float S, CandS[3], D;
	local vector Dir;
	local int i, j;

	if ( Away == vect(0,0,0) )
		return false;
	// the three best-placed nodes within reach of a short run, then the first of them we can walk straight to
	for ( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
	{
		Dir = N.Location - Pawn.Location;
		if ( Abs(Dir.Z) > 120.f || N.bBlocked || LiftCenter(N) != None )
			continue;
		Dir.Z = 0;
		D = VSize(Dir);
		if ( D < 90.f || D > 600.f )
			continue;
		S = (Away dot (Dir / D)) - D / 3000.f;
		if ( S < 0.3f )
			continue;
		for ( i=0; i<3; i++ )
			if ( Cand[i] == None || S > CandS[i] )
			{
				for ( j=2; j>i; j-- )
				{
					Cand[j] = Cand[j-1];
					CandS[j] = CandS[j-1];
				}
				Cand[i] = N;
				CandS[i] = S;
				break;
			}
	}
	for ( i=0; i<3; i++ )
		if ( Cand[i] != None && ActorReachable(Cand[i]) )
		{
			MoveTarget = Cand[i];
			return true;
		}
	return false;
}

// Specimens a careful player takes on with a blade.
final function bool IsEasyMeleeTarget(Pawn P)
{
	return ( P != None && (P.IsA('ZombieClot') || P.IsA('ZombieCrawler') || P.IsA('ZombieStalker')) );
}

// The blast radius of what W fires if that is a rocket (the LAW), 0 for anything else.
final function float RocketBlastRadius(Weapon W)
{
	local WeaponFire F;

	if ( W == None || W.bMeleeWeapon )
		return 0.f;
	F = W.GetFireMode(0);
	if ( F == None || !F.bSplashDamage || F.ProjectileClass == None || class<Nade>(F.ProjectileClass) != None
		|| F.ProjectileClass.default.DamageRadius < 250.f )
		return 0.f;
	return F.ProjectileClass.default.DamageRadius;
}

// A rocket goes off on the first thing it touches (wall, door frame, any specimen) and on any damage it takes in
// the air (a Siren's scream), and its blast reaches several hundred units. What would one fired at Tgt now cost
// us? -1: no clear shot at all. Otherwise the health we would lose, after difficulty and armour.
final function float RocketSelfDamage(Actor Tgt, class<Projectile> PC, out vector BoomSpot)
{
	local vector Start, End, Dir, Side, Up, Off, HL, HN;
	local float Dist, Along, Boom, Radius, Dmg, Lane;
	local Controller C;
	local Pawn P;
	local int i;

	Radius = PC.default.DamageRadius;
	Start = Pawn.Location + Pawn.EyePosition();
	End = Tgt.Location;
	Dist = VSize(End - Start);
	if ( Dist < 60.f )
		return -1.f;
	Dir = (End - Start) / Dist;
	// the target in plain view
	if ( !FastTrace(End, Start) )
		return -1.f;
	Boom = Dist;
	// anything solid near the line where it is still close to us (the aim can be a little off)
	Lane = FMin(Dist, Radius + 30.f);
	Side = Normal(Dir cross vect(0,0,1)) * 60.f;
	Up = vect(0,0,45);
	for ( i=0; i<4; i++ )
	{
		if ( i == 0 )
			Off = Side;
		else if ( i == 1 )
			Off = -Side;
		else if ( i == 2 )
			Off = Up;
		else
			Off = -Up;
		if ( Trace(HL, HN, Start + Dir * Lane + Off, Start, false) != None )
			Boom = FMin(Boom, VSize(HL - Start));
	}
	for ( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		P = C.Pawn;
		if ( KFMonster(P) == None || P.Health <= 0 )
			continue;
		Off = P.Location - Start;
		// a Siren that is screaming sets it off in the air
		if ( P.IsA('ZombieSiren') && Monster(P).bShotAnim && VSize(Off) < 1150.f )
			return -1.f;
		// a specimen in the line, or about to step into it
		Along = Off dot Dir;
		if ( P != Tgt && Along > -40.f && Along < Boom && Abs(Off.Z - Dir.Z * Along) < P.CollisionHeight + 50.f )
		{
			Off -= Dir * Along;
			Off.Z = 0;
			if ( VSize(Off) < P.CollisionRadius + 70.f )
				Boom = FMax(Along - P.CollisionRadius, 0.f);
		}
	}
	BoomSpot = Start + Dir * Boom;
	if ( Boom - Pawn.CollisionRadius >= Radius )
		return 0.f;
	// LAWProj.HurtRadius halves it for the bot that fired it, KFGameType.ReduceDamage halves self-damage again,
	// and once more for bots up to Normal; armour then takes three quarters while it lasts
	Dmg = PC.default.Damage * (1.f - FMax(0.f, (Boom - Pawn.CollisionRadius) / Radius)) * 0.25f;
	if ( Level.Game.GameDifficulty <= 3 )
		Dmg *= 0.5f;
	return Dmg - FMin(Pawn.ShieldStrength, 0.75f * Dmg);
}

// Fire a rocket at Tgt now? Yes when it costs us nothing; when it does, only if we can afford it, and more of it
// when the blast takes several specimens with it.
final function bool RocketShotSafe(Actor Tgt, class<Projectile> PC)
{
	local float Loss, Allowed;
	local vector BoomSpot;
	local Controller C;
	local Pawn P;
	local int Caught;
	local bool bFriendlyFire;

	if ( Tgt == None || Pawn == None || PC == None )
		return false;
	Loss = RocketSelfDamage(Tgt, PC, BoomSpot);
	if ( Loss < 0.f )
		return false;
	bFriendlyFire = ( TeamGame(Level.Game) != None && TeamGame(Level.Game).FriendlyFireScale > 0.f );
	for ( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		P = C.Pawn;
		if ( P == None || P == Pawn || P.Health <= 0 )
			continue;
		if ( KFMonster(P) != None )
		{
			if ( VSize(P.Location - BoomSpot) < 0.7f * PC.default.DamageRadius )
				Caught++;
		}
		else if ( bFriendlyFire && P.GetTeamNum() == Pawn.GetTeamNum()
			&& (VSize(P.Location - BoomSpot) < PC.default.DamageRadius
				|| (VSize(P.Location - Pawn.Location) < 240.f && (Normal(P.Location - Pawn.Location) dot Normal(BoomSpot - Pawn.Location)) < -0.3f)) )
			return false;	// friendly fire is on: nobody of ours near the blast, or right behind us in the back blast
	}
	if ( Loss <= 0.f )
		return true;
	if ( Caught >= 3 )
		Allowed = 0.35f * Pawn.Health;
	else
		Allowed = 0.15f * Pawn.Health;
	return ( Loss <= Allowed && Pawn.Health - Loss >= 30.f );
}

// The class of rocket W fires (the LAW's), None for anything else.
final function class<Projectile> RocketClassOf(Weapon W)
{
	local WeaponFire F;

	if ( W == None || W.bMeleeWeapon )
		return None;
	F = W.GetFireMode(0);
	if ( F == None || !F.bSplashDamage || F.ProjectileClass == None || class<Nade>(F.ProjectileClass) != None
		|| F.ProjectileClass.default.DamageRadius < 250.f )
		return None;
	return F.ProjectileClass;
}

// With a rocket launcher in hand: may it be fired at Tgt now?
final function bool HeldRocketSafe(Actor Tgt)
{
	local class<Projectile> PC;

	PC = RocketClassOf(Pawn.Weapon);
	if ( PC == None || RocketShotSafe(Tgt, PC) )
		return true;
	RocketUnsafeTime = Level.TimeSeconds;	// RateWeapon: take something else for now
	return false;
}

// How close to us our own grenade may come down.
final function float GetNadeMinDist()
{
	if ( GetPerkName() == "Field Medic" )
		return 0.f;		// healing grenade
	if ( GetPerkName() == "Firebug" )
		return 300.f;	// fire grenade
	return 540.f;
}

// Where a grenade thrown at Tgt should come down.
final function vector GetNadeTossSpot(Actor Tgt)
{
	local vector Spot, Flat;
	local float D, MinD;

	Spot = Tgt.Location;
	if ( KFMonster(Tgt) == None )
		return Spot;		// an ally, or ourselves (healing grenade)
	// on the floor, about where the specimen will be when it goes off (two seconds after the first bounce)
	Spot.Z -= Tgt.CollisionHeight;
	Flat = Tgt.Velocity * 2.f;
	Flat.Z = 0;
	Spot += Flat;
	// ...but never inside our own blast
	MinD = GetNadeMinDist();
	Flat = Spot - Pawn.Location;
	Flat.Z = 0;
	D = VSize(Flat);
	if ( D < MinD )
	{
		if ( D < 1.f )
			Flat = vector(Pawn.Rotation);
		Flat.Z = 0;
		Flat = Normal(Flat) * MinD;
		Spot.X = Pawn.Location.X + Flat.X;
		Spot.Y = Pawn.Location.Y + Flat.Y;
	}
	return Spot;
}

final function float GetNadeTossSpeed(vector Spot)
{
	return FMax(850.f, 1.1f * VSize(Spot - Pawn.Location));
}

// The low arc that takes a grenade from Start to Spot at that speed.
final function vector GetNadeTossDir(vector Start, vector Spot)
{
	local vector Flat;
	local float D, DZ, V, G, Disc, TanA;

	Flat = Spot - Start;
	DZ = Flat.Z;
	Flat.Z = 0;
	D = VSize(Flat);
	G = -Pawn.PhysicsVolume.Gravity.Z;
	if ( D < 60.f || G < 1.f )
		return Normal(Spot - Start);
	Flat /= D;
	V = GetNadeTossSpeed(Spot) + (Flat dot Pawn.Velocity);
	Disc = V*V*V*V - G * (G*D*D + 2.f*DZ*V*V);
	if ( Disc < 0.f )
		TanA = 1.f;		// out of reach: as far as it will go
	else
		TanA = (V*V - Sqrt(Disc)) / (G*D);
	Flat.Z = TanA;
	return Normal(Flat);
}

// Is the arc to where the grenade should come down free of walls, ceilings and furniture for most of the way?
final function bool NadePathClear(Actor Tgt)
{
	local vector Start, Spot, Vel, Flat, P0, P1;
	local float G, T, TEnd, HSpeed;
	local int i;

	Start = Pawn.Location + Pawn.EyePosition();
	Spot = GetNadeTossSpot(Tgt);
	Vel = GetNadeTossDir(Start, Spot) * GetNadeTossSpeed(Spot);
	G = -Pawn.PhysicsVolume.Gravity.Z;
	Flat = Spot - Start;
	Flat.Z = 0;
	HSpeed = Sqrt(Vel.X*Vel.X + Vel.Y*Vel.Y);
	if ( HSpeed < 1.f )
		return true;
	TEnd = 0.85f * VSize(Flat) / HSpeed;
	P0 = Start;
	for ( i=1; i<=6; i++ )
	{
		T = TEnd * i / 6.f;
		P1 = Start + Vel * T;
		P1.Z -= 0.5f * G * T * T;
		if ( !FastTrace(P1, P0) )
			return false;
		P0 = P1;
	}
	return true;
}

// While the grenade we threw is live: note where it really is (it can stop short of where it was thrown) and,
// whatever we are doing, get out of its blast.
final function CheckOwnNade()
{
	if ( MyLiveNade == None )
		return;
	if ( MyLiveNade.bDeleteMe || MyLiveNade.bHasExploded || Pawn == None || Pawn.Health <= 0 )
	{
		MyLiveNade = None;
		NadeDangerTime = 0;
		return;
	}
	NadeDangerSpot = MyLiveNade.Location;
	NadeDangerTime = Level.TimeSeconds + 0.5f;
	if ( NadeDanger() && Pawn.Physics == PHYS_Walking && !IsInState('AvoidOwnNade') && !IsInState('NadeTarget')
		&& !IsInState('Dead') && !IsInState('GameEnded') && !IsInState('RoundEnded') )
	{
		GoalString = "Clear of own grenade";
		GotoState('AvoidOwnNade');
	}
}

// A grenade stops dead at the first specimen it touches: is the first stretch of the throw at Tgt free of them?
final function bool NadeLaneClear(Pawn Tgt)
{
	local Controller C;
	local vector Dir, Off;
	local float Along, Reach;

	Dir = Tgt.Location - Pawn.Location;
	Dir.Z = 0;
	Dir = Normal(Dir);
	Reach = GetNadeMinDist() - 20.f;
	for ( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		if ( KFMonster(C.Pawn) == None || C.Pawn.Health <= 0 || C.Pawn == Tgt )
			continue;
		Off = C.Pawn.Location - Pawn.Location;
		if ( Abs(Off.Z) > 200.f )
			continue;
		Off.Z = 0;
		Along = Off dot Dir;
		if ( Along > 0.f && Along < Reach && VSize(Off - Dir * Along) < C.Pawn.CollisionRadius + 70.f )
			return false;
	}
	return true;
}

// Top up the magazine while nothing is around.
final function ReloadIfLow()
{
	local KFWeapon KW;

	KW = KFWeapon(Pawn.Weapon);
	if ( KW != None && !KW.bMeleeWeapon && !KW.bIsReloading && KW.ClipCount > 1 && KW.ClipLeft < KW.ClipCount * 0.6 && KW.AllowReload() )
		KW.ReloadMeNow();
}

// When a wave is down to its last few specimens and none has been met for a while, go and find one
// instead of waiting around the squad leader. (Not when the leader is a player: then it is the player's call.)
function bool HuntRemainingSpecimens()
{
	local Controller C;
	local KFMonster M, Best;
	local float D, BestD;
	local KFGameType G;

	G = KFGameType(Level.Game);
	if ( G == None || !G.bWaveInProgress || G.TotalMaxMonsters > 0 || G.NumMonsters > 8
		|| NextHuntCheckTime > Level.TimeSeconds || Level.TimeSeconds - LastEnemyEncounter < 10.f
		|| (Squad != None && PlayerController(Squad.SquadLeader) != None) )
		return false;
	NextHuntCheckTime = Level.TimeSeconds + 1.f;

	for ( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		M = KFMonster(C.Pawn);
		if ( M == None || M.Health <= 0 || OnOtherFloor(M) )
			continue;
		D = VSize(M.Location - Pawn.Location);
		if ( Best == None || D < BestD )
		{
			Best = M;
			BestD = D;
		}
	}
	if ( Best == None || !FindBestPathToward(Best, false, false) )
		return false;
	RouteGoal = Best;
	GoalString = "Hunt remaining specimen";
	GotoState('Roaming');
	return true;
}

function Tick(float DeltaTime)
{
	Super.Tick(DeltaTime);
	if ( NextWedgeCheckTime < Level.TimeSeconds )
	{
		CheckWedged();
		CheckOwnNade();
		CheckBile();
		CheckSurprise();
		CheckLift();
	}
}

final function SetLiftsBlocked(bool bBlock)
{
	local KFGameType G;

	G = KFGameType(Level.Game);
	if ( G != None && G.FloorMap != None )
		G.FloorMap.SetLiftsBlocked(bBlock);
}

final function bool OnOtherFloor(Pawn Other)
{
	local KFGameType G;

	G = KFGameType(Level.Game);
	return ( G != None && G.FloorMap != None
		&& G.FloorMap.OtherFloor(G.FloorMap.FloorOf(Pawn), G.FloorMap.FloorAt(Other.Location)) );
}

final function bool RidingLift(KFElevator E)
{
	local Controller C;

	if ( PendingMover == E
		|| (LiftCenter(MoveTarget) != None && LiftCenter(MoveTarget).MyLift == E)
		|| (LiftExit(MoveTarget) != None && LiftExit(MoveTarget).MyLift == E) )
		return true;
	if ( Squad != None && Squad.SquadLeader != None && Squad.SquadLeader != self
		&& Squad.SquadLeader.Pawn != None && Squad.SquadLeader.Pawn.Base == E )
		return true;
	for ( C=Level.ControllerList; C!=None; C=C.nextController )
		if ( PlayerController(C) != None && C.Pawn != None && C.Pawn.Base == E )
			return true;
	return false;
}

final function int LiftFloorOf(KFElevator E)
{
	local int i;

	for ( i=0; i<ArrayCount(E.MyExits); i++ )
		if ( E.MyExits[i] != None && Abs(E.MyExits[i].Location.Z - Pawn.Location.Z) < 120.f
			&& VSize(E.MyExits[i].Location - Pawn.Location) < 400.f )
			return i;
	return -1;
}

final function bool LiftHere()
{
	return ( !WaitLift.bInterpolating && WaitLift.KeyNum < ArrayCount(WaitLift.MyExits)
		&& WaitLift.MyExits[WaitLift.KeyNum] == WaitLiftExit );
}

final function bool PickLiftWaitSpot()
{
	local vector Back, Side, Spot;

	Back = WaitLiftExit.Location - WaitLift.MyMarker.Location;
	Back.Z = 0;
	if ( VSize(Back) < 1.f )
		return false;
	Back = Normal(Back);
	Side = Back cross vect(0,0,1);
	Spot = WaitLiftExit.Location + 90.f * Back + (PlayerReplicationInfo.PlayerID % 3 - 1) * 75.f * Side;
	Spot.Z = Pawn.Location.Z;
	if ( !pointReachable(Spot) )
	{
		Spot = WaitLiftExit.Location;
		Spot.Z = Pawn.Location.Z;
		if ( VSize(Spot - Pawn.Location) < 40.f || !pointReachable(Spot) )
			return false;
	}
	Destination = Spot;
	return true;
}

final function CheckLift()
{
	local KFElevator E;
	local int i;

	if ( Pawn == None || Pawn.Health <= 0 || NextLiftCheckTime > Level.TimeSeconds
		|| IsInState('LeaveLift') || IsInState('WaitForLift') || IsInState('AvoidBile') || IsInState('AvoidOwnNade')
		|| IsInState('Dead') || IsInState('GameEnded') || IsInState('RoundEnded') )
		return;
	E = KFElevator(Pawn.Base);
	if ( E != None )
	{
		if ( E.bInterpolating || E.KeyNum >= ArrayCount(E.MyExits) || E.MyExits[E.KeyNum] == None || RidingLift(E) )
			return;
		LiftLeaveSpot = E.MyExits[E.KeyNum];
		GoalString = "Step out of the lift";
		GotoState('LeaveLift');
		return;
	}
	if ( LiftCenter(MoveTarget) == None || Pawn.Physics != PHYS_Walking )
		return;
	E = KFElevator(LiftCenter(MoveTarget).MyLift);
	if ( E == None )
		return;
	i = LiftFloorOf(E);
	if ( i < 0 || (!E.bInterpolating && E.KeyNum == i) )
		return;
	WaitLift = E;
	WaitLiftExit = E.MyExits[i];
	GoalString = "Wait for the lift";
	GotoState('WaitForLift');
}

function bool FindInventoryGoal(float BestWeight)
{
	local bool bFound;

	SetLiftsBlocked(true);
	bFound = Super.FindInventoryGoal(BestWeight);
	SetLiftsBlocked(false);
	return bFound;
}

// A pawn that an opening door has pressed against a wall can be left resting on the door's edge: falling physics,
// not moving, unable to land. Nothing in the AI ends that (a move never times out while falling) and the specimens
// usually cannot reach the spot, so the match hangs on the last bot alive.
final function CheckWedged()
{
	NextWedgeCheckTime = Level.TimeSeconds + 0.25;
	if ( Pawn == None || Pawn.Health <= 0 || Pawn.Physics != PHYS_Falling || VSize(Pawn.Location - WedgeSpot) > 3.f )
	{
		if ( Pawn != None )
			WedgeSpot = Pawn.Location;
		WedgeTime = Level.TimeSeconds;
		WedgeTries = 0;
		return;
	}
	if ( Level.TimeSeconds - WedgeTime >= 1.5 + 1.5 * WedgeTries )
		Unwedge();
}

final function Unwedge()
{
	local NavigationPoint N, Best;
	local float D, BestD;
	local vector Old;

	Old = Pawn.Location;
	if ( WedgeTries++ == 0 )
	{
		// First let the engine's own "does it fit here" adjustment move the pawn clear of the wall it is pressed into.
		Pawn.SetLocation(Pawn.Location);
	}
	else
	{
		// Then put it on the nearest path node it can see.
		for ( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
		{
			D = VSize(N.Location - Pawn.Location);
			if ( D < 700.f && (Best == None || D < BestD) && !N.bBlocked && FastTrace(N.Location, Pawn.Location) )
			{
				Best = N;
				BestD = D;
			}
		}
		if ( Best == None )
			Best = Pawn.LastAnchor;
		if ( Best != None )
			Pawn.SetLocation(Best.Location);
	}
	if ( VSize(Pawn.Location - Old) > 3.f )
	{
		log(PlayerReplicationInfo.PlayerName$" was stuck in mid-air, moved clear (try "$WedgeTries$")");
		Pawn.SetPhysics(PHYS_Falling);
		Pawn.Velocity = vect(0,0,0);
		MoveTimer = -1.f;
	}
}

// For a bot with a gun that has a specimen inside its kite distance and no room to step back: the nearby path node
// that leads away best from what is close. Sets MoveTarget.
final function bool PickPathAwayFromThreats()
{
	local float D, Mg;

	if ( HoldingMelee() || FindNearestThreat(D, Mg) == None || Mg >= 0.f )
		return false;
	return PickPathAway(GetThreatAwayDir());
}

// Inside this distance a dying Bloat's bile reaches us.
final function float BloatSafeDist()
{
	return 330.f;
}

// Notice a specimen that has come close. With no enemy: take it as one (bots resting with their backs to a door
// used to find out when it was already on them). With an enemy, but busy with something that does not look at
// what is near (an errand, a pickup, resting, standing still to shoot): decide again, now.
final function CheckSurprise()
{
	local KFMonster Threat;
	local float D, Mg;

	if ( Pawn == None || Pawn.Health <= 0 || Squad == None
		|| IsInState('Dead') || IsInState('GameEnded') || IsInState('RoundEnded') )
		return;
	Threat = FindNearestThreat(D, Mg);
	if ( Threat == None )
		return;
	if ( Enemy == None )
	{
		if ( D < 600.f && Squad.SetEnemy(self, Threat) )
			WhatToDoNext(158);
	}
	else if ( Mg < 0.f && NextDangerCheckTime < Level.TimeSeconds && !HoldingMelee()
		&& (IsInState('Fallback') || IsInState('RestFormation') || IsInState('Roaming') || IsInState('RangedAttack')
			|| IsInState('StakeOut') || IsInState('Hunting') || IsInState('WaitForLift')) )
	{
		NextDangerCheckTime = Level.TimeSeconds + 0.8f;
		WhatToDoNext(159);
	}
}

// In or next to bile on the ground, or hit by bile within the last second.
final function bool InBile()
{
	local KFBloatVomit V;
	local BileJet J;

	if ( KFPawn(Pawn) != None && KFPawn(Pawn).BileCount >= 6 )
		return true;
	foreach Pawn.VisibleCollidingActors(class'KFBloatVomit', V, 140.f)
		return true;
	foreach DynamicActors(class'BileJet', J)
		if ( VSize(J.Location - Pawn.Location) < 380.f )
			return true;
	return false;
}

final function CheckBile()
{
	if ( Pawn == None || Pawn.Health <= 0 || Pawn.Physics != PHYS_Walking || NextBileAvoidTime > Level.TimeSeconds
		|| IsInState('AvoidBile') || IsInState('AvoidOwnNade') || IsInState('Dead') || IsInState('GameEnded') || IsInState('RoundEnded') )
		return;
	if ( InBile() )
	{
		GoalString = "Get out of the bile";
		GotoState('AvoidBile');
	}
}

// The weapon we are holding or are about to hold.
final function bool HoldingMelee()
{
	if ( Pawn.PendingWeapon != None )
		return Pawn.PendingWeapon.bMeleeWeapon;
	return ( Pawn.Weapon != None && Pawn.Weapon.bMeleeWeapon );
}

function EnemyChanged(bool bNewEnemyVisible)
{
    Super.EnemyChanged(bNewEnemyVisible);
    LastEnemyEncounter = Level.TimeSeconds;
}

// More tailored to KF
function ExecuteWhatToDoNext()
{
	local KFMonster Threat;
	local float ThreatDist, ThreatMargin;

	if (PendingMover != None && Pawn.Base == PendingMover && !PendingMover.bInterpolating)
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
		ReloadIfLow();

		BlockedPath = None;
		bFrustrated = false;
		if (Target == None || (Pawn(Target) != None && Pawn(Target).Health <= 0))
			StopFiring();
	}

	if ( ScriptingOverridesAI() && ShouldPerformScript() )
		return;
	if (Pawn.Physics == PHYS_None)
		Pawn.SetMovementPhysics();
	if ( Pawn.FindAnchorFailedTime == Level.TimeSeconds && Pawn.LastValidAnchorTime > 10.f && TeleportBackIn() ) // Maps are buggy, unstick ourselves
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

	// A specimen inside its kite distance comes before errands and squad orders.
	Threat = FindNearestThreat(ThreatDist, ThreatMargin);
	if ( Threat != None && ThreatMargin < 0.f && (Enemy != None || LineOfSightTo(Threat)) )
	{
		if ( Enemy == None )
			Enemy = Threat;
		if ( Enemy != Threat )
			NextTargetCheck = 0;	// let FightEnemy pick the target again now
		SwitchToBestWeapon();
		ChooseAttackMode();
		return;
	}

	if( FindDownedAlly() )
	{
		GoalString = "REVIVING";
		GotoState('Reviving');
		return;
	}

	if( Enemy==none && ((ShouldGoShopping() && GoShopping()) || ShouldBegForCash()) )
		Return;
	if( LastHealTime<Level.TimeSeconds && FindInjuredAlly() && (!EnemyReallyScary() && StartleActor==None) && GoHealing() )
		return;
	else
	{
		if ( Enemy == None && HuntRemainingSpecimens() )
			return;
		if ( AssignSquadResponsibility() )
		{
			if ( Pawn == None )
				return;
			SwitchToBestWeapon();
			return;
		}
		if ( ShouldPerformScript() )
			return;
		if(ThrowAwayBadWeaponForBetterPickup())
		{
			GoalString = "ExecuteWhatToDoNext - Picking up better weapon";
			return;
		}
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
    local KActor KA;
	local KFGlassMover GM;
    local vector ThrowDir;

	Disable('NotifyBump');
	KA = KActor(Other);
	if (KA != None)
	{
		ThrowDir = vector(Pawn.Rotation);
		ThrowDir.Z = 0.5; // A little upward kick
		ThrowDir = Normal(ThrowDir);
		KA.KAddImpulse(ThrowDir * 1500, KA.Location);
		return true;
	}
	GM = KFGlassMover(Other);
	if( GM!=None )
	{
		GM.TakeDamage(50.f, Pawn, Pawn.Location, vect(0,0,0), class'DamageType');
		return true;
	}
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
	{
		CancelCampFor(P.Controller);
		if ( Stopped() && !Pawn.bStationary )
			DirectedWander(Normal(Pawn.Location - P.Location));
		Squad.ClearPathFor(P.Controller);
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
		local bool bSaidThanks; // Don't spam thanks

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

State BeggingPlayerCash
{
Ignores SwitchToBestWeapon;

	function BeginState()
	{
		SetTimer(0,false);
	}
	function EndState()
	{
		BeggingPlayer = None;
	}
	function Timer()
	{
		// Give up if the player left, died, or we've got enough
		if( BeggingPlayer==None || BeggingPlayer.Pawn==None || !ActorReachable(BeggingPlayer.Pawn) || PlayerReplicationInfo.Score>=300 )
			WhatToDoNext(40);
	}
Begin:
	if( BeggingPlayer!=None && BeggingPlayer.Pawn!=None )
		MoveToward(BeggingPlayer.Pawn,BeggingPlayer.Pawn);
	Pawn.Acceleration = vect(0,0,0);
	if( BeggingPlayer!=None && BeggingPlayer.Pawn!=None )
		Focus = BeggingPlayer.Pawn;
	FinishRotation();
	SetTimer(1.0,true);
	Sleep(6.f);
	if( PlayerReplicationInfo.Score>=300 )
		SendChatMsg("Thanks for the dosh!");
	WhatToDoNext(41);
}

//Tosses out the worst weapon in our inventory, or the specified weapon
final function bool ThrowAwayBadWeapon(KFWeapon WeapToThrow)
{
	local vector TossVel, X,Y,Z;

	if( WeapToThrow!=none )
	{
		if ( Pawn.Weapon != WeapToThrow )
		{
			Pawn.PendingWeapon = WeapToThrow;
			Pawn.ChangedWeapon();
			if ( Pawn.Weapon != WeapToThrow )
				return false;	// can't switch right now (reloading, mid-fire): try again another time
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

	foreach DynamicActors(class'KFWeaponPickup',GroundPk) // Scan ground pickups
	{
        if (GroundPk == None || GroundPk.InventoryType == None || !GroundPk.ReadyToPickup(0) || !ActorReachable(GroundPk) || VSize(GroundPk.Location - Pawn.Location) > 400.f)
            continue;

		NewWWeight = GroundPk.Default.Weight;
		if(HP.CanCarry(NewWWeight)) // Already fits, no drop needed
			continue;

		GroundRating = class<KFWeapon>(GroundPk.InventoryType).default.AIRating;
		if(WeaponIsForPerk(GroundPk.Class)) // Perk weapons get a bump
			GroundRating *= 1.5;

        bAlreadyOwn        = false;
        CurBestDrop        = None;
        CurBestDropRating  = 0.0;

		for (Inv = Pawn.Inventory; Inv != None; Inv = Inv.Inventory) // Compare against inventory
		{
			W = KFWeapon(Inv);
			if (W == None || W.bKFNeverThrow) // Must be real and throwable
				continue;

			//SendChatMsg("Considering dropping my "$W.GetHumanReadableName()$" for pickup "$GroundPk.GetHumanReadableName()$".");

            if (W.Class == class<KFWeapon>(GroundPk.InventoryType))
            {
                bAlreadyOwn = true;
                break;
            }

			CurWRating = W.default.AIRating;
			if(WeaponIsForPerk(class<KFWeaponPickup>(W.PickupClass))) // Perk weapon bump
				CurWRating *= 1.5; 

			if ( GroundRating <= CurWRating ) // Pickup isn't better, skip
				continue;

			if ((HP.CurrentWeight - W.Weight) + NewWWeight > HP.MaxCarryWeight) // Still wouldn't fit after dropping, skip
				continue;

            if (!bAlreadyOwn && (CurBestDrop == None || CurWRating < CurBestDropRating))
            {
                CurBestDrop       = W;
                CurBestDropRating = CurWRating;
            }
		}
		if (bAlreadyOwn) // Already have it, skip
            continue; 

		// Best trade so far?
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
		if(MoveTarget != None && VSize(MoveTarget.Location - Pawn.Location) < 200.f) 
		{
			GoToState('Fallback');
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
		if( (DoorPaths[i].Door.bSealed || DoorPaths[i].Door.bTriggerTooFar || DoorPaths[i].Door.MyTrigger == None) && !DoorPaths[i].Door.bDoorIsDead )
			DoorPaths[i].Path.CollisionRadius -= 10000; // Pretend that no pawn is small enough to use this.
		else DoorPaths.Remove(i--,1); // Remove opened paths.
	}

	SetLiftsBlocked(true);
	Result = FindRandomDest();
	SetLiftsBlocked(false);
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
		if( (DoorPaths[i].Door.bSealed || DoorPaths[i].Door.bTriggerTooFar || DoorPaths[i].Door.MyTrigger == None) && !DoorPaths[i].Door.bDoorIsDead )
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
		if( (DoorPaths[i].Door.bSealed || DoorPaths[i].Door.bTriggerTooFar || DoorPaths[i].Door.MyTrigger == None) && !DoorPaths[i].Door.bDoorIsDead )
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
				if ( (NumRandomJumps > 4) || PhysicsVolume.bWaterVolume ) // TODO: Sometimes they get stuck behind doors (fucking dumbasses)
				{
					if (TeleportBackIn())
						return true;
					else
					{
							// Last resort, waste this man
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
	// Clear the counter if we've got a usable anchor
	if ( Pawn.Anchor != None )
		NumRandomJumps = 0;
	GoalString = "Find roam dest "$Level.TimeSeconds;

	if ( (RouteGoal == None) || (Pawn.Anchor == RouteGoal)
		|| Pawn.ReachedDestination(RouteGoal) )
	{
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
			// The random search can hand back the node the bot is standing on (it always does when no usable path
			// leads away from it). That is no destination: Roaming would start over at once, again and again
			// within one tick, until the engine stops the game with "runaway loop".
			if ( RouteGoal != None && (RouteGoal == Pawn.Anchor || Pawn.ReachedDestination(RouteGoal)) )
			{
				RouteGoal = None;
				BestPath = None;
			}
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
	return false;
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
	//log(PlayerReplicationInfo.PlayerName$" Starting Trading. Cash available: " $PlayerReplicationInfo.Score);
    ShoppingAttempts = 0;
	if (KFEndlessGameType(Level.Game) != None)
		LastShopTime = Level.TimeSeconds + 120 + 120*FRand();
	else LastShopTime = Level.TimeSeconds + 60 + 60*FRand();
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
				log(PlayerReplicationInfo.PlayerName@"of perk"@GetPerkName()@"Buying weapon: " $ BuyWeapClass $ " for " $ Cost);
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
	PlayerReplicationInfo.Score = Max(PlayerReplicationInfo.Score,0);
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
		//Have to do this again so it fills up even guns we just have in our inventory
		AmmoWeapClass = class<KFWeaponPickup>(ShoppingList[i]);
		WeapAmmo = FindWeaponInInv(AmmoWeapClass);
		if(WeapAmmo!=none)
		{
			FillAllAmmo(WeapAmmo.GetAmmoClass(0),1.f);
			// Fill secondary ammo (e.g. explosive shells) if the weapon has a distinct secondary ammo type
			if (WeapAmmo.GetAmmoClass(1) != None && WeapAmmo.GetAmmoClass(1) != WeapAmmo.GetAmmoClass(0))
				FillAllAmmo(WeapAmmo.GetAmmoClass(1),1.f);
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
		GoalString = "RECOVER_DROP";
        GotoState('RecoverDroppedWeapons');
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
    // Only try once per shopping session, skip if wave ends soon unless it's close and roughly our floor
    if (bTriedRecoverLastDrop || (KFEndlessGameType(Level.Game) == None && KFGameReplicationInfo(Level.Game.GameReplicationInfo).TimeToNextWave < 20 && (PickupTarget != None && ((VSize(Pawn.Location - PickupTarget.Location) > 800) || (Pawn.Location.Z - PickupTarget.Location.Z) > 500))))
        return false;

    return (PickupTarget != None);
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

function bool FindDownedAlly()
{
	local Controller C;
	local KFHumanPawnZombies P, Best;
	local float D, BestD;

	ReviveTarget = None;
	if( Level.TimeSeconds<NextReviveTime || Pawn==None || Pawn.Health<=0 )
		return false;

	for( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		P = KFHumanPawnZombies(C.Pawn);
		if( P==None || P==Pawn || !P.bIsDowned || P.bSelfReviving || P.Health<=0 )
			continue;
		if( P.bBeingRevived && P.Reviver!=Pawn )
			continue;

		D = VSize(P.Location-Pawn.Location);
		if( D<ReviveSearchDist && (Best==None || D<BestD) )
		{
			Best = P;
			BestD = D;
		}
	}

	ReviveTarget = Best;
	return Best!=None;
}

function SetCombatTimer()
{
	SetTimer(0.16f, True);
}
function PawnDied(Pawn P)
{
	TempBlockedPaths.Length = 0;
	DoorPaths.Length = 0;

    InjuredAlly = None;
    ReviveTarget = None;
    BeggingTarget = None;
    AnswerBegger = None;
    DonatePlayer = None;
    PickupTarget = None;
    ShopVolumeActor = None;
    TargetDoor = None;
    NearbyHealCloud = None;

    // Respawn fresh
    LastShopTime = 0;
    LastHealTime = 0;
    LastEnemyEncounter = 0;
    bTriedRecoverLastDrop = false;
    LastDroppedWeaponClasses.Length = 0;
    ShoppingAttempts = 0;

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
	if ( W.bMeleeWeapon && Enemy != None && GetPerkName() != "Berserker" )
	{
		// Not a Berserker: a blade is for a lone weak specimen or for when the guns are dry, and not at all when hurt.
		if ( Pawn.Health <= 40 )
			return 0.05;
		if ( !IsEasyMeleeTarget(Enemy) || CountThreatsWithin(300.f) >= 3 )
			R *= 0.5;
	}
	// A rocket launcher that cannot be fired safely at the enemy is no weapon for now.
	if ( Enemy != None && RocketClassOf(W) != None
		&& (Level.TimeSeconds - RocketUnsafeTime < 1.5f || !RocketShotSafe(Enemy, RocketClassOf(W))) )
		return 0.05;
	// (No more "save the last 9mm magazine": it made a bot with a few rounds left draw the knife instead.)
	return R;
}

function float AdjustDesireFor(Pickup P)
{
	if( KFWeaponPickup(P)!=None )
	{
		if( !WeaponIsForPerk(Class<KFWeaponPickup>(P.Class)) )
			return -0.5f;
	}
	return 0.5f;
}

final function bool WeaponIsForPerk( class<KFWeaponPickup> Wep )
{
	if( KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill==None )
		return true;
	if (GetPerkName() == "Field Medic" || GetPerkName() == "Sergeant") // These guys don't get perk weapons
		return true;
	return (Wep.Default.CorrespondingVeterancyName==GetPerkName());
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
    if( Alpha == Alpha && Alpha + 1.0 != Alpha )
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
		Pawn.bWantsToCrouch = false;
	}
	function EndState()
	{
		SetBotSprinting(false);
	}
	final function bool TryToHealthTarget()
	{
		local vector V;
		local WeaponFire F;
		local int MedicReward,HealSum;
		local KFPlayerReplicationInfo PRI;

		if( InjuredAlly==None || InjuredAlly.Health<=0 )
			return false;

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
			MedicReward = int((FMin(float(MedicReward),InjuredAlly.HealthMax)/InjuredAlly.HealthMax) * 60);
		}
		MySyringe.PlayOwnedSound(Sound'KFWeaponSound.SyringeFire',SLOT_Interact,F.TransientSoundVolume,,F.TransientSoundRadius,,false);
		MySyringe.IncrementFlashCount(0);
		return true;
	}
	function Timer()
	{
		local float D, Mg;

		// drop it when a specimen gets inside its kite distance
		if( FindNearestThreat(D, Mg)!=None && Mg<0.f )
		{
			InjuredAlly = None;
			LastHealTime = level.TimeSeconds+3;
			WhatToDoNext(164);
			return;
		}
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
		else if( !Pawn.Weapon.HasAmmo() )
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

state Reviving
{
ignores WaitForMover;

	function BeginState()
	{
		SetBotSprinting(true);
		Pawn.bWantsToCrouch = false;
	}
	function EndState()
	{
		SetBotSprinting(false);
	}
	final function bool ReviveTargetValid()
	{
		return ReviveTarget!=None && ReviveTarget.bIsDowned && ReviveTarget.Health>0 && Pawn!=None && Pawn.Health>0;
	}
	function Timer()
	{
		local float D, Mg;

		if( FindNearestThreat(D, Mg)!=None && Mg<0.f )
		{
			ReviveTarget = None;
			NextReviveTime = Level.TimeSeconds+3;
			WhatToDoNext(165);
			return;
		}
		if( !ReviveTargetValid() )
		{
			ReviveTarget = None;
			WhatToDoNext(166);
			return;
		}
		if( VSize(ReviveTarget.Location-Pawn.Location)<=ReviveTarget.ReviveRadius )
			ReviveTarget.AccumulateRevive(Pawn);
	}
Begin:
	WaitForLanding();
	SetTimer(0.1, True);

	while( ReviveTargetValid() )
	{
		if( VSize(ReviveTarget.Location-Pawn.Location)<=ReviveTarget.ReviveRadius*0.8 && LineOfSightTo(ReviveTarget) )
		{
			Focus = ReviveTarget;
			Pawn.Acceleration = vect(0,0,0);
			Sleep(0.2);
		}
		else if( FindBestPathToward(ReviveTarget,false,false) )
			MoveToward(MoveTarget,ReviveTarget,,true);
		else break;
	}

	ReviveTarget = None;
	NextReviveTime = Level.TimeSeconds+2;
	WhatToDoNext(167);
	if ( bSoaking )
		SoakStop("STUCK IN REVIVING!");
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
	if( CurrentPath!=None && KFDoorMover(Wall)!=None && ((KFDoorMover(Wall).bSealed && !KFDoorMover(Wall).bDisallowWeld) || KFDoorMover(Wall).bTriggerTooFar || KFDoorMover(Wall).MyTrigger == None) )
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


/* ChooseAttackMode, picks which type of attack to do */
function ChooseAttackMode()
{
    GoalString = " ChooseAttackMode last seen "$(Level.TimeSeconds - LastSeenTime);
    // should I run away?
    if ( (Squad == None) || (Enemy == None) || (Pawn == None) )
        log("HERE 1 Squad "$Squad$" Enemy "$Enemy$" pawn "$Pawn);

	// Between weapons (the one in hand was sold or dropped): take one out before judging it.
	if ( Pawn.Weapon == None )
	{
		SwitchToBestWeapon();
		if ( Pawn.Weapon == None )
		{
			DoRetreat();
			return;
		}
	}

	// Fall back to a better pickup, but only when it's safe.
	// No close visible enemies, not surrounded.
	if ( (Pawn.Weapon.CurrentRating < 0.5) && (Pawn.Weapon.default.AIRating < 0.5)
		&& !ManyEnemiesAround(3, Pawn.Location)
		&& (!EnemyVisible() || VSize(Pawn.Location - Enemy.Location) > 500.f) )
	{
		if ( FindInventoryGoal(0) )
		{
			GoalString = "Fallback to better pickup (safe)";
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

final function vector GetHeadAimLocation(Actor Tgt)
{
	local Pawn P;
	local coords C;

	P = Pawn(Tgt);
	if (P != None && P.HeadBone != '')
	{
		C = P.GetBoneCoords(P.HeadBone);
		return C.Origin + (P.HeadHeight * P.HeadScale * C.XAxis);
	}
	// Fallback, Monster.IsHeadShot geometric formula (no bone)
	return Tgt.Location + Tgt.CollisionHeight * vect(0,0,0.5);
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

	// A thrown grenade leaves the hand at the speed TossNade sets (850 or more, not the projectile's default 160),
	// in an arc, and goes off two seconds later. Aimed as a straight projectile of speed 160, the lead on a
	// specimen walking at the bot put the aim point at the bot's own feet, or behind it.
	if ( class<Nade>(FiredAmmunition.ProjectileClass) != None )
	{
		FireRotation = rotator(GetNadeTossDir(projStart, GetNadeTossSpot(Target)));
		SetRotation(FireRotation);
		return FireRotation;
	}

	// A rocket: straight at the body, with a little lead. The stock aim goes for the floor at the target's feet, or
	// for the corner where the target was last seen, and the rocket then goes off on the way, inside its own blast.
	if ( Pawn(Target) != None && FiredAmmunition.ProjectileClass != None && RocketBlastRadius(Pawn.Weapon) > 0.f
		&& FiredAmmunition.ProjectileClass == Pawn.Weapon.GetFireMode(0).ProjectileClass )
	{
		FireSpot = Target.Location + 0.8f * Target.Velocity * (TargetDist / FMax(projspeed, 1.f));
		if ( Target.Physics == PHYS_Walking )
			FireSpot.Z = Target.Location.Z;
		if ( !FastTrace(FireSpot, projStart) )
			FireSpot = Target.Location;
		FireRotation = rotator(FireSpot - projStart);
		FireRotation.Yaw = SetFireYaw(FireRotation.Yaw + AdjustAimError(aimerror, TargetDist, false, false, true) / 2);
		SetRotation(FireRotation);
		return FireRotation;
	}

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
    if (!bClean)
    {
		// try head
		FireSpot = GetHeadAimLocation(Target);
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

	// Don't splash ourselves, nudge FireSpot outside blast radius
	if ( Pawn.Weapon != None && Pawn.Weapon.SplashDamage()
		&& VSize(FireSpot - Pawn.Location) < Pawn.Weapon.GetDamageRadius() )
	{
		FireSpot = Pawn.Location + Normal(FireSpot - Pawn.Location) * (Pawn.Weapon.GetDamageRadius() + 50);
		if ( !FastTrace(FireSpot, ProjStart) )
			bCanFire = false;
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
	if(Pawn.Health > 0 && LastChatTime + 3.f < Level.TimeSeconds) // Don't spam chat when dead or more than every 3 seconds
	{		
		LastChatTime = Level.TimeSeconds;
		Level.Game.Broadcast(self, "["$PlayerReplicationInfo.GetCallSign()$"] "$S, 'TeamSayQuiet');
	}
}

final function MaybeCalloutEnemy(Pawn SeenEnemy)
{
    local KFMonster M;
    local float D;

    if (LastCalloutTime + 60.f > Level.TimeSeconds)
        return; // Don't spam

    M = KFMonster(SeenEnemy);
    if (M == None || M.Health <= 0)
        return;

    D = VSize(M.Location - Pawn.Location);

    if (M.IsA('ZombieBoss'))
    {
        LastCalloutTime = Level.TimeSeconds;
        switch (Rand(3))
        {
            case 0: SendChatMsg("patty here"); break;
            case 1: SendChatMsg("on me"); break;
            case 2: SendChatMsg("BOSS"); break;
        }
    }
    else if (M.IsA('ZombieFleshPound'))
    {
        LastCalloutTime = Level.TimeSeconds;
        switch (Rand(4))
        {
            case 0: SendChatMsg("fp"); break;
            case 1: SendChatMsg("FP"); break;
            case 2: SendChatMsg("fp on me"); break;
            case 3: SendChatMsg("watch out fp"); break;
        }
    }
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
	if(GetPerkName() == "Berserker") // Berserkers heal less often
		return 20;
	else if( (Level.TimeSeconds-LastEnemyEncounter)>10.f )
		return 99;
	else if( (Level.TimeSeconds-LastEnemyEncounter)>3.f )
		return 75;
	return 50;
}

final function bool ManyEnemiesAround(int MinEnemies, vector Loc)
{
    local Controller C;
    local int NearbyEnemies;

    for (C = Level.ControllerList; C != None; C = C.nextController)
    {
        if (KFMonster(C.Pawn) != None && KFMonster(C.Pawn).Health > 0)
        {
            if (VSize(C.Pawn.Location - Loc) < 800.f && FastTrace(Loc, C.Pawn.Location))
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
	if (GetPerkName() == "Field Medic")
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

// Stray semicolon in original after the FastTrace if made return false unconditional,
// so ClearShot always returned false
function bool ClearShot(Vector TargetLoc, bool bImmediateFire)
{
    local bool bSeeTarget;

    if ( (Enemy == None) || (VSize(Enemy.Location - TargetLoc) > MAXSTAKEOUTDIST) )
        return false;

    bSeeTarget = FastTrace(TargetLoc, Pawn.Location + Pawn.EyeHeight * vect(0,0,1));
    if ( !bImmediateFire && !bSeeTarget && Pawn.bIsCrouched )
        bSeeTarget = FastTrace(TargetLoc, Pawn.Location + (Pawn.Default.EyeHeight + Pawn.Default.CollisionHeight - Pawn.CollisionHeight) * vect(0,0,1));

    if ( !bSeeTarget || !FastTrace(TargetLoc, Enemy.Location + Enemy.BaseEyeHeight * vect(0,0,1)) )
        return false;
    if ( (Pawn.Weapon.SplashDamage() && (VSize(Pawn.Location - TargetLoc) < Pawn.Weapon.GetDamageRadius()))
        || !FastTrace(TargetLoc + vect(0,0,0.9) * Enemy.CollisionHeight, Pawn.Location) )
    {
        StopFiring();
        return false;
    }
    return true;
}

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

//Rewritten for KF
function FightEnemy(bool bCanCharge, float EnemyStrength)
{
	local float enemyDist;
	local float AdjustedCombatStyle;
	local bool bFarAway, bOldForcedCharge;
	local KFMonster Threat;
	local float ThreatDist, ThreatMargin;

	if ( (Squad == None) || (Enemy == None) || (Pawn == None) )
		log("HERE 3 Squad "$Squad$" Enemy "$Enemy$" pawn "$Pawn);
	Threat = FindNearestThreat(ThreatDist, ThreatMargin);
	if ( Pawn.Weapon == None )
	{
		SwitchToBestWeapon();
		if ( Pawn.Weapon == None )
		{
			DoRetreat();
			return;
		}
	}

	if( NextTargetCheck<Level.TimeSeconds )
	{
		FindBetterTarget();	
		NextTargetCheck = Level.TimeSeconds+1.f;
	}
	if( Enemy!=None )
		LastEnemyEncounter = Level.TimeSeconds;
	// Badly hurt with something on top of us: get clear before anything else.
	if ( Pawn.Health < 35 && Threat != None && ThreatDist < 220.f && GetPerkName() != "Berserker" )
	{
		GoalString = "Retreat, badly hurt";
		DoRetreat();
		return;
	}
	// Heal when nothing can reach us while we do it (was: only with fewer than two specimens in sight within 800).
	if (Pawn.Health < GetMinHealingValue() && (Threat == None || ThreatMargin > 150.f) && StartleActor == None && TryToHealSelf() )
		return;
	if( NextNadeTimer<Level.TimeSeconds && MyGrenades!=None && MyGrenades.HasAmmo() && (Threat==None || ThreatMargin>0.f) && (Rand(2)==0 || ManyEnemiesAround(5, Pawn.Location)) && ShouldNadeEnemy() )
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
			Aggression += AdjustedCombatStyle;
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

	// see enemy, decide whether to charge it or strafe around/stand and fire
	BlockedPath = None;
	Target = Enemy;

	// A Bloat this close is better left alive until we are out of reach of what comes out of it when it dies.
	if ( !HoldingMelee() && Enemy.IsA('ZombieBloat') && VSize(Enemy.Location - Pawn.Location) < BloatSafeDist() && PickAwayMove(220.f) )
	{
		GoalString = "Back away from the Bloat before killing it";
		GotoState('BackFromBloat');
		return;
	}

	// With a gun in hand, never stand still inside a specimen's reach or next to our own grenade: back off and keep shooting.
	if ( !HoldingMelee() && ((Threat != None && ThreatMargin < 0.f) || NadeDanger()) )
	{
		GoalString = "Back off and shoot";
		DoTacticalMove();
		return;
	}
	// A blade in the hands of anyone but a Berserker is a last resort: don't walk into a crowd, or into bile, with it.
	if ( HoldingMelee() && GetPerkName() != "Berserker" && KFMonster(Enemy) != None
		&& (!IsEasyMeleeTarget(Enemy) || CountThreatsWithin(300.f) >= 3) )
	{
		GoalString = "Retreat, no gun";
		DoRetreat();
		return;
	}

	if( Pawn.Weapon.bMeleeWeapon || (bCanCharge && bOldForcedCharge) )
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
	if( Pawn.Health<=25 && VSize(Pawn.Location - Enemy.Location)<120.f )
	{
		GoalString = "Retreat";
		DoRetreat();
		return;
	}
	GoalString = "Do tactical move";
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
		{
			UnWeldFromRoom(KFDoorMover(Wall));
			if(FRand() < 0.5)
				SendChatMsg("That door is sealed! Let me try to open it.");
			return true;
		}
		return Global.NotifyHitWall(HitNormal,Wall);
	}
    function float RateWeapon(Weapon W)
    {
        if( KFWeapon(W)==None )
            return Global.RateWeapon(W);
        return FMax(10.f-KFWeapon(W).Weight,0.f)*0.75*int(KFWeapon(W).bMeleeWeapon);
    }
    function EndState()
    {
		Super.EndState();
        SetBotSprinting(false);
    }
}

state NadeTarget
{
	ignores	EnemyChanged,NotifyBump;

	final function TossNade()
	{
		local Nade N;

		// the target can have died and gone while we turned towards it
		if ( Target == None )
			return;
		if (MyGrenades != None)
		{
			FragFire(MyGrenades.GetFireMode(0)).mHoldSpeedMax = GetNadeTossSpeed(GetNadeTossSpot(Target));
			MyGrenades.ServerThrow();
			if ( KFMonster(Target) != None && GetPerkName() != "Field Medic" )
			{
				// keep track of it, to stay out of its blast until it has gone off (see CheckOwnNade)
				NadeDangerSpot = GetNadeTossSpot(Target);
				NadeDangerTime = Level.TimeSeconds + 0.5f;
				foreach DynamicActors(class'Nade', N)
					if ( N.Instigator == Pawn && !N.bHasExploded )
						MyLiveNade = N;
			}
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
		Target = Enemy; // Default: nade the enemy
	}
	else
	{
		//SendChatMsg("No valid target for grenade!");
		WhatToDoNext(153);
		Stop;
	}
	Pawn.Acceleration = vect(0,0,0);	// stand still for the throw
	Sleep(0.1f);
	if( KFPawn(Pawn) != none )
		KFPawn(Pawn).SetAnimAction('NadeToss');
	if ( NeedToTurn(Target.Location) )
	{
		Focus = Target;
		FinishRotation();
	}
	TossNade();
	Sleep(0.4);
	if(rand(2)==0 && ManyEnemiesAround(5, Pawn.Location) && MyGrenades.HasAmmo() && ShouldNadeEnemy())
		GoTo'Begin';
	WhatToDoNext(153);
	if ( bSoaking )
		SoakStop("STUCK IN NADES!");
}

// Our own grenade is about to go off close by: back away from it (and from whatever else is near), keep shooting.
state AvoidOwnNade
{
	ignores EnemyChanged, EnemyNotVisible, SeePlayer, HearNoise;

	function BeginState()
	{
		SetBotSprinting(true);
		Pawn.bWantsToCrouch = false;
	}
	function EndState()
	{
		SetBotSprinting(false);
	}
	function Timer()
	{
		enable('NotifyBump');
		if ( Enemy != None )
			TimedFireWeaponAtEnemy();
		else
			SetCombatTimer();
	}
Begin:
	WaitForLanding();
	while ( MyLiveNade != None )
	{
		if ( NadeDanger() && PickAwayMove(200.f) )
		{
			if ( MoveTarget != None )
				MoveToward(MoveTarget, Enemy,, true);
			else if ( Enemy != None )
				MoveTo(Destination, Enemy);
			else
				MoveTo(Destination);
		}
		else
		{
			// far enough: hold here until it has gone off instead of walking back into it
			Pawn.Acceleration = vect(0,0,0);
			if ( Enemy != None )
				Focus = Enemy;
			Sleep(0.2);
		}
	}
	WhatToDoNext(154);
}

// One leg of a fighting retreat along the path network (see PickPathAwayFromThreats).
state FallBackOnPath
{
	ignores SeePlayer, HearNoise;

	function BeginState()
	{
		SetBotSprinting(true);
		Pawn.bWantsToCrouch = false;
	}
	function EndState()
	{
		SetBotSprinting(false);
	}
	function Timer()
	{
		enable('NotifyBump');
		Target = Enemy;
		if ( Enemy != None )
			TimedFireWeaponAtEnemy();
		else
			SetCombatTimer();
	}
Begin:
	WaitForLanding();
	if ( MoveTarget != None )
		MoveToward(MoveTarget, Enemy,, true);
	WhatToDoNext(155);
}

// Standing in Bloat bile, or just hit by it: leave. The damage keeps coming for as long as a pawn stays in or
// next to it, and nothing else tells the bot (it used to carry on resting, healing or shooting on the spot).
state AvoidBile
{
	ignores EnemyChanged, EnemyNotVisible, SeePlayer, HearNoise;

	function BeginState()
	{
		SetBotSprinting(true);
		Pawn.bWantsToCrouch = false;
		BileLeaveTime = Level.TimeSeconds + 3.f;
	}
	function EndState()
	{
		SetBotSprinting(false);
		NextBileAvoidTime = Level.TimeSeconds + 0.5f;
	}
	function Timer()
	{
		enable('NotifyBump');
		Target = Enemy;
		if ( Enemy != None )
			TimedFireWeaponAtEnemy();
		else
			SetCombatTimer();
	}
Begin:
	WaitForLanding();
	while ( InBile() && Level.TimeSeconds < BileLeaveTime )
	{
		if ( !PickAwayMove(250.f) )
			break;
		if ( MoveTarget != None )
			MoveToward(MoveTarget, Enemy,, true);
		else if ( Enemy != None )
			MoveTo(Destination, Enemy);
		else
			MoveTo(Destination);
	}
	WhatToDoNext(156);
}

state LeaveLift
{
	ignores EnemyChanged, EnemyNotVisible, SeePlayer, HearNoise;

	function BeginState()
	{
		SetBotSprinting(true);
		Pawn.bWantsToCrouch = false;
	}
	function EndState()
	{
		SetBotSprinting(false);
		NextLiftCheckTime = Level.TimeSeconds + 1.f;
	}
	function Timer()
	{
		enable('NotifyBump');
		Target = Enemy;
		if ( Enemy != None )
			TimedFireWeaponAtEnemy();
		else
			SetCombatTimer();
	}
Begin:
	WaitForLanding();
	if ( LiftLeaveSpot != None )
		MoveToward(LiftLeaveSpot, Enemy,, true);
	WhatToDoNext(160);
}

state WaitForLift
{
	function BeginState()
	{
		WaitLiftUntil = Level.TimeSeconds + 20.f;
		Pawn.bWantsToCrouch = false;
	}
	function EndState()
	{
		if ( PendingMover == WaitLift )
			PendingMover = None;
		NextLiftCheckTime = Level.TimeSeconds + 0.5f;
	}
	function Timer()
	{
		enable('NotifyBump');
		Target = Enemy;
		if ( Enemy != None )
			TimedFireWeaponAtEnemy();
		else
			SetCombatTimer();
	}
Begin:
	WaitForLanding();
	PendingMover = WaitLift;
	if ( PickLiftWaitSpot() )
		MoveTo(Destination, WaitLift.MyMarker);
Waiting:
	Pawn.Acceleration = vect(0,0,0);
	if ( Enemy != None && EnemyVisible() )
		Focus = Enemy;
	else
		Focus = WaitLift.MyMarker;
	PendingMover = WaitLift;
	ReloadIfLow();
	Sleep(0.3);
	if ( LiftHere() )
	{
		Sleep(0.4);
		WhatToDoNext(161);
	}
	else if ( Level.TimeSeconds > WaitLiftUntil )
		WhatToDoNext(162);
	Goto('Waiting');
}

// Moving out of reach of a Bloat without shooting it (see FightEnemy).
state BackFromBloat
{
	ignores SeePlayer, HearNoise;

	function BeginState()
	{
		SetBotSprinting(true);
		Pawn.bWantsToCrouch = false;
		StopFiring();
	}
	function EndState()
	{
		SetBotSprinting(false);
	}
	function Timer()
	{
		enable('NotifyBump');
		SetCombatTimer();
	}
	function bool FireWeaponAt(Actor A)
	{
		return false;
	}
Begin:
	WaitForLanding();
	if ( MoveTarget != None )
		MoveToward(MoveTarget, Enemy,, true);
	else if ( Enemy != None )
		MoveTo(Destination, Enemy);
	else
		MoveTo(Destination);
	WhatToDoNext(157);
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
    local float D;
    local bool bAnyMonsterHasLOS;
    local bool bHasLOS;
    local KFNadeHealingExplosion TempCloud;
	local Vector HN,HL;

	if( CurrentMov==None )
	{
		for( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
		{
			if( LiftCenter(N)!=None )
				continue;
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
		if( N==CurrentMov || N.bBlocked || LiftCenter(N)!=None || !ActorReachable(N) )
			continue;
		EnemyDir = vect(0,0,0);
        TotalWeight = 0.0;
        bAnyMonsterHasLOS = false;
        for( C = Level.ControllerList; C != None; C = C.nextController )
        {
            M = KFMonster(C.Pawn);
            if( M == None || M.Health <= 0 )
                continue;

            D = VSize(M.Location - Pawn.Location);
            bHasLOS = LineOfSightTo(M);
            // Visible within 600u, or around-corner within 800u
            if( D > 800.f || (bHasLOS && D > 600.f) )
                continue;

            // Closer/focused = higher weight; non-visible = half
            Weight = 1.0 / FMax(D, 1.0);
            if( !bHasLOS )
                Weight *= 0.5;
            if( C.Enemy == Pawn )
                Weight *= 1.5;

            EnemyDir    += Weight * Normal(M.Location - Pawn.Location);
            TotalWeight += Weight;

            if( C.LineOfSightTo(N) )
                bAnyMonsterHasLOS = true;
        }
        if ( TotalWeight > 0 )
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
                    Dist -= Normal(NextSquadMember.Pawn.Location - Pawn.Location) dot Normal(N.Location - Pawn.Location) * 0.3f; 
        }
		if( MoveTarget==None || Dist<BestDist )
		{
			MoveTarget = N;
			BestDist = Dist;
		}
		if( Pawn.Health < 60 )
		{
			TempCloud = FindNearbyHealCloud();
			if( TempCloud != None )
				MoveTarget = TempCloud;
		}
	}
	for( i=0; i<TempBlockedPaths.Length; ++i )
		TempBlockedPaths[i].bBlocked = false;
	if( MoveTarget != None && NavigationPoint(MoveTarget) != None && TotalWeight > 0 && BestDist > 0 )
		MoveTarget = None;
	if( MoveTarget!=None )
	{
		if(Trace(HL,HN,Pawn.Location,MoveTarget.Location,false)==Enemy) // Don't march straight at the enemy
		{	
			MoveTarget = None;
			//SendChatMsg("Trying to pick a different move to avoid going directly towards the enemy.");
		}
		PreviousNavPath = NavigationPoint(MoveTarget);
		AddOldMove(CurrentMov);
	    if( IsPingPonging() )
		{
			MoveTarget = None;
			//SendChatMsg("Ping ponging detected, trying to pick a different move.");
		}
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

final function bool IsPingPonging()
{
    return OldMovesCount >= 4
        && OldMoves[0] == OldMoves[2]
        && OldMoves[1] == OldMoves[3];
}
 
function DoRetreat()
{
	GotoState('Retreating');
}

state Retreating
{
ignores SeePlayer, HearNoise;

	function BeginState()
	{
		SetBotSprinting(true);
		Pawn.bWantsToCrouch = false;
		SetTimer(0.1,true);
	}

	function Timer()
	{
		enable('NotifyBump');
		Target = Enemy;
		if ( (Enemy != None) && !bNotifyApex )
			TimedFireWeaponAtEnemy();
		else
			SetCombatTimer();
	}

	function EnemyNotVisible()
	{
		StopFiring();
		if ( enemy != None )
		{
			if ( aggressiveness > relativestrength(enemy) )
			{
				if ( FastTrace(Enemy.Location, LastSeeingPos) )
					GotoState('TacticalMove','RecoverEnemy');
				else
					WhatToDoNext(20);
			}
		}
		else
			WhatToDoNext(201);

		Disable('EnemyNotVisible');
	}

	function EndState()
	{
		SetBotSprinting(false);
		//ClearStayingDebugLines();
	}
	
Begin:
	SwitchToBestWeapon();
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
		LastFallbackMoveTime = Level.TimeSeconds;
		PickNextRetMove();
		if( MoveTarget==None )
		{
			MoveTo(Normal(Pawn.Location-Enemy.Location)*400.f+VRand()*300.f+Pawn.Location,Enemy);
			break;
		}
		else
			MoveToward(MoveTarget,Enemy,GetDesiredOffset(),ShouldStrafeTo(MoveTarget));
		if( Level.TimeSeconds - LastFallbackMoveTime < 0.15 )
			Sleep(0.15);
	}
	WhatToDoNext(44);
	if ( bSoaking )
		SoakStop("STUCK IN RETREAT!");
	goalstring = goalstring$" STUCK IN RETREAT!";
}

state Charging
{
ignores SeePlayer, HearNoise;

	/* MayFall() called by engine physics if walking and bCanJump, and
		is about to go off a ledge.  Pawn has opportunity (by setting
		bCanJump to false) to avoid fall
	*/
	function MayFall()
	{
		if ( MoveTarget != Enemy )
			return;

		Pawn.bCanJump = ActorReachable(Enemy);
		if ( !Pawn.bCanJump )
			MoveTimer = -1.0;
	}

	function bool TryToDuck(vector duckDir, bool bReversed)
	{
		if ( !Pawn.bCanStrafe )
			return false;
		if ( FRand() < 0.6 )
			return Global.TryToDuck(duckDir, bReversed);
		if ( MoveTarget == Enemy )
			return TryStrafe(duckDir);
	}

	function bool StrafeFromDamage(float Damage, class<DamageType> DamageType, bool bFindDest)
	{
		local vector sideDir;

		if ( FRand() * Damage < 0.15 * CombatStyle * Pawn.Health )
			return false;

		if ( !bFindDest )
			return true;

		sideDir = Normal( Normal(Enemy.Location - Pawn.Location) Cross vect(0,0,1) );
		if ( (Pawn.Velocity Dot sidedir) > 0 )
			sidedir *= -1;

		return TryStrafe(sideDir);
	}

	function bool TryStrafe(vector sideDir)
	{
		local vector extent, HitLocation, HitNormal;
		local actor HitActor;

		Extent = Pawn.GetCollisionExtent();
		HitActor = Trace(HitLocation, HitNormal, Pawn.Location + MINSTRAFEDIST * sideDir, Pawn.Location, false, Extent);
		if (HitActor != None)
		{
			sideDir *= -1;
			HitActor = Trace(HitLocation, HitNormal, Pawn.Location + MINSTRAFEDIST * sideDir, Pawn.Location, false, Extent);
		}
		if (HitActor != None)
			return false;

		if ( Pawn.Physics == PHYS_Walking )
		{
			HitActor = Trace(HitLocation, HitNormal, Pawn.Location + MINSTRAFEDIST * sideDir - MAXSTEPHEIGHT * vect(0,0,1), Pawn.Location + MINSTRAFEDIST * sideDir, false, Extent);
			if ( HitActor == None )
				return false;
		}
		Destination = Pawn.Location + 2 * MINSTRAFEDIST * sideDir;
		GotoState('TacticalMove', 'DoStrafeMove');
		return true;
	}

	function NotifyTakeHit(pawn InstigatedBy, vector HitLocation, int Damage, class<DamageType> damageType, vector Momentum)
	{
		local float pick;
		local vector sideDir;
		local bool bWasOnGround;

		Super.NotifyTakeHit(InstigatedBy,HitLocation, Damage,DamageType,Momentum);
		LastUnderFire = Level.TimeSeconds;

		bWasOnGround = (Pawn.Physics == PHYS_Walking);
		if ( Pawn.health <= 0 )
			return;
		if ( StrafeFromDamage(damage, damageType, true) )
			return;
		else if ( bWasOnGround && (MoveTarget == Enemy) &&
					(Pawn.Physics == PHYS_Falling) ) //weave
		{
			pick = 1.0;
			if ( bStrafeDir )
				pick = -1.0;
			sideDir = Normal( Normal(Enemy.Location - Pawn.Location) Cross vect(0,0,1) );
			sideDir.Z = 0;
			Pawn.Velocity += pick * Pawn.GroundSpeed * 0.7 * sideDir;
			if ( FRand() < 0.2 )
				bStrafeDir = !bStrafeDir;
		}
	}

	event bool NotifyBump(actor Other)
	{
		if ( (Other == Enemy)
			&& (Pawn.Weapon != None) && !Pawn.Weapon.bMeleeWeapon && (FRand() > 0.4 + 0.1 * skill) )
		{
			DoRangedAttackOn(Enemy);
			return false;
		}
		return Global.NotifyBump(Other);
	}

	function Timer()
	{
		enable('NotifyBump');
		Target = Enemy;
		TimedFireWeaponAtEnemy();
	}

	function EnemyNotVisible()
	{
		WhatToDoNext(15);
	}

	function EndState()
	{
		if ( (Pawn != None) && Pawn.JumpZ > 0 )
			Pawn.bCanJump = true;
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
	if ( !FindBestPathToward(Enemy, false,true) )
		DoTacticalMove();
Moving:
	if ( Pawn.Weapon.bMeleeWeapon ) // FIXME HACK
		FireWeaponAt(Enemy);
	LastFallbackMoveTime = Level.TimeSeconds;
	MoveToward(MoveTarget,FaceActor(1),,ShouldStrafeTo(MoveTarget));
	if (Level.TimeSeconds - LastFallbackMoveTime < 0.15)
		Sleep(0.15);
	WhatToDoNext(17);
	if ( bSoaking )
		SoakStop("STUCK IN CHARGING!");
}


state Fallback2 extends Fallback
{
	function BeginState()
	{
		Super.BeginState();
		SetBotSprinting(true);
		CurrentMov = None;
		OldMovesCount = 0;
	}
	function bool FireWeaponAt(Actor A)
	{
		return Global.FireWeaponAt(A);
	}
	function EndState()
	{
		Super.EndState();
		SetBotSprinting(false);
	}
Begin:
	WaitForLanding();

Moving:
    LastFallbackMoveTime = Level.TimeSeconds;
    if ( Enemy != None && ( EnemyReallyScary() || ManyEnemiesAround(5, Pawn.Location) ) )
    {
        Timer();
        PickNextRetMove();
        if ( MoveTarget == None )
            MoveTo(Normal(Pawn.Location - Enemy.Location) * 400.f + VRand() * 200.f + Pawn.Location,FaceActor(1));
        else
            MoveToward(MoveTarget,FaceActor(1),GetDesiredOffset(),ShouldStrafeTo(MoveTarget)); 
    }
    else
    {
        if ( Pawn.bCanPickupInventory && (InventorySpot(MoveTarget) != None) )
            MoveTarget = InventorySpot(MoveTarget).GetMoveTargetFor(self,0);
        MoveToward(MoveTarget,FaceActor(1),GetDesiredOffset(),ShouldStrafeTo(MoveTarget));
        Timer(); // keep firing as we advance
    }
    if (Level.TimeSeconds - LastFallbackMoveTime < 0.15)
        Sleep(0.15);
    WhatToDoNext(14);
    if ( bSoaking )
        SoakStop("STUCK IN FALLBACK!");
    goalstring = goalstring$" STUCK IN FALLBACK!";
}

function SetAttractionState()
{
	if ( Enemy != None )
		GotoState('FallBack2');
	else
		GotoState('Roaming');
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
			// Hack, unstuck shotguns and husk gun
			if( !Pawn.Weapon.GetFireMode(0).bFireOnRelease || (Pawn.Weapon.GetFireMode(0).NextFireTime-Level.TimeSeconds)<(-1) )
			{
				// debugf;
				Pawn.Weapon.ServerStopFire(0);
			}
			// else DEBUGF(Pawn.Weapon.GetFireMode(0).bWaitForRelease@Pawn.Weapon.GetFireMode(0).bFireOnRelease@(Pawn.Weapon.GetFireMode(0).NextFireTime-Level.TimeSeconds));
			return false;
		}

		// A rocket only when we can afford what its blast would do to us (see RocketShotSafe).
		if ( !HeldRocketSafe(Target) )
		{
			StopFiring();
			return false;
		}

		if ( !Pawn.IsFiring() )
		{
			if ( (Pawn.Weapon != None && Pawn.Weapon.bMeleeWeapon) || !NeedToTurn(Target.Location) )
			{
				Focus = Target;
				bCanFire = true;
				bStoppedFiring = false;
				if (Pawn.Weapon != None)
					bFireSuccess = Pawn.Weapon.BotFire(bFinishedFire);
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
					bFireSuccess = Pawn.Weapon.BotFire(bFinishedFire);
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
	if( Enemy!=None )
		MoveTo(Normal(Pawn.Location-Enemy.Location)*400.f+VRand()*200.f+Pawn.Location);
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
		// Stay out of our own blast: a frag does up to 400 damage within 420 units and the thrower takes it too
		// (half of it up to Normal difficulty). A fire grenade only burns what is close; a healing one hurts nobody.
		if( D<GetNadeMinDist()+60.f && !bGodMode )
			continue;
		
		Score = 0.f;
		foreach VisibleCollidingActors(class'KFMonster',MM,600.f,M.Location)
		{
			Score += FMin(MM.Health,200.f) * (1.25f - (VSize(MM.Location-M.Location) / 600.f));
		}
		if( Score>450.f && (Best == None || BestScore < Score) && NadeLaneClear(M) && NadePathClear(M) )
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
    local Controller C;
    local int AllyCount;

    Cost = VSize(M.Location-Pawn.Location);
    // Whatever is about to reach us comes first, then what is inside its kite distance.
    if( Cost<180 )
        Cost*=0.3f;
    else if( Cost<KiteDistanceFor(M) )
        Cost*=0.6f;
    Cost*=(1.f/FMax(float(M.ScoringValue)*0.001f,0.7f));
    // A Bloat sprays bile for two seconds when it dies: kill it while it is far away, leave it while it is close.
    if( M.IsA('ZombieBloat') )
    {
        if( VSize(M.Location-Pawn.Location)<BloatSafeDist() )
            Cost*=3.f;
        else
            Cost*=0.6f;
    }
    // Prefer finishing off wounded enemies (was up to 10x: a dying specimen far away beat one in our face)
    Cost *= FClamp(float(M.Health) / M.HealthMax, 0.4, 1.0);
    if( Enemy==M )
        Cost*=0.85f;
    if( !bCheckedSight && !LineOfSightTo(M) )
        Cost*=2.f;
    if( M.Controller!=None && M.Controller.Enemy==Pawn )
        Cost*=0.85f;

	// Avoid dogpiling, count allies already targeting this one
    for( C=Level.ControllerList; C!=None; C=C.nextController )
    {
        if( C!=Self && C.bIsPlayer && C.Pawn!=None && C.Pawn.Health>0 && C.Enemy==M )
        {
            AllyCount++;
            if( AllyCount>=3 )
                break;
        }
    }
    if( AllyCount>0 )
        Cost *= (1.f - FMin(float(AllyCount) * 0.15f, 0.4f)); 

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
	{
		WhatToDoNext(3);
	}
	if ( Enemy == SeenPlayer )
	{
		VisibleEnemy = Enemy;
		EnemyVisibilityTime = Level.TimeSeconds;
		bEnemyIsVisible = true;
		MaybeCalloutEnemy(SeenPlayer);
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

// The stock version reads Pawn.Weapon, and a bot is sometimes between two weapons when it gets here.
function CheckIfShouldCrouch(vector StartPosition, vector TargetPosition, float probability)
{
	if ( Pawn.Weapon == None )
	{
		Pawn.bWantsToCrouch = false;
		return;
	}
	Super.CheckIfShouldCrouch(StartPosition, TargetPosition, probability);
}

function bool NeedWeapon()
{
	local Inventory Inv;

	for ( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		if ( Weapon(Inv) != None && Weapon(Inv).AIRating > 0.5 )
		{
			if ( Weapon(Inv).HasAmmo() )
				return false; // Got a good weapon with ammo
			return true; // Good weapon but dry, need ammo
		}
	}
	return (KFHumanPawn(Pawn) != None && KFHumanPawn(Pawn).CanCarry(0));
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
		if( TargetDoor.bDoorIsDead )
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
	function bool NotifyHitWall(vector HitNormal, actor Wall)
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
WeldDoor:
	WeldAssistTimer = Level.TimeSeconds+12.f;
	Pawn.Acceleration = vect(0,0,0);
	Sleep(10.f);
	WhatToDoNext(44);
}


state TacticalMove
{
ignores SeePlayer, HearNoise;

	function BeginState()
	{
		Super.BeginState();
		SetBotSprinting(true);
	}
	function EndState()
	{
		Super.EndState();
		SetBotSprinting(false);
	}
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
		local vector pickdir, enemydir, enemyPart, Y, LookDir, AwayDir, SideDir;
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

		if ( !HoldingMelee() )
		{
			// Back off from whatever is close: all of it, weighted by how close, not just the current enemy
			AwayDir = GetThreatAwayDir();
			if ( AwayDir != vect(0,0,0) )
			{
				if ( EngageDirection(AwayDir, false) )
					return;
				// straight back is blocked: try the two diagonals before strafing
				SideDir = AwayDir Cross vect(0,0,1);
				if ( bStrafeDir )
					SideDir *= -1;
				if ( EngageDirection(Normal(AwayDir + SideDir), false) )
					return;
				if ( EngageDirection(Normal(AwayDir - SideDir), false) )
					return;
			}
			else if ( VSize(Enemy.Location-Pawn.Location)<600.f && EngageDirection(-enemydir, false) ) // Back off if enemy is close
				return;
		}

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

	function bool EngageDirection(vector StrafeDir, bool bForced)
	{
		local actor HitActor;
		local vector HitLocation, collspec, MinDest, HitNormal;
		local bool bWantJump;

		// successfully engage direction if can trace out and down
		MinDest = Pawn.Location + MINSTRAFEDIST * StrafeDir;
		if ( !bForced )
		{
			collSpec = Pawn.GetCollisionExtent();
			collSpec.Z = FMax(6, Pawn.CollisionHeight - MAXSTEPHEIGHT);

			bWantJump = (Vehicle(Pawn) == None) && (Pawn.Physics != PHYS_Falling) && ((FRand() < 0.05 * Skill + 0.6 * Jumpiness) || (Pawn.Weapon != None && Pawn.Weapon.SplashJump() && ProficientWithWeapon()))
				&& (Enemy.Location.Z - Enemy.CollisionHeight <= Pawn.Location.Z + MAXSTEPHEIGHT - Pawn.CollisionHeight)
				&& !NeedToTurn(Enemy.Location);

			HitActor = Trace(HitLocation, HitNormal, MinDest, Pawn.Location, false, collSpec);
			if ( (HitActor != None) && (!bWantJump || !Pawn.bCanWallDodge) )
				return false;

			if ( Pawn.Physics == PHYS_Walking )
			{
				collSpec.X = FMin(14, 0.5 * Pawn.CollisionRadius);
				collSpec.Y = collSpec.X;
				HitActor = Trace(HitLocation, HitNormal, minDest - (3 * MAXSTEPHEIGHT) * vect(0,0,1), minDest, false, collSpec);
				if ( HitActor == None )
				{
					HitNormal = -1 * StrafeDir;
					return false;
				}
			}

			if ( bWantJump )
			{
				if ( Pawn.Weapon != None && Pawn.Weapon.SplashJump() )
				{
					StopFiring();
					bNotifyApex = true;
					bTacticalDoubleJump = true;
				}

				// try jump move
				bPlannedJump = true;
				DodgeLandZ = Pawn.Location.Z;
				bInDodgeMove = true;
				Pawn.SetPhysics(PHYS_Falling);
				Pawn.Velocity = SuggestFallVelocity(MinDest, Pawn.Location, 1.5*Pawn.JumpZ, Pawn.GroundSpeed);
				Pawn.Velocity.Z = Pawn.JumpZ;
				Pawn.Acceleration = vect(0,0,0);
				if ( Pawn.bCanWallDodge && (Skill + 2*Jumpiness > 3 + 3*FRand()) )
					bNotifyFallingHitWall = true;
				Destination = MinDest;
				return true;
			}
		}
		Destination = MinDest + StrafeDir * (0.5 * MINSTRAFEDIST
											+ FMin(VSize(Enemy.Location - Pawn.Location), MINSTRAFEDIST * (FRand() + FRand())));
		return true;
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
		// Nowhere to step to. With a specimen inside its kite distance, standing here to shoot is what gets a bot
		// killed in a corridor or a corner: fall back to the next path node that leads away, still firing.
		if ( PickPathAwayFromThreats() )
		{
			GoalString = "Cornered: fall back along the path";
			GotoState('FallBackOnPath');
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

	function EndState()
	{
		Super.EndState();
		bTriedRecoverLastDrop = false;
	}
Begin:
	WaitForLanding();
	AssignPersonality(); // Gain new personality on new wave.
	SwitchToBestWeapon();
	BestShopDist = 9999.f; //Need to set this up first
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
        ShopDist = VSize(Pawn.Location - ShoppingPath.Location);
        if (ShopDist < BestShopDist - 64)
        {
            BestShopDist = ShopDist;
            ShoppingAttempts = 0;
        }
        else
        {
            ShoppingAttempts++;
        }
        if (ShoppingAttempts > 10)
        {
            ShoppingAttempts = 0;
            LastShopTime = Level.TimeSeconds + 1.0;
            if ( RouteCache[1] != None )
                Pawn.SetLocation(RouteCache[1].Location);
            WhatToDoNext(151);
        }
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

state RecoverDroppedWeapons extends MoveToGoalNoEnemy
{
	ignores EnemyNotVisible;

    function EndState()
    {
		Super.EndState();
        bTriedRecoverLastDrop = true;
        PickupTarget = None;
    }

Begin:
    WaitForLanding();
	SwitchToBestWeapon();

KeepMoving:
    if (PickupTarget == None || PickupTarget.bHidden || (KFEndlessGameType(Level.Game) == None && KFGameReplicationInfo(Level.Game.GameReplicationInfo).TimeToNextWave < 20))
	{	
		bTriedRecoverLastDrop = true;
        WhatToDoNext(37);
	}
    if (ActorReachable(PickupTarget))
        MoveToward(PickupTarget, MoveTarget,, true);
    else if (FindBestPathToward(PickupTarget, true, false))
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

state Roaming
{
    ignores EnemyNotVisible;

    function BeginState()
    {
        Super.BeginState();
        SetBotSprinting(true);
    }
    event bool NotifyHitWall(vector HitNormal, actor Wall)
    {
        if( KFDoorMover(Wall)!=None && KFDoorMover(Wall).bSealed && !KFDoorMover(Wall).bDisallowWeld )
        {
            UnWeldFromRoom(KFDoorMover(Wall));
			if(FRand() < 0.5)
            	SendChatMsg("That door is sealed! Let me try to open it.");
			return true;
        }
        return Global.NotifyHitWall(HitNormal,Wall);
    }
	function float RateWeapon(Weapon W) // Run faster when following player/bot leader
	{
		if( KFWeapon(W)==None || Enemy != None ) 
			return Global.RateWeapon(W);
		if( !KFWeapon(W).bMeleeWeapon )
			return 0;
		return FMax(KFWeapon(W).Weight, 1.f); 
	}
    function EndState()
    {
        Super.EndState();
        RoamingAttempts = 0;
        RoamGoal = None;
        SetBotSprinting(false);
    }

	final function NavigationPoint FindNavNear(Actor A)
	{
		local NavigationPoint N, BestNav;
		local float D, BestDist;

		for (N = Level.NavigationPointList; N != None; N = N.nextNavigationPoint)
		{
			if (N.bBlocked)
				continue;
			D = VSize(N.Location - A.Location);
			if (BestNav == None || D < BestDist)
			{
				BestNav = N;
				BestDist = D;
			}
		}
		return BestNav;
	}

Begin:
	// Whatever sends us back here, never go round more than a few times without letting a tick pass.
	if ( RoamLoopTime == Level.TimeSeconds )
	{
		if ( ++RoamLoopCount > 4 )
		{
			RoamLoopCount = 0;
			Sleep(0.3);
		}
	}
	else
	{
		RoamLoopTime = Level.TimeSeconds;
		RoamLoopCount = 0;
	}
	SwitchToBestWeapon();
	WaitForLanding();
	if ( RouteGoal != None && Pawn.ReachedDestination(RouteGoal) )
	{
		RouteGoal = None;
		FindRoamDest();
		Sleep(0.5);     
		Goto('DoneRoaming');
	}
	if ( Pawn.bCanPickupInventory && (InventorySpot(MoveTarget) != None) && (Squad.PriorityObjective(self) == 0) && (Vehicle(Pawn) == None) )
	{
		MoveTarget = InventorySpot(MoveTarget).GetMoveTargetFor(self,5);
		if ( (Pickup(MoveTarget) != None) && !Pickup(MoveTarget).ReadyToPickup(0) )
		{
			CampTime = FMax(MoveTarget.LatentFloat, 0.5);
			GoalString = "Short wait for inventory "$MoveTarget;
			GotoState('RestFormation','ShortWait');
		}
	}
	if( RouteGoal != None && actorReachable(RouteGoal) )
	{
		GoalString = "Roaming directly to goal";
		MoveToward(RouteGoal,MoveTarget,,true);
	}
	else if( RouteGoal != None && FindBestPathToward(RouteGoal,true,false) )
	{
		// Count only the legs that bring us no closer: a long trip is not a failed one
		// (every 30th leg used to teleport the bot back to the squad leader).
		if ( RoamGoal != RouteGoal || VSize(Pawn.Location - RouteGoal.Location) < BestRoamDist - 64.f )
		{
			RoamGoal = RouteGoal;
			BestRoamDist = VSize(Pawn.Location - RouteGoal.Location);
			RoamingAttempts = 0;
		}
		else
			RoamingAttempts++;
        if(RoamingAttempts >= 30)
        {
			RoamingAttempts = 0;
			if (InventorySpot(RouteGoal) != None)
			{
				//Abandon unreachable inventory and try to find another one or roam
				RouteGoal = None;
				WhatToDoNext(157);
			}
			else if ( Squad.SquadLeader != None && Squad.SquadLeader.Pawn != None )
			{
				if (Pawn.SetLocation(FindNavNear(Squad.SquadLeader.Pawn).Location))
				{
					log(self$" Roaming failed, teleporting near squad leader");
				}
				else if (RouteCache[1] != None)
					Pawn.SetLocation(RouteCache[1].Location);
			}
            WhatToDoNext(157);
        }
		GoalString = "Roaming to goal via path";
		MoveToward(MoveTarget,MoveTarget,,false);
	}
	else
	{
		RouteGoal = None;
		RoamingAttempts++;
		if (RoamingAttempts >= 20)
		{
			RoamingAttempts = 0;
			if ( Squad.SquadLeader != None && Squad.SquadLeader.Pawn != None )
			{
				if (Pawn.SetLocation(FindNavNear(Squad.SquadLeader.Pawn).Location))
					log(self$" Roaming failed (no path), teleporting near squad leader");
			}
			WhatToDoNext(157);
		}
		FindRoamDest();
		Sleep(0.5 + FRand());
	}
DoneRoaming:
	WaitForLanding();
	WhatToDoNext(12);
	if ( bSoaking )
		SoakStop("STUCK IN ROAMING!");
}

final function KFNadeHealingExplosion FindNearbyHealCloud()
{
    local KFNadeHealingExplosion Cloud, Best;
    local float Dist, BestDist;

    if (Pawn == None || Pawn.Health >= 90)
        return None;

    foreach DynamicActors(class'KFNadeHealingExplosion', Cloud)
    {
        if (Cloud == None || Cloud.HealTime <= 0)
            continue;

        Dist = VSize(Cloud.Location - Pawn.Location);
        if (Dist > 800.f)
            continue;

        // Closer is better
        if (Best == None || Dist < BestDist)
        {
            Best = Cloud;
            BestDist = Dist;
        }
    }

    if (Best != None && ManyEnemiesAround(6, Best.Location))
        return None;

    return Best;
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

function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
	Super.DisplayDebug(Canvas,YL, YPos);

	Canvas.DrawText("Perk: "@GetPerkName());
	YPos += YL;
	Canvas.SetPos(4,YPos);
}

defaultproperties
{
	ReviveSearchDist=2500.000000
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
