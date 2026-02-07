// A very stupid hack for large zombies.
<<<<<<< HEAD
Class ExtendedZCollision extends Actor
	NotPlaceable
	Transient;

var vector Offset;

function Tick( float Delta )
{
	local vector V;

	if( Owner==None )
	{
		Destroy();
		Return;
	}
	V = Owner.Location+Offset;
	if( Location!=V )
		Move(V-Location);
}
function TakeDamage(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType)
=======
class ExtendedZCollision extends Actor
	NotPlaceable
	Transient;

// Damage the player this is attached to
function TakeDamage( int Damage, Pawn EventInstigator, Vector Hitlocation, Vector Momentum, class<DamageType> damageType)
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
{
	if( Owner!=None )
		Owner.TakeDamage(Damage,EventInstigator,HitLocation,Momentum,DamageType);
}

defaultproperties
{
<<<<<<< HEAD
	bHidden=True
	RemoteRole=ROLE_None
	SurfaceType=EST_Flesh
	bCollideActors=True
	bProjTarget=True
=======
	RemoteRole=ROLE_None
	bHidden=False
	bCollideActors=True
	bProjTarget=True
	SurfaceType=EST_Flesh
	DrawType=DT_None
	// Debug draw
	//DrawType=DT_Sprite
	//Texture=S_Actor
	//DrawScale=+00001.000000
	//DrawScale=+00000.0100000
	//DrawScale3D=(X=1,Y=1,Z=1)
	bCollideWorld=False
	bBlockKarma=False
	bIgnoreEncroachers=True
	bUseCylinderCollision=true
	bBlockActors=False
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
