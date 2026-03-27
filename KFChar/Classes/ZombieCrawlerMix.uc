// Zombie Monster for KF Invasion gametype
class ZombieCrawlerMix extends ZombieCrawler;

simulated function BeginPlay()
{
	LinkSkelAnim(MeshAnimation'InfectedWhiteMale1');
	Super.BeginPlay();
}

defaultproperties
{
<<<<<<< HEAD
	Mesh=SkeletalMesh'KFCharacterModels.InfectedWhiteMale2'
	Skins(0)=Texture'KFCharacters.SirenSkin'
	Skins(1)=FinalBlend'KFCharacters.SirenHairFB'
=======
     Mesh=SkeletalMesh'KFCharacterModels.InfectedWhiteMale2'
     Skins(0)=Texture'KFCharacters.SirenSkin'
     Skins(1)=FinalBlend'KFCharacters.SirenHairFB'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
