//=============================================================================
// Welder Pickup.
//=============================================================================
class WelderPickup extends KFWeaponPickup;

#exec obj load file="..\StaticMeshes\NewPatchSM.usx"

defaultproperties
{
     Weight=0.000000
     InventoryType=Class'KFMod.Welder'
     PickupMessage="You got the Welder."
     PickupSound=Sound'PickupSounds.AssaultRiflePickup'
     PickupForce="AssaultRiflePickup"
     StaticMesh=StaticMesh'NewPatchSM.WelderGround'
     CollisionHeight=5.000000
}
