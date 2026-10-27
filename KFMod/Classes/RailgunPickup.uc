//=============================================================================
// RailgunPickup
// The railgun at the trader and on the floor (the Bullpup's models).
//=============================================================================
class RailgunPickup extends BullpupPickup;

defaultproperties
{
     cost=3500
     AmmoCost=60
     BuyClipSize=6
     PowerValue=95
     SpeedValue=15
     RangeValue=100
     Description="A Horzine prototype railgun. Each slug goes through everything in its line to the wall."
     ItemName="Railgun"
     AmmoItemName="Rail slugs"
     InventoryType=Class'KFMod.Railgun'
     PickupMessage="You got the Railgun"
}
