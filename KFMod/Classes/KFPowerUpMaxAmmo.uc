class KFPowerUpMaxAmmo extends KFZombiesPowerUp;

function Activate( KFHumanPawn P, KFZombiesGameType G )
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
