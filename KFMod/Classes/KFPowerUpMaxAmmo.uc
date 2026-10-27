class KFPowerUpMaxAmmo extends KFZombiesPowerUp;

function Activate( KFHumanPawn P, KFEndlessGameType G )
{
	G.GiveMaxAmmo();
}

defaultproperties
{
	PickupMessage="FULL AMMO!"
	StaticMesh=StaticMesh'KillingFloorStatics.L85Ammo'
	DrawScale=1.500000
	LightHue=85
}
