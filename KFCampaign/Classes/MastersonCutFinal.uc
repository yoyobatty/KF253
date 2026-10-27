// Masterson's last cutscene (KFMod 1.0).
class MastersonCutFinal extends Decoration;

#exec OBJ LOAD FILE=KF10MapObjects.ukx

function PostBeginPlay()
{
	LinkSkelAnim(MeshAnimation'KF10MapObjects.MastersonCut');
	LoopAnim('CutEnd');
}

defaultproperties
{
	bStatic=False
	DrawType=DT_Mesh
	Mesh=SkeletalMesh'KF10MapObjects.MastersonCut'
}
