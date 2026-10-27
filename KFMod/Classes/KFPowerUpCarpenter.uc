class KFPowerUpCarpenter extends KFZombiesPowerUp;

function Activate( KFHumanPawn P, KFEndlessGameType G )
{
	if( KFZombiesGameType(G) != None )
		KFZombiesGameType(G).Carpenter();
}

defaultproperties
{
	PickupMessage="BARRICADES REBUILT!"
	StaticMesh=StaticMesh'NewPatchSM.WelderGround'
	DrawScale=1.200000
	LightHue=160
}
