// Gavin, the injured soldier in KFS-01 (KFMod 1.0's InjuredSoldier, on 1.0's mesh).
class CampaignInjuredSoldier extends Decoration;

#exec OBJ LOAD FILE=KF10MapObjects.ukx

function PostBeginPlay()
{
	LinkSkelAnim(MeshAnimation'KF10MapObjects.SoldierInjured');
	LoopAnim('idle');
}

defaultproperties
{
	bStatic=False
	bStasis=False
	DrawType=DT_Mesh
	Mesh=SkeletalMesh'KF10MapObjects.SoldierInjured'
}
