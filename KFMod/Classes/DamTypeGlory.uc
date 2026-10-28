// A glory kill (KFMonster.GloryKill): a staggered specimen torn apart by hand, Doom style. KFMonster.GloryGore picks
// how (split, cleaved, cut in two, the top of the skull off, the arms torn off).
class DamTypeGlory extends DamTypeMelee;

defaultproperties
{
     WeaponClass=Class'KFMod.Knife'
     DeathString="%o was torn apart by %k."
     PawnDamageSounds(0)=Sound'KFPawnDamageSound.MeleeDamageSounds.axehitflesh'
     KDamageImpulse=20000.000000
     GibPerterbation=0.150000
     bAlwaysSevers=True
     VehicleDamageScaling=0.700000
}
