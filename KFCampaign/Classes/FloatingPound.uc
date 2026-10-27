// Fleshpound floating in a tank (KFMod 1.0).
class FloatingPound extends Decoration;

#exec OBJ LOAD FILE=KF10MapObjects.ukx

function PostBeginPlay()
{
	LinkSkelAnim(MeshAnimation'KF10MapObjects.FloatingPound');
	LoopAnim('Idle');
}

defaultproperties
{
	bStatic=False
	DrawType=DT_Mesh
	Mesh=SkeletalMesh'KF10MapObjects.FloatingPound'
}
