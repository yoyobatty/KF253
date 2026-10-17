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

// cut n pasted to remove uneeded stuff and generally tweak+modify.
// A bot that has a 9mm (every bot does) gets Dualies from this, so it is judged as Dualies then.
function float BotDesireability( pawn Bot )
{
	local float desire;

	if ( Bot.FindInventoryType(Class'Dualies') != None )
		return 0;
	if ( Bot.FindInventoryType(Class'Single') != None )
	{
		if ( KFHumanPawn(Bot)!=none && !KFHumanPawn(Bot).CanCarry(Class'Dualies'.Default.Weight) )
			return 0;
		desire = Class'DualiesPickup'.Default.MaxDesireability + Bot.Controller.AdjustDesireFor(self);
	}
	else
	{
		// Check weight, and make too-heavy items completely unwantable
		if ( KFHumanPawn(Bot)!=none && !CheckCanCarry(KFHumanPawn(Bot)) )
			return 0;
		desire = MaxDesireability + Bot.Controller.AdjustDesireFor(self);
	}

    if( bDropped && AmmoAmount[0] <= 0 ) //Don't make it worthless if no ammo
		desire *= 0.1;
		
	if ( Bot.Controller.bHuntPlayer && Bot.Weapon != None && (MaxDesireability * 0.833 < Bot.Weapon.AIRating - 0.1) )
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
