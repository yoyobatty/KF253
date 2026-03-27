Class BodyAttacher extends KBSJoint
	Transient;

var vector AttachEndPoint;
<<<<<<< HEAD

=======
/* 
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated function PostBeginPlay()
{
	SetTimer(1,False);
}
simulated function Timer()
{
	Destroy();
}
<<<<<<< HEAD
=======
*/
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated function Tick( float Delta )
{
	if( Owner==None )
	{
		Destroy();
		Return;
	}
	if( Physics==PHYS_Karma || Owner.Physics!=PHYS_KarmaRagdoll )
		Return;
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
<<<<<<< HEAD
	bNoDelete=False
	Physics=PHYS_None
	LifeSpan=20.000000
=======
	RemoteRole=ROLE_None
	bHidden=True
    bNoDelete=False
    Physics=PHYS_None
    LifeSpan=20.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
