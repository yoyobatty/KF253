//=============================================================================
// BoomStick Pickup.
//=============================================================================
class BoomStickPickup extends KFWeaponPickup;

function ShowShotgunInfo(Canvas C)
{
	C.SetPos((C.SizeX - C.SizeY) / 2,0);
	C.DrawTile( Texture'KillingfloorHUD.ClassMenu.Shotgun', C.SizeY, C.SizeY, 0.0, 0.0, 256, 256);
}

defaultproperties
{
     cost=450
     AmmoCost=25
     BuyClipSize=6
     PowerValue=90
     SpeedValue=30
     RangeValue=12
     Description="A double barreled shotgun used by big game hunters."
     ItemName="Hunting Shotgun"
     AmmoItemName="12-gauge Hunting shells"
     showMesh=SkeletalMesh'KFWeaponModels.BoomStick3P'
     AmmoMesh=StaticMesh'KillingFloorStatics.DBShotgunAmmoPickup'
     InventoryType=Class'KFMod.BoomStick'
     PickupMessage="You got the Hunting Shotgun"
     PickupForce="AssaultRiflePickup"
     StaticMesh=StaticMesh'KillingFloorStatics.BoomStickGround'
     CollisionRadius=35.000000
     CollisionHeight=5.000000
     CorrespondingVeterancyName="Support Specialist"
}
