//=============================================================================
// BuyableUpgrade
// An upgrade of a gun the player owns, on the trader's Upgrades list (KFTraderUpgrades): listed while the player has
// that gun not upgraded yet, bought with KFPawn.ServerUpgradeWeapon. Its weight is what the variant it makes weighs
// more (or less) than the gun.
//=============================================================================
class BuyableUpgrade extends BuyableWeapon;

var int Line;							// its line in KFTraderUpgrades
var class<KFWeapon> Base, Variant;		// the gun it upgrades, and what that becomes (None: the gun's own upgrade)

// The gun it upgrades, if the player has it and it is not upgraded yet
function KFWeapon Owned( Pawn P )
{
	local Inventory I;

	if ( P == None )
		return None;
	for ( I = P.Inventory; I != None; I = I.Inventory )
	{
		if ( I.Class == Base )
		{
			if ( KFWeapon(I) == None || KFWeapon(I).bUpgraded || KFWeapon(I).bUpgradeBusy )
				return None;
			return KFWeapon(I);
		}
	}
	return None;
}

function bool ShowMe( Pawn P, eSaleCat Index, GUIBuyMenu ParentMenu )
{
	return Index == SALE_Upgrades && Owned(P) != None;
}

function bool CanBuyMe( PlayerController PC )
{
	return KFHumanPawn(PC.Pawn) != None && Owned(PC.Pawn) != None;
}

function BuyMe( KFPawn P )
{
	P.ServerUpgradeWeapon(Base, Variant);
}

function SellMe( KFPawn P );
