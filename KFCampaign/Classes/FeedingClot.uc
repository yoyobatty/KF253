// Feeding clot in the intro (KFMod 1.0).
class FeedingClot extends Decoration;

#exec OBJ LOAD FILE=KF10MapObjects.ukx

function PostBeginPlay()
{
	LinkSkelAnim(MeshAnimation'KF10MapObjects.FeedingClot');
	LoopAnim('Feeding');
}

defaultproperties
{
	bStatic=False
	DrawType=DT_Mesh
	Mesh=SkeletalMesh'KF10MapObjects.FeedingClot'
}
