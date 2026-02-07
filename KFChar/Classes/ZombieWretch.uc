// Zombie Monster for KF Invasion gametype

class ZombieWretch extends KFMonster;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFCharacterModels.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax

function ZombieMoan(){}

defaultproperties
{
     MeleeAnims(0)="ClawGore"
     MeleeAnims(1)="ClawGore"
     MeleeAnims(2)="ClawGore"
     bCannibal=True
     damageRand=2
     damageConst=3
     damageForce=5000
     KFRagdollName="ClotRag"
     PuntAnim="ClotPunt"
     AdditionalWalkAnims(0)="ClotWalk2"
     Intelligence=BRAINS_Mammal
     HitSound(0)=Sound'KFPlayerSound.zpain1'
     HitSound(1)=Sound'KFPlayerSound.zpain2'
     HitSound(2)=Sound'KFPlayerSound.zpain3'
     HitSound(3)=Sound'KFPlayerSound.zpain4'
     ScoringValue=1
     MeleeRange=30.000000
     GroundSpeed=135.000000
     WaterSpeed=125.000000
     HealthMax=165.000000
     Health=165
     MenuName="Wretch"
     MovementAnims(0)="WalkWretch"
     WalkAnims(0)="WalkStalk"
     WalkAnims(1)="WalkStalk"
     WalkAnims(2)="WalkWretch"
     WalkAnims(3)="WalkWretch"
     AmbientSound=Sound'KFPlayerSound.Zombiesbreath'
     Mesh=SkeletalMesh'KFCharacterModels.InfectedWhiteMale1'
     DrawScale=0.900000
     Skins(0)=Shader'KFCharacters.ZombieWShader'
     Mass=500.000000
     RotationRate=(Yaw=45000,Roll=0)
}
