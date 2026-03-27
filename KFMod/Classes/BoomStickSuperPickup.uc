//=============================================================================
// BoomStick Pickup.
//=============================================================================
class BoomStickSuperPickup extends BoomStickPickup;

function ShowShotgunInfo(Canvas C)
{
	C.SetPos((C.SizeX - C.SizeY) / 2,0);
	C.DrawTile( Texture'KillingfloorHUD.ClassMenu.Shotgun', C.SizeY, C.SizeY, 0.0, 0.0, 256, 256);
}

defaultproperties
{
     cost=10000
     AmmoCost=100
     Description="Boom."
     ItemName="Super Hunting Shotgun"
     AmmoItemName="Evil fucking ZED nuker shells"
     InventoryType=Class'KFMod.BoomStickSuper'
     PickupMessage="You got the Super Hunting Shotgun"
     DrawScale=0.750000
}
