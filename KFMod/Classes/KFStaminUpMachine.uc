class KFStaminUpMachine extends KFPerkMachine
	placeable;

function bool HasPerk( KFPlayerReplicationInfo KFPRI )
{
	Return KFPRI.bHasStaminUp;
}

function GivePerk( KFHumanPawnZombies P, KFPlayerReplicationInfo KFPRI )
{
	KFPRI.bHasStaminUp = true;
}

defaultproperties
{
	Cost=2000
	PerkName="Fleet Foot"
	AlreadyBoughtMessage="You already have Fleet Foot."
	PurchasedMessage="Fleet Foot purchased! You sprint faster and longer."
}
