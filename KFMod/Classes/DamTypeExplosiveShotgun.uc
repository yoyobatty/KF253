class DamTypeExplosiveShotgun extends DamTypeFrag;

static function GetHitEffects(out class<xEmitter> HitEffects[4], int VictimHealth)
{
    HitEffects[0] = class'HitSmoke';

    if (VictimHealth <= 0)
        HitEffects[1] = class'KFHitFlame';
    else if (FRand() < 0.8)
        HitEffects[1] = class'KFHitFlame';
}

defaultproperties
{
    bIsPowerWeapon=True
    WeaponClass=Class'KFMod.Shotgun'
    DeathString="%o was blown apart by %k's explosive shell."
    FemaleSuicide="%o blew themselves up."
    MaleSuicide="%o blew themselves up."
    bLocationalHit=False
    bKUseOwnDeathVel=True
    DamageThreshold=1
    KDamageImpulse=20000.000000
    KDeathVel=1200.000000
    KDeathUpKick=1200.000000
    bThrowRagdoll=True
}
