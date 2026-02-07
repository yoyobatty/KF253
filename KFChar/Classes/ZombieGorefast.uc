// Zombie Monster for KF Invasion gametype
// GOREFAST.
// He's speedy, and swings with a Single enlongated arm, affording him slightly more range
class ZombieGoreFast extends KFMonster;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFCharacterModels.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax

var bool bRunning;

replication
{
	reliable if(Role == ROLE_Authority)
		bRunning;
}

simulated function PostNetReceive()
{
	if (bRunning)
		MovementAnims[0]='ZombieRun';
	else MovementAnims[0]=default.MovementAnims[0];
}

function PlayZombieAttackHitSound()
{
	local int MeleeAttackSounds;

	MeleeAttackSounds = rand(3);

	switch(MeleeAttackSounds)
	{
		case 0:
			PlaySound(sound'KFWeaponSound.knife_hit2', SLOT_Interact);
			break;
		case 1:
			PlaySound(sound'KFWeaponSound.knife_hit3', SLOT_Interact);
			break;
		case 2:
			PlaySound(sound'KFWeaponSound.knife_hit4', SLOT_Interact);
	}
}

function RangedAttack(Actor A)
{
	Super.RangedAttack(A);
	if( !bShotAnim && !bDecapitated && VSize(A.Location-Location)<=400 )
		GoToState('RunningState');
}

State RunningState
{
	function BeginState()
	{
		SetGroundSpeed(OriginalGroundSpeed * 1.7);
		bRunning = true;
		if( Level.NetMode!=NM_DedicatedServer )
			PostNetReceive();
	}
	function EndState()
	{
		SetGroundSpeed(OriginalGroundSpeed);
		bRunning = False;
		if( Level.NetMode!=NM_DedicatedServer )
			PostNetReceive();
	}
	function RemoveHead()
	{
		GoToState('');
		Global.RemoveHead();
	}
	function RangedAttack(Actor A)
	{
		Super.RangedAttack(A);
	}
Begin:
	While( Controller!=None && Controller.Target!=None && VSize(Controller.Target.Location-Location)<400 )
		Sleep(0.5+FRand());
	GoToState('');
}

defaultproperties
{
     MeleeAnims(0)="GoreAttack1"
     MeleeAnims(1)="GoreAttack2"
     MeleeAnims(2)="GoreAttack1"
     MoanVoice(0)=Sound'KFPlayerSound.GoreFastVoice2'
     MoanVoice(1)=Sound'KFPlayerSound.GoreFastVoice4'
     MoanVoice(2)=Sound'KFPlayerSound.GoreFastVoice2'
     bCannibal=True
     damageRand=10
     damageConst=10
     damageForce=5000
     HitSound(0)=Sound'KFPlayerSound.zpain1'
     HitSound(1)=Sound'KFPlayerSound.zpain2'
     HitSound(2)=Sound'KFPlayerSound.zpain3'
     HitSound(3)=Sound'KFPlayerSound.zpain4'
     ChallengeSound(0)=Sound'KFPlayerSound.GoreFastVoice1'
     ChallengeSound(1)=Sound'KFPlayerSound.GoreFastVoice1'
     ChallengeSound(2)=Sound'KFPlayerSound.GoreFastVoice3'
     ChallengeSound(3)=Sound'KFPlayerSound.GoreFastVoice3'
     ScoringValue=3
     IdleHeavyAnim="GoreIdle"
     IdleRifleAnim="GoreIdle"
     MeleeRange=60.000000
     GroundSpeed=140.000000
     WaterSpeed=130.000000
     HealthMax=350.000000
     Health=350
	 HeadHealth=150.000000
     MenuName="Gorefast"
     ControllerClass=Class'KFChar.GorefastController'
     MovementAnims(0)="GoreWalk"
     WalkAnims(0)="GoreWalk"
     WalkAnims(1)="GoreWalk"
     WalkAnims(2)="GoreWalk"
     WalkAnims(3)="GoreWalk"
     IdleCrouchAnim="GoreIdle"
     IdleWeaponAnim="GoreIdle"
     IdleRestAnim="GoreIdle"
     AmbientSound=Sound'KFPlayerSound.Zombiesbreath'
     Mesh=SkeletalMesh'KFCharacterModels.GoreFast'
     Skins(0)=Shader'KFCharacters.Zombie3Shader'
     Mass=350.000000
     RotationRate=(Yaw=45000,Roll=0)
}
