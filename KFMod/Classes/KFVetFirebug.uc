Class KFVetFirebug extends KFVeterancyTypes
	Abstract;

static function bool QualityFor( KFPlayerStats Other )
{
	Return (Other.FlameThrowerDamage>=20000);
}
static function string ProgressFor( KFPlayerStats Other )
{
	Return Tally("Flamethrower damage dealt",Other.FlameThrowerDamage,20000);
}

static function bool FlamingNades()
{
	Return True;
}

static function int AddDamage( KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType )
{
	if( DmgType==Class'DamTypeFlamethrower' || DmgType==Class'DamTypeShotgunFire' || DmgType==Class'Burned' )
		Return InDamage*1.5;
	Return InDamage;
}

static function int ReduceDamage( KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType )
{
	if( DmgType==Class'DamTypeFlamethrower' || DmgType==Class'DamTypeShotgunFire' || DmgType==Class'Burned'  )
		Return 0;
	Return InDamage;
}

static function float AddExtraAmmoFor( Class<Ammunition> AmmoType )
{
	if( AmmoType==Class'FlameAmmo' )
		Return 1.75;   // 75% more fuel
	Return 1;
}

static function float GetMagCapacityMod(KFWeapon Other)
{
	if ( Flamethrower(Other) != none )
		return 1.6;
	return 1.0;
}

// Change effective range on FLamethrower
static function float ExtraRange()
{
	Return 0.5; // +50% (as an int this 1.5 was 1: +33%)
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
	VeterancyDescription="|FIREBUG ||Grenades become Incendiary|Immunity to burn damage |+50% Flamethrower damage|+50% Flamethrower range |+75% more ammo for Flamethrower|Shotgun and Bullpup get fire rounds."
	VeterancyRequirement="|REQUIREMENTS:||- Deal 20,000 damage with the Flamethrower."
}
