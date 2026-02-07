class Flag extends Decoration;

#exec OBJ LOAD FILE=KFMapObjects.ukx

function PostBeginPlay()
{
	if( Level.NetMode!=NM_DedicatedServer )
		LoopAnim('Fly');
}

defaultproperties
{
<<<<<<< HEAD
	bStatic=False
	bNoDelete=True
	bStasis=False
	RemoteRole=ROLE_None
	Mesh=SkeletalMesh'KFMapObjects.flag'
=======
     bStatic=False
     bNoDelete=True
     bStasis=False
     RemoteRole=ROLE_None
     Mesh=SkeletalMesh'KFMapObjects.flag'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
