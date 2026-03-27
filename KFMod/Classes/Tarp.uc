class Tarp extends Decoration;     // Decoration

#exec OBJ LOAD FILE=KFMapObjects.ukx

function PostBeginPlay() {
   LinkSkelAnim(MeshAnimation'Tarp');
   LoopAnim('bLow');
}

defaultproperties
{
     bStatic=False
     bStasis=False
     bReplicateAnimations=True
     Mesh=SkeletalMesh'KFMapObjects.Tarp'
}
