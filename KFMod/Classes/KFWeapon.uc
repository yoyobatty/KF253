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

var	float SwingPhase;
var float NewSwingPhase;	
var() Rotator SwingRot;			// Rotate the view for our swing
var() float	SwingTime;		// Time it takes to move weapon throughout swing
var() range SwingRand;		// Rand range factor for fun 

var rotator ViewLag_LastViewRot;
var vector  ViewLag_Offset;
var() float   ViewLag_StrengthYaw, ViewLag_StrengthPitch;   // How much lag (higher = more lag)
var() float   MaxLag;
var() float   TurnSpeed;

var float WallOffsetFactor, TargetWallOffsetFactor; // 0 (at wall) to 1 (far from wall)
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

    // ---------------------------------------------------------------
	SetLocation(Instigator.Location + Instigator.CalcDrawOffset(self) + WeaponOffset + (ViewLag_Offset.X * X + ViewLag_Offset.Y * Y + ViewLag_Offset.Z * Z));

    if ( Hand == 0 )
    {
        CenteredRotation = Instigator.GetViewRotation();
        CenteredRotation.Yaw += CenteredYaw + WallPivotRot.Yaw;
        CenteredRotation.Roll = CenteredRoll + WallPivotRot.Roll;
        CenteredRotation.Pitch += WallPivotRot.Pitch;
        SetRotation(CenteredRotation);
    }
    else
    {
        NewRotation = Instigator.GetViewRotation();
        NewRotation.Yaw += WallPivotRot.Yaw;
        NewRotation.Pitch += WallPivotRot.Pitch;
        NewRotation.Roll += WallPivotRot.Roll;
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
        PlayIdle();
        ClientState = WS_ReadyToFire;
        

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

            if (  DownDelay <= 0 )
            {
				if ( ClientState == WS_BringUp )
					TweenAnim(SelectAnim,PutDownTime);
				else if ( HasAnim(PutDownAnim) )
				{
					if( ClientGrenadeState == GN_TempDown )
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

    // Fix: Initialize viewmodel lag variables to prevent network glitch
    if (Instigator != None && Instigator.IsHumanControlled())
    {
        ViewLag_LastViewRot = Instigator.GetViewRotation();
        ViewLag_Offset = vect(0,0,0);
    }

	// From Weapon.uc
    if ( ClientState == WS_Hidden || ClientGrenadeState == GN_BringUp )
	{
		PlayOwnedSound(SelectSound, SLOT_Interact,,,,, false);
		ClientPlayForceFeedback(SelectForce);  // jdf

		if ( Instigator.IsLocallyControlled() )
		{
			if ( (Mesh!=None) && HasAnim(SelectAnim) )
			{
                if( ClientGrenadeState == GN_BringUp )
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
        if( ClientGrenadeState == GN_BringUp )
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
	//TickSwingCamera(DeltaTime);
	UpdateViewModelLag(DeltaTime);
	WallOffsetFactor += (TargetWallOffsetFactor - WallOffsetFactor) * FMin(DeltaTime * 8.0, 1.0);
}

simulated function UpdateViewModelLag(float DeltaTime)
{
    local rotator CurViewRot, DeltaRot;
    local vector  LagMove, VDiff;
    local float LagScale, SpeedScale;
    local float   PitchDeg;

	// Only update for the human player's weapon
    if (Instigator == None || !Instigator.IsHumanControlled())
        return;

    if (Level.NetMode != NM_Client && !Instigator.IsLocallyControlled())
        return;		

    CurViewRot = Instigator.GetViewRotation();
    DeltaRot = CurViewRot - ViewLag_LastViewRot;
	DeltaRot = Normalize(DeltaRot);

	DeltaRot.Pitch = Clamp(DeltaRot.Pitch, -8192, 8192); 
	DeltaRot.Yaw   = Clamp(DeltaRot.Yaw,   -16384, 16384); 
	LagMove.X = 0;
	LagMove.Y = -float(DeltaRot.Yaw) * ViewLag_StrengthYaw;
	LagMove.Z = -float(DeltaRot.Pitch) * ViewLag_StrengthPitch;

    PitchDeg = float(CurViewRot.Pitch) * (360.0 / 65536.0);
    if (PitchDeg > 180)       PitchDeg -= 360;
    else if (PitchDeg < -180) PitchDeg += 360;

	LagMove.X += (PitchDeg * 0.05); // slight offset based on pitch
	LagMove.Y += (PitchDeg * 0.05);
	LagMove.Z += (PitchDeg * 0.05);

	VDiff = (LagMove - ViewLag_Offset);
    // HL2-style: Fixed MaxLag, scale catch-up speed if lag is too large
	SpeedScale = TurnSpeed;
    if (VSize(VDiff) > MaxLag && MaxLag > 0.0)
	{
        LagScale = VSize(VDiff) / MaxLag;
		SpeedScale *= LagScale; // Scale catch-up speed
	}
    // Smoothly interpolate the lag offset, scaling catch-up speed if needed
	ViewLag_Offset += VDiff * SpeedScale * DeltaTime;

	// Clamp to prevent runaway values
	if (VSize(ViewLag_Offset) > 32.0)
		ViewLag_Offset = Normal(ViewLag_Offset) * 32.0;

    ViewLag_LastViewRot = CurViewRot;
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


simulated function TickSwingCamera(float DT)
{
	if( Instigator == None || !Instigator.IsHumanControlled() || PlayerController(Instigator.Controller).bBehindView )//Don't even run this if we are not a human player
		return;
	SwingPhase = SwingPhase + FClamp(NewSwingPhase - SwingPhase, -DT/SwingTime, DT/SwingTime);
	if(NewSwingPhase > 0.f)
	{
		NewSwingPhase = NewSwingPhase - FMin(NewSwingPhase, DT/SwingTime);
	}
    if (Abs(SwingPhase) < 0.001 && NewSwingPhase <= 0.0)
    {
        SwingPhase     = 0.0;
        NewSwingPhase  = 0.0;
        return;
    }
	SwingRot *= RandRange(SwingRand.Min, SwingRand.Max);
	Instigator.SetViewRotation(Instigator.GetViewRotation() + SwingRot * SwingPhase); 
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
	ViewLag_StrengthYaw=0.015000
	ViewLag_StrengthPitch=0.025000
	MaxLag=10.000000
	TurnSpeed=4.000000
	GunLengthDist=50.000000
	WallPivotRot=(Pitch=5000,Yaw=-5000,Roll=0)
	WallPivotOffset=(x=-10,y=0,z=-10)
	//PrePivot=(X=0.000000,Y=0.000000,Z=-2.000000)
	bModeZeroCanDryFire=True
}
