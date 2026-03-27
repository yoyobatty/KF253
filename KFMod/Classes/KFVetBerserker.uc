Class KFVetBerserker extends KFVeterancyTypes
	Abstract;

static function bool QualityFor( KFPlayerStats Other )
{
	Return (Other.TotalMeleeDamage>=10000);
}

static function int AddDamage( KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType )
{
	if( Class<KFWeaponDamageType>(DmgType)!=None && Class<KFWeaponDamageType>(DmgType).Default.bIsMeleeDamage )
		Return InDamage*1.25;
	Return InDamage;
}
static function float GetMeleeMovementSpeedModifier()
{
	Return 0.15;
}
static function int ReduceDamage( KFPawn Injured, KFMonster DamageTaker, int InDamage, class<DamageType> DmgType )
{
	Return InDamage/1.15;
}
static function float GetFireSpeedMod( Weapon Other )
{
	if( KFMeleeGun(Other)!=None )
		Return 1.1;
	Return 1;
}

defaultproperties
{
     OnHUDIcon=Texture'KFX.Berserker'
     VeterancyName="Berserker"
     VeterancyDescription="|BERSERKER ||+ 25% damage for all melee weapons|+ 10% refire speed for all melee weapons|+ 15% movement speed adjustment when using a melee weapon|+ 15% resistance to all forms of damage"
     VetButtonStyle="VetStyleBerserk"
}
