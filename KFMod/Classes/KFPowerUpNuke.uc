class KFPowerUpNuke extends KFZombiesPowerUp;

function Activate( KFHumanPawn P, KFEndlessGameType G )
{
	G.Nuke();
}

defaultproperties
{
	PickupMessage="KABOOM!"
	StaticMesh=StaticMesh'KillingFloorStatics.FragPickup'
	DrawScale=1.200000
	LightHue=20
}
