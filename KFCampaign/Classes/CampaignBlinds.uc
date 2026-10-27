// Window blinds blowing (KFMod 1.0's Blinds, on 1.0's mesh).
class CampaignBlinds extends Decoration;

#exec OBJ LOAD FILE=KF10MapObjects.ukx

function PostBeginPlay()
{
	LinkSkelAnim(MeshAnimation'KF10MapObjects.Blinds');
	LoopAnim('bLow');
}

defaultproperties
{
	bStatic=False
	bStasis=False
	DrawType=DT_Mesh
	Mesh=SkeletalMesh'KF10MapObjects.Blinds'
}
