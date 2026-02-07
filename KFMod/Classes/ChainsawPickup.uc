//=============================================================================
// Chainsaw Pickup.
//=============================================================================
class ChainsawPickup extends KFWeaponPickup;

defaultproperties
{
	Weight=8.000000
	cost=250
	PowerValue=60
	SpeedValue=90
	RangeValue=-25
	Description="A gas powered industrial strength chainsaw. This tool may rely on a steady supply of gasoline, but it can cut through a variety of surfaces with ease."
	ItemName="Chainsaw"
	showMesh=SkeletalMesh'KFWeaponModels.Chainsaw3P'
	InventoryType=Class'KFMod.Chainsaw'
	PickupMessage="You got the Chainsaw."
	PickupSound=Sound'PickupSounds.AssaultRiflePickup'
	PickupForce="AssaultRiflePickup"
	StaticMesh=StaticMesh'KillingFloorStatics.ChainsawGround'
	CollisionRadius=35.000000
	CollisionHeight=10.000000
}
