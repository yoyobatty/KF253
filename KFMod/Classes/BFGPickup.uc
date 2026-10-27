//=============================================================================
// BFGPickup
// The BFG 9000 at the trader and on the floor (the LAW's own models).
//=============================================================================
class BFGPickup extends LAWPickup;

defaultproperties
{
     Weight=13.000000
     cost=5000
     AmmoCost=450
     BuyClipSize=1
     PowerValue=100
     SpeedValue=10
     RangeValue=100
     Description="A Horzine prototype plasma cannon built on a L.A.W's frame. It throws a slow ball of green plasma that lashes every specimen near its path, bursts like a small sun, and sends its tracers out to everything you face."
     ItemName="BFG 9000"
     AmmoItemName="BFG Cells"
     InventoryType=Class'KFMod.BFG'
     PickupMessage="You got the BFG 9000!"
}
