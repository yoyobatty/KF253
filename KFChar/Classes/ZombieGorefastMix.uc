// Zombie Monster for KF Invasion gametype
// GOREFAST.
// He's speedy, and swings with a Single enlongated arm, affording him slightly more range
class ZombieGorefastMix extends ZombieGorefast;

defaultproperties
{
     Mesh=SkeletalMesh'KFCharacterModels.SawZombie'
     DrawScale=0.800000
     Skins(0)=Shader'KFCharacters.Zombie6Shader'
     Skins(1)=Texture'KillingFloorWeapons.Chainsaw.ChainSawSkin3PZombie'
     Skins(2)=TexOscillator'KillingFloorWeapons.Chainsaw.SAWCHAIN'
     Skins(3)=Texture'KFCharacters.ScrakeFrock'
}
