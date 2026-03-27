// Chainsaw Zombie Monster for KF Invasion gametype
// He's not quite as speedy as the other Zombies, But his attacks are TRULY damaging.
//Charges when you're too close or looking away
class ZombieScrake extends KFMonster ;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFCharacterModels.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax

simulated Function PostNetBeginPlay()
{
	EnableChannelNotify ( 1,1);
	AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
	super.PostNetBeginPlay();
}

function RangedAttack(Actor A)
{
	if ( bShotAnim || Physics == PHYS_Swimming)
		return;
	else if ( CanAttack(A) )
	{
		bShotAnim = true;
		SetAnimAction(MeleeAnims[Rand(2)]);
		CurrentDamType = ZombieDamType[0];
		PlaySound(sound'Claw2s', SLOT_None);
		GoToState('SawingLoop');
	}
	if( !bShotAnim && !bDecapitated && (VSize(A.Location-Location)<200 || (Normal(Controller.Target.Location - Location) dot vector(Controller.Target.Rotation) > 0.0) ) )
		GoToState('RunningState');
}

State RunningState
{
   	function bool CanSpeedAdjust()
    {
        return false;
    }
	function BeginState()
	{
		SetGroundSpeed(OriginalGroundSpeed * 2.5);
		if( Level.NetMode!=NM_DedicatedServer )
			PostNetReceive();
	}
	function EndState()
	{
		SetGroundSpeed(OriginalGroundSpeed);
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
	     if ( bShotAnim || Physics == PHYS_Swimming)
		     return;
	     else if ( CanAttack(A) )
	     {
		     bShotAnim = true;
		     SetAnimAction(MeleeAnims[Rand(2)]);
			 CurrentDamType = ZombieDamType[0];
		     PlaySound(sound'Claw2s', SLOT_None);
		     GoToState('SawingLoop');
	     }
	}
Begin:
	While( Controller!=None && Controller.Target!=None && (VSize(Controller.Target.Location-Location)<250 || (Normal(Controller.Target.Location - Location) dot vector(Controller.Target.Rotation) > 0.0)))
		Sleep(0.5+FRand());
	GoToState('');
}

State SawingLoop
{
	function RangedAttack(Actor A)
	{
		if ( bShotAnim )
			return;
		else if ( CanAttack(A) )
		{
			Acceleration = vect(0,0,0);
			bShotAnim = true;
			damageRand = default.damageRand*0.6;
			damageConst = default.damageConst*0.6;
			CurrentDamType = ZombieDamType[0];
			SetAnimAction('SawImpaleLoop');
		}
		else GoToState('');
	}
	function AnimEnd( int Channel )
	{
		Super.AnimEnd(Channel);
		if( Controller!=None && Controller.Enemy!=None )
			RangedAttack(Controller.Enemy); // Keep on attacking if possible.
	}
	function EndState()
	{
		damageRand= default.damageRand;
		damageConst= default.damageConst;
	}
}

function PlayTakeHit(vector HitLocation, int Damage, class<DamageType> DamageType)
{
	local int StunChance;

	StunChance = rand(5);

	if( Level.TimeSeconds - LastPainAnim < MinTimeBetweenPainAnims )
		return;

	if( Damage>=150 || (DamageType.name=='DamTypeStunNade' && StunChance>3) || (DamageType.name=='DamTypeCrossbowHeadshot' && Damage>=200) )
		PlayDirectionalHit(HitLocation);

	LastPainAnim = Level.TimeSeconds;

	if( Level.TimeSeconds - LastPainSound < MinTimeBetweenPainSounds )
		return;

	LastPainSound = Level.TimeSeconds;
	PlaySound(HitSound[Rand(4)], SLOT_Pain,2*TransientSoundVolume,,400);
}

simulated function int DoAnimAction( name AnimName )
{
	if( AnimName=='SawZombieAttack1' || AnimName=='SawZombieAttack2' || AnimName=='SawImpaleLoop' )
	{
		AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
		PlayAnim(AnimName,, 0.0, 1);
		Return 1;
	}
	Return Super.DoAnimAction(AnimName);
}

defaultproperties
{
     MeleeAnims(0)="SawZombieAttack1"
     MeleeAnims(1)="SawZombieAttack2"
     MoanVoice(0)=Sound'KFPlayerSound.ScrakeGiggle'
     MoanVoice(1)=Sound'KFPlayerSound.ScrakeVoice2'
     MoanVoice(2)=Sound'KFPlayerSound.ScrakeVoice8'
     bCannibal=True
     damageRand=11
     damageConst=14
     damageForce=-400000
     bFatAss=True
     KFRagdollName="SawZombieRag"
     bMeleeStunImmune=True
     Intelligence=BRAINS_Mammal
     bUseExtendedCollision=True
     ColOffset=(Z=39.000000)
     ColRadius=29.000000
     ColHeight=40.000000
     HitSound(0)=Sound'KFPlayerSound.zpain1'
     HitSound(1)=Sound'KFPlayerSound.zpain2'
     HitSound(2)=Sound'KFPlayerSound.zpain3'
     HitSound(3)=Sound'KFPlayerSound.zpain4'
     ChallengeSound(0)=Sound'KFPlayerSound.ScrakeVoice7'
     ChallengeSound(1)=Sound'KFPlayerSound.ScrakeVoice4'
     ChallengeSound(2)=Sound'KFPlayerSound.ScrakeVoice7'
     ScoringValue=5
     IdleHeavyAnim="SawZombieIdle"
     IdleRifleAnim="SawZombieIdle"
     MeleeRange=60.000000
     GroundSpeed=85.000000
     WaterSpeed=75.000000
     HealthMax=1000.000000
     Health=1000
	 HeadHealth=700.000000
     MenuName="Scrake"
     ControllerClass=Class'KFChar.SawZombieController'
     MovementAnims(0)="SawZombieWalk"
     MovementAnims(1)="SawZombieWalk"
     MovementAnims(2)="SawZombieWalk"
     MovementAnims(3)="SawZombieWalk"
     WalkAnims(0)="SawZombieWalk"
     WalkAnims(1)="SawZombieWalk"
     WalkAnims(2)="SawZombieWalk"
     WalkAnims(3)="SawZombieWalk"
     IdleCrouchAnim="SawZombieIdle"
     IdleWeaponAnim="SawZombieIdle"
     IdleRestAnim="SawZombieIdle"
     AmbientSound=Sound'KFWeaponSound.SawIdle'
     Mesh=SkeletalMesh'KFCharacterModels.SawZombie'
     PrePivot=(Z=8.000000)
     Skins(0)=Shader'KFCharacters.Zombie6Shader'
     Skins(1)=Texture'KillingFloorWeapons.Chainsaw.ChainSawSkin3PZombie'
     Skins(2)=TexOscillator'KillingFloorWeapons.Chainsaw.SAWCHAIN'
     Skins(3)=Texture'KFCharacters.ScrakeFrock'
     SoundRadius=200.000000
     Mass=500.000000
     RotationRate=(Yaw=45000,Roll=0)
}
