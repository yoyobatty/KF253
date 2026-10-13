class KnifeZombiesStabFire extends KFMeleeFire;

simulated function Timer()
{
}

defaultproperties
{
	WeaponRange=65.000000
	FireAnim="Stab"
	FireAnimRate=1.200000
	damageConst=40
	maxAdditionalDamage=15
	DamagedelayMin=0.100000
	DamagedelayMax=0.300000
	hitDamageClass=Class'KFMod.DamTypeKnife'
	WideDamageMinHitAngle=0.750000
	FireRate=0.600000
	BotRefireRate=0.900000
	AmmoPerFire=0
}
