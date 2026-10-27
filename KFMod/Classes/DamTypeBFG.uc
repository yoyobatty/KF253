//=============================================================================
// DamTypeBFG
// The BFG 9000's ball, its zaps and its tracers (BFGBall). What it kills it mostly blows apart (KFMonster.DeathGore).
//=============================================================================
class DamTypeBFG extends DamTypeLAW
	abstract;

defaultproperties
{
     WeaponClass=Class'KFMod.BFG'
     DeathString="%k erased %o with the BFG 9000."
     FemaleSuicide="%o erased herself."
     MaleSuicide="%o erased himself."
     bFlaming=False
     KDamageImpulse=26000.000000
     KDeathVel=1800.000000
     KDeathUpKick=1800.000000
}
