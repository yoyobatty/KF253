class LAWPickup extends KFWeaponPickup;

#exec OBJ LOAD FILE=KillingFloorWeapons.utx
#exec OBJ LOAD FILE=WeaponStaticMesh.usx

defaultproperties
{
<<<<<<< HEAD
	Weight=15.000000
	cost=600
	AmmoCost=30
	BuyClipSize=1
	PowerValue=100
	SpeedValue=20
	RangeValue=64
	Description="Light Anti Tank weapon. Designed to punch through armored vehicles."
	ItemName="L.A.W"
	AmmoItemName="L.A.W Rockets"
	showMesh=SkeletalMesh'KFWeaponModels.LAW3P'
	AmmoMesh=StaticMesh'KillingFloorStatics.LAWAmmo'
	MaxDesireability=0.790000
	InventoryType=Class'KFMod.LAW'
	RespawnTime=60.000000
	PickupMessage="You got the L.A.W."
	PickupForce="AssaultRiflePickup"
	StaticMesh=StaticMesh'KillingFloorStatics.LAWGround'
	CollisionRadius=35.000000
	CollisionHeight=10.000000
=======
     Weight=13.000000
     cost=600
     AmmoCost=30
     BuyClipSize=1
     PowerValue=100
     SpeedValue=20
     RangeValue=64
     Description="Light Anti Tank weapon. Designed to punch through armored vehicles."
     ItemName="L.A.W"
     AmmoItemName="L.A.W Rockets"
     showMesh=SkeletalMesh'KFWeaponModels.LAW3P'
     AmmoMesh=StaticMesh'KillingFloorStatics.LAWAmmo'
     MaxDesireability=0.900000
     InventoryType=Class'KFMod.LAW'
     RespawnTime=60.000000
     PickupMessage="You got the L.A.W."
     PickupForce="AssaultRiflePickup"
     StaticMesh=StaticMesh'KillingFloorStatics.LAWGround'
     CollisionRadius=35.000000
     CollisionHeight=10.000000
     CorrespondingVeterancyName="Support Specialist"
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
