//-----------------------------------------------------------
//
//-----------------------------------------------------------
class SyringePickup extends KFWeaponPickup;

/*
function ShowAxeInfo(Canvas C)
{
  C.SetPos((C.SizeX - C.SizeY) / 2,0);
  C.DrawTile( Texture'KillingfloorHUD.ClassMenu.Axe', C.SizeY, C.SizeY, 0.0, 0.0, 256, 256);
}
*/

defaultproperties
{
	Weight=0.000000
	InventoryType=Class'KFMod.Syringe'
	PickupMessage="You got the Med-Syringe."
	PickupSound=Sound'PickupSounds.AssaultRiflePickup'
	PickupForce="AssaultRiflePickup"
	StaticMesh=StaticMesh'KillingFloorStatics.SyringeGround'
	CollisionHeight=5.000000
}
