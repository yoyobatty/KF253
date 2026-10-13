// A very stupid hack for large zombies.
class ExtendedZCollision extends Actor
	NotPlaceable
	Transient;

// Damage the player this is attached to
function TakeDamage( int Damage, Pawn EventInstigator, Vector Hitlocation, Vector Momentum, class<DamageType> damageType)
{
	if( Owner!=None && !IsBlast(HitLocation,Momentum) )
		Owner.TakeDamage(Damage,EventInstigator,HitLocation,Momentum,DamageType);
}

// A blast hurts everything in reach, so the owner already gets it directly and must not get it again here.
// Blast code hands each victim a hit point half its size from its centre, on the line to the blast.
// A shot that lands on this cylinder does not look like that.
function bool IsBlast( vector HitLocation, vector Momentum )
{
	local vector Out;

	Out = HitLocation - Location;
	if ( Abs(VSize(Out) - 0.5 * (CollisionHeight + CollisionRadius)) > 0.05 )
		return false;
	return Momentum == vect(0,0,0) || Abs(Normal(Momentum) dot Normal(Out)) > 0.9999;
}

defaultproperties
{
     DrawType=DT_None
     bIgnoreEncroachers=True
     RemoteRole=ROLE_None
     SurfaceType=EST_Flesh
     bCollideActors=True
     bProjTarget=True
     bUseCylinderCollision=True
}
/* 
defaultproperties
{
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
	//bBlockActors=False
}
*/
