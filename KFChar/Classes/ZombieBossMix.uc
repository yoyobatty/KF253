// Zombie Monster for KF Invasion gametype
class ZombieBossMix extends ZombieBoss;

simulated function BeginPlay()
{
	LinkSkelAnim(MeshAnimation'BossAnims');
	Super.BeginPlay();
}

defaultproperties
{
     Mesh=SkeletalMesh'KFCharacterModels.InfectedWhiteMale1'
     DrawScale=1.300000
     Skins(0)=Texture'KFCharacters.ClotSkin'
     Skins(1)=Texture'KFCharacters.ClotSkin'
     Skins(2)=Texture'KFCharacters.ClotSkin'
     Skins(3)=Texture'KFCharacters.ClotSkin'
     Skins(4)=Texture'KFCharacters.ClotSkin'
     Skins(5)=Texture'KFCharacters.ClotSkin'
     Skins(6)=Texture'KFCharacters.ClotSkin'
}
