//Custom Killing Floor Frag Grenade Damage Type
class DamTypeFrag extends KFWeaponDamageType;

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
	WeaponClass=Class'KFMod.Frag'
	DeathString="%o filled %k's body with shrapnel."
	FemaleSuicide="%o blew up."
	MaleSuicide="%o blew up."
	bKUseOwnDeathVel=True
	DamageThreshold=1
	KDamageImpulse=15000.000000
	KDeathVel=800.000000
	KDeathUpKick=800.000000
}
