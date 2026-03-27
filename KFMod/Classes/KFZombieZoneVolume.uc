// A special type of volume which functions like a blocking volume, but blocks ONLY humans from entering

class KFZombieZoneVolume extends BlockingVolume;

function Trigger( actor Other, pawn EventInstigator )
{
	SetCollision(!bCollideActors);
}

defaultproperties
{
<<<<<<< HEAD
	bClassBlocker=True
	BlockedClasses(0)=Class'KFMod.KFHumanPawn'
	bStatic=False
=======
     bClassBlocker=True
     BlockedClasses(0)=Class'KFMod.KFHumanPawn'
     bStatic=False
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
