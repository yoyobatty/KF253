class KFSpeedColaMachine extends KFPerkMachine
	placeable;

function bool HasPerk( KFPlayerReplicationInfo KFPRI )
{
	Return KFPRI.bHasSpeedCola;
}

function GivePerk( KFHumanPawnZombies P, KFPlayerReplicationInfo KFPRI )
{
	KFPRI.bHasSpeedCola = true;
}

defaultproperties
{
	Cost=3000
	PerkName="Quick Hands"
	AlreadyBoughtMessage="You already have Quick Hands."
	PurchasedMessage="Quick Hands purchased! You reload faster."
}
