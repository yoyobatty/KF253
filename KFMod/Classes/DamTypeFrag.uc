//Custom Killing Floor Frag Grenade Damage Type
class DamTypeFrag extends KFWeaponDamageType;

static function GetHitEffects(out class<xEmitter> HitEffects[4], int VictimHealth)
{
    // smoke only: a frag sets nobody alight (the Firebug's own nades burn through their own damage type)
    HitEffects[0] = class'HitSmoke';
}

defaultproperties
{
    bIsPowerWeapon=True
    WeaponClass=Class'KFMod.Frag'
    DeathString="%o filled %k's body with shrapnel."
    FemaleSuicide="%o blew up."
    MaleSuicide="%o blew up."
    bLocationalHit=False
    bKUseOwnDeathVel=True
    DamageThreshold=1
    KDamageImpulse=15000.000000
    KDeathVel=500.000000
    KDeathUpKick=300.000000
    bThrowRagdoll=True
    //bAlwaysSevers=True
    //bFlaming=True
}
