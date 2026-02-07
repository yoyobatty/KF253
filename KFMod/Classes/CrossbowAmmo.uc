class CrossbowAmmo extends KFAmmunition;

#EXEC OBJ LOAD FILE=KillingFloorHUD.utx

defaultproperties
{
     MaxAmmo=40
     InitialAmount=40
     PickupClass=Class'KFMod.CrossbowAmmoPickup'
     IconMaterial=Texture'KillingFloorHUD.Generic.HUD'
     IconCoords=(X1=4,Y1=350,X2=110,Y2=395)
     ItemName="An arrow"
}
