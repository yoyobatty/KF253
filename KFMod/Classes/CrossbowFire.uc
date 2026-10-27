class CrossbowFire extends KFShotgunFire;

simulated function bool AllowFire()
{
	return (KFWeapon(Weapon).FireAmmo(ThisModeNum) >= AmmoPerFire);
}

function float MaxRange()
{
    return 10000;
}

// An upgraded crossbow's bolts stick and blow up (the flamethrower's fire is this class's too)
function DoFireEffect()
{
	if ( Crossbow(Weapon) != None )
	{
		if ( Upgraded() )
			ProjectileClass = class'CrossbowArrowStinger';
		else
			ProjectileClass = default.ProjectileClass;
	}
	Super.DoFireEffect();
}

defaultproperties
{
	MechSound=Sound'KFWeaponSound.XbowString'
	MechVolume=0.250000
	MechPitch=1.300000
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
