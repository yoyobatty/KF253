//=============================================================================
// Single Pickup.
//=============================================================================
class SinglePickup extends KFWeaponPickup;

function inventory SpawnCopy( pawn Other )
{
	local Inventory I;

	For( I=Other.Inventory; I!=None; I=I.Inventory )
	{
		if( Single(I)!=None )
		{
			if( Inventory!=None )
				Inventory.Destroy();
			InventoryType = Class'Dualies';
               I.Destroyed();
			I.Destroy();
			Return Super.SpawnCopy(Other);
		}
	}
	InventoryType = Default.InventoryType;
	Return Super.SpawnCopy(Other);
}

// cut n pasted to remove uneeded stuff and generally tweak+modify, also fixing alreadyhas check to work with dualies
function float BotDesireability( pawn Bot )
{
	local Weapon AlreadyHas;
	local float desire;

	desire = MaxDesireability + Bot.Controller.AdjustDesireFor(self); 

	// see if bot already has a weapon of this type
	AlreadyHas = Weapon(Bot.FindInventoryType(InventoryType));
	if ( AlreadyHas != None || Weapon(Bot.FindInventoryType(Class'Dualies')) != None )// Hack because this spawns dualies
		return 0;

	// Check weight, and make too-heavy items completely unwantable
	if ( KFHumanPawn(Bot)!=none && !CheckCanCarry(KFHumanPawn(Bot)) )
		return 0;

    if( bDropped && AmmoAmount[0] <= 0 ) //Don't make it worthless if no ammo
		desire *= 0.1;
		
	if ( Bot.Controller.bHuntPlayer && (MaxDesireability * 0.833 < Bot.Weapon.AIRating - 0.1) )
		return 0;

	// incentivize bot to get this weapon if it doesn't have a good weapon already
	if ( (Bot.Weapon == None) || (Bot.Weapon.AIRating < 0.5) )
		return 2*desire;
	return desire;
}

defaultproperties
{
     Weight=0.000000
     cost=0
     AmmoCost=10
     BuyClipSize=30
     PowerValue=20
     SpeedValue=50
     RangeValue=35
     MaxDesireability=0.25
     Description="A 9mm handgun."
     ItemName="9mm Pistol"
     AmmoItemName="9mm Rounds"
     AmmoMesh=StaticMesh'KillingFloorStatics.DualiesAmmo'
     InventoryType=Class'KFMod.Single'
     PickupMessage="You got the 9mm handgun"
     PickupForce="AssaultRiflePickup"
     StaticMesh=StaticMesh'22Patch.9mmGround'
     CollisionHeight=5.000000
     CorrespondingVeterancyName="Sharpshooter"
}
