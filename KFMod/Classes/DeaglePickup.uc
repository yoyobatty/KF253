//=============================================================================
// Deagle Pickup.
//=============================================================================
class DeaglePickup extends KFWeaponPickup;

/*
function ShowDeagleInfo(Canvas C)
{
  C.SetPos((C.SizeX - C.SizeY) / 2,0);
  C.DrawTile( Texture'KillingfloorHUD.ClassMenu.Deagle', C.SizeY, C.SizeY, 0.0, 0.0, 256, 256);
}
*/

defaultproperties
{
<<<<<<< HEAD
	Weight=4.000000
	cost=250
	AmmoCost=15
	BuyClipSize=7
	PowerValue=65
	SpeedValue=35
	RangeValue=60
	Description="50 Cal AE handgun. A powerful personal choice for personal defense."
	ItemName="Handcannon"
	AmmoItemName=".300 JHP Ammo"
	showMesh=SkeletalMesh'KFWeaponModels.Deagle3P'
	AmmoMesh=StaticMesh'KillingFloorStatics.DeagleAmmo'
	InventoryType=Class'KFMod.Deagle'
	PickupMessage="You got the Handcannon"
	PickupForce="AssaultRiflePickup"
	StaticMesh=StaticMesh'KillingFloorStatics.3PDeagle_Ground'
	DrawScale=0.700000
	CollisionHeight=5.000000
=======
     Weight=4.000000
     cost=250
     AmmoCost=15
     BuyClipSize=7
     PowerValue=65
     SpeedValue=35
     RangeValue=60
     Description="50 Cal AE handgun. A powerful personal choice for personal defense."
     ItemName="Handcannon"
     AmmoItemName=".300 JHP Ammo"
     showMesh=SkeletalMesh'KFWeaponModels.Deagle3P'
     AmmoMesh=StaticMesh'KillingFloorStatics.DeagleAmmo'
     InventoryType=Class'KFMod.Deagle'
     PickupMessage="You got the Handcannon"
     PickupForce="AssaultRiflePickup"
     StaticMesh=StaticMesh'KillingFloorStatics.3PDeagle_Ground'
     DrawScale=0.700000
     CollisionHeight=5.000000
     CorrespondingVeterancyName="Sharpshooter"
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
