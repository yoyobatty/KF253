class Sign extends Decoration;

#exec OBJ LOAD FILE=KFMapObjects.ukx

simulated function PostBeginPlay()
{
	LoopAnim('swing');
}

defaultproperties
{
<<<<<<< HEAD
	bStatic=False
	bNoDelete=True
	bStasis=False
	RemoteRole=ROLE_None
	Mesh=SkeletalMesh'KFMapObjects.sign'
=======
     bStatic=False
     bNoDelete=True
     bStasis=False
     RemoteRole=ROLE_None
     Mesh=SkeletalMesh'KFMapObjects.sign'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
