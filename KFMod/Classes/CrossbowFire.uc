class CrossbowFire extends KFShotgunFire;

simulated function bool AllowFire()
{
	return (Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire);
}

function float MaxRange()
{
    return 10000;
}

defaultproperties
{
     bRandomPitchFireSound=False
     ProjPerFire=1
     ProjSpawnOffset=(Y=0.000000,Z=0.000000)
     TransientSoundVolume=40.000000
     FireSound=Sound'KFWeaponSound.XbowFire'
     FireForce="AssaultRifleFire"
     FireRate=1.800000
     AmmoClass=Class'KFMod.CrossbowAmmo'
     ShakeRotMag=(X=3.000000,Y=4.000000,Z=2.000000)
     ShakeOffsetMag=(X=3.000000,Y=3.000000,Z=3.000000)
     ProjectileClass=Class'KFMod.CrossbowArrow'
     BotRefireRate=0.700000
     FlashEmitterClass=None
     aimerror=1.000000
     Spread=0.750000
     SpreadStyle=SS_None
}
