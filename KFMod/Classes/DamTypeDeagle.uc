class DamTypeDeagle extends KFWeaponDamageType
	abstract;

defaultproperties
{
	bIsPowerWeapon=True
	WeaponClass=Class'KFMod.Deagle'
	DeathString="(#FF0101)%k killed %o (Deagle)."
	FemaleSuicide="%o shot herself in the foot."
	MaleSuicide="%o shot himself in the foot."
	bRagdollBullet=True
	bBulletHit=True
	FlashFog=(X=600.000000)
	KDamageImpulse=9500.000000
	VehicleDamageScaling=0.800000
}
