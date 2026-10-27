class KFPowerUpDoublePoints extends KFZombiesPowerUp;

function Activate( KFHumanPawn P, KFEndlessGameType G )
{
	G.StartDoublePoints();
}

defaultproperties
{
	PickupMessage="DOUBLE DOSH!"
	StaticMesh=StaticMesh'22Patch.BankNote'
	DrawScale=0.800000
	LightHue=40
}
