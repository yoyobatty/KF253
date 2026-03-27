//=============================================================================
// L.A.W Ammo Pickup.
//=============================================================================
class LAWAmmoPickup extends KFAmmoPickup;

defaultproperties
{
     AmmoAmount=4
     InventoryType=Class'KFMod.LAWAmmo'
     PickupMessage="HEAT Rockets"
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'KillingFloorStatics.LAWAmmo'
     DrawScale=0.500000
     CollisionRadius=40.000000
}
