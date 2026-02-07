// Zombie Monster for KF Invasion gametype
class ZombieSirenMix extends ZombieSiren;

simulated function BeginPlay()
{
	LinkSkelAnim(MeshAnimation'KFCharacterModels.SirenSet');
	Super.BeginPlay();
}

defaultproperties
{
	Mesh=SkeletalMesh'KFBoss.Boss'
	DrawScale=0.800000
	Skins(0)=FinalBlend'KFPatch2.BossHairFB'
	Skins(1)=Texture'KFPatch2.BossBits'
}
