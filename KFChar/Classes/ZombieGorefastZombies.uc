// Zombies gametype-specific Gorefast. Scaffolding for KFZombiesGameType tuning.
class ZombieGorefastZombies extends ZombieGorefast;

var() float ClawCooldown;
var float NextClawTime;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	damageConst = 50;
	damageRand = 0;
}

function ClawDamageTarget()
{
	if( Level.TimeSeconds < NextClawTime )
		Return;
	NextClawTime = Level.TimeSeconds + ClawCooldown;
	Super.ClawDamageTarget();
}

simulated function AnimEnd(int Channel)
{
	AnimAction = '';
	if ( bShotAnim && Channel==ExpectingChannel )
	{
		bShotAnim = false;
		if( Controller!=None )
			Controller.bPreparingMove = false;
	}
	if( !bPhysicsAnimUpdate && Channel==0 )
		bPhysicsAnimUpdate = Default.bPhysicsAnimUpdate;
	Super(Skaarj).AnimEnd(Channel);
}

State RunningState
{
   	function bool CanSpeedAdjust()
    {
        return false;
    }
	function BeginState()
	{
		SetGroundSpeed(OriginalGroundSpeed * 1.2);
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
    HealthMax=200.000000
    Health=200
	GroundSpeed=110.000000
    JumpZ=150.000000
    HiddenGroundSpeed=110.000000
    CollisionRadius=20.000000
	ClawCooldown=1.200000
    ScoringValue=3
	HitSound(0)=Sound'KFPlayerSoundOld.zpain1'
	HitSound(1)=Sound'KFPlayerSoundOld.zpain2'
	HitSound(2)=Sound'KFPlayerSoundOld.zpain3'
	HitSound(3)=Sound'KFPlayerSoundOld.zpain4'
	DeathSound(0)=Sound'KFPlayerSoundOld.ZombieDie1'
	DeathSound(1)=Sound'KFPlayerSoundOld.ZombieDie2'
	DeathSound(2)=Sound'KFPlayerSoundOld.ZombieDie3'
	DeathSound(3)=Sound'KFPlayerSoundOld.ZombieDie4'
	MoanVoice(0)=Sound'KFPlayerSoundOld.Moan1'
	MoanVoice(1)=Sound'KFPlayerSoundOld.Moan2'
	MoanVoice(2)=Sound'KFPlayerSoundOld.Moan3'
	MoanVoice(3)=Sound'KFPlayerSoundOld.Moan4'
	MoanVoice(4)=Sound'PatchSounds.GFBreathe'
	MeleeAnims(0)="ClawGore"
	MeleeAnims(1)="ClawGore"
	MeleeAnims(2)="ClawGore"
	MovementAnims(0)="WalkGore"
	WalkAnims(0)="WalkGore"
	WalkAnims(1)="WalkGore"
	WalkAnims(2)="WalkGore"
	WalkAnims(3)="WalkGore"
	HitAnims(0)="HitF"
	HitAnims(1)="HitF2"
	HitAnims(2)="HitF3"
	TurnLeftAnim="Turn"
	TurnRightAnim="Turn"
	AmbientSound=Sound'PatchSounds.GFAmbient'
	Mesh=SkeletalMesh'KFCharacterModelsOld.GoreFast'
	Skins(0)=Shader'KFCharactersOld.Zombie3Shader'
	ChallengeSound(0)=Sound'PatchSounds.GFFindTarget'
	ChallengeSound(1)=Sound'PatchSounds.GFFindTarget'
	ChallengeSound(2)=Sound'PatchSounds.GFFindTarget'
	ChallengeSound(3)=Sound'PatchSounds.GFFindTarget'
}
