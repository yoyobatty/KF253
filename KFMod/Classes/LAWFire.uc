class LAWFire extends KFShotgunFire;//ProjectileFire;

function bool AllowFire()
{
	if( !KFWeapon(Weapon).bAimingRifle && PlayerController(Instigator.Controller)!=None ) // Only disallow this on human players
		return false;
	return ( Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire);
}
function ServerPlayFiring()
{
	Super.ServerPlayFiring();
	if( KFWeapon(Weapon)!=none )
		KFWeapon(Weapon).bAimingRifle = False;
	if( KFHumanPawn(Instigator)!=None )
		KFHumanPawn(Instigator).SetAiming(False);
}
function PlayFiring()
{
	Super.PlayFiring();
	if( KFWeapon(Weapon)!=none )
		KFWeapon(Weapon).bAimingRifle = False;
	if( KFHumanPawn(Instigator)!=None )
		KFHumanPawn(Instigator).SetAiming(False);
	Weapon.IdleAnim = Weapon.Default.IdleAnim;
	Weapon.GetFireMode(1).bIsFiring = False; // Stop zooming :)
}

defaultproperties
{
<<<<<<< HEAD
	MaxAccuracyBonus=0.100000
	CrouchedAccuracyBonus=0.100000
	KickMomentum=(X=-45.000000,Z=25.000000)
	ProjPerFire=1
	ProjSpawnOffset=(X=100.000000)
	bSplashDamage=True
	bRecommendSplashDamage=True
	PreFireTime=0.250000
	TransientSoundVolume=100.000000
	FireAnim="AimFire"
	FireSound=Sound'KFWeaponSound.LAWFire'
	FireForce="redeemer_shoot"
	FireRate=3.250000
	AmmoClass=Class'KFMod.LAWAmmo'
	ShakeRotMag=(X=100.000000,Y=100.000000,Z=100.000000)
	ShakeOffsetMag=(X=20.000000,Y=20.000000,Z=20.000000)
	ProjectileClass=Class'KFMod.LAWProj'
	BotRefireRate=3.250000
	FlashEmitterClass=Class'KFMod.ShotgunMuzzFlash'
	Spread=1.000000
=======
     MaxAccuracyBonus=0.100000
     CrouchedAccuracyBonus=0.100000
     KickMomentum=(X=-45.000000,Z=25.000000)
     bRandomPitchFireSound=False
     ProjPerFire=1
     ProjSpawnOffset=(X=50.000000,Z=0.000000)
     bSplashDamage=True
     bRecommendSplashDamage=True
     bWaitForRelease=True
     PreFireTime=0.000000
     TransientSoundVolume=100.000000
     FireAnim="AimFire"
     FireSound=Sound'KFWeaponSound.LAWFire'
     FireForce="redeemer_shoot"
     FireRate=3.250000
     AmmoClass=Class'KFMod.LAWAmmo'
     ShakeRotMag=(X=100.000000,Y=100.000000,Z=100.000000)
     ShakeOffsetMag=(X=20.000000,Y=20.000000,Z=20.000000)
     ProjectileClass=Class'KFMod.LAWProj'
     BotRefireRate=0.500000
     FlashEmitterClass=Class'KFMod.ShotgunMuzzFlash'
     Spread=0.050000
     WarnTargetPct=0.900000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
