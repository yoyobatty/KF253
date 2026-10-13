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
	PerkName="Stamin-Up"
	AlreadyBoughtMessage="You already have Stamin-Up."
	PurchasedMessage="Stamin-Up purchased! You sprint faster and longer."
}
