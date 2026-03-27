//-----------------------------------------------------------
//
//-----------------------------------------------------------
class BileJet extends Actor;

function PostBeginPlay()
{
	settimer(0.5, true);
}

simulated function timer()
{
	local vector X,Y,Z, FireStart;
	local rotator FireRotation;

	GetAxes(Rotation,X,Y,Z);
	FireStart = location;
	FireRotation = rotation;

	Spawn(class'KFMod.KFVomitJet',,,FireStart, FireRotation);
	Spawn(Class'KFMod.KFBloatVomit',,,FireStart,FireRotation);

	FireStart = FireStart - 1.8 * CollisionRadius * Y;
	FireRotation.Yaw += 400;
	spawn(Class'KFMod.KFBloatVomit',,,FireStart, FireRotation);

	FireStart = FireStart - 1.8 * CollisionRadius * Z;
	FireRotation.Pitch += 400;
	spawn(Class'KFMod.KFBloatVomit',,,FireStart, FireRotation);

	FireStart = FireStart - 1.8 * CollisionRadius * X;
	FireRotation.Roll += 400;
	spawn(Class'KFMod.KFBloatVomit',,,FireStart, FireRotation);
}

defaultproperties
{
<<<<<<< HEAD
	bHidden=True
	LifeSpan=2.500000
=======
     bHidden=True
     LifeSpan=2.500000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
