//=============================================================================
// DamTypeAxeSlash
// The Executioner's flying cut (KFAxeSlash). What it kills is cut in two at the waist (KFMonster.DeathGore, CutInTwo).
//=============================================================================
class DamTypeAxeSlash extends KFWeaponDamageType
	abstract;

defaultproperties
{
     WeaponClass=Class'KFMod.Axe'
     DeathString="%k cleaved %o in two."
     FemaleSuicide="%o cut herself in two."
     MaleSuicide="%o cut himself in two."
     bIsMeleeDamage=True
     bKUseOwnDeathVel=True
     KDeathVel=250.000000
     KDeathUpKick=80.000000
     KDamageImpulse=20000.000000
     GibPerterbation=0.100000
     PawnDamageSounds(0)=Sound'KFPawnDamageSound.MeleeDamageSounds.axehitflesh'
}
