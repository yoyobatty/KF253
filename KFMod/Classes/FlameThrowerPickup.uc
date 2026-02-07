//=============================================================================
// L85 Pickup.
//=============================================================================
class FlameThrowerPickup extends KFWeaponPickup;

defaultproperties
{
	cost=400
	AmmoCost=30
	BuyClipSize=50
	PowerValue=30
	SpeedValue=100
	RangeValue=40
	Description="A deadly experimental weapon designed by Horzine industries. It can fire streams of burning liquid which ignite on contact."
	ItemName="FlameThrower"
	AmmoItemName="Napalm"
	showMesh=SkeletalMesh'KFWeaponModels.FlameThrower3P'
	AmmoMesh=StaticMesh'KillingFloorStatics.FT_AmmoMesh'
	InventoryType=Class'KFMod.FlameThrower'
	PickupMessage="You got the FlameThrower"
	PickupForce="AssaultRiflePickup"
	StaticMesh=StaticMesh'KillingFloorStatics.FTGround'
	CollisionRadius=30.000000
	CollisionHeight=5.000000
}
