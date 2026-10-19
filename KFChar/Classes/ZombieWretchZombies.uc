// Zombies gametype-specific Wretch. Scaffolding for KFZombiesGameType tuning.
class ZombieWretchZombies extends ZombieWretch;

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
	// (not Skaarj's: it goes on to Monster's, which lets the specimen go at the end of any animation, a flinch's too)
	Super(xPawn).AnimEnd(Channel);
}

defaultproperties
{
	Mesh=SkeletalMesh'KFCharacterModelsOld.InfectedWhiteMale1'
	Skins(0)=Shader'KFCharactersOld.Zombie2Shader'
	AmbientSound=Sound'KFPlayerSoundOld.Zombiesbreath'
	MovementAnims(0)="WalkStalk"
	MovementAnims(1)="WalkStalk"
	MovementAnims(2)="WalkStalk"
	MovementAnims(3)="WalkStalk"
	WalkAnims(0)="WalkStalk"
	WalkAnims(1)="WalkStalk"
	WalkAnims(2)="WalkStalk"
	WalkAnims(3)="WalkStalk"
	MeleeAnims(0)="Claw"
	MeleeAnims(1)="Claw2"
	MeleeAnims(2)="Claw3"
	HitAnims(0)="HitF"
	HitAnims(1)="HitF2"
	HitAnims(2)="HitF3"
	TurnLeftAnim="Turn"
	TurnRightAnim="Turn"
	AdditionalWalkAnims(0)="WalkF"
	HitSound(0)=Sound'KFPlayerSoundOld.zpain1'
	HitSound(1)=Sound'KFPlayerSoundOld.zpain2'
	HitSound(2)=Sound'KFPlayerSoundOld.zpain3'
	HitSound(3)=Sound'KFPlayerSoundOld.zpain4'
	MoanVoice(0)=Sound'KFPlayerSoundOld.Moan1'
	MoanVoice(1)=Sound'KFPlayerSoundOld.Moan2'
	MoanVoice(2)=Sound'KFPlayerSoundOld.Moan3'
	MoanVoice(3)=Sound'KFPlayerSoundOld.Moan4'
	MoanVoice(4)=Sound'KFPlayerSoundOld.zombiegrowl1'
	DeathSound(0)=Sound'KFPlayerSoundOld.ZombieDie1'
	DeathSound(1)=Sound'KFPlayerSoundOld.ZombieDie2'
	DeathSound(2)=Sound'KFPlayerSoundOld.ZombieDie3'
	DeathSound(3)=Sound'KFPlayerSoundOld.ZombieDie4'
	GroundSpeed=125.000000
	JumpZ=150.000000
	HiddenGroundSpeed=125.000000
	CollisionRadius=20.000000
	ClawCooldown=1.200000
	ScoringValue=3
}
