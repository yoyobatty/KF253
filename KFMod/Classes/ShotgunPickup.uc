//=============================================================================
// Shotgun Pickup.
//=============================================================================
class ShotgunPickup extends KFWeaponPickup;

defaultproperties
{
	Weight=8.000000
	cost=300
	BuyClipSize=8
	PowerValue=70
	SpeedValue=40
	RangeValue=15
	Description="A rugged 12-gauge pump action shotgun. "
	ItemName="Shotgun"
	AmmoItemName="12-gauge shells"
	SecondaryAmmoItemName="Explosive Shells"
	SecondaryAmmoCost=40
	SecondaryClipCount=4
	showMesh=SkeletalMesh'KFWeaponModels.Shotgun3P'
	AmmoMesh=StaticMesh'KillingFloorStatics.ShotgunAmmo'
	InventoryType=Class'KFMod.Shotgun'
	PickupMessage="You got the Shotgun."
	PickupForce="AssaultRiflePickup"
	StaticMesh=StaticMesh'KillingFloorStatics.3PShotgun_Ground'
	CollisionRadius=35.000000
	CollisionHeight=5.000000
	CorrespondingVeterancyName="Support Specialist"
}
