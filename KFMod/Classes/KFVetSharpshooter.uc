Class KFVetSharpshooter extends KFVeterancyTypes
	Abstract;

static function bool QualityFor( KFPlayerStats Other )
{
	Return (Other.DecaptedKills>=50);
}
static function int AddDamage( KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType )
{
<<<<<<< HEAD
	if( DmgType==Class'DamTypeCrossbow' || DmgType==Class'DamTypeCrossbowHeadShot' || DmgType==Class'DamTypeWinchester' )
		Return InDamage*1.25;
=======
	if( DmgType==Class'DamTypeCrossbow' || DmgType==Class'DamTypeCrossbowHeadShot' || DmgType==Class'DamTypeWinchester' || DmgType==Class'DamTypeDeagle' || DmgType==Class'DamTypeDualies' )
		Return InDamage*1.5;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	Return InDamage;
}
static function float ModifyRecoilSpread( WeaponFire Other, out float Recoil )
{
<<<<<<< HEAD
	if( Crossbow(Other.Weapon)!=None || Winchester(Other.Weapon)!=None )
=======
	if( Crossbow(Other.Weapon)!=None || Winchester(Other.Weapon)!=None
		|| Single(Other.Weapon) != none || Dualies(Other.Weapon) != none
        || Deagle(Other.Weapon) != none )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	{
		Recoil = 0.25;
		Return Recoil;
	}
	Recoil = 1;
	Return Recoil;
}
static function float GetHeadShotDamMulti()
{
<<<<<<< HEAD
	Return 1.5;
=======
	Return 1.4;
}

static function float GetFireSpeedMod( Weapon Other )
{
	if( Winchester(Other) != none || Crossbow(Other) != none )
		Return 1.5; //Shoot 50% faster for fun
	Return 1;
}

static function float GetReloadSpeedModifier( KFWeapon Other )
{
	if ( Crossbow(Other) != none || Winchester(Other) != none || Single(Other) != none || Dualies(Other) != none|| Deagle(Other) != none )
		Return 1.5; //Reload 50% faster for fun
	Return 1;
}

static function float AddExtraAmmoFor( Class<Ammunition> AmmoType )
{
	if( AmmoType==Class'WinchesterAmmo' || AmmoType==Class'CrossbowAmmo' || AmmoType==Class'DeagleAmmo' || AmmoType==Class'SingleAmmo' )
		Return 1.25;   // 25% increase in ammo carry for Winchester / Crossbow / Pistols 
	Return 1;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

defaultproperties
{
<<<<<<< HEAD
	OnHUDIcon=Texture'KFX.SharpShooter'
	VeterancyName="Sharpshooter"
	VeterancyDescription="|SHARPSHOOTER ||+25% increased damage with Winchester / Crossbow|+50% greater headshot damage with all weapons|-75% recoil and spread with Winchester / Crossbow"
=======
	bHasPerkWeapon=true
	OnHUDIcon=Texture'KFX.SharpShooter'
	VeterancyName="Sharpshooter"
	VeterancyDescription="|SHARPSHOOTER ||+50% increased damage with Winchester / Crossbow / Pistols|+25% Ammo for Winchester / Crossbow / Pistols|+50% Faster reloading with Winchester / Crossbow / Pistols|+40% greater headshot damage with all weapons|-75% recoil and spread with Winchester / Crossbow|+50% Faster shooting with Winchester / Crossbow"
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	VeterancyRequirement="|REQUIREMENTS:||- Make at least 50 headshot kills using ranged weapons(Winchester / Crossbow)."
}
