//=============================================================================
// Shotgun Fire
//=============================================================================
class ShotgunFire extends KFShotgunFire;

defaultproperties
{
     KickMomentum=(X=-85.000000,Z=15.000000)
     ProjPerFire=7
     bAttachSmokeEmitter=True
     TransientSoundVolume=95.000000
     TransientSoundRadius=500.000000
     FireSound=Sound'KFWeaponSound.HuntingFire'
     FireRate=1.500000
     AmmoClass=Class'KFMod.ShotgunAmmo'
     ProjectileClass=Class'KFMod.ShotgunBullet'
     BotRefireRate=1.500000
     FlashEmitterClass=Class'KFMod.ShotgunMuzzFlash'
     aimerror=1.000000
     Spread=1500.000000
}
