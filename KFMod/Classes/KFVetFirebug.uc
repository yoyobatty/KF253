Class KFVetFirebug extends KFVeterancyTypes
	Abstract;

static function bool QualityFor( KFPlayerStats Other )
{
	Return (Other.FlameThrowerDamage>=200);
}

static function bool FlamingNades()
{
	Return True;
}

static function int AddDamage( KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType )
{
	if( DmgType==Class'DamTypeFlamethrower' || DmgType==Class'Burned'  )
		Return InDamage*1.5;
	Return InDamage;
}

static function int ReduceDamage( KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType )
{
	if( DmgType==Class'DamTypeFlamethrower' || DmgType==Class'Burned'  )
		Return 0;
	Return InDamage;
}

static function float AddExtraAmmoFor( Class<Ammunition> AmmoType )
{
	if( AmmoType==Class'FlameAmmo' )
		Return 1.6;   // 60% more fuel
	Return 1;
}

static function float GetMagCapacityMod(KFWeapon Other)
{
	if ( Flamethrower(Other) != none )
		return 1.6;
	return 1.0;
}

// Change effective range on FLamethrower
static function int ExtraRange()
{
	Return 1.5; // he he
}

static function float GetReloadSpeedModifier( KFWeapon Other )
{
	if( FlameThrower(Other) != none )
		Return 1.5;
	Return 1;
}

static function class<DamageType> GetMAC10DamageType()
{
	return class'KFMod.DamTypeFlamethrower';
}

defaultproperties
{
	bHasPerkWeapon=true
	OnHUDIcon=Texture'KFPatch2.Firebug'
	VeterancyName="Firebug"
	VeterancyDescription="|FIREBUG ||Grenades become Incendiary|Immunity to burn damage |+50% Flamethrower damage|+50% Flamethrower range |+60% more ammo for Flamethrower|Shotgun and Bullpup get fire rounds."
	VeterancyRequirement="|REQUIREMENTS:||- Deal 20,000 damage with the Flamethrower."
}
