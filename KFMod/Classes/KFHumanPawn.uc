//=============================================================================
// KFPawn - Assault
//=============================================================================
class KFHumanPawn extends KFPawn;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFSoldiers.ukx

// --- Audio/Visual ---
var Emitter Blood;
var Sound BreathingSound;
var Sound MiscSound;
var() Material InjuredOverlay, CriticalOverlay;

// --- Camera/Effects ---
var CameraEffect CameraEffectFound;
var globalconfig bool bHitBlurEnabled;
var bool bUsingHitBlur;
var float StopBlurTime;

// --- Player State ---
var int ScoreCounter;
var int AlphaAmount;
//var PlayerController PC;
var bool bAimingRifle;

// --- Inventory/Weight ---
var() float MaxCarryWeight;
var float CurrentWeight;
var() HeldWeapon RifleAtt, MeleeAtt;

// --- Torch/Flashlight ---
var() int TorchBatteryLife;
var bool bTorchOn;
var int TempScore;

// --- Movement/Physics ---
var() float SprintMulti;
var() float HealthSpeedModifier;
var bool bIsSprinting;

// --- Miscellaneous ---
var int SpeedAdjustment;
var float BaseMeleeIncrease;

// --- Crouch/Jump Parameters ---
var float  CrouchEndTime;
var float  LandedTime;
var() float JumpCrouchBonus;   // Jump height multiplier for crouching
var() float JumpCrouchTime;
var bool   bAirCrouched;       // True when we applied the mid-air crouch offset
var bool   bCrouchJumped;      // True when player was crouched at time of jump
var bool   bCrouchLanded;      // True when last landing was a crouch-landing (persists through slide window)
var() float CrouchSlideBoost;  // Horizontal speed multiplier when landing while crouched
var() float CrouchSlideWindow; // Duration (seconds) of the slide momentum window

replication
{
    reliable if (Role == ROLE_Authority)
        bIsSprinting;

	reliable if ( bNetDirty && (Role == Role_Authority) )
		bAimingRifle;

	reliable if ( bNetDirty && (Role == Role_Authority) && bNetOwner )
		CurrentWeight,MaxCarryWeight,AlphaAmount,bTorchOn,TorchBatteryLife;

	reliable if(RemoteRole == ROLE_AutonomousProxy)
		DoHitCamEffects, StopHitCamEffects;

	reliable if(Role < ROLE_Authority)
		SetAiming,ServerStartSprintKF,ServerStopSprintKF;
}

function CheckCarryWeight()
{
	local Inventory I;

	MaxCarryWeight = Default.MaxCarryWeight+GetVeteran().Static.AddCarryMaxWeight();
	if( CurrentWeight>MaxCarryWeight ) // Now carrying too much, drop something.
	{
		For( I=Inventory; I!=None; I=I.Inventory )
		{
			if( KFWeapon(I)!=None && !KFWeapon(I).bKFNeverThrow )
			{
				I.Velocity = Velocity;
				I.DropFrom(Location+VRand()*10);
				if( CurrentWeight<=MaxCarryWeight )
					Return; // Drop weapons until player is capable of carrying them all.
			}
		}
	}
}

event PreBeginPlay()
{
	Super.PreBeginPlay();
	SetTimer(1.5,true);
}

Simulated function tick(float DeltaTime)
{
	local float HeightDiff;
	local bool bDuckInput;

	super.Tick(DeltaTime);

	// --- Air-crouch: the engine's ProcessMove skips ShouldCrouch() during
	// PHYS_Falling, so bWantsToCrouch never gets set mid-air.  Read the raw
	// bDuck input directly from the controller instead. ---
	bDuckInput = (PlayerController(Controller) != None && PlayerController(Controller).bDuck != 0);
	HeightDiff = default.CollisionHeight - CrouchHeight;

	if (Physics == PHYS_Falling && bDuckInput && !bAirCrouched)
	{
		SetCollisionSize(CollisionRadius, CrouchHeight);
		// No MoveSmooth — server processes bDuck at a different time,
		// so client/server disagree on Location.Z. Corrections cause pops.
		// Collision shrinks for gameplay; camera stays via EyeHeight.
		if (bCrouchJumped)
			BaseEyeHeight = FMin(0.8 * CrouchHeight, CrouchHeight - 10);
		else
			BaseEyeHeight = default.BaseEyeHeight;
		bAirCrouched = true;
	}
	else if (bAirCrouched && Physics == PHYS_Falling && !bDuckInput)
	{
		// Don't expand collision during falling — expanding without a
		// position adjustment can push through terrain below.  Keep
		// crouch collision; Landed() restores it safely on the ground.
		BaseEyeHeight = default.BaseEyeHeight;
	}
	else if (Physics == PHYS_Falling && bCrouchJumped && !bDuckInput && !bAirCrouched)
	{
		// Crouch-jump but player released crouch before air-crouch was applied;
		// let UpdateEyeHeight smooth toward standing height.
		BaseEyeHeight = default.BaseEyeHeight;
	}

	// Safety: if grounded and standing, ensure BaseEyeHeight isn't stuck
	// low from EndCrouch's crouch-jump path (fast landings, etc.)
	if (Physics != PHYS_Falling && !bIsCrouched && !bAirCrouched && !bWantsToCrouch
	    && BaseEyeHeight < default.BaseEyeHeight)
	{
		BaseEyeHeight = default.BaseEyeHeight;
	}

	if (PlayerController(Controller) != None)
	{
		if (KFPlayerReplicationInfo(PlayerController(Controller).PlayerReplicationInfo).ThreeSecondScore > 0 && AlphaAmount > 0)
			AlphaAmount -=2;
    
		if (AlphaAmount <= 0)
		{
			KFPlayerReplicationInfo(PlayerController(Controller).PlayerReplicationInfo).ThreeSecondScore = 0;
			ScoreCounter = 0;
		}
	}
}


simulated event PhysicsVolumeChange( PhysicsVolume NewVolume )
{
    Super.PhysicsVolumeChange(NewVolume);
}

function SetAiming(bool IsAiming)
{
	bAimingRifle = IsAiming;
}

function Timer()
{
	local Actor WallActor;
	local KFBloodSplatter Streak;
	local vector WallHit, WallNormal;
	local PlayerController PCC;//,Owner;

	if (BurnDown > 0)
	{
		LastBurnDamage *= 0.5;
        TakeFireDamage(LastBurnDamage, BurnInstigator);
	}
	else
	{
		RemoveFlamingEffects();
		StopBurnFX();
	}

	// Flashlight Drain
	if(Weapon != none && KFWeapon(Weapon).FlashLight != none)
	{
		// Increment / Decrement battery life
		if (KFWeapon(Weapon).FlashLight.bHasLight && TorchBatteryLife > 0)
			TorchBatteryLife -= 10;
		else if (!KFWeapon(Weapon).FlashLight.bHasLight && TorchBatteryLife < default.TorchBatteryLife)
		{
			TorchBatteryLife += 20;
			if ( TorchBatteryLife > default.TorchBatteryLife )
			{
				TorchBatteryLife = default.TorchBatteryLife;
			}
		}
	}
	else if( TorchBatteryLife<default.TorchBatteryLife )
	{
		TorchBatteryLife += 20;
		if ( TorchBatteryLife > default.TorchBatteryLife )
		{
			TorchBatteryLife = default.TorchBatteryLife;
		}
	}

	if (Controller != none)
	{
		PCC = PlayerController(Controller);
		if(PCC != None )
		{
			if(bUsingHitBlur && Level.TimeSeconds >= StopBlurTime)
				StopHitCamEffects();
			// Update for the scoreboards.
			if (Health <= 0)
			{
				PlaySound(MiscSound,SLOT_Talk);
				return;
			}
			if ( Health < HealthMax * 0.25 )
			{
				PlaySound(BreathingSound, SLOT_Talk, ((50-Health)/5)*TransientSoundVolume,,TransientSoundRadius,, false);
				WallActor = Trace(WallHit, WallNormal, Location - 50 * Velocity, Location, false);
				Streak= spawn(class 'KFMod.KFBloodSplatter',,,vect(0,0,0), Rotation);
				if (Streak != none)
					Streak.SetRotation(Rotator(Velocity));
			}

			// Accuracy vs. Movement tweakage!  - Alex
			if (KFWeapon(Weapon) != none)
				KFWeapon(Weapon).AccuracyUpdate(vsize(Velocity));
		}

	}

	// TODO: WTF? central here
	// Instantly set the animation to arms at sides Idle if we've got no weapon (rather than Pointing an invisible gun!)
	if (Weapon != none)
	{
		if (WeaponAttachment(Weapon.ThirdPersonActor) == none && VSize(Velocity) <= 0)
			IdleWeaponAnim = IdleRestAnim;
	}
	else if (Weapon == none)
		IdleWeaponAnim = IdleRestAnim;

}

simulated function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
	if( Controller!=None && Controller.bGodMode )
		return;

	// Berserkers resist knockback from monsters
	if( InstigatedBy != none && ((KFMonster(instigatedBy)!=None && GetVeteran().default.VeterancyName=="Berserker") || KFHumanPawn(instigatedBy)!=None) )
		momentum = vect(0,0,0);

	Super.TakeDamage(Damage,instigatedBy,hitlocation,momentum,damageType);
	//log("TakeDamage: "$self$" Damage: "$Damage$" InstigatedBy: "$instigatedBy$" HitLocation: "$hitlocation$" Momentum: "$momentum$" DamageType: "$damageType);
	//Bloody Overlays
	if ((Health-Damage) <= 0.5*HealthMax)
		SetOverlayMaterial(InjuredOverlay,0, true);

	if( Controller==none || PlayerController(Controller)==None )
		return;

	// hopefully this should stop friendly fire view spazzing
	if (Level.Game.ReduceDamage(Damage, self, instigatedBy, hitLocation, Momentum, DamageType ) > 0)
		DoHitCamEffects(momentum);
}                               

function TakeBileDamage()
{
	local int RandBileDamage;
    local int actualDamage;
	local vector BileVect;
    local vector HitMomentum;

	RandBileDamage = 2+Rand(2);

    Super(XPawn).TakeDamage(RandBileDamage, BileInstigator, Location, vect(0,0,0), class'DamTypeVomit');
    healthtoGive-=5;

    HitMomentum = vect(0,0,0);
    actualDamage = Level.Game.ReduceDamage(RandBileDamage, self, BileInstigator, Location, HitMomentum, class'DamTypeVomit');

    if( actualDamage <= 0 )
        return;

	//TODO: move this sanity check to DoHitCamEffect?
	if(Controller == none || PlayerController(Controller) == None)
		return;

	if(Controller.bGodMode)
		return;

	BileVect.X=frand()*400.0-200.0;
	BileVect.Y=frand()*200.0-100.0;
	BileVect.Z=frand()*400.0-200.0;
	DoHitCamEffects( BileVect );
}

simulated function DoHitCamEffects(vector Momentum)
{
	//if(!bHitBlurEnabled)
	//	return;
	StopBlurTime = Level.TimeSeconds+3;
	if(!bUsingHitBlur)
	{
		//reset to false if need be.
		SetTimer(1.5,true);

		if( bHitBlurEnabled && !PlatformIsMacOS() && !PlatformIsUnix())
			FindCameraEffect(class 'KFmod.UnderWaterBlur');

		// this cast is OK as long as this is only called from TakeDamage,
		// where the controller is tested before this function is called
		PlayerController(Controller).ShakeView( 6000 * Normal(vector(rotator(Momentum))) , 15000 * Normal(vector(rotator(Momentum))),
			   2.0,
			   60 * (Normal(Momentum)/30),
			   vect(1,1,1)/200,
			   1);
		bUsingHitBlur = true;
	}
}

simulated function StopHitCamEffects()
{
	if(bUsingHitBlur)
	{
		RemoveCameraEffect(CameraEffectFound);
		// StopViewShaking zeroes Rate/Max/Time but leaves the current
		// ShakeRot/ShakeOffset intact.  ViewShake only decays them when
		// Rate != 0, so the residual offset persists forever.  Zero them.
		PlayerController(Controller).StopViewShaking();
		PlayerController(Controller).ShakeRot = rot(0,0,0);
		PlayerController(Controller).ShakeOffset = vect(0,0,0);
		bUsingHitBlur=false;
	}
}

simulated function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	StopHitCamEffects();
	log("Died: "$Controller.GetHumanReadableName()$" Killer: "$Killer.GetHumanReadableName()$" DamageType: "$damageType);
	Super.Died(Killer, damageType, HitLocation);
}

simulated function CameraEffect FindCameraEffect(class<CameraEffect> CameraEffectClass)
{
	local PlayerController PlayerControllerLocal;
	local int i;

	PlayerControllerLocal = Level.GetLocalPlayerController();
	if ( PlayerControllerLocal != None )
	{
		for (i = 0; i < PlayerControllerLocal.CameraEffects.Length; i++)
			if ( PlayerControllerLocal.CameraEffects[i].Class == CameraEffectClass )
			{
				CameraEffectFound = PlayerControllerLocal.CameraEffects[i];
				break;
			}
		if ( CameraEffectFound == None )
			CameraEffectFound = CameraEffect(Level.ObjectPool.AllocateObject(CameraEffectClass));
		if ( CameraEffectFound != None )
			PlayerControllerLocal.AddCameraEffect(CameraEffectFound);
	}
	return CameraEffectFound;
}


//=============================================================================
// RemoveCameraEffect
//
// Removes one reference to the CameraEffect from the CameraEffects array. If
// there are any more references to the same CameraEffect object, they remain
// there. The CameraEffect will be put back in the ObjectPool if no other
// references to it are left in the CameraEffects array.
//=============================================================================

simulated function RemoveCameraEffect(CameraEffect CameraEffect)
{
  local PlayerController PlayerControllerLocal;
  local int i;

  PlayerControllerLocal = Level.GetLocalPlayerController();
  if ( PlayerControllerLocal != None ) {
    PlayerControllerLocal.RemoveCameraEffect(CameraEffect);
    for (i = 0; i < PlayerControllerLocal.CameraEffects.Length; i++)
      if ( PlayerControllerLocal.CameraEffects[i] == CameraEffect ) {
        log(CameraEffect@"still in CameraEffects array");
        return;
      }
    log("Freeing"@CameraEffect);
    Level.ObjectPool.FreeObject(CameraEffect);
    CameraEffectFound = none;
  }
}

simulated function PrevWeapon()
{
    if ( Level.Pauser != None )
        return;

    if ( Weapon == None && Controller != None )
    {
        Controller.SwitchToBestWeapon();
        return;
    }

    if ( PendingWeapon != None )
    {
        if ( PendingWeapon.bForceSwitch )
            return;
        PendingWeapon = Inventory.PrevWeapon(None, PendingWeapon);
    }
    else
    {
        PendingWeapon = Inventory.PrevWeapon(None, Weapon);
    }

    if ( PendingWeapon != None )
        Weapon.PutDown();
}

/* NextWeapon()
- switch to next inventory group weapon
*/
simulated function NextWeapon()
{
    if ( Level.Pauser != None )
        return;

    if ( Weapon == None && Controller != None )
    {
        Controller.SwitchToBestWeapon();
        return;
    }

    if ( PendingWeapon != None )
    {
        if ( PendingWeapon.bForceSwitch )
            return;
        PendingWeapon = Inventory.NextWeapon(None, PendingWeapon);
    }
    else
    {
        PendingWeapon = Inventory.NextWeapon(None, Weapon);
    }
    if ( PendingWeapon != None && Weapon != none )
        Weapon.PutDown();
}

function bool AddInventory( inventory NewItem )
{
	if( !super.AddInventory(NewItem) )
		return false;

	if(KFWeapon(NewItem)!=none)
		CurrentWeight += KFWeapon(NewItem).Weight;
	return true;
}

// Remove Item from this pawn's inventory, if it exists.
function DeleteInventory( inventory Item )
{
	local Inventory I;
	local bool bFoundItem;

	if ( Role != ROLE_Authority )
	{
		return;
	}

	for ( I = Inventory; I != none; I = I.Inventory )
	{
		if ( I == Item )
		{
			bFoundItem = true;
		}
	}

	if ( bFoundItem )
	{
        if ( KFWeapon(Item) != none )
		{
			CurrentWeight -= KFWeapon(Item).Weight;
		}
	}

	super.DeleteInventory(Item);
}

function AddDefaultInventory()
{
	local int i;

	if( KFSPGameType(Level.Game)!=None )
	{
		Level.Game.AddGameSpecificInventory(self);
		if ( inventory != None )
			inventory.OwnerEvent('LoadOut');
		Return;
	}
	if ( IsLocallyControlled() )
	{
		for ( i=0; i<16; i++ )
			if ( RequiredEquipment[i] != "" )
				CreateInventory(RequiredEquipment[i]);

		for ( i=0; i<16; i++ )
			if ( (SelectedEquipment[i] == 1) && (OptionalEquipment[i] != "") )
				CreateInventory(OptionalEquipment[i]);

		Level.Game.AddGameSpecificInventory(self);
	}
	else
	{
		Level.Game.AddGameSpecificInventory(self);

		for ( i=15; i>=0; i-- )
			if ( (SelectedEquipment[i] == 1) && (OptionalEquipment[i] != "") )
				CreateInventory(OptionalEquipment[i]);

		for ( i=15; i>=0; i-- )
			if ( RequiredEquipment[i] != "" )
				CreateInventory(RequiredEquipment[i]);
	}

	// HACK FIXME
	if ( inventory != None )
		inventory.OwnerEvent('LoadOut');

	Controller.ClientSwitchToBestWeapon();
}
function bool CanCarry( float Weight )
{
	return ((CurrentWeight+Weight)<=MaxCarryWeight);
}

function bool PerformDodge(eDoubleClickDir DoubleClickMove, vector Dir, vector Cross)
{
	return false;
}

function bool ShowStalkers()
{
	if ( KFPlayerReplicationInfo(PlayerReplicationInfo) != none && KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none )
	{
		return KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.Static.ShowStalkers();
	}

	return false;
}

//
// Compute offset for drawing an inventory item.
//
simulated function vector CalcDrawOffset(inventory Inv)
{
	local vector DrawOffset;

	if ( Controller == None )
		return (Inv.PlayerViewOffset >> Rotation) + BaseEyeHeight * vect(0,0,1);

	DrawOffset = ((0.9/Weapon.DisplayFOV * 100 * ModifiedPlayerViewOffset(Inv)) >> GetViewRotation() );
	if ( !IsLocallyControlled() )
		DrawOffset.Z += BaseEyeHeight;
	else
	{
		DrawOffset.Z += EyeHeight;
        //if( bWeaponBob )
		//    DrawOffset += WeaponBob(Inv.BobDamping);
         DrawOffset += CameraShake();
	}
	return DrawOffset;
}


simulated event ModifyVelocity(float DeltaTime, vector OldVelocity)
{
    local float HealthMod, SprintMod, WeightMod;
	local float EncumbrancePercentage;
	local float InitialCrouchSpeed, CrouchDecayRate;
	local float Speed2D, FrictionBlend, Drop, NewSpeed, SpeedFraction;

    Super.ModifyVelocity(DeltaTime, OldVelocity);

	if (Controller == none)
		return;

	// Cancel crouch-landing slide if the player stands up — prevents
	// the inflated GroundSpeed cap from applying at full standing speed.
	if (bCrouchLanded && !bIsCrouched && !bWantsToCrouch)
		bCrouchLanded = false;

	// Calculate encumbrance, but cap it to the maxcarryweight so when we use dev weapon cheats we don't move mega slow
	EncumbrancePercentage = (FMin(CurrentWeight, MaxCarryWeight)/MaxCarryWeight);
	// Calculate the weight modifier to speed
	WeightMod = (1.0 - (EncumbrancePercentage * 0.13));
	// Calculate the health modifier to speed
	HealthMod = ((Health/HealthMax) * HealthSpeedModifier) + (1.0 - HealthSpeedModifier);
	if(!bCrouchLanded && (bIsSprinting || Physics == PHYS_Falling)) 
	{
		if(!bIsCrouched)
			SprintMod = SprintMulti;
		else SprintMod = 1.0;
		InitialCrouchSpeed = 1.5;
		CrouchDecayRate = 1.0;
	}
	else 
	{
		SprintMod = 1.0;
		InitialCrouchSpeed = 1.25;
		CrouchDecayRate = 1.5;
	}
	GroundSpeed = default.GroundSpeed * HealthMod;
	GroundSpeed *= WeightMod;
	GroundSpeed *= SprintMod;
	AccelRate = default.AccelRate * SprintMod;

	if ( KFPlayerReplicationInfo(PlayerReplicationInfo) != none && KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill != none )
	{
		GroundSpeed *= KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetMovementSpeedModifier();
		if(Weapon != none && KFWeapon(Weapon).bMeleeWeapon)
			GroundSpeed += (default.GroundSpeed * (BaseMeleeIncrease + KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill.static.GetMeleeMovementSpeedModifier()));
	}

	// Check if the player is crouching
	if (bIsCrouched)
	{
		// Gradually reduce the ground speed towards the crouch speed
		// Don't decay during falling or the landing slide window (native physics
		// scales speed by CrouchedPct — decaying it eats slide momentum).
		if(Physics != PHYS_Falling && Level.TimeSeconds - LandedTime >= CrouchSlideWindow)
			CrouchedPct = FClamp(CrouchedPct - (DeltaTime * CrouchDecayRate), default.CrouchedPct, InitialCrouchSpeed);
	}
	else if (!bCrouchLanded)
	{
		// Don't ramp up during the crouch-landing slide window — preserve
		// the default CrouchedPct that Landed set.
		CrouchedPct = FClamp(CrouchedPct + (DeltaTime * 200), default.CrouchedPct, InitialCrouchSpeed);
	}

	// Clear crouch-landed flag once the slide window expires.
	if (bCrouchLanded && Level.TimeSeconds - LandedTime >= CrouchSlideWindow)
		bCrouchLanded = false;

	// Preserve slide momentum after landing — don't let GroundSpeed cap the
	// slide velocity (including any CrouchSlideBoost) during the slide window.
	if (Physics == PHYS_Walking && bCrouchLanded && Level.TimeSeconds - LandedTime < CrouchSlideWindow)
		GroundSpeed = FMax(GroundSpeed, Sqrt(Velocity.X * Velocity.X + Velocity.Y * Velocity.Y));

	// Ground friction when not accelerating.
	if (Physics == PHYS_Walking)
	{
		if (Acceleration.X * Acceleration.X + Acceleration.Y * Acceleration.Y < 1.0)
		{
			Speed2D = Sqrt(Velocity.X * Velocity.X + Velocity.Y * Velocity.Y);
			SpeedFraction = FClamp(Speed2D / FMax(default.GroundSpeed, 1.0), 0.0, 2.0);

			if (bCrouchLanded && Level.TimeSeconds - LandedTime < CrouchSlideWindow)
			{
				// Crouch-landing slide: high momentum preservation, gentle decel
				FrictionBlend = 0.98 - (Level.TimeSeconds - LandedTime) * (0.03 / FMax(CrouchSlideWindow, 0.01));
			}
			else if (Level.TimeSeconds - LandedTime < 0.3)
			{
				// Normal landing: brief grace period but shorter
				FrictionBlend = 0.93 - (Level.TimeSeconds - LandedTime) * 0.20;
			}
			else
			{
				FrictionBlend = FMin(0.80 + 0.10 * SpeedFraction, 0.93);
			}

			Velocity.X += (OldVelocity.X - Velocity.X) * FrictionBlend;
			Velocity.Y += (OldVelocity.Y - Velocity.Y) * FrictionBlend;

			Speed2D = Sqrt(Velocity.X * Velocity.X + Velocity.Y * Velocity.Y);
			if (Speed2D > 1.0)
			{
				if (bCrouchLanded)
					Drop = default.GroundSpeed * 1.0 * DeltaTime;
				else
					Drop = Speed2D * 4.0 * DeltaTime;
				NewSpeed = FMax(Speed2D - Drop, 0.0) / Speed2D;
				Velocity.X *= NewSpeed;
				Velocity.Y *= NewSpeed;
			}
		}
	}

	if(VSize(Velocity) < 1.f && Bot(Controller) == None) //No sprinting when standing still, except for bots
		bIsSprinting = False;
}

event Landed(vector HitNormal)
{
    local float HeightDiff;
    local bool bWasCrouchLanding;
    local float Speed2D, MaxSlideSpeed, BoostedSpeed;

    bWasCrouchLanding = bAirCrouched
        && (PlayerController(Controller) != None && PlayerController(Controller).bDuck != 0);

    if (bAirCrouched)
    {
        HeightDiff = default.CollisionHeight - CrouchHeight;

        // Always restore standing collision so native crouch tracking
        // (StartCrouch/EndCrouch/bIsCrouched) stays consistent.
        MoveSmooth(vect(0,0,1) * HeightDiff);
        OldZ += HeightDiff;
        SetCollisionSize(CollisionRadius, default.CollisionHeight);

        if (PlayerController(Controller) != None && PlayerController(Controller).bDuck != 0)
        {
            // Still holding crouch — compensate EyeHeight for the upward move
            // so the camera stays at the same world position.  The engine will
            // re-crouch us next tick (StartCrouch adds HeightDiff back).
            EyeHeight -= HeightDiff;
            BaseEyeHeight = EyeHeight;
            bWantsToCrouch = true;
        }
        else
        {
            EyeHeight -= HeightDiff;
            BaseEyeHeight = default.BaseEyeHeight;
        }
        bAirCrouched = false;
    }
    else if (bCrouchJumped)
    {
        // Crouch-jump that landed before Tick applied air-crouch.
        // EndCrouch lowered BaseEyeHeight; restore it now.
        if (PlayerController(Controller) != None && PlayerController(Controller).bDuck != 0)
            bWantsToCrouch = true;
        else
            BaseEyeHeight = default.BaseEyeHeight;
    }
    bCrouchJumped = false;
    super.Landed(HitNormal);
    LandedTime = Level.TimeSeconds;

    // Crouch-landing speed boost: reward landing while holding crouch.
    // Cap so repeated crouch-landings can't compound beyond sprint speed.
    if (bWasCrouchLanding && CrouchSlideBoost > 0)
    {
        CrouchedPct = default.CrouchedPct;
        Speed2D = Sqrt(Velocity.X * Velocity.X + Velocity.Y * Velocity.Y);
        MaxSlideSpeed = default.GroundSpeed * SprintMulti * (1.0 + CrouchSlideBoost);
        if (Speed2D < MaxSlideSpeed)
        {
            BoostedSpeed = FMin(Speed2D * (1.0 + CrouchSlideBoost), MaxSlideSpeed);
            if (Speed2D > 0)
            {
                Velocity.X *= (BoostedSpeed / Speed2D);
                Velocity.Y *= (BoostedSpeed / Speed2D);
            }
        }
        bCrouchLanded = true;
    }
    else
    {
        bCrouchLanded = false;
    }
}

event StartCrouch(float HeightAdjust)
{
    // Clear landing-bob/recovery state so the recovery path's
    // FMin(lerp, BaseEyeHeight) clamp can't snap EyeHeight when
    // BaseEyeHeight drops from standing to crouch in one frame.
    bJustLanded = false;
    bLandRecovery = false;
    Super.StartCrouch(HeightAdjust);
}

event EndCrouch(float HeightAdjust)
{
    CrouchEndTime = Level.TimeSeconds;
    if (bCrouchJumped)
    {
        // Engine uncrouched for the jump — undo its position change and
        // restore crouch collision. Both client and server fire EndCrouch
        // deterministically at jump time, so no network disagreement.
        // Shrink collision BEFORE moving down — standing collision (50)
        // clips the floor and blocks the MoveSmooth.
        SetCollisionSize(CollisionRadius, CrouchHeight);
        MoveSmooth(vect(0,0,-1) * HeightAdjust);
        BaseEyeHeight = FMin(0.8 * CrouchHeight, CrouchHeight - 10);
        bAirCrouched = true;
    }
    else if (Physics == PHYS_Falling && PlayerController(Controller) != None && PlayerController(Controller).bDuck != 0)
    {
        // Engine forced uncrouch (walked off ledge) but player still holding
        // duck.  Undo the native position/collision change immediately so the
        // pawn stays crouched with no visual pop.
        // Gated on PHYS_Falling — on the ground the MoveSmooth down can
        // push the pawn into terrain; let Super handle ground uncrouching.
        SetCollisionSize(CollisionRadius, CrouchHeight);
        MoveSmooth(vect(0,0,-1) * HeightAdjust);
        BaseEyeHeight = FMin(0.8 * CrouchHeight, CrouchHeight - 10);
        bAirCrouched = true;
    }
    else
    {
        Super.EndCrouch(HeightAdjust);
    }
}

simulated event UpdateEyeHeight(float DeltaTime)
{
    local float MaxEyeHeight;
    local Actor HitActor;
    local vector HitLocation, HitNormal;

    super.UpdateEyeHeight(DeltaTime);

    // While air-crouched, lock EyeHeight so the native stair-smoothing
    // formula (which uses OldZ) can't fight our MoveSmooth offset.
    // Clamp against ceiling trace so the camera can't poke through
    // low ceilings (collision is shorter than standing eye height).
    if (bAirCrouched)
    {
        HitActor = Trace(HitLocation, HitNormal,
            Location + (CollisionHeight + MAXSTEPHEIGHT + 14) * vect(0,0,1),
            Location + CollisionHeight * vect(0,0,1), true);
        if (HitActor == None)
            MaxEyeHeight = CollisionHeight + MAXSTEPHEIGHT;
        else
            MaxEyeHeight = HitLocation.Z - Location.Z - 14;

        EyeHeight = FClamp(BaseEyeHeight, -0.5 * CollisionHeight, MaxEyeHeight);
    }
}

//Player Jumped
function bool DoJump( bool bUpdating )
{
	if ( ((Physics == PHYS_Walking) || (Physics == PHYS_Ladder) || (Physics == PHYS_Spider)) )
	{
		if ( Role == ROLE_Authority )
		{
			if ( (Level.Game != None) && (Level.Game.GameDifficulty > 2) )
				MakeNoise(0.1 * Level.Game.GameDifficulty);
			if ( bCountJumps && (Inventory != None) )
				Inventory.OwnerEvent('Jumped');
		}
		if ( Physics == PHYS_Spider )
			Velocity = JumpZ * Floor;
		else if ( Physics == PHYS_Ladder )
			Velocity.Z = 0;
		else if ( bIsWalking )
			Velocity.Z = Default.JumpZ;
		else
			Velocity.Z = JumpZ;
		if ( (Base != None) && !Base.bWorldGeometry )
			Velocity += Base.Velocity;

        if( bIsCrouched || bWantsToCrouch || Level.TimeSeconds - CrouchEndTime < JumpCrouchTime )
		{
            Velocity.Z -= JumpZ * JumpCrouchBonus;
			bCrouchJumped = true;
		}
		
		SetPhysics(PHYS_Falling);
		if ( !bUpdating )
			PlayOwnedSound(GetSound(EST_Jump), SLOT_Pain, GruntVolume,,80);
        return true;
	}
    return false;
}

simulated function StartSprintKF()
{
	if(!bIsSprinting && !bIsCrouched)
		bIsSprinting = True;
	ServerStartSprintKF();
}

function ServerStartSprintKF()
{
	if(!bIsSprinting && !bIsCrouched)
		bIsSprinting = True;
}

simulated function StopSprintKF()
{
	if(bIsSprinting)
		bIsSprinting = False;
	ServerStopSprintKF();
}

function ServerStopSprintKF()
{
	if(bIsSprinting)
		bIsSprinting = False;
}

// No more File cabinet surfing bots please!
singular event BaseChange()
{
	Super.BaseChange();
	if ( AIController(Controller)!=None && KActor(Base)!=None )
		JumpOffPawn();
}

simulated function DisplayDebug(Canvas Canvas, out float YL, out float YPos)
{
	super.DisplayDebug(Canvas, YL, YPos);

    Canvas.SetDrawColor(255,128,0);
    Canvas.DrawText("CrouchedPct: " @ CrouchedPct @ " Sprinting: " @ bIsSprinting @ " GroundSpeed: " @ GroundSpeed);
    YPos += YL;
    Canvas.SetPos(4,YPos);
}


defaultproperties
{
	BreathingSound=Sound'KFPlayerSound.Malebreath'
	BaseMeleeIncrease=0.200000
	MaxCarryWeight=15.000000
	InjuredOverlay=Shader'KFCharacters.BloodiedShader'
	CriticalOverlay=Shader'KFCharacters.BloodiedShader'
	TorchBatteryLife=500
	GruntVolume=10.000000
	RequiredEquipment(0)="KFMod.Knife"
	RequiredEquipment(1)="KFMod.Single"
	RequiredEquipment(2)="KFMod.Frag"
	RequiredEquipment(3)="KFMod.Syringe"
	RequiredEquipment(4)="KFMod.Welder"
	bCanDodgeDoubleJump=False
	bCanDoubleJump=False
	bCanWallDodge=False
	bCanWalkOffLedges=True
	MultiJumpRemaining=0
	MaxMultiJump=0
	GroundSpeed=200.000000
	WaterSpeed=200.000000
	AirSpeed=400.000000
	JumpZ=325.000000
	AirControl=0.150000
	MaxFallSpeed=700.000000
	BaseEyeHeight=48.000000
	EyeHeight=48.000000
	CrouchHeight=28.000000
	AccelRate=1500.000000
	SprintMulti=1.400000
	CrouchedPct=0.500000
	JumpCrouchBonus=0.350000
	JumpCrouchTime=0.300000
	CrouchSlideBoost=0.300000
	CrouchSlideWindow=0.800000
	HealthSpeedModifier=0.300000
	ControllerClass=Class'KFMod.KFInvasionBot'
	CrouchTurnRightAnim="CrouchR"
	CrouchTurnLeftAnim="CrouchL"
	bDramaticLighting=False
	Mesh=SkeletalMesh'KFSoldiers.Soldier'
	Skins(0)=Texture'KFCharacters.DavinSkin'
	Skins(1)=Shader'KFCharacters.GasMaskShader'
	CollisionHeight=50.000000
}
