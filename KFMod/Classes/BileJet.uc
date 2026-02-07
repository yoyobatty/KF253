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
     bHidden=True
     LifeSpan=2.500000
}
