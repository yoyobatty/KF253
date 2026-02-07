//=============================================================================
// Pickup.
//=============================================================================
class PlaceMinePickup extends KFWeaponPickup;

/*
function ShowDeagleInfo(Canvas C)
{
  C.SetPos((C.SizeX - C.SizeY) / 2,0);
  C.DrawTile( Texture'KillingfloorHUD.ClassMenu.Deagle', C.SizeY, C.SizeY, 0.0, 0.0, 256, 256);
}
*/

defaultproperties
{
	Weight=0.000000
	InventoryType=Class'KFMod.PlaceMineWeapon'
	PickupMessage="You got some mines."
	PickupSound=Sound'PickupSounds.AssaultRiflePickup'
	PickupForce="AssaultRiflePickup"
	StaticMesh=StaticMesh'PatchStatics.Mine'
	CollisionHeight=5.000000
}
