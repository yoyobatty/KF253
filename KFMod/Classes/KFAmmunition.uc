//=============================================================================
// KF Ammo.
//=============================================================================
class KFAmmunition extends Ammunition;

simulated function CheckOutOfAmmo()
{
    if( AmmoAmount<=0 && Pawn(Owner)!=None && Pawn(Owner).Weapon!=None )
        Pawn(Owner).Weapon.OutOfAmmo();
}
simulated function PostNetReceive()
{
	CheckOutOfAmmo();
}
function bool HandlePickupQuery( pickup Item )
{
	if ( class == item.InventoryType ) 
	{
		MaxAmmo = Default.MaxAmmo;
		if( KFPawn(Owner)!=None )
			MaxAmmo*=KFPawn(Owner).GetVeteran().Static.AddExtraAmmoFor(Class);
		if (AmmoAmount==MaxAmmo) 
			return true;
		item.AnnouncePickup(Pawn(Owner));
		AddAmmo(Ammo(item).AmmoAmount);
        item.SetRespawn(); 
		return true;				
	}
	if ( Inventory == None )
		return false;

	return Inventory.HandlePickupQuery(Item);
}

defaultproperties
{
     bNetNotify=True
}
