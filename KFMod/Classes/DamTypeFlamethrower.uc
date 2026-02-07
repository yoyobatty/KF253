class DamTypeFlamethrower extends KFWeaponDamageType
	abstract;

static function AwardDamage( KFPlayerStats Other, int dmg )
{
	Other.ReceiveDamage(dmg,false,true);
}

defaultproperties
{
<<<<<<< HEAD
	WeaponClass=Class'KFMod.FlameThrower'
	DeathString="(#FF0101)%k incinerated %o (Flamethrower)."
	FemaleSuicide="%o roasted herself alive."
	MaleSuicide="%o roasted himself alive."
=======
     WeaponClass=Class'KFMod.FlameThrower'
     DeathString="�%k incinerated %o (Flamethrower)."
     FemaleSuicide="%o roasted herself alive."
     MaleSuicide="%o roasted himself alive."
     bNeverSevers=True
     GibModifier=0.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
