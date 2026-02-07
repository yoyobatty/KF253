// Zombie Monster for KF Invasion gametype
class ZombieBloatMix extends ZombieBloat;

simulated function BeginPlay()
{
	LinkSkelAnim(MeshAnimation'BloatSet');
	Super.BeginPlay();
}

defaultproperties
{
	Mesh=SkeletalMesh'KFCharacterModels.ZombieBoss'
	Skins(0)=Texture'KFCharacters.PoundSkin'
	Skins(1)=Shader'KFCharacters.PoundBitsShader'
	Skins(2)=FinalBlend'KFCharacters.YellowPoundMeter'
	Skins(3)=Shader'KFCharacters.FPAmberBloomShader'
}
