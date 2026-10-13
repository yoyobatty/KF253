class KFPowerUpDoublePoints extends KFZombiesPowerUp;

function Activate( KFHumanPawn P, KFZombiesGameType G )
{
	G.StartDoublePoints();
}

defaultproperties
{
	PickupMessage="DOUBLE POINTS!"
	StaticMesh=StaticMesh'22Patch.BankNote'
	DrawScale=0.800000
	LightHue=40
}
