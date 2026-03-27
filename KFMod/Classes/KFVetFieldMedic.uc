Class KFVetFieldMedic extends KFVeterancyTypes
	Abstract;

static function bool QualityFor( KFPlayerStats Other )
{
	Return (Other.TotalHealed>=1000);
}
static function float GetSyringeChargeRate()
{
<<<<<<< HEAD
	Return 2;
}
static function float GetHealPotency()
{
	Return 1.5;
}
static function float GetMovementSpeedModifier()
{
	Return 1.05;
}
static function int ReduceDamage( KFPawn Injured, KFMonster DamageTaker, int InDamage, class<DamageType> DmgType )
{
	if( DmgType==class'DamTypeVomit' )
		Return InDamage/2;
	Return InDamage;
=======
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

defaultproperties
{
	OnHUDIcon=Texture'KFX.MEDIC'
	VeterancyName="Field Medic"
<<<<<<< HEAD
	VeterancyDescription="|MEDIC ||+100% recharge rate with med-syringe|+50% potency of medical injections|+5% player movement speed|-50% damage from bloat bile"
=======
	VeterancyDescription="|MEDIC ||+150% recharge rate with med-syringe|+75% potency of medical injections|+25% player movement speed|-75% damage from bloat bile|-20% damage taken from all damage types|+50% better armour|Healing grenades"
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	VeterancyRequirement="|REQUIREMENTS:||- Heal at least 1,000 hitpoints on your team-mates"
}
