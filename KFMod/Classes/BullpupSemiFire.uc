//=============================================================================
 //L85 Fire
//=============================================================================
class BullpupSemiFire extends KFFire;

var float ClickTime;
var vector  KickMomentum;
var bool bZoomed;


function Recoil()
{
	local Rotator NewRotation;
	local float NewPitch, NewYaw;

	if ( (Instigator != None) && Instigator.IsFirstPerson())
	{
		NewPitch = int(Frand()*240); NewYaw = int(Frand()*330);
		if (Frand() > 0.5)
			NewYaw *= -1;
		if (Frand() > 0.5)
			NewPitch *= -1;
		NewRotation = Instigator.GetViewRotation();
		NewRotation.Pitch += NewPitch;
		NewRotation.Yaw += NewYaw;
		Instigator.SetViewRotation(NewRotation);
	}
}

simulated function bool AllowFire()
{
	if (Super.AllowFire())
		return true;
	else
	{
		if ( (PlayerController(Instigator.Controller) != None) && (Level.TimeSeconds > ClickTime) )
		{
			Instigator.PlaySound(Sound'WeaponSounds.P1Reload5');
			ClickTime = Level.TimeSeconds + 0.25;
		}
		return false;
	}
}

defaultproperties
{
	KickMomentum=(X=-1.500000,Z=1.000000)
	DamageType=Class'KFMod.DamTypeBullpup'
	DamageMin=15
	DamageMax=20
	Momentum=10000.000000
	bWaitForRelease=True
	TransientSoundVolume=20.000000
	FireEndAnim=
	FireSound=Sound'KFWeaponSound.L85Fire'
	FireForce="AssaultRifleFire"
	FireRate=0.110000
	AmmoClass=Class'KFMod.BullpupAmmo'
	AmmoPerFire=1
	ShakeRotMag=(X=50.000000,Y=50.000000,Z=50.000000)
	ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
	ShakeRotTime=2.000000
	ShakeOffsetMag=(X=1.000000,Y=1.000000,Z=1.000000)
	ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
	ShakeOffsetTime=2.000000
	BotRefireRate=0.120000
	FlashEmitterClass=Class'KFMod.BullpupMuzzFlash'
	aimerror=0.000000
}
