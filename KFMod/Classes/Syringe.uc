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
	Super.Tick(dt);
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
simulated function Timer()
{
	Super.Timer();
	if( KFPawn(Instigator)!=None && KFPawn(Instigator).bIsQuickHealing>0 && ClientState==WS_ReadyToFire )
	{
		if( KFPawn(Instigator).bIsQuickHealing==1 )
		{
			if( !HackClientStartFire() )
			{
				if( Instigator.Health>=Instigator.HealthMax || ChargeBar()<0.75 )
					KFPawn(Instigator).bIsQuickHealing = 2; // Was healed by someone else or some other error occurred.
				SetTimer(0.2,False);
				return;
			}
			KFPawn(Instigator).bIsQuickHealing = 2;
			SetTimer(FireMode[1].FireRate+0.5,False);
		}
		else
		{
			Instigator.SwitchToLastWeapon();
			KFPawn(Instigator).bIsQuickHealing = 0;
		}
	}
	else if( ClientState==WS_Hidden && KFPawn(Instigator)!=None )
		KFPawn(Instigator).bIsQuickHealing = 0; // Weapon was changed, ensure to reset this.
}
simulated function bool HackClientStartFire()
{
	if( StartFire(1) )
	{
		if( Role<ROLE_Authority )
			ServerStartFire(1);
		FireMode[1].ModeDoFire(); // Force to start animating.
		return true;
	}
	return false;
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
     Priority=5
     SmallViewOffset=(X=6.000000,Y=12.000000,Z=-50.000000)
     CenteredOffsetY=-5.000000
     CenteredRoll=3000
     InventoryGroup=6
     GroupOffset=1
     PickupClass=Class'KFMod.SyringePickup'
     PlayerViewOffset=(X=1.000000,Y=9.500000,Z=-36.000000)
     PlayerViewPivot=(Pitch=5400)
	 PrePivot=(X=0,Y=0,Z=0)
     BobDamping=4.000000
     AttachmentClass=Class'KFMod.SyringeAttachment'
     IconCoords=(X1=169,Y1=39,X2=241,Y2=77)
     ItemName="Med-Syringe"
     Mesh=SkeletalMesh'KFWeaponModels.Syringe'
     AmbientGlow=2
	 GunLengthDist=0.000000
	 WallPivotRot=(Pitch=0,Yaw=0,Roll=0)
	 WallPivotOffset=(x=0,y=0,z=0)
}
