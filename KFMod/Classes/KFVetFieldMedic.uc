Class KFVetFieldMedic extends KFVeterancyTypes
	Abstract;

static function bool QualityFor( KFPlayerStats Other )
{
	Return (Other.TotalHealed>=1000);
}
static function float GetSyringeChargeRate()
{
	Return 2.5;
}
static function float GetHealPotency()
{
	Return 2.0;
}
static function float GetMovementSpeedModifier()
{
	Return 1.25;
}
static function int ReduceDamage( KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType )
{
	if( DmgType==class'DamTypeVomit' )
		Return float(InDamage) * 0.25;
	Return float(InDamage)*0.8; //take 20% less because medic
}

static function bool HealingNades()
{
	Return True;
}

// Reduce damage when wearing Armor
static function float GetBodyArmorDamageModifier()
{
	return 0.25;
}

defaultproperties
{
	OnHUDIcon=Texture'KFX.MEDIC'
	VeterancyName="Field Medic"
	VeterancyDescription="|MEDIC ||+150% recharge rate with med-syringe|+75% potency of medical injections|+25% player movement speed|-75% damage from bloat bile|-20% damage taken from all damage types|+50% better armour|Healing grenades"
	VeterancyRequirement="|REQUIREMENTS:||- Heal at least 1,000 hitpoints on your team-mates"
}
