//=============================================================================
// 50Cal.
//=============================================================================

class MountedCalWeapon extends Weapon_Turret_Minigun;

<<<<<<< HEAD
=======
simulated function ClientStartFire(int mode)
{
        Super(Weapon).ClientStartFire( mode );
}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated function float ChargeBar()
{
	local float CurrentClip, MaxClip;

        CurrentClip = ammoAmount(0);
	MaxClip = MaxAmmo(0) ;

	return FMin(1, CurrentClip/MaxClip);
}

<<<<<<< HEAD

=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
function bool AddAmmo(int AmmoToAdd, int Mode)
{
       AmmoCharge[mode] = Min(MaxAmmo(mode), AmmoCharge[mode]+AmmoToAdd);

        return true;

    if (Ammo[Mode] != None)
        return Ammo[Mode].AddAmmo(AmmoToAdd);
}

defaultproperties
{
<<<<<<< HEAD
	FireModeClass(0)=Class'KFMod.MountedCalFire'
	FireModeClass(1)=None
	bShowChargingBar=True
	CustomCrosshair=7
	CustomCrossHairColor=(A=0)
	CustomCrossHairScale=0.000000
	CustomCrossHairTextureName="Crosshairs.HUD.Crosshair_Cross1"
	AttachmentClass=Class'KFMod.MountedCalAttachment'
	Mesh=SkeletalMesh'KFVehicleModels.50Cal'
=======
     FireModeClass(0)=Class'KFMod.MountedCalFire'
     FireModeClass(1)=None
     bShowChargingBar=True
     CustomCrossHairColor=(A=0)
     CustomCrossHairScale=0.000000
     AttachmentClass=Class'KFMod.MountedCalAttachment'
     Mesh=SkeletalMesh'KFVehicleModels.50Cal'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
