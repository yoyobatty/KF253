// Guard in the outro (KFMod 1.0).
class LabGuard extends Decoration;

#exec OBJ LOAD FILE=KF10MapObjects.ukx

function PostBeginPlay()
{
	LinkSkelAnim(MeshAnimation'KF10MapObjects.LabGuard');
	LoopAnim('Guarding');
}

defaultproperties
{
	bStatic=False
	DrawType=DT_Mesh
	Mesh=SkeletalMesh'KF10MapObjects.LabGuard'
}
