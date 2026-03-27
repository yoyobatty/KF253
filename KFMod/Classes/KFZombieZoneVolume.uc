// A special type of volume which functions like a blocking volume, but blocks ONLY humans from entering

class KFZombieZoneVolume extends BlockingVolume;

defaultproperties
{
     bClassBlocker=True
     BlockedClasses(0)=Class'KFMod.KFHumanPawn'
     BlockedClasses(1)=Class'KFMod.KFHumanPawnLight'
     BlockedClasses(2)=Class'KFMod.KFHumanPawnHeavy'
}
