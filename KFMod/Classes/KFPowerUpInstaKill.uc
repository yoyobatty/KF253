class KFPowerUpInstaKill extends KFZombiesPowerUp;

function Activate( KFHumanPawn P, KFEndlessGameType G )
{
	G.StartInstaKill();
}

defaultproperties
{
	PickupMessage="ONE-HIT KILLS!"
	StaticMesh=StaticMesh'KillingFloorStatics.3PDeagle_Ground'
	DrawScale=1.200000
	LightHue=0
}
