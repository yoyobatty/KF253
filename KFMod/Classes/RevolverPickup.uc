//=============================================================================
// RevolverPickup
// The magnum revolver at the trader (its own third-person model, RevolverAttachment's) and on the floor (the Deagle's
// floor model, for now: the held model stands on end there).
//=============================================================================
class RevolverPickup extends DeaglePickup;

defaultproperties
{
     Weight=4.000000
     cost=500
     AmmoCost=18
     BuyClipSize=6
     PowerValue=80
     SpeedValue=25
     RangeValue=65
     Description="A six-shot .44 magnum revolver. Slow to load, hits like a train."
     ItemName="Magnum Revolver"
     AmmoItemName=".44 Magnum rounds"
     InventoryType=Class'KFMod.Revolver'
     PickupMessage="You got the Magnum Revolver"
     showMesh=SkeletalMesh'KFMod.RevolverMesh3P'
}
