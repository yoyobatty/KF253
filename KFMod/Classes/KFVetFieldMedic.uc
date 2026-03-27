Class KFVetFieldMedic extends KFVeterancyTypes
	Abstract;

static function bool QualityFor( KFPlayerStats Other )
{
	Return (Other.TotalHealed>=1000);
}
static function float GetSyringeChargeRate()
{
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
}

defaultproperties
{
     OnHUDIcon=Texture'KFX.MEDIC'
     VeterancyName="Field Medic"
     VeterancyDescription="|MEDIC ||+100% recharge rate with med-syringe|+50% potency of medical injections|+5% player movement speed|-50% damage from bloat bile"
     VetButtonStyle="VetStyleMedic"
}
