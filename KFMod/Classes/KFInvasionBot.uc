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
var Pawn CalledOut;			// the big specimen this bot last called out
var float NextHoldChat, LastHoldChat;
var float LastFallbackMoveTime;
var NavigationPoint CurrentMov,OldMoves[4],PreviousNavPath;
var array<NavigationPoint> TempBlockedPaths;

// Zombie zones (volumes that stop human pawns but not specimens, as KFZombieZoneVolume): the paths are built through
// them, so the links that cross one, each with its zone, are shut for our own path searches and reach checks
// (ShutZoneLinks to OpenZoneLinks).
var array<ReachSpec> ZoneLinkPath, ShutLinks;
var array<BlockingVolume> ZoneLinkZone;
var bool bZoneLinksFound;
var int ZoneShutDepth;

// Holding a place through a wave as players do (KFHoldPlan): a post in the held area and where to look from it
var() bool bHoldSpots;
var() float HoldReach;		// at the post when this close
var() float HoldQuietTime;	// with nothing met for this long and specimens about, go and find them
var() float HoldEarlyTime;	// trader time: at the spot with this many seconds left
var() float HoldGlanceShare;	// at the post: share of looks down another way in
var() bool bPostNades;			// at the post: the grenade decision of any other fight (TryNade)
var() float HoldNoWayRest;	// no path to the post: this long doing other things before trying it again
var float HoldOffUntil;
var NavigationPoint HoldNoWayNode;	// the post we last found no way to
var() bool bHumanOrdersFirst;	// a player's order beats the team's hold (Hold: his spot; Freelance, Attack: none)
var name HumanOrders;			// the last order a player gave this bot

// Grenades, as players spend them
var() bool bFragFP;				// a frag for a Fleshpound (FPToFrag), one at a time a Fleshpound, some kept for them in their waves
var() int FragReserve;			// in a Fleshpound wave, frags kept for Fleshpounds (not thrown at other bunches)
var KFMonster FragTarget;		// the Fleshpound our last frag was meant for, and when we went to throw it
var float FragTime;

// Weapons, as players use them
var() bool bTacticalReload;		// a part-empty gun reloaded in a lull of the fight, not at the last round (TacticalReload)
var() bool bAmmoRun;			// low on ammo in a wave: a box from the map near by (AmmoRunAssignment, state AmmoRun)
var() bool bBuyOffListAmmo;		// at the trader, ammo too for the guns it does not sell, the 9mm above all (BuyOffListAmmo)
var() bool bNoStrayBlades;		// only a Berserker buys a blade (GetShoppingWishes): for anyone else it is weight and cash spent on nothing
var() bool bRocketBig;			// the LAW kept for Fleshpounds and Scrakes and used on them: rated for them, aimed over cover by the head, not held back by a Siren screaming away from its way, and kept out a moment for a clear line rather than swapped away and back (LAW.GetAIRating, RocketSelfDamage, RocketWait)
var KFAmmoPickup AmmoRunTarget;
var float NextAmmoRunTime, AmmoRunBestDist;
var int AmmoRunStalls;

// Retreats
var() bool bRetreatToTeam;		// from a big one after us, back towards the nearest team-mate's guns, not just away (PickNextRetMove)
var() bool bSirenAware;			// backing off, not down a Siren's scream: in front of her, in her sight, within its reach (PickNextRetMove)
var() bool bScrakeFocus;		// a Scrake close by is the target, faced: he charges whoever turns away from him (GetEnemyDesire)

// Pits
var() bool bPitAware;			// no dodge jump over, and no step off a ledge into, a drop that would badly hurt or kill (PitBelow)
var bool bPitBlockedFall;		// jumping was switched off for this tick, to stop a step off a ledge into a pit

// Team-mates to players
var() bool bAnswerCalls;		// a player's voice calls answered: Medic, Cover, Form up (HeardCall)
var() bool bHumanFirst;			// a hurt player healed before a hurt bot (FindInjuredAlly)
var Pawn MedicCallFor, CoverFor;	// who called for a medic, for cover; and until when we answer
var float MedicCallUntil, CoverUntil;
var NavigationPoint HoldNode, HoldFace;

// Berserkers fighting the way players play them
var() bool bZerkBile;		// bile is not run from unless hurt (the perk takes 80% less of it)
var() bool bZerkRhythm;		// a step back as each blow lands, out of the reply, and in again
var() bool bZerkGun;		// a Berserker shoots what hurts from afar (Sirens, the Patriarch) with his gun, as players carry one for them
var float LastStepBackSwing;
var vector ZerkBackSpot;

// Internal to state
var NavigationPoint ShoppingPath;
var KFDoorMover TargetDoor;

var Syringe MySyringe;
var Welder ActiveWelder;
var Frag MyGrenades;
var Actor ShopVolumeActor;
var Pickup PickupTarget;
var float NextRecoverTime, RecoverBestDist;
var int RecoverStalls;

// Swapping a gun we carry for a better one on the floor (FindPickupSwap, state SwapForPickup).
var KFWeaponPickup SwapPickup, LastSwapPickup, SwapBlocked;
var array<KFWeapon> SwapDrops;
var array< class<Inventory> > SwapThrownClasses;
var float NextSwapCheckTime, SwapGuardTime, SwapBlockedTime, SwapBestDist;
var int SwapStalls;
var() float SwapSearchDist, SwapDropDist, SwapMinGain;

// Perk choice (PerkFit, MaybeSwitchPerk).
var float NextPerkSwitchTime;
var bool bPerkCheckPending;
var() bool bPerkSwitching;
var() float PerkStay, PerkMedicNeed, PerkCrowd, PerkSwitchGap;
var() bool bLateZerkSwap;		// a Berserker takes another perk for the waves with Fleshpounds in them

// Trader: steps walked into the shop, the wave whose personality we have.
var int ShopSteps, PersonalityWave;

// Crowd sense (AloneInFight to EscapeFocus, state EscapeCrowd): the specimens known of, the path search's nodes with
// the node before, the length and search cost of the way there and the least time to spare on it.
struct CrowdThreat
{
	var KFMonster M;
	var vector Loc;
	var float Speed, Reach, Pad;
};
var array<CrowdThreat> CrowdList;
var array<NavigationPoint> EscNode;
var array<int> EscPrev;
var array<float> EscLen, EscCost, EscMargin;
var array<byte> EscDone;
var NavigationPoint EscapeGoal;
var KFMonster EscapeBlocker;
var float EscapeUntil, NextEscapePlanTime, PlannedLegMargin, NextEscapeTime, EscapeGoalMargin;
var int EscapeLegs;
var bool bEscapeFlee;
var() bool bCrowdEscape, bBenchDebug;	// bBenchDebug: log escape legs and shop trips (for the test bench)
var() float CrowdSenseDist, CrowdRadius, CrowdAllyDist, CrowdEnterPressure, PincerRadius, PincerNear;
var() float EscapeSearchDist, EscapeDangerCost, EscapeDeadEnd, EscapeAllyPull, EscapeFrontBonus, EscapeMaxTime, EscapeCooldown;
var() float EscapeSpawnPenalty, EscapeSpawnDist, EscapeSpawnRecent, EscapeMinMargin;
var array<ZombieVolume> SpawnAreas;
var bool bSpawnAreasFound;
var() int EscapeMaxNodes;

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

// A Field Medic's healing grenade where specimens crowd the team, as players use it (bMedicCrowdHeal: CrowdHealTarget,
// MedicHealNade): MedicHealCrowd or more specimens within MedicHealReach of a team-mate, or of himself, within MedicHealDist.
var() bool bMedicCrowdHeal;
var() int MedicHealCrowd;
var() float MedicHealReach, MedicHealDist;
var KFHumanPawn HealNadeTarget;		// for state NadeTarget: the team-mate (or ourselves) chosen by MedicHealNade
var float NextHealNadeTime;			// no other one while the last one's cloud lasts

// Where our own grenade is about to go off, and until when to stay away from it.
var vector NadeDangerSpot;
var float NadeDangerTime;
var Nade MyLiveNade;
// When a rocket shot was last held back as unsafe, and when one was last clear.
var float RocketUnsafeTime, RocketSafeTime;
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

// Off the path network (no anchor found): since when and where. After AnchorLostLimit seconds there, unseen, it is
// put back on its last anchor (TeleportBackIn).
var() bool bLedgeJump;			// walked into a ledge under a low opening (a window sill): hop into the opening (LedgeJump)
var float NextLedgeJump;
var float AnchorLostTime;
var vector AnchorLostSpot;
var() float AnchorLostLimit;

// Standing still in WaitingForLanding since (CheckLandedIdle).
var float LandedIdleSince;

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

	// Picked a gun it had just thrown away for a better one straight back up: leave that swap alone for a while.
	if ( NewItem != None && Level.TimeSeconds < SwapGuardTime )
		for ( i=0; i<SwapThrownClasses.Length; i++ )
			if ( NewItem.Class == SwapThrownClasses[i] )
			{
				SwapBlocked = LastSwapPickup;
				SwapBlockedTime = Level.TimeSeconds + 30.f;
				SwapGuardTime = 0;
				break;
			}
	// A new gun may suit another perk: look at the next decision (its weight is not counted yet here).
	if ( KFWeapon(NewItem) != None && Pawn != None && Level.TimeSeconds - Pawn.SpawnTime > 2.f )
		bPerkCheckPending = true;

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
	local Actor InWay;

	if ( A == None )
		A = Enemy;
	// the shots land on a specimen standing in the way: make that one the target
	InWay = SpecimenInLine(A);
	if ( InWay != A )
	{
		if ( A == Enemy )
			Enemy = Pawn(InWay);
		A = InWay;
	}
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
		if ( PlayerReplicationInfo.Team != None )
			PlayerReplicationInfo.Team.Score -= Amount;	// as a player's toss does: picking it up adds it back
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
	// (bAnswerCalls) the player who called for a medic, through a fight if need be
	if( MedicCallFor != None && Level.TimeSeconds < MedicCallUntil && KFHumanPawn(MedicCallFor) != None && MedicCallFor.Health > 0
		&& MedicCallFor.Health + KFHumanPawn(MedicCallFor).HealthToGive < MedicCallFor.HealthMax && MySyringe != None
		&& MySyringe.ChargeBar() >= 0.6f && (FindNearestThreat(AllyDist, BestDist) == None || BestDist >= 200.f) )
	{
		InjuredAlly = KFHumanPawn(MedicCallFor);
		return true;
	}
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
		if( bHumanFirst && PlayerController(aKFHPawn.Controller) != None )
			AllyDist*=0.4f;
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
			// (every specimen spawns a little faster than its class default, for the difficulty, so this takes any Fleshpound
			// after us within 1000, raging or not; tested against a true rage check, the early retreat did as well or better)
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

// What hurts from afar: a Siren with her head on, the Patriarch, the specimens that shoot (a Berserker shoots these
// with his gun while nothing is on top of him)
final function bool RangedThreat( KFMonster M )
{
	if ( M == None || M.Health <= 0 )
		return false;
	if ( M.IsA('ZombieSiren') )
		return !M.bDecapitated;
	return M.IsA('ZombieBoss') || M.IsA('ZombieFleshPoundRange') || M.IsA('ZombieSoldier');
}

// A gun (not a blade, tool or grenade) with a round in it or in reserve
final function bool HasLoadedGun()
{
	local Inventory Inv;
	local KFWeapon W;

	for ( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		W = KFWeapon(Inv);
		if ( W != None && !W.bMeleeWeapon && Welder(W) == None && Syringe(W) == None && Frag(W) == None && W.HasAmmo() )
			return true;
	}
	return false;
}

// A Fleshpound or a Scrake within 1000 whose enemy we are
final function bool BigOneAfterUs()
{
	local Controller C;

	for ( C=Level.ControllerList; C!=None; C=C.nextController )
		if ( C.Enemy == Pawn && C.Pawn != None && C.Pawn.Health > 0 && (C.Pawn.IsA('ZombieFleshPound') || C.Pawn.IsA('ZombieScrake'))
			&& VSize(C.Pawn.Location - Pawn.Location) < 1000.f )
			return true;
	return false;
}

// A Berserker's blow has just landed on what is in front of him: a step back out of its reply (players time their
// hits this way), to ZerkBackSpot
final function bool ZerkStepBackNow()
{
	local KFMeleeFire F;
	local vector Back;

	if ( !bZerkRhythm || Enemy == None || Pawn == None || Pawn.Physics != PHYS_Walking || Pawn.Weapon == None
		|| !Pawn.Weapon.bMeleeWeapon || GetPerkName() != "Berserker" )
		return false;
	F = KFMeleeFire(Pawn.Weapon.GetFireMode(0));
	if ( F == None || F.SwingTo <= LastStepBackSwing || Level.TimeSeconds < F.SwingTo || Level.TimeSeconds > F.SwingTo + 0.3 )
		return false;
	LastStepBackSwing = F.SwingTo;
	if ( VSize(Enemy.Location - Pawn.Location) > Enemy.CollisionRadius + Pawn.CollisionRadius + 110.f )
		return false;
	Back = Pawn.Location + 90.f * Normal((Pawn.Location - Enemy.Location) * vect(1,1,0));
	// clear behind us, with floor under the spot
	if ( !FastTrace(Back, Pawn.Location) || FastTrace(Back - vect(0,0,80), Back) )
		return false;
	ZerkBackSpot = Back;
	return true;
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

// The nearest live specimen standing in the line of fire to Tgt, short of it (where our shots would land); else Tgt.
final function Actor SpecimenInLine( Actor Tgt )
{
	local Controller C;
	local vector Dir, Off;
	local float Along, BestAlong;
	local Actor Best;

	if ( Pawn(Tgt) == None || Pawn == None )
		return Tgt;
	Dir = Tgt.Location - Pawn.Location;
	BestAlong = VSize(Dir);
	Dir = Normal(Dir);
	Best = Tgt;
	for ( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		if ( KFMonster(C.Pawn) == None || C.Pawn == Tgt || C.Pawn.Health <= 0 )
			continue;
		Off = C.Pawn.Location - Pawn.Location;
		Along = Off dot Dir;
		if ( Along > 0.f && Along < BestAlong && VSize(Off - Along * Dir) < C.Pawn.CollisionRadius + 10.f )
		{
			Best = C.Pawn;
			BestAlong = Along;
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

// ---- Crowd sense ----------------------------------------------------------------------------------------------------
// A bot on its own (no team-mate close by and in sight) that specimens are pressing on, or closing on from more than one
// side, looks for a way out over the path network instead of stepping back from them. Every way within
// EscapeSearchDist is rated by the time it has to spare against each specimen it knows of (the time that one needs to
// get within reach of each node at its pace, less the time the bot needs to get there), by whether it leaves room to go
// on (not a dead end) and, with team-mates left elsewhere, by whether it leads towards them. The bot runs the first leg
// of the best way, shooting the specimen that most threatens it, and plans again.

// No team-mate (player or bot, alive and not downed) within CrowdAllyDist and in sight: the bot is on its own.
final function bool AloneInFight()
{
	local Controller C;

	for ( C=Level.ControllerList; C!=None; C=C.nextController )
		if ( C != self && C.bIsPlayer && KFHumanPawn(C.Pawn) != None && C.Pawn.Health > 0
			&& (KFHumanPawnZombies(C.Pawn) == None || !KFHumanPawnZombies(C.Pawn).bIsDowned)
			&& VSize(C.Pawn.Location - Pawn.Location) < CrowdAllyDist && FastTrace(C.Pawn.Location, Pawn.Location) )
			return false;
	return true;
}

// Where the nearest team-mate elsewhere is (alive, not downed). False if there is none.
final function bool NearestAllyLoc( out vector Loc )
{
	local Controller C;
	local float D, BestD;
	local bool bFound;

	for ( C=Level.ControllerList; C!=None; C=C.nextController )
		if ( C != self && C.bIsPlayer && KFHumanPawn(C.Pawn) != None && C.Pawn.Health > 0
			&& (KFHumanPawnZombies(C.Pawn) == None || !KFHumanPawnZombies(C.Pawn).bIsDowned) )
		{
			D = VSize(C.Pawn.Location - Pawn.Location);
			if ( !bFound || D < BestD )
			{
				Loc = C.Pawn.Location;
				BestD = D;
				bFound = true;
			}
		}
	return bFound;
}

// The specimens the bot knows of: in sight within CrowdSenseDist, or close enough to hear (600), on about its floor.
final function SenseCrowd()
{
	local Controller C;
	local KFMonster M;
	local float D;
	local int n;

	CrowdList.Length = 0;
	for ( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		M = KFMonster(C.Pawn);
		if ( M == None || M.Health <= 0 || Abs(M.Location.Z - Pawn.Location.Z) > 300.f )
			continue;
		D = VSize(M.Location - Pawn.Location);
		if ( D > CrowdSenseDist || (D > 600.f && !LineOfSightTo(M)) )
			continue;
		n = CrowdList.Length;
		CrowdList.Length = n + 1;
		CrowdList[n].M = M;
		CrowdList[n].Loc = M.Location;
		CrowdList[n].Speed = FMax(FMax(M.GroundSpeed, VSize(M.Velocity)), 100.f);
		CrowdList[n].Reach = ThreatReach(M);
		CrowdList[n].Pad = ThreatPad(M);
	}
}

// How close a specimen has to be to hurt: its melee reach, more for those that hurt from further off.
final function float ThreatReach( KFMonster M )
{
	local float R;

	R = M.MeleeRange * 1.4 + M.CollisionRadius + Pawn.CollisionRadius;
	if ( M.IsA('ZombieBloat') )
		R = FMax(R, 280.f);
	else if ( M.IsA('ZombieSiren') )
		R = FMax(R, 450.f);
	else if ( M.IsA('ZombieBoss') )
		R = FMax(R, 500.f);
	return R;
}

// Seconds of room wanted from a specimen over and above its reach: more from the ones that kill quickly.
final function float ThreatPad( KFMonster M )
{
	if ( M.IsA('ZombieFleshPound') || M.IsA('ZombieScrake') || M.IsA('ZombieBoss') )
		return 0.6;
	if ( M.IsA('ZombieGorefast') || M.IsA('ZombieCrawler') )
		return 0.25;
	return 0.f;
}

// How hard the crowd presses: 1 for each specimen within 400, half for one further out within CrowdRadius, twice that
// for the big ones. Nearest: the distance to the nearest specimen.
final function float CrowdPressure( out float Nearest )
{
	local int i;
	local float D, W, P;

	Nearest = 100000.f;
	for ( i=0; i<CrowdList.Length; i++ )
	{
		D = VSize(CrowdList[i].Loc - Pawn.Location);
		Nearest = FMin(Nearest, D);
		if ( D < 400.f )
			W = 1.f;
		else if ( D < CrowdRadius )
			W = 0.5f;
		else
			continue;
		if ( CrowdList[i].Pad >= 0.6 )
			W *= 2.f;
		P += W;
	}
	return P;
}

// How the specimens within Radius of a spot spread round it: the widest gap between their bearings (65536 a full
// turn); a full turn when there are fewer than two. N: how many there are.
final function int CrowdGap( vector From, float Radius, out int N )
{
	local array<int> B;
	local int i, j, Y, MaxGap;
	local vector Dir;

	N = 0;
	for ( i=0; i<CrowdList.Length; i++ )
	{
		Dir = CrowdList[i].Loc - From;
		Dir.Z = 0;
		if ( VSize(Dir) > Radius )
			continue;
		Y = rotator(Dir).Yaw & 65535;
		j = 0;
		while ( j < B.Length && B[j] < Y )
			j++;
		B.Insert(j, 1);
		B[j] = Y;
		N++;
	}
	if ( N < 2 )
		return 65536;
	MaxGap = B[0] + 65536 - B[N-1];
	for ( i=1; i<N; i++ )
		MaxGap = Max(MaxGap, B[i] - B[i-1]);
	return MaxGap;
}

// A pincer: specimens within PincerRadius on more than one side of us (no gap of 200 degrees between them), the
// nearest of them within PincerNear.
final function bool InPincer( float Nearest )
{
	local int N;

	return ( Nearest < PincerNear && CrowdGap(Pawn.Location, PincerRadius, N) < 36409 && N >= 2 );
}

// Time to get out: on our own (and bCrowdEscape), caught in a pincer or with the crowd pressing hard
// (CrowdEnterPressure). Specimens all on one side are left to the usual backing off while shooting. Not again for
// EscapeCooldown after an escape. A Berserker with a blade stands unless pressed hard or hurt.
final function bool ShouldEscapeCrowd()
{
	local float P, Nearest;

	if ( !bCrowdEscape || Pawn == None || Pawn.Physics != PHYS_Walking || Level.TimeSeconds < NextEscapeTime
		|| !AloneInFight() )
		return false;
	SenseCrowd();
	P = CrowdPressure(Nearest);
	if ( HoldingMelee() && GetPerkName() == "Berserker" && P < CrowdEnterPressure && Pawn.Health > 50 )
		return false;
	return ( P >= CrowdEnterPressure || InPincer(Nearest) );
}

// Whether there is a way out worth taking: one that gets past every specimen with EscapeMinMargin to spare. Where
// there is none (a crowd in a corridor), running only takes the bot past them: it stays and fights. Not asked again for
// half a second.
final function bool EscapeOpen()
{
	if ( PlanEscape() && EscapeGoalMargin >= EscapeMinMargin )
		return true;
	NextEscapeTime = Level.TimeSeconds + 0.5;
	return false;
}

// Whether to keep going: still on our own, and still in a pincer, pressed hard, or about to be hit; when running from
// what is too much for us (bEscapeFlee), anything within 700.
final function bool EscapeStillNeeded()
{
	local float P, Nearest;

	if ( !AloneInFight() )
		return false;
	SenseCrowd();
	P = CrowdPressure(Nearest);
	if ( bEscapeFlee )
		return ( Nearest < 700.f );
	return ( Nearest < 200.f || P >= CrowdEnterPressure || InPincer(Nearest) );
}

// The least time to spare at a spot for a bot that gets there in T seconds: for each specimen, the time it needs to
// get within reach of the spot at its pace, less T and the room wanted from it.
final function float NodeMargin( vector Loc, float T )
{
	local int i;
	local float Mg, Least;

	Least = 10.f;
	for ( i=0; i<CrowdList.Length; i++ )
	{
		Mg = FMax(VSize(CrowdList[i].Loc - Loc) - CrowdList[i].Reach, 0.f) / CrowdList[i].Speed - T - CrowdList[i].Pad;
		if ( Mg < Least )
			Least = Mg;
	}
	return Least;
}

// The specimen that has the least time to spare against us at a spot, if we can see it (the one to shoot).
final function KFMonster MostThreatening( vector Loc, float T )
{
	local int i, Best;
	local float Mg, Least;

	Best = -1;
	for ( i=0; i<CrowdList.Length; i++ )
	{
		Mg = FMax(VSize(CrowdList[i].Loc - Loc) - CrowdList[i].Reach, 0.f) / CrowdList[i].Speed - T - CrowdList[i].Pad;
		if ( Best < 0 || Mg < Least )
		{
			Best = i;
			Least = Mg;
		}
	}
	if ( Best >= 0 && CrowdList[Best].M != None && LineOfSightTo(CrowdList[Best].M) )
		return CrowdList[Best].M;
	return None;
}

// A path a human-sized bot can run along: no flying, swimming, ladders, special moves, forced jumps or doors welded shut.
final function bool UsableEscapeSpec( ReachSpec Spec )
{
	local NavigationPoint E;
	local int i;

	if ( Spec == None )
		return false;
	E = Spec.End;
	if ( E == None || E.bBlocked || LiftCenter(E) != None || (Teleporter(E) != None && Teleporter(E).URL != "")
		|| Spec.bForced || (Spec.reachFlags & (2|4|32|64|128)) != 0
		|| Spec.CollisionRadius < Pawn.CollisionRadius || Spec.CollisionHeight < Pawn.CollisionHeight )
		return false;
	for ( i=0; i<DoorPaths.Length; i++ )
		if ( DoorPaths[i].Path == Spec && DoorPaths[i].Door != None && DoorPaths[i].Door.bSealed && !DoorPaths[i].Door.bDoorIsDead )
			return false;
	return true;
}

// How much a place lies where specimens have just been coming in: a spawn area within EscapeSpawnDist that produced one
// in the last EscapeSpawnRecent seconds (1 just now, less as it gets older). Players soon learn where they pour in from.
final function float SpawnNearness( vector Loc )
{
	local ZombieVolume Z;
	local int i;
	local float Age, Most;

	if ( !bSpawnAreasFound )
	{
		bSpawnAreasFound = true;
		foreach AllActors(class'ZombieVolume', Z)
			SpawnAreas[SpawnAreas.Length] = Z;
	}
	for ( i=0; i<SpawnAreas.Length; i++ )
	{
		Z = SpawnAreas[i];
		if ( Z == None || Z.LastSpawnedTime <= 0 )
			continue;
		Age = Level.TimeSeconds - Z.LastSpawnedTime;
		if ( Age > EscapeSpawnRecent || VSize(Z.Location - Loc) > EscapeSpawnDist )
			continue;
		Most = FMax(Most, 1.f - Age / EscapeSpawnRecent);
	}
	return Most;
}

// How many ways lead on from a node: 1 is a dead end (only the way back).
final function int EscapeExits( NavigationPoint N )
{
	local int k, Links;

	for ( k=0; k<N.PathList.Length; k++ )
		if ( UsableEscapeSpec(N.PathList[k]) )
			Links++;
	return Links;
}

final function int EscIndex( NavigationPoint N )
{
	local int i;

	for ( i=0; i<EscNode.Length; i++ )
		if ( EscNode[i] == N )
			return i;
	return -1;
}

// Adds a node the search starts from (or a better way to it): its path length, search cost and least margin.
final function AddEscapeNode( NavigationPoint N, int Prev, float Len, float Cost, float Mg )
{
	local int j;

	j = EscIndex(N);
	if ( j < 0 )
	{
		if ( EscNode.Length >= EscapeMaxNodes )
			return;
		j = EscNode.Length;
		EscNode.Length = j + 1;
		EscPrev.Length = j + 1;
		EscLen.Length = j + 1;
		EscCost.Length = j + 1;
		EscMargin.Length = j + 1;
		EscDone.Length = j + 1;
		EscNode[j] = N;
		EscDone[j] = 0;
	}
	else if ( EscDone[j] != 0 || Cost >= EscCost[j] )
		return;
	EscPrev[j] = Prev;
	EscLen[j] = Len;
	EscCost[j] = Cost;
	EscMargin[j] = Mg;
}

// The nodes the way out starts from: in each of eight directions the nearest path node 100 to 700 away on about our
// floor that we can walk straight to (not the one we stand on: running to it gets us nowhere).
final function AddEscapeSources( float BotSpeed )
{
	local NavigationPoint N, Cand[8];
	local float D, CandD[8], Mg, NM;
	local vector Dir;
	local int s;

	for ( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
	{
		Dir = N.Location - Pawn.Location;
		if ( Abs(Dir.Z) > 120.f || N.bBlocked || LiftCenter(N) != None )
			continue;
		D = VSize(Dir);
		if ( D > 700.f || D < 100.f )
			continue;
		Dir.Z = 0;
		s = ((rotator(Dir).Yaw & 65535) + 4096) / 8192;
		if ( s > 7 )
			s = 0;
		if ( Cand[s] == None || D < CandD[s] )
		{
			Cand[s] = N;
			CandD[s] = D;
		}
	}
	for ( s=0; s<8; s++ )
		if ( Cand[s] != None && ActorReachable(Cand[s]) )
		{
			D = CandD[s];
			NM = NodeMargin(Cand[s].Location, D / BotSpeed);
			Mg = FMin(NM, NodeMargin(0.5 * (Cand[s].Location + Pawn.Location), 0.5 * D / BotSpeed));
			AddEscapeNode(Cand[s], -1, D, D + EscapeDangerCost * FMax(0.f, 1.5f - Mg), Mg);
		}
}

// The way out (see the note above). Sets MoveTarget to the node to run to now, EscapeGoal to where the way leads and
// EscapeBlocker to the specimen that comes closest to cutting the first leg. False if there is no path node to use.
// Not through zombie zones: no link through one is usable, and no node beyond one counts as in reach.
final function bool PlanEscape()
{
	local bool bFound;

	ShutZoneLinks();
	bFound = PlanEscapeRoute();
	OpenZoneLinks();
	return bFound;
}

final function bool PlanEscapeRoute()
{
	local NavigationPoint N, E;
	local ReachSpec Spec;
	local int i, k, Cur, Best, First, Second, Links, Near;
	local float Len, Cost, NM, Mg, BotSpeed, Score, BestScore;
	local vector Ally;
	local bool bAlly;

	if ( Pawn == None )
		return false;
	SenseCrowd();
	BotSpeed = Pawn.GroundSpeed;
	if ( KFHumanPawn(Pawn) != None && !KFHumanPawn(Pawn).bIsSprinting )
		BotSpeed *= KFHumanPawn(Pawn).SprintMulti;
	BotSpeed = FMax(BotSpeed, 150.f);
	bAlly = NearestAllyLoc(Ally);

	EscNode.Length = 0;
	EscPrev.Length = 0;
	EscLen.Length = 0;
	EscCost.Length = 0;
	EscMargin.Length = 0;
	EscDone.Length = 0;
	AddEscapeSources(BotSpeed);
	if ( EscNode.Length == 0 )
		return false;

	// the cheapest way to each node within reach: a way costs its length and more for running close to specimens
	while ( true )
	{
		Cur = -1;
		for ( i=0; i<EscNode.Length; i++ )
			if ( EscDone[i] == 0 && (Cur < 0 || EscCost[i] < EscCost[Cur]) )
				Cur = i;
		if ( Cur < 0 )
			break;
		EscDone[Cur] = 1;
		if ( EscMargin[Cur] < -2.5f || EscLen[Cur] > EscapeSearchDist )
			continue;	// cut off for good, or far enough: not gone on from
		N = EscNode[Cur];
		for ( k=0; k<N.PathList.Length; k++ )
		{
			Spec = N.PathList[k];
			if ( !UsableEscapeSpec(Spec) )
				continue;
			E = Spec.End;
			Len = EscLen[Cur] + Spec.Distance;
			NM = FMin(NodeMargin(E.Location, Len / BotSpeed), NodeMargin(0.5 * (E.Location + N.Location), (Len - 0.5 * Spec.Distance) / BotSpeed));
			Mg = FMin(EscMargin[Cur], NM);
			Cost = EscCost[Cur] + Spec.Distance + EscapeDangerCost * FMax(0.f, 1.5f - NM);
			AddEscapeNode(E, Cur, Len, Cost, Mg);
		}
	}

	// the best place to make for: time to spare on the way there first, then a way on from it, then team-mates
	Best = -1;
	for ( i=0; i<EscNode.Length; i++ )
	{
		if ( EscLen[i] < 250.f )
			continue;
		Score = FClamp(EscMargin[i], -3.f, 3.f) + 0.25 * FMin(EscLen[i], 1500.f) / 1500.f;
		Links = EscapeExits(EscNode[i]);
		if ( Links <= 1 )
			Score -= EscapeDeadEnd;
		else if ( Links >= 3 )
			Score += 0.15;
		// from there they are all on one side (spread over 160 degrees at most): a place to stand and fight from
		if ( EscMargin[i] > -0.5 && CrowdGap(EscNode[i].Location, 1000.f, Near) >= 36409 )
			Score += EscapeFrontBonus;
		// not towards where they have just been coming in
		if ( EscapeSpawnPenalty > 0 )
			Score -= EscapeSpawnPenalty * SpawnNearness(EscNode[i].Location);
		if ( bAlly )
			Score += EscapeAllyPull * (1.f - FMin(VSize(Ally - EscNode[i].Location) / 3000.f, 1.f));
		if ( Best < 0 || Score > BestScore )
		{
			Best = i;
			BestScore = Score;
		}
	}
	if ( Best < 0 )
	{
		// nowhere far enough: the start node with the most room
		for ( i=0; i<EscNode.Length; i++ )
			if ( EscPrev[i] < 0 && (Best < 0 || EscMargin[i] > EscMargin[Best]) )
				Best = i;
		if ( Best < 0 )
			return false;
	}
	EscapeGoal = EscNode[Best];
	EscapeGoalMargin = EscMargin[Best];
	// the first leg: the node the way starts from, or the one after it when we are all but there
	First = Best;
	Second = -1;
	while ( EscPrev[First] >= 0 )
	{
		Second = First;
		First = EscPrev[First];
	}
	if ( Second >= 0 && VSize(EscNode[First].Location - Pawn.Location) < 120.f && ActorReachable(EscNode[Second]) )
		First = Second;
	MoveTarget = EscNode[First];
	PlannedLegMargin = EscMargin[First];
	EscapeBlocker = MostThreatening(MoveTarget.Location, VSize(MoveTarget.Location - Pawn.Location) / BotSpeed);
	return true;
}

// The leg we are on is about to be cut: a specimen will now get within reach of its end well before we do, more than
// was planned.
final function bool LegCutOff()
{
	local int i;
	local float T, Mg;

	if ( MoveTarget == None )
		return false;
	T = VSize(MoveTarget.Location - Pawn.Location) / FMax(Pawn.GroundSpeed, 150.f);
	for ( i=0; i<CrowdList.Length; i++ )
	{
		if ( CrowdList[i].M == None || CrowdList[i].M.Health <= 0 )
			continue;
		Mg = FMax(VSize(CrowdList[i].M.Location - MoveTarget.Location) - CrowdList[i].Reach, 0.f) / CrowdList[i].Speed - T - CrowdList[i].Pad;
		if ( Mg < 0.3 && Mg < PlannedLegMargin - 0.6 )
			return true;
	}
	return false;
}

// What to look at while running: the enemy while we can see it (we back off firing), else the way.
final function Actor EscapeFocus()
{
	if ( Enemy != None && Enemy.Health > 0 && VSize(Enemy.Location - Pawn.Location) < 1500.f && LineOfSightTo(Enemy) )
		return Enemy;
	return MoveTarget;
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
		if ( Cand[i] != None && CanReach(Cand[i]) )
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

// (bRocketBig) The launcher W out already for a big one that was in a clear shot moments ago, with nothing on us (him
// included: inside his kite distance he is inside the blast too): only something passing (a body across the line, a
// scream, a step behind cover) stops the shot, so it stays out, held, rather than swapped away and back.
final function bool RocketWait(Weapon W)
{
	local float D, M;

	if ( !bRocketBig || W == None || W != Pawn.Weapon || RocketClassOf(W) == None || !IsBigSpecimen(Enemy)
		|| Level.TimeSeconds - RocketSafeTime > 3.f )
		return false;
	return ( FindNearestThreat(D, M) == None || M > 0.f );
}

// What a rocket is for: a Fleshpound or a Scrake with his head on.
final function bool IsBigSpecimen(Pawn P)
{
	return ( KFMonster(P) != None && P.Health > 0 && !KFMonster(P).bDecapitated
		&& (P.IsA('ZombieFleshPound') || P.IsA('ZombieScrake')) );
}

// A rocket launcher we carry with a rocket in it.
final function Weapon LoadedRocket()
{
	local Inventory Inv;

	for ( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
		if ( Weapon(Inv) != None && RocketClassOf(Weapon(Inv)) != None && Weapon(Inv).HasAmmo() )
			return Weapon(Inv);
	return None;
}

// Where to put a rocket on Tgt from Start: its body, else (bRocketBig) its head over whatever hides the body.
final function vector RocketAimSpot(Actor Tgt, vector Start)
{
	local vector Head;

	if ( !bRocketBig || Pawn(Tgt) == None || FastTrace(Tgt.Location, Start) )
		return Tgt.Location;
	Head = GetHeadAimLocation(Tgt);
	if ( FastTrace(Head, Start) )
		return Head;
	return Tgt.Location;
}

// Would Siren S's scream (ZombieSiren.HurtRadius: 700 round her, ahead of her by a dot of 0.45) catch a rocket over the
// first Len units of its way from Start along Dir? Only there can it set the rocket off close enough to hurt us.
final function bool ScreamCatches(Pawn S, vector Start, vector Dir, float Len)
{
	local vector X, Look;
	local int i;

	Look = vector(S.Rotation);
	Look.Z = 0;
	Look = Normal(Look);
	for ( i=0; i<=4; i++ )
	{
		X = Start + Dir * (Len * i / 4.f) - S.Location;
		if ( VSize(X) > 730.f )
			continue;
		X.Z = 0;
		if ( (Normal(X) dot Look) >= 0.45f )
			return true;
	}
	return false;
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
	End = RocketAimSpot(Tgt, Start);
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
		// a Siren that is screaming sets it off in the air (bRocketBig: if her scream reaches its way while it is close to us)
		if ( P.IsA('ZombieSiren') && Monster(P).bShotAnim && VSize(Off) < 1150.f
			&& (!bRocketBig || ScreamCatches(P, Start, Dir, FMin(Dist, Radius + Pawn.CollisionRadius))) )
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
	// and the perk's cut of it (a Support Specialist takes 40% less from his own rockets)
	if ( bRocketBig && KFPlayerReplicationInfo(PlayerReplicationInfo) != None && KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != None )
		Dmg = KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.ReduceDamage(KFPawn(Pawn), Pawn, int(Dmg), PC.default.MyDamageType);
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
	if ( PC == None )
		return true;
	if ( RocketShotSafe(Tgt, PC) )
	{
		RocketSafeTime = Level.TimeSeconds;
		return true;
	}
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
	local KFGameType G;

	G = KFGameType(Level.Game);
	if ( G == None || !G.bWaveInProgress || G.TotalMaxMonsters > 0 || G.NumMonsters > 8
		|| NextHuntCheckTime > Level.TimeSeconds || Level.TimeSeconds - LastEnemyEncounter < 10.f
		|| (Squad != None && PlayerController(Squad.SquadLeader) != None) )
		return false;
	return HuntNearestSpecimen();
}

// Off along the paths to the nearest specimen on our floor
final function bool HuntNearestSpecimen()
{
	local Controller C;
	local KFMonster M, Best;
	local float D, BestD;

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
	// (bPitAware) jumping back on after the tick it was off for (TacticalMove keeps it off)
	if ( bPitBlockedFall )
	{
		bPitBlockedFall = false;
		if ( Pawn != None && !IsInState('TacticalMove') )
			Pawn.bCanJump = Pawn.JumpZ > 0;
	}
	// zombie zone links are only ever shut within one call: left shut, the specimens could not use them either
	if ( ZoneShutDepth > 0 )
	{
		warn(GetHumanReadableName()$" left zombie zone links shut");
		ZoneShutDepth = 1;
		OpenZoneLinks();
	}
	if ( NextWedgeCheckTime < Level.TimeSeconds )
	{
		CheckWedged();
		CheckOwnNade();
		CheckBile();
		CheckSurprise();
		CheckLift();
		CheckLandedIdle();
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
	ShutZoneLinks();
	bFound = Super.FindInventoryGoal(BestWeight);
	OpenZoneLinks();
	SetLiftsBlocked(false);
	return bFound;
}

// WaitingForLanding ends the tick after landing. A bot standing still in it for over a second has lost its state code
// (seen twice after a teleport onto a node, cause not found): decide again.
final function CheckLandedIdle()
{
	if ( Pawn == None || Pawn.Physics == PHYS_Falling || VSize(Pawn.Velocity) > 50.f || !IsInState('WaitingForLanding') )
	{
		LandedIdleSince = 0;
		return;
	}
	if ( LandedIdleSince == 0 )
		LandedIdleSince = Level.TimeSeconds;
	else if ( Level.TimeSeconds - LandedIdleSince > 1.f )
	{
		LandedIdleSince = 0;
		WhatToDoNext(172);
	}
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
	// (a Berserker takes a fifth of it: not worth leaving a fight for unless hurt)
	if ( InBile() && !(bZerkBile && GetPerkName() == "Berserker" && Pawn.Health > 40) )
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
	if ( bPerkCheckPending )
	{
		bPerkCheckPending = false;
		MaybeSwitchPerk();
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
	if ( Pawn.FindAnchorFailedTime == Level.TimeSeconds && AnchorLostTooLong() ) // Maps are buggy, unstick ourselves
		TeleportBackIn();
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

	if ( Enemy == None && ShouldRecoverDroppedWeapon() )
	{
		GoalString = "RECOVER_DROP";
		GotoState('RecoverDroppedWeapons');
		return;
	}
	if( Enemy==none && ((ShouldGoShopping() && GoShopping()) || ShouldBegForCash()) )
		Return;
	if( LastHealTime<Level.TimeSeconds && FindInjuredAlly() && (!EnemyReallyScary() && StartleActor==None) && GoHealing() )
		return;
	else
	{
		// A better gun on the floor close by that we cannot carry as we are: swap one for it while nothing is close.
		if ( (Threat == None || ThreatMargin > 150.f) && FindPickupSwap() )
		{
			GoalString = "Swap "$SwapText();
			GotoState('SwapForPickup');
			return;
		}
		if ( AmmoRunAssignment(Threat, ThreatMargin) )
			return;
		if ( CoverAssignment() )
			return;
		if ( Enemy == None && HuntRemainingSpecimens() )
			return;
		if ( HoldAssignment() )
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

// The best trade within SwapSearchDist (and about our floor) of guns we carry for a gun on the floor that we cannot
// carry as we are: the guns to leave are the fewest and least worth that make room (PlanSwapDrops), and the new gun
// must be worth more than all of them together (TradeWorth, PickupWorth) by SwapMinGain. Three empty guns are worth
// next to nothing, so a Commando out of ammo takes a LAW; a loaded Bullpup and Deagle outweigh one. Sets SwapPickup
// and SwapDrops. Looked for every two seconds at most.
final function bool FindPickupSwap()
{
	local KFHumanPawn P;
	local KFWeaponPickup Pk;
	local array<KFWeapon> Drops;
	local class<KFWeapon> WC;
	local float Gain, BestGain;
	local int i;

	if ( Level.TimeSeconds < NextSwapCheckTime )
		return false;
	NextSwapCheckTime = Level.TimeSeconds + 2.f;
	P = KFHumanPawn(Pawn);
	if ( P == None )
		return false;
	SwapPickup = None;
	SwapDrops.Length = 0;
	foreach Pawn.CollidingActors(class'KFWeaponPickup', Pk, SwapSearchDist)
	{
		WC = class<KFWeapon>(Pk.InventoryType);
		if ( WC == None || Pk.bHidden || !Pk.ReadyToPickup(0) || (Pk == SwapBlocked && Level.TimeSeconds < SwapBlockedTime)
			|| Abs(Pk.Location.Z - Pawn.Location.Z) > 150.f || P.CanCarry(WC.default.Weight) || Pawn.FindInventoryType(WC) != None
			|| !PlanSwapDrops(WC.default.Weight, Drops) )
			continue;
		Gain = PickupWorth(Pk);
		for ( i=0; i<Drops.Length; i++ )
			Gain -= TradeWorth(Drops[i]);
		if ( Gain > SwapMinGain && (SwapPickup == None || Gain > BestGain) )
		{
			SwapPickup = Pk;
			SwapDrops = Drops;
			BestGain = Gain;
		}
	}
	if ( SwapPickup == None || (!CanReach(SwapPickup) && !FindBestPathToward(SwapPickup, true, false)) )
	{
		SwapPickup = None;
		SwapDrops.Length = 0;
		return false;
	}
	return true;
}

// The guns to leave behind to make room for one of this weight: the least worth first, as few as it takes (one taken
// early is put back if a heavier one made it unneeded). False if even all of them would not make room. The 9mm, knife,
// syringe, welder and grenades are never left, so the bot is never left unarmed.
final function bool PlanSwapDrops( float Weight, out array<KFWeapon> Drops )
{
	local Inventory Inv;
	local KFWeapon W;
	local array<KFWeapon> Cand;
	local KFHumanPawn P;
	local float Load;
	local int i, j;

	Drops.Length = 0;
	P = KFHumanPawn(Pawn);
	for ( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		W = KFWeapon(Inv);
		if ( W == None || W.bKFNeverThrow || !W.bCanThrow )
			continue;
		j = 0;
		while ( j < Cand.Length && TradeWorth(Cand[j]) <= TradeWorth(W) )
			j++;
		Cand.Insert(j, 1);
		Cand[j] = W;
	}
	Load = P.CurrentWeight;
	for ( i=0; i<Cand.Length && Load + Weight > P.MaxCarryWeight; i++ )
	{
		Drops[Drops.Length] = Cand[i];
		Load -= Cand[i].Weight;
	}
	if ( Load + Weight > P.MaxCarryWeight )
	{
		Drops.Length = 0;
		return false;
	}
	for ( i=Drops.Length-1; i>=0; i-- )
		if ( Load + Drops[i].Weight + Weight <= P.MaxCarryWeight )
		{
			Load += Drops[i].Weight;
			Drops.Remove(i, 1);
		}
	return ( Drops.Length > 0 );
}

// What a gun on the floor would be worth to this bot (as TradeWorth for one it carries): next to nothing if it was
// dropped empty.
final function float PickupWorth( KFWeaponPickup Pk )
{
	local class<KFWeapon> WC;
	local float R;

	WC = class<KFWeapon>(Pk.InventoryType);
	R = WC.default.AIRating;
	if ( WeaponIsForPerk(Pk.Class) )
		R *= 1.5;
	if ( Pk.bDropped && Pk.AmmoAmount[0] <= 0 && !WC.default.bMeleeWeapon )
		R *= 0.1;
	return R;
}

// The guns a swap leaves behind are all still ours.
final function bool SwapDropsHeld()
{
	local int i;

	if ( SwapDrops.Length == 0 )
		return false;
	for ( i=0; i<SwapDrops.Length; i++ )
		if ( SwapDrops[i] == None || SwapDrops[i].bDeleteMe || SwapDrops[i].Owner != Pawn )
			return false;
	return true;
}

// What a swap is for, for GoalString: "Bullpup, Deagle for LAW".
final function string SwapText()
{
	local string S;
	local int i;

	for ( i=0; i<SwapDrops.Length; i++ )
	{
		if ( i > 0 )
			S = S $ ", ";
		if ( SwapDrops[i] != None )
			S = S $ SwapDrops[i].ItemName;
	}
	if ( SwapPickup != None )
		S = S $ " for " $ SwapPickup.ItemName;
	return S;
}

// Throws the SwapDrops back the way we came, spread a little, away from SwapPickup, without taking them out first (as
// CheckCarryWeight drops guns). The thrown guns are no longer this bot's own, so it does not come back for them
// between waves.
final function bool DropForSwap()
{
	local vector Away, Side, Dir, StartLoc;
	local sound OldAmbient;
	local bool bHeld;
	local KFWeaponPickup Pk;
	local class<Inventory> DropClass;
	local KFWeapon W;
	local int i;

	if ( SwapPickup == None || !SwapDropsHeld() )
		return false;
	Away = Pawn.Location - SwapPickup.Location;
	Away.Z = 0;
	Away = Normal(Away);
	Side = Away cross vect(0,0,1);
	if ( FRand() < 0.5 )
		Side *= -1;
	OldAmbient = Pawn.AmbientSound;
	SwapThrownClasses.Length = 0;
	for ( i=0; i<SwapDrops.Length; i++ )
	{
		W = SwapDrops[i];
		if ( W == None || !W.bCanThrow )
			continue;
		if ( Pawn.Weapon == W )
			bHeld = true;
		Dir = Normal(Away + (0.5 - 0.6 * i) * Side);
		DropClass = W.Class;
		StartLoc = Pawn.Location + Dir * Pawn.CollisionRadius * 0.8;
		W.Velocity = Pawn.Velocity + Dir * 300.f + vect(0,0,180);
		W.DropFrom(StartLoc);
		foreach Pawn.CollidingActors(class'KFWeaponPickup', Pk, 150.f, StartLoc)
			if ( Pk.Owner == Self && Pk.InventoryType == DropClass )
				Pk.SetOwner(None);
		SwapThrownClasses[SwapThrownClasses.Length] = DropClass;
	}
	// dropping a gun that is not in hand must not silence the one that is (DropFrom clears the pawn's sound)
	if ( !bHeld )
		Pawn.AmbientSound = OldAmbient;
	SwapGuardTime = Level.TimeSeconds + 5.f;
	LastSwapPickup = SwapPickup;
	if ( bHeld || Pawn.Weapon == None )
		SwitchToBestWeapon();
	return true;
}

// ---- Perk choice ----------------------------------------------------------------------------------------------------
// Players may change perk whenever they like (KFPlayerController.SelectVeterancy); a bot does too when it makes sense:
// when the guns it carries suit another perk clearly better, or the team has no medic. Looked at on each trader visit
// and after a gun is picked up, at most once in PerkSwitchGap seconds. Never to a perk with less carry weight than the
// bot carries (the game would make it drop guns).

// How well a perk suits the bot as it is: the rating of each gun it carries that is that perk's (next to nothing if out
// of ammo; the 9mm and knife everyone has do not count), PerkMedicNeed for a medic when the team has none,
// PerkStay for keeping the perk it has, less PerkCrowd for each team-mate on it.
final function float PerkFit( class<KFVeterancyTypes> V )
{
	local Inventory Inv;
	local KFWeapon W;
	local class<KFWeaponPickup> PC;
	local float Fit;

	for ( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		W = KFWeapon(Inv);
		if ( W == None || W.bKFNeverThrow || W.default.AIRating <= 0 )
			continue;
		PC = class<KFWeaponPickup>(W.PickupClass);
		if ( PC == None || PC.default.CorrespondingVeterancyName != V.default.VeterancyName )
			continue;
		if ( !W.bMeleeWeapon && !W.HasAmmo() )
			Fit += 0.1 * W.default.AIRating;
		else
			Fit += W.default.AIRating;
	}
	if ( V.default.VeterancyName == "Field Medic" && TeamOnPerk(V) == 0 )
		Fit += PerkMedicNeed;
	if ( V == KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill )
		Fit += PerkStay;
	if ( bLateZerkSwap && V.default.VeterancyName == "Berserker" && FleshpoundWave() )
		Fit -= 2.0;
	// a team does better with a spread of perks: a little less for each team-mate who has it already
	return Fit - PerkCrowd * TeamOnPerk(V);
}

// The wave on (or next, in trader time) has Fleshpounds in its squads, or is the last.
final function bool FleshpoundWave()
{
	local KFGameType G;
	local int i, j, Bit;

	G = KFGameType(Level.Game);
	if ( G == None )
		return false;
	if ( G.WaveNum >= G.FinalWave || G.WaveNum >= ArrayCount(G.Waves) )
		return true;
	Bit = 1;
	for ( i=0; i<G.InitSquads.Length; i++ )
	{
		if ( (Bit & G.Waves[G.WaveNum].WaveMask) != 0 )
			for ( j=0; j<G.InitSquads[i].MSquad.Length; j++ )
				if ( G.InitSquads[i].MSquad[j] != None && InStr(Caps(string(G.InitSquads[i].MSquad[j].Name)), "FLESHPOUND") >= 0 )
					return true;
		Bit *= 2;
	}
	return false;
}

// How many other living team-mates (players or bots) have this perk.
final function int TeamOnPerk( class<KFVeterancyTypes> V )
{
	local Controller C;
	local KFPlayerReplicationInfo PRI;
	local int N;

	for ( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		PRI = KFPlayerReplicationInfo(C.PlayerReplicationInfo);
		if ( C != self && C.bIsPlayer && PRI != None && PRI.ClientVeteranSkill == V && C.Pawn != None && C.Pawn.Health > 0 )
			N++;
	}
	return N;
}

// Takes the perk that fits best (PerkFit) if it is not the one it has. True if it changed.
final function bool MaybeSwitchPerk()
{
	local KFGameType G;
	local KFPlayerReplicationInfo PRI;
	local KFHumanPawn P;
	local class<KFVeterancyTypes> V, Best;
	local float Fit, BestFit;
	local int i;

	G = KFGameType(Level.Game);
	PRI = KFPlayerReplicationInfo(PlayerReplicationInfo);
	P = KFHumanPawn(Pawn);
	if ( !bPerkSwitching || G == None || !G.bPerksEnabled || PRI == None || P == None || P.Health <= 0
		|| Level.TimeSeconds < NextPerkSwitchTime )
		return false;
	for ( i=0; i<G.LoadedSkills.Length; i++ )
	{
		V = G.LoadedSkills[i];
		if ( V == None || P.default.MaxCarryWeight + V.static.AddCarryMaxWeight() < P.CurrentWeight )
			continue;
		Fit = PerkFit(V);
		if ( Best == None || Fit > BestFit )
		{
			Best = V;
			BestFit = Fit;
		}
	}
	if ( Best == None || Best == PRI.ClientVeteranSkill )
		return false;
	PRI.ClientVeteranSkill = Best;
	P.CheckCarryWeight();
	NextPerkSwitchTime = Level.TimeSeconds + PerkSwitchGap;
	SendChatMsg("Switching to "$Best.default.VeterancyName$".");
	log(PlayerReplicationInfo.PlayerName$" switched perk to "$Best.default.VeterancyName);
	return true;
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
	local Single S;

	if( W==None || W.bKFNeverThrow )
		return false;
	PlayerReplicationInfo.Score+=GetWeaponWorth(W);
	log(PlayerReplicationInfo.PlayerName$" Sold weapon: " $ W.GetHumanReadableName() $ " for " $ GetWeaponWorth(W));
	// as a player's sale does (KFPawn.ServerSellWeapon): Dualies give the one 9mm back
	if ( Dualies(W) != None && Pawn.FindInventoryType(class'Single') == None )
	{
		S = Spawn(class'Single');
		if ( S != None )
			S.GiveTo(Pawn);
	}
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
	ShutZoneLinks();
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
	OpenZoneLinks();
	for( i=0; i<DoorPaths.Length; ++i )
		DoorPaths[i].Path.CollisionRadius += 10000;

	return Result;
}

function bool FindBestPathToward(Actor A, bool bCheckedReach, bool bAllowDetour)
{
	local int i;

	if ( !bCheckedReach && CanReach(A) )
	{
		MoveTarget = A;
		return true;
	}

	// Setup special path finding.
	ShutZoneLinks();
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
	OpenZoneLinks();
	for( i=0; i<DoorPaths.Length; ++i )
		DoorPaths[i].Path.CollisionRadius += 10000;

	return (MoveTarget!=None);
}

function bool FindBestPathTo( vector Dest )
{
	local int i;

	// Setup special path finding.
	ShutZoneLinks();
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
	OpenZoneLinks();
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
					else if ( BackInSpot() == None )
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

// Where a bot stuck off the path network goes back to: its last anchor, else a player start.
final function NavigationPoint BackInSpot()
{
	local NavigationPoint N, TeleNav;

	if(Pawn.LastAnchor != None)
		return Pawn.LastAnchor;
	for (N = Level.NavigationPointList; N != None; N = N.nextNavigationPoint)
	{
		if(PlayerStart(N)!= None)
			TeleNav = N;
	}
	return TeleNav;
}

// Puts a bot stuck off the path network back on BackInSpot. False if a player would see it go or arrive (try again
// later), or there is nowhere to put it.
function bool TeleportBackIn()
{
	local NavigationPoint TeleNav;

	TeleNav = BackInSpot();
	if ( !TeleportUnseen(TeleNav) )
		return false;
	log(PlayerReplicationInfo.PlayerName$" was stuck off the paths, put back on "$TeleNav);
	GoalString = "Teleported to location: "$TeleNav$" after being stuck.";
	NumRandomJumps = 0;
	return true;
}

// Moves the bot to Spot when no player can see it leave or arrive.
final function bool TeleportUnseen( NavigationPoint Spot )
{
	if ( Spot == None || HumanCanSee(Pawn.Location) || HumanCanSee(Spot.Location) || !Pawn.SetLocation(Spot.Location) )
		return false;
	Pawn.FindAnchorFailedTime = 0;	// let this decision's path searches find the new anchor
	AnchorLostTime = Level.TimeSeconds;
	AnchorLostSpot = Pawn.Location;
	return true;
}

// The path search found no anchor: true once that has gone on for AnchorLostLimit seconds without the bot getting
// anywhere (it starts over after a valid anchor or a move of 200).
final function bool AnchorLostTooLong()
{
	if ( AnchorLostTime <= Pawn.LastValidAnchorTime || VSize(Pawn.Location - AnchorLostSpot) > 200.f )
	{
		AnchorLostTime = Level.TimeSeconds;
		AnchorLostSpot = Pawn.Location;
	}
	return ( Level.TimeSeconds - AnchorLostTime >= AnchorLostLimit );
}

// Armour at the price a player pays (KFPawn.ServerBuyKevlar): scaled by difficulty for anyone with a perk.
final function BuyKevlar()
{
	local float Cost, Scale;
	local int UnitsAffordable;

	if ( Pawn.ShieldStrength>=100 )
		Return;

	Scale = 1.f;
	if ( KFPlayerReplicationInfo(PlayerReplicationInfo) != None && KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != None )
		Scale = class'KFPawn'.static.GetCostScaling(Level.Game.GameDifficulty);
	Cost = class'Vest'.default.ItemCost * ((100.0 - Pawn.ShieldStrength) / 100.0) * Scale;

	if ( PlayerReplicationInfo.Score >= Cost )
	{
		PlayerReplicationInfo.Score -= Cost;
		Pawn.ShieldStrength = 100;
	}
	else if ( Pawn.ShieldStrength>0 )
	{
		Cost = class'Vest'.default.ItemCost * Scale / 100.0;
		UnitsAffordable = int(PlayerReplicationInfo.Score / Cost);
		PlayerReplicationInfo.Score -= int(Cost * UnitsAffordable);
		Pawn.ShieldStrength += UnitsAffordable;
	}
}

// One visit to the trader. Ammo for the perk guns first, then up to three guns in order of wish, then the other guns'
// ammo, then armour. A bot whose perk has guns of its own and who cannot get the one it wants most yet saves for it:
// no off-perk guns, and armour only when it is down to half.
function DoTrading()
{
	local array<class<KFWeaponPickup> > Wish;
	local class<KFWeaponPickup> Saving;
	local int i, Bought;
	local bool bAny;

	if( KFHumanPawn(Pawn)==None )
		return;
	ShoppingAttempts = 0;
	if (KFEndlessGameType(Level.Game) != None)
		LastShopTime = Level.TimeSeconds + 120 + 120*FRand();
	else LastShopTime = Level.TimeSeconds + 60 + 60*FRand();

	MaybeSwitchPerk();	// before buying, as a player picks his perk at the trader
	BuyAmmoFor(true);
	for ( Bought=0; Bought<3; Bought++ )
	{
		GetShoppingWishes(Wish);
		bAny = false;
		for ( i=0; i<Wish.Length && !bAny; i++ )
		{
			if ( Saving != None && !WeaponIsForPerk(Wish[i]) )
				continue;
			if ( BuyWeapon(Wish[i]) )
				bAny = true;
			else if ( Saving == None && PerkPicky() && WeaponIsForPerk(Wish[i]) && FitsAfterSales(Wish[i]) )
				Saving = Wish[i];
		}
		if ( !bAny )
			break;
	}
	BuyAmmoFor(false);
	PlayerReplicationInfo.Score = FMax(PlayerReplicationInfo.Score,0);
	if( PlayerReplicationInfo.Score>0 && (Saving == None || Pawn.ShieldStrength < 50) )
		BuyKevlar();
	// (bBuyOffListAmmo) the 9mm last, with what is left (bought before the guns it cost guns and armour at Elite), and
	// not from savings for a perk gun unless no gun has a round
	if ( bBuyOffListAmmo && PlayerReplicationInfo.Score > 0 && (Saving == None || !HasLoadedGun()) )
		BuyOffListAmmo();
	SwitchToBestWeapon();
	LastShopCash = PlayerReplicationInfo.Score;
	log(PlayerReplicationInfo.PlayerName$" Finished Trading. Cash left: "$int(PlayerReplicationInfo.Score)$" armour "$int(Pawn.ShieldStrength)$" saving for "$Saving$" in shop "$InShop());
}

// What a gun costs: what a player pays (KFPawn.ServerBuyWeapon), the list price scaled by difficulty.
final function int WeaponPrice( class<KFWeaponPickup> PC )
{
	return int(float(PC.default.Cost) * class'KFPawn'.static.GetCostScaling(Level.Game.GameDifficulty));
}

// The perks that have guns of their own. For the others (and with no perk) every gun counts as a perk gun.
final function bool PerkPicky()
{
	local string P;

	P = GetPerkName();
	return ( P != "" && P != "Field Medic" && P != "Sergeant" );
}

// What a gun the bot carries is worth to it in a trade: its rating, half again for a perk gun, next to nothing when
// it is out of ammo.
final function float TradeWorth( KFWeapon W )
{
	local float R;

	R = W.default.AIRating;
	if ( class<KFWeaponPickup>(W.PickupClass) != None && WeaponIsForPerk(class<KFWeaponPickup>(W.PickupClass)) )
		R *= 1.5;
	if ( !W.bMeleeWeapon && !W.HasAmmo() )
		R *= 0.1;
	return R;
}

// The guns on sale here that the bot does not have, the one it wants most first: perk guns far ahead, then by how
// much a bot wants such a gun, with some chance in it so that bots do not all buy alike.
final function GetShoppingWishes( out array<class<KFWeaponPickup> > Wish )
{
	local array<class<Pickup> > L;
	local array<float> Des;
	local class<KFWeaponPickup> PC;
	local float D;
	local int i, j;

	Wish.Length = 0;
	L = GetLegalPurchases();
	for ( i=0; i<L.Length; i++ )
	{
		PC = class<KFWeaponPickup>(L[i]);
		if ( PC == None || class<KFWeapon>(PC.default.InventoryType) == None || Pawn.FindInventoryType(PC.default.InventoryType) != None )
			continue;
		// (bNoStrayBlades) a blade only for a Berserker
		if ( bNoStrayBlades && class<KFWeapon>(PC.default.InventoryType).default.bMeleeWeapon && GetPerkName() != "Berserker" )
			continue;
		D = PC.default.MaxDesireability * (1.f + FRand() * 0.5f);
		if ( WeaponIsForPerk(PC) )
			D *= 4.f;
		j = 0;
		while ( j < Des.Length && Des[j] >= D )
			j++;
		Wish.Insert(j, 1);
		Des.Insert(j, 1);
		Wish[j] = PC;
		Des[j] = D;
	}
}

// Buys a gun the way a player does (KFPawn.PurchaseWeapon) and fills its ammo. For a perk gun it cannot afford or carry
// it first sells off-perk guns, but only when the sales cover both its price and its weight (see PlanSales).
final function bool BuyWeapon( class<KFWeaponPickup> PC )
{
	local class<KFWeapon> WC;
	local array<KFWeapon> Plan;
	local KFWeapon W;
	local int Price, i;

	WC = class<KFWeapon>(PC.default.InventoryType);
	if ( WC == None || KFHumanPawn(Pawn) == None )
		return false;
	Price = WeaponPrice(PC);
	if ( Price > PlayerReplicationInfo.Score || !KFHumanPawn(Pawn).CanCarry(WC.default.Weight) )
	{
		if ( !WeaponIsForPerk(PC) || !PlanSales(Price, WC.default.Weight, Plan) )
			return false;
		for ( i=0; i<Plan.Length; i++ )
			SellWeapon(Plan[i]);
	}
	if ( !KFHumanPawn(Pawn).PurchaseWeapon(WC, Price) )
		return false;
	W = KFWeapon(Pawn.FindInventoryType(WC));
	if ( W != None )
	{
		FillAllAmmo(W.GetAmmoClass(0),1.f);
		if ( W.GetAmmoClass(1) != None && W.GetAmmoClass(1) != W.GetAmmoClass(0) )
			FillAllAmmo(W.GetAmmoClass(1),1.f);
	}
	log(PlayerReplicationInfo.PlayerName@"of perk"@GetPerkName()@"Bought weapon: "$PC$" for "$Price$" cash left "$int(PlayerReplicationInfo.Score));
	return true;
}

// Off-perk guns to sell for a perk gun of this price and weight: the least useful first, as many as it takes and no
// more. False, with nothing planned, if even all of them would not cover it. Perk guns are never on the list.
final function bool PlanSales( int Price, float Weight, out array<KFWeapon> Plan )
{
	local Inventory Inv;
	local KFWeapon W;
	local array<KFWeapon> Cand;
	local KFHumanPawn P;
	local float Cash, Load;
	local int i, j;

	Plan.Length = 0;
	P = KFHumanPawn(Pawn);
	if ( P == None )
		return false;
	for ( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		W = KFWeapon(Inv);
		if ( W == None || W.bKFNeverThrow || class<KFWeaponPickup>(W.PickupClass) == None
			|| WeaponIsForPerk(class<KFWeaponPickup>(W.PickupClass)) )
			continue;
		j = 0;
		while ( j < Cand.Length && TradeWorth(Cand[j]) <= TradeWorth(W) )
			j++;
		Cand.Insert(j, 1);
		Cand[j] = W;
	}
	Cash = PlayerReplicationInfo.Score;
	Load = P.CurrentWeight;
	for ( i=0; i<Cand.Length && (Cash < Price || Load + Weight > P.MaxCarryWeight); i++ )
	{
		Plan[Plan.Length] = Cand[i];
		Cash += GetWeaponWorth(Cand[i]);
		Load -= Cand[i].Weight;
	}
	if ( Cash < Price || Load + Weight > P.MaxCarryWeight )
	{
		Plan.Length = 0;
		return false;
	}
	// a gun taken early may not be needed once a bigger one is on the list
	for ( i=Plan.Length-1; i>=0; i-- )
		if ( Cash - GetWeaponWorth(Plan[i]) >= Price && Load + Plan[i].Weight + Weight <= P.MaxCarryWeight )
		{
			Cash -= GetWeaponWorth(Plan[i]);
			Load += Plan[i].Weight;
			Plan.Remove(i, 1);
		}
	return true;
}

// Whether this gun would fit if every off-perk gun were sold (what saving up for it needs).
final function bool FitsAfterSales( class<KFWeaponPickup> PC )
{
	local Inventory Inv;
	local KFWeapon W;
	local KFHumanPawn P;
	local float Load;

	P = KFHumanPawn(Pawn);
	if ( P == None || class<KFWeapon>(PC.default.InventoryType) == None )
		return false;
	Load = P.CurrentWeight;
	for ( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		W = KFWeapon(Inv);
		if ( W != None && !W.bKFNeverThrow && class<KFWeaponPickup>(W.PickupClass) != None
			&& !WeaponIsForPerk(class<KFWeaponPickup>(W.PickupClass)) )
			Load -= W.Weight;
	}
	return ( Load + class<KFWeapon>(PC.default.InventoryType).default.Weight <= P.MaxCarryWeight );
}

// (bBuyOffListAmmo) Ammo for the guns we carry that the trader does not sell, the 9mm above all: a player buys it from the
// trader's ammo list, but the bots only ever filled guns on sale, so a bot whose main gun was a LAW was left with an empty
// pistol and the knife whenever specimens came close.
final function BuyOffListAmmo()
{
	local array<class<Pickup> > L;
	local Inventory Inv;
	local KFWeapon W;
	local int i;
	local bool bOnSale;

	L = GetLegalPurchases();
	for ( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		W = KFWeapon(Inv);
		if ( W == None || W.bMeleeWeapon || W == MyGrenades || Syringe(W) != None || Welder(W) != None
			|| class<KFWeaponPickup>(W.PickupClass) == None || W.GetAmmoClass(0) == None )
			continue;
		bOnSale = false;
		for ( i=0; i<L.Length && !bOnSale; i++ )
			if ( L[i] == W.PickupClass )
				bOnSale = true;
		if ( !bOnSale )
			FillAllAmmo(W.GetAmmoClass(0), 1.f);
	}
}

// Fills the ammo of the guns on sale here that the bot carries: its perk guns, or the others.
final function BuyAmmoFor( bool bPerkGuns )
{
	local array<class<Pickup> > L;
	local class<KFWeaponPickup> PC;
	local KFWeapon W;
	local int i;

	L = GetLegalPurchases();
	for ( i=0; i<L.Length; i++ )
	{
		PC = class<KFWeaponPickup>(L[i]);
		if ( PC == None || WeaponIsForPerk(PC) != bPerkGuns )
			continue;
		W = FindWeaponInInv(PC);
		if ( W == None )
			continue;
		FillAllAmmo(W.GetAmmoClass(0),1.f);
		// secondary ammo (e.g. explosive shells) if the weapon has a distinct secondary ammo type
		if ( W.GetAmmoClass(1) != None && W.GetAmmoClass(1) != W.GetAmmoClass(0) )
			FillAllAmmo(W.GetAmmoClass(1),1.f);
	}
}

function bool GoShopping()
{
	if( !GetNearestShop() )
		Return false;
	GoalString = "SHOPPING";
	GotoState('Shopping');
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
	if( Sp.MyTrader!=None )
		ShopVolumeActor = Sp.MyTrader;
	else ShopVolumeActor = Sp;
	// Where to walk to: a path node inside the shop, else the one nearest the trader with a clear line to him (the
	// last steps in are walked straight, see Shopping). Only then the spots players are put out to when it closes.
	ShoppingPath = Sp.EntryPoint();
	if ( bBenchDebug )
		log("SHOP"@PlayerReplicationInfo.PlayerName@Sp@"trader="$ShopVolumeActor@"entry="$ShoppingPath@"inside="$(ShoppingPath != None && Sp.Encompasses(ShoppingPath))
			@"d="$int(VSize(Sp.Location - Pawn.Location))@"shops="$KFGT.ShopList.Length);
	if( ShoppingPath!=None )
		return true;
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
	return true;
}

// Inside the shop, where a player can buy.
final function bool InShop()
{
	return ( KFPawn(Pawn) != None && KFPawn(Pawn).CanBuyNow() );
}

// Whether a living player could see this spot (from his eyes, whichever way he faces), or is watching this bot.
final function bool HumanCanSee( vector Spot )
{
	local Controller C;

	for ( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		if ( PlayerController(C) == None )
			continue;
		if ( PlayerController(C).ViewTarget == Pawn && Pawn != None )
			return true;
		if ( C.Pawn != None && C.Pawn.Health > 0 && FastTrace(Spot, C.Pawn.Location + C.Pawn.EyeHeight * vect(0,0,1)) )
			return true;
	}
	return false;
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

// The nearest of this bot's own guns on the floor (dropped at death, or put down for being too heavy) that it still
// wants and has room for. A gun it threw away for a better one is no longer its own (see DropForSwap).
function Pickup FindBestDroppedPickupNear()
{
	local KFWeaponPickup Pk, Best;
	local float D, BestD;

	foreach DynamicActors(class'KFWeaponPickup', Pk)
	{
		if ( Pk.Owner != Self || Pk.bHidden || Pk.bDeleteMe || Pk.BotDesireability(Pawn) <= 0.0 )
			continue;
		D = VSize(Pk.Location - Pawn.Location);
		if ( Best == None || D < BestD )
		{
			Best = Pk;
			BestD = D;
		}
	}
	return Best;
}

// Time to fetch a gun of ours from the floor: the trader is open (between waves; always in Endless), and there is one
// we want with time to get to it. Looked for every few seconds; after a try, not again for half a minute.
function bool ShouldRecoverDroppedWeapon()
{
	if ( Level.TimeSeconds < NextRecoverTime || KFGameType(Level.Game) == None || KFGameType(Level.Game).bWaveInProgress )
		return false;
	PickupTarget = FindBestDroppedPickupNear();
	if ( PickupTarget == None || !RecoverTimeOK(PickupTarget) )
	{
		PickupTarget = None;
		NextRecoverTime = Level.TimeSeconds + 5.f;
		return false;
	}
	return true;
}

// Time before the next wave to go and get something lying here: always in Endless; else the run there (half as far
// again as the straight line, more on another floor, at a sprint) and 5 seconds to spare fit in the trader time left.
final function bool RecoverTimeOK( Actor A )
{
	local KFGameReplicationInfo GRI;
	local float Speed, Way;

	GRI = KFGameReplicationInfo(Level.Game.GameReplicationInfo);
	if ( KFEndlessGameType(Level.Game) != None || GRI == None )
		return true;
	Speed = FMax(Pawn.GroundSpeed, 150.f);
	if ( KFHumanPawn(Pawn) != None && !KFHumanPawn(Pawn).bIsSprinting )
		Speed *= KFHumanPawn(Pawn).SprintMulti;
	Way = 1.5 * VSize(A.Location - Pawn.Location);
	if ( Abs(A.Location.Z - Pawn.Location.Z) > 300.f )
		Way *= 1.7;
	return ( GRI.TimeToNextWave > Way / Speed + 5.f );
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
    NextRecoverTime = 0;
    SwapPickup = None;
    SwapDrops.Length = 0;
    SwapGuardTime = 0;
    ShoppingAttempts = 0;
    AnchorLostTime = 0;

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
	// a Berserker shoots what hurts from afar with his gun rather than walk into it (players carry one for Sirens)
	if ( bZerkGun && W.bMeleeWeapon && KFMonster(Enemy) != None && RangedThreat(KFMonster(Enemy))
		&& VSize(Enemy.Location - Pawn.Location) > 350.f && GetPerkName() == "Berserker" && LineOfSightTo(Enemy)
		&& CountThreatsWithin(300.f) == 0 )
		R *= 0.3;
	if ( W.bMeleeWeapon && Enemy != None && GetPerkName() != "Berserker" )
	{
		// Not a Berserker: a blade is for a lone weak specimen or for when the guns are dry, and not at all when hurt.
		if ( Pawn.Health <= 40 )
			return 0.05;
		if ( !IsEasyMeleeTarget(Enemy) || CountThreatsWithin(300.f) >= 3 )
			R *= 0.5;
	}
	// A rocket launcher that cannot be fired safely at the enemy is no weapon for now (unless it is out and waiting a moment
	// for a big one's line to clear, RocketWait).
	if ( Enemy != None && RocketClassOf(W) != None )
	{
		if ( Level.TimeSeconds - RocketUnsafeTime >= 1.5f && RocketShotSafe(Enemy, RocketClassOf(W)) )
			RocketSafeTime = Level.TimeSeconds;
		else if ( !RocketWait(W) )
			return 0.05;
	}
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
		local int HealSum;
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
		HealSum = MySyringe.HealBoostAmount;

		if ( PRI!=None && PRI.ClientVeteranSkill!=none )
			HealSum *= PRI.ClientVeteranSkill.Static.GetHealPotency();

		// (paid as a player is: it worked out a reward and then gave none)
		class'SyringeFire'.static.PayForHealing(Pawn, class'SyringeFire'.static.Restores(InjuredAlly, HealSum));
		InjuredAlly.GiveHealth(HealSum, InjuredAlly.HealthMax);
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

// The path links that run through a zombie zone or end inside one. Worked out once and shared by the bots.
final function FindZoneLinks()
{
	local Controller C;
	local BlockingVolume V;
	local array<BlockingVolume> Zones;
	local NavigationPoint N;
	local ReachSpec Spec;
	local vector HL, HN;
	local int i, k;

	bZoneLinksFound = true;
	for ( C=Level.ControllerList; C!=None; C=C.NextController )
		if ( C != self && KFInvasionBot(C) != None && KFInvasionBot(C).bZoneLinksFound )
		{
			ZoneLinkPath = KFInvasionBot(C).ZoneLinkPath;
			ZoneLinkZone = KFInvasionBot(C).ZoneLinkZone;
			return;
		}
	foreach AllActors(class'BlockingVolume', V)
		if ( VerifyBlockingVolume(V) )
			Zones[Zones.Length] = V;
	if ( Zones.Length == 0 )
		return;
	for ( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
		for ( k=0; k<N.PathList.Length; k++ )
		{
			Spec = N.PathList[k];
			if ( Spec == None || Spec.End == None )
				continue;
			for ( i=0; i<Zones.Length; i++ )
				if ( Zones[i].Encompasses(N) || Zones[i].Encompasses(Spec.End) || !Zones[i].TraceThisActor(HL, HN, Spec.End.Location, N.Location) )
				{
					ZoneLinkPath[ZoneLinkPath.Length] = Spec;
					ZoneLinkZone[ZoneLinkZone.Length] = Zones[i];
				}
		}
	log("Zombie zones:"@Zones.Length@"path links through them:"@ZoneLinkPath.Length);
}

// Shuts the ways through zombie zones until OpenZoneLinks: the links through a zone that is on (a trigger can switch
// its collision) and the nodes we ran into one on the way to (TempBlockedPaths). Calls may nest.
final function ShutZoneLinks()
{
	local int i;

	if ( !bZoneLinksFound )
		FindZoneLinks();
	ZoneShutDepth++;
	if ( ZoneShutDepth > 1 )
		return;
	for ( i=0; i<ZoneLinkPath.Length; i++ )
		if ( ZoneLinkPath[i] != None && ZoneLinkZone[i] != None && ZoneLinkZone[i].bCollideActors && ZoneLinkZone[i].bBlockActors )
		{
			ZoneLinkPath[i].CollisionRadius -= 10000; // Pretend that no pawn is small enough to use this.
			ShutLinks[ShutLinks.Length] = ZoneLinkPath[i];
		}
	for ( i=0; i<TempBlockedPaths.Length; i++ )
		TempBlockedPaths[i].bBlocked = true;
}

final function OpenZoneLinks()
{
	local int i;

	if ( ZoneShutDepth <= 0 )
		return;
	ZoneShutDepth--;
	if ( ZoneShutDepth > 0 )
		return;
	for ( i=0; i<ShutLinks.Length; i++ )
		if ( ShutLinks[i] != None )
			ShutLinks[i].CollisionRadius += 10000;
	ShutLinks.Length = 0;
	for ( i=0; i<TempBlockedPaths.Length; i++ )
		TempBlockedPaths[i].bBlocked = false;
}

// (the last order a player gave us, for the hold to give way to)
function SetOrders(name NewOrders, Controller OrderGiver)
{
	if ( PlayerController(OrderGiver) != None )
		HumanOrders = NewOrders;
	Super.SetOrders(NewOrders, OrderGiver);
}

// During a wave the team holds one place (KFHoldPlan): the map's proven spot, or round a player who leads and stays
// put. Each bot goes to its post and watches its way in from there, shooting what comes and not going after what it
// cannot see. What is close is dealt with as ever, before this (ExecuteWhatToDoNext), and the bot comes back to its
// post after, once the way there is clear.
final function bool HoldAssignment()
{
	local KFHoldPlan Plan;
	local KFMonster Threat;
	local float ThreatDist, ThreatMargin;

	if ( !bHoldSpots || KFGameType(Level.Game) == None || Level.TimeSeconds < HoldOffUntil )
		return false;
	// a player told us where to be (a Hold order puts his HoldSpot in GoalScript) or to go our own way
	if ( bHumanOrdersFirst && (HoldSpot(GoalScript) != None || HumanOrders == 'Freelance' || HumanOrders == 'Attack') )
		return false;
	// a wave on, or the end of trader time: at the spot before the specimens come, as players are
	if ( !KFGameType(Level.Game).bWaveInProgress && KFGameType(Level.Game).WaveCountDown > HoldEarlyTime )
		return false;
	Plan = class'KFHoldPlan'.static.Get(self);
	if ( Plan == None )
		return false;
	// a player leading: posts round him once he stays put (until then, follow him as ever); with him dead, hold on where
	// we were; else the team's own spot
	if ( PlayerController(Squad.SquadLeader) != None )
	{
		if ( Squad.SquadLeader.Pawn != None && Squad.SquadLeader.Pawn.Health > 0 )
		{
			if ( !Plan.LeaderSettled(Squad.SquadLeader.Pawn) )
				return false;
		}
		else if ( !Plan.bReady && !Plan.Ready() )
			return false;
	}
	else if ( !Plan.Ready() )
		return false;
	if ( !Plan.PostFor(self, HoldNode, HoldFace, HoldNoWayNode) )
		return false;
	// no gun with ammo and nothing on us: go and restock (the squad's errands look for ammo and guns), as players do, and
	// come back after
	if ( Enemy == None && NeedWeapon() )
		return false;
	// a fight on: the gun out (the knife may be out from the run here)
	if ( Enemy != None )
		SwitchToBestWeapon();
	// nothing has come for a while with specimens about: go and find them, as players do (a spot off the specimens'
	// way stalls the wave), then come back
	if ( Enemy == None && Level.TimeSeconds - LastEnemyEncounter > HoldQuietTime && KFGameType(Level.Game).NumMonsters > 0
		&& NextHuntCheckTime < Level.TimeSeconds && HuntNearestSpecimen() )
	{
		GoalString = "Hold: quiet too long, going to find them";
		HoldChat(2);
		return true;
	}
	if ( Enemy != None && EnemyVisible() && VSize(HoldNode.Location - Pawn.Location) < HoldReach )
	{
		if ( HoldingMelee() )
			ChooseAttackMode();
		else
		{
			if ( NextTargetCheck < Level.TimeSeconds )
			{
				FindBetterTarget();
				NextTargetCheck = Level.TimeSeconds + 1.f;
			}
			if ( MedicHealNade() )
				return true;
			Threat = FindNearestThreat(ThreatDist, ThreatMargin);
			// a grenade from the post as in any other fight (the bot shoots from here without going through FightEnemy)
			if ( bPostNades && TryNade(Threat, ThreatMargin) )
				return true;
			TacticalReload(Threat, ThreatMargin);
			GoalString = "Hold: shoot from my post";
			DoRangedAttackOn(Enemy);
		}
		return true;
	}
	// off the post with a fight on: back to it only when the way there does not lead into the specimens (players give
	// ground and take the spot back once it is clear, they do not walk into what pushed them off it)
	if ( !HoldWayClear() )
	{
		HoldChat(1);
		return false;
	}
	GoalString = "Hold: my post "$HoldNode.Name$", watching "$HoldFace.Name;
	GotoState('HoldPost');
	return true;
}

// Where to look from the post: down our own way in, now and then down another (players keep an eye on every way in)
final function Actor HoldGlance()
{
	local KFHoldPlan Plan;
	local NavigationPoint F;

	if ( FRand() < HoldGlanceShare )
	{
		Plan = class'KFHoldPlan'.static.Get(self);
		if ( Plan != None )
			F = Plan.OtherFace(HoldFace);
	}
	if ( F != None )
		return F;
	return HoldFace;
}

// The first of the team at its post says so (once a spot)
final function AnnounceHold()
{
	local KFHoldPlan Plan;

	Plan = class'KFHoldPlan'.static.Get(self);
	if ( Plan != None && Plan.bReady && Plan.AnnouncedCenter != Plan.Center )
	{
		Plan.AnnouncedCenter = Plan.Center;
		HoldChat(0);
	}
}

// The way back to our post clear of the fight: no enemy, or no specimen in sight (or our enemy) about as near the post
// as we are, or nearer.
final function bool HoldWayClear()
{
	local Controller C;
	local float D;

	if ( Enemy == None )
		return true;
	D = VSize(HoldNode.Location - Pawn.Location);
	for ( C=Level.ControllerList; C!=None; C=C.nextController )
		if ( KFMonster(C.Pawn) != None && C.Pawn.Health > 0 && VSize(C.Pawn.Location - HoldNode.Location) < D + 300.f
			&& VSize(C.Pawn.Location - Pawn.Location) < 1500.f && (C.Pawn == Enemy || LineOfSightTo(C.Pawn)) )
			return false;
	return true;
}

// ActorReachable, but not across a zombie zone: the engine takes a path link from our anchor as walkable without
// testing the walk.
final function bool CanReach( Actor A )
{
	local bool bReach;

	ShutZoneLinks();
	bReach = ActorReachable(A);
	OpenZoneLinks();
	return bReach;
}

event bool NotifyHitWall(vector HitNormal, actor Wall)
{
	local vector HL, HN;

	if( PreviousNavPath!=None )
	{
		// (only a zone that stands between us and the node: scraping past one on the way to a node beside it says nothing)
		if( VerifyBlockingVolume(BlockingVolume(Wall)) && !Wall.TraceThisActor(HL, HN, PreviousNavPath.Location, Pawn.Location) )
		{
			// debugf;
			TempBlockedPaths.Insert(0,1);
			TempBlockedPaths[0] = PreviousNavPath;
			if( TempBlockedPaths.Length>4 )
				TempBlockedPaths.Length = 4;
			PreviousNavPath = None;
		}
	}
	// (glass's stand-in for trader time: break the glass, as a bump on it would)
	if( KFGlassBlocker(Wall)!=None && KFGlassBlocker(Wall).Glass!=None )
	{
		KFGlassBlocker(Wall).Glass.TakeDamage(50.f, Pawn, Pawn.Location, vect(0,0,0), class'DamageType');
		return true;
	}
	if( CurrentPath!=None && KFDoorMover(Wall)!=None && ((KFDoorMover(Wall).bSealed && !KFDoorMover(Wall).bDisallowWeld) || KFDoorMover(Wall).bTriggerTooFar || KFDoorMover(Wall).MyTrigger == None) )
	{
		AddSealPath(CurrentPath,KFDoorMover(Wall));
		MoveTarget = Pawn.Anchor;
	}
	if( LedgeJump(HitNormal) )
		return true;
	return Super.NotifyHitWall(HitNormal, Wall);
}

// (bLedgeJump) A ledge in a low opening, as KF-Offices' window sills (PathNode84, PathNode111): the engine's step up
// rises the whole MAXSTEPHEIGHT before it moves on, and its jump test (PickWallAdjust) looks ahead only at the top of
// the jump, so where the opening is lower than the pawn and a step both fail and the bot walks into the sill for good.
// Look for the heights up to our jump at which the way ahead is clear, with floor beyond, and hop to their middle.
final function bool LedgeJump(vector HitNormal)
{
	local vector Dir, Ext, HL, HN, Start, Ahead;
	local float Rise, H, Low, High, G, Reach;

	if( !bLedgeJump || Pawn==None || Pawn.Physics!=PHYS_Walking || !Pawn.bCanJump || Pawn.JumpZ<=0 || Level.TimeSeconds<NextLedgeJump
		|| Destination.Z<Pawn.Location.Z-MAXSTEPHEIGHT )
		return false;
	Dir = Destination - Pawn.Location;
	Dir.Z = 0;
	if( VSize(Dir)<1.f )
		return false;
	Dir = Normal(Dir);
	HitNormal.Z = 0;
	if( (Normal(HitNormal) dot Dir)>-0.5 )
		return false;
	G = FMax(Abs(Pawn.PhysicsVolume.Gravity.Z), 1.f);
	Rise = Square(Pawn.JumpZ) / (2.f * G);
	Ext = Pawn.GetCollisionExtent();
	Start = Pawn.Location;
	Reach = Pawn.CollisionRadius + 16.f;
	if( Trace(HL, HN, Start + Dir * Reach, Start, true, Ext)==None )
		return false;
	Low = -1;
	High = -1;
	for( H=4.f; H<=Rise; H+=4.f )
	{
		if( Trace(HL, HN, Start + vect(0,0,1) * H, Start, false, Ext)!=None )
			break;
		Ahead = Start + vect(0,0,1) * H + Dir * Reach;
		if( Trace(HL, HN, Ahead, Start + vect(0,0,1) * H, true, Ext)==None
			&& Trace(HL, HN, Ahead - vect(0,0,1) * (H + MAXSTEPHEIGHT), Ahead, false, Ext)!=None )
		{
			if( Low<0 )
				Low = H;
			High = H;
		}
		else if( Low>=0 )
			break;
	}
	if( Low<0 )
		return false;
	H = FMin(Rise, 0.5 * (Low + High) + 4.f);
	NextLedgeJump = Level.TimeSeconds + 1.f;
	Pawn.Velocity = Dir * Pawn.GroundSpeed;
	Pawn.Velocity.Z = Sqrt(2.f * G * H);
	Pawn.Acceleration = Dir * Pawn.AccelRate;
	bJumpOverWall = true;
	bNotifyApex = true;
	Pawn.SetPhysics(PHYS_Falling);
	return true;
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
			FireSpot = RocketAimSpot(Target, projStart);
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
    local Controller C;
    local string S;

    if (LastCalloutTime + 60.f > Level.TimeSeconds)
        return; // Don't spam

    M = KFMonster(SeenEnemy);
    if (M == None || M.Health <= 0)
        return;
    // one call for each big one, as in a team of players: not when a team-mate has called this one, or anything just now
    for ( C=Level.ControllerList; C!=None; C=C.nextController )
        if ( KFInvasionBot(C) != None && C != self
            && (KFInvasionBot(C).CalledOut == M || KFInvasionBot(C).LastCalloutTime + 8.f > Level.TimeSeconds) )
            return;

    if (M.IsA('ZombieBoss'))
    {
        switch (Rand(3))
        {
            case 0: S = "patty here"; break;
            case 1: S = "on me"; break;
            case 2: S = "BOSS"; break;
        }
    }
    else if (M.IsA('ZombieFleshPound'))
    {
        switch (Rand(4))
        {
            case 0: S = "fp"; break;
            case 1: S = "FP"; break;
            case 2: S = "fp on me"; break;
            case 3: S = "watch out fp"; break;
        }
    }
    else if (M.IsA('ZombieScrake'))
    {
        switch (Rand(3))
        {
            case 0: S = "scrake"; break;
            case 1: S = "SC"; break;
            case 2: S = "scrake here"; break;
        }
    }
    else if (M.IsA('ZombieSiren'))
    {
        switch (Rand(3))
        {
            case 0: S = "siren"; break;
            case 1: S = "SIREN"; break;
            case 2: S = "siren, get her"; break;
        }
    }
    if (S == "")
        return;
    LastCalloutTime = Level.TimeSeconds;
    CalledOut = M;
    SendChatMsg(S);
}

// A word to the team about the hold, typed as players type it: now and then, and seldom twice running.
// Kind 0 the team's spot taken (once a spot, by whoever gets there first), 1 giving ground, 2 going to find the last ones.
final function HoldChat( byte Kind )
{
	local string S;
	local Controller C;

	if ( Kind != 0 )
	{
		if ( Level.TimeSeconds < NextHoldChat || FRand() < 0.5 )
			return;
		for ( C=Level.ControllerList; C!=None; C=C.nextController )
			if ( KFInvasionBot(C) != None && C != self && KFInvasionBot(C).LastHoldChat + 20.f > Level.TimeSeconds )
				return;
	}
	NextHoldChat = Level.TimeSeconds + 30.f + 30.f * FRand();
	LastHoldChat = Level.TimeSeconds;
	switch ( Kind )
	{
		case 0:
			switch ( Rand(5) )
			{
				case 0: S = "hold here"; break;
				case 1: S = "camp here"; break;
				case 2: S = "lets hold here"; break;
				case 3: S = "set up here"; break;
				case 4: S = "stay together"; break;
			}
			break;
		case 1:
			switch ( Rand(4) )
			{
				case 0: S = "back up"; break;
				case 1: S = "too many"; break;
				case 2: S = "falling back"; break;
				case 3: S = "fall back"; break;
			}
			break;
		case 2:
			switch ( Rand(3) )
			{
				case 0: S = "where are they"; break;
				case 1: S = "ill go look"; break;
				case 2: S = "gonna find the last ones"; break;
			}
			break;
	}
	SendChatMsg(S);
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

// (bPitAware) A fall from Loc (the pawn's middle) that would badly hurt or kill, as players see the drop before they step: no
// floor within the height whose fall costs a quarter of the health (falls hurt from MaxFallSpeed on), or the floor in a pain
// volume or under the zone's kill height
final function bool PitBelow( vector Loc )
{
	local vector HitLocation, HitNormal;
	local float Drop;
	local PhysicsVolume V;

	Drop = Square(1.25 * Pawn.MaxFallSpeed) / (2.0 * FMax(Abs(Pawn.PhysicsVolume.Gravity.Z), 100.0));
	if ( Trace(HitLocation, HitNormal, Loc - vect(0,0,1) * (Pawn.CollisionHeight + Drop), Loc, false, Pawn.GetCollisionExtent()) == None )
		return true;
	if ( HitLocation.Z < Pawn.Region.Zone.KillZ + 2 * Pawn.CollisionHeight )
		return true;
	V = Level.GetPhysicsVolume(HitLocation);
	return ( V != None && V.bPainCausing && V.DamagePerSec > 0 );
}

// (bPitAware) Whether a jump from here towards Dest comes down in a pit or flies over one: the ground a quarter, a half, three
// quarters and all the way there (a combat jump lands short of where it was aimed, and over what it passes when it hits something)
final function bool PitOnTheWay( vector Dest )
{
	local vector Dir;
	local int i;

	Dir = Dest - Pawn.Location;
	Dir.Z = 0;
	for ( i=1; i<=4; i++ )
		if ( PitBelow(Pawn.Location + Dir * (0.25 * i)) )
			return true;
	return false;
}

// (bPitAware) The engine asks before the bot goes off a ledge (MayFall): not into a pit. Jumping is switched off for this tick,
// so the engine takes the step back and ends the move. A path down to a node below is trusted.
final function PitCheckFall()
{
	if ( !bPitAware || Pawn == None || !Pawn.bCanJump )
		return;
	if ( NavigationPoint(MoveTarget) != None && InLatentExecution(LATENT_MOVETOWARD)
		&& MoveTarget.Location.Z < Pawn.Location.Z - Pawn.CollisionHeight - MAXSTEPHEIGHT )
		return;
	if ( PitBelow(Pawn.Location) )
	{
		Pawn.bCanJump = false;
		bPitBlockedFall = true;
	}
}

event MayFall()
{
	PitCheckFall();
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
	if ( MedicHealNade() )
		return;
	// Badly hurt with something on top of us: get clear before anything else.
	if ( Pawn.Health < 35 && Threat != None && ThreatDist < 220.f && GetPerkName() != "Berserker" )
	{
		GoalString = "Retreat, badly hurt";
		DoRetreat();
		return;
	}
	// On our own with the crowd pressing, or specimens closing from more than one side: take the way out it leaves.
	if ( ShouldEscapeCrowd() && EscapeOpen() )
	{
		GoalString = "Escape the crowd";
		bEscapeFlee = false;
		GotoState('EscapeCrowd');
		return;
	}
	// Heal when nothing can reach us while we do it (was: only with fewer than two specimens in sight within 800).
	if (Pawn.Health < GetMinHealingValue() && (Threat == None || ThreatMargin > 150.f) && StartleActor == None && TryToHealSelf() )
		return;
	if ( TryNade(Threat, ThreatMargin) )
		return;
	if ( AmmoRunAssignment(Threat, ThreatMargin) )
		return;
	TacticalReload(Threat, ThreatMargin);

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
			if ( KFHumanPawn(Target) != None )
				NextHealNadeTime = Level.TimeSeconds + 7.f;
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
	if ( HealNadeTarget != None && HealNadeTarget.Health > 0 )
		Target = HealNadeTarget;
	else
		Target = NearbyAllyNeedsHealing();
	HealNadeTarget = None;
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
	if ( Target == None )
	{
		WhatToDoNext(154);
		Stop;
	}
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

// Running from a crowd along the way out the crowd sense finds (PlanEscape), a leg at a time, planning again after each
// leg and when the leg is about to be cut. Fires at what most threatens the way. Ends when the crowd no longer presses.
state EscapeCrowd
{
	ignores SeePlayer, HearNoise, EnemyNotVisible;

	function BeginState()
	{
		SetBotSprinting(true);
		Pawn.bWantsToCrouch = false;
		EscapeUntil = Level.TimeSeconds + EscapeMaxTime;
		NextEscapePlanTime = Level.TimeSeconds + 0.5;
	}
	function EndState()
	{
		SetBotSprinting(false);
		EscapeBlocker = None;
		if ( !bEscapeFlee )
			NextEscapeTime = Level.TimeSeconds + EscapeCooldown;
		bEscapeFlee = false;
	}
	function Timer()
	{
		enable('NotifyBump');
		if ( EscapeBlocker != None && EscapeBlocker != Enemy && EscapeBlocker.Health > 0 )
			Enemy = EscapeBlocker;
		Target = Enemy;
		if ( Enemy != None )
			TimedFireWeaponAtEnemy();
		else
			SetCombatTimer();
		if ( Level.TimeSeconds > NextEscapePlanTime && LegCutOff() )
		{
			if ( bBenchDebug )
				log("ESC cut t="$Level.TimeSeconds@PlayerReplicationInfo.PlayerName);
			NextEscapePlanTime = Level.TimeSeconds + 0.5;
			GotoState('EscapeCrowd', 'Moving');
		}
	}
Begin:
	WaitForLanding();
	EscapeLegs = 0;
Moving:
	if ( EscapeLegs > 0 && (Level.TimeSeconds > EscapeUntil || !EscapeStillNeeded()) )
		WhatToDoNext(170);
	// no way out with time to spare (any more): stand and fight, or run the old way when fleeing
	if ( !PlanEscape() || EscapeGoalMargin < EscapeMinMargin )
	{
		if ( EscapeLegs == 0 && bEscapeFlee )
		{
			NextEscapeTime = Level.TimeSeconds + 0.5;
			GotoState('Retreating');
		}
		else
			WhatToDoNext(171);
	}
	EscapeLegs++;
	// hurt, and nothing can reach us for a while: heal now; with a second or so to spare, reload
	// (the state change is a statement of its own: one inside a condition leaves the rest of the condition to be read
	// from the new state's code, and the script engine stops the actor with "Unknown code token")
	if ( Pawn.Health < GetMinHealingValue() && NodeMargin(Pawn.Location, 0.f) > 2.f && MySyringe != None && MySyringe.ChargeBar() >= 0.99f )
		GotoState('GoHealSelf');
	if ( NodeMargin(Pawn.Location, 0.f) > 1.5f )
		ReloadIfLow();
	LastFallbackMoveTime = Level.TimeSeconds;
	if ( bBenchDebug )
		log("ESC t="$Level.TimeSeconds@PlayerReplicationInfo.PlayerName@"leg="$EscapeLegs@"to="$MoveTarget@"d="$int(VSize(MoveTarget.Location - Pawn.Location))
			@"goal="$EscapeGoal@"m="$PlannedLegMargin@"nodes="$EscNode.Length@"crowd="$CrowdList.Length@"flee="$bEscapeFlee@"spd="$int(VSize(Pawn.Velocity)));
	PreviousNavPath = NavigationPoint(MoveTarget);	// (NotifyHitWall: what a zombie zone stopped us reaching)
	MoveToward(MoveTarget, EscapeFocus(),, true);
	if ( bBenchDebug )
		log("ESC done t="$Level.TimeSeconds@PlayerReplicationInfo.PlayerName@"left="$int(VSize(MoveTarget.Location - Pawn.Location))@"took="$(Level.TimeSeconds - LastFallbackMoveTime));
	if ( Level.TimeSeconds - LastFallbackMoveTime < 0.1 )
		Sleep(0.1);
	Goto('Moving');
}

// At my post in the held area (HoldAssignment): get there, shooting what is in sight on the way, then stand and watch
// my way in.
state HoldPost
{
	ignores HearNoise;

	function BeginState()
	{
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
	function Actor HoldLook()
	{
		if ( Enemy != None && LineOfSightTo(Enemy) )
			return Enemy;
		return MoveTarget;
	}
Begin:
	WaitForLanding();
	if ( HoldNode != None && VSize(HoldNode.Location - Pawn.Location) > HoldReach )
	{
		SetBotSprinting(Enemy == None && VSize(HoldNode.Location - Pawn.Location) > 600.f);
		if ( CanReach(HoldNode) )
		{
			MoveTarget = HoldNode;
			MoveToward(HoldNode, HoldLook(),, Enemy != None);
		}
		else if ( FindBestPathToward(HoldNode, true, true) )
			MoveToward(MoveTarget, HoldLook(),, Enemy != None);
		else
		{
			GoalString = "Hold: no way to my post";
			HoldOffUntil = Level.TimeSeconds + HoldNoWayRest;
			HoldNoWayNode = HoldNode;
			if ( class'KFHoldPlan'.static.Get(self) != None )
				class'KFHoldPlan'.static.Get(self).DropPost(self);
			if ( Pawn.FindAnchorFailedTime == Level.TimeSeconds && AnchorLostTooLong() )
				TeleportBackIn();
			Sleep(0.5);
		}
		WhatToDoNext(180);
	}
	SetBotSprinting(false);
	AnnounceHold();
	Focus = HoldGlance();
	Pawn.Acceleration = vect(0,0,0);
	Sleep(0.4 + 0.4 * FRand());
	WhatToDoNext(181);
}

// To an ammo box on the map (see AmmoRunAssignment), shooting on the way
state AmmoRun
{
	ignores HearNoise;

	function BeginState()
	{
		Pawn.bWantsToCrouch = false;
	}
	function EndState()
	{
		NextAmmoRunTime = Level.TimeSeconds + 10.f;
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
	// still there and still of use to us, nothing to run from, and closer within the last few legs
	final function bool KeepGoing()
	{
		local float D;

		if ( AmmoRunTarget == None || AmmoRunTarget.bHidden || AmmoRunTarget.bDeleteMe || !AmmoRunTarget.IsInState('Pickup')
			|| AmmoRunTarget.BotDesireability(Pawn) <= 0 || EnemyReallyScary() )
			return false;
		D = VSize(AmmoRunTarget.Location - Pawn.Location);
		if ( D < AmmoRunBestDist - 48.f )
		{
			AmmoRunBestDist = D;
			AmmoRunStalls = 0;
		}
		else if ( ++AmmoRunStalls > 8 )
			return false;
		return true;
	}
Begin:
	WaitForLanding();
	AmmoRunBestDist = 1000000.f;
	AmmoRunStalls = 0;
KeepMoving:
	if ( !KeepGoing() )
		WhatToDoNext(195);
	else if ( CanReach(AmmoRunTarget) )
	{
		MoveToward(AmmoRunTarget, FaceActor(1),, Enemy != None);
		Goto('KeepMoving');
	}
	else if ( FindBestPathToward(AmmoRunTarget, true, true) )
	{
		MoveToward(MoveTarget, FaceActor(1),, Enemy != None);
		Goto('KeepMoving');
	}
	else
		WhatToDoNext(196);
}

// To a player who called for cover (see CoverAssignment), shooting on the way
state CoverRun
{
	ignores HearNoise;

	function BeginState()
	{
		Pawn.bWantsToCrouch = false;
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
	if ( CoverFor == None || CoverFor.Health <= 0 )
		WhatToDoNext(197);
	else if ( CanReach(CoverFor) )
		MoveToward(CoverFor, FaceActor(1),, Enemy != None);
	else if ( FindBestPathToward(CoverFor, true, true) )
		MoveToward(MoveTarget, FaceActor(1),, Enemy != None);
	else
		CoverFor = None;
	WhatToDoNext(198);
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
	{
		PreviousNavPath = NavigationPoint(MoveTarget);
		MoveToward(MoveTarget, Enemy,, true);
	}
	WhatToDoNext(155);
}

// The stock state with one change: its own DoWaitForLanding (asked for when the last line's decision finds the bot
// falling again, as after a teleport onto a node in mid-air) only reset the state, and with its code run out the bot
// stood there for good. Now it waits again.
state WaitingForLanding
{
	function bool DoWaitForLanding()
	{
		if ( bJustLanded )
			return false;
		BeginState();
		GotoState('WaitingForLanding', 'Wait');
		return true;
	}

Begin:
	if ( Pawn.PhysicsVolume.bWaterVolume )
		WhatToDoNext(150);
	if ( Pawn.PhysicsVolume.Gravity.Z > 0.9 * Pawn.PhysicsVolume.Default.Gravity.Z )
	{
		if ( (MoveTarget == None) || (MoveTarget.Location.Z > Pawn.Location.Z) )
		{
			NotifyMissedJump();
			if ( MoveTarget != None )
				MoveToward(MoveTarget,Focus,,true);
		}
		else if (Physics != PHYS_Falling)
			WhatToDoNext(151);
		else
		{
			Sleep(0.5);
			Goto('Begin');
		}
	}
Wait:
	WaitForLanding();
	WhatToDoNext(50);
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
	local Vector HN,HL,MateLoc;
	local bool bToMate;
	local float SirenCost;

	// (bRetreatToTeam) a Fleshpound or Scrake after us: lead him into the team's fire
	bToMate = bRetreatToTeam && BigOneAfterUs() && NearestAllyLoc(MateLoc) && VSize(MateLoc - Pawn.Location) < 1500.f;
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
		if( CurrentMov==None || !CanReach(CurrentMov) )
			return;
		MoveTarget = CurrentMov;
		return;
	}
	if( VSize(CurrentMov.Location-Pawn.Location)>100.f )
	{
		if( CanReach(CurrentMov) )
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
	ShutZoneLinks();
	for( i=0; i<CurrentMov.PathList.Length; i++ )
	{
		N = CurrentMov.PathList[i].End;
		if( N==CurrentMov || N.bBlocked || LiftCenter(N)!=None || !ActorReachable(N) )
			continue;
		EnemyDir = vect(0,0,0);
        TotalWeight = 0.0;
        bAnyMonsterHasLOS = false;
        SirenCost = 0;
        for( C = Level.ControllerList; C != None; C = C.nextController )
        {
            M = KFMonster(C.Pawn);
            if( M == None || M.Health <= 0 )
                continue;

            // (bSirenAware) inside a Siren's scream: within its reach (700), in front of her (her cone), in her sight
            if ( bSirenAware && M.IsA('ZombieSiren') && !M.bDecapitated && VSize(N.Location - M.Location) < 750.f
                && (Normal(N.Location - M.Location) dot vector(M.Rotation)) > 0.4f && FastTrace(N.Location, M.Location + M.EyePosition()) )
                SirenCost += 0.5f;

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
		Dist += SirenCost;
        if ( bToMate )
            Dist -= Normal(MateLoc - Pawn.Location) dot Normal(N.Location - Pawn.Location) * 0.8f;
        else if ( Squad != None )
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
	OpenZoneLinks();
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
	// On our own: run along the way out the crowd sense finds (state EscapeCrowd), not a node at a time.
	// Not again straight after it found none (NextEscapeTime).
	if ( bCrowdEscape && Enemy != None && Pawn.Physics == PHYS_Walking && Level.TimeSeconds >= NextEscapeTime && AloneInFight() )
	{
		bEscapeFlee = true;
		GotoState('EscapeCrowd');
		return;
	}
	GotoState('Retreating');
}

state Retreating
{
ignores SeePlayer, HearNoise;

	function BeginState()
	{
		SetBotSprinting(true);
		Pawn.bWantsToCrouch = false;
		// (a running fire timer re-armed on every entry never fires when the bot comes back here each tick)
		if ( TimerRate <= 0.f || TimerRate > 0.1f )
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
			// nowhere to back off to (the move ended at once): stand and shoot, not decide to retreat again every tick
			if( Enemy!=None && Level.TimeSeconds - LastFallbackMoveTime < 0.15 )
			{
				GoalString = "Cornered: stand and shoot";
				DoRangedAttackOn(Enemy);
			}
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
		if ( MoveTarget == Enemy )
		{
			Pawn.bCanJump = ActorReachable(Enemy);
			if ( !Pawn.bCanJump )
				MoveTimer = -1.0;
		}
		PitCheckFall();
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

	function Tick( float DeltaTime )
	{
		Global.Tick(DeltaTime);
		// (the checks in Global.Tick can have sent us elsewhere, to get out of bile: no StepBack label there)
		if ( IsInState('Charging') && ZerkStepBackNow() )
			GotoState(, 'StepBack');
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
	Stop;
StepBack:
	GoalString = "Step back after the blow";
	MoveTo(ZerkBackSpot, Enemy);
	WhatToDoNext(18);
}


// (bPitAware) Stock Fallback and Hunting answer MayFall themselves: the pit check after theirs
state Fallback
{
	function MayFall()
	{
		Super.MayFall();
		PitCheckFall();
	}
}

state Hunting
{
ignores EnemyNotVisible;

	function MayFall()
	{
		Super.MayFall();
		PitCheckFall();
	}
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

// A fight's grenade: where specimens bunch, or a Field Medic's healing one for a hurt team-mate close by (ShouldNadeEnemy).
// True if the bot goes to throw it.
final function bool TryNade( KFMonster Threat, float ThreatMargin )
{
	local KFMonster FP;

	// a frag for a Fleshpound goes before the toss of a coin (bFragFP)
	if ( bFragFP && NextNadeTimer<Level.TimeSeconds && MyGrenades!=None && MyGrenades.HasAmmo() )
	{
		FP = FPToFrag();
		if ( FP != None )
		{
			Enemy = FP;
			FragTarget = FP;
			FragTime = Level.TimeSeconds;
			NextNadeTimer = Level.TimeSeconds+2.5f+FRand();
			GoalString = "Frag the Fleshpound";
			GoToState('NadeTarget');
			return true;
		}
	}
	if( NextNadeTimer<Level.TimeSeconds && MyGrenades!=None && MyGrenades.HasAmmo() && (Threat==None || ThreatMargin>0.f) && (Rand(2)==0 || ManyEnemiesAround(5, Pawn.Location))
		&& !(bFragFP && KeepFragsForFP()) && ShouldNadeEnemy() )
	{
		NextNadeTimer = Level.TimeSeconds+6.f+FRand()*5.f;
		GoalString = "NadeEnemy";
		GoToState('NadeTarget');
		return true;
	}
	else NextNadeTimer = Level.TimeSeconds+1.f+FRand()*4.f;
	return false;
}

// (bFragFP) The Fleshpound to throw a frag at, as players spend theirs on them (frags and rockets do him double damage): in
// sight, in throwing range with a clear arc, with more than a quarter of his health left, and no grenade already on its way to
// him (anyone's) nor one a team-mate has just gone to throw; the nearest. Not from a Field Medic or a Firebug, whose grenades
// heal or burn.
final function KFMonster FPToFrag()
{
	local Controller C, C2;
	local KFMonster M, Best;
	local Nade N;
	local float D, BestD;
	local bool bTaken;

	if ( GetPerkName() == "Field Medic" || GetPerkName() == "Firebug" )
		return None;
	for ( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		M = KFMonster(C.Pawn);
		if ( M == None || M.Health <= 0.25 * M.HealthMax || !M.IsA('ZombieFleshPound') || M.bDecapitated )
			continue;
		D = VSize(M.Location - Pawn.Location);
		if ( D < GetNadeMinDist() + 60.f || D > 1100.f || (Best != None && D >= BestD) || !LineOfSightTo(M) )
			continue;
		bTaken = false;
		for ( C2=Level.ControllerList; C2!=None && !bTaken; C2=C2.nextController )
			if ( C2 != self && KFInvasionBot(C2) != None && KFInvasionBot(C2).FragTarget == M && Level.TimeSeconds - KFInvasionBot(C2).FragTime < 2.5f )
				bTaken = true;
		foreach DynamicActors(class'Nade', N)
			if ( !bTaken && !N.bHasExploded && VSize(N.Location - M.Location) < 600.f )
				bTaken = true;
		if ( bTaken || !NadeLaneClear(M) || !NadePathClear(M) )
			continue;
		Best = M;
		BestD = D;
	}
	return Best;
}

// (bFragFP) In a wave with Fleshpounds, the last FragReserve frags are theirs (a Field Medic's and a Firebug's grenades are not
// for them, so they keep none)
final function bool KeepFragsForFP()
{
	if ( GetPerkName() == "Field Medic" || GetPerkName() == "Firebug" || MyGrenades == None )
		return false;
	return MyGrenades.AmmoAmount(0) <= FragReserve && FleshpoundWave();
}

// (bTacticalReload) In a lull of the fight (nothing within 500, nothing inside its kite distance with 250 to spare), a gun
// under a third full is reloaded now, as players do, rather than at its last round with a specimen on top of us
final function TacticalReload( KFMonster Threat, float ThreatMargin )
{
	local KFWeapon KW;

	if ( !bTacticalReload || Pawn == None )
		return;
	KW = KFWeapon(Pawn.Weapon);
	if ( KW == None || KW.bMeleeWeapon || KW.bIsReloading || KW.ClipCount <= 1 || KW.ClipLeft >= KW.ClipCount * 0.35
		|| !KW.AllowReload() || (Threat != None && ThreatMargin < 250.f) || CountThreatsWithin(500.f) > 0 )
		return;
	KW.ReloadMeNow();
}

// (bAmmoRun) Low on ammo in a wave with nothing close (every gun we would use under a quarter full): an ammo box for one of our
// guns lying out on the map near by, with no crowd round it. Players top up from the boxes rather than fight on with the 9mm.
final function bool AmmoRunAssignment( KFMonster Threat, float ThreatMargin )
{
	if ( !bAmmoRun || Pawn == None || Level.TimeSeconds < NextAmmoRunTime || KFGameType(Level.Game) == None
		|| !KFGameType(Level.Game).bWaveInProgress || (Threat != None && ThreatMargin < 300.f) || !LowOnAmmo() )
		return false;
	NextAmmoRunTime = Level.TimeSeconds + 3.f;
	AmmoRunTarget = AmmoBoxNear();
	if ( AmmoRunTarget == None )
		return false;
	GoalString = "Ammo run to "$AmmoRunTarget.Name;
	GotoState('AmmoRun');
	return true;
}

// Every gun we would fight with (not melee, rated over 0.5, not the grenades) under a quarter of its ammo
final function bool LowOnAmmo()
{
	local Inventory Inv;
	local KFWeapon W;
	local bool bAny;

	for ( Inv=Pawn.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		W = KFWeapon(Inv);
		if ( W == None || W.bMeleeWeapon || W.AIRating <= 0.5 || W.AmmoClass[0] == None || Frag(W) != None )
			continue;
		bAny = true;
		if ( W.AmmoAmount(0) >= 0.25 * W.MaxAmmo(0) )
			return false;
	}
	return bAny;
}

// The nearest ammo box out on the map for one of our guns: within 1800 on about our floor, with no crowd round it
final function KFAmmoPickup AmmoBoxNear()
{
	local KFAmmoPickup P, Best;
	local float D, BestD;

	foreach DynamicActors(class'KFAmmoPickup', P)
	{
		if ( P.bHidden || P.bDeleteMe || !P.IsInState('Pickup') || P.BotDesireability(Pawn) <= 0 )
			continue;
		D = VSize(P.Location - Pawn.Location);
		if ( D > 1800.f || (Best != None && D >= BestD) || Abs(P.Location.Z - Pawn.Location.Z) > 400.f || ManyEnemiesAround(4, P.Location) )
			continue;
		Best = P;
		BestD = D;
	}
	return Best;
}

// A player's voice call (KFVoicePack.PlayerSpeech), which the stock code passes on to bots only when it is an order
static function TellBotsOfCall( Controller Caller, name CallType )
{
	local Controller C;

	if ( Caller == None || Caller.Pawn == None )
		return;
	for ( C=Caller.Level.ControllerList; C!=None; C=C.nextController )
		if ( KFInvasionBot(C) != None && C.Pawn != None && C.Pawn.Health > 0 && C.SameTeamAs(Caller) )
			KFInvasionBot(C).HeardCall(Caller, CallType);
}

// (bAnswerCalls) A player's call: "Medic!" brings the best placed of us to heal him (MedicAnswerer), "Cover!" the two of us
// nearest him and "Form up!" all of us, for a while
function HeardCall( Controller Caller, name CallType )
{
	if ( !bAnswerCalls || Caller.Pawn == None || Pawn == None )
		return;
	if ( CallType == 'MEDIC' )
	{
		if ( Caller.Pawn.Health < Caller.Pawn.HealthMax && MedicAnswerer(Caller.Pawn) == self )
		{
			MedicCallFor = Caller.Pawn;
			MedicCallUntil = Level.TimeSeconds + 12.f;
			if ( Caller.PlayerReplicationInfo != None )
				SendChatMsg("Coming, "$Caller.PlayerReplicationInfo.PlayerName$"!");
		}
	}
	else if ( CallType == 'COVER' || CallType == 'FORM' )
	{
		if ( CallType == 'FORM' || AmongNearestTo(Caller.Pawn, 2) )
		{
			CoverFor = Caller.Pawn;
			CoverUntil = Level.TimeSeconds + 15.f;
		}
	}
}

// Of us bots, the one to answer a call for a medic from P: a Field Medic first (half the distance), then whoever is nearest
// with the syringe charged; none further than 2000
final function KFInvasionBot MedicAnswerer( Pawn P )
{
	local Controller C;
	local KFInvasionBot B, Best;
	local float D, BestD;

	for ( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		B = KFInvasionBot(C);
		if ( B == None || B.Pawn == None || B.Pawn.Health <= 0 || B.Pawn == P || !B.bAnswerCalls )
			continue;
		D = VSize(B.Pawn.Location - P.Location);
		if ( B.GetPerkName() == "Field Medic" )
			D *= 0.5;
		else if ( B.MySyringe == None || B.MySyringe.ChargeBar() < 0.6f )
			continue;
		if ( D < 2000.f && (Best == None || D < BestD) )
		{
			Best = B;
			BestD = D;
		}
	}
	return Best;
}

// Whether we are among the N bots nearest to P
final function bool AmongNearestTo( Pawn P, int N )
{
	local Controller C;
	local float MyD;
	local int Nearer;

	MyD = VSize(Pawn.Location - P.Location);
	for ( C=Level.ControllerList; C!=None; C=C.nextController )
		if ( C != self && KFInvasionBot(C) != None && C.Pawn != None && C.Pawn.Health > 0 && C.Pawn != P
			&& VSize(C.Pawn.Location - P.Location) < MyD )
			Nearer++;
	return Nearer < N;
}

// (bAnswerCalls) Answering "Cover!" or "Form up!": to the player, then fight as usual round him until the call runs out
final function bool CoverAssignment()
{
	if ( CoverFor == None || Level.TimeSeconds > CoverUntil || CoverFor.Health <= 0 )
	{
		CoverFor = None;
		return false;
	}
	if ( VSize(CoverFor.Location - Pawn.Location) < 350.f && LineOfSightTo(CoverFor) )
		return false;
	if ( CoverFor.PlayerReplicationInfo != None )
		GoalString = "Cover "$CoverFor.PlayerReplicationInfo.PlayerName;
	GotoState('CoverRun');
	return true;
}

// Field Medic (bMedicCrowdHeal): the healing grenade thrown where specimens crowd the team (CrowdHealTarget). Unlike other
// grenades it goes with specimens close by, since it cannot hurt us; not with a raging Fleshpound after us. True if the bot
// goes to throw it.
final function bool MedicHealNade()
{
	if ( !bMedicCrowdHeal || MyGrenades == None || !MyGrenades.HasAmmo() || Level.TimeSeconds < NextHealNadeTime
		|| GetPerkName() != "Field Medic" )
		return false;
	HealNadeTarget = CrowdHealTarget();
	if ( HealNadeTarget == None && MedicCallFor != None && Level.TimeSeconds < MedicCallUntil && KFHumanPawn(MedicCallFor) != None
		&& MedicCallFor.Health > 0 && MedicCallFor.Health < 70 && VSize(MedicCallFor.Location - Pawn.Location) < MedicHealDist
		&& LineOfSightTo(MedicCallFor) && NadePathClear(MedicCallFor) )
		HealNadeTarget = KFHumanPawn(MedicCallFor);
	if ( HealNadeTarget == None || EnemyReallyScary() )
	{
		HealNadeTarget = None;
		return false;
	}
	NextHealNadeTime = Level.TimeSeconds + 7.f;
	GoalString = "Heal grenade into the crowd";
	GoToState('NadeTarget');
	return true;
}

// Where a medic throws the healing grenade, as players do when it gets wild: at his own feet when specimens are round him,
// or into team-mates they surround, even from across the room. Of the team-mates in sight within MedicHealDist (and
// himself) with MedicHealCrowd or more specimens within MedicHealReach, the one where the cloud does most: those
// specimens, the team-mates it would cover and the health they miss.
final function KFHumanPawn CrowdHealTarget()
{
	local Controller C, C2;
	local KFHumanPawn P, Q, Best;
	local int Z, T;
	local float Score, BestScore, Missing;

	for ( C=Level.ControllerList; C!=None; C=C.nextController )
	{
		P = KFHumanPawn(C.Pawn);
		if ( P == None || P.Health <= 0 || VSize(P.Location - Pawn.Location) > MedicHealDist )
			continue;
		if ( P != Pawn && (!LineOfSightTo(P) || !NadePathClear(P)) )
			continue;
		Z = SpecimensNear(P.Location, MedicHealReach);
		if ( Z < MedicHealCrowd )
			continue;
		T = 0;
		Missing = 0;
		for ( C2=Level.ControllerList; C2!=None; C2=C2.nextController )
		{
			Q = KFHumanPawn(C2.Pawn);
			if ( Q != None && Q.Health > 0 && VSize(Q.Location - P.Location) < 175.f )
			{
				T++;
				Missing += FMax(Q.HealthMax - Q.Health - Q.HealthToGive, 0);
			}
		}
		Score = Z + 2 * T + Missing / 50.f;
		if ( Best == None || Score > BestScore )
		{
			Best = P;
			BestScore = Score;
		}
	}
	return Best;
}

// Live specimens within R of Loc, about on its floor
final function int SpecimensNear( vector Loc, float R )
{
	local Controller C;
	local int Count;

	for ( C=Level.ControllerList; C!=None; C=C.nextController )
		if ( KFMonster(C.Pawn) != None && C.Pawn.Health > 0 && VSize(C.Pawn.Location - Loc) < R && Abs(C.Pawn.Location.Z - Loc.Z) < 150.f )
			Count++;
	return Count;
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
    // a Berserker with a gun and nothing on top of him shoots Sirens first, from where he is
    if( bZerkGun && M.IsA('ZombieSiren') && !M.bDecapitated && VSize(M.Location-Pawn.Location)<1200.f && GetPerkName()=="Berserker"
        && HasLoadedGun() && CountThreatsWithin(300.f) == 0 )
        Cost*=0.4f;
    // (bScrakeFocus) a Scrake within 700 with his head on comes first: he charges at two and a half times his pace at
    // anyone who turns away from him, so a player keeps him in front while backing off
    if( bScrakeFocus && M.IsA('ZombieScrake') && !M.bDecapitated && VSize(M.Location-Pawn.Location)<700.f )
        Cost*=0.4f;
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
	if( BP!=None )
		BP = KFMonster(SpecimenInLine(BP));
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
	// A wall in the way: slide along it (stock decided again here, and the decision mostly picked the same move into the
	// same wall, many times a second). No room along it, or a second wall: fall back along the paths, or stand and shoot.
	function bool NotifyHitWall(vector HitNormal, actor Wall)
	{
		local vector Dir, Along, Start, Extent, HitLocation, WallNormal;

		if ( Pawn.Physics == PHYS_Falling || Enemy == None || Vehicle(Wall) != None )
			return Super.NotifyHitWall(HitNormal, Wall);
		HitNormal.Z = 0;
		HitNormal = Normal(HitNormal);
		Dir = Destination - Pawn.Location;
		Dir.Z = 0;
		Along = Dir - (Dir dot HitNormal) * HitNormal;
		if ( !bChangeDir && VSize(Along) > 60.f )
		{
			bChangeDir = true;
			Extent = Pawn.GetCollisionExtent();
			Extent.Z = FMax(6, Pawn.CollisionHeight - MAXSTEPHEIGHT);
			Start = Pawn.Location + 2 * HitNormal;	// off the wall, so the trace does not begin against it
			if ( Trace(HitLocation, WallNormal, Start + Along, Start, false, Extent) != None )
				Along = HitLocation - Start;
			if ( VSize(Along) > 60.f )
			{
				Destination = Start + Along;
				return true;
			}
		}
		Focus = Enemy;
		if ( PickPathAwayFromThreats() )
		{
			GoalString = "Against a wall: fall back along the path";
			GotoState('FallBackOnPath');
		}
		else
		{
			GoalString = "Against a wall: stand and shoot";
			DoRangedAttackOn(Enemy);
		}
		return true;
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
			// (bPitAware) no dodge jump that comes down in a pit or flies over one
			if ( bWantJump && bPitAware && PitOnTheWay(MinDest) )
				bWantJump = false;

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

	// A step of the way in from where the path ends: straight towards the trader, or a little to either side, as far
	// as the bot can walk. False once it is at the trader or can get no closer.
	final function bool NextShopStep()
	{
		local vector Dir, Try;
		local rotator R;
		local int i;

		if ( ShopVolumeActor == None )
			return false;
		Dir = ShopVolumeActor.Location - Pawn.Location;
		Dir.Z = 0;
		if ( VSize(Dir) < Pawn.CollisionRadius + ShopVolumeActor.CollisionRadius + 40.f )
			return false;
		for ( i=0; i<3; i++ )
		{
			R = rotator(Dir);
			if ( i == 1 )
				R.Yaw += 5000;
			else if ( i == 2 )
				R.Yaw -= 5000;
			Try = Pawn.Location + vector(R) * FMin(160.f, VSize(Dir));
			if ( pointReachable(Try) )
			{
				Destination = Try;
				return true;
			}
		}
		return false;
	}
Begin:
	WaitForLanding();
	if ( KFGameType(Level.Game) != None && KFGameType(Level.Game).WaveNum != PersonalityWave )
	{
		PersonalityWave = KFGameType(Level.Game).WaveNum;
		AssignPersonality(); // Gain new personality on new wave.
	}
	SwitchToBestWeapon();
	BestShopDist = 9999.f; //Need to set this up first
KeepMoving:
    if( KFGameType(Level.Game).bWaveInProgress )
    {
        LastShopTime = level.TimeSeconds+15+FRand()*15;
        WhatToDoNext(152);
    }
    if( CanReach(ShoppingPath) )
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
            // Some places hold bots with no way out on the paths (KF-Offices' third floor by the breakable glass):
            // jump a step along the route, but never where a player could see it; else try again a little later.
            if ( RouteCache[1] != None && !HumanCanSee(Pawn.Location) && !HumanCanSee(RouteCache[1].Location) )
                Pawn.SetLocation(RouteCache[1].Location);
            else LastShopTime = Level.TimeSeconds + 4.0;
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
	// Where no path node is inside the shop: walk the last steps in.
	ShopSteps = 0;
	while ( ShopSteps++ < 12 && !InShop() && NextShopStep() )
		MoveTo(Destination, ShopVolumeActor);
	if ( bBenchDebug )
		log("SHOP at"@PlayerReplicationInfo.PlayerName@"in="$InShop()@"steps="$ShopSteps@"to trader="$int(VSize(ShopVolumeActor.Location - Pawn.Location))
			@"to entry="$int(VSize(ShoppingPath.Location - Pawn.Location))@"loc="$Pawn.Location);
	Focus = ShopVolumeActor;
	Pawn.Acceleration = vect(0,0,0);
	DoTrading();
	Sleep(0.5);
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
		PickupTarget = None;
		NextRecoverTime = Level.TimeSeconds + 30.f;
	}
	// Still there, still wanted, still time for it; and we have come closer within the last few legs.
	final function bool KeepGoing()
	{
		local float D;

		if ( PickupTarget == None || PickupTarget.bHidden || PickupTarget.bDeleteMe || PickupTarget.BotDesireability(Pawn) <= 0
			|| !RecoverTimeOK(PickupTarget) )
			return false;
		D = VSize(PickupTarget.Location - Pawn.Location);
		if ( D < RecoverBestDist - 48.f )
		{
			RecoverBestDist = D;
			RecoverStalls = 0;
		}
		else if ( ++RecoverStalls > 8 )
			return false;
		return true;
	}

Begin:
	WaitForLanding();
	SwitchToBestWeapon();
	RecoverBestDist = 1000000.f;
	RecoverStalls = 0;
KeepMoving:
	// (the next try is held off before deciding again: the decision could otherwise pick this same gun at once,
	// and a state chosen again starts over without BeginState)
	if ( !KeepGoing() )
	{
		NextRecoverTime = Level.TimeSeconds + 30.f;
		WhatToDoNext(37);
	}
	else if ( CanReach(PickupTarget) )
	{
		MoveToward(PickupTarget, PickupTarget);
		Goto('KeepMoving');
	}
	else if ( FindBestPathToward(PickupTarget, true, false) )
	{
		MoveToward(MoveTarget, FaceActor(1));
		Goto('KeepMoving');
	}
	else
	{
		NextRecoverTime = Level.TimeSeconds + 30.f;
		WhatToDoNext(38);
	}
	if(bSoaking)
		SoakStop("RECOVER DROPPED WEAPON FAILED");
}

// Walking over to a better gun on the floor to swap one we carry for it (see FindPickupSwap). At a spot just short of
// it the worse gun is thrown back the way we came (DropForSwap), then we step onto the new one. Fires on the way.
state SwapForPickup extends MoveToGoalWithEnemy
{
	ignores EnemyNotVisible;

	function Timer()
	{
		enable('NotifyBump');
		Target = Enemy;
		if ( Enemy != None )
			TimedFireWeaponAtEnemy();
		else
			SetCombatTimer();
	}
	function EndState()
	{
		SwapPickup = None;
		SwapDrops.Length = 0;
	}
	// The pickup is still there and the gun to leave still ours; and we have come closer within the last few legs.
	final function bool KeepGoing()
	{
		local float D;

		if ( SwapPickup == None || SwapPickup.bDeleteMe || SwapPickup.bHidden || !SwapDropsHeld() )
			return false;
		D = VSize(SwapPickup.Location - Pawn.Location);
		if ( D < SwapBestDist - 32.f )
		{
			SwapBestDist = D;
			SwapStalls = 0;
		}
		else if ( ++SwapStalls > 6 )
			return false;
		return true;
	}
	// Where to stand while the old gun goes: SwapDropDist this side of the pickup. Not on it: a pickup the bot is
	// already touching is not picked up when room is made for it, only one it walks into.
	final function bool DropSpot()
	{
		local vector Dir;
		local float D;

		Dir = Pawn.Location - SwapPickup.Location;
		Dir.Z = 0;
		D = VSize(Dir);
		if ( D < 1.f )
		{
			Dir = -vector(Pawn.Rotation);
			Dir.Z = 0;
		}
		if ( D > 0.7 * SwapDropDist && D <= SwapDropDist )
		{
			Destination = Pawn.Location;
			return true;
		}
		Destination = SwapPickup.Location + Normal(Dir) * SwapDropDist;
		Destination.Z = Pawn.Location.Z;
		return pointReachable(Destination);
	}
Begin:
	WaitForLanding();
	SwapBestDist = 1000000.f;
	SwapStalls = 0;
Moving:
	if ( !KeepGoing() )
	{
		NextSwapCheckTime = Level.TimeSeconds + 6.f;
		WhatToDoNext(60);
	}
	else if ( CanReach(SwapPickup) && DropSpot() )
	{
		if ( VSize(Destination - Pawn.Location) > 16.f )
			MoveTo(Destination, SwapPickup);
		if ( SwapPickup != None && !SwapPickup.bDeleteMe && DropForSwap() )
			MoveToward(SwapPickup, SwapPickup);
		NextSwapCheckTime = Level.TimeSeconds + 6.f;
		WhatToDoNext(61);
	}
	else if ( FindBestPathToward(SwapPickup, true, false) )
	{
		MoveToward(MoveTarget, FaceActor(1),, ShouldStrafeTo(MoveTarget));
		Goto('Moving');
	}
	else
	{
		NextSwapCheckTime = Level.TimeSeconds + 6.f;
		WhatToDoNext(62);
	}
}

state Roaming
{
    ignores EnemyNotVisible;

    function BeginState()
    {
        Super.BeginState();
        SetBotSprinting(true);
    }
    function MayFall()
    {
        Super.MayFall();
        PitCheckFall();
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
				if ( TeleportUnseen(FindNavNear(Squad.SquadLeader.Pawn)) )
				{
					log(self$" Roaming failed, teleporting near squad leader");
				}
				else if (RouteCache[1] != None)
					TeleportUnseen(NavigationPoint(RouteCache[1]));
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
				if ( TeleportUnseen(FindNavNear(Squad.SquadLeader.Pawn)) )
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
	SwapSearchDist=400.000000
	SwapDropDist=110.000000
	SwapMinGain=0.050000
	bPerkSwitching=True
	bLateZerkSwap=True
	bPostNades=True
	bMedicCrowdHeal=True
	MedicHealCrowd=3
	FragReserve=2
	MedicHealReach=300.000000
	MedicHealDist=1000.000000
	PerkStay=0.400000
	PerkMedicNeed=0.500000
	PerkCrowd=0.150000
	PerkSwitchGap=90.000000
	bCrowdEscape=True
	CrowdSenseDist=1500.000000
	CrowdRadius=700.000000
	CrowdAllyDist=900.000000
	CrowdEnterPressure=4.000000
	PincerRadius=600.000000
	PincerNear=450.000000
	EscapeSearchDist=2500.000000
	EscapeDangerCost=300.000000
	EscapeDeadEnd=0.600000
	EscapeAllyPull=0.600000
	EscapeFrontBonus=0.400000
	EscapeMaxTime=4.000000
	EscapeCooldown=1.000000
	EscapeSpawnPenalty=0.800000
	EscapeSpawnDist=800.000000
	EscapeSpawnRecent=15.000000
	EscapeMinMargin=1.000000
	EscapeMaxNodes=64
	AnchorLostLimit=10.000000
	HoldReach=120.000000
	bHoldSpots=True
	bLedgeJump=True
	HoldNoWayRest=5.000000
	bHumanOrdersFirst=True
	HoldQuietTime=15.000000
	HoldEarlyTime=30.000000
	HoldGlanceShare=0.250000
	bZerkBile=True
	bZerkRhythm=True
	bZerkGun=True
	bTacticalReload=True
	bFragFP=True
	bAmmoRun=True
	bRetreatToTeam=True
	bAnswerCalls=True
	bHumanFirst=True
	bPitAware=True
	bNoStrayBlades=True
	bBuyOffListAmmo=True
	bSirenAware=True
	bScrakeFocus=True
	bRocketBig=True
}
