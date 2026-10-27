//=============================================================================
// Winchester Fire
// Goes on through up to four bodies past the first, its damage halved after each (KFFire.PenetratingTrace); it
// always did full damage, so DamageMin is DamageMax.
//=============================================================================
class WinchesterFire extends KFFire;

var name FireAimingAnim;

simulated function bool AllowFire()
{
	if( KFWeapon(Weapon).bIsReloading && KFWeapon(Weapon).FireClip(ThisModeNum) < 2 )
		return false;
	if(KFPawn(Instigator).SecondaryItem!=none)
		return false;    
	if( KFPawn(Instigator).bThrowingNade )
		return false;

	if( Level.TimeSeconds - LastClickTime>FireRate )
	{
		LastClickTime = Level.TimeSeconds;
	}

	if( KFWeapon(Weapon).FireClip(ThisModeNum) < 1 )
	{
		return false;
	}

	return KFWeapon(Weapon).FireAmmo(ThisModeNum) >= AmmoPerFire;
}

function AimingSpeed()
{
	FireAnim = FireAimingAnim;
}

function NormalSpeed()
{
	FireAnim = default.FireAnim;
}

defaultproperties
{
     FlashFXClass=Class'KFMod.KFFlashWinchester'
     FireAimingAnim="AimFire"
     DamageType=Class'KFMod.DamTypeWinchester'
     DamageMin=350
     MaxPenetrations=4
     PenDamageScale=0.500000
     DamageMax=350
     Momentum=18000.000000
     bPawnRapidFireAnim=True
     bWaitForRelease=True
     bModeExclusive=False
     bAttachSmokeEmitter=True
     TransientSoundVolume=100.000000
     FireLoopAnim=
     FireEndAnim=
     FireSound=Sound'KFWeaponSound.WinchesterFire'
     FireForce="ShockRifleFire"
     FireRate=1.100000
     AmmoClass=Class'KFMod.WinchesterAmmo'
     AmmoPerFire=1
     ShakeRotMag=(X=100.000000,Y=500.000000,Z=100.000000)
     ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
     ShakeRotTime=2.000000
     ShakeOffsetMag=(X=12.000000,Y=12.000000,Z=12.000000)
     ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
     ShakeOffsetTime=2.000000
     BotRefireRate=0.650000
     FlashEmitterClass=None
     aimerror=0.000000
}
