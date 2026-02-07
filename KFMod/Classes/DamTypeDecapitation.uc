//=============================================================================
// DamTypeDecapitation
//=============================================================================
// Damage type for damage that decapitated someone
//=============================================================================
// Killing Floor Source
// Copyright (C) 2009 Tripwire Interactive LLC
// - John "Ramm-Jaeger" Gibson
//=============================================================================

class DamTypeDecapitation extends KFWeaponDamageType
	abstract;

defaultproperties
{
    WeaponClass=Class'KFMod.KFMeleeGun'
    DeathString="%o was beat down by %k."
    FemaleSuicide="%o beat herself down."
    MaleSuicide="%o beat himself down."
    bRagdollBullet=True
    bBulletHit=True
    FlashFog=(X=600.000000)
    VehicleDamageScaling=0.600000
    bIsMeleeDamage=True
    bLocationalHit=true
	KDamageImpulse=2000
	KDeathUpKick=25
    KDeathVel=100.000000
}
