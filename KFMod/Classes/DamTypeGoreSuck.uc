// The Gore Cannon's vacuum (GoreCannonSuck): what it kills is thrown at the barrel, to be swallowed
class DamTypeGoreSuck extends KFWeaponDamageType
	abstract;

defaultproperties
{
     WeaponClass=Class'KFMod.GoreCannon'
     DeathString="%o was vacuumed into %k's Gore Cannon."
     FemaleSuicide="%o vacuumed herself."
     MaleSuicide="%o vacuumed himself."
     bKUseOwnDeathVel=True
     KDeathVel=900.000000
     KDeathUpKick=250.000000
}
