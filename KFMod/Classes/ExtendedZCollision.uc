// A very stupid hack for large zombies.
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
{
	if( Owner!=None )
		Owner.TakeDamage(Damage,EventInstigator,HitLocation,Momentum,DamageType);
}

defaultproperties
{
	bHidden=True
	RemoteRole=ROLE_None
	SurfaceType=EST_Flesh
	bCollideActors=True
	bProjTarget=True
}
