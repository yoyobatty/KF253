// Zombies gametype-specific Stalker. Scaffolding for KFZombiesGameType tuning.
class ZombieStalkerZombies extends ZombieStalker;

var() float ClawCooldown;
var float NextClawTime;

simulated function PostBeginPlay()
{
	Super(KFMonster).PostBeginPlay();
	damageConst = 50;
	damageRand = 0;
}


simulated function Tick(float DeltaTime)
{
	Super(KFMonster).Tick(DeltaTime);
}

function ClawDamageTarget()
{
	if( Level.TimeSeconds < NextClawTime )
		Return;
	NextClawTime = Level.TimeSeconds + ClawCooldown;
	Super.ClawDamageTarget();
}

function RemoveHead()
{
	Super(KFMonster).RemoveHead();
}

simulated function SeverHead( bool bThrow, optional rotator Dir, optional float Spread, optional class<DamageType> DamageType )
{
	Super(KFMonster).SeverHead(bThrow, Dir, Spread, DamageType);
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	Super(KFMonster).PlayDying(DamageType,HitLoc);

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
	GroundSpeed=160.000000
	JumpZ=150.000000
	HiddenGroundSpeed=160.000000
	CollisionRadius=20.000000
	ClawCooldown=1.200000
	ScoringValue=3
	MovementAnims(0)="ZombieRun"
	MovementAnims(1)="ZombieRun"
	MovementAnims(2)="ZombieRun"
	MovementAnims(3)="ZombieRun"
	WalkAnims(0)="ZombieRun"
	WalkAnims(1)="ZombieRun"
	WalkAnims(2)="ZombieRun"
	WalkAnims(3)="ZombieRun"
	MeleeAnims(0)="Claw"
	MeleeAnims(1)="Claw3"
	MeleeAnims(2)="JumpAttack"
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
	MoanVoice(4)=Sound'KFPlayerSoundOld.zombiegrowl1'
	AmbientSound=Sound'KFPlayerSoundOld.Zombiesbreath'
	Mesh=SkeletalMesh'KFCharacterModelsOld.InfectedWhiteFemale'
	Skins(0)=Shader'KFCharactersOld.Zombie4Shader'
	Skins(1)=Texture'KFCharactersOld.ZombieFemaleHair'
}
