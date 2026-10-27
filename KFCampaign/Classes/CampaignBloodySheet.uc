// A bloody sheet swaying (KFMod 1.0's BloodySheet, on 1.0's mesh).
class CampaignBloodySheet extends Decoration;

#exec OBJ LOAD FILE=KF10MapObjects.ukx

function PostBeginPlay()
{
	LinkSkelAnim(MeshAnimation'KF10MapObjects.BloodySheet');
	LoopAnim('Sway');
}

defaultproperties
{
	bStatic=False
	bStasis=False
	DrawType=DT_Mesh
	Mesh=SkeletalMesh'KF10MapObjects.BloodySheet'
}
