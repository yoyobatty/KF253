//=============================================================================
// Pickup.
//=============================================================================
class PlaceCalPickup extends KFWeaponPickup;

/*
function ShowDeagleInfo(Canvas C)
{
  C.SetPos((C.SizeX - C.SizeY) / 2,0);
  C.DrawTile( Texture'KillingfloorHUD.ClassMenu.Deagle', C.SizeY, C.SizeY, 0.0, 0.0, 256, 256);
}
*/

defaultproperties
{
	cost=300
	PowerValue=30
	SpeedValue=100
	RangeValue=60
	Description="a Heavy belt-fed mounted machine gun."
	ItemName="Placeable .50Cal Heavy"
	InventoryType=Class'KFMod.PlaceCalWeapon'
	PickupMessage="you got the .50 Cal Heavy"
	PickupSound=Sound'PickupSounds.AssaultRiflePickup'
	PickupForce="AssaultRiflePickup"
	StaticMesh=StaticMesh'KillingFloorStatics.3PDeagle_Ground'
	CollisionHeight=5.000000
}
