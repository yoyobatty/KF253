//Custom Killing Floor Frag Grenade Damage Type
class DamTypeLAW extends KFWeaponDamageType;

static function GetHitEffects(out class<xEmitter> HitEffects[4], int VictimHealth)
{
    HitEffects[0] = class'HitSmoke';

    if( VictimHealth <= 0 )
        HitEffects[1] = class'KFHitFlame';
    else if ( FRand() < 0.8 )
        HitEffects[1] = class'KFHitFlame';
}

defaultproperties
{
    bIsPowerWeapon=True
    WeaponClass=Class'KFMod.LAW'
    DeathString="%o annihilated %k."
    FemaleSuicide="%o blew up."
    MaleSuicide="%o blew up."
    bLocationalHit=False
    bKUseOwnDeathVel=True
    DamageThreshold=1
    KDamageImpulse=18000.000000
    KDeathVel=1500.000000
    KDeathUpKick=1500.000000
    bThrowRagdoll=True
    //bAlwaysSevers=True
    bFlaming=True
}
