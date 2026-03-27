class DamTypeMelee extends KFWeaponDamageType
	abstract;

defaultproperties
{
     bIsMeleeDamage=True
     WeaponClass=Class'KFMod.KFMeleeGun'
     DeathString="%o was beat down by %k."
     FemaleSuicide="%o beat herself down."
     MaleSuicide="%o beat himself down."
     bRagdollBullet=True
     bBulletHit=True
     FlashFog=(X=600.000000)
     KDamageImpulse=3500.000000
     VehicleDamageScaling=0.600000
}
