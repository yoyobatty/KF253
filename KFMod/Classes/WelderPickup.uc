//=============================================================================
// Welder Pickup.
//=============================================================================
class WelderPickup extends KFWeaponPickup;

#exec obj load file="..\StaticMeshes\NewPatchSM.usx"

defaultproperties
{
<<<<<<< HEAD
	Weight=0.000000
	InventoryType=Class'KFMod.Welder'
	PickupMessage="You got the Welder."
	PickupSound=Sound'PickupSounds.AssaultRiflePickup'
	PickupForce="AssaultRiflePickup"
	StaticMesh=StaticMesh'NewPatchSM.WelderGround'
	CollisionHeight=5.000000
=======
     Weight=0.000000
     InventoryType=Class'KFMod.Welder'
     PickupMessage="You got the Welder."
     PickupSound=Sound'PickupSounds.AssaultRiflePickup'
     PickupForce="AssaultRiflePickup"
     StaticMesh=StaticMesh'NewPatchSM.WelderGround'
     CollisionHeight=5.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
