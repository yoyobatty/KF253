class StunAmmoPickup extends KFAmmoPickup;

defaultproperties
{
	AmmoAmount=5
	InventoryType=Class'KFMod.StunAmmo'
	RespawnTime=0.000000
	PickupMessage="Found some Concussion Grenades"
	PickupSound=Sound'PickupSounds.AssaultAmmoPickup'
	PickupForce="AssaultAmmoPickup"
	DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'PatchStatics.StunPickup'
	TransientSoundVolume=0.400000
	CollisionRadius=10.000000
}
