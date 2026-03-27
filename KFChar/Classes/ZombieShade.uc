// Zombie Monster for KF Invasion gametype

class ZombieShade extends KFMonster ;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFCharacterModels.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax

defaultproperties
{
     MeleeAnims(1)="Claw"
     MeleeAnims(2)="Claw2"
     damageRand=10
     damageConst=10
     damageForce=6000
     HitSound(0)=Sound'KFPlayerSound.zpain1'
     HitSound(1)=Sound'KFPlayerSound.zpain2'
     HitSound(2)=Sound'KFPlayerSound.zpain3'
     HitSound(3)=Sound'KFPlayerSound.zpain4'
     ScoringValue=1
     GroundSpeed=220.000000
     WaterSpeed=210.000000
     Health=900
     MenuName="Shade"
     MovementAnims(0)="WalkStalk"
     MovementAnims(1)="WalkStalk"
     MovementAnims(2)="WalkStalk"
     MovementAnims(3)="WalkStalk"
     WalkAnims(0)="WalkStalk"
     WalkAnims(1)="WalkStalk"
     WalkAnims(2)="WalkStalk"
     WalkAnims(3)="WalkStalk"
     Mesh=SkeletalMesh'KFCharacterModels.Shade'
     Skins(0)=TexOscillator'KFCharacters.ShadeSkinS'
     CollisionHeight=42.000000
     RotationRate=(Yaw=45000,Roll=0)
}
