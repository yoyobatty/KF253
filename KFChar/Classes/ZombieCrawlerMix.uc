// Zombie Monster for KF Invasion gametype
class ZombieCrawlerMix extends ZombieCrawler;

simulated function BeginPlay()
{
	LinkSkelAnim(MeshAnimation'InfectedWhiteMale1');
	Super.BeginPlay();
}

defaultproperties
{
	Mesh=SkeletalMesh'KFCharacterModels.InfectedWhiteMale2'
	Skins(0)=Texture'KFCharacters.SirenSkin'
	Skins(1)=FinalBlend'KFCharacters.SirenHairFB'
}
