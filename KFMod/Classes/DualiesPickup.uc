//=============================================================================
// Dualies Pickup.
//=============================================================================
class DualiesPickup extends KFWeaponPickup;

function ShowDualiesInfo(Canvas C)
{
	C.SetPos((C.SizeX - C.SizeY) / 2,0);
	C.DrawTile( Texture'KillingfloorHUD.ClassMenu.Dualies', C.SizeY, C.SizeY, 0.0, 0.0, 256, 256);
}

defaultproperties
{
<<<<<<< HEAD
	Weight=4.000000
	cost=150
	AmmoCost=10
	BuyClipSize=30
	PowerValue=35
	SpeedValue=85
	RangeValue=35
	Description="A pair of custom 9mm handguns."
	ItemName="Dual 9mms"
	AmmoItemName="9mm Rounds"
	showMesh=SkeletalMesh'KFWeaponModels.Dualies3P'
	AmmoMesh=StaticMesh'KillingFloorStatics.DualiesAmmo'
	InventoryType=Class'KFMod.Dualies'
	PickupMessage="You found another 9mm handgun"
	PickupForce="AssaultRiflePickup"
	StaticMesh=StaticMesh'KillingFloorStatics.SingleGround'
	CollisionHeight=5.000000
=======
     Weight=4.000000
     cost=150
     AmmoCost=10
     BuyClipSize=30
     PowerValue=35
     SpeedValue=85
     RangeValue=35
     MaxDesireability=0.400000
     Description="A pair of custom 9mm handguns."
     ItemName="Dual 9mms"
     AmmoItemName="9mm Rounds"
     showMesh=SkeletalMesh'KFWeaponModels.Dualies3P'
     AmmoMesh=StaticMesh'KillingFloorStatics.DualiesAmmo'
     InventoryType=Class'KFMod.Dualies'
     PickupMessage="You found another 9mm handgun"
     PickupForce="AssaultRiflePickup"
     StaticMesh=StaticMesh'KillingFloorStatics.SingleGround'
     CollisionHeight=5.000000
     CorrespondingVeterancyName="Sharpshooter"
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
