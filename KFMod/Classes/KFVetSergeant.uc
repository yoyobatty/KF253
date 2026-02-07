Class KFVetSergeant extends KFVeterancyTypes
	Abstract;

static function bool QualityFor( KFPlayerStats Other )
{
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
}

defaultproperties
{
	OnHUDIcon=Texture'KFPatch2.Sergeant'
	VeterancyName="Sergeant"
	VeterancyDescription="|SERGEANT||+5% recharge rate with med-syringe|+5% player movement speed|-10% of all damage types|+5 % damage to all weapons|+2 additional carry slots"
	VeterancyRequirement="|REQUIREMENTS:||- Win at least 2 games|- Play at least 20 games"
}
