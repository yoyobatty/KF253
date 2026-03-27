// Chainsaw Zombie Monster for KF Invasion gametype
// He's not quite as speedy as the other Zombies, But his attacks are TRULY damaging.

class ZombieScrake extends KFMonster ;

var bool bSawImpaling;  // Is he stickin' ya like a pig?

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
		SetAnimAction('Claw');
		PlaySound(sound'Claw2s', SLOT_None);
		return;
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

simulated event SetAnimAction(name NewAction)
{
	if (!bWaitForAnim)
	{
		AnimAction = NewAction;
		if ( AnimAction == KFHitFront )
		{
			AnimBlendParams(1, 1.0, 0.0,,'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == KFHitBack )
		{
			AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == KFHitRight )
		{
			AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == KFHitLeft )
		{
			AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
		}		
		else if ( AnimAction == 'SawZombieAttack1' )
		{
			if (bSawImpaling)
			{
				AnimAction = ('SawImpaleLoop');
				SetAnimAction(AnimAction);
			}
			AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'SawZombieAttack2' )
		{
			if (bSawImpaling)
			{
				AnimAction = ('SawImpaleLoop');
				SetAnimAction(AnimAction);
			}
			AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'SawImpaleLoop' )
		{
			AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
			DamageForce *= 2;
			damageRand *= 0.75;
			damageConst *= 0.75;
			Velocity = Vect(0,0,0);
			bSawImpaling = true;
		}
		else if(AnimAction == 'Claw')
		{
			AnimAction=meleeAnims[Rand(3)];
			SetAnimAction(AnimAction);
			return;
		}
		if(NewAction == 'ZombieFeed')
		{
			AnimAction = NewAction;
			LoopAnim(AnimAction,,0.1);
		}
		else AnimAction = NewAction;

		if ( PlayAnim(AnimAction,,0.1) && AnimAction != KFHitFront 
			&& AnimAction != KFHitBack
			&& AnimAction != KFHitLeft
			&& AnimAction != KFHitRight
			&& AnimAction != 'SawZombieAttack1'
			&& AnimAction != 'SawZombieAttack2' ) 
		{
			if ( Physics != PHYS_None )
				bWaitForAnim = true;
		}
	}
}
function StopImpaling()
{
	bSawImpaling = false;
	DamageForce = default.DamageForce;
	damageRand= default.damageRand;
	damageConst= default.damageConst;
}

state ZombieCharge
{
	function bool StrafeFromDamage(float Damage, class<DamageType> DamageType, bool bFindDest)
	{
		return false;
	}

	function Timer()
	{
		disable('NotifyBump');
	}

	// I suspect this function causes bloats to get confused
	function bool TryStrafe(vector sideDir)
	{
		return false;
	}
}

defaultproperties
{
     MeleeAnims(0)="SawZombieAttack1"
     MeleeAnims(1)="SawZombieAttack2"
     MeleeAnims(2)="SawImpaleLoop"
     MoanVoice(0)=Sound'KFPlayerSound.ScrakeGiggle'
     MoanVoice(1)=Sound'KFPlayerSound.ScrakeVoice2'
     MoanVoice(2)=Sound'KFPlayerSound.ScrakeVoice8'
     bDurableHead=True
     bCannibal=True
     damageRand=11
     damageConst=14
     damageForce=-400000
     bFatAss=True
     KFRagdollName="SawZombieRag"
     bMeleeStunImmune=True
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
     HealthMax=1500.000000
     Health=1500
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
     Skins(0)=Shader'KFCharacters.Zombie6Shader'
     Skins(1)=Texture'KillingFloorWeapons.Chainsaw.ChainSawSkin3PZombie'
     Skins(2)=TexOscillator'KillingFloorWeapons.Chainsaw.SAWCHAIN'
     Skins(3)=Texture'KFCharacters.ScrakeFrock'
     SoundRadius=200.000000
     CollisionRadius=30.000000
     CollisionHeight=58.000000
     Mass=500.000000
     RotationRate=(Yaw=45000,Roll=0)
}
