Class BossHPNeedle extends Decoration
	NotPlaceable;

#exec obj load file="NewPatchSM.usx"

simulated function DroppedNow()
{
	SetCollision(True);
	SetPhysics(PHYS_Falling);
	bFixedRotationDir = True;
	RotationRate = RotRand(True);
}
simulated function HitWall( vector HitNormal, actor HitWall )
{
	local rotator R;

	if( VSize(Velocity)<40 )
	{
		SetPhysics(PHYS_None);
		R.Roll = Rand(65536);
		R.Yaw = Rand(65536);
		SetRotation(R);
		Return;
	}
	Velocity = MirrorVectorByNormal(Velocity,HitNormal)*0.75;
	if( HitWall!=None && HitWall.Physics!=PHYS_None )
		Velocity+=HitWall.Velocity;
}
simulated function Landed( vector HitNormal )
{
	HitWall(HitNormal,None);
}
simulated function TakeDamage( int NDamage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
	if( Physics==PHYS_None )
	{
		SetPhysics(PHYS_Falling);
		bFixedRotationDir = True;
		RotationRate = RotRand(True);
		Velocity = vect(0,0,0);
	}
	Velocity+=momentum/10;
}
simulated function Destroyed();
function Bump( actor Other );
singular function PhysicsVolumeChange( PhysicsVolume NewVolume );

defaultproperties
{
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'NewPatchSM.BossSyringe'
     bStatic=False
     RemoteRole=ROLE_None
     LifeSpan=300.000000
     CollisionRadius=4.000000
     CollisionHeight=4.000000
     bCollideWorld=True
     bProjTarget=True
     bBounce=True
}
