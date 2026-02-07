// Zombie Monster for KF Invasion gametype

class ZombieWretch extends KFMonster ;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFCharacterModels.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax

defaultproperties
{
	damageRand=4
	damageConst=7
	damageForce=5000
	HitSound(0)=Sound'KFPlayerSound.zpain1'
	HitSound(1)=Sound'KFPlayerSound.zpain2'
	HitSound(2)=Sound'KFPlayerSound.zpain3'
	HitSound(3)=Sound'KFPlayerSound.zpain4'
	ScoringValue=1
	GroundSpeed=135.000000
	WaterSpeed=125.000000
	Health=165
	MenuName="Wertch"
	MovementAnims(0)="WalkStalk"
	WalkAnims(0)="WalkStalk"
	WalkAnims(1)="WalkStalk"
	WalkAnims(2)="WalkStalk"
	WalkAnims(3)="WalkStalk"
	AmbientSound=Sound'KFPlayerSound.Zombiesbreath'
	Mesh=SkeletalMesh'KFCharacterModels.InfectedWhiteMale2'
	Skins(0)=Shader'KFCharacters.Zombie2Shader'
	Mass=500.000000
	RotationRate=(Yaw=45000,Roll=0)
}
