class Drapes extends Decoration;     // Decoration

#exec OBJ LOAD FILE=KFMapObjects.ukx

function PostBeginPlay() {
   LinkSkelAnim(MeshAnimation'Drapes');
   LoopAnim('Flap');

}

defaultproperties
{
<<<<<<< HEAD
	bStatic=False
	bNoDelete=True
	bStasis=False
	RemoteRole=ROLE_None
	Mesh=SkeletalMesh'KFMapObjects.Drapes'
=======
     bStatic=False
     bNoDelete=True
     bStasis=False
     RemoteRole=ROLE_None
     Mesh=SkeletalMesh'KFMapObjects.Drapes'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
