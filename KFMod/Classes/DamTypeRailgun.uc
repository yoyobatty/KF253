//=============================================================================
// DamTypeRailgun
// The railgun's slug. What it kills outright with plenty to spare comes apart (KFMonster.DeathGore).
//=============================================================================
class DamTypeRailgun extends DamTypeDeagle
	abstract;

defaultproperties
{
     WeaponClass=Class'KFMod.Railgun'
     DeathString="%k railed %o."
     KDamageImpulse=9000.000000
     HeadShotDamageMult=2.000000
     bKUseOwnDeathVel=True
     KDeathVel=1100.000000
     KDeathUpKick=350.000000
}
