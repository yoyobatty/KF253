//=============================================================================
// BoomStick Fire
//=============================================================================
class BoomStickFire extends KFShotgunFire;

simulated function bool AllowFire()
{
	return ( Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire);
}

defaultproperties
{
     KickMomentum=(X=-105.000000,Z=55.000000)
     ProjPerFire=10
     bAttachSmokeEmitter=True
     TransientSoundVolume=150.000000
     TransientSoundRadius=500.000000
     FireSound=Sound'KFWeaponSound.DBFire'
     FireRate=2.500000
     AmmoClass=Class'KFMod.DBShotgunAmmo'
     AmmoPerFire=2
     ProjectileClass=Class'KFMod.BoomStickBullet'
     BotRefireRate=2.500000
     FlashEmitterClass=Class'KFMod.ShotgunMuzzFlash'
     aimerror=2.000000
     Spread=4000.000000
}
