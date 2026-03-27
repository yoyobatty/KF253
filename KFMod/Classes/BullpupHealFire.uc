//=============================================================================
// MP7M Alt Fire that shoots healing projectiles
//=============================================================================
class BullpupHealFire extends KFShotgunFire;

simulated function bool AllowFire()
{
	if(KFWeapon(Weapon).bIsReloading)
		return false;
	if(KFPawn(Instigator).SecondaryItem!=none)
		return false;
	if(KFPawn(Instigator).bThrowingNade)
		return false;

	return Bullpup(Weapon).HealAmmoCharge >= AmmoPerFire;
}

defaultproperties
{
    ProjPerFire=1
    bWaitForRelease=True
    bAttachSmokeEmitter=True
    TransientSoundVolume=2.000000
    TransientSoundRadius=500.000000
    FireRate=0.500000
    AmmoPerFire=250
    ShakeRotMag=(X=50.000000,Y=50.000000,Z=400.000000)
    ShakeRotRate=(X=12500.000000,Y=12500.000000,Z=12500.000000)
    ShakeRotTime=5.000000
    ShakeOffsetMag=(X=6.000000,Y=2.000000,Z=10.000000)
    ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
    ShakeOffsetTime=3.000000
    ProjectileClass=Class'KFMod.BullpupHealingProj'
    FlashEmitterClass=None
    FireSound=None
    BotRefireRate=0.250000
    aimerror=1.000000
    Spread=0.000000
}
