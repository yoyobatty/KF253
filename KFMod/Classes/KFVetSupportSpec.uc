Class KFVetSupportSpec extends KFVeterancyTypes
	Abstract;

static function bool QualityFor( KFPlayerStats Other )
{
	Return (Other.TotalWelded>=2000 && Other.PowerWpnKills>=60);
}
static function int AddDamage( KFMonster Injured, KFPawn DamageTaker, int InDamage, class<DamageType> DmgType )
{
	if( DmgType==Class'DamTypeShotgun' || DmgType==Class'DamTypeDBShotgun' || DmgType==CLass'DamTypeFrag' )
		Return InDamage*1.5;
	Return InDamage;
}
static function int ReduceDamage( KFPawn Injured, Pawn Instigator, int InDamage, class<DamageType> DmgType )
{
	if( DmgType==class'DamTypeFrag' )
		Return float(InDamage) * 0.6;
	Return InDamage;
}

static function float ModifyRecoilSpread( WeaponFire Other, out float Recoil )
{
	if( ClassIsChildOf(Other.Weapon.Class, class'KFWeaponShotgun') )
	{
		Recoil = 0.75;
		Return Recoil;
	}
	Recoil = 1;
	Return Recoil;
}

static function int AddCarryMaxWeight()
{
	Return 7;  // 7 more carry slots
}
static function float GetVeldSpeedModifier()
{
	Return 2.5;
}
static function float AddExtraAmmoFor( Class<Ammunition> AmmoType )
{
	if( AmmoType==Class'FragAmmo' )
		Return 2.0;   // carry twice as many nades
	else if( AmmoType==Class'ShotgunAmmo' || AmmoType==Class'DBShotgunAmmo' || AmmoType==Class'LAWAmmo' )
		Return 1.25;   // 25% increase in power weapon ammo carry
	Return 1;
}

defaultproperties
{
	bHasPerkWeapon=true
	OnHUDIcon=Texture'KFX.Support'
	VeterancyName="Support Specialist"
	VeterancyDescription="|SUPPORT ||+7 max carry weight|+25% faster welding / unwelding with welder tool.|Doubled frag grenade capacity |+25% max ammo capacity with Shotgun / Hunting Shotgun / LAW |+50% extra shotgun and grenade damage|+80% better shotgun penetration|+60% less damage from grenades|+25% less spread from shotguns"
	VeterancyRequirement="|REQUIREMENTS:||- Weld at least 2,000 hitpoints|- Make at least 60 kills with power weapons (HandCannon, Shotgun,...)"
}
