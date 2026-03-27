// A very stupid hack for large zombies.
class ExtendedZCollision extends Actor
	NotPlaceable
	Transient;

// Damage the player this is attached to
function TakeDamage( int Damage, Pawn EventInstigator, Vector Hitlocation, Vector Momentum, class<DamageType> damageType)
{
	if( Owner!=None )
		Owner.TakeDamage(Damage,EventInstigator,HitLocation,Momentum,DamageType);
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
