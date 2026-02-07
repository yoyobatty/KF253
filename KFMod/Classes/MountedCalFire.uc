//=============================================================================
// 50Cal Fire
//=============================================================================

class MountedCalFire extends FM_Turret_Minigun_Fire;


simulated function bool AllowFire()
{
    return ( Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire);

}

defaultproperties
{
<<<<<<< HEAD
	DamageMin=25
	DamageMax=30
	Momentum=35000.000000
	TransientSoundVolume=80.000000
	FireLoopAnim="Fire"
	FireEndAnim="Fire"
	FireSound=Sound'KFWeaponSound.50CalFire'
	FireRate=0.110000
	AmmoClass=Class'KFMod.MountedCalAmmo'
	AmmoPerFire=1
	ShakeOffsetRate=(Y=-3000.000000)
	aimerror=800.000000
	Spread=0.055000
=======
     DamageMin=25
     DamageMax=30
     Momentum=35000.000000
     TransientSoundVolume=80.000000
     FireLoopAnim="Fire"
     FireEndAnim="Fire"
     FireSound=Sound'KFWeaponSound.50CalFire'
     FireRate=0.110000
     AmmoClass=Class'KFMod.MountedCalAmmo'
     AmmoPerFire=1
     ShakeOffsetRate=(Y=-3000.000000)
     aimerror=800.000000
     Spread=0.055000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
