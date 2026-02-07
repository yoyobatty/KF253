class DamTypeBullpup extends KFWeaponDamageType
	abstract;

static function AwardDamage( KFPlayerStats Other, int dmg )
{
	Other.ReceiveDamage(dmg,true,false);
}

defaultproperties
{
	WeaponClass=Class'KFMod.Bullpup'
	DeathString="(#FF0101)%k killed %o (Bullpup)."
	FemaleSuicide="%o shot herself in the foot."
	MaleSuicide="%o shot himself in the foot."
}
