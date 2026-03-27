// Zombie Monster for KF Invasion gametype
class ZombieFleshPoundMix extends ZombieFleshPound;

// changes colors on Device (notified in anim)
simulated function DeviceGoRed();
simulated function DeviceGoNormal();

defaultproperties
{
     Mesh=SkeletalMesh'KFCharacterModels.GoreFast'
     Skins(0)=Texture'KFCharacters.GorefastSkin'
     Skins(1)=Texture'KFCharacters.GorefastSkin'
     Skins(2)=Texture'KFCharacters.GorefastSkin'
     Skins(3)=Texture'KFCharacters.GorefastSkin'
}
