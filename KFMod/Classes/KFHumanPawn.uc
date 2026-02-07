//=============================================================================
// KFPawn - Assault
//=============================================================================
class KFHumanPawn extends KFPawn;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFSoldiers.ukx
var float DrugBonusMovement;
var bool bOnDrugs;
var Emitter Blood;
var Sound BreathingSound;
//var int BreathingTime;
var Sound MiscSound; //So I can get the damn thing to shutup if the players dead.

//var UnderWaterBlur myHitBlur;
var bool bUsingHitBlur;
var float StopBlurTime;

var int SpeedAdjustment; // Give our brave melee players a little bit more under the hood.
var float BaseMeleeIncrease;

var int ScoreCounter; // Once it hits two, reset 3 second score in GRI

var bool bAimingRifle;


var CameraEffect CameraEffectFound;
var globalconfig bool           bHitBlurEnabled;   // Changed from detailsettings tab (for mac and linux users)

var () float MaxCarryWeight;

var float CurrentWeight;
var bool bMeBeDoomed;
var int AlphaAmount ; // Amount of Alpha for Cash bonus HUD.

var() Material InjuredOverlay,CriticalOverlay;

var PlayerController PC;

var () int TorchBatteryLife;
var bool bTorchOn;  // HUD var only.  
var int TempScore; // temporary score.

replication
{
	reliable if ( bNetDirty && (Role == Role_Authority) )
		bAimingRifle;

	reliable if ( bNetDirty && (Role == Role_Authority) && bNetOwner )
		CurrentWeight,MaxCarryWeight,AlphaAmount,bTorchOn,TorchBatteryLife,bOnDrugs;

	reliable if(RemoteRole == ROLE_AutonomousProxy)
		DoHitCamEffects, StopHitCamEffects;

	reliable if(Role < ROLE_Authority)
		SetAiming;
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
	PC = PlayerController(Controller);
}

Simulated function tick(float DeltaTime)
{
	super.Tick(deltaTime);

	if (PC != none)
	{
		if (KFPlayerReplicationInfo(PC.PlayerReplicationInfo).ThreeSecondScore > 0 && AlphaAmount > 0)
			AlphaAmount -=2;
    
		if (AlphaAmount <= 0)
		{
			KFPlayerReplicationInfo(PC.PlayerReplicationInfo).ThreeSecondScore = 0;
			ScoreCounter = 0;
		}
	}
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
	if (Weapon != none)
 	{
		if(KFWeapon(Weapon).FlashLight != none)
		{
			// Increment / Decrement battery life
			if (KFWeapon(Weapon).FlashLight.bHasLight && TorchBatteryLife > 0)
				TorchBatteryLife -= 10;
			else if (!KFWeapon(Weapon).FlashLight.bHasLight && TorchBatteryLife < default.TorchBatteryLife)
				TorchBatteryLife += 20;
		}
	}

	if (Controller != none)
	{
		PCC = PlayerController(Controller);
		if(PCC != None )
		{
			bOnDrugs = false;
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



		// Experience Level relate stuff .
		if (Weapon!= none && KFWeapon(Weapon).bSpeedMeUp)
		{
			// Adjust Melee weapon speed bonuses depending on perk.
                        BaseMeleeIncrease = GetVeteran().Static.GetMeleeMovementSpeedModifier() + default.BaseMeleeIncrease;
                        SpeedAdjustment = ((default.GroundSpeed * BaseMeleeIncrease) - (KFWeapon(Weapon).Weight * 2));
		}
		else if (Weapon == none || !KfWeapon(Weapon).bSpeedMeUp)
			SpeedAdjustment = 0;
		groundspeed = ((FMax(140,Health*2)) - (2 * CurrentWeight) + SpeedAdjustment)*GetVeteran().Static.GetMovementSpeedModifier();
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

	Super.TakeDamage(Damage,instigatedBy,hitlocation,momentum,damageType);

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

	super.TakeBileDamage();

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

simulated function died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	StopHitCamEffects();
	super.Died(Killer, damageType, HitLocation);
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

//This is a terribly ugly hack which allows us to silently give
//weapons to pawns in the case of buy menu consumables
function SilentGiveWeapon(string aClassName )
{
	local class<Weapon> WeaponClass;
	local Weapon NewWeapon;

	WeaponClass = class<Weapon>(DynamicLoadObject(aClassName, class'Class'));

	if( FindInventoryType(WeaponClass) != None )
		return;
	newWeapon = Spawn(WeaponClass);

	if( newWeapon != None && KFWeapon(newWeapon) != None)
		KFWeapon(newWeapon).SilentGiveTo(self);
	else if(newWeapon != none)
	    newWeapon.GiveTo(self);
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
	if(KFWeapon(Item)!=none)
		CurrentWeight -= KFWeapon(Item).Weight;
	super.DeleteInventory(Item);
}

function Drugs()
{
 local PlayerController IPC;
 IPC = PlayerController(Controller);


 // Still not sure what to do with this.
 // It's some sort of drug heightened adrenal state where the player can run faster etc...
 // Amusingly, it's incremental. So each "hit" (call of this function :P) will send you into
 // a further....enhanced state for the duration of the drug's life (30 seconds max).

 // call it like so :
 //   bOnDrugs = true;
 //   Drugs();

 if(bOnDrugs)
 {
// Log("You're on Some Drugs");
   DrugBonusMovement = 150;
   Groundspeed +=DrugBonusMovement;

   PlaySound(BreathingSound, SLOT_Talk, TransientSoundVolume,,TransientSoundRadius,, false);
   Weapon.StartBerserk();

   IPC.ShakeView(vect(30,-30,30),vect(200,-300,200),30,vect(-30,30,30),vect(300,-200,200),30);

 }

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
	Return ((CurrentWeight+Weight)<=MaxCarryWeight);
}
function bool PerformDodge(eDoubleClickDir DoubleClickMove, vector Dir, vector Cross)
{
	Return False;
}

defaultproperties
{
	BreathingSound=Sound'KFPlayerSound.Malebreath'
	BaseMeleeIncrease=0.200000
	MaxCarryWeight=15.000000
	InjuredOverlay=Shader'KFCharacters.BloodiedShader'
	CriticalOverlay=Shader'KFCharacters.BloodiedShader'
	TorchBatteryLife=500
	bCanDodgeDoubleJump=False
	GruntVolume=50.000000
	MultiJumpRemaining=0
	MaxMultiJump=0
	RequiredEquipment(0)="KFMod.Knife"
	RequiredEquipment(1)="KFMod.Single"
	RequiredEquipment(2)="KFMod.Frag"
	RequiredEquipment(3)="KFMod.Syringe"
	RequiredEquipment(4)="KFMod.Welder"
	bCanDoubleJump=False
	bCanWallDodge=False
	GroundSpeed=230.000000
	WaterSpeed=200.000000
	AirSpeed=230.000000
	AccelRate=1000.000000
	JumpZ=325.000000
	AirControl=0.150000
	MaxFallSpeed=600.000000
	BaseEyeHeight=48.000000
	EyeHeight=48.000000
	CrouchHeight=40.000000
	ControllerClass=Class'KFMod.KFInvasionBot'
	CrouchTurnRightAnim="CrouchR"
	CrouchTurnLeftAnim="CrouchL"
	bDramaticLighting=False
	Mesh=SkeletalMesh'KFSoldiers.Soldier'
	Skins(0)=Texture'KFCharacters.DavinSkin'
	Skins(1)=Shader'KFCharacters.GasMaskShader'
	CollisionHeight=50.000000
}
