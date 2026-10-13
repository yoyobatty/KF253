class KFPowerUpInstaKill extends KFZombiesPowerUp;

function Activate( KFHumanPawn P, KFZombiesGameType G )
{
	G.StartInstaKill();
}

defaultproperties
{
	PickupMessage="INSTA-KILL!"
	StaticMesh=StaticMesh'KillingFloorStatics.3PDeagle_Ground'
	DrawScale=1.200000
	LightHue=0
}
