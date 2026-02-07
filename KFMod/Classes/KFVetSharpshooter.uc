Class KFVetSharpshooter extends KFVeterancyTypes
	Abstract;

static function bool QualityFor( KFPlayerStats Other )
{
	Return (Other.DecaptedKills>=50);
}
static function int AddDamage( KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType )
{
	if( DmgType==Class'DamTypeCrossbow' || DmgType==Class'DamTypeCrossbowHeadShot' || DmgType==Class'DamTypeWinchester' )
		Return InDamage*1.25;
	Return InDamage;
}
static function float ModifyRecoilSpread( WeaponFire Other, out float Recoil )
{
	if( Crossbow(Other.Weapon)!=None || Winchester(Other.Weapon)!=None )
	{
		Recoil = 0.25;
		Return Recoil;
	}
	Recoil = 1;
	Return Recoil;
}
static function float GetHeadShotDamMulti()
{
	Return 1.5;
}

defaultproperties
{
	OnHUDIcon=Texture'KFX.SharpShooter'
	VeterancyName="Sharpshooter"
	VeterancyDescription="|SHARPSHOOTER ||+25% increased damage with Winchester / Crossbow|+50% greater headshot damage with all weapons|-75% recoil and spread with Winchester / Crossbow"
	VeterancyRequirement="|REQUIREMENTS:||- Make at least 50 headshot kills using ranged weapons(Winchester / Crossbow)."
}
