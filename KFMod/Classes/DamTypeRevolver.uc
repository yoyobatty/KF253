//=============================================================================
// DamTypeRevolver
// The magnum revolver's rounds.
//=============================================================================
class DamTypeRevolver extends DamTypeDeagle
	abstract;

defaultproperties
{
     WeaponClass=Class'KFMod.Revolver'
     DeathString="%k blew %o away with a magnum (Revolver)."
     KDamageImpulse=5500.000000
     HeadShotDamageMult=1.600000
}
