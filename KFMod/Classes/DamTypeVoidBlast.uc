//=============================================================================
// DamTypeVoidBlast
// The shock wave the Void Executioner's wielder arrives in (KFAxeVoidSlash.Shock): a blast, so what it kills is torn up
// and thrown (KFMonster.DeathGore).
//=============================================================================
class DamTypeVoidBlast extends DamTypeLAW
	abstract;

defaultproperties
{
     WeaponClass=Class'KFMod.AxeVoid'
     DeathString="%o was in the way when %k came through the void."
     FemaleSuicide="%o tore herself through the void."
     MaleSuicide="%o tore himself through the void."
}
