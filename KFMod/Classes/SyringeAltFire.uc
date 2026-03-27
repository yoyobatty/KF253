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
<<<<<<< HEAD
	Load = 0;
	Super.ModeDoFire(); // We don't consume the ammo just yet.
=======
        Load = 0;
        Super.ModeDoFire(); // We don't consume the ammo just yet.
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

defaultproperties
{
<<<<<<< HEAD
	InjectDelay=1.000000
	HealeeRange=70.000000
	TransientSoundVolume=100.000000
	FireAnim="AltFire"
	FireRate=4.160000
=======
	InjectDelay=0.100000
	HealeeRange=70.000000
	TransientSoundVolume=100.000000
	FireAnim="AltFire"
	FireRate=3.600000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	AmmoPerFire=500
}
