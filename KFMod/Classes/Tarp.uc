class Tarp extends Decoration;     // Decoration

#exec OBJ LOAD FILE=KFMapObjects.ukx

function PostBeginPlay() {
   LinkSkelAnim(MeshAnimation'Tarp');
   LoopAnim('bLow');
}

defaultproperties
{
<<<<<<< HEAD
	bStatic=False
	bStasis=False
	bReplicateAnimations=True
	Mesh=SkeletalMesh'KFMapObjects.Tarp'
=======
     bStatic=False
     bStasis=False
     bReplicateAnimations=True
     Mesh=SkeletalMesh'KFMapObjects.Tarp'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
