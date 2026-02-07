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
		Return InDamage*1.25;
	Return InDamage;
}


// Change effective range on FLamethrower
static function int ExtraRange()
{
	Return 1;
}

defaultproperties
{
	OnHUDIcon=Texture'KFPatch2.Firebug'
	VeterancyName="Firebug"
	VeterancyDescription="|FIREBUG ||Grenades become Incendiary| - near-immunity to burn damage | + 25% Flamethrower damage| +35% Flamethrower range."
	VeterancyRequirement="|REQUIREMENTS:||- Deal 20,000 damage with the Flamethrower."
}
