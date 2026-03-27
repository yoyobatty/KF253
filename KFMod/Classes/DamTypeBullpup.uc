class DamTypeBullpup extends DamTypeKFSnipe
	abstract;

static function AwardDamage( KFPlayerStats Other, int dmg )
{
	Other.ReceiveDamage(dmg,True);
}

defaultproperties
{
     WeaponClass=Class'KFMod.Bullpup'
     DeathString="ÿ%k killed %o (Bullpup)."
     FemaleSuicide="%o shot herself in the foot."
     MaleSuicide="%o shot himself in the foot."
}
