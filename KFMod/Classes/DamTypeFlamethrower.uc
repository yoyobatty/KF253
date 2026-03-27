class DamTypeFlamethrower extends KFWeaponDamageType
	abstract;

static function AwardDamage( KFPlayerStats Other, int dmg )
{
	Other.ReceiveDamage(dmg,false,true);
}

defaultproperties
{
     WeaponClass=Class'KFMod.FlameThrower'
     DeathString="�%k incinerated %o (Flamethrower)."
     FemaleSuicide="%o roasted herself alive."
     MaleSuicide="%o roasted himself alive."
     bNeverSevers=True
     GibModifier=0.000000
}
