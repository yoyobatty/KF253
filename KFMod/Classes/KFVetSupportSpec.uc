Class KFVetSupportSpec extends KFVeterancyTypes
	Abstract;

static function bool QualityFor( KFPlayerStats Other )
{
	Return (Other.TotalWelded>=1000 && Other.PowerWpnKills>=60);
}
static function int AddCarryMaxWeight()
{
	Return 5;  // 5 more carry slots
}
static function float GetVeldSpeedModifier()
{
	Return 2.5;
}
static function float AddExtraAmmoFor( Class<Ammunition> AmmoType )
{
	if( AmmoType==Class'FragAmmo' )
		Return 2.0;   // carry twice as many nades
	else if( AmmoType==Class'ShotgunAmmo' || AmmoType==Class'DBShotgunAmmo' || AmmoType==Class'LAWAmmo' || AmmoType==Class'DeagleAmmo' )
		Return 1.25;   // 25% increase in power weapon ammo carry
	Return 1;
}

defaultproperties
{
     OnHUDIcon=Texture'KFX.Support'
     VeterancyName="Support Specialist"
     VeterancyDescription="|SUPPORT ||+ 5 max carry weight|+ 25% faster welding / unwelding with welder tool.|+ doubled frag grenade capacity |+ 25% max ammo capacity with Shotgun / Hunting Shotgun / LAW / Handcannon"
     VetButtonStyle="VetStyleSupport"
}
