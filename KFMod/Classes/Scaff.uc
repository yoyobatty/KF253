class Scaff extends Decoration;

#exec OBJ LOAD FILE=KFMapObjects.ukx

function PostBeginPlay()
{
	LoopAnim('Flutter');
}

defaultproperties
{
<<<<<<< HEAD
	bStatic=False
	bNoDelete=True
	bStasis=False
	RemoteRole=ROLE_None
	Mesh=SkeletalMesh'KFMapObjects.Scaff'
=======
     bStatic=False
     bNoDelete=True
     bStasis=False
     RemoteRole=ROLE_None
     Mesh=SkeletalMesh'KFMapObjects.Scaff'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
