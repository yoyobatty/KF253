//=============================================================================
// DamTypeCryo
// The cryo cannon's freezing burst. What it kills is frozen, so it shatters (KFMonster.DeathGore).
//=============================================================================
class DamTypeCryo extends KFWeaponDamageType
	abstract;

defaultproperties
{
     WeaponClass=Class'KFMod.CryoCannon'
     DeathString="%k froze %o solid."
     FemaleSuicide="%o froze herself."
     MaleSuicide="%o froze himself."
     bLocationalHit=False
     bNeverSevers=False
}
