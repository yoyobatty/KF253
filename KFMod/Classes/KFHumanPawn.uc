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
var() float JumpCrouchBonus;   // Jump height multiplier for crouching
var() float JumpCrouchTime;

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
	//PC = PlayerController(Controller);
	PhysicsVolume.GroundFriction = 4.000000; //default is 8, this feels more natural, like there's a slight bit of slip to the floor
}

Simulated function tick(float DeltaTime)
{
	super.Tick(DeltaTime);

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
	NewVolume.GroundFriction = 4.000000; //default is 8, this feels more natural, like there's a slight bit of slip to the floor
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
		TakeFireDamage(LastBurnDamage + rand(2) + 3 , BurnInstigator);
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

	if( bDeleteMe || Health <= 0 )
		return;

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
	local vector BileVect;

	local int RandBileDamage;
    local int actualDamage;
    local vector HitMomentum;

	RandBileDamage = 2+Rand(2);

    if (bDeleteMe || Health <= 0)
        return;

    Super(XPawn).TakeDamage(RandBileDamage, BileInstigator, Location, vect(0,0,0), class'DamTypeVomit');
    healthtoGive-=5;

    HitMomentum = vect(0,0,0);
    actualDamage = Level.Game.ReduceDamage(RandBileDamage, self, BileInstigator, Location, HitMomentum, class'DamTypeVomit');

    if( actualDamage <= 0 )
    {
        return;
    }

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
	StopBlurTime = Level.TimeSeconds+3;
	if(!bUsingHitBlur)
	{
		//reset to false if need be.
		SetTimer(1.5,true);

		if( !PlatformIsMacOS() && !PlatformIsUnix())
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
		PlayerController(Controller).StopViewShaking();
		bUsingHitBlur=false;
	}
}

simulated function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	StopHitCamEffects();
	log("Died: "$self$" Killer: "$Killer$" DamageType: "$damageType$" HitLocation: "$HitLocation);
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

simulated event ModifyVelocity(float DeltaTime, vector OldVelocity)
{
    local float HealthMod, SprintMod, WeightMod;
	local float EncumbrancePercentage;
	local float InitialCrouchSpeed, CrouchDecayRate;

    super.ModifyVelocity(DeltaTime, OldVelocity);

	if (Controller == none)
		return;
	
	// Calculate encumbrance, but cap it to the maxcarryweight so when we use dev weapon cheats we don't move mega slow
	EncumbrancePercentage = (FMin(CurrentWeight, MaxCarryWeight)/MaxCarryWeight);
	// Calculate the weight modifier to speed
	WeightMod = (1.0 - (EncumbrancePercentage * 0.13));
	// Calculate the health modifier to speed
	HealthMod = ((Health/HealthMax) * HealthSpeedModifier) + (1.0 - HealthSpeedModifier);
	if(bIsSprinting || Physics == PHYS_Falling)
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
		//Check if we are falling too, as we wouldn't want to reduce or crouch multiplayer if still falling
		if(Physics != PHYS_Falling)
			CrouchedPct = FClamp(CrouchedPct - (DeltaTime * CrouchDecayRate), default.CrouchedPct, InitialCrouchSpeed);
	}
	else
	{
		CrouchedPct = FClamp(CrouchedPct + (DeltaTime * 200), default.CrouchedPct, InitialCrouchSpeed);
	}
	if(VSize(Velocity) < 1.f)
		bIsSprinting = False;
}

event EndCrouch(float HeightAdjust)
{	
    CrouchEndTime = Level.TimeSeconds;
    Super.EndCrouch(HeightAdjust);
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
            Velocity.Z -= JumpZ * JumpCrouchBonus;
		
		SetPhysics(PHYS_Falling);
		if ( !bUpdating )
			PlayOwnedSound(GetSound(EST_Jump), SLOT_Pain, GruntVolume,,80);
        return true;
	}
    return false;
}

exec simulated function StartSprintKF()
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

exec simulated function StopSprintKF()
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
	 AccelRate=750.000000
	 SprintMulti=1.400000
	 CrouchedPct=0.500000
	 JumpCrouchBonus=0.15
	 JumpCrouchTime=0.30
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
