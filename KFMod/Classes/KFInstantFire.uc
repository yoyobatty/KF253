//=============================================================================
// KF Instant Fire Class (Single Handed Only)
//=============================================================================
class KFInstantFire extends AssaultRifle ;

function bool HandlePickupQuery( pickup Item )
{
    // Nullifies the Dual Pickup function of the Assault Rifle Inventory Class
    return false;
}

defaultproperties
{
	MessageNoAmmo=" is Empty."
	Priority=10
}
