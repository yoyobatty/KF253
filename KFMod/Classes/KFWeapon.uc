class KFWeapon extends Weapon
	abstract;

var()   vector FirstPersonFlashlightOffset;	

var() int ClipCount; // How Much ammo this weapon can hold in its magazine
var() float ReloadRate;
var float ReloadTimer;
var int ClipLeft; // How Much ammo is left in the magazine
var bool bzoomed;
var float ZoomLevel;
var Bool bSpeedMeUp;

var() sound ReloadBeginSound, ReloadSound, ReloadEndSound, ToggleSound;
var() name ReloadAnim;
var() float ReloadAnimRate;
var() bool bHoldToReload;

var bool bDoSingleReload;        // The reload key has been released, but no rounds were added yet

var name FlashBoneName;
var name WeaponReloadAnim;

var () int MinimumFireRange; // Minimum distance to fire ...for avoiding LAW / Flamethrower casualties specifically.

var () name ModeSwitchAnim;

var () material HudImage; // What to display on the HUD, when this weapon is selected.

var Name IdleAimAnim;

var bool bSteadyAim;  // If Flicked,  this weapon's accuracy is not affected by Movement.

//var() float HealRate;
//var transient float HealAccum;


// Zoomshit
var transient float LastFOV,ZoomingInTimer;
var bool zoomed;
var Bool bZooming;

var         bool            bModeZeroCanDryFire;        // FireMode zero can dry fire/cause a reload

var bool bIsReloading, bReloadEffectDone;

var () float Weight; // how much does it weigh

var bool bKFNeverThrow;

var() bool bIsGrenadeWeapon;

var bool bAmmoHUDAsBar;

var bool bUseCombos; // Disable combos for the time being...Too iffy

var bool bNoHit; // Hack for Syringe / Welder. 

var () bool bTorchEnabled; // just a hook for the pawn, and his light.  Dualies and Single have this set to true. the other weapons dont.


var int StoppingPower; // How much each fire of the gun slows you down. Always in negative numbers.
var int UpKick;  // How much upkick each shot has.
var int SideKick; // How much horizontal (yaw) kick each shot has.

var bool bAimingRifle;

var () class<InventoryAttachment> TacShineClass;
var Actor TacShine;

var Effect_TacLightProjector FlashLight;

var float NextAmmoCheckTime,LastAmmoResult,LastHasGunMsgTime;

// Keep track of what this weapon is doing on the client while we are throwing a grenade
var() 		enum 			EClientGrenadeState
{
	GN_None,
	GN_TempDown,
	GN_BringUp,
} ClientGrenadeState; // this will always be none on the server

// === View turn inertia / sway (spring-physics, CoD-style) (Yes this is vibe-coded, I'm not smart enough to make this myself)===
// Core tunables
var() float LagPosStrength;      // Position responsiveness to angular velocity
var() float LagRotStrength;      // Rotation responsiveness
var() float LagSpringK;          // Pos spring stiffness
var() float LagSpringDamping;    // Pos spring damping
var() float RotSpringK;          // Rot spring stiffness
var() float RotSpringDamping;    // Rot spring damping
var() float FlickThresholdDegPerSec;
var() float FlickImpulsePos;
var() float FlickImpulseRot;
var() float BreathAmplitude;     // Vertical breathing offset
var() float BreathPitchAmplitude;
var() float BreathFreq;
var() float MoveBobAmp;
var() float MoveBobFreq;
var() float MoveBobYawRot;
var() float MoveBobPitchRot;
var() float MoveBobRollRot;          // Roll tilt per bob cycle (side-to-side rock)
var() float MoveBobSprintMulti;      // Bob amplitude multiplier when sprinting
var() float MoveBobHorizScale;       // Horizontal bob relative to vertical (figure-8)
var() float MoveBobVertScale;
var() float StrafeRollStrength;      // Roll lean from strafing (degrees at full strafe)
var() float StrafePosStrength;       // Lateral position shift from strafing
var() float StrafeLeanSpeed;         // How fast lean blends in/out
var() float MoveReactStrength;       // Weapon reacts to velocity changes (acceleration)
var() float JumpKickPos;             // Positional impulse on jump (weapon drops back)
var() float JumpKickRot;             // Rotational impulse on jump (pitch up)
var() float LandKickPos;             // Positional impulse on landing (weapon slams down)
var() float LandKickRot;             // Rotational impulse on landing (pitch forward)
var() float LandKickSpeedScale;      // Scale land kick by fall speed (0=fixed, 1=fully proportional)
var() float ViewLagMaxOffset;    // Clamp positional offset magnitude

// Runtime state
var rotator PrevViewRot;
var rotator PrevViewPunch;             // View punch that was in PrevViewRot
var vector  VM_PosOffset, VM_PosVel;
var vector  VM_RotOffset, VM_RotVel;   // (Pitch,Yaw,Roll) in degrees
var float   LastMotionUpdateTime;
var float   BobPhase;                  // Bob cycle phase accumulator (radians)
var vector  PrevVelocity;              // Previous frame velocity for movement reaction

// Direct offsets (bypass spring entirely, applied in RenderOverlays)
var vector  BobPosOffset;              // Direct bob positional offset (local X,Y,Z)
var vector  BobRotOffset;              // Direct bob rotational offset (Pitch,Yaw,Roll) degrees
var float   StrafeRoll;                // Current strafe lean in degrees
var float   StrafeOffsetY;             // Current strafe lateral shift
var EPhysics  PrevPhysics;               // Previous frame physics for jump/land detection
var float   LastGroundAmpScale;
var float   BreathOffsetZ;
var float   BreathPitchOffset;

// === Wall offset (weapon pivots up near walls) ===
var float WallOffsetFactor, TargetWallOffsetFactor;
var() float GunLengthDist;
var() rotator WallPivotRot;
var() vector WallPivotOffset;

var float SprintFactor;
var() float SprintTransitionSpeed;
var() rotator SprintDownRot;
var() vector SprintDownOffset;
var() float ZombiesSprintBobMulti;
var bool bUpgraded;

replication
{
	//TODO - does ClipCount still need sending,
	// and does clipleft simulate sucessfully enough to not need repping?
	reliable if(Role == ROLE_Authority)
		ClipLeft;

	reliable if( bNetDirty && bNetOwner && (Role==ROLE_Authority) )
		ClipCount, bUpgraded;

	// TODO - which of these ACTUALLY need sending?
	reliable if(Role < ROLE_Authority)
		ReloadMeNow, finishReloading, recalcClipCount,ServerSetAiming, ServerSpawnLight, ServerRequestAutoReload,
		ServerInterruptReload;

	reliable if(Role == ROLE_Authority)
		ClientReload, ClientFinishReloading, ClientReloadEffects, FlashLight, 
		ClientInterruptReload, ClientForceKFAmmoUpdate;
}

simulated function PostBeginPlay()
{
	if (Level.GetLocalPlayerController() != None)
	{
		Level.GetLocalPlayerController().ConsoleCommand("nearclip 3");
	}

	Super.PostBeginPlay();

	// Initialize motion state
	if (Instigator != None)
		PrevViewRot = Instigator.GetViewRotation();
	PrevViewPunch = AppliedViewPunch();
	LastMotionUpdateTime = Level.TimeSeconds;
}

function bool HandlePickupQuery( pickup Item )
{
	if ( Item.InventoryType==Class )
	{
		if( LastHasGunMsgTime<Level.TimeSeconds && PlayerController(Instigator.Controller)!=none )
		{
			LastHasGunMsgTime = Level.TimeSeconds+0.5;
			PlayerController(Instigator.Controller).ReceiveLocalizedMessage(Class'KFMainMessages',1);
		}
		return true;
	}
	return Super.HandlePickupQuery(Item);
}

function LightFire()  //simulated
{
	ServerSpawnLight();
}

function ServerSpawnLight()
{
	if (!FireMode[0].bIsFiring && !bIsReloading)
      {
		if( FlashLight == None && KFHumanPawn(Owner).TorchBatteryLife >= 1 && KFHumanPawn(Owner).Health > 0 )
		{
			FlashLight = Spawn(class'Effect_TacLightProjector',Instigator);
			Flashlight.SetRelativeLocation(vect(-80,0,0));
			PlaySound(sound'KFWeaponSound.HuntingCrack',SLOT_Misc,100);
			PlayAnim(ModeSwitchAnim,FireMode[0].FireAnimRate,FireMode[0].TweenTime);
			FlashLight.bHasLight=!FlashLight.bHasLight;
		}
		else if( FlashLight != None )
		{
			FlashLight.bHasLight=!FlashLight.bHasLight;
			PlayAnim(ModeSwitchAnim,FireMode[0].FireAnimRate,FireMode[0].TweenTime);
			PlaySound(sound'KFWeaponSound.HuntingCrack',SLOT_Misc,100);
		}
	}
}

simulated event RenderOverlays( Canvas Canvas )
{
    local int m;
    local vector WeaponOffset;
    local rotator NewRotation, CenteredRotation, SprintRotScaled;
    local float PivotAmount;
	local vector X, Y, Z;

	GetViewAxes(X, Y, Z);

    if (Instigator == None)
        return;

	if ( Instigator.Controller != None )
		Hand = Instigator.Controller.Handedness;

    if ((Hand < -1.0) || (Hand > 1.0))
        return;

    // draw muzzleflashes/smoke for all fire modes so idle state won't
    // cause emitters to just disappear
    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if (FireMode[m] != None)
        {
            FireMode[m].DrawMuzzleFlash(Canvas);
        }
    }

    if ( class'PlayerController'.Default.bSmallWeapons )
        PlayerViewOffset = SmallViewOffset;
    else if ( Mesh == OldMesh )
        PlayerViewOffset = OldPlayerViewOffset;
    else
        PlayerViewOffset = Default.PlayerViewOffset;
    if ( Hand == 0 )
        PlayerViewOffset.Y = CenteredOffsetY;
    else
        PlayerViewOffset.Y *= Hand;

	// PivotAmount goes from 0 (far) to 1 (at wall)
	PivotAmount = 1.0 - WallOffsetFactor;
	UpdateWallOffset();
	// --- Pivot up and to the left as you get close to a wall ---
	WallPivotRot = default.WallPivotRot * PivotAmount;
	WallPivotOffset = default.WallPivotOffset * PivotAmount;
	SprintRotScaled = default.SprintDownRot * SprintFactor;
	WallPivotRot.Pitch += SprintRotScaled.Pitch;
	WallPivotRot.Yaw   += SprintRotScaled.Yaw;
	WallPivotRot.Roll  += SprintRotScaled.Roll;
	WallPivotOffset += default.SprintDownOffset * SprintFactor;
	WeaponOffset = (X*WallPivotOffset.X + Y*WallPivotOffset.Y + Z*WallPivotOffset.Z);

    WeaponOffset += VM_PosOffset + Z * BreathOffsetZ;
    WeaponOffset += X * BobPosOffset.X + Y * (BobPosOffset.Y + StrafeOffsetY) + Z * BobPosOffset.Z;

    SetLocation(Instigator.Location + Instigator.CalcDrawOffset(self) + WeaponOffset);

    // Final rotation (add dynamic rotation offset)
    if ( Hand == 0 )
    {
        CenteredRotation = Instigator.GetViewRotation();
        CenteredRotation.Yaw += CenteredYaw + WallPivotRot.Yaw;
        CenteredRotation.Roll = CenteredRoll + WallPivotRot.Roll;
        CenteredRotation.Pitch += WallPivotRot.Pitch;
        CenteredRotation.Pitch += int( (VM_RotOffset.X + BreathPitchOffset + BobRotOffset.X) * (65536.0/360.0) );
        CenteredRotation.Yaw  += int( (VM_RotOffset.Y + BobRotOffset.Y) * (65536.0/360.0) );
        CenteredRotation.Roll += int( (VM_RotOffset.Z + BobRotOffset.Z + StrafeRoll) * (65536.0/360.0) );
        SetRotation(CenteredRotation);
    }
    else
    {
        NewRotation = Instigator.GetViewRotation();
        NewRotation.Yaw += WallPivotRot.Yaw;
        NewRotation.Pitch += WallPivotRot.Pitch;
        NewRotation.Roll += WallPivotRot.Roll;
        NewRotation.Pitch += int( (VM_RotOffset.X + BreathPitchOffset + BobRotOffset.X) * (65536.0/360.0) );
        NewRotation.Yaw  += int( (VM_RotOffset.Y + BobRotOffset.Y) * (65536.0/360.0) );
        NewRotation.Roll += int( (VM_RotOffset.Z + BobRotOffset.Z + StrafeRoll) * (65536.0/360.0) );
        SetRotation(NewRotation);
    }
    bDrawingFirstPerson = true;
    Canvas.DrawActor(self, false, false, DisplayFOV);
    bDrawingFirstPerson = false;
    if ( Hand == 0 )
        PlayerViewOffset.Y = 0;
}

simulated function UpdateWallOffset()
{
    local vector TraceStart, TraceEnd, HitLocation, HitNormal;
    local actor HitActor;
    local float Dist;

    if (Instigator == None || !Instigator.IsHumanControlled())
    {
        TargetWallOffsetFactor = 1.0;
        return;
    }
    // Start from player's eye position
    TraceStart = Instigator.Location + Instigator.EyePosition();
    // Trace forward from view rotation
    TraceEnd = TraceStart + vector(Instigator.GetViewRotation()) * GunLengthDist;
    HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, false, vect(0,4,6));
    if (HitActor != None && HitActor != Instigator && BlockingVolume(HitActor) == None && Abs(HitNormal.Z) < 0.5)
    {
        Dist = VSize(HitLocation - TraceStart);
        TargetWallOffsetFactor = FClamp(Dist / GunLengthDist, 0.0, 1.0);
    }
    else
    {
        TargetWallOffsetFactor = 1.0;
    }
}

exec function ReloadMeNow()
{
	local float ReloadMulti;

	if(!AllowReload())
		return;
	if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
	{
		ReloadMulti = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(self);
	}
	else ReloadMulti = 1;
	if( KFPawn(Instigator)!=None )
		ReloadMulti *= KFPawn(Instigator).GetReloadSpeedScale();
	bIsReloading = true;
	ReloadTimer = Level.TimeSeconds;
	ReloadRate = Default.ReloadRate/ReloadMulti;
	PlaySound(ReloadBeginSound, SLOT_Misc, TransientSoundVolume,,TransientSoundRadius,ReloadMulti,false);
	ClientReload();
	Instigator.SetAnimAction(WeaponReloadAnim);
}

simulated function ClientReload()
{
	local float ReloadMulti;

	if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
	{
		ReloadMulti = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(self);
	}
	else ReloadMulti = 1;
	if( KFPawn(Instigator)!=None )
		ReloadMulti *= KFPawn(Instigator).GetReloadSpeedScale();
	bIsReloading = true;
	PlayAnim(ReloadAnim, ReloadAnimRate*ReloadMulti, 0.1);
}

// This function is borked. I think it's calcualting something
// best called numclips, but there is no numclips
// TODO - purge or correct any calls to this function
simulated function recalcClipCount(byte mode)
{
	ClipCount = default.ClipCount ;
	if(ammoAmount(mode) < default.ClipCount)
		clipCount = 1 ;
}

simulated function ClientReloadEffects(){}

// The empty sound if your out of ammo
simulated function Fire(float F)
{
	if( bModeZeroCanDryFire && ClipLeft < 1 && !bIsReloading &&
		FireMode[0].NextFireTime <= Level.TimeSeconds )
	{
		// We're dry, ask the server to autoreload
		ServerRequestAutoReload();

	}

	super.Fire(F);
}

// request an auto reload on the server - happens when the player dry fires
function ServerRequestAutoReload()
{
	if( AllowReload() )
	{
		ReloadMeNow();
		return;
	}
}

//// client & server ////
// Overriden to support interrupting reloads
simulated function bool StartFire(int Mode)
{
	local bool RetVal;

	if( KFHumanPawn(Instigator)!=None && KFHumanPawn(Instigator).bIsDowned )
		return false;

	RetVal = super.StartFire(Mode);

	if( RetVal )
	{
		InterruptReload();
	}

	return RetVal;
}

// Interrupt the reload for single bullet insert weapons
simulated function bool InterruptReload()
{
	if( bHoldToReload && bIsReloading )
	{
		ServerInterruptReload();

		if ( Level.NetMode != NM_StandAlone && (Level.NetMode != NM_ListenServer || !Instigator.IsLocallyControlled()) )
		{
			ClientInterruptReload();
		}

		return true;
	}

	return false;
}

simulated function ServerInterruptReload()
{
	bDoSingleReload = false;
	bIsReloading = false;
	bReloadEffectDone = false;
	PlayIdle();
}

// Server forces the reload to be cancelled
simulated function ClientInterruptReload()
{
	bIsReloading = false;
	PlayIdle();
}

exec function FinishReloading()
{
	if(!bIsReloading)
		return;
	if(bHoldToReload)
		ActuallyFinishReloading();
}

//We shouldn't allow finishreloading to finish reloading unless
//the weapon works like that.
simulated function ActuallyFinishReloading()
{ 
   bDoSingleReload = false;
   PlaySound(ReloadEndSound, SLOT_Misc, TransientSoundVolume,,TransientSoundRadius,, false);
   ClientFinishReloading();
   bIsReloading = false;
   bReloadEffectDone = false;
}

simulated function ClientFinishReloading()
{
	bIsReloading = false;
	PlayIdle();

	if(Instigator.PendingWeapon != none && Instigator.PendingWeapon != self)
		Instigator.Controller.ClientSwitchToBestWeapon();
}

function ServerSetAiming(bool IsAiming)
{
	if( KFHumanPawn(Instigator)!=None )
		KFHumanPawn(Instigator).SetAiming(IsAiming);
	bAimingRifle = IsAiming;
	InterruptReload();
}

function bool AllowReload()
{
	UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    if(KFInvasionBot(Instigator.Controller) != None && !bIsReloading &&
		ClipLeft < ClipCount && AmmoAmount(0) > ClipLeft)
		return true;
		
	if(KFFriendlyAI(Instigator.Controller) != None && !bIsReloading &&
		ClipLeft < ClipCount && AmmoAmount(0) > ClipLeft)
		return true;
		

	if(FireMode[0].IsFiring() || FireMode[1].IsFiring() ||
		   bIsReloading || ClipLeft >= ClipCount ||
		   ClientState == WS_BringUp ||
		   AmmoAmount(0) <= ClipLeft ||
                   (FireMode[0].NextFireTime - Level.TimeSeconds) > 0.1 )
		return false;
	return true;
}

simulated function PostNetReceive()
{
    //This function changes the weapon in netplay if it has no ammo
    //we WANT to be able to select guns without ammo. Therefore this
    //function has to be overridden do it does.....nothing.

}

function ServerStopFire(byte Mode)
{
  //TODO: This works, but could be better timing wise
  //      Still, at least the DBShottie/XBow don't have wierd
  //      negative clip sizes now

  super.ServerStopFire(Mode);

  if(ClipCount==1)
    ClipLeft=1;

}

// TODO: Play spot the difference
// cut n pasted to change putdown behaviours
simulated function Timer()
{
	local int Mode;
	local float OldDownDelay;

	OldDownDelay = DownDelay;
	DownDelay = 0;
	
    if (ClientState == WS_BringUp)
    {
		for( Mode = 0; Mode < NUM_FIRE_MODES; Mode++ )
	       FireMode[Mode].InitEffects();
        ClientState = WS_ReadyToFire;

        // If the server started a reload while we were still in BringUp
        // (due to network latency), don't stomp the reload anim with idle
        if (!bIsReloading)
            PlayIdle();

    }
    else if (ClientState == WS_PutDown)
    {
        if ( OldDownDelay > 0 )
        {
            if ( HasAnim(PutDownAnim) )
                PlayAnim(PutDownAnim, PutDownAnimRate, 0.0);
			SetTimer(PutDownTime, false);
			return;
		}
		if ( Instigator.PendingWeapon == None )
		{
			if( ClientGrenadeState == GN_TempDown )
			{
				if(KFPawn(Instigator)!=none)
				{
					KFPawn(Instigator).WeaponDown();
				}
			}
			else
			{
	 			PlayIdle();
			}
            ClientState = WS_ReadyToFire;
		}
		else
		{
			if( FlashLight!=none )
				Tacshine.Destroy();
			ClientState = WS_Hidden;
			Instigator.ChangedWeapon();
			if ( Instigator.Weapon == self )
			{
				PlayIdle();
				ClientState = WS_ReadyToFire;
			}
			else
			{
				for( Mode = 0; Mode < NUM_FIRE_MODES; Mode++ )
					FireMode[Mode].DestroyEffects();
			}
		}
    }
}

// Kludge to prevent destroyed weapons destroying the ammo if other guns
// are still using the same ammo
simulated function Destroyed()
{
	local byte m;
	local Inventory InvIt;
	local byte bSaveAmmo[NUM_FIRE_MODES]; // byte, because bool arrays aren't allowed :(
	local Actor TempOwner;

	AmbientSound = None;

	if ( FlashLight != none )
		FlashLight.Destroy();

	if ( TacShine != none )
		TacShine.Destroy();

	if ( Owner == none )
	{
		TempOwner = Instigator;
	}
	else
	{
		TempOwner = Owner;
	}

	if ( TempOwner != none)
	{
		for(InvIt = TempOwner.Inventory; InvIt!=none; InvIt=InvIt.Inventory)
		{
			if(Weapon(InvIt)!=none && InvIt!=self)
			{
				for(m=0; m < NUM_FIRE_MODES; m++)
				{
					if( Weapon(InvIt).Ammo[m]==Ammo[m] )
						bSaveAmmo[m] = 1;
				}
			}
		}

		for (m = 0; m < NUM_FIRE_MODES; m++)
		{
			if ( FireMode[m] != None )
				FireMode[m].DestroyEffects();
			if( Ammo[m] != none && bSaveAmmo[m]==0 )
			{
				Ammo[m].Destroy();
				Ammo[m] = None;
			}
		}

		if ( Pawn(TempOwner) != none )
		{
			Pawn(TempOwner).DeleteInventory(self);
		}
	}

	if ( ThirdPersonActor != None )
		ThirdPersonActor.Destroy();
}
simulated function Weapon PrevWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
	//allow selection of empty guns, so that we can select them
	//in order to chuck them away

	if ( (CurrentChoice == None) )
	{
		if ( CurrentWeapon != self )
			CurrentChoice = self;
	}
	else if ( InventoryGroup == CurrentWeapon.InventoryGroup )
	{
		if ( (GroupOffset < CurrentWeapon.GroupOffset) && ((CurrentChoice.InventoryGroup != InventoryGroup)
		 || (GroupOffset > CurrentChoice.GroupOffset)) )
			CurrentChoice = self;
	}
	else if ( InventoryGroup == CurrentChoice.InventoryGroup )
	{
		if ( GroupOffset > CurrentChoice.GroupOffset )
			CurrentChoice = self;
	}
	else if ( InventoryGroup > CurrentChoice.InventoryGroup )
	{
		if ( (InventoryGroup < CurrentWeapon.InventoryGroup)
		 || (CurrentChoice.InventoryGroup > CurrentWeapon.InventoryGroup)
		 || ( (CurrentChoice.InventoryGroup == CurrentWeapon.InventoryGroup) && (CurrentChoice.GroupOffset>CurrentWeapon.GroupOffset) ) )
			CurrentChoice = self;
	}
	else if ( (CurrentChoice.InventoryGroup > CurrentWeapon.InventoryGroup || ( (CurrentChoice.InventoryGroup == CurrentWeapon.InventoryGroup) && (CurrentChoice.GroupOffset>CurrentWeapon.GroupOffset) ))
	 && (InventoryGroup < CurrentWeapon.InventoryGroup) )
		CurrentChoice = self;

	if ( Inventory == None )
		return CurrentChoice;
	else return Inventory.PrevWeapon(CurrentChoice,CurrentWeapon);
}

simulated function Weapon NextWeapon(Weapon CurrentChoice, Weapon CurrentWeapon)
{
	if ( (CurrentChoice == None) )
	{
		if ( CurrentWeapon != self )
			CurrentChoice = self;
	}
	else if ( InventoryGroup == CurrentWeapon.InventoryGroup )
	{
		if ( (GroupOffset > CurrentWeapon.GroupOffset)
		 && ((CurrentChoice.InventoryGroup != InventoryGroup) || (GroupOffset < CurrentChoice.GroupOffset)) )
			CurrentChoice = self;
	}
	else if ( InventoryGroup == CurrentChoice.InventoryGroup )
	{
		if ( GroupOffset < CurrentChoice.GroupOffset )
			CurrentChoice = self;
	}
	else if ( InventoryGroup < CurrentChoice.InventoryGroup )
	{
		if ( (InventoryGroup > CurrentWeapon.InventoryGroup)
		 || (CurrentChoice.InventoryGroup < CurrentWeapon.InventoryGroup)
		 || ( (CurrentChoice.InventoryGroup == CurrentWeapon.InventoryGroup) && (CurrentChoice.GroupOffset<CurrentWeapon.GroupOffset) ) )
			CurrentChoice = self;
	}
	else if ( (CurrentChoice.InventoryGroup < CurrentWeapon.InventoryGroup || (CurrentChoice.InventoryGroup == CurrentWeapon.InventoryGroup) && (CurrentChoice.GroupOffset<CurrentWeapon.GroupOffset))
	 && (InventoryGroup > CurrentWeapon.InventoryGroup) )
		CurrentChoice = self;
	if ( Inventory == None )
		return CurrentChoice;
	else return Inventory.NextWeapon(CurrentChoice,CurrentWeapon);
}
simulated function Weapon WeaponChange( byte F, bool bSilent )
{
	if ( InventoryGroup == F )
		return self;
	else if ( Inventory == None )
		return None;
	else return Inventory.WeaponChange(F,bSilent);
}

simulated function bool PutDown()
{
	local int Mode;

	InterruptReload();

	if ( bIsReloading )
		return false;

	// From Weapon.uc
	if (ClientState == WS_BringUp || ClientState == WS_ReadyToFire)
	{
		if ( (Instigator.PendingWeapon != None) && !Instigator.PendingWeapon.bForceSwitch )
		{
			for (Mode = 0; Mode < NUM_FIRE_MODES; Mode++)
			{
		    	// if _RO_
				if( FireMode[Mode] == none )
					continue;
				// End _RO_

				if ( FireMode[Mode].bFireOnRelease && FireMode[Mode].bIsFiring )
					return false;
				if ( FireMode[Mode].NextFireTime > Level.TimeSeconds + FireMode[Mode].FireRate*(1.f - MinReloadPct))
					DownDelay = FMax(DownDelay, FireMode[Mode].NextFireTime - Level.TimeSeconds - FireMode[Mode].FireRate*(1.f - MinReloadPct));
			}
		}

		if (Instigator.IsLocallyControlled())
		{
			for (Mode = 0; Mode < NUM_FIRE_MODES; Mode++)
			{
		    	// if _RO_
				if( FireMode[Mode] == none )
					continue;
				// End _RO_

				if ( FireMode[Mode].bIsFiring )
					ClientStopFire(Mode);
			}

            if ( DownDelay <= 0 || KFPawn(Instigator).bIsQuickHealing > 0 )
            {
				if ( ClientState == WS_BringUp || KFPawn(Instigator).bIsQuickHealing > 0 )
					TweenAnim(SelectAnim,PutDownTime);
				else if ( HasAnim(PutDownAnim) )
				{
					if( ClientGrenadeState == GN_TempDown || KFPawn(Instigator).bIsQuickHealing > 0 )
                    {
                       PlayAnim(PutDownAnim, PutDownAnimRate * (PutDownTime/0.15), 0.0);
                	}
                	else
                	{
                	   PlayAnim(PutDownAnim, PutDownAnimRate, 0.0);
                	}

				}
			}
        }
		ClientState = WS_PutDown;
		if ( Level.GRI.bFastWeaponSwitching )
			DownDelay = 0;
		if ( DownDelay > 0 )
		{
			SetTimer(DownDelay, false);
		}
		else
		{
			if( ClientGrenadeState == GN_TempDown )
			{
			   SetTimer(0.15, false);
			}
			else
			{
			   SetTimer(PutDownTime, false);
			}
		}
	}
	for (Mode = 0; Mode < NUM_FIRE_MODES; Mode++)
	{
		// if _RO_
		if( FireMode[Mode] == none )
			continue;
		// End _RO_

		FireMode[Mode].bServerDelayStartFire = false;
		FireMode[Mode].bServerDelayStopFire = false;
	}
	Instigator.AmbientSound = None;
	OldWeapon = None;
	return true; // return false if preventing weapon switch
}


simulated function BringUp(optional Weapon PrevWeapon)
{
	local int Mode;

	if( KFHumanPawn(Instigator)!=None )
		KFHumanPawn(Instigator).SetAiming(False);
	bAimingRifle = False;
	bIsReloading = false;
	IdleAnim = Default.IdleAnim;
	//Super.BringUp(PrevWeapon);

    // Fix: Initialize viewmodel motion variables to prevent network glitch
    if (Instigator != None && Instigator.IsHumanControlled())
    {
        PrevViewRot = Instigator.GetViewRotation();
        PrevViewPunch = AppliedViewPunch();
        VM_PosOffset = vect(0,0,0);
        VM_PosVel    = vect(0,0,0);
        VM_RotOffset = vect(0,0,0);
        VM_RotVel    = vect(0,0,0);
        BreathOffsetZ = 0;
        BreathPitchOffset = 0;
        BobPhase = 0;
        BobPosOffset = vect(0,0,0);
        BobRotOffset = vect(0,0,0);
        StrafeRoll = 0;
        StrafeOffsetY = 0;
        PrevPhysics = Instigator.Physics;
        PrevVelocity = vect(0,0,0);
        LastMotionUpdateTime = Level.TimeSeconds;
    }

	// From Weapon.uc
    if ( ClientState == WS_Hidden || ClientGrenadeState == GN_BringUp || KFPawn(Instigator).bIsQuickHealing > 0 )
	{
		PlayOwnedSound(SelectSound, SLOT_Interact,,,,, false);
		ClientPlayForceFeedback(SelectForce);  // jdf

		if ( Instigator.IsLocallyControlled() )
		{
			if ( (Mesh!=None) && HasAnim(SelectAnim) )
			{
                if( ClientGrenadeState == GN_BringUp || KFPawn(Instigator).bIsQuickHealing > 0 )
				{
					PlayAnim(SelectAnim, SelectAnimRate * (BringUpTime/0.150000), 0.0);
				}
				else
				{
					PlayAnim(SelectAnim, SelectAnimRate, 0.0);
				}
			}
		}

		ClientState = WS_BringUp;
        if( ClientGrenadeState == GN_BringUp || KFPawn(Instigator).bIsQuickHealing > 0 )
		{
			ClientGrenadeState = GN_None;
			SetTimer(0.150000, false);
		}
		else
		{
			SetTimer(BringUpTime, false);
		}
	}

	for (Mode = 0; Mode < NUM_FIRE_MODES; Mode++)
	{
		FireMode[Mode].bIsFiring = false;
		FireMode[Mode].HoldTime = 0.0;
		FireMode[Mode].bServerDelayStartFire = false;
		FireMode[Mode].bServerDelayStopFire = false;
		FireMode[Mode].bInstantStop = false;
	}

	if ( (PrevWeapon != None) && PrevWeapon.HasAmmo() && !PrevWeapon.bNoVoluntarySwitch )
		OldWeapon = PrevWeapon;
	else
		OldWeapon = None;
}

simulated function bool ConsumeAmmo( int Mode, float Load, optional bool bAmountNeededIsMax )
{
	if( Super.ConsumeAmmo(Mode, Load, bAmountNeededIsMax) )
	{
		if( Load > 0 )
			ClipLeft--;   // ClipLeft --
		return true;
	}
	return false;
}

//TODO - this should, in theory, let us buy/carry more ammo.
//       is this intended, or should this side-effect be squashed?
function ClipUpgrade()
{
	ClipCount += (0.25 * default.ClipCount);
}

function OwnerEvent(name EventName)
{
	if( EventName=='ChangedWeapon' )
	{
		if( TacShine!=None)
			TacShine.Destroy();
		if( FlashLight!=None && FlashLight.bHasLight )
			ServerSpawnLight();
	}
	Super.OwnerEvent(EventName);
}

simulated function WeaponTick(float DT)
{
	local float LastSeenSeconds, ReloadMulti, t, baseBrightness;
	local int battery;

    if ( (Level.NetMode == NM_Client) || Instigator == None || KFFriendlyAI(Instigator.Controller) == none && Instigator.PlayerReplicationInfo == None)
        return;

	// Turn it off on death  / battery expenditure
	if (FlashLight != none)
	{
		// Keep the 1Pweapon client beam up to date.
		AdjustLightGraphic();
		if (FlashLight.bHasLight)
		{
			battery = KFHumanPawn(Instigator).TorchBatteryLife;
			if (battery <= 100)
			{
				t = 1.0 - float(battery) / 100.0;
				baseBrightness = Flashlight.TacLightGlow.default.LightBrightness * float(battery) / 100.0;
				// Sputter in final moments like a dying filament
				if (battery <= 30)
					baseBrightness *= 0.3 + 0.7 * FRand();
				Flashlight.TacLightGlow.LightBrightness = baseBrightness;
				// Warm amber/orange shift as filament cools: hue 0->20, saturation 255->100
				Flashlight.TacLightGlow.LightHue = byte(20.0 * t);
				Flashlight.TacLightGlow.LightSaturation = byte(255.0 - 155.0 * t);
			}
			else
			{
				Flashlight.TacLightGlow.LightBrightness = Flashlight.TacLightGlow.default.LightBrightness;
				Flashlight.TacLightGlow.LightHue = Flashlight.TacLightGlow.default.LightHue;
				Flashlight.TacLightGlow.LightSaturation = Flashlight.TacLightGlow.default.LightSaturation;
			}
			if (Instigator.Health <= 0 || battery <= 0 || Instigator.PendingWeapon != none)
			{
				KFHumanPawn(Instigator).bTorchOn = false;
				ServerSpawnLight();
			}
		}
	}

	UpdateMagCapacity(Instigator.PlayerReplicationInfo);

	if(!bIsReloading)
	{

		if(!Instigator.IsHumanControlled())
		{
			LastSeenSeconds = Level.TimeSeconds - Instigator.Controller.LastSeenTime;
			if(ClipLeft == 0 || ((LastSeenSeconds >= 5 || LastSeenSeconds > ClipLeft) && ClipLeft < ClipCount))
			{
				ReloadMeNow();
			}
		}
	}
	else
	{

		if((Level.TimeSeconds - ReloadTimer) >= ReloadRate)
		{
			if(AmmoAmount(0) <= ClipCount && !bHoldToReload)
			{
				ClipLeft = AmmoAmount(0);
				ActuallyFinishReloading();
			}
			else
			{
				if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
				{
					ReloadMulti = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetReloadSpeedModifier(self);
				}
				else ReloadMulti = 1;
				if( KFPawn(Instigator)!=None )
					ReloadMulti *= KFPawn(Instigator).GetReloadSpeedScale();
				PlaySound(ReloadSound, SLOT_Misc, TransientSoundVolume,,TransientSoundRadius,ReloadMulti,false);

				InsertBullet();

				if(ClipLeft < ClipCount && ClipLeft < AmmoAmount(0) && bHoldToReload)
					ReloadTimer = Level.TimeSeconds;
				if(ClipLeft >= ClipCount || ClipLeft >= AmmoAmount(0) || !bHoldToReload || bDoSingleReload)
					ActuallyFinishReloading();
				else if( Level.NetMode!=NM_Client )
					Instigator.SetAnimAction(WeaponReloadAnim);
			}
		}
		else if(bIsReloading && !bReloadEffectDone && Level.TimeSeconds - ReloadTimer >= ReloadRate / 2)
		{
			bReloadEffectDone = true;
			ClientReloadEffects();
		}
	}

}

simulated function Tick(float DeltaTime)
{
	Super.Tick(DeltaTime);
	WallOffsetFactor += (TargetWallOffsetFactor - WallOffsetFactor) * FMin(DeltaTime * 8.0, 1.0);
    if (Instigator != None && Instigator.Controller != None && Instigator.IsFirstPerson())
		if (Level.NetMode != NM_DedicatedServer)
        	UpdateViewModelMotion(Instigator.GetViewRotation(), DeltaTime);
}

// The view punch that is in the owner's view right now.
simulated function rotator AppliedViewPunch()
{
	if ( Instigator != None && KFPlayerController(Instigator.Controller) != None )
		return KFPlayerController(Instigator.Controller).PunchApplied;
	return rot(0,0,0);
}

// Kicks the owner's view for one shot. Scale is the shot's share of UpKick, Duration grows through a burst.
simulated function ViewKick( float Scale, float Duration, float Damping, float Spring )
{
	local KFPlayerController PC;
	local float Largest;

	if ( Instigator == None )
		return;
	PC = KFPlayerController(Instigator.Controller);
	if ( PC == None )
		return;

	// A shot kicks between half and all of Largest
	Largest = 0.5 * UpKick * Scale;
	PC.PunchDamping = Damping;
	PC.PunchSpring = Spring;
	PC.ViewPunch(FClamp(Largest * (0.5 + FRand()*0.5), 80, 5000) * Duration, (FRand() - 0.5) * SideKick * Duration,
		FClamp(Largest, 80, 5000) * Duration, 0.5 * SideKick * Duration);
}

//All vibe coded
simulated function UpdateViewModelMotion(rotator CurViewRot, float DeltaTime)
{
    local rotator dR, Punch;
    local float dyawDeg, dpitchDeg;
    local float angVelYaw, angVelPitch;
    local float turnYaw, turnPitch;
    local vector forcePos, forcePosWorld, torqueRot;
    local float speed2D, speedNorm, bobHz, ampScale, breathVal, strafeSpeed, strafeNorm;
    local vector viewX, viewY, viewZ, accelVec;
    local vector targetBobPos, targetBobRot;
    local float targetStrafeRoll, targetStrafeY;
    local bool bOnGround, bSprinting, bZombiesSprint;
    local EPhysics curPhysics;
    local float fallSpeed, landScale;
    local float SprintTargetFactor;

    if (DeltaTime <= 0.0)
        return;

    GetAxes(CurViewRot, viewX, viewY, viewZ);

    dR.Yaw   = CurViewRot.Yaw - PrevViewRot.Yaw;
    dR.Pitch = CurViewRot.Pitch - PrevViewRot.Pitch;
    if (dR.Yaw > 32768) dR.Yaw -= 65536; else if (dR.Yaw < -32768) dR.Yaw += 65536;
    if (dR.Pitch > 32768) dR.Pitch -= 65536; else if (dR.Pitch < -32768) dR.Pitch += 65536;

    dyawDeg   = float(dR.Yaw)   * (360.0/65536.0);
    dpitchDeg = float(dR.Pitch) * (360.0/65536.0);

    angVelYaw   = dyawDeg   / DeltaTime;
    angVelPitch = dpitchDeg / DeltaTime;

    // Turn inertia forces
    forcePos.X = -Abs(angVelYaw) * LagPosStrength * 0.015;
    forcePos.Y = -angVelYaw      * LagPosStrength * 0.010;
    forcePos.Z =  angVelPitch    * LagPosStrength * 0.010;

    torqueRot.Y = -angVelYaw      * LagRotStrength * 0.020;
    torqueRot.X =  angVelPitch    * LagRotStrength * 0.025;
    torqueRot.Z = -angVelYaw      * LagRotStrength * 0.008;

    // The player's own turning, without the view punch: a shot's kick is not a flick
    Punch = AppliedViewPunch();
    turnYaw   = angVelYaw   - float(Punch.Yaw   - PrevViewPunch.Yaw)   * (360.0/65536.0) / DeltaTime;
    turnPitch = angVelPitch - float(Punch.Pitch - PrevViewPunch.Pitch) * (360.0/65536.0) / DeltaTime;
    PrevViewPunch = Punch;

    // Flick impulses
    if (Abs(turnYaw) > FlickThresholdDegPerSec)
    {
        if (turnYaw > 0) { VM_PosVel -= viewY * FlickImpulsePos; VM_RotVel.Z -= FlickImpulseRot; }
        else             { VM_PosVel += viewY * FlickImpulsePos; VM_RotVel.Z += FlickImpulseRot; }
    }
    if (Abs(turnPitch) > FlickThresholdDegPerSec)
    {
        if (turnPitch > 0) { VM_PosVel += viewZ * (FlickImpulsePos * 0.2); VM_RotVel.X += FlickImpulseRot * 0.35; }
        else               { VM_PosVel -= viewZ * (FlickImpulsePos * 0.2); VM_RotVel.X -= FlickImpulseRot * 0.35; }
    }

    // --- CoD-style Movement Bob (DIRECT offsets, not through spring) ---
    if (Instigator != None)
    {
        curPhysics = Instigator.Physics;
        bOnGround = (curPhysics == PHYS_Walking || curPhysics == PHYS_Ladder);
        speed2D = VSize(Instigator.Velocity);
        bSprinting = (KFHumanPawn(Instigator) != None && KFHumanPawn(Instigator).bIsSprinting);
        bZombiesSprint = bSprinting && KFHumanPawnZombies(Instigator)!=None;
        if (bZombiesSprint)
            SprintTargetFactor = 1.0;
        else
            SprintTargetFactor = 0.0;
        SprintFactor += (SprintTargetFactor - SprintFactor) * FMin(DeltaTime * SprintTransitionSpeed, 1.0);

        if (PrevPhysics == PHYS_Walking && curPhysics == PHYS_Falling)
        {
            VM_PosVel -= viewZ * JumpKickPos;
            VM_PosVel -= viewX * (JumpKickPos * 0.3);
            VM_RotVel.X += JumpKickRot;
        }
        else if (PrevPhysics == PHYS_Falling && curPhysics == PHYS_Walking)
        {
            fallSpeed = FMax(-PrevVelocity.Z, 0.0);
            landScale = 1.0 + LandKickSpeedScale * FClamp(fallSpeed / 600.0, 0.0, 2.0);
            VM_PosVel -= viewZ * (LandKickPos * landScale);
            VM_RotVel.X -= LandKickRot * landScale;
        }
        PrevPhysics = curPhysics;

        if (speed2D > 10 && bOnGround)
        {
            speedNorm = FClamp(speed2D / 200.0, 0.0, 1.0);
            if (bZombiesSprint)
                bobHz = MoveBobFreq * 1.5;
            else if (bSprinting)
                bobHz = MoveBobFreq * 1.3;
            else
                bobHz = MoveBobFreq;

            BobPhase += DeltaTime * bobHz * 6.283185;
            if (BobPhase > 6.283185) BobPhase -= 6.283185;

            ampScale = speedNorm * speedNorm;
            ampScale = FClamp(ampScale, 0.0, 1.0);
            if (bSprinting)
                ampScale *= MoveBobSprintMulti;
            if (bZombiesSprint)
                ampScale *= ZombiesSprintBobMulti;
            targetBobPos.Z = -Abs(Cos(BobPhase)) * MoveBobAmp * MoveBobVertScale * ampScale;
            targetBobPos.Y = Sin(BobPhase) * MoveBobAmp * MoveBobHorizScale * ampScale;
            targetBobPos.X = 0;

            targetBobRot.Z = Sin(BobPhase)  * MoveBobRollRot  * ampScale;
            targetBobRot.Y = Sin(BobPhase)  * MoveBobYawRot   * ampScale;
            targetBobRot.X = -Abs(Cos(BobPhase)) * MoveBobPitchRot * ampScale;

            LastGroundAmpScale = ampScale;
        }
        else
        {
            BobPhase *= (1.0 - FMin(1.0, 5.0 * DeltaTime));
            LastGroundAmpScale *= (1.0 - FMin(1.0, 5.0 * DeltaTime));

            targetBobPos.Z = -Abs(Cos(BobPhase)) * MoveBobAmp * MoveBobVertScale * LastGroundAmpScale;
            targetBobPos.Y = Sin(BobPhase) * MoveBobAmp * MoveBobHorizScale * LastGroundAmpScale;
            targetBobPos.X = 0;

            targetBobRot.Z = Sin(BobPhase)  * MoveBobRollRot  * LastGroundAmpScale;
            targetBobRot.Y = Sin(BobPhase)  * MoveBobYawRot   * LastGroundAmpScale;
            targetBobRot.X = -Abs(Cos(BobPhase)) * MoveBobPitchRot * LastGroundAmpScale;
        }

        BobPosOffset += (targetBobPos - BobPosOffset) * FMin(DeltaTime * 12.0, 1.0);
        BobRotOffset += (targetBobRot - BobRotOffset) * FMin(DeltaTime * 12.0, 1.0);

        strafeSpeed = Instigator.Velocity dot viewY;
        strafeNorm = strafeSpeed / FMax(Instigator.GroundSpeed, 200.0);

        targetStrafeRoll = -strafeNorm * StrafeRollStrength;
        targetStrafeY    =  strafeNorm * StrafePosStrength;

        StrafeRoll    += (targetStrafeRoll - StrafeRoll)    * FMin(DeltaTime * StrafeLeanSpeed, 1.0);
        StrafeOffsetY += (targetStrafeY    - StrafeOffsetY) * FMin(DeltaTime * StrafeLeanSpeed, 1.0);

        if (DeltaTime > 0.001)
        {
            accelVec = (Instigator.Velocity - PrevVelocity) / DeltaTime;
            accelVec.Z = 0;
            if (VSize(accelVec) > 2000.0)
                accelVec = Normal(accelVec) * 2000.0;
            forcePos.X += -(accelVec dot viewX) * MoveReactStrength * 0.002;
            forcePos.Y += -(accelVec dot viewY) * MoveReactStrength * 0.002;
            forcePos.Z += -(accelVec dot viewZ) * MoveReactStrength * 0.001;
        }
        PrevVelocity = Instigator.Velocity;
    }

    forcePosWorld = viewX * forcePos.X + viewY * forcePos.Y + viewZ * forcePos.Z;

    VM_PosVel    += ( -LagSpringK * VM_PosOffset - LagSpringDamping * VM_PosVel + forcePosWorld ) * DeltaTime;
    VM_PosOffset += VM_PosVel * DeltaTime;
    if (VSize(VM_PosOffset) > ViewLagMaxOffset)
        VM_PosOffset = Normal(VM_PosOffset) * ViewLagMaxOffset;

    VM_RotVel    += ( -RotSpringK * VM_RotOffset - RotSpringDamping * VM_RotVel + torqueRot ) * DeltaTime;
    VM_RotOffset += VM_RotVel * DeltaTime;
    if (VM_RotOffset.X > 12) VM_RotOffset.X = 12; else if (VM_RotOffset.X < -12) VM_RotOffset.X = -12;
    if (VM_RotOffset.Y > 12) VM_RotOffset.Y = 12; else if (VM_RotOffset.Y < -12) VM_RotOffset.Y = -12;
    if (VM_RotOffset.Z > 15) VM_RotOffset.Z = 15; else if (VM_RotOffset.Z < -15) VM_RotOffset.Z = -15;

    breathVal = Sin(Level.TimeSeconds * BreathFreq * 6.283185); //2 * pi
    BreathOffsetZ    = breathVal * BreathAmplitude;        
    BreathPitchOffset= breathVal * BreathPitchAmplitude; 

    PrevViewRot = CurViewRot;
    LastMotionUpdateTime = Level.TimeSeconds;
}

simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
    Super.DisplayDebug(Canvas, YL, YPos);
	Canvas.DrawText("FOV: " @ string(DisplayFOV));
	YPos += YL;
}

function AdjustLightGraphic()
{
	if ( TacShine==none )
	{
		TacShine = Spawn(TacShineClass,,,,);
		AttachToBone(TacShine,'LightBone');
	}
	if( FlashLight!=none )
		Tacshine.bHidden = !FlashLight.bHasLight;
}

function InsertBullet()
{
	UpdateMagCapacity(Instigator.PlayerReplicationInfo);

	if(ammoAmount(0) >= clipCount)
            ClipLeft = ClipCount;
        else
            clipLeft = ammoAmount(0) ;

	if( !bHoldToReload )
	{
		ClientForceKFAmmoUpdate(ClipLeft,AmmoAmount(0));
	}
}

simulated function ClientForceKFAmmoUpdate(int NewMagAmmoRemaining, int TotalAmmoRemaining)
{
	//log(self$" ClientForceKFAmmoUpdate NewMagAmmoRemaining "$NewMagAmmoRemaining$" TotalAmmoRemaining "$TotalAmmoRemaining);
	ClientForceAmmoUpdate(0, TotalAmmoRemaining);
}

simulated function ClientForceAmmoUpdate(int Mode, int NewAmount)
{
	//log(self$" ClientForceAmmoUpdate mode "$Mode$" newamount "$NewAmount);
	if ( bNoAmmoInstances )
		AmmoCharge[Mode] = NewAmount;
	else if ( Ammo[mode] != None )
		Ammo[mode].AmmoAmount = NewAmount;
}

simulated function DoToggle ()
{
	PlaySound(ToggleSound, SLOT_Misc, TransientSoundVolume,,TransientSoundRadius,, false);
}

// TODO - Decode the purpose of this mangled mess
simulated function float ChargeBar()
{
	Return 0;
}

function byte BestMode()
{
	return 0;
}

simulated function vector GetEffectStart()
{
	local Vector FlashLoc;

	// jjs - this function should actually never be called in third person views
	// any effect that needs a 3rdp weapon offset should figure it out itself

	// 1st person
	if (Instigator.IsFirstPerson())
	{
		if ( WeaponCentered() )
			return CenteredEffectStart();

		FlashLoc = GetBoneCoords(FlashBoneName).Origin;

		return FlashLoc;
	}
	// 3rd person
	else
	{
		return (Instigator.Location +
			Instigator.EyeHeight*Vect(0,0,0.5) +
			Vector(Instigator.Rotation) * 40.0);
	}
}

// complete cut n' paste job needed, so that it can be modified
// to stop this function giving ammo to empty guns that have been
// thrown out
function GiveAmmo(int m, WeaponPickup WP, bool bJustSpawned)
{
    local bool bJustSpawnedAmmo;
    local int addAmount, InitialAmount;
	local KFPawn KFP;
    local KFPlayerReplicationInfo KFPRI;

    KFP = KFPawn(Instigator);
    if( KFP != none )
    {
        KFPRI = KFPlayerReplicationInfo(KFP.PlayerReplicationInfo);
    }

	UpdateMagCapacity(Instigator.PlayerReplicationInfo);

    if ( FireMode[m] != None && FireMode[m].AmmoClass != None )
    {
		//log("Giving ammo for mode "$m$" of weapon "$GetHumanReadableName());
        Ammo[m] = Ammunition(Instigator.FindInventoryType(FireMode[m].AmmoClass));
		bJustSpawnedAmmo = false;

		if ( bNoAmmoInstances )
		{
            if ( (FireMode[m].AmmoClass == None) || ((m != 0) && (FireMode[m].AmmoClass == FireMode[0].AmmoClass)) )
				return;

			InitialAmount = FireMode[m].AmmoClass.Default.InitialAmount;

            // HERE IS THE IMPORTANT CHANGE
            //if ( (WP != None) && ((WP.AmmoAmount[0] > 0) || (WP.AmmoAmount[1] > 0))  )
			if(WP!=none && WP.bThrown==true)
            {
                InitialAmount = WP.AmmoAmount[m];
                if(KFWeaponPickup(WP)!=none)
                  ClipLeft = KFWeaponPickup(WP).ClipLeft;
			}
			else
			{
			  // Other change - if not thrown, give the gun a full clip
			  ClipLeft = ClipCount;

			}

			if ( Ammo[m] != None )
			{
				addamount = InitialAmount + Ammo[m].AmmoAmount;
				Ammo[m].Destroy();

			}
			else
				addAmount = InitialAmount;

			AddAmmo(addAmount,m);
		}
		else
		{
			if ( (Ammo[m] == None) && (FireMode[m].AmmoClass != None) )
			{
				Ammo[m] = Spawn(FireMode[m].AmmoClass, Instigator);
				Instigator.AddInventory(Ammo[m]);
				bJustSpawnedAmmo = true;
			}
			else if ( (m == 0) || (FireMode[m].AmmoClass != FireMode[0].AmmoClass) )
				bJustSpawnedAmmo = ( bJustSpawned || ((WP != None) && !WP.bWeaponStay) );

	  	      // and here is the modification for instanced ammo actors

			if(WP!=none && WP.bThrown==true)
			{
				addAmount = WP.AmmoAmount[m];
			}
			else if ( bJustSpawnedAmmo )
			{
				if (default.ClipCount == 0)
					addAmount = 0;  // prevent division by zero.
				else
					addAmount = Ammo[m].InitialAmount * (float(ClipCount) / float(default.ClipCount));
			}

			// Don't double add ammo if primary and secondary fire modes share the same ammo class
            if ( WP != none && m > 0 && (FireMode[m].AmmoClass == FireMode[0].AmmoClass) )
			{
				return;
			}

            // AddAmmo caps at MaxAmmo, but veterancy might allow for more than max,
            // so take that into account
			if( KFPRI != none && KFPRI.ClientVeteranSkill != none )
            {
                Ammo[m].MaxAmmo = MaxAmmo(m);
        	}

			Ammo[m].AddAmmo(addAmount);
			Ammo[m].GotoState('');
		}
    }
}

function GiveTo( pawn Other, optional Pickup Pickup )
{
	UpdateMagCapacity(Other.PlayerReplicationInfo);

	if ( KFWeaponPickup(Pickup)!=None && Pickup.bDropped )
	{
		ClipLeft = Clamp(KFWeaponPickup(Pickup).ClipLeft, 0, ClipCount);
	}
	else
		ClipLeft = ClipCount;

	//log(GetHumanReadableName()$" Given to "$Other.GetHumanReadableName()$" ClipLeft: "$ClipLeft);

	Super.GiveTo(Other,Pickup);
}

// Modded to allow for throwing even when out of ammo.  (also added : You cannot throw while reloading)
simulated function bool CanThrow()
{
    local int Mode;

    if(bKFNeverThrow)
      return false;

    for (Mode = 0; Mode < NUM_FIRE_MODES; Mode++)
    {
        if ( FireMode[Mode].bFireOnRelease && FireMode[Mode].bIsFiring )
            return false;
        if ( FireMode[Mode].NextFireTime > Level.TimeSeconds)
            return false;
    }
    return (bCanThrow && !bIsReloading && (ClientState == WS_ReadyToFire || (Level.NetMode == NM_DedicatedServer) || (Level.NetMode == NM_ListenServer)));
}

simulated function ClientWeaponThrown()
{
	local int m;
	local Inventory InvIt;
   	local byte bSaveAmmo[NUM_FIRE_MODES];

	AmbientSound = None;
	Instigator.AmbientSound = None;

	if( Level.NetMode != NM_Client )
		return;

	for ( InvIt = Instigator.Inventory; InvIt != none; InvIt = InvIt.Inventory )
	{
		if ( Weapon(InvIt) != none && InvIt != self)
		{
			for ( m = 0; m < NUM_FIRE_MODES; m++ )
			{
				if ( Weapon(InvIt).Ammo[m] == Ammo[m] )
				{
					bSaveAmmo[m] = 1;
				}
			}
		}
	}

	Instigator.DeleteInventory(self);
	for (m = 0; m < NUM_FIRE_MODES; m++)
	{
		if (Ammo[m] != none && bSaveAmmo[m] == 0 )
			Instigator.DeleteInventory(Ammo[m]);
	}
}

function DropFrom(vector StartLocation)
{
    local int m;
    local Pickup Pickup;
	local Vector Direction;
	//local InventorySpot mySpot;

    if (!bCanThrow)
        return;

    Pickup = Spawn(PickupClass,Instigator.Controller,, StartLocation);
    if ( Pickup != None )
    {
        Pickup.InitDroppedPickupFor(self);
        Pickup.Velocity = Velocity + (Direction * 100);
        if (Instigator.Health > 0)
            WeaponPickup(Pickup).bThrown = true;
    } else return; // couldn't spawn pickup for some reason

    ClientWeaponThrown();

    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if (FireMode[m].bIsFiring)
            StopFire(m);
    }

	if ( Instigator != None )
	{
		DetachFromPawn(Instigator);
		Direction = vector(Instigator.Rotation);
	}
	else if ( Owner != none )
	{
		Direction = vector(Owner.Rotation);
	}

	Destroyed();
    Destroy();
}

// Only fill to initial the FIRST time we come across this weapon.
simulated function FillToInitialAmmo()
{
	if ( bNoAmmoInstances )
	{
		if ( AmmoClass[0] != None )
			AmmoCharge[0] = Max(AmmoCharge[0], AmmoClass[0].Default.InitialAmount);
		if ( (AmmoClass[1] != None) && (AmmoClass[0] != AmmoClass[1]) )
			AmmoCharge[1] = Max(AmmoCharge[1], AmmoClass[1].Default.InitialAmount);
		return;
	}

	if ( Ammo[0] != None )
        Ammo[0].AmmoAmount = /*Max(*/Ammo[0].AmmoAmount;//,Ammo[0].InitialAmount * (float(MagCapacity) / float(default.MagCapacity)));
	if ( Ammo[1] != None )
        Ammo[1].AmmoAmount = Max(Ammo[1].AmmoAmount,Ammo[1].InitialAmount * (float(ClipCount) / float(default.ClipCount)));
}

// Change the Accuracy based on player movement
simulated function AccuracyUpdate(float Velocity)
{
 if (Owner != none)
 {
   if (KFFire(FireMode[0])!= none)
    KFFire(FireMode[0]).AccuracyUpdate(Velocity);
   else
   if  (KFShotgunFire(FireMode[0]) !=none)
    KFShotgunFire(FireMode[0]).AccuracyUpdate(Velocity);
 }
}

simulated function PlayAnimZoom( bool bZoomNow ); // Called from KFZoom whenever start or end the zooming.

simulated function bool CanZoomNow()
{
	Return !FireMode[0].bIsFiring && !KFHumanPawn(Instigator).bIsSprinting && !bIsReloading && ClientState == WS_ReadyToFire;
}

simulated function float GetAmmoMulti()
{
	if ( NextAmmoCheckTime > Level.TimeSeconds )
	{
		return LastAmmoResult;
	}

	NextAmmoCheckTime = Level.TimeSeconds + 1;

	if ( FireMode[0] != none && FireMode[0].AmmoClass != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none &&
		 KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
	{
		LastAmmoResult = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.static.AddExtraAmmoFor(FireMode[0].AmmoClass);
	}
	else
	{
		LastAmmoResult = 1;
	}

	return LastAmmoResult;
}

simulated function int MaxAmmo(int mode)
{
	if ( AmmoClass[mode] != None )
		return AmmoClass[mode].Default.MaxAmmo*GetAmmoMulti();
	return 0;
}
// Don't consider secondary fire modes, it fucks up the bots
simulated function bool HasAmmo()
{
	return (Ammo[0] != None && FireMode[0] != None && Ammo[0].AmmoAmount >= FireMode[0].AmmoPerFire);
}
simulated function bool AmmoMaxed(int mode)
{
	if ( AmmoClass[mode] == None )
		return false;

	if ( bNoAmmoInstances )
	{
		if ( AmmoClass[0] == AmmoClass[mode] )
			mode = 0;
		return AmmoCharge[mode] >= MaxAmmo(mode);
	}
	if ( Ammo[mode] == None )
		return false;
	return (Ammo[mode].AmmoAmount >= MaxAmmo(mode));
}
simulated function float AmmoStatus(optional int Mode) // returns float value for ammo amount
{
	if ( bNoAmmoInstances )
	{
		if ( AmmoClass[Mode] == None )
			return 0;
		if ( AmmoClass[0] == AmmoClass[mode] )
			mode = 0;

		return float(AmmoCharge[Mode])/float(MaxAmmo(Mode));
	}
	if (Ammo[Mode] == None)
		return 0.0;
	else return float(Ammo[Mode].AmmoAmount) / float(Ammo[Mode].MaxAmmo)*GetAmmoMulti();
}

// Avoid potential suicides...
function bool CanAttack(Actor Other)
{
    local float Dist, CheckDist;
    local vector HitLocation, HitNormal,X,Y,Z, projStart;
    local actor HitActor;
    local int m;
    local bool bInstantHit;

    if ( (Instigator == None) || (Instigator.Controller == None) )
        return false;

    // check that target is within range
    Dist = VSize(Instigator.Location - Other.Location);
    if ( (Dist > FireMode[0].MaxRange()) && (Dist > FireMode[1].MaxRange()) )
	{
		//log("Weapon " $ Class $ " cannot attack " $ Other.Name $ " at distance " $ Dist);
        return false;
	}

    // check that can see target
    if ( !Instigator.Controller.LineOfSightTo(Other) )
        return false;

    for (m = 0; m < NUM_FIRE_MODES; m++)
    {
        if ( FireMode[m].bInstantHit )
            bInstantHit = true;
        else
        {
            CheckDist = FMax(CheckDist, 0.5 * FireMode[m].ProjectileClass.Default.Speed);
            CheckDist = FMax(CheckDist, 300);
            CheckDist = FMin(CheckDist, VSize(Other.Location - Location));
        }
    }
    // check that would hit target, and not a friendly
    GetAxes(Instigator.Controller.Rotation, X,Y,Z);
    projStart = GetFireStart(X,Y,Z);
    if ( bInstantHit )
        HitActor = Trace(HitLocation, HitNormal, Other.Location + Other.CollisionHeight * vect(0,0,0.8), projStart, true);
    else
    {
        // for non-instant hit, only check partial path (since others may move out of the way)
        HitActor = Trace(HitLocation, HitNormal,
                projStart + CheckDist * Normal(Other.Location + Other.CollisionHeight * vect(0,0,0.8) - Location),
                projStart, true);
    }

    if ( (HitActor == None) || (HitActor == Other) || Pawn(HitActor) != None )
        return true;
    return !HitActor.BlocksShotAt(Other);
}

simulated function GetAmmoCount(out float MaxAmmoPrimary, out float CurAmmoPrimary)
{
	if ( Instigator == None || Instigator.Controller == None )
	{
		return;
	}

	if ( AmmoClass[0] == None )
	{
		return;
	}

	if ( bNoAmmoInstances )
	{
		MaxAmmoPrimary = MaxAmmo(0);
		CurAmmoPrimary = AmmoCharge[0];

		if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
		{
			MaxAmmoPrimary *= KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.static.AddExtraAmmoFor(AmmoClass[0]);
			MaxAmmoPrimary = int(MaxAmmoPrimary);
		}

		return;
	}

	if ( Ammo[0] == None )
	{
		return;
	}

	MaxAmmoPrimary = Ammo[0].default.MaxAmmo;
	CurAmmoPrimary = Ammo[0].AmmoAmount;

	if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
	{
		MaxAmmoPrimary *= KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.static.AddExtraAmmoFor(Ammo[0].class);
		MaxAmmoPrimary = int(MaxAmmoPrimary);
	}
}

simulated function UpdateMagCapacity(PlayerReplicationInfo PRI)
{
	if ( KFPlayerReplicationInfo(PRI) != none && KFPlayerReplicationInfo(PRI).ClientVeteranSkill != none )
	{
		ClipCount = default.ClipCount * KFPlayerReplicationInfo(PRI).ClientVeteranSkill.Static.GetMagCapacityMod(self);
	}
	else
	{
		ClipCount = default.ClipCount;
	}
}

simulated function float DesireAmmo(class<Inventory> NewAmmoClass, bool bDetour)
{
	local int i;
	local float curr, max;

	for ( i=0; i<2; i++ )
	{
		if ( NewAmmoClass == AmmoClass[i] )
		{
			if ( AmmoMaxed(i) )
				return -100;
			curr = AmmoAmount(i);
			if ( curr == 0 )
				return 1;
			max = MaxAmmo(i);
			return 2.0 * (max - curr) / max; //Thanks Epic for breaking this function in the first place
		}
	}
	return 0;
}

simulated function ChangedPerk(String NewPerk)
{
}

defaultproperties
{
	FlashBoneName="tip"
	WeaponReloadAnim="Reload1"
	ModeSwitchAnim="'"
	bReloadEffectDone=True
	Weight=10.000000
	StoppingPower=-1000
	UpKick=500
	SideKick=100
	TacShineClass=Class'KFMod.TacLightShineAttachment'
	bSniping=True
	bNoAmmoInstances=False
	Description="This is a very generic weapon."
	LightType=LT_Steady
	LightEffect=LE_NonIncidence
	LightHue=30
	LightSaturation=150
	LightBrightness=255.000000
	LightRadius=10.000000
	LightPeriod=3
	AmbientGlow=0
	TransientSoundVolume=100.000000
	CustomCrosshair=13
	CustomCrossHairScale=0.666700
	CustomCrossHairTextureName="Crosshairs.HUD.Crosshair_Cross5"
	GunLengthDist=50.000000
	WallPivotRot=(Pitch=5000,Yaw=-5000,Roll=0)
	WallPivotOffset=(x=-10,y=0,z=-10)
	//PrePivot=(X=0.000000,Y=0.000000,Z=-2.000000)
	bModeZeroCanDryFire=True

	// Motion system defaults
	LagPosStrength=1.0
	LagRotStrength=1.0
	LagSpringK=12.0
	LagSpringDamping=7.5
	RotSpringK=10.0
	RotSpringDamping=6.5
	FlickThresholdDegPerSec=260.0
	FlickImpulsePos=2.0
	FlickImpulseRot=3.2
	BreathAmplitude=0.45
	BreathPitchAmplitude=1.5
	BreathFreq=0.35
	ViewLagMaxOffset=6.0

	// CoD-style movement bob (direct offsets)
	MoveBobAmp=1.4
	MoveBobFreq=1.1
	MoveBobYawRot=0.4
	MoveBobPitchRot=0.3
	MoveBobRollRot=1.5
	MoveBobHorizScale=0.35
	MoveBobVertScale=1.7
	MoveBobSprintMulti=2.0

	SprintTransitionSpeed=7.0
	SprintDownRot=(Pitch=-1500,Yaw=800,Roll=800)
	SprintDownOffset=(X=-6,Y=1,Z=-6)
	ZombiesSprintBobMulti=1.5

	// Strafe lean & movement reaction
	StrafeRollStrength=6.0
	StrafePosStrength=2.5
	StrafeLeanSpeed=8.0
	MoveReactStrength=2.0

	// Jump/Land weapon kick
	JumpKickPos=25.0
	JumpKickRot=18.0
	LandKickPos=40.0
	LandKickRot=30.0
	LandKickSpeedScale=0.8
}
