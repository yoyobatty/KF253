class CrossbowFire extends KFShotgunFire;

simulated function bool AllowFire()
{
	return (Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire);
}

function DoFireEffect()
{
   Super(FlakFire).DoFireEffect();
}

function Recoil( float Multi )
{
      /*
	local Rotator NewRotation;
	local float NewPitch, NewYaw;

	if ( (Instigator != None) && Instigator.IsFirstPerson())
	{
		NewPitch = int(Frand()*755); NewYaw = int(Frand()*910);
		if (Frand() > 0.5)
			NewYaw *= -1;
		if (Frand() > 0.5)
			NewPitch *= -1;
		NewRotation = Instigator.GetViewRotation();
		NewRotation.Pitch += NewPitch*Multi;
		NewRotation.Yaw += NewYaw*Multi;
		Instigator.SetViewRotation(NewRotation);
	}
	*/
}

defaultproperties
{
     ProjPerFire=1
     ProjSpawnOffset=(X=5.000000,Z=-25.000000)
     TransientSoundVolume=40.000000
     FireSound=Sound'KFWeaponSound.XbowFire'
     FireForce="AssaultRifleFire"
     FireRate=1.800000
     AmmoClass=Class'KFMod.CrossbowAmmo'
     ShakeRotMag=(X=5.000000,Y=10.000000,Z=5.000000)
     ShakeOffsetMag=(X=3.000000,Y=3.000000,Z=3.000000)
     ProjectileClass=Class'KFMod.CrossbowArrow'
     BotRefireRate=1.800000
     FlashEmitterClass=None
     aimerror=1.000000
     Spread=1.000000
     SpreadStyle=SS_None
}
