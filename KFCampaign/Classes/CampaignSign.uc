// A hanging sign swinging in the wind (KFMod 1.0's Sign, on 1.0's mesh).
class CampaignSign extends Decoration;

#exec OBJ LOAD FILE=KF10MapObjects.ukx

function PostBeginPlay()
{
	LinkSkelAnim(MeshAnimation'KF10MapObjects.sign');
	LoopAnim('swing');
}

defaultproperties
{
	bStatic=False
	bStasis=False
	DrawType=DT_Mesh
	Mesh=SkeletalMesh'KF10MapObjects.sign'
}
