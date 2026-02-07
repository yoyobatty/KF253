class Trader extends Decoration;

#exec OBJ LOAD FILE=KFMapObjects.ukx

simulated function PostBeginPlay()
{
	if( Level.NetMode!=NM_DedicatedServer )
		LoopAnim('Idle');
}

defaultproperties
{
<<<<<<< HEAD
	bStatic=False
	bNoDelete=True
	bStasis=False
	RemoteRole=ROLE_None
	Mesh=SkeletalMesh'KFMapObjects.Trader'
=======
     bStatic=False
     bNoDelete=True
     bStasis=False
     RemoteRole=ROLE_None
     Mesh=SkeletalMesh'KFMapObjects.Trader'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
