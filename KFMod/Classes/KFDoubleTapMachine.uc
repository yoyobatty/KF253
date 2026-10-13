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
	PerkName="Double Tap"
	AlreadyBoughtMessage="You already have Double Tap."
	PurchasedMessage="Double Tap purchased! You fire faster."
}
