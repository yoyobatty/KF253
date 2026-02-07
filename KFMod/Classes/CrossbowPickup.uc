class CrossbowPickup extends KFWeaponPickup;

#exec OBJ LOAD FILE=KillingFloorWeapons.utx
#exec OBJ LOAD FILE=WeaponStaticMesh.usx

defaultproperties
{
<<<<<<< HEAD
	cost=400
	AmmoCost=15
	BuyClipSize=5
	PowerValue=64
	SpeedValue=50
	RangeValue=100
	Description="Recreational hunting weapon, equipped with powerful scope and firing trigger. Exceptional headshot damage."
	ItemName="Crossbow"
	AmmoItemName="Crossbow Bolts"
	showMesh=SkeletalMesh'KFWeaponModels.Xbow3P'
	AmmoMesh=StaticMesh'KillingFloorStatics.XbowAmmo'
	MaxDesireability=0.790000
	InventoryType=Class'KFMod.Crossbow'
	PickupMessage="You got the Xbow."
	PickupForce="AssaultRiflePickup"
	StaticMesh=StaticMesh'KillingFloorStatics.XbowGround'
	CollisionRadius=25.000000
	CollisionHeight=10.000000
=======
     Weight=9.000000
     cost=400
     AmmoCost=15
     BuyClipSize=5
     PowerValue=64
     SpeedValue=50
     RangeValue=100
     Description="Recreational hunting weapon, equipped with powerful scope and firing trigger. Exceptional headshot damage."
     ItemName="Crossbow"
     AmmoItemName="Crossbow Bolts"
     showMesh=SkeletalMesh'KFWeaponModels.Xbow3P'
     AmmoMesh=StaticMesh'KillingFloorStatics.XbowAmmo'
     MaxDesireability=0.790000
     InventoryType=Class'KFMod.Crossbow'
     PickupMessage="You got the Xbow."
     PickupForce="AssaultRiflePickup"
     StaticMesh=StaticMesh'KillingFloorStatics.XbowGround'
     CollisionRadius=25.000000
     CollisionHeight=10.000000
     CorrespondingVeterancyName="Sharpshooter"
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
