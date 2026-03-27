//=============================================================================
// Bat Pickup.
//=============================================================================
class BatPickup extends KFWeaponPickup;

defaultproperties
{
     Weight=3.000000
     cost=100
     PowerValue=35
     SpeedValue=56
     RangeValue=-20
     MaxDesireability=0.25
     Description="This bit of broken pipe looks like it was pried from a gas-line."
     ItemName="Broken Pipe"
     showMesh=SkeletalMesh'KFWeaponModels.Bat3P'
     InventoryType=Class'KFMod.Bat'
     PickupMessage="You got a broken pipe."
     PickupSound=Sound'PatchSounds.pickupm2-2'
     PickupForce="AssaultRiflePickup"
     StaticMesh=StaticMesh'KillingFloorStatics.BatGround'
     CollisionRadius=28.000000
     CollisionHeight=5.000000
     CorrespondingVeterancyName="Berserker"
}
