class DamTypeBullpup extends KFWeaponDamageType
	abstract;

static function AwardDamage( KFPlayerStats Other, int dmg )
{
	Other.ReceiveDamage(dmg,true,false);
}

defaultproperties
{
<<<<<<< HEAD
	WeaponClass=Class'KFMod.Bullpup'
	DeathString="(#FF0101)%k killed %o (Bullpup)."
	FemaleSuicide="%o shot herself in the foot."
	MaleSuicide="%o shot himself in the foot."
=======
     WeaponClass=Class'KFMod.Bullpup'
     DeathString="ÿ%k killed %o (Bullpup)."
     FemaleSuicide="%o shot herself in the foot."
     MaleSuicide="%o shot himself in the foot."
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
