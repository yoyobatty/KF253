//=============================================================================
// Axe Pickup.
//=============================================================================
class AxePickup extends KFWeaponPickup;

defaultproperties
{
     Weight=5.000000
     cost=150
     PowerValue=56
     SpeedValue=32
     RangeValue=-20
     Description="A sturdy fireman's axe."
     ItemName="Axe"
     showMesh=SkeletalMesh'KFWeaponModels.Axe3P'
     InventoryType=Class'KFMod.Axe'
     PickupMessage="You got the Fire Axe."
     PickupSound=Sound'PatchSounds.pickupm2-3'
     PickupForce="AssaultRiflePickup"
     StaticMesh=StaticMesh'KillingFloorStatics.3PFireAxe_Ground'
     CollisionRadius=27.000000
     CollisionHeight=5.000000
}
