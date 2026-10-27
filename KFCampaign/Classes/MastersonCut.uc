// Masterson in cutscenes (KFMod 1.0).
class MastersonCut extends Decoration;

#exec OBJ LOAD FILE=KF10MapObjects.ukx

function PostBeginPlay()
{
	LinkSkelAnim(MeshAnimation'KF10MapObjects.MastersonCut');
	LoopAnim('Idle');
}

defaultproperties
{
	bStatic=False
	DrawType=DT_Mesh
	Mesh=SkeletalMesh'KF10MapObjects.MastersonCut'
}
