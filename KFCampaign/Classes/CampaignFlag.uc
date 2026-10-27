// A flag flying (KFMod 1.0's Flag, on 1.0's mesh).
class CampaignFlag extends Decoration;

#exec OBJ LOAD FILE=KF10MapObjects.ukx

function PostBeginPlay()
{
	LinkSkelAnim(MeshAnimation'KF10MapObjects.Flag');
	LoopAnim('Fly');
}

defaultproperties
{
	bStatic=False
	bStasis=False
	DrawType=DT_Mesh
	Mesh=SkeletalMesh'KF10MapObjects.flag'
}
