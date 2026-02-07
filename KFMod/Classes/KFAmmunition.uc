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
<<<<<<< HEAD
		if( KFPawn(Owner)!=None )
			MaxAmmo*=KFPawn(Owner).GetVeteran().Static.AddExtraAmmoFor(Class);
=======
		if ( KFPawn(Owner) != none && KFPlayerReplicationInfo(KFPawn(Owner).PlayerReplicationInfo) != none &&
			 KFPlayerReplicationInfo(KFPawn(Owner).PlayerReplicationInfo).ClientVeteranSkill != none )
		{
			MaxAmmo = float(MaxAmmo) * KFPlayerReplicationInfo(KFPawn(Owner).PlayerReplicationInfo).ClientVeteranSkill.Static.AddExtraAmmoFor(Class);
		}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
<<<<<<< HEAD
	bNetNotify=True
=======
     bNetNotify=True
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
