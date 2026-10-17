class KFPowerUpCarpenter extends KFZombiesPowerUp;

function Activate( KFHumanPawn P, KFZombiesGameType G )
{
	G.Carpenter();
}

defaultproperties
{
	PickupMessage="BARRICADES REBUILT!"
	StaticMesh=StaticMesh'NewPatchSM.WelderGround'
	DrawScale=1.200000
	LightHue=160
}
