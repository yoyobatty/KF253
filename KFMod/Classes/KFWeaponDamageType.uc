// Gib Pert. fix.
class KFWeaponDamageType extends WeaponDamageType;

var float HeadShotDamageMult;
var bool bIsPowerWeapon,bIsMeleeDamage,bSniperWeapon;

static function AwardKill( KFPlayerStats Other, bool bDecapited, bool bWasStalker )
{
	Other.ReceiveKill(Default.bIsMeleeDamage,(Default.bSniperWeapon && bDecapited),Default.bIsPowerWeapon,bWasStalker);
}
static function AwardDamage( KFPlayerStats Other, int dmg )
{
	if( Default.bIsMeleeDamage )
		Other.ReceiveDamage(dmg,False);
}

defaultproperties
{
     HeadShotDamageMult=1.100000
     GibPerterbation=0.250000
}
