//=============================================================================
// Frag Pickup.
//=============================================================================
class FragPickup extends BullpupPickup;

defaultproperties
{
	Weight=1.000000
	AmmoCost=40
	BuyClipSize=3
	Description="Fragmentation Grenades."
	ItemName="Grenades"
	AmmoItemName="Grenades"
	AmmoMesh=StaticMesh'KillingFloorStatics.FragPickup'
	InventoryType=Class'KFMod.Frag'
	PickupMessage="You got the Frag Grenades"
	StaticMesh=StaticMesh'KillingFloorStatics.FragPickup'
	CollisionRadius=10.000000
	CollisionHeight=10.000000
}
