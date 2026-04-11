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
var float   BreathOffsetZ;
var float   BreathPitchOffset;

// === Wall offset (weapon pivots up near walls) ===
var float WallOffsetFactor, TargetWallOffsetFactor;
var() float GunLengthDist;
var() rotator WallPivotRot;
var() vector WallPivotOffset;

replication
{
	//TODO - does ClipCount still need sending,
	// and does clipleft simulate sucessfully enough to not need repping?
	reliable if(Role == ROLE_Authority)
		ClipLeft;

	reliable if( bNetDirty && bNetOwner && (Role==ROLE_Authority) )
		ClipCount;

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
    local rotator NewRotation, CenteredRotation;
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
	WeaponOffset = (X*WallPivotOffset.X + Y*WallPivotOffset.Y + Z*WallPivotOffset.Z);

    // Apply spring positional offset in local space
    WeaponOffset += X * VM_PosOffset.X + Y * VM_PosOffset.Y + Z * (VM_PosOffset.Z + BreathOffsetZ);
    // Apply direct bob + strafe offsets (bypass spring entirely)
    WeaponOffset += X * BobPosOffset.X + Y * (BobPosOffset.Y + StrafeOffsetY) + Z * BobPosOffset.Z;

    // Final location
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
    if (HitActor != None && HitActor != Instigator && BlockingVolume(HitActor) == None)
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
        PrevPhysics = PHYS_Walking;
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
	local float LastSeenSeconds, ReloadMulti;

    if ( (Level.NetMode == NM_Client) || Instigator == None || KFFriendlyAI(Instigator.Controller) == none && Instigator.PlayerReplicationInfo == None)
        return;

	// Turn it off on death  / battery expenditure
	if (FlashLight != none)
	{
		// Keep the 1Pweapon client beam up to date.
		AdjustLightGraphic();
		if (FlashLight.bHasLight)
		{
			if (KFHumanPawn(Instigator).TorchBatteryLife<40) 
				Flashlight.TacLightGlow.LightBrightness *= (KFHumanPawn(Instigator).TorchBatteryLife / KFHumanPawn(Instigator).default.TorchBatteryLife) * 10;
			else Flashlight.LightBrightness = Flashlight.default.LightBrightness;
			if (Instigator.Health <= 0 || KFHumanPawn(Instigator).TorchBatteryLife <= 0 || Instigator.PendingWeapon != none )
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

simulated function UpdateViewModelMotion(rotator CurViewRot, float DeltaTime)
{
    local rotator dR;
    local float dyawDeg, dpitchDeg;
    local float angVelYaw, angVelPitch;
    local vector forcePos, torqueRot;
    local float speed2D, speedNorm, bobHz, ampScale, breathVal, strafeSpeed, strafeNorm;
    local vector viewX, viewY, viewZ, accelVec;
    local vector targetBobPos, targetBobRot;
    local float targetStrafeRoll, targetStrafeY;
    local bool bOnGround, bSprinting;
    local EPhysics curPhysics;
    local float fallSpeed, landScale;

    if (DeltaTime <= 0.0)
        return;

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

    // Flick impulses
    if (Abs(angVelYaw) > FlickThresholdDegPerSec)
    {
        if (angVelYaw > 0) { VM_PosVel.Y -= FlickImpulsePos; VM_RotVel.Z -= FlickImpulseRot; }
        else               { VM_PosVel.Y += FlickImpulsePos; VM_RotVel.Z += FlickImpulseRot; }
    }
    if (Abs(angVelPitch) > FlickThresholdDegPerSec)
    {
        if (angVelPitch > 0) { VM_PosVel.Z += FlickImpulsePos * 0.2; VM_RotVel.X += FlickImpulseRot * 0.35; }
        else                 { VM_PosVel.Z -= FlickImpulsePos * 0.2; VM_RotVel.X -= FlickImpulseRot * 0.35; }
    }

    // --- CoD-style Movement Bob (DIRECT offsets, not through spring) ---
    if (Instigator != None)
    {
        curPhysics = Instigator.Physics;
        bOnGround = (curPhysics == PHYS_Walking || curPhysics == PHYS_Ladder);
        speed2D = VSize(Instigator.Velocity);
        bSprinting = (KFHumanPawn(Instigator) != None && KFHumanPawn(Instigator).bIsSprinting);

        // --- Jump/Land detection: inject impulses into the spring ---
        if (PrevPhysics == PHYS_Walking && curPhysics == PHYS_Falling)
        {
            // Takeoff: weapon drops back and pitches up
            VM_PosVel.Z -= JumpKickPos;
            VM_PosVel.X -= JumpKickPos * 0.3;
            VM_RotVel.X += JumpKickRot;
        }
        else if (PrevPhysics == PHYS_Falling && curPhysics == PHYS_Walking)
        {
            // Landing: weapon slams down and pitches forward, scaled by fall speed
            fallSpeed = FMax(-PrevVelocity.Z, 0.0);
            landScale = 1.0 + LandKickSpeedScale * FClamp(fallSpeed / 600.0, 0.0, 2.0);
            VM_PosVel.Z -= LandKickPos * landScale;
            VM_RotVel.X -= LandKickRot * landScale;
        }
        PrevPhysics = curPhysics;

        if (speed2D > 10 && bOnGround)
        {
            // Normalize speed against default ground speed so bob caps at normal run
            speedNorm = FClamp(speed2D / 200.0, 0.0, 1.0);

            // Sprint = slightly faster cadence, heavier footfalls
            if (bSprinting)
                bobHz = MoveBobFreq * 1.3;
            else
                bobHz = MoveBobFreq;

            // Advance phase
            BobPhase += DeltaTime * bobHz * 6.283185;
            if (BobPhase > 6.283185) BobPhase -= 6.283185;

            // Squared speed curve: walking is very subtle, running ramps up hard
            ampScale = speedNorm * speedNorm;
            ampScale = FClamp(ampScale, 0.0, 1.0);
            if (bSprinting)
                ampScale *= MoveBobSprintMulti;

            // BobPhase = full stride cycle (two footsteps)
            // Vertical: smooth V-dip per footstep (2x per stride) using -Abs(Cos)
            targetBobPos.Z = -Abs(Cos(BobPhase)) * MoveBobAmp * ampScale;
            // Horizontal: simple side-to-side sway, once per stride
            targetBobPos.Y = Sin(BobPhase) * MoveBobAmp * MoveBobHorizScale * ampScale;
            // Minimal forward pull
            targetBobPos.X = 0;

            // Roll follows horizontal sway (lean into step), yaw subtle, pitch minimal
            targetBobRot.Z = Sin(BobPhase)  * MoveBobRollRot  * ampScale;
            targetBobRot.Y = Sin(BobPhase)  * MoveBobYawRot   * ampScale;
            targetBobRot.X = -Abs(Cos(BobPhase)) * MoveBobPitchRot * ampScale;
        }
        else
        {
            // Decay phase smoothly when stopped/airborne
            BobPhase *= (1.0 - FMin(1.0, 5.0 * DeltaTime));
            targetBobPos = vect(0,0,0);
            targetBobRot = vect(0,0,0);
        }

        // Smooth blend bob offsets (weighted follow for organic feel)
        BobPosOffset += (targetBobPos - BobPosOffset) * FMin(DeltaTime * 12.0, 1.0);
        BobRotOffset += (targetBobRot - BobRotOffset) * FMin(DeltaTime * 12.0, 1.0);

        // --- Strafe lean (DIRECT, not through spring) ---
        GetAxes(CurViewRot, viewX, viewY, viewZ);
        strafeSpeed = Instigator.Velocity dot viewY;
        strafeNorm = strafeSpeed / FMax(Instigator.GroundSpeed, 200.0);

        targetStrafeRoll = -strafeNorm * StrafeRollStrength;
        targetStrafeY    =  strafeNorm * StrafePosStrength;

        StrafeRoll    += (targetStrafeRoll - StrafeRoll)    * FMin(DeltaTime * StrafeLeanSpeed, 1.0);
        StrafeOffsetY += (targetStrafeY    - StrafeOffsetY) * FMin(DeltaTime * StrafeLeanSpeed, 1.0);

        // --- Movement reaction: weapon shifts opposite to acceleration (through springs) ---
        if (DeltaTime > 0.001)
        {
            accelVec = (Instigator.Velocity - PrevVelocity) / DeltaTime;
            forcePos.X += -(accelVec dot viewX) * MoveReactStrength * 0.002;
            forcePos.Y += -(accelVec dot viewY) * MoveReactStrength * 0.002;
            forcePos.Z += -(accelVec dot viewZ) * MoveReactStrength * 0.001;
        }
        PrevVelocity = Instigator.Velocity;
    }

    // Integrate springs
    VM_PosVel    += ( -LagSpringK * VM_PosOffset - LagSpringDamping * VM_PosVel + forcePos ) * DeltaTime;
    VM_PosOffset += VM_PosVel * DeltaTime;
    if (VSize(VM_PosOffset) > ViewLagMaxOffset)
        VM_PosOffset = Normal(VM_PosOffset) * ViewLagMaxOffset;

    VM_RotVel    += ( -RotSpringK * VM_RotOffset - RotSpringDamping * VM_RotVel + torqueRot ) * DeltaTime;
    VM_RotOffset += VM_RotVel * DeltaTime;
    if (VM_RotOffset.X > 12) VM_RotOffset.X = 12; else if (VM_RotOffset.X < -12) VM_RotOffset.X = -12;
    if (VM_RotOffset.Y > 12) VM_RotOffset.Y = 12; else if (VM_RotOffset.Y < -12) VM_RotOffset.Y = -12;
    if (VM_RotOffset.Z > 15) VM_RotOffset.Z = 15; else if (VM_RotOffset.Z < -15) VM_RotOffset.Z = -15;

    // Direct breathing offsets (NOT through the spring, so always visible)
    breathVal = Sin(Level.TimeSeconds * BreathFreq * 6.283185);
    BreathOffsetZ    = breathVal * BreathAmplitude;        // world units
    BreathPitchOffset= breathVal * BreathPitchAmplitude;   // degrees

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

    if ( (HitActor == None) || (HitActor == Other) )
        return true;
    if ( Pawn(HitActor) == None )
        return !HitActor.BlocksShotAt(Other); 
    if ( (Pawn(HitActor).Controller == None) || !Instigator.Controller.SameTeamAs(Pawn(HitActor).Controller) )
        return true;

    return false;
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
			return ( FMin(0.5*(max-curr),curr)/max ); //Thanks Epic for breaking this function in the first place
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
	MoveBobSprintMulti=2.0

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
