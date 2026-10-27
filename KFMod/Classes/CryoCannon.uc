//=============================================================================
// CryoCannon
// A prototype freeze gun after Duke Nukem 3D's freezethrower, on the crossbow's frame in the white-blue camo of the
// upgraded guns (KFElement 4; it comes upgraded). Its bolt (CryoBolt) bursts into a freezing cloud: the specimens in it
// are frozen solid where they stand (KFMonster.Freeze), and one killed while frozen shatters like glass.
//=============================================================================
class CryoCannon extends Crossbow;

defaultproperties
{
     Element=4
     bUpgraded=True
     UpgradeName="Cryo Cannon"
     ItemName="Cryo Cannon"
     Description="A Horzine prototype freeze gun on a crossbow's frame. Its bolt bursts into a freezing cloud that freezes specimens solid; frozen ones break like glass."
     FireModeClass(0)=Class'KFMod.CryoFire'
     PickupClass=Class'KFMod.CryoPickup'
     Priority=8
}
