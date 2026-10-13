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
	PerkName="Speed Cola"
	AlreadyBoughtMessage="You already have Speed Cola."
	PurchasedMessage="Speed Cola purchased! You reload faster."
}
