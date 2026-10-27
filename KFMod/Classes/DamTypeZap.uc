// The upgraded flamethrower's lightning (FlameBurstFire.Zap): fire damage as far as perks, stats and burning go, without
// the fire's own puffs at every strike
class DamTypeZap extends DamTypeFlamethrower
	abstract;

static function GetHitEffects(out class<xEmitter> HitEffects[4], int VictimHealth)
{
}

defaultproperties
{
     DeathString="%k electrocuted %o (Blue Inferno)."
     FemaleSuicide="%o electrocuted herself."
     MaleSuicide="%o electrocuted himself."
}
