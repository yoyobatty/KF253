//=============================================================================
// PlaceCal Ammo.
//=============================================================================
class PlaceCalAmmo extends KFAmmunition;

#EXEC OBJ LOAD FILE=InterfaceContent.utx

defaultproperties
{
	MaxAmmo=1
	InitialAmount=1
	PickupClass=Class'KFMod.DeagleAmmoPickup'
	IconCoords=(X1=338,Y1=40,X2=393,Y2=79)
	ItemName="a placeable 50 cal gun"
}
