// Zombie Monster for KF Invasion gametype

class ZombieFleshpound extends KFMonster;

#exec OBJ LOAD FILE=KFCharacters.utx
#exec OBJ LOAD FILE=KFCharacterModels.ukx
#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax

var () float BlockDamageReduction;
var bool bChargingPlayer,bClientCharge;
var int TwoSecondDamageTotal;
var float LastDamagedTime,RageStartTime;

var() vector RotMag;						// how far to rot view
var() vector RotRate;					 // how fast to rot view
var() float	RotTime;					 // how much time to rot the instigator's view
var() vector OffsetMag;				 // max view offset vertically
var() vector OffsetRate;				// how fast to offset view vertically
var() float	OffsetTime;				// how much time to offset view

var name ChargingAnim;		// How he runs when charging the player.

//var ONSHeadlightCorona DeviceGlow;

var () int RageDamageThreshold;  // configurable.

var bool bFrustrated;

replication
{
	reliable if(Role == ROLE_Authority)
		bChargingPlayer;
}

simulated Function PostNetBeginPlay()
{
	EnableChannelNotify ( 1,1);
	AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
	super.PostNetBeginPlay();
}

// Important Block of code controlling how the Zombies (excluding the Bloat and Fleshpound who cannot be stunned, respond to damage from the
// various weapons in the game. The basic rule is that any damage amount equal to or greater than 40 points will cause a stun.
// There are exceptions with the fists however, which are substantially under the damage quota but can still cause stuns 50% of the time.
// Why? Cus if they didn't at least have that functionality, they would be fundamentally useless. And anyone willing to take on a hoarde of zombies
// with only the gloves on his hands, deserves more respect than that!
function PlayTakeHit(vector HitLocation, int Damage, class<DamageType> DamageType)
{
	if( Level.TimeSeconds - LastPainAnim < MinTimeBetweenPainAnims )
		return;

	if( Damage>=150 || (DamageType.name=='DamTypeStunNade' && rand(5)>3) || (DamageType.name=='DamTypeCrossbowHeadshot' && Damage>=200) )
		PlayDirectionalHit(HitLocation);

	LastPainAnim = Level.TimeSeconds;

	if( Level.TimeSeconds - LastPainSound < MinTimeBetweenPainSounds )
		return;

	LastPainSound = Level.TimeSeconds;
	PlaySound(HitSound[Rand(4)], SLOT_Pain,2*TransientSoundVolume,,400);
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
	local int OldHealth;

	//GetAxes(Rotation, X,Y,Z);

	if( LastDamagedTime<Level.TimeSeconds )
		TwoSecondDamageTotal = 0;
	LastDamagedTime = Level.TimeSeconds+2;
	OldHealth = Health;
	
	// He's impervious to small arms fire (non explosives)
	// Frags and LAW rockets will bring him down way faster than bullets and shells.
	if (DamageType != class 'DamTypeFrag' && DamageType != class 'DamTypeLAW')
		Damage *= 0.6;
	 
	if (DamageType == class 'DamTypeFrag' || DamageType == class 'DamTypeLAW')
		Damage *= 2.0;

	// Shut off his "Device" when dead
	if (Damage >= Health)
		PostNetReceive();


	if (AnimAction == 'PoundBlock')
		Damage *= BlockDamageReduction;

	//if (damageType == class 'DamTypeVomit')
	//	Damage = 0; // nulled

	if((Health - Damage) > 0)
		Momentum = vect(0,0,0) ;
	Super.takeDamage(Damage, instigatedBy, hitLocation, momentum, damageType);

	TwoSecondDamageTotal += OldHealth - Health; // Corrected issue where only the Base Health is counted toward the FP's Rage

	if (TwoSecondDamageTotal > RageDamageThreshold && !bChargingPlayer || bFrustrated)
		StartCharging();
}

// changes colors on Device (notified in anim)
simulated function DeviceGoRed()
{
	Skins[2]=FinalBlend'KFCharacters.RedPoundMeter';
	Skins[3]=Shader'KFCharacters.FPRedBloomShader';
}
simulated function DeviceGoNormal()
{
	Skins[2] = FinalBlend'KFCharacters.YellowPoundMeter';
	Skins[3] = Shader'KFCharacters.FPAmberBloomShader';
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

function BlockDamage()
{
	if (bShotAnim || Physics == PHYS_Swimming)
		return;
	else
	{
		//Level.Game.Broadcast(self, 'FleshPoundBlock');
		bShotAnim = true;
		SetAnimAction('PoundBlock');
		return;
	}
}

// Sets the FP in a berserk charge state until he either strikes his target, or hits timeout
function StartCharging()
{
    if( Health <= 0 )
    {
        return;
    }
	SetAnimAction('PoundRage');
	Acceleration = vect(0,0,0);
	bShotAnim = true;
	Velocity.X = 0;
	Velocity.Y = 0;
	Controller.GoToState('WaitForAnim');
	KFMonsterController(Controller).bUseFreezeHack = True;
    FleshpoundZombieController(Controller).SetPoundRageTimout(1.5);
	GoToState('BeginRaging');
}

state BeginRaging
{
    Ignores StartCharging;

	function Tick( float Delta )
	{
        Acceleration = vect(0,0,0);

        global.Tick(Delta);
	}

Begin:
    Sleep(1.5);
    GotoState('RageCharging');
}

State RageCharging
{
Ignores StartCharging;

	function BeginState()
	{
		local float DifficultyModifier;

		bChargingPlayer = true;
		if( Level.NetMode!=NM_DedicatedServer )
			ClientChargingAnims();

		// Scale rage length by difficulty
		if( Level.Game.GameDifficulty < 2.0 )
		{
			DifficultyModifier = 0.85;
		}
		else if( Level.Game.GameDifficulty < 4.0 )
		{
			DifficultyModifier = 1.0;
		}
		else if( Level.Game.GameDifficulty < 5.0 )
		{
			DifficultyModifier = 1.25;
		}
		else // Hardest difficulty
		{
			DifficultyModifier = 3.0; 
		}
		RageStartTime = (Level.TimeSeconds + 5 * DifficultyModifier) + (FRand() * 6 * DifficultyModifier);
		NetUpdateTime = Level.TimeSeconds - 1;
	}
	function EndState()
	{
		bChargingPlayer = False;
		bFrustrated = false;
		FleshPoundZombieController(Controller).RageFrustrationTimer = 0;
		if( Health>0 )
		{
			SetGroundSpeed(OriginalGroundSpeed);
			if( Level.NetMode!=NM_DedicatedServer )
				ClientChargingAnims();
			NetUpdateTime = Level.TimeSeconds - 1;
		}
	}
	function Tick( float Delta )
	{
		if( !bShotAnim )
		{
			SetGroundSpeed(OriginalGroundSpeed * 2.1);//2.0;
			if( !bFrustrated && Level.TimeSeconds>RageStartTime )
				GoToState('');
		}
	}
	function Bump( Actor Other )
	{
		if( !bShotAnim && Pawn(Other)!=None && ZombieFleshPound(Other)==None && Pawn(Other).Health>0 )
		{
			Controller.Target = Other;
			Controller.Focus = Other;
			Acceleration = vect(0,0,0);
			bShotAnim = true;
			SetAnimAction('Claw');
			PlaySound(sound'Claw2s', SLOT_None);
		}
		else Global.Bump(Other);
	}
	// If fleshie hits his target on a charge, then he should settle down for abit.
	function bool MeleeDamageTarget(int hitdamage, vector pushdir)
	{
		local bool RetVal,bWasEnemy;

		bWasEnemy = (Controller.Target==Controller.Enemy);
		RetVal = Super.MeleeDamageTarget(hitdamage*1.75, pushdir*3);
		if( RetVal && bWasEnemy )
			GoToState('');
		return RetVal;
	}
}

simulated function PostNetReceive()
{
	if( bClientCharge!=bChargingPlayer )
	{
		bClientCharge = bChargingPlayer;
		if( Health<=0 )
			Return;
		if (bChargingPlayer)
		{
			MovementAnims[0]=ChargingAnim;
			MeleeAnims[0]='FPRageAttack';
			MeleeAnims[1]='FPRageAttack';
			MeleeAnims[2]='FPRageAttack';
			DeviceGoRed();
		}
		else
		{
			MovementAnims[0]=default.MovementAnims[0];
			MeleeAnims[0]=default.MeleeAnims[0];
			MeleeAnims[1]=default.MeleeAnims[1];
			MeleeAnims[2]=default.MeleeAnims[2];
			DeviceGoNormal();
		}
	}
}
simulated function PlayDyingAnimation(class<DamageType> DamageType, vector HitLoc)
{
	Super.PlayDyingAnimation(DamageType,HitLoc);
	if( Level.NetMode!=NM_DedicatedServer )
		DeviceGoNormal();
}
simulated function ClientChargingAnims()
{
	PostNetReceive();
}

function ClawDamageTarget()
{
	local vector PushDir;
	local KFHumanPawn HumanTarget;
	local KFPlayerController HumanTargetController;

	if(Controller!=none && Controller.Target!=none)
	{
		//calculate based on relative positions
		PushDir = (damageForce * Normal(Controller.Target.Location - Location));
	}
	else
	{
		//calculate based on way Monster is facing
		PushDir = damageForce * vector(Rotation);
	}
	if ( MeleeDamageTarget( (damageConst + rand(damageRand) ), PushDir))
	{
		HumanTarget = KFHumanPawn(Controller.Target);
		if( HumanTarget!=None )
			HumanTargetController = KFPlayerController(HumanTarget.Controller);
		if( HumanTargetController!=None )
			HumanTargetController.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);
		PlayZombieAttackHitSound();
	}
}


function SpinDamage(actor Target)
{
	local vector HitLocation;
	local Name TearBone;
	local Float dummy;
	local float DamageAmount;
	local vector PushDir;
	local KFHumanPawn HumanTarget;

	if(target==none)
		return;

	PushDir = (damageForce * Normal(Target.Location - Location));
	damageamount = (SpinDamConst + rand(SpinDamRand) );

	// FLING DEM DEAD BODIEZ!
	if (Target.IsA('KFHumanPawn') && Pawn(Target).Health <= DamageAmount)
	{
		KFHumanPawn(Target).RagDeathVel *= 3;
		KFHumanPawn(Target).RagDeathUpKick *= 1.5;
	}

	if (Target !=none && Target.IsA('KFDoorMover'))
	{
		Target.TakeDamage(DamageAmount , self ,HitLocation,pushdir, class 'KFMod.ZombieMeleeDamage');
		PlayZombieAttackHitSound();
	}

	if (KFHumanPawn(Target)!=none)
	{
		HumanTarget = KFHumanPawn(Target);
		if (HumanTarget.Controller != none) 
			HumanTarget.Controller.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

		//TODO - line below was KFPawn. Does this whole block need to be KFPawn, or is it OK as KFHumanPawn?
		KFHumanPawn(Target).TakeDamage(DamageAmount, self ,HitLocation,pushdir, class 'KFMod.ZombieMeleeDamage');

		if (KFHumanPawn(Target).Health <=0)
		{
			KFHumanPawn(Target).SpawnGibs(rotator(pushdir), 1);
			TearBone=KFPawn(Target).GetClosestBone(HitLocation,Velocity,dummy);
			KFHumanPawn(Controller.Target).HideBone(TearBone);
			//HideBone(TearBone);
		}
	}
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
		else if ( AnimAction == 'PoundRage' )
		{
			PlayAnim(NewAction);
		}
		else if ( AnimAction == 'PoundAttack1' )
		{
			AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'PoundAttack2' )
		{
			AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'FPRageAttack' )
		{
			AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if(AnimAction == 'Claw')
		{
			AnimAction=meleeAnims[Rand(3)];
			SetAnimAction(AnimAction);
			return;
		}
		if( AnimAction=='PoundAttack3' && Controller!=None )
			Controller.GotoState('spinattack');
		else if(NewAction == 'ZombieFeed')
		{
			AnimAction = NewAction;
			LoopAnim(AnimAction,,0.1);
		}
		else AnimAction = NewAction;

		CurrentDamtype = ZombieDamType[Rand(3)];

		if ( PlayAnim(AnimAction,,0.1) && AnimAction != KFHitFront 
			&& AnimAction != KFHitBack
			&& AnimAction != KFHitLeft
			&& AnimAction != KFHitRight
			&& AnimAction != 'PoundAttack1'
			&& AnimAction != 'PoundAttack2' 
			&& AnimAction != 'FPRageAttack' ) 
		{
			if ( Physics != PHYS_None )
				bWaitForAnim = true;
		}
	}
}
simulated function int DoAnimAction( name AnimName )
{
	if( AnimName=='PoundAttack1' || AnimName=='PoundAttack2' || AnimName=='FPRageAttack' || AnimName=='ZombieFireGun' )
	{
		AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
		PlayAnim(AnimName,, 0.0, 1);
		Return 1;
	}
	Return Super.DoAnimAction(AnimName);
}
function bool FlipOver()
{
	Return False;
}
function bool SameSpeciesAs(Pawn P)
{
	return (ZombieFleshPound(P)!=None);
}

defaultproperties
{
     RunAnim=""
     BlockDamageReduction=0.400000
     RotMag=(X=400.000000,Y=400.000000)
     RotRate=(X=400.000000,Y=400.000000,Z=400.000000)
     RotTime=2.500000
     OffsetMag=(X=35.000000,Y=35.000000,Z=35.000000)
     OffsetRate=(X=300.000000,Y=300.000000,Z=300.000000)
     OffsetTime=3.500000
     ChargingAnim="PoundRun"
     RageDamageThreshold=360
     MeleeAnims(0)="PoundAttack1"
     MeleeAnims(1)="PoundAttack2"
     MeleeAnims(2)="PoundAttack3"
     MoanVoice(0)=Sound'KFPlayerSound.Flesh1'
     MoanVoice(1)=Sound'KFPlayerSound.Flesh2'
     MoanVoice(2)=Sound'KFPlayerSound.Flesh3'
     MoanVoice(3)=Sound'KFPlayerSound.Flesh4'
     damageRand=15
     damageConst=25
     damageForce=15000
     bFatAss=True
     KFRagdollName="FleshPoundRag"
     SpinDamConst=20.000000
     SpinDamRand=20.000000
     bMeleeStunImmune=True
     Intelligence=BRAINS_Mammal
     bUseExtendedCollision=True
     ColOffset=(Z=42.000000)
     ColRadius=36.000000
     ColHeight=46.000000
     bBoss=True
     HitSound(0)=Sound'KFPlayerSound.zpain1'
     HitSound(1)=Sound'KFPlayerSound.zpain2'
     HitSound(2)=Sound'KFPlayerSound.zpain3'
     HitSound(3)=Sound'KFPlayerSound.zpain4'
     ScoringValue=10
     IdleHeavyAnim="PoundIdle"
     IdleRifleAnim="PoundIdle"
     RagDeathVel=100.000000
     RagDeathUpKick=100.000000
     MeleeRange=55.000000
     GroundSpeed=130.000000
     WaterSpeed=120.000000
     HealthMax=1500.000000
     Health=1500
	 HeadHealth=800
     MenuName="Flesh Pound"
     ControllerClass=Class'KFChar.FleshpoundZombieController'
     MovementAnims(0)="PoundWalk"
     MovementAnims(1)="PoundWalk"
     MovementAnims(2)="PoundWalk"
     MovementAnims(3)="PoundWalk"
     WalkAnims(0)="PoundWalk"
     WalkAnims(1)="PoundWalk"
     WalkAnims(2)="PoundWalk"
     WalkAnims(3)="PoundWalk"
     IdleCrouchAnim="PoundIdle"
     IdleWeaponAnim="PoundIdle"
     IdleRestAnim="PoundIdle"
     AmbientSound=Sound'KFPlayerSound.Zombiesbreath'
     Mesh=SkeletalMesh'KFCharacterModels.ZombieBoss'
     PrePivot=(Z=8.000000)
     Skins(0)=Texture'KFCharacters.PoundSkin'
     Skins(1)=Shader'KFCharacters.PoundBitsShader'
     Skins(2)=FinalBlend'KFCharacters.YellowPoundMeter'
     Skins(3)=Shader'KFCharacters.FPAmberBloomShader'
     Mass=600.000000
     RotationRate=(Yaw=45000,Roll=0)
}
