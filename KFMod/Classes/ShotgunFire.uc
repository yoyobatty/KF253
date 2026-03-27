//=============================================================================
// Shotgun Fire
//=============================================================================
class ShotgunFire extends KFShotgunFire;

<<<<<<< HEAD
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
=======
function DoFireEffect()
{
     if (KFPawn(Instigator).GetVeteran().default.VeterancyName == "Firebug")
          ProjectileCLass=Class'KFMod.ShotgunBulletFire';
     else ProjectileCLass=default.ProjectileCLass;

	Super.DoFireEffect();
}

defaultproperties
{
     KickMomentum=(X=-85.000000,Z=15.000000)
     bRandomPitchFireSound=False
     ProjPerFire=12
     bAttachSmokeEmitter=True
     TransientSoundVolume=95.000000
     TransientSoundRadius=500.000000
     FireSound=Sound'KFWeaponSound.HuntingFire'
     FireRate=1.100000
     AmmoClass=Class'KFMod.ShotgunAmmo'
     ProjectileClass=Class'KFMod.ShotgunBullet'
     BotRefireRate=0.700000
     FlashEmitterClass=Class'KFMod.ShotgunMuzzFlash'
     aimerror=1.000000
     Spread=1125.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
