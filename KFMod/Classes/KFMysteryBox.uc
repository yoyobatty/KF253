class KFMysteryBox extends KFZombiesUsable
	placeable;

var() array<class<KFWeaponPickup> > PossibleWeapons;
var() int Cost;
var() float SpinDuration;
var() float SpinMeshInterval;
var() float RiseHeight;   // How high the won weapon floats up while waiting to be grabbed.
var() float RiseDuration; // Seconds the rise animation takes.
var() float OwnerGrabTime, WonTimeout;
var() StaticMesh BoxMesh; // Idle appearance between uses.
var() sound SpinSound, SpinOpenSound;
var() string NotEnoughPointsMessage, AlreadySpinningMessage, CantCarryMessage, NotYoursMessage, AlreadyOwnedMessage;

var bool bSpinning;
var int CurrentSpinIndex;
var class<KFWeaponPickup> WonWeaponClass;
var float SpinEndTime, NextSpinMeshTime, WonTime;
var Pawn SpinningUser;
var vector RestLocation;
var float RiseElapsed;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	RestLocation = Location;
	SetDrawType(DT_StaticMesh);
	if( BoxMesh!=None )
		SetStaticMesh(BoxMesh);
	bHidden = true;
}

function bool HasWeapon( Pawn P, class<Weapon> WClass )
{
	local Inventory Inv;

	if( P==None || WClass==None )
		Return false;

	For( Inv=P.Inventory; Inv!=None; Inv=Inv.Inventory )
	{
		if( Inv.Class==WClass )
			Return true;
	}
	Return false;
}

function bool CanGrab( Pawn P )
{
	Return P==SpinningUser || SpinningUser==None || SpinningUser.Health<=0 || Level.TimeSeconds-WonTime>=OwnerGrabTime;
}

function string GetPrompt( Pawn P )
{
	if( IsInState('Won') )
	{
		if( WonWeaponClass!=None && CanGrab(P) )
			Return "[USE] to grab" @ WonWeaponClass.Default.ItemName;
		Return "";
	}
	if( bSpinning )
		Return "";
	Return "[USE] Buy Mystery Weapon -" @ Cost;
}

function class<KFWeaponPickup> PickWeaponFor( Pawn P )
{
	local array<class<KFWeaponPickup> > Pool;
	local int i;

	For( i=0; i<PossibleWeapons.Length; i++ )
	{
		if( PossibleWeapons[i]!=None && !HasWeapon(P, class<Weapon>(PossibleWeapons[i].Default.InventoryType)) )
			Pool[Pool.Length] = PossibleWeapons[i];
	}

	if( Pool.Length==0 )
		Return PossibleWeapons[Rand(PossibleWeapons.Length)];
	Return Pool[Rand(Pool.Length)];
}

function UsedBy( Pawn user )
{
	if( !IsValidUser(user) || PlayerController(user.Controller)==None )
		Return;

	if( IsInState('Won') )
	{
		TryGrab(user);
		Return;
	}

	if( bSpinning )
	{
		Notify(user, AlreadySpinningMessage);
		Return;
	}

	if( PossibleWeapons.Length==0 )
	{
		Warn(Self $ ": PossibleWeapons is empty - this mystery box was placed without any weapons configured.");
		Return;
	}

	if( !CanUseNow(user) )
		Return;

	if( !Charge(user, Cost) )
	{
		Notify(user, NotEnoughPointsMessage);
		Return;
	}

	SpinningUser = user;
	bSpinning = true;
	GotoState('Spinning');
}

function TryGrab( Pawn user )
{
	local class<Weapon> WClass;
	local KFPawn KFP;

	KFP = KFPawn(user);
	if( KFP==None || WonWeaponClass==None )
		Return;

	if( !CanGrab(user) )
	{
		Notify(user, NotYoursMessage);
		Return;
	}

	WClass = class<Weapon>(WonWeaponClass.Default.InventoryType);
	if( WClass==None )
	{
		ResetBox();
		Return;
	}

	if( HasWeapon(user, WClass) )
	{
		Notify(user, AlreadyOwnedMessage);
		Return;
	}

	if( !KFP.PurchaseWeapon(WClass, 0, true) )
	{
		Notify(user, CantCarryMessage);
		Return;
	}

	ResetBox();
}

function ResetBox()
{
	bSpinning = false;
	SpinningUser = None;
	WonWeaponClass = None;
	SetLocation(RestLocation);
	if( BoxMesh!=None )
		SetStaticMesh(BoxMesh);
	bHidden = true;
	NetUpdateTime = Level.TimeSeconds - 1;
	GotoState('');
}

state Spinning
{
	function BeginState()
	{
		bHidden = false;
		SpinEndTime = Level.TimeSeconds + SpinDuration;
		NextSpinMeshTime = 0;
		NetUpdateTime = Level.TimeSeconds - 1;
		PlaySound(SpinOpenSound,SLOT_None,255,True);
		PlaySound(SpinSound,SLOT_None,255,True);
	}

	function Tick( float DeltaTime )
	{
		if( Level.TimeSeconds>=NextSpinMeshTime )
		{
			NextSpinMeshTime = Level.TimeSeconds + SpinMeshInterval;
			CurrentSpinIndex = (CurrentSpinIndex+1) % PossibleWeapons.Length;
			if( PossibleWeapons[CurrentSpinIndex]!=None )
				SetStaticMesh(PossibleWeapons[CurrentSpinIndex].Default.StaticMesh);
		}

		if( Level.TimeSeconds>=SpinEndTime )
		{
			WonWeaponClass = PickWeaponFor(SpinningUser);
			if( WonWeaponClass==None )
				ResetBox();
			else
				GotoState('Won');
		}
	}
}

state Won
{
	// Won weapon rises out of the box and waits there until the player
	// presses [USE] to grab it.
	function BeginState()
	{
		SetStaticMesh(WonWeaponClass.Default.StaticMesh);
		RiseElapsed = 0.0;
		WonTime = Level.TimeSeconds;
	}

	function Tick( float DeltaTime )
	{
		local float Alpha;

		if( RiseElapsed<RiseDuration )
		{
			RiseElapsed += DeltaTime;
			Alpha = FClamp(RiseElapsed/RiseDuration, 0.0, 1.0);
			SetLocation(RestLocation + vect(0,0,1)*RiseHeight*Alpha);
		}

		if( Level.TimeSeconds-WonTime>=WonTimeout )
			ResetBox();
	}
}

defaultproperties
{
	Cost=950
	SpinDuration=4.000000
	SpinMeshInterval=0.150000
	RiseHeight=64.000000
	RiseDuration=1.000000
	OwnerGrabTime=8.000000
	WonTimeout=12.000000
	RefireDelay=0.500000
	DrawType=DT_StaticMesh
	NotEnoughPointsMessage="Not enough dosh."
	AlreadySpinningMessage="Someone is already using the mystery box."
	CantCarryMessage="You can't carry that."
	NotYoursMessage="That weapon isn't yours yet."
	AlreadyOwnedMessage="You already have that weapon."
	RemoteRole=ROLE_DumbProxy
	bAlwaysRelevant=True
	DrawScale=0.700000
	SpinSound=Sound'CODSounds.1s_musicbox01'
	SpinOpenSound=Sound'CODSounds.1s_musicboxopen01'
}
