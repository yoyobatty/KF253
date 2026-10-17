class KFDoubleTapMachine extends KFPerkMachine
	placeable;

function bool HasPerk( KFPlayerReplicationInfo KFPRI )
{
	Return KFPRI.bHasDoubleTap;
}

function GivePerk( KFHumanPawnZombies P, KFPlayerReplicationInfo KFPRI )
{
	KFPRI.bHasDoubleTap = true;
}

defaultproperties
{
	Cost=2000
	PerkName="Hair Trigger"
	AlreadyBoughtMessage="You already have Hair Trigger."
	PurchasedMessage="Hair Trigger purchased! You fire faster."
}
