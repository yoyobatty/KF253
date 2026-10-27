//=============================================================================
// AxeVoidPickup
// The Void Executioner at the trader and on the floor (the axe's models).
//=============================================================================
class AxeVoidPickup extends AxePickup;

defaultproperties
{
     cost=7500
     PowerValue=100
     SpeedValue=60
     RangeValue=100
     Description="An axe that should not exist. Its edge flies, and you go where it lands, in a shock wave nothing survives."
     ItemName="Void Executioner"
     InventoryType=Class'KFMod.AxeVoid'
     PickupMessage="You got the Void Executioner."
}
