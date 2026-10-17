Class BodyAttacher extends KBSJoint
	Transient;

var vector AttachEndPoint;
var() float WaitForDeath;	// how long the one hit has to fall for its body to be pinned: a hit that did not kill pins nothing
var() float NearHit;		// ...and how near where it was struck its body must be
var float MadeAt;
/* 
simulated function PostBeginPlay()
{
	SetTimer(1,False);
}
simulated function Timer()
{
	Destroy();
}
*/
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	MadeAt = Level.TimeSeconds;
}

// (a victim that lived could walk off and die anywhere in the next 20 s, and its body was dragged back toward this wall)
simulated function Tick( float Delta )
{
	if( Owner==None )
	{
		Destroy();
		Return;
	}
	if( Physics==PHYS_Karma )
		Return;
	if( Owner.Physics!=PHYS_KarmaRagdoll )
	{
		if( Level.TimeSeconds - MadeAt > WaitForDeath )
			Destroy();
		Return;
	}
	if( VSize(Owner.Location - Location) > NearHit )
	{
		Destroy();
		Return;
	}
	KConstraintActor1 = Owner;
	KPos1 = (Location-AttachEndPoint)/50.f;
	KPos2 = AttachEndPoint/50.f;
	KPriAxis1 = vect(1,0,0);
	KSecAxis1 = vect(0,0,1);
	KPriAxis2 = vect(1,0,0);
	KSecAxis2 = vect(0,0,1);
	SetPhysics(PHYS_Karma);
	SetTimer(0,False);
}

defaultproperties
{
	RemoteRole=ROLE_None
	bHidden=True
    bNoDelete=False
    Physics=PHYS_None
    LifeSpan=20.000000
    WaitForDeath=1.000000
    NearHit=150.000000
}
