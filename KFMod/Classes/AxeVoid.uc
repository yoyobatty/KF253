//=============================================================================
// AxeVoid
// The Void Executioner: the Executioner made worse. Both its buttons throw its edge through the air as the Executioner's
// do (upright, flat), violet; where the cut lands, on the first specimen or wall it meets or at the end of its flight,
// its wielder is there in a blink, in a shock wave that kills every specimen round about (KFAxeVoidSlash).
//=============================================================================
class AxeVoid extends Axe;

defaultproperties
{
     Element=4
     bUpgraded=True
     UpgradeName="Void Executioner"
     FireModeClass(0)=Class'KFMod.AxeVoidFire'
     FireModeClass(1)=Class'KFMod.AxeVoidSlashFire'
     PickupClass=Class'KFMod.AxeVoidPickup'
     Description="An axe that should not exist. Its edge flies, and you go where it lands."
     ItemName="Void Executioner"
}
