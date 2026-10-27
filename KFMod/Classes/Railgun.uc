//=============================================================================
// Railgun
// A prototype railgun after Quake's, on the Bullpup's frame in the shock camo of the upgraded guns (KFElement 4; it
// comes upgraded). One slug a shot, through every specimen in its line to the wall, leaving a spiral of light in the
// air (RailgunFire, KFRailBeam). Its scope is the Bullpup's.
//=============================================================================
class Railgun extends Bullpup;

// (one mode only: the Bullpup's semi/auto switch does nothing)
simulated function DoToggle();
function ServerChangeFireMode(bool bNewAltFire);
exec simulated function SwitchModes();

defaultproperties
{
     Element=4
     bUpgraded=True
     UpgradeName="Railgun"
     ItemName="Railgun"
     Description="A Horzine prototype railgun on a Bullpup's frame. Each slug goes through everything in its line to the wall."
     ClipCount=6
     ReloadRate=2.400000
     UpKick=900
     FireModeClass(0)=Class'KFMod.RailgunFire'
     PickupClass=Class'KFMod.RailgunPickup'
     Priority=7
     BrassClass=None
}
