// Zombies gametype-specific Clot. Scaffolding for KFZombiesGameType tuning.
class ZombieClotZombies extends ZombieClot;

var() float ClawCooldown;
var float NextClawTime;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	damageConst = 50;
	damageRand = 0;
}

// Its claws are whole-body animations (the clot's grapple is over the upper body only, so that one walks on while it
// grabs): it stops to swing, as other specimens do, or it slid along in the swing. (The clot's Tick, left out here,
// is the grapple's: it pushed the clot on at the target all through an attack.)
simulated function Tick(float DeltaTime)
{
	Super(KFMonster).Tick(DeltaTime);
}

function RangedAttack(Actor A)
{
	if ( bShotAnim || Physics == PHYS_Swimming )
		return;
	if ( CanAttack(A) )
	{
		bShotAnim = true;
		SetAnimAction('Claw');
		Controller.bPreparingMove = true;
		Acceleration = vect(0,0,0);
	}
}

function ClawDamageTarget()
{
	if( Level.TimeSeconds < NextClawTime )
		Return;
	NextClawTime = Level.TimeSeconds + ClawCooldown;
	Super(KFMonster).ClawDamageTarget();
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
	AmbientSound=Sound'KFPlayerSoundOld.Zombiesbreath'
	Mesh=SkeletalMesh'KFCharacterModelsOld.InfectedWhiteMale1'
	Skins(0)=Shader'KFCharactersOld.Zombie1Shader'
	MovementAnims(0)="RunL"
	MovementAnims(1)="RunR"
	MovementAnims(2)="RunR"
	MovementAnims(3)="RunL"
	WalkAnims(0)="WalkF"
	WalkAnims(1)="WalkF"
	WalkAnims(2)="WalkF"
	WalkAnims(3)="WalkF"
	MeleeAnims(0)="Claw"
	MeleeAnims(1)="Claw2"
	MeleeAnims(2)="Claw3"
	HitAnims(0)="HitF"
	HitAnims(1)="HitF2"
	HitAnims(2)="HitF3"
	IdleHeavyAnim="Idle_Biggun"
	IdleRifleAnim="Idle_Biggun"
	IdleCrouchAnim="Idle_Biggun"
	IdleWeaponAnim="Idle_Biggun"
	IdleRestAnim="Idle_Biggun"
	KFHitFront="HitF"
	KFHitBack="HitB"
	KFHitLeft="HitL"
	KFHitRight="HitR"
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
	GroundSpeed=85.000000
	JumpZ=150.000000
	HiddenGroundSpeed=85.000000
	CollisionRadius=20.000000
	ClawCooldown=1.200000
	ScoringValue=3
}
