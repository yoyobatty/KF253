class BloodySheet extends Decoration;

simulated function PostBeginPlay()
{
	if( Level.NetMode!=NM_DedicatedServer )
		LoopAnim('Sway');
}

defaultproperties
{
<<<<<<< HEAD
	bStatic=False
	bNoDelete=True
	RemoteRole=ROLE_None
	Mesh=SkeletalMesh'KFMapObjects.BloodySheet'
=======
     bStatic=False
     bNoDelete=True
     RemoteRole=ROLE_None
     Mesh=SkeletalMesh'KFMapObjects.BloodySheet'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
