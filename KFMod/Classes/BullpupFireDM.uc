//=============================================================================
 //Masterson's Custom Bullpup ...
//=============================================================================
class BullpupFireDM extends BullpupFire;

defaultproperties
{
	KickMomentum=(X=-1.500000,Z=1.000000)
	DamageMin=2
	DamageMax=3
	TraceRange=4000.000000
	Momentum=10000.000000
	FireEndAnim="Idle"
	FireRate=0.110000
	AmmoClass=Class'KFMod.BullpupAmmoDM'
	AmmoPerFire=0
	ShakeRotMag=(X=50.000000,Y=50.000000,Z=50.000000)
	ShakeOffsetMag=(X=1.000000,Y=1.000000,Z=1.000000)
	BotRefireRate=0.120000
	SpreadStyle=SS_Line
}
