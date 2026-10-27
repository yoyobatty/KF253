// The undead soldier of the campaign: 1.0's mesh, skin and sounds on KFMod254's specimen, with KFMod254's specimen
// animations (the same skeleton; 1.0's set lacks the hit, stun and knock-down sequences KFMod254's code plays).
class CampaignZombieSoldier extends ZombieSoldier;

simulated function BeginPlay()
{
	LinkSkelAnim(MeshAnimation'KFCharacterModels.InfectedWhiteMale1');
	Super.BeginPlay();
}

defaultproperties
{
	HitSound(0)=Sound'KF10PlayerSound.zpain1'
	HitSound(1)=Sound'KF10PlayerSound.zpain2'
	HitSound(2)=Sound'KF10PlayerSound.zpain3'
	HitSound(3)=Sound'KF10PlayerSound.zpain4'
	AmbientSound=Sound'KF10PlayerSound.Zombiesbreath'
	Mesh=SkeletalMesh'KF10CharacterModels.InfectedWhiteSoldier'
	Skins(0)=Shader'KF10Characters.Zombie8Shader'
}
