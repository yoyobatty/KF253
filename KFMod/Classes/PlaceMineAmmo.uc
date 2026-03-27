//=============================================================================
// PlaceMine Ammo.
//=============================================================================
class PlaceMineAmmo extends KFAmmunition;

#EXEC OBJ LOAD FILE=InterfaceContent.utx

defaultproperties
{
     MaxAmmo=5
     InitialAmount=1
     PickupClass=Class'KFMod.DeagleAmmoPickup'
     IconCoords=(X1=338,Y1=40,X2=393,Y2=79)
     ItemName="You picked up a mine."
}
