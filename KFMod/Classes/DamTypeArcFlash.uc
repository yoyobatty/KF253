//=============================================================================
// DamTypeArcFlash
// (Blue Inferno) The charged discharge (FlameAltFire.ArcFlash): lightning and burning plasma. What it kills outright it
// can blow apart (KFMonster.DeathGore).
//=============================================================================
class DamTypeArcFlash extends DamTypeZap
	abstract;

defaultproperties
{
     DeathString="%k vaporised %o with an arc flash (Blue Inferno)."
     FemaleSuicide="%o vaporised herself."
     MaleSuicide="%o vaporised himself."
     bNeverSevers=False
     GibModifier=1.500000
     GibPerterbation=0.400000
     KDamageImpulse=20000.000000
     bKUseOwnDeathVel=True
     KDeathVel=900.000000
     KDeathUpKick=700.000000
}
