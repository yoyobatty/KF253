//=============================================================================
// Syringe Inventory class
//=============================================================================
class Syringe extends KFMeleeGun;

var () float AmmoRegenRate;
var () int HealBoostAmount;
Const MaxAmmoCount=500;
var float RegenTimer;

simulated function MaxOutAmmo()
{
	AmmoCharge[0] = MaxAmmoCount;
}
simulated function SuperMaxOutAmmo()
{
	AmmoCharge[0] = 999;
}
simulated function int MaxAmmo(int mode)
{
	Return MaxAmmoCount;
}
simulated function FillToInitialAmmo()
{
	AmmoCharge[0] = MaxAmmoCount;
}
simulated function int AmmoAmount(int mode)
{
	Return AmmoCharge[0];
}
simulated function bool AmmoMaxed(int mode)
{
	Return AmmoCharge[0]>=MaxAmmoCount;
}
simulated function GetAmmoCount(out float MaxAmmoPrimary, out float CurAmmoPrimary)
{
	MaxAmmoPrimary = MaxAmmoCount;
	CurAmmoPrimary = AmmoCharge[0];
}
simulated function float AmmoStatus(optional int Mode) // returns float value for ammo amount
{
	Return float(AmmoCharge[0])/float(MaxAmmoCount);
}
simulated function bool ConsumeAmmo(int Mode, float load, optional bool bAmountNeededIsMax)
{
	if( Load>AmmoCharge[0] )
		Return False;
	AmmoCharge[0]-=Load;
	Return True;
}
function bool AddAmmo(int AmmoToAdd, int Mode)
{
	if( AmmoCharge[0]<MaxAmmoCount )
	{
		AmmoCharge[0]+=AmmoToAdd;
		if( AmmoCharge[0]>MaxAmmoCount )
			AmmoCharge[0] = MaxAmmoCount;
	}
	Return False;
}
simulated function bool HasAmmo()
{
	Return (AmmoCharge[0]>0);
}
simulated function CheckOutOfAmmo()
{
	if( AmmoCharge[0]<=0 )
		OutOfAmmo();
}

simulated function float RateSelf()
{
	return -100;
}

simulated function Tick(float dt)
{
	if ( Level.NetMode!=NM_Client && AmmoCharge[0]<MaxAmmoCount && RegenTimer<Level.TimeSeconds )
	{
		RegenTimer = Level.TimeSeconds+AmmoRegenRate;
		if( KFPawn(Instigator)!=None )
			AmmoCharge[0]+=10*KFPawn(Instigator).GetVeteran().Static.GetSyringeChargeRate();
		else AmmoCharge[0]+=10;
		if( AmmoCharge[0]>MaxAmmoCount )
			AmmoCharge[0] = MaxAmmoCount;
	}
}

simulated function float ChargeBar()
{
	return FClamp(float(AmmoCharge[0])/float(MaxAmmoCount),0,1);
}

simulated function HealthBoost(); //OBSOLOTE!

defaultproperties
{
     AmmoRegenRate=0.300000
     HealBoostAmount=20
     weaponRange=90.000000
     MeleeHitSounds(0)=Sound'KFPawnDamageSound.MeleeDamageSounds.axehitflesh'
     Weight=0.000000
     bKFNeverThrow=True
     bAmmoHUDAsBar=True
     FireModeClass(0)=Class'KFMod.SyringeFire'
     FireModeClass(1)=Class'KFMod.SyringeAltFire'
     AIRating=-2.000000
     bMeleeWeapon=False
     bShowChargingBar=True
     AmmoCharge(0)=500
     DisplayFOV=85.000000
     Priority=40
     SmallViewOffset=(X=6.000000,Y=12.000000,Z=-50.000000)
     CenteredOffsetY=-5.000000
     CenteredRoll=3000
     InventoryGroup=6
     GroupOffset=2
     PickupClass=Class'KFMod.SyringePickup'
     PlayerViewOffset=(X=1.000000,Y=9.500000,Z=-36.000000)
     PlayerViewPivot=(Pitch=5400)
     BobDamping=8.000000
     AttachmentClass=Class'KFMod.SyringeAttachment'
     IconCoords=(X1=169,Y1=39,X2=241,Y2=77)
     ItemName="Med-Syringe"
     Mesh=SkeletalMesh'KFWeaponModels.Syringe'
     AmbientGlow=2
}
