Class KFVetSergeant extends KFVeterancyTypes
	Abstract;

static function bool QualityFor( KFPlayerStats Other )
{
	Return (Other.GamesWon>=10 && (Other.GamesWon+Other.GamesLost)>=50);
}
static function float GetSyringeChargeRate()
{
	Return 1.25;
}
static function float GetHealPotency()
{
	Return 1.20;
}
static function float GetMovementSpeedModifier()
{
	Return 1.15;
}
static function float GetRecoilMovementSpeedModifier()
{
	Return 0.25;
}
static function int ReduceDamage( KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType )
{
	Return InDamage/1.25;
}
static function int AddDamage( KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType )
{
	Return InDamage*1.2;
}
static function float GetHeadShotDamMulti()
{
    Return 1.20;
}
static function float AddExtraAmmoFor( Class<Ammunition> AmmoType )
{
	Return 1.15;   // 15% more ammo
}
static function int AddCarryMaxWeight()
{
	Return 3;
}
// Reduce damage when wearing Armor
static function float GetBodyArmorDamageModifier()
{
	return 0.75;
}
static function float GetReloadSpeedModifier( KFWeapon Other )
{
	Return 1.15;
}

static function float ModifyRecoilSpread( WeaponFire Other, out float Recoil )
{
	Recoil = 0.85;
	Return Recoil;
}

static function float GetVeldSpeedModifier()
{
	Return 1.15;
}

defaultproperties
{
	OnHUDIcon=Texture'KFPatch2.Sergeant'
	VeterancyName="Sergeant"
    VeterancyDescription="|SERGEANT||+25% recharge rate with med-syringe|+20% heal potency|+15% player movement speed|+25% reduction in recoil movement penalty|+20% resistance to all damage|+20% damage to all weapons|+20% headshot damage multiplier|-15% recoil/spread for all weapons|+15% faster reload speed|+15% welding speed|+25% better armour|+3 additional carry slots|+15% extra ammo for all weapons"
	VeterancyRequirement="|REQUIREMENTS:||- Win at least 10 games|- Play at least 50 games"
}
