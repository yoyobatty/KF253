Class KFVetSergeant extends KFVeterancyTypes
	Abstract;

static function bool QualityFor( KFPlayerStats Other )
{
<<<<<<< HEAD
	Return (Other.GamesWon>=2 && (Other.GamesWon+Other.GamesLost)>=20);
}
static function float GetSyringeChargeRate()
{
	Return 1.05;
}
static function float GetMovementSpeedModifier()
{
	Return 1.05;
}
static function int ReduceDamage( KFPawn Injured, KFMonster DamageTaker, int InDamage, class<DamageType> DmgType )
{
	Return InDamage/1.1;
}
static function int AddDamage( KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType )
{
	Return InDamage*1.05;
}
static function int AddCarryMaxWeight()
{
	Return 2;
=======
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
static function int ReduceDamage( KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType )
{
	Return InDamage/1.25;
}
static function int AddDamage( KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType )
{
	Return InDamage*1.2;
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

defaultproperties
{
	OnHUDIcon=Texture'KFPatch2.Sergeant'
	VeterancyName="Sergeant"
<<<<<<< HEAD
	VeterancyDescription="|SERGEANT||+5% recharge rate with med-syringe|+5% player movement speed|-10% of all damage types|+5 % damage to all weapons|+2 additional carry slots"
	VeterancyRequirement="|REQUIREMENTS:||- Win at least 2 games|- Play at least 20 games"
=======
	VeterancyDescription="|SERGEANT||+25% recharge rate with med-syringe|+20% heal potency|+15% player movement speed|+25% resistance to all damage|+20% damage to all weapons|+15% faster reload speed|+25% better armour|+3 additional carry slots|+15% extra ammo for all weapons"
	VeterancyRequirement="|REQUIREMENTS:||- Win at least 10 games|- Play at least 50 games"
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
