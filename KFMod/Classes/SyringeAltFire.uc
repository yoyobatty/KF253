// Self Healing Fire //
class SyringeAltFire extends WeaponFire;

var float InjectDelay;
var float HealeeRange;

function DoFireEffect()
{
	SetTimer(InjectDelay, False);
}
Function Timer()
{
	local int HealSum;
	
	HealSum = Syringe(Weapon).HealBoostAmount * KFPawn(Instigator).GetVeteran().Static.GetHealPotency();

        Weapon.ConsumeAmmo(ThisModeNum, AmmoPerFire);
	Instigator.GiveHealth(HealSum, 100);
}
function bool AllowFire()
{
	if (Instigator.Health >= Instigator.HealthMax)
	 return false;

        return Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire;
}
event ModeDoFire()
{
	Load = 0;
	Super.ModeDoFire(); // We don't consume the ammo just yet.
}

defaultproperties
{
	InjectDelay=1.000000
	HealeeRange=70.000000
	TransientSoundVolume=100.000000
	FireAnim="AltFire"
	FireRate=4.160000
	AmmoPerFire=500
}
