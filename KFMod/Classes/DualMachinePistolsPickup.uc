//=============================================================================
// Dualies Pickup.
//=============================================================================
class DualMachinePistolsPickup extends KFWeaponPickup;

function ShowDualiesInfo(Canvas C)
{
	C.SetPos((C.SizeX - C.SizeY) / 2,0);
	C.DrawTile( Texture'KillingfloorHUD.ClassMenu.Dualies', C.SizeY, C.SizeY, 0.0, 0.0, 256, 256);
}

defaultproperties
{
     Weight=4.000000
     cost=150
     AmmoCost=10
     BuyClipSize=30
     PowerValue=35
     SpeedValue=85
     RangeValue=35
     MaxDesireability=0.900000
     Description="A pair of custom 9mm handguns, fully automatic."
     ItemName="Dual 9mm Machine Pistols"
     AmmoItemName="9mm Rounds"
     showMesh=SkeletalMesh'KFWeaponModels.Dualies3P'
     AmmoMesh=StaticMesh'KillingFloorStatics.DualiesAmmo'
     InventoryType=Class'KFMod.DualMachinePistols'
     PickupMessage="You found the dual machine pistols"
     PickupForce="AssaultRiflePickup"
     StaticMesh=StaticMesh'KillingFloorStatics.SingleGround'
     CollisionHeight=5.000000
     CorrespondingVeterancyName="Sharpshooter"
}
