class DamTypeMelee extends KFWeaponDamageType
	abstract;

// A killing blow takes the part its edge passes through this often (KFMonster.BladeCut); 0 for a blunt weapon
var() float CutChance;
var() bool bChops;		// whole limbs and the head; otherwise only a forearm or the head

defaultproperties
{
     HeadShotDamageMult=1.250000
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
