// The helicopter of the outro (KFMod 1.0): flies over when triggered.
class ChopperFlyOver extends Decoration;

#exec OBJ LOAD FILE=KF10MapObjects.ukx

function Trigger( Actor Other, Pawn EventInstigator )
{
	Instigator = EventInstigator;
	LinkSkelAnim(MeshAnimation'KF10MapObjects.ChopperFlyOver');
	PlayAnim('FlyOver');
}

defaultproperties
{
	bStatic=False
	DrawType=DT_Mesh
	Mesh=SkeletalMesh'KF10MapObjects.ChopperFlyOver'
}
