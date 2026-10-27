//=============================================================================
// CryoPickup
// The cryo cannon at the trader and on the floor (the crossbow's models).
//=============================================================================
class CryoPickup extends CrossbowPickup;

defaultproperties
{
     cost=3000
     AmmoCost=40
     BuyClipSize=1
     PowerValue=60
     SpeedValue=30
     RangeValue=70
     Description="A Horzine prototype freeze gun. Its bolt freezes specimens solid; frozen ones break like glass."
     ItemName="Cryo Cannon"
     AmmoItemName="Cryo cartridges"
     InventoryType=Class'KFMod.CryoCannon'
     PickupMessage="You got the Cryo Cannon"
}
