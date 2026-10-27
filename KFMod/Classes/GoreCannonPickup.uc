//=============================================================================
// GoreCannonPickup
// The Gore Cannon at the trader and on the floor (the L.A.W's models). Its rounds are what it swallows: none are sold.
//=============================================================================
class GoreCannonPickup extends LAWPickup;

defaultproperties
{
     Weight=10.000000
     cost=3500
     AmmoCost=9999
     BuyClipSize=1
     PowerValue=90
     SpeedValue=40
     RangeValue=60
     Description="A L.A.W refitted as a meat gun. Hold the alt button to vacuum up bodies and giblets (and to drag in and tear apart weakened specimens); fire to throw them back: whole bodies burst where they land, giblets fly as a spread."
     ItemName="Gore Cannon"
     AmmoItemName="Meat"
     InventoryType=Class'KFMod.GoreCannon'
     PickupMessage="You got the Gore Cannon."
}
