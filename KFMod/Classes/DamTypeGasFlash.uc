// A cloud of fuel vapour going up (KFFireGrid.Flash): fire, as far as perks, stats and burning go
class DamTypeGasFlash extends DamTypeFlamethrower
	abstract;

static function GetHitEffects(out class<xEmitter> HitEffects[4], int VictimHealth)
{
}

defaultproperties
{
     DeathString="%k's fuel cloud went up under %o."
     FemaleSuicide="%o lit her own fuel cloud."
     MaleSuicide="%o lit his own fuel cloud."
}
