// Zombie Monster for KF Invasion gametype
class ZombieClot extends KFMonster;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFCharacterModels.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax

function ClawDamageTarget()
{
	local vector PushDir;
  
	Super.ClawDamageTarget();

	// If zombie has latched onto us...
	if ( MeleeDamageTarget( (damageConst + rand(damageRand) ), PushDir))
	{
		if( !bDecapitated && KFHumanPawn(Controller.Target)!=None )
			Pawn(Controller.Target).GroundSpeed = 1;
	}
}

function RangedAttack(Actor A)
{
	if ( bShotAnim || Physics == PHYS_Swimming )
		return;
	else if ( CanAttack(A) )
	{
		bShotAnim = true;
		SetAnimAction('Claw');
		//PlaySound(sound'Claw2s', SLOT_None); Unsuitable sound for here.
		Acceleration = Normal(A.Location-Location)*600;
		Controller.GoToState('WaitForAnim');
		Controller.MoveTarget = A;
		Controller.MoveTimer = 1.5;
	}
}
function RemoveHead()
{
	Super.RemoveHead();
	MeleeAnims[0] = 'Claw';
	MeleeAnims[1] = 'Claw';
	MeleeAnims[2] = 'Claw2';
	
    damageRand *= 2;
    damageConst *= 2;
    MeleeRange *= 2;
}

defaultproperties
{
     MeleeAnims(0)="ClotGrapple"
     MeleeAnims(1)="ClotGrapple"
     MeleeAnims(2)="ClotGrapple"
     MoanVoice(0)=Sound'KFPlayerSound.ClotVoice1'
     MoanVoice(1)=Sound'KFPlayerSound.ClotVoice2'
     MoanVoice(2)=Sound'KFPlayerSound.ClotVoice3'
     MoanVoice(3)=Sound'KFPlayerSound.ClotVoice4'
     MoanVoice(4)=Sound'KFPlayerSound.ClotVoice5'
     bCannibal=True
     damageRand=2
     damageConst=3
     damageForce=5000
     KFRagdollName="ClotRag"
     PuntAnim="ClotPunt"
     AdditionalWalkAnims(0)="ClotWalk2"
     HitSound(0)=Sound'KFPlayerSound.zpain1'
     HitSound(1)=Sound'KFPlayerSound.zpain2'
     HitSound(2)=Sound'KFPlayerSound.zpain3'
     HitSound(3)=Sound'KFPlayerSound.zpain4'
     ScoringValue=1
     MeleeRange=30.000000
     GroundSpeed=105.000000
     WaterSpeed=105.000000
     HealthMax=200.000000
     Health=200
     MenuName="Clot"
     MovementAnims(0)="ClotWalk"
     WalkAnims(0)="ClotWalk"
     WalkAnims(1)="ClotWalk"
     WalkAnims(2)="ClotWalk"
     WalkAnims(3)="ClotWalk"
     AmbientSound=Sound'KFPlayerSound.Zombiesbreath'
     Mesh=SkeletalMesh'KFCharacterModels.InfectedWhiteMale1'
     Skins(0)=Shader'KFCharacters.Zombie1Shader'
     RotationRate=(Yaw=45000,Roll=0)
}
