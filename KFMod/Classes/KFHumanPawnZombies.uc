//=============================================================================
// KFPawn - Assault
//=============================================================================
class KFHumanPawnZombies extends KFHumanPawn;

var() float RegenDelay, RegenRate;

var float RegenAccumulator;

var bool bQuickMeleeing, bStaminaExhausted;
var() float QuickMeleeTimeout;
var float QuickMeleeTimeoutTime;

var() int MaxPrimaryWeapons;

var() float SwapConfirmWindow;
var() string SwapPromptMessage, RevivePromptMessage, SelfReviveMessage;
var Class<Weapon> PendingSwapWeaponClass;
var float PendingSwapExpireTime;

var() float ZombiesViewBobWalkMulti, ZombiesViewBobSprintMulti, ZombiesViewBobVertBias , MaxViewBobOffset;

var() float MaxStamina, StaminaDrainRate, StaminaRegenRate, StaminaRegenDelay, StaminaExhaustRecoverPct;
var float CurrentStamina;

var float LastSprintStopTime, LastDamageTime;

var() float ReviveHoldGrace, SelfReviveDuration, QuickReviveScale, RevivePromptInterval;
var float BleedoutTimeLeft, LastReviveUseTime, NextRevivePromptTime;
var bool bSelfReviving;
var byte BleedoutByte, ReviveByte;

var() float SpeedColaReloadScale, DoubleTapFireScale, StaminUpSprintScale, StaminUpStaminaScale;
var float PerkHealthBonus;

var string UsePrompt;
var float UsePromptExpireTime;

replication
{
	reliable if( bNetDirty && (Role==ROLE_Authority) && bNetOwner )
		CurrentStamina, bStaminaExhausted, UsePrompt;

	reliable if( bNetDirty && (Role==ROLE_Authority) )
		bSelfReviving, BleedoutByte, ReviveByte, PerkHealthBonus;
}

function CheckBob(float DeltaTime, vector Y)
{
	local float ScaleMulti, BobMag;

	Super.CheckBob(DeltaTime, Y);

	if( Physics == PHYS_Falling )
	{
		WalkBob = vect(0,0,0);
		Return;
	}

	if( bIsSprinting )
		ScaleMulti = ZombiesViewBobSprintMulti;
	else
		ScaleMulti = ZombiesViewBobWalkMulti;

	WalkBob.X *= ScaleMulti;
	WalkBob.Y *= ScaleMulti;
	WalkBob.Z *= ScaleMulti * ZombiesViewBobVertBias;

	BobMag = VSize(WalkBob);
	if( BobMag > MaxViewBobOffset )
		WalkBob = WalkBob * (MaxViewBobOffset / BobMag);
}

function bool MaySprint()
{
	return !(bIsDowned || bStaminaExhausted || CurrentStamina<=0);
}

simulated function StartSprintKF()
{
	if( bIsDowned || bStaminaExhausted || CurrentStamina<=0 )
		Return;
	Super.StartSprintKF();
}

function ServerStartSprintKF()
{
	if( bIsDowned || bStaminaExhausted || CurrentStamina<=0 )
	{
		ClientSprintDenied();
		Return;
	}
	Super.ServerStartSprintKF();
}

simulated function StopSprintKF()
{
	if( bIsSprinting )
		LastSprintStopTime = Level.TimeSeconds;
	Super.StopSprintKF();
}

function ServerStopSprintKF()
{
	if( bIsSprinting )
		LastSprintStopTime = Level.TimeSeconds;
	Super.ServerStopSprintKF();
}

function UpdateStamina( float DeltaTime )
{
	local float Drain;

	if( bIsSprinting )
	{
		Drain = StaminaDrainRate;
		if( HasStaminUp() )
			Drain /= StaminUpStaminaScale;
		CurrentStamina = FMax(CurrentStamina - Drain*DeltaTime, 0);
		if( CurrentStamina<=0 )
		{
			bStaminaExhausted = true;
			bIsSprinting = false;
			LastSprintStopTime = Level.TimeSeconds;
		}
	}
	else if( CurrentStamina<MaxStamina && Level.TimeSeconds-LastSprintStopTime>=StaminaRegenDelay )
	{
		CurrentStamina = FMin(CurrentStamina + StaminaRegenRate*DeltaTime, MaxStamina);
		if( bStaminaExhausted && CurrentStamina>=MaxStamina*StaminaExhaustRecoverPct )
			bStaminaExhausted = false;
	}
}

simulated function bool HasStaminUp()
{
	Return KFPlayerReplicationInfo(PlayerReplicationInfo)!=None && KFPlayerReplicationInfo(PlayerReplicationInfo).bHasStaminUp;
}

simulated function float GetFireSpeedScale()
{
	if( KFPlayerReplicationInfo(PlayerReplicationInfo)!=None && KFPlayerReplicationInfo(PlayerReplicationInfo).bHasDoubleTap )
		Return DoubleTapFireScale;
	Return 1;
}

simulated function float GetReloadSpeedScale()
{
	if( KFPlayerReplicationInfo(PlayerReplicationInfo)!=None && KFPlayerReplicationInfo(PlayerReplicationInfo).bHasSpeedCola )
		Return SpeedColaReloadScale;
	Return 1;
}

simulated event ModifyVelocity(float DeltaTime, vector OldVelocity)
{
	if( HasStaminUp() )
		SprintMulti = Default.SprintMulti*StaminUpSprintScale;
	else
		SprintMulti = Default.SprintMulti;

	Super.ModifyVelocity(DeltaTime, OldVelocity);
}

function SetPerkHealthBonus( float Bonus )
{
	Health += Bonus - PerkHealthBonus;
	PerkHealthBonus = Bonus;
	HealthMax = Default.HealthMax + PerkHealthBonus;
}

function SetUsePrompt( string S )
{
	if( UsePrompt!=S )
		UsePrompt = S;
	UsePromptExpireTime = Level.TimeSeconds + 1.0;
}

simulated function KnifeZombies FindKnife()
{
	local Inventory inv;

	For( inv=Inventory; inv!=None; inv=inv.Inventory )
	{
		if( KnifeZombies(inv)!=None )
			Return KnifeZombies(inv);
	}
	Return None;
}

simulated exec function QuickMelee()
{
	local KFWeapon W;

	if( bIsDowned || bQuickMeleeing || bThrowingNade || Health<=0 || PendingWeapon!=None || SecondaryItem!=None || FindKnife()==None )
		Return;

	W = KFWeapon(Weapon);
	if( W==None || (W.ClientState!=WS_ReadyToFire && W.ClientState!=WS_BringUp)
	 || W.GetFireMode(0).NextFireTime - Level.TimeSeconds > 0.1
	 || (W.bIsReloading && !W.InterruptReload()) )
		Return;

	W.ClientGrenadeState = GN_TempDown;
	if( !W.PutDown() || W.ClientState!=WS_PutDown )
	{
		W.ClientGrenadeState = GN_None;
		Return;
	}

	bQuickMeleeing = true;
	QuickMeleeTimeoutTime = Level.TimeSeconds + QuickMeleeTimeout;
}

function WeaponDown()
{
	local KnifeZombies K;

	if( bQuickMeleeing )
	{
		K = FindKnife();
		if( K!=None )
		{
			SecondaryItem = K;
			K.StartStab();
			Return;
		}
		bQuickMeleeing = false;
	}

	Super.WeaponDown();
}

simulated function QuickMeleeFinished()
{
	SecondaryItem = None;
	if( KFWeapon(Weapon)!=None )
		KFWeapon(Weapon).ClientGrenadeState = GN_BringUp;
	if( Weapon!=None )
		Weapon.BringUp();
	bQuickMeleeing = false;
}

function ThrowGrenade()
{
	if( bIsDowned || bQuickMeleeing )
		Return;
	Super.ThrowGrenade();
}

function bool IsPrimaryWeaponSlot( KFWeapon W )
{
	return W!=None && Single(W)==None && Dualies(W)==None && !W.bIsGrenadeWeapon && KFMeleeGun(W)==None;
}

function bool IsPrimaryWeaponClass( class<KFWeapon> WC )
{
	return WC!=None && !ClassIsChildOf(WC, Class'Single') && !ClassIsChildOf(WC, Class'Dualies')
	 && !WC.Default.bIsGrenadeWeapon && !ClassIsChildOf(WC, Class'KFMeleeGun');
}

function int CountPrimaryWeapons()
{
	local Inventory I;
	local int Count;

	For( I=Inventory; I!=None; I=I.Inventory )
		if( IsPrimaryWeaponSlot(KFWeapon(I)) )
			Count++;
	Return Count;
}

function KFWeapon GetSwapCandidate()
{
	local Inventory I;

	if( IsPrimaryWeaponSlot(KFWeapon(Weapon)) )
		Return KFWeapon(Weapon);
	For( I=Inventory; I!=None; I=I.Inventory )
		if( IsPrimaryWeaponSlot(KFWeapon(I)) )
			Return KFWeapon(I);
	Return None;
}

function bool AddInventory( inventory NewItem )
{
	Return Super(KFPawn).AddInventory(NewItem);
}

function DeleteInventory( inventory Item )
{
	Super(KFPawn).DeleteInventory(Item);
}

function bool CanCarry( float Weight )
{
	Return CountPrimaryWeapons() < MaxPrimaryWeapons;
}

function bool PurchaseWeapon( Class<Weapon> WClass, float Price, optional bool bForceSwap )
{
	local Inventory I;
	local KFWeapon OldWeapon;

	if( PlayerReplicationInfo==None || Class<KFWeapon>(WClass)==None || PlayerReplicationInfo.Score<Price )
		Return False;

	For( I=Inventory; I!=None; I=I.Inventory )
		if( I.Class==WClass )
			Return False;

	if( !IsPrimaryWeaponClass(Class<KFWeapon>(WClass)) || CountPrimaryWeapons()<MaxPrimaryWeapons )
	{
		PendingSwapWeaponClass = None;
		Return GiveBoughtWeapon(WClass, Price);
	}

	OldWeapon = GetSwapCandidate();
	if( OldWeapon==None )
		Return False;

	if( bForceSwap || (PendingSwapWeaponClass==WClass && Level.TimeSeconds<PendingSwapExpireTime) )
	{
		PendingSwapWeaponClass = None;
		OldWeapon.Destroyed();
		OldWeapon.Destroy();
		Return GiveBoughtWeapon(WClass, Price);
	}

	PendingSwapWeaponClass = WClass;
	PendingSwapExpireTime = Level.TimeSeconds + SwapConfirmWindow;
	if( PlayerController(Controller)!=None && SwapPromptMessage!="" )
		PlayerController(Controller).ClientMessage(SwapPromptMessage, 'CriticalEvent');
	Return False;
}

function bool GiveBoughtWeapon( Class<Weapon> WClass, float Price )
{
	local Inventory I;

	I = Spawn(WClass);
	if( I==None )
		Return False;

	KFWeapon(I).UpdateMagCapacity(PlayerReplicationInfo);
	KFWeapon(I).FillToInitialAmmo();
	I.GiveTo(self);
	PlayerReplicationInfo.Score-=Price;
	Return True;
}

simulated function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
	if( bIsDowned )
		Return;
	LastDamageTime = Level.TimeSeconds;
	Super.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType);
}

//Hehehehe COD style revive system
function GoDowned( optional bool bSelfRevive )
{
	local KFPlayerReplicationInfo KFPRI;

	if( bIsDowned )
		Return;

	bIsDowned = true;
	Health = 1;
	BleedoutTimeLeft = DownedBleedoutTime;
	BleedoutByte = 255;
	bBeingRevived = false;
	bSelfReviving = bSelfRevive;
	Reviver = None;
	ReviveProgress = 0;
	ReviveByte = 0;
	bIsSprinting = false;
	bAlwaysRelevant = true;
	NetUpdateTime = Level.TimeSeconds - 1;

	KFPRI = KFPlayerReplicationInfo(PlayerReplicationInfo);
	if( KFPRI!=None )
		KFPRI.bIsDowned = true;

	if( PlayerController(Controller)!=None )
	{
		if( bSelfReviving && SelfReviveMessage!="" )
			PlayerController(Controller).ClientMessage(SelfReviveMessage, 'CriticalEvent');
		else if( DownedMessage!="" )
			PlayerController(Controller).ClientMessage(DownedMessage, 'CriticalEvent');
	}
	if( DownedSound!=None )
		PlaySound(DownedSound,,255,,300);

	FreezeDownedAnim();
	BreakMonsterLocksOnMe();
}

//Hack to make sure monsters don't keep attacking a downed player
function BreakMonsterLocksOnMe()
{
	local Controller C;
	local KFMonsterController MC;

	for ( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		MC = KFMonsterController(C);
		if ( MC!=None && (MC.Enemy==Self || MC.Target==Self) )
		{
			MC.Enemy = None;
			MC.Target = None;
		}
	}
}

simulated function FreezeDownedAnim()
{
	if( HasAnim('DeathF') )
	{
		PlayAnim('DeathF', 0.0, 0.0);
		SetAnimFrame(0.44);
	}
}

function bool IsValidReviver( Pawn P )
{
	Return P!=None && P!=Self && P.Health>0 && KFHumanPawn(P)!=None && !KFHumanPawn(P).bIsDowned
	 && VSize(P.Location-Location)<=ReviveRadius;
}

function float GetReviveDuration( Pawn P )
{
	if( P!=None && KFPlayerReplicationInfo(P.PlayerReplicationInfo)!=None && KFPlayerReplicationInfo(P.PlayerReplicationInfo).bHasQuickRevive )
		Return ReviveDuration*QuickReviveScale;
	Return ReviveDuration;
}

function AccumulateRevive( Pawn user )
{
	if( !bIsDowned || bSelfReviving || Health<=0 || !IsValidReviver(user) )
		Return;

	if( bBeingRevived && Reviver!=user && IsValidReviver(Reviver) && Level.TimeSeconds-LastReviveUseTime<=ReviveHoldGrace )
		Return;

	if( !bBeingRevived || Reviver!=user )
	{
		Reviver = user;
		bBeingRevived = true;
		ReviveProgress = 0;
		if( PlayerController(user.Controller)!=None && ReviveStartMessage!="" )
			PlayerController(user.Controller).ClientMessage(ReviveStartMessage, 'CriticalEvent');
	}
	LastReviveUseTime = Level.TimeSeconds;
}

function StopRevive()
{
	if( Reviver!=None && PlayerController(Reviver.Controller)!=None && ReviveInterruptedMessage!="" )
		PlayerController(Reviver.Controller).ClientMessage(ReviveInterruptedMessage, 'CriticalEvent');

	bBeingRevived = false;
	Reviver = None;
	ReviveProgress = 0;
}

function ForceBleedOut()
{
	bBeingRevived = false;
	Reviver = None;
	ReviveProgress = 0;
	BleedoutTimeLeft = 0;
}

function Revive()
{
	local KFPlayerReplicationInfo KFPRI;
	local Pawn OldReviver;

	if( !bIsDowned )
		Return;

	OldReviver = Reviver;

	bIsDowned = false;
	Health = DownedRevivedHealth;
	bBeingRevived = false;
	Reviver = None;
	ReviveProgress = 0;
	ReviveByte = 0;
	bAlwaysRelevant = Default.bAlwaysRelevant;
	LastDamageTime = Level.TimeSeconds;
	NetUpdateTime = Level.TimeSeconds - 1;

	KFPRI = KFPlayerReplicationInfo(PlayerReplicationInfo);
	if( KFPRI!=None )
	{
		KFPRI.bIsDowned = false;
		if( bSelfReviving )
			KFPRI.bHasQuickRevive = false;
	}
	bSelfReviving = false;

	if( PlayerController(Controller)!=None && RevivedMessage!="" )
		PlayerController(Controller).ClientMessage(RevivedMessage, 'CriticalEvent');
	if( RevivedSound!=None )
		PlaySound(RevivedSound,,255,,300);

	if( OldReviver!=None && KFZombiesGameType(Level.Game)!=None )
		KFZombiesGameType(Level.Game).NotifyRevived(Self, OldReviver);
}

function BleedOut()
{
	if( !bIsDowned || Health<=0 )
		Return;

	Health = 0;
	Died(Controller, class'DamTypeBleedOut', Location);
}

function PromptNearbyRevivers()
{
	local KFHumanPawnZombies P;
	local string S;

	if( Level.TimeSeconds<NextRevivePromptTime )
		Return;
	NextRevivePromptTime = Level.TimeSeconds + RevivePromptInterval;

	S = RevivePromptMessage;
	if( PlayerReplicationInfo!=None )
		S = S @ PlayerReplicationInfo.PlayerName;

	ForEach VisibleCollidingActors(class'KFHumanPawnZombies', P, ReviveRadius)
	{
		if( P!=Self && P.Health>0 && !P.bIsDowned && (!bBeingRevived || Reviver!=P) )
			P.SetUsePrompt(S);
	}
}

function UpdateDowned( float DeltaTime )
{
	if( Health<=0 )
		Return;

	if( bSelfReviving )
	{
		ReviveProgress += DeltaTime;
		ReviveByte = byte(FClamp(ReviveProgress/SelfReviveDuration, 0.0, 1.0)*255);
		if( ReviveProgress>=SelfReviveDuration )
			Revive();
		Return;
	}

	if( bBeingRevived )
	{
		if( !IsValidReviver(Reviver) || Level.TimeSeconds-LastReviveUseTime>ReviveHoldGrace )
			StopRevive();
		else
		{
			ReviveProgress += DeltaTime;
			if( ReviveProgress>=GetReviveDuration(Reviver) )
			{
				Revive();
				Return;
			}
		}
	}
	else
	{
		BleedoutTimeLeft -= DeltaTime;
		if( BleedoutTimeLeft<=0 )
		{
			BleedOut();
			Return;
		}
	}

	if( bBeingRevived )
		ReviveByte = byte(FClamp(ReviveProgress/GetReviveDuration(Reviver), 0.0, 1.0)*255);
	else
		ReviveByte = 0;
	BleedoutByte = byte(FClamp(BleedoutTimeLeft/DownedBleedoutTime, 0.0, 1.0)*255);

	PromptNearbyRevivers();
}

function UpdateRegen( float DeltaTime )
{
	if( !bIsDowned && Health>0 && Health<HealthMax && Level.TimeSeconds-LastDamageTime>=RegenDelay )
	{
		RegenAccumulator += RegenRate*DeltaTime;
		if( RegenAccumulator>=1.0 )
		{
			Health = Min(int(HealthMax), Health + int(RegenAccumulator));
			RegenAccumulator -= int(RegenAccumulator);
		}
	}
	else
	{
		RegenAccumulator = 0;
	}
}

simulated function Fire( optional float F )
{
	if( bIsDowned )
		Return;
	Super.Fire(F);
}

simulated function AltFire( optional float F )
{
	if( bIsDowned )
		Return;
	Super.AltFire(F);
}

Simulated function Tick(float DeltaTime)
{
	local name CurSeq;
	local float CurFrame, CurRate;

	Super.Tick(DeltaTime);

	if (bIsDowned)
	{
		GetAnimParams(0, CurSeq, CurFrame, CurRate);
		if (CurSeq != 'DeathF' || CurFrame < 1.0)
			FreezeDownedAnim();
	}

	if (bQuickMeleeing && Level.TimeSeconds > QuickMeleeTimeoutTime)
		QuickMeleeFinished();

	if (Role < ROLE_Authority)
	{
		HealthMax = Default.HealthMax + PerkHealthBonus;
		Return;
	}

	if (UsePrompt != "" && Level.TimeSeconds > UsePromptExpireTime)
		UsePrompt = "";

	if (bIsDowned)
		UpdateDowned(DeltaTime);

	UpdateRegen(DeltaTime);
	UpdateStamina(DeltaTime);
}

simulated function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	local KFPlayerReplicationInfo KFPRI;

	KFPRI = KFPlayerReplicationInfo(PlayerReplicationInfo);

	Super.Died(Killer, damageType, HitLocation);

	if( Health>0 )
		Return;

	if( KFPRI!=None )
	{
		KFPRI.bIsDowned = false;
		KFPRI.ClearZombiesPerks();
	}
	bIsDowned = false;
	bBeingRevived = false;
	bSelfReviving = false;
	bQuickMeleeing = false;
	Reviver = None;
	UsePrompt = "";
}

defaultproperties
{
	BreathingSound=None
	DownedBleedoutTime=45.000000
	DownedRevivedHealth=50.000000
	DownedSpeedScale=0.200000
	ReviveDuration=4.000000
	ReviveRadius=110.000000
	ReviveHoldGrace=0.400000
	RevivePromptInterval=0.300000
	SelfReviveDuration=8.000000
	QuickReviveScale=0.500000
	DownedMessage="You're down! Wait for a teammate to revive you."
	RevivedMessage="You're back up!"
	ReviveStartMessage="Reviving..."
	ReviveInterruptedMessage="Revive cancelled."
	RevivePromptMessage="Hold [USE] to revive"
	SelfReviveMessage="You're down! Quick Revive is getting you back up."
	RegenDelay=5.000000
	RegenRate=10.000000
	RequiredEquipment(0)="KFMod.KnifeZombies"
	RequiredEquipment(1)="KFMod.SingleZombies"
	RequiredEquipment(2)="KFMod.Frag"
	RequiredEquipment(3)=""
	RequiredEquipment(4)=""
	SprintMulti=1.500000
	HealthSpeedModifier=0.000000
	MaxPrimaryWeapons=2
	SwapConfirmWindow=5.000000
	SwapPromptMessage="[USE] again to swap out the weapon you're holding"
	QuickMeleeTimeout=1.500000
	ZombiesViewBobWalkMulti=0.350000
	ZombiesViewBobSprintMulti=1.800000
	ZombiesViewBobVertBias=1.300000
	MaxViewBobOffset=14.000000
	MaxStamina=100.000000
	CurrentStamina=100.000000
	StaminaDrainRate=25.000000
	StaminaRegenRate=50.000000
	StaminaRegenDelay=1.000000
	StaminaExhaustRecoverPct=0.500000
	SpeedColaReloadScale=1.600000
	DoubleTapFireScale=1.330000
	StaminUpSprintScale=1.150000
	StaminUpStaminaScale=2.000000
}
