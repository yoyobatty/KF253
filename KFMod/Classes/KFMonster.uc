// Base Zombie Class.
Class KFMonster extends Skaarj
	hidecategories(AnimTweaks,DeRes,Force,Gib,Karma,Udamage,UnrealPawn)
	Abstract;

#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax
//#exec OBJ LOAD FILE=22CharTex.utx

var name MeleeAnims[3];
var name HitAnims[3];

var array<sound> MoanVoice;

var float NextBileTime, BileFrequency;
var int BileCount;
var Pawn BileInstigator;

var name KFHitFront;
var name KFHitBack;
var name KFHitLeft;
var name KFHitRight;

var int HitMomentum;

var class <KFGib> HeadStubClass;	// the cap of raw meat left on a joint that has come apart

var Vector LastBloodHitDirection;
var Bool bRanged;

var() float CrowdShrinkFactor;      // Shrink current radius to this fraction when bumping another zed.
var() float CrowdShrinkMinRadius;   // Never shrink below this, to avoid clipping through geometry.
var() float CrowdShrinkRestoreDelay;// Seconds of no further crowd-bumps before restoring.
var bool bCrowdRadiusShrunk;
var bool bFixedPace;		// its speed is set for it (a holdout's one pace): no sprint of its own on top
var() bool bCrowdRoomCheck;         // Grow back only where no other body is in the way.
var float PreCrowdShrinkRadius;
var float CrowdShrinkEndTime;

var() bool bStunImmune; // is the zombie immune to stun hit effects?
var bool bSTUNNED;
var bool bDecapitated; // has he lost his noggin'!?
var int  Gored; // Has he lost his whole torso?! if so, how much of it?
var bool DECAP;
var bool bBurnified;
var bool bBurnApplied;
var byte HeatAmount;
var()	float	BleedOutDuration;   // How long this zombie survives after losing its head
var		float	BleedOutTime;       // When this zombie will die from bleeding out

var() bool bCannibal;  // If true, this enemy will stop to eat corpses it finds.

var float StunTime, LastPuntTime, DecapTime;
var float LastHeadShotSoundTime;

var Rotator NewTorsoRotation;
//var int MaxTorsoYaw,MaxTorsoPitch,MaxTorsoRoll;  // limits on SetBoneRot for hit reactions.

var(AI) int MaxSpineVariation; // Maximum base amount the bone can bend. Set in defprops.
var(AI) bool bContorts ;  // Does this guy do the LIiiiMBO!!!
var(AI) float MaxContortionPercentage; // def. 0.25

var int damageRand;
var int damageConst;
var int damageForce;
var float LastPainAnim;
var(AI) float MinTimeBetweenPainAnims;
var bool playedHit;
var vector KickLocation, ImpactVector;
var actor KickTarget;
var bool bPlayBrainSplash;		// every machine has been told the head is gone
var bool bPlayGoreSplash;		// blown to pieces: the body is removed instead of falling
var float FeedThreshold; // OBSOLOTE.

var float CorpseStaticTime;   // The level.timeseconds record of when the corpse has stopped moving, and should soon go static.  1 second later, it will.
var bool bCorpsePositionSet;
var float CorpseLifeSpan;  // The time the zombie corpse will be around for.

var(Sounds) Sound ZJumpSound;

var pawn LastDamagedBy;
var class<damagetype> LastDamagedByType;
var int LastDamageAmount;
var vector LastHitLocation,LastMomentum ;
var float TorsoReturnAlpha;

var bool bFatAss; // HACK for pathfinding

var string KFRagdollName;

var class<DamTypeZombieAttack> ZombieDamType[3];
var class<DamTypeZombieAttack> CurrentDamType;

var Sound MiscSound; //

var float SpinDamConst;
var float SpinDamRand;
var() int ScreamDamage;
var() float HeadHealth;
var() bool bMeleeStunImmune; // if true, this monster cannot be stunned or staggered by melee blows

// Fire Related

var int BurnDown ; // Number of times our zombie must suffer Fire Damage.
var bool bAshen; // is our Zed crispy yet? (burnt through, as the server sees it)
var class<Emitter> BurnEffect;  // The appearance of the flames we are attaching to our Zed.
var int LastBurnDamage; // Record the last amount of Fire damage the pawn suffered.
var() float BurnSpeedScale;				// a specimen on fire moves this much slower

// A body chars for as long as it burns: each machine drawing it lets the burnt skin come in over CharTime
// seconds of fire, and one the server calls burnt through (bAshen) always goes all the way.
var float CharLevel;					// how far the burnt skin has come in, 0 to 1
var() float CharTime;
var bool bCharDone;
var Combiner CharSkins[4];				// the blend standing in for each skin on the way
var ConstantColor CharMask;				// how much of the skin is left
var array<Object> CharMade;				// from the level's pool, to be given back

// The dead burn on for CorpseBurnTime seconds where they fall, and then smoke
var() float CorpseBurnTime;
var float CorpseBurnEnd;				// when the fire on the body goes out; 0 for a body that is not burning
var bool bCorpseSmoked;
var Emitter CorpseSmoke;
var() class<Emitter> CorpseSmokeClass;

// Blood by the size of the hit: HeavyHitDamage and over gets the heavy puff. A blow of BurstHitDamage,
// or a power weapon that has done BurstBlastDamage in one blast, bursts out of the far side as well.
var() class<Actor> HeavyBloodClass, BurstBloodClass;
var() int HeavyHitDamage, BurstHitDamage;
var() float BurstBlastDamage;
var float LastBurstTime;

// One that has lost its head pumps blood from the neck and leaves a trail until it drops
var xEmitter NeckJet;
var() class<xEmitter> NeckJetClass;
var() class<Actor> DripDecalClass;
var() int MaxDrips;
var() float DripSpacing;
var int DripsLeft;
var vector LastDripSpot;
var float LastDripTime;


var Effect_ShadowController RealtimeShadow;
var(Pawn) bool bRealtimeShadows; // Advanced Shadows care of Squirrelzero's code.

var(Pawn) Name PuntAnim; // The animation to play when a zombie punts a karma object


// Add an animation name here, to have it randomize with the monster's default movement animations.
var Array<Name>AdditionalWalkAnims;
var Name SpawningWalkAnim;  // the anim we're confirmed to spawn with.

var float BloodStreakInterval;
var transient float LastStreakTime;


var class <KFGib> MonsterHeadGiblet;
var class <KFGib> MonsterThighGiblet;
var class <KFGib> MonsterArmGiblet;
var class <KFGib> MonsterLegGiblet;
var class <KFGib> MonsterTorsoGiblet;
var class <KFGib> MonsterLowerTorsoGiblet;

// Better Gore

var(Pawn) Material GoredMat;  // Swap this in when he's blown in half.

// A body comes apart at ten joints (SeverSlot lists them). Only the server knows what a hit did;
// what has come off is kept by each machine drawing the specimen.
var byte Severed[10];
var KFGib Stumps[10];					// the stump on each joint
var float StumpSize[10];				// its size against the neck's
var name LimbJoints[8], LimbEnds[8];	// the eight limb bones: the joint each comes off at, and its far end
var() float GibScale;					// giblets and stumps against a Clot's

// A power weapon (shotgun, explosive) is judged by its whole blast: the damage it did within
// BlastWindow seconds, as a multiple of the specimen's starting health. A kill worth LimbBlast takes
// a limb at the shoulder or hip, TorsoBlast the upper body, and BodyBlast (explosions only) leaves
// nothing but pieces.
var() float LimbBlast, TorsoBlast, BodyBlast, BlastWindow;
var float BlastDamage, BlastTime, BlastKillTime;
var bool bDeathGoreDone;				// the killing blow has had its say
var() int CorpseGibHealth;				// a body knocked down to this health can be blown to pieces

var bool bDiffAdjusted; // has this monster had it's stats adjusted for the server's difficulty? Do once.

var bool bCloaked;
var bool bSpotted; // if true , use the "revealed" shader, instead of the cloak effect
var Emitter FlamingFXs;

var Pawn BurnInstigator;

var(AI) enum EIntelligence
{
	BRAINS_Retarded, // Dumbasses
	BRAINS_Stupid, // Just plain stupid.
	BRAINS_Mammal,
	BRAINS_Human // Smarties
} Intelligence;
var(AI) bool bCanDistanceAttackDoors;

var() bool bStartUpDisabled,bNoAutoHuntEnemies;
var() int HealthModifer;
var() name FirstSeePlayerEvent;

var int ExpectingChannel;
var bool bResetAnimAct;
var float ResetAnimActTime;

var bool bUseExtendedCollision;
var vector ColOffset;
var float ColRadius,ColHeight;
var ExtendedZCollision MyExtCollision;
var bool SavedExtCollision;          // Saved original state of the external collision
var ExtendedZCollision MyHeadCollision; // Hit zone that rides the head bone

var float LastViewCheckTime;      // internal use, used to see how long its been since we checked if there was line of site between this Zed and the local player controller
var float OriginalGroundSpeed;// The difficulty adjusted ground speed (need to store this off, because we have to restore this value at certain times)
var() float HiddenGroundSpeed;      // How fast this Zed should move when it's out of view;

var() Name RunAnim;                 // Animation to use when moving fast. Set to '' to disable speed-based run anim.
var() float RunAnimSpeedThreshold;  // GroundSpeed above which RunAnim is used instead of walk anim.
var Name SavedWalkAnim;             // The walk anim chosen at spawn (stored after randomization).
var bool bUsingRunAnim;             // Currently showing the run animation.

var bool bDestroyNextTick; // Destroy this pawn next tick because destroying it now will cause problems
var float TimeSetDestroyNextTickTime; // The time we set the bDestroyNextTick flag

var bool bSettledBody;					// a body at rest, out of Karma's world contacts and gravity until something hits it
var int SettleChecks;					// body timer checks in a row it has been slower than SettleSpeed
var float SettleSpeed;					// a body this slow at SettleChecksNeeded checks a second apart settles (0: never)
var int SettleChecksNeeded;
var float SettledLinDamp, SettledAngDamp;	// its damping before it settled

var() Sound DecapSound;

var float NextVisCheckTime;

replication
{
	reliable if(Role == ROLE_Authority)
		bDecapitated,Gored,bBurnified,bAshen,FeedThreshold,bCannibal,bDiffAdjusted,bCloaked;
}

function bool MakeGrandEntry()
{
	Return False;
}
simulated function Setup(xUtil.PlayerRecord rec, optional bool bLoadNow);

simulated function bool Cloaked()
{ 
	return bCloaked;
}
simulated Function PostNetBeginPlay()
{
	EnableChannelNotify ( 1,1);
	AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
	AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Head');
	super(pawn).PostNetBeginPlay();
}

// move karma objects by a kick
// The Kick animation will ONLY be called if the Zombie is On level ground with the KActor,
// and is facing it.
event Bump(actor Other)
{
	local Vector X,Y,Z;
	local KFMonster KFMonst;

	KFMonst = KFMonster(Other);
	if( Role == ROLE_Authority && KFMonster(Other)!=None )
		ShrinkForCrowding();
	GetAxes(Rotation, X,Y,Z);
	super.Bump(Other);
	if( Other==none )
		return;

	if( Other.IsA('NetKActor') && Physics != PHYS_Falling && Location.Z < Other.Location.Z + CollisionHeight
	 && Location.Z > Other.Location.Z - (CollisionHeight * 0.5) && Base!=Other && Base.bStatic
	 && normal(X) dot normal(Other.Location - Location) >= 0.7)
	{
		if( KActor(Other).KGetMass()>=0.5 && !MonsterController(Controller).CanAttack(Controller.Enemy) )
		{
			// Store kick impact data

			ImpactVector = Vector(controller.Rotation)*15000 + (velocity * (Mass / 2) )  ;   // 30
			KickLocation = Other.Location;
			KickTarget = Other;
			KFMonsterController(Controller).KickTarget = KActor(Other);
			SetAnimAction(PuntAnim);
		}
	}
	if( KFMonst!=None && Pawn(Other).Health>0 )
	{
		if(bBurnified && !KFMonst.bBurnified)
		{
			// (in the name of whoever lit this one: in its own name the other burned uncredited and turned on it)
			Other.TakeDamage(15, BurnInstigator, Other.Location,Vect(0,0,0), class'Burned');
			//log("Enemy caught fire" $self);
		}
	}
        
}

// No more File cabinet surfing zombies please..
singular event BaseChange()
{
	if ( KActor(Base)!=None || Pawn(Base)!=None )
		JumpOffPawn();
}

function JumpOffPawn()
{
	Velocity += (50 + CollisionRadius) * VRand();
	Velocity.Z = 80 + CollisionHeight;
	SetPhysics(PHYS_Falling);
	bNoJumpAdjust = true;
	if ( Controller != None )
		Controller.SetFall();
}

// Actually execute the kick (this is notified in the ZombieKick animation)
function KickActor()
{
	KickTarget.Velocity.Z += (Mass * 5 + (KGetMass() * 10));
	KickTarget.KAddImpulse(ImpactVector, KickLocation);
	Acceleration = vect(0,0,0);
	Velocity = vect(0,0,0);
	KFMonsterController(controller).GotoState('Kicking');
	bShotAnim = true;
}

simulated function PostBeginPlay()
{
	local vector AttachPos;
	local float ScalingFactor;
	local float Difficulty;

	if(ROLE==ROLE_Authority)
	{
		if ( (ControllerClass != None) && (Controller == None) )
			Controller = spawn(ControllerClass);
		
		if ( Controller != None )
			Controller.Possess(self);

		if (Controller != none)
        	MyAmmo = spawn(AmmunitionClass);

		SplashTime = 0;
		SpawnTime = Level.TimeSeconds;
		EyeHeight = BaseEyeHeight;
		OldRotYaw = Rotation.Yaw;
		if( HealthModifer!=0 )
			Health = HealthModifer;

		if ( bUseExtendedCollision && MyExtCollision == none )
		{
			MyExtCollision = Spawn(class 'ExtendedZCollision',self);
			MyExtCollision.SetCollisionSize(ColRadius,ColHeight);

			MyExtCollision.bHardAttach = true;
			AttachPos = Location + (ColOffset >> Rotation);
			MyExtCollision.SetLocation( AttachPos );
			MyExtCollision.SetPhysics( PHYS_None );
			MyExtCollision.SetBase( self );
			SavedExtCollision = MyExtCollision.bCollideActors;
		}

		// The head leans out of the body cylinder, so it gets a hit zone of its own that rides the head bone
		if ( HeadBone != '' && MyHeadCollision == none )
		{
			MyHeadCollision = Spawn(class 'ExtendedZCollision',self);
			MyHeadCollision.SetCollisionSize(HeadRadius * HeadScale, HeadRadius * HeadScale);
			if ( AttachToBone(MyHeadCollision, HeadBone) )
			{
				MyHeadCollision.SetRelativeLocation(vect(1,0,0) * (HeadHeight * HeadScale));
				bForceSkelUpdate = true;      // keeps it on the bone when nobody is looking
			}
			else
			{
				MyHeadCollision.Destroy();
				MyHeadCollision = none;
			}
		}
	}

	AssignInitialPose();
	// Let's randomly alter the position of our zombies' spines, to give their animations
	// the appearance of being somewhat unique.
	SetTimer(1.0, false);

	//Set Karma Ragdoll skeleton for this character.
	if (KFRagdollName != "")
		RagdollOverride = KFRagdollName; //ClotKarma
	//Log("Ragdoll Skeleton name is :"$RagdollOverride);

	if (bActorShadows && bPlayerShadows && (Level.NetMode != NM_DedicatedServer))
	{
		// decide which type of shadow to spawn
		if (!bRealtimeShadows)
		{
			PlayerShadow = Spawn(class'ShadowProjector',Self,'',Location);
			PlayerShadow.ShadowActor = self;
			PlayerShadow.bBlobShadow = bBlobShadow;
			PlayerShadow.LightDirection = Normal(vect(1,1,3));
			PlayerShadow.LightDistance = 320;
			PlayerShadow.MaxTraceDistance = 350;
			PlayerShadow.InitShadow();
		}
		else
		{
			RealtimeShadow = Spawn(class'Effect_ShadowController',self,'',Location);
			RealtimeShadow.Instigator = self;
			RealtimeShadow.Initialize();
		}
	}

	bSTUNNED = false;
	DECAP = false;

	// Difficulty Scaling
	if (Level.Game != none && !bDiffAdjusted)
	{
		Difficulty = DeathMatch(Level.Game).AdjustedDifficulty;

		// Some randomization to their walk speeds.
		GroundSpeed = default.GroundSpeed - (0.5*default.Groundspeed) + (rand(default.groundspeed*0.5) + (0.25 * default.groundspeed));
		if (Difficulty <= 3)
		{
			ScalingFactor = 0.75 + (Difficulty - 1) * 0.125;
		}
		else
		{
			ScalingFactor = 1.0 + (Difficulty - 3) * 0.3;
		}
		GroundSpeed += (Difficulty * 3);
		AirSpeed += (Difficulty * 3);
		WaterSpeed += (Difficulty * 3);
		Health *= ScalingFactor;
		Health *= NumPlayersHealthModifer();
		HealthMax *= ScalingFactor;
		HealthMax *= NumPlayersHealthModifer();
		HeadHealth *= ScalingFactor * NumPlayersHealthModifer();
		damageConst *= ScalingFactor;
		if( Level.Game.NumPlayers == 1 ) damageConst *= 0.75;
		damageRand *= ScalingFactor;
		if ( Level.Game.NumPlayers == 1 ) damageRand *= 0.75;
		SpinDamConst *= ScalingFactor;
		if ( Level.Game.NumPlayers == 1 ) SpinDamConst *= 0.75;
		SpinDamRand *= ScalingFactor;
		if ( Level.Game.NumPlayers == 1 ) SpinDamRand *= 0.75;
		ScreamDamage *= ScalingFactor;
		if ( Level.Game.NumPlayers == 1 ) ScreamDamage *= 0.75;
		OriginalGroundSpeed = GroundSpeed;
		if ( Difficulty >= 5.0 ) // Elite and above
		{
			Intelligence = BRAINS_Human;
		}

		bDiffAdjusted = true;
	}
    if( Level.NetMode!=NM_DedicatedServer )
	{
		AdditionalWalkAnims[AdditionalWalkAnims.length] = default.MovementAnims[0];
		MovementAnims[0] = AdditionalWalkAnims[Rand(AdditionalWalkAnims.length)];
		SavedWalkAnim = MovementAnims[0];
	}
	else
		SavedWalkAnim = MovementAnims[0];
}

// Scales the health this Zed has by number of players
function float NumPlayersHealthModifer()
{
	local float AdjustedModifier;
	local float NumEnemies;
	local Controller C;

	AdjustedModifier = 1.0;

	For( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( C.bIsPlayer && C.Pawn!=None && C.Pawn.Health > 0 )
		{
			if(Bot(C)!=None)
			{
				NumEnemies+= 0.5; // Bots count as a half of a player
				continue;
			}
			NumEnemies+=1.0;
		}
	}

	if( NumEnemies > 1.0 )
	{
		AdjustedModifier += (NumEnemies - 1.0) * 0.25; // Each additional player increases health by 25%
	}

	return FMin(AdjustedModifier, 5.0); // Cap it at 5x health for sanity's sake
}

// Accessor for GroundSpeed so we can track what is setting it
simulated function SetGroundSpeed(float NewGroundSpeed)
{
	// one on fire is slowed, whatever speed it is told to take
	if ( bBurnified )
		NewGroundSpeed *= BurnSpeedScale;
    GroundSpeed = NewGroundSpeed;
    UpdateRunAnim();
}

simulated function UpdateRunAnim()
{
    if ( RunAnim == '' )
        return;

    if ( GroundSpeed > RunAnimSpeedThreshold && !bUsingRunAnim )
    {
        if ( HasAnim(RunAnim) )
        {
            MovementAnims[0] = RunAnim;
            bUsingRunAnim = true;
        }
    }
    else if ( GroundSpeed <= RunAnimSpeedThreshold && bUsingRunAnim )
    {
        MovementAnims[0] = SavedWalkAnim;
        bUsingRunAnim = false;
    }
}

// Setters for extra collision cylinders
simulated function ToggleAuxCollision(bool newbCollision)
{
	if ( MyHeadCollision != none )
		MyHeadCollision.SetCollision(newbCollision);
	if ( MyExtCollision == none )
		return;

	if ( !newbCollision )
	{
		SavedExtCollision = MyExtCollision.bCollideActors;

		MyExtCollision.SetCollision(false);
	}
	else
	{
		MyExtCollision.SetCollision(SavedExtCollision);
	}
}

// Return true if we can do the Zombie speed adjust that gets the Zeds
// to the player faster if they can't be seen
function bool CanSpeedAdjust()
{
	if ( !bDecapitated )
	{
		return true;
	}

	return false;
}

simulated function Tick(float DeltaTime)
{
	local Controller C;
	local Pawn PawnCheck;
	local float Dist;
	local bool bSeen;

	// If we've flagged this character to be destroyed next tick, handle that
    if( bDestroyNextTick && TimeSetDestroyNextTickTime < Level.TimeSeconds )
    {
        Destroy();
    }

	if( Role==ROLE_Authority && bCrowdRadiusShrunk && Level.TimeSeconds>=CrowdShrinkEndTime )
	{
		// Back to full width only where there is room for it: one that grew while inside another body could
		// then walk on through it, and specimens ended up standing inside players.
		if( !bCrowdRoomCheck || RoomToGrow() )
		{
			bCrowdRadiusShrunk = false;
			SetCollisionSize(PreCrowdShrinkRadius, CollisionHeight);
		}
		else CrowdShrinkEndTime = Level.TimeSeconds + 0.25 + 0.1 * FRand();
	}

	// Throttled visibility check - only trace every 0.3-0.5s instead of every frame
	if (Level.NetMode != NM_Client && CanSpeedAdjust() && Level.TimeSeconds >= NextVisCheckTime)
	{
		// Stagger next check to spread load across monsters
		NextVisCheckTime = Level.TimeSeconds + 0.1;

		bSeen = false;

		for (C = Level.ControllerList; C != None; C = C.NextController)
		{
			PawnCheck = C.Pawn;
			if (PawnCheck == None || KFHumanPawn(PawnCheck) == None || PawnCheck.Health <= 0)
				continue;

			Dist = VSize(PawnCheck.Location - Location);

			if ((!PawnCheck.Region.Zone.bDistanceFog || (Dist < PawnCheck.Region.Zone.DistanceFogEnd)) &&
				FastTrace(Location + EyePosition(), PawnCheck.Location + PawnCheck.EyePosition()))
			{
				bSeen = true;
				break;
			}
		}

		if (bSeen)
		{
			LastViewCheckTime = Level.TimeSeconds + 1.5;
			SetGroundSpeed(OriginalGroundSpeed);
		}
		else
		{
			if(LastViewCheckTime < Level.TimeSeconds && Level.TimeSeconds - LastRenderTime > 5.0)
				SetGroundSpeed(default.GroundSpeed * (HiddenGroundSpeed / default.GroundSpeed));
		}
	}

	if( bResetAnimAct && ResetAnimActTime<Level.TimeSeconds )
	{
		AnimAction = '';
		bResetAnimAct = True;
	}

	// If the Zed has been bleeding long enough, make it die
	if ( Role == ROLE_Authority && bDecapitated )
	{
		if ( BleedOutTime > 0 && Level.TimeSeconds - BleedOutTime >= 0 )
		{
			// (whoever took the head may have gone since)
			if ( LastDamagedBy != None )
				Died(LastDamagedBy.Controller,class'DamTypeMelee',Location);
			else
				Died(None,class'DamTypeMelee',Location);
			BleedOutTime=0;
		}

	}

	if( Level.NetMode!=NM_DedicatedServer )
	{
		if( NeckJet != None )
			AimNeckJet();

		// a body chars for as long as it burns, watched or not
		if( !bCharDone && (CharLevel > 0.0 || bBurnified || bAshen || CorpseBurnEnd > 0.0) )
			TickChar(DeltaTime);

		// Skip all client visual updates for monsters not rendered recently
		if( Level.TimeSeconds - LastRenderTime < 1.0 )
		{
			TickFX(DeltaTime);

			// the head is gone, however late the news got here
			if ( bDecapitated && Severed[4] == 0 )
				SeverHead(false);

			if( WantsFlames() )
			{
				if ( !bBurnApplied && !bGibbed )
					StartBurnFX();
			}
			else if( bBurnApplied )
				StopBurnFX();

			// the fire on a body has burnt out: it smokes for a while
			if( bPlayedDeath && !bCorpseSmoked && CorpseBurnEnd > 0.0 && Level.TimeSeconds >= CorpseBurnEnd )
			{
				bCorpseSmoked = true;
				if ( !bGibbed && !bHidden )
					SmokeBody();
			}

			if( bBurnApplied && FlamingFXs != None )
				OverBody(FlamingFXs);
			if( CorpseSmoke != None )
				OverBody(CorpseSmoke);

			if( DripsLeft > 0 && bDecapitated && !bPlayedDeath )
				BloodTrail();
		}
		else if( bBurnApplied )
			StopBurnFX(); // Clean up burn FX when going off-screen
	}

	if( DECAP )
	{
		if(Level.TimeSeconds>(DecapTime + 2.0) && Controller!=none)
		{
			DECAP = false;
			MonsterController(Controller).ExecuteWhatToDoNext();
		}
	}
	if( BileCount>0 && NextBileTime<level.TimeSeconds )
	{
		--BileCount;
		NextBileTime+=BileFrequency;
		TakeBileDamage();
	}

	// one of a riot's rows: it keeps its place across the way (after its controller has steered it this tick)
	if( Role==ROLE_Authority && Health>0 && KFMonsterController(Controller)!=None && KFMonsterController(Controller).RiotRow>=0 )
		KFMonsterController(Controller).RiotSteer(DeltaTime);
}

function TakeBileDamage()
{
    if (bDeleteMe || Health <= 0)
        return;

	Super.TakeDamage(2+Rand(3), BileInstigator, Location, vect(0,0,0), class'DamTypeVomit');
}

// Whether there should be fire on this one: the living while alight, the dead until theirs burns out
simulated function bool WantsFlames()
{
	if ( bPlayedDeath )
		return Level.TimeSeconds < CorpseBurnEnd;
	return bBurnified;
}

// A body still has fire or smoke to show (its Tick is not to be stopped)
simulated function bool StillBurning()
{
	return Level.NetMode != NM_DedicatedServer && CorpseBurnEnd > 0.0 && (!bCorpseSmoked || !bCharDone);
}

// A point on the body, wherever it stands or lies: along a limb, up the trunk, or the head
simulated function vector BodySpot()
{
	local int i;
	local vector A, B;

	i = Rand(14);
	if ( i < ArrayCount(LimbJoints) )
	{
		A = GetBoneCoords(LimbJoints[i]).Origin;
		B = GetBoneCoords(LimbEnds[i]).Origin;
	}
	else if ( i < 13 || bDecapitated )
	{
		A = GetBoneCoords('Bip01 Pelvis').Origin;
		B = GetBoneCoords('Bip01 Neck').Origin;
	}
	else return GetBoneCoords(HeadBone).Origin;
	return A + FRand() * (B - A);
}

// What an effect on the body gives off next starts at some point on the body: asked each tick, so that it
// comes off the whole of it. (The engine's own way of spawning from a skeleton, UseSkeletalLocationAs, adds
// joint positions in the model's space, neither turned nor shifted: flames set so hang in the air.)
simulated function OverBody( Emitter E )
{
	local int i;

	for ( i=0; i<E.Emitters.Length; i++ )
		E.Emitters[i].StartLocationOffset = BodySpot() - E.Location;
}

simulated function StartBurnFX()
{
    if( bDeleteMe )
    {
        return;
    }

	if( FlamingFXs==None )
		FlamingFXs = Spawn(BurnEffect);
	if( FlamingFXs!=None )
	{
		FlamingFXs.SetBase(Self);
		OverBody(FlamingFXs);
	}
	bBurnApplied = True;
}

simulated function StopBurnFX()
{
	RemoveFlamingEffects();
	// a flame told to die cannot be lit again: the next fire gets a new one
	if( FlamingFXs!=None )
	{
		FlamingFXs.Kill();
		FlamingFXs.LifeSpan = 2;
		FlamingFXs = None;
	}
	bBurnApplied = False;
}

simulated function SmokeBody()
{
	if ( CorpseSmokeClass == None )
		return;
	CorpseSmoke = Spawn(CorpseSmokeClass);
	if ( CorpseSmoke != None )
	{
		CorpseSmoke.SetBase(Self);
		OverBody(CorpseSmoke);
	}
}

// The burnt skin comes in by degrees. A skin a blend can be made of (PlainSkin) is swapped for one that shows
// the burnt skin through it; the others, hair and the like, change with the rest at the end.
simulated function TickChar( float DeltaTime )
{
	local Texture T;
	local int i;

	if ( bAshen && CharLevel <= 0.0 && !bPlayedDeath )
		CharLevel = 1.0;		// burnt through before this machine saw it burn
	else if ( bAshen || (bBurnified && !bPlayedDeath) || (bPlayedDeath && CorpseBurnEnd > 0.0) )
		CharLevel = FMin(1.0, CharLevel + DeltaTime / CharTime);

	// the living wait for the server's word, so that what else changes their skins has finished with them
	if ( CharLevel >= 1.0 && (bAshen || bPlayedDeath) )
	{
		CharDone();
		return;
	}
	if ( CharLevel <= 0.0 || bCloaked || Level.TimeSeconds - LastRenderTime > 1.0 )
		return;

	if ( CharMask == None )
		CharMask = class'KFFXMat'.static.Tone(CharMade, Level, 255, 255);
	CharMask.Color.A = Clamp(int(255.0 * (1.0 - CharLevel)), 0, 255);
	for ( i=0; i<ArrayCount(CharSkins) && i<Skins.Length; i++ )
	{
		if ( Skins[i] == None || Skins[i] == CharSkins[i] )
			continue;
		// the first look at this skin, or something has changed it since
		T = PlainSkin(Skins[i]);
		if ( T == None )
			continue;
		if ( CharSkins[i] == None )
			CharSkins[i] = class'KFFXMat'.static.Fade(CharMade, Level, Texture'PatchTex.Common.ZedBurnSkin', T, CharMask);
		else
			CharSkins[i].Material2 = T;
		Skins[i] = CharSkins[i];
	}
}

// The plain picture under a skin, when the skin is one a blend can be made of: solid all over, and still
simulated function Texture PlainSkin( Material M )
{
	local int i;

	for ( i=0; i<4 && M != None; i++ )
	{
		if ( Texture(M) != None )
		{
			if ( Texture(M).bMasked || Texture(M).bAlphaTexture )
				return None;
			return Texture(M);
		}
		if ( Shader(M) != None && Shader(M).Opacity == None && Shader(M).OutputBlending == OB_Normal )
			M = Shader(M).Diffuse;
		else
			return None;
	}
	return None;
}

simulated function CharDone()
{
	bCharDone = true;
	CharLevel = 1.0;
	Skins[0]=Texture 'PatchTex.Common.ZedBurnSkin';
	Skins[1]=Texture 'PatchTex.Common.ZedBurnSkin';
	Skins[2]=Texture 'PatchTex.Common.ZedBurnSkin';
	Skins[3]=Texture 'PatchTex.Common.ZedBurnSkin';
	FreeChar();
}

simulated function FreeChar()
{
	local int i;

	for ( i=0; i<ArrayCount(CharSkins); i++ )
		CharSkins[i] = None;
	CharMask = None;
	if ( CharMade.Length > 0 )
		class'KFFXMat'.static.FreeAll(CharMade, Level);
}

// The jet stays on the neck and points up it, a little toward the sky. (Fixed to the head bone it would point
// along that bone's own axes, which is out of the side of the neck.)
simulated function AimNeckJet()
{
	local vector Top, Up;

	if ( NeckJet == None )
		return;
	Top = GetBoneCoords(HeadBone).Origin;
	Up = Normal(Top - GetBoneCoords('Bip01 Neck').Origin);
	NeckJet.SetLocation(Top);
	NeckJet.SetRotation(rotator(Up + vect(0,0,0.6)));
}

// One that has lost its head leaves a little blood on the floor where it staggers: a drop each DripSpacing,
// or now and then where it stands
simulated function BloodTrail()
{
	local vector Neck, Spot, Ground;

	if ( Level.bDropDetail || Level.TimeSeconds - LastDripTime < 0.15 )
		return;
	if ( VSize(Location - LastDripSpot) < DripSpacing && Level.TimeSeconds - LastDripTime < 2.0 )
		return;
	LastDripTime = Level.TimeSeconds;
	Neck = GetBoneCoords(HeadBone).Origin;
	if ( Trace(Spot, Ground, Neck - vect(0,0,250), Neck, false) == None )
		return;
	Spawn(DripDecalClass,,, Spot + 20 * Ground, rotator(-Ground));
	LastDripSpot = Location;
	DripsLeft--;
}

// A specimen's sidestep (the Fleshpound's, when a projectile is fired at it from in front:
// FleshpoundZombieController.ReceiveWarning) is the stock dodge's move without the stock dodge's grunt, which in every
// specimen's sound group is a UT player's (PlayerSounds.JumpSounds.MaleDodge).
function bool PerformDodge(eDoubleClickDir DoubleClickMove, vector Dir, vector Cross)
{
	local float VelocityZ;

	if ( Physics == PHYS_Falling )
	{
		TakeFallingDamage();
		if ( Velocity.Z < -DodgeSpeedZ*0.5 )
			Velocity.Z += DodgeSpeedZ*0.5;
	}
	VelocityZ = Velocity.Z;
	Velocity = DodgeSpeedFactor*GroundSpeed*Dir + (Velocity Dot Cross)*Cross;
	if ( !bCanDodgeDoubleJump )
		MultiJumpRemaining = 0;
	if ( bCanBoostDodge || (Velocity.Z < -100) )
		Velocity.Z = VelocityZ + DodgeSpeedZ;
	else
		Velocity.Z = DodgeSpeedZ;
	CurrentDir = DoubleClickMove;
	SetPhysics(PHYS_Falling);
	return true;
}

// High damage was taken, make em fall over.
function bool FlipOver()
{
	// (not a model without the knock-down, such as the Zombies mode's older ones: nothing played, so nothing ever let
	// it go again)
	if( !HasAnim('StunState') )
		Return False;
	if( Physics==PHYS_Falling )
	{
		SetPhysics(PHYS_Walking);
	}

	bShotAnim = true;
	SetAnimAction('StunState');
	Acceleration = vect(0, 0, 0);
	Velocity.X = 0;
	Velocity.Y = 0;
	// (one knocked over as it dies has no controller any more)
	if( Controller!=None )
	{
		Controller.GoToState('WaitForAnim');
		KFMonsterController(Controller).bUseFreezeHack = True;
	}
	Return True;
}

function AddVelocity( vector NewVelocity)
{
	if( VSize(NewVelocity)>50 )
		Super.AddVelocity(NewVelocity);
}

// Important Block of code controlling how the Zombies (excluding the Bloat and Fleshpound who cannot be stunned, respond to damage from the
// various weapons in the game. The basic rule is that any damage amount equal to or greater than 40 points will cause a stun.
// There are exceptions with the fists however, which are substantially under the damage quota but can still cause stuns 50% of the time.
// Why? Cus if they didn't at least have that functionality, they would be fundamentally useless. And anyone willing to take on a hoarde of zombies
// with only the gloves on his hands, deserves more respect than that!

simulated function PlayTakeHit(vector HitLocation, int Damage, class<DamageType> DamageType)
{
	local int FistStrikeStunChance;

	if( Level.TimeSeconds - LastPainAnim < MinTimeBetweenPainAnims )
		return;

	if( Damage>=5 )
		PlayDirectionalHit(HitLocation);
	else if (DamageType.name == 'DamTypeShotgun' || DamageType.name == 'DamTypeDBShotgun' || DamageType.name == 'DamTypeFrag' || DamageType.name == 'DamTypeLAW')
		PlayDirectionalHit(HitLocation);
	else if (DamageType.name == 'DamTypeClaws')
	{
		FistStrikeStunChance = rand(10);
		if ( FistStrikeStunChance > 5 )
			PlayDirectionalHit(HitLocation);
	}
	else if (DamageType.name == 'DamTypeKnife')
	{
		FistStrikeStunChance = rand(10);
		if ( FistStrikeStunChance > 7 )
			PlayDirectionalHit(HitLocation);
	}
	else if (DamageType.name == 'DamTypeChainsaw')
		PlayDirectionalHit(HitLocation);
	else if (DamageType.name == 'DamTypeStunNade')
		PlayDirectionalHit(HitLocation);
	else if (DamageType.name == 'DamTypeCrossbowHeadshot')
		PlayDirectionalHit(HitLocation);
	LastPainAnim = Level.TimeSeconds;

	if( Level.TimeSeconds - LastPainSound < MinTimeBetweenPainSounds )
		return;

	LastPainSound = Level.TimeSeconds;
	
	  if (DamageType != class 'Burned' && DamageType != class 'DamTypeFlamethrower')
		PlaySound(HitSound[Rand(4)], SLOT_Pain,2*TransientSoundVolume,,400);
}

simulated function DoDerezEffect(); // fuck no!

// Only the server knows what a hit did to a body. It leaves a note in the HitFX ring, and every
// machine drawing the specimen acts on it in ProcessHitFX.
simulated function PostHitFX( name Bone, class<DamageType> DamageType, rotator r, bool bSever )
{
	// The ring holds eight notes, and a full ring reads as an empty one. A shotgun blast on a body
	// posts more than that in one tick, so a machine that draws the body acts on them before they are lost.
	if ( Level.NetMode != NM_DedicatedServer && (HitFxTicker + 1) % ArrayCount(HitFX) == SimHitFxTicker )
		ProcessHitFX();
	HitFX[HitFxTicker].damtype = DamageType;
	HitFX[HitFxTicker].bone = Bone;
	HitFX[HitFxTicker].rotDir = r;
	HitFX[HitFxTicker].bSever = bSever;
	HitFxTicker = HitFxTicker + 1;
	if ( HitFxTicker > ArrayCount(HitFX) - 1 )
		HitFxTicker = 0;
}

simulated function bool CanSever( name Bone, int Damage, class<DamageType> DamageType )
{
	return !DamageType.default.bNeverSevers && !class'GameInfo'.static.UseLowGore()
		&& (Level.Game == None || !Level.Game.PreventSever(self, Bone, Damage, DamageType));
}

// Any joint for a blast to take: an elbow, shoulder, knee or hip, or now and then the head
simulated function name RandomJoint()
{
	if ( !bDecapitated && FRand() < 0.15 )
		return HeadBone;
	return LimbJoints[Rand(ArrayCount(LimbJoints))];
}

// boneName is the joint a limb would come off at, or None for a hit on the trunk.
// A Damage of exactly 1000 is this code's own way of asking for the part to come off for certain.
simulated function DoDamageFX( Name boneName, int Damage, class<DamageType> DamageType, Rotator r )
{
	local bool bSever;

	if ( DamageType == None )
		return;

	// A head just lost: every machine is told once, whatever took it off
	if ( bDecapitated && !bPlayBrainSplash )
	{
		bPlayBrainSplash = true;
		PostHitFX(HeadBone, DamageType, r, CanSever(HeadBone, Damage, DamageType));
	}

	// Only the dead lose limbs, and nothing is drawn on the bones of the living
	if ( Health > 0 )
		return;

	if ( CanSever(boneName, Damage, DamageType) )
	{
		if ( Damage == 1000 || DamageType.default.bAlwaysSevers )
			bSever = true;
		else if ( DamageType.default.GibModifier > 0.0 )
			bSever = FRand() < Abs((Health - Damage * DamageType.default.GibModifier) / 130.0);

		// a blast is aimed at nothing in particular
		if ( bSever && boneName == 'None' && !DamageType.default.bLocationalHit )
			boneName = RandomJoint();
	}
	if ( boneName == 'None' )
	{
		// blood and smoke still have somewhere to sit
		boneName = FireRootBone;
		bSever = false;
	}
	PostHitFX(boneName, DamageType, r, bSever);
}

// The weapons whose kills are judged by the size of the blast: shotguns and explosives
simulated function bool IsPowerHit( class<DamageType> DamageType )
{
	return class<KFWeaponDamageType>(DamageType) != None && class<KFWeaponDamageType>(DamageType).default.bIsPowerWeapon
		&& !DamageType.default.bNeverSevers;
}

function NoteBlast( float Damage, class<DamageType> DamageType )
{
	if ( !IsPowerHit(DamageType) )
		return;
	if ( Level.TimeSeconds - BlastTime > BlastWindow )
		BlastDamage = 0;
	BlastDamage += Damage;
	BlastTime = Level.TimeSeconds;
}

// Pellets of the same shot still on their way in. They count toward the blast: without them a
// specimen that died to the first few pellets would get off lightly.
function float PelletsStillComing( Pawn Shooter )
{
	local ShotgunBullet B;
	local vector Dir, Rel, Miss;
	local float Total, Along;
	local int i;

	if ( Shooter == None )
		return 0;
	foreach CollidingActors(class'ShotgunBullet', B, 400, Location)
	{
		if ( B.Instigator != Shooter || !IsPowerHit(B.MyDamageType) )
			continue;
		for ( i=0; i<B.HurtPawns.Length; i++ )
			if ( B.HurtPawns[i] == self )
				break;
		if ( i < B.HurtPawns.Length )
			continue;
		// on course for the body?
		Dir = Normal(B.Velocity);
		Rel = Location - B.Location;
		Along = Rel dot Dir;
		Miss = Rel - Dir * Along;
		if ( Along > 0 && Abs(Miss.Z) < CollisionHeight && VSize(Miss * vect(1,1,0)) < CollisionRadius )
			Total += B.Damage;
	}
	return Total;
}

function int JointIndex( name Bone )
{
	local int i;

	for ( i=0; i<ArrayCount(LimbJoints); i++ )
		if ( LimbJoints[i] == Bone )
			return i;
	return -1;
}

// The killing blow decides how much of the body goes. Bullets and blades take the limb they pass
// through, now and then. A power weapon is judged by its whole blast.
function DeathGore( name HitBone, int Damage, class<DamageType> DamageType, Pawn InstigatedBy, rotator r )
{
	local float Force;
	local bool bBlast;
	local int i;

	if ( IsPowerHit(DamageType) && Level.TimeSeconds - BlastTime <= BlastWindow )
	{
		BlastDamage += PelletsStillComing(InstigatedBy);
		// the same blast does not always do the same thing
		Force = BlastDamage / float(default.Health) * (0.6 + 0.8 * FRand());
	}
	bBlast = !DamageType.default.bLocationalHit;
	i = JointIndex(HitBone);

	if ( bBlast && Force >= BodyBlast )
		DoDamageFX('obliterate', 1000, DamageType, r);
	else if ( Force >= TorsoBlast && (bBlast || i < 4) )
	{
		// blown in half; an explosion may take a leg as well
		DoDamageFX('Bip01 Spine1', 1000, DamageType, r);
		if ( bBlast && FRand() < 0.4 )
			DoDamageFX(LimbJoints[4 + 2 * Rand(2)], 1000, DamageType, r);
	}
	else if ( Force >= TorsoBlast )
	{
		// a shotgun fired low takes both legs from under it
		DoDamageFX(LimbJoints[4], 1000, DamageType, r);
		DoDamageFX(LimbJoints[6], 1000, DamageType, r);
	}
	else if ( Force >= LimbBlast )
	{
		// a whole limb: the one in the way, else any of them for an explosion, an arm for a shot to the chest
		if ( i < 0 )
		{
			if ( bBlast )
				i = 2 * Rand(4);
			else
				i = 2 * Rand(2);
		}
		DoDamageFX(LimbJoints[i & 6], 1000, DamageType, r);
		if ( bBlast && FRand() < 0.35 )
			DoDamageFX(LimbJoints[2 * Rand(4)], 1000, DamageType, r);
		if ( bBlast && !bDecapitated && FRand() < 0.2 )
			DoDamageFX(HeadBone, 1000, DamageType, r);
	}
	else
		DoDamageFX(HitBone, Damage, DamageType, r);
}

// Shortest distance between a shot (from Start along Dir, or just the point Start when Dir is zero)
// and the bone that runs from joint A to joint B.
function float ShotToBone( vector Start, vector Dir, name A, name B )
{
	local coords CA, CB;
	local vector E, R;
	local float DE, EE, DR, ER, Denom, t, u;

	CA = GetBoneCoords(A);
	CB = GetBoneCoords(B);
	E = CB.Origin - CA.Origin;
	R = Start - CA.Origin;
	DE = Dir dot E;
	EE = E dot E;
	DR = Dir dot R;
	ER = E dot R;
	Denom = EE - DE * DE;
	if ( Denom > 0.001 )
		t = FMax(0.0, (DE * ER - EE * DR) / Denom);
	if ( EE > 0.001 )
		u = FClamp((DE * t + ER) / EE, 0.0, 1.0);
	t = FMax(0.0, DE * u - DR);
	return VSize(R + Dir * t - E * u);
}

// The joint a limb would come off at for a shot through HitLoc along Dir: the limb the shot passes
// nearest, or None when that is the trunk or nothing at all.
function name LimbJointNear( vector HitLoc, vector Dir )
{
	local float Best, D;
	local name Joint;
	local int i;

	Joint = 'None';
	Best = ShotToBone(HitLoc, Dir, 'Bip01 Pelvis', 'Bip01 Neck') - 9.0 * GibScale;		// the trunk is thicker
	for ( i=0; i<ArrayCount(LimbJoints); i++ )
	{
		D = ShotToBone(HitLoc, Dir, LimbJoints[i], LimbEnds[i]) - 3.0 * GibScale;
		if ( D < Best )
		{
			Best = D;
			Joint = LimbJoints[i];
		}
	}
	if ( Best > 8.0 )
		return 'None';
	return Joint;
}

// The specimen meshes carry no bone aliases, so the stock lookup can only ever answer None.
// Only the dead lose limbs, so the living are not measured.
function CalcHitLoc( Vector hitLoc, Vector hitRay, out Name boneName, out float dist )
{
	boneName = 'None';
	dist = 0;
	if ( Health <= 0 )
		boneName = LimbJointNear(hitLoc - hitRay * 20, hitRay);
}

//Stops the green shit when a player dies.
simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	local float frame, rate;
	local name seq;
	local LavaDeath LD;
	local MiscEmmiter BE;
	
	AmbientSound = None;
	bCanTeleport = false; // sjs - fix karma going crazy when corpses land on teleporters
	bReplicateMovement = false;
	bTearOff = true;
	bPlayedDeath = true;
	// one that was alight, or that fire killed, burns on where it falls
	if ( bBurnified || DamageType == class'Burned' || DamageType == class'DamTypeFlamethrower' )
		CorpseBurnEnd = Level.TimeSeconds + CorpseBurnTime * (0.75 + 0.5 * FRand());
	else
		StopBurnFX();

	if (CurrentCombo != None)
		CurrentCombo.Destroy();

	HitDamageType = DamageType; // these are replicated to other clients
	TakeHitLocation = HitLoc;

	// Noted on every machine, because each keeps and hits its own copy of the body: the killing blow
	// is past, and the rest of a blast that killed is about to land on the corpse
	bDeathGoreDone = true;
	if ( IsPowerHit(DamageType) )
		BlastKillTime = Level.TimeSeconds;

	bSTUNNED = false;
	bMovable = true;
			 
	if (DamageType == class 'Burned' ||  DamageType == class 'DamTypeFlamethrower')
		ZombieCrispUp();

	ProcessHitFX();
	// a head lost while alive stays lost
	if ( bDecapitated )
		SeverHead(false);

	if ( DamageType != None )
	{
		if ( DamageType.default.bSkeletize )
		{
			SetOverlayMaterial(DamageType.Default.DamageOverlayMaterial, 4.0, true);
			if (!bSkeletized)
			{
				if ( (Level.NetMode != NM_DedicatedServer) && (SkeletonMesh != None) )
				{
					if ( DamageType.default.bLeaveBodyEffect )
					{
						BE = spawn(class'MiscEmmiter',self);
						if ( BE != None )
						{
							BE.DamageType = DamageType;
							BE.HitLoc = HitLoc;
							bFrozenBody = true;
						}
					}
					GetAnimParams( 0, seq, frame, rate );
					LinkMesh(SkeletonMesh, true);
					Skins.Length = 0;
					PlayAnim(seq, 0, 0);
					SetAnimFrame(frame);
				}
				if (Physics == PHYS_Walking)
					Velocity = Vect(0,0,0);
				TearOffMomentum *= 0.25;
				bSkeletized = true;
				if ( (Level.NetMode != NM_DedicatedServer) && (DamageType == class'FellLava') )
				{
					LD = spawn(class'LavaDeath', , , Location + vect(0, 0, 10), Rotation );
					if ( LD != None )
						LD.SetBase(self);
					PlaySound( sound'WeaponSounds.BExplosion5', SLOT_None, 1.5*TransientSoundVolume );
				}
			}
		}
		else if ( DamageType.Default.DeathOverlayMaterial != None )
			SetOverlayMaterial(DamageType.Default.DeathOverlayMaterial, DamageType.default.DeathOverlayTime, true);
		else if ( (DamageType.Default.DamageOverlayMaterial != None) && (Level.DetailMode != DM_Low) && !Level.bDropDetail )
			SetOverlayMaterial(DamageType.Default.DamageOverlayMaterial, 2*DamageType.default.DamageOverlayTime, true);
	}

	// stop shooting
	AnimBlendParams(1, 0.0);
	FireState = FS_None;

	LifeSpan = RagdollLifeSpan;

	GotoState('ZombieDying');
	if ( BE != None )
		return;
	PlayDyingAnimation(DamageType, HitLoc);
}


State ZombieDying extends Dying
{
ignores AnimEnd, Trigger, Bump, HitWall, HeadVolumeChange, PhysicsVolumeChange, Falling, BreathTimer, Died, RangedAttack;     //Tick

	function Landed(vector HitNormal)
	{
		//SetPhysics(PHYS_None);
		SetCollision(false, false, false);
		if( !bDestroyNextTick )
		{
			// (a body with fire on it has more to show)
			if( !StillBurning() )
				Disable('Tick');
		}

		if ( !IsAnimating(0) )
			LandThump();
	}

	simulated function Timer()
	{
        local KarmaParamsSkel skelParams;

        if( bDestroyNextTick )
        {
            // If we've flagged this character to be destroyed next tick, handle that
            if( TimeSetDestroyNextTickTime < Level.TimeSeconds )
            {
                Destroy();
            }
            else
            {
                SetTimer(0.01, false);
            }

            return;
        }

		if ( !PlayerCanSeeMe() )
		{
			Destroy();
		}
		// If we are running out of life, but we still haven't come to rest, force the de-res.
		// unless pawn is the viewtarget of a player who used to own it
		else if ( LifeSpan <= DeResTime && bDeRes == false )
		{
			skelParams = KarmaParamsSkel(KParams);

			skelParams.bKImportantRagdoll = false;

			// spawn derez
			StartDeRes();
		}
		else
		{
			CheckSettle();
			SetTimer(1.0, false);
		}
	}

	simulated function BeginState()
	{
        if( bDestroyNextTick )
        {
            // If we've flagged this character to be destroyed next tick, handle that
            if( TimeSetDestroyNextTickTime < Level.TimeSeconds )
            {
                Destroy();
            }
            else
            {
                SetTimer(0.01, false);
            }
        }
        else
        {
            if ( bTearOff && (Level.NetMode == NM_DedicatedServer) || class'GameInfo'.static.UseLowGore() )
                LifeSpan = 1.0;
            else
                SetTimer(2.0, false);
		}

		SetPhysics(PHYS_Falling);
		if ( Controller != None )
		{
			Controller.Destroy();
		}
 	}

	simulated function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType)
	{
		local Vector HitNormal, shotDir;
		local Vector PushLinVel, PushAngVel;
		local bool bIsHeadshot;

		if( Physics == PHYS_KarmaRagdoll )
		{
			WakeBody();

			// Can't shoot corpses during de-res
			//if ( bDeRes )
			//	return;

			// To allow gibbing corpses
			if (Damage > 0)
			{
				Health -= Damage;

				if ( !bDecapitated && class<WeaponDamageType>(damageType)!=none )
				{
					bIsHeadShot = IsHeadShot(HitLocation, normal(Momentum), 1.0);
				}

				// The head of a corpse bursts like a living one's and takes as much again of the body with it.
				// Not through RemoveHead: that is for the living and leans on what only the server remembers,
				// and a network player's bodies should fare the same as a solo player's.
				if( bIsHeadShot )
				{
					bDecapitated = true;
					Health -= Damage + int(0.25 * HealthMax);
					PlaySound(DecapSound, SLOT_Misc);
				}

				PlayHit(Damage,InstigatedBy,HitLocation,DamageType,Momentum);

				if ( !bPlayGoreSplash && Health <= CorpseGibHealth && CorpseGibs(InstigatedBy, DamageType) )
				{
					if ( Momentum != vect(0,0,0) )
						HitNormal = -Normal(Momentum);
					else if ( InstigatedBy != None )
						HitNormal = Normal(InstigatedBy.Location - HitLocation);
					GibBody(Rotator(Normal(HitNormal + VRand() * 0.2 + vect(0,0,2.8))), 1.0);
					RemoveGibbedBody();
					return;
				}
			}

			// Throw the body if its a rocket explosion or shock combo
			if( damageType.Default.bThrowRagdoll )
			{
				shotDir = Normal(Momentum);
				PushLinVel = (RagDeathVel * shotDir) +  vect(0, 0, 250);
				PushAngVel = Normal(shotDir Cross vect(0, 0, 1)) * -18000;
				KSetSkelVel( PushLinVel, PushAngVel );
			}
			else if( damageType.Default.bRagdollBullet )
			{
				if ( Momentum == vect(0,0,0) && InstigatedBy != None )
					Momentum = HitLocation - InstigatedBy.Location;
				if ( FRand() < 0.65 )
				{
					if ( Velocity.Z <= 0 )
						PushLinVel = vect(0,0,40);
					PushAngVel = Normal(Normal(Momentum) Cross vect(0, 0, 1)) * -8000 ;
					PushAngVel.X *= 0.5;
					PushAngVel.Y *= 0.5;
					PushAngVel.Z *= 4;
					KSetSkelVel( PushLinVel, PushAngVel );
				}
				PushLinVel = RagShootStrength*Normal(Momentum);
				KAddImpulse(PushLinVel, HitLocation);
				if ( (LifeSpan > 0) && (LifeSpan < DeResTime + 2) )
					LifeSpan += 0.2;
			}
			else
			{
				PushLinVel = RagShootStrength*Normal(Momentum);
				KAddImpulse(PushLinVel, HitLocation);
			}
		}

		if ( (DamageType.Default.DamageOverlayMaterial != None) && (Level.DetailMode != DM_Low) && !Level.bDropDetail )
			SetOverlayMaterial(DamageType.Default.DamageOverlayMaterial, DamageType.default.DamageOverlayTime, true);
	}
	// We shorten the lifetime when the guys comes to rest.
	event KVelDropBelow()
	{
	}
}    

simulated function Timer()
{
	/*local int RandomNumber;
	local Rotator DefaultTorsoRotation;*/

	// lets see if this helps the soldier bots pick up on the fact that there's a growling zombie right behind them
	MakeNoise(1.0);

	if (BurnDown > 0)
	{
		TakeFireDamage(LastBurnDamage + rand(2) + 3 , LastDamagedBy);
		SetTimer(1.0,false); // Sets timer function to be executed each second
	}
	else
	{
		RemoveFlamingEffects();
		StopBurnFX();
		SetTimer(0, false);
	}
	/*if (bContorts)
	{
		DefaultTorsoRotation = GetBoneRotation('Bip01 Spine1');
		NewTorsoRotation = DefaultTorsoRotation ;

		RandomNumber = (rand(MaxSpineVariation) * (rand(3)+1)) - (MaxSpineVariation * (rand(3)+1));
		//Log("Random Number: "$RandomNumber);

		NewTorsoRotation.Roll += RandomNumber;
		NewTorsoRotation.Pitch += RandomNumber ;
		NewTorsoRotation.Yaw += RandomNumber;

		//Log("New Torso Rot: "$NewTorsoRotation);

		if ( NewTorsoRotation.Roll + (DefaultTorsoRotation.Roll + RandomNumber) > (MaxContortionPercentage * DefaultTorsoRotation.Roll) ||
		 NewTorsoRotation.Roll + (DefaultTorsoRotation.Roll + RandomNumber) < (MaxContortionPercentage * DefaultTorsoRotation.Roll) )
			NewTorsoRotation.Roll = DefaultTorsoRotation.Roll + (RandomNumber * MaxContortionPercentage);
		if ( NewTorsoRotation.Pitch + (DefaultTorsoRotation.Pitch + RandomNumber) > (MaxContortionPercentage * DefaultTorsoRotation.Pitch) ||
		 NewTorsoRotation.Pitch + (DefaultTorsoRotation.Pitch + RandomNumber) < (MaxContortionPercentage * DefaultTorsoRotation.Pitch) )
			NewTorsoRotation.Pitch = DefaultTorsoRotation.Pitch + (RandomNumber * MaxContortionPercentage);
		if ( NewTorsoRotation.Yaw+ (DefaultTorsoRotation.Yaw + RandomNumber) > (MaxContortionPercentage * DefaultTorsoRotation.Yaw) ||
		 NewTorsoRotation.Yaw + (DefaultTorsoRotation.Yaw + RandomNumber) < (MaxContortionPercentage * DefaultTorsoRotation.Yaw) )
			NewTorsoRotation.Yaw = DefaultTorsoRotation.Yaw + (RandomNumber * MaxContortionPercentage);

		SetBoneRotation( 'Bip01 Spine1', NewTorsoRotation,, 1.0 );
	}*/
}

simulated function ProcessHitFX()
{
	local Coords boneCoords;
	local class<xEmitter> HitEffects[4];
	local int i,j;
	local name Bone;

	// nothing more can come off a body that is already in pieces
	if( (Level.NetMode == NM_DedicatedServer) || bSkeletized || (Mesh == SkeletonMesh) || bGibbed )
	{
		SimHitFxTicker = HitFxTicker;
		return;
	}

	for ( SimHitFxTicker = SimHitFxTicker; SimHitFxTicker != HitFxTicker; SimHitFxTicker = (SimHitFxTicker + 1) % ArrayCount(HitFX) )
	{
		j++;
		if ( j > 30 )
		{
			SimHitFxTicker = HitFxTicker;
			return;
		}

		if( (HitFX[SimHitFxTicker].damtype == None) || (Level.bDropDetail && (Level.TimeSeconds - LastRenderTime > 3) && !IsHumanControlled()) )
			continue;

		Bone = HitFX[SimHitFxTicker].bone;
		if ( class'GameInfo'.static.UseLowGore() )
			HitFX[SimHitFxTicker].bSever = false;
		bFlaming = HitFX[SimHitFxTicker].damtype.default.bFlaming || bBurnApplied;

		if ( Bone == 'obliterate' )
		{
			if ( !HitFX[SimHitFxTicker].bSever )
				continue;
			GibBody(HitFX[SimHitFxTicker].rotDir, HitFX[SimHitFxTicker].damtype.default.GibPerterbation);
			// a body just killed is removed by PlayDyingAnimation; one already down has to be removed here
			if ( IsInState('ZombieDying') )
				RemoveGibbedBody();
			SimHitFxTicker = HitFxTicker;
			return;
		}

		boneCoords = GetBoneCoords( Bone );

		if ( !Level.bDropDetail && !bSkeletized )
		{
			AttachEffect( GibGroupClass.static.GetBloodEmitClass(), Bone, boneCoords.Origin, HitFX[SimHitFxTicker].rotDir );

			HitFX[SimHitFxTicker].damtype.static.GetHitEffects( HitEffects, Health );

			if( !PhysicsVolume.bWaterVolume ) // don't attach effects under water
			{
				for( i = 0; i < ArrayCount(HitEffects); i++ )
				{
					if( HitEffects[i] == None )
						continue;

					AttachEffect( HitEffects[i], Bone, boneCoords.Origin, HitFX[SimHitFxTicker].rotDir );
				}
			}
		}

		if( HitFX[SimHitFxTicker].bSever )
			Sever(Bone, HitFX[SimHitFxTicker].rotDir, HitFX[SimHitFxTicker].damtype.default.GibPerterbation);
	}
}

// The ten joints a body can come apart at, by bone-scale slot; -1 for any other bone.
simulated function int SeverSlot( name Bone )
{
	switch ( Bone )
	{
		case 'Bip01 L Thigh':		return 0;
		case 'Bip01 R Thigh':		return 1;
		case 'Bip01 R Forearm':		return 2;
		case 'Bip01 L Forearm':		return 3;
		case 'Bip01 Head':			return 4;
		case 'Bip01 Spine1':		return 5;
		case 'Bip01 L Calf':		return 6;
		case 'Bip01 R Calf':		return 7;
		case 'Bip01 L UpperArm':	return 8;
		case 'Bip01 R UpperArm':	return 9;
	}
	return -1;
}

simulated function GibAt( class<Gib> GibClass, name Bone, rotator Dir, float Spread )
{
	local coords C;

	C = GetBoneCoords(Bone);
	SpawnGiblet(GibClass, C.Origin, Dir, Spread);
}

// Caps a joint with the stump mesh. It rides the hidden bone, so it stays on the joint.
simulated function AddStump( int Slot, name Bone )
{
	if ( HeadStubClass == None || Stumps[Slot] != None )
		return;
	Stumps[Slot] = Spawn(HeadStubClass, self);
	if ( Stumps[Slot] == None )
		return;
	Stumps[Slot].RemoteRole = ROLE_None;		// every machine makes its own
	Stumps[Slot].SetPhysics(PHYS_None);			// part of the body, not a loose giblet
	Stumps[Slot].bCollideWorld = false;
	Stumps[Slot].SetDrawScale(Stumps[Slot].DrawScale * StumpSize[Slot] * GibScale * DrawScale);
	AttachToBone(Stumps[Slot], Bone);
}

simulated function DropStump( int Slot )
{
	if ( Stumps[Slot] != None )
		Stumps[Slot].Destroy();
	Stumps[Slot] = None;
}

// The head goes: hidden, the neck capped. bThrow adds the head and bits of brain flying off; without
// it the head is simply gone, for a machine that learns of it late.
simulated function SeverHead( bool bThrow, optional rotator Dir, optional float Spread )
{
	local coords C;

	if ( Severed[4] != 0 || Level.NetMode == NM_DedicatedServer || class'GameInfo'.static.UseLowGore() )
		return;
	Severed[4] = 1;
	if ( bThrow )
	{
		C = GetBoneCoords(HeadBone);
		Spawn(class'KFMod.BrainSplash',,, C.Origin, Rotation);
		SpawnGiblet(MonsterHeadGiblet, C.Origin, Dir, Spread);
		if ( EffectIsRelevant(Location, false) )
		{
			SpawnGiblet(class'KFMod.KFGibBrain', C.Origin, Rotation, 0.06);
			SpawnGiblet(class'KFMod.KFGibBrainb', C.Origin, Rotation, 0.06);
		}
		PlaySound(sound'PlayerSounds.NewGibs.NewGib2', SLOT_Misc, 255);
	}
	HideBone(HeadBone);
	AddStump(4, HeadBone);
	// one still on its feet pumps blood from the neck, and leaves a trail
	if ( !bPlayedDeath && NeckJet == None && NeckJetClass != None )
	{
		NeckJet = Spawn(NeckJetClass, self,, GetBoneCoords(HeadBone).Origin);
		AimNeckJet();
		DripsLeft = MaxDrips;
	}
}

// A joint comes apart on this machine: what hangs from it is thrown as giblets and hidden, and the
// joint is capped. A part goes only once, and not after the part it hangs from.
simulated function Sever( name Bone, rotator Dir, float Spread )
{
	local coords C;
	local int Slot;

	Slot = SeverSlot(Bone);
	if ( Slot < 0 || Severed[Slot] != 0 )
		return;
	if ( Slot == 4 )
	{
		SeverHead(true, Dir, Spread);
		return;
	}
	C = GetBoneCoords(Bone);

	switch ( Slot )
	{
		case 0:		// a leg at the hip; the shin may have gone before it
			if ( Severed[6] == 0 )
				GibAt(MonsterLegGiblet, 'Bip01 L Calf', Dir, Spread);
			Severed[6] = 1;
			DropStump(6);
			SpawnGiblet(MonsterThighGiblet, C.Origin, Dir, Spread);
			break;
		case 1:
			if ( Severed[7] == 0 )
				GibAt(MonsterLegGiblet, 'Bip01 R Calf', Dir, Spread);
			Severed[7] = 1;
			DropStump(7);
			SpawnGiblet(MonsterThighGiblet, C.Origin, Dir, Spread);
			break;
		case 6:		// below the knee
		case 7:
			SpawnGiblet(MonsterLegGiblet, C.Origin, Dir, Spread);
			break;
		case 8:		// an arm at the shoulder; the forearm may have gone before it
			if ( Severed[3] == 0 )
				GibAt(MonsterArmGiblet, 'Bip01 L Forearm', Dir, Spread);
			Severed[3] = 1;
			DropStump(3);
			SpawnGiblet(MonsterArmGiblet, C.Origin, Dir, Spread);
			break;
		case 9:
			if ( Severed[2] == 0 )
				GibAt(MonsterArmGiblet, 'Bip01 R Forearm', Dir, Spread);
			Severed[2] = 1;
			DropStump(2);
			SpawnGiblet(MonsterArmGiblet, C.Origin, Dir, Spread);
			break;
		case 2:		// below the elbow
		case 3:
			SpawnGiblet(MonsterArmGiblet, C.Origin, Dir, Spread);
			break;
		case 5:		// blown in half: the chest goes, and with it the head and whatever is left of the arms
			if ( Severed[4] == 0 )
				GibAt(MonsterHeadGiblet, HeadBone, Dir, Spread);
			if ( Severed[3] == 0 )
				GibAt(MonsterArmGiblet, 'Bip01 L Forearm', Dir, Spread);
			if ( Severed[2] == 0 )
				GibAt(MonsterArmGiblet, 'Bip01 R Forearm', Dir, Spread);
			GibAt(MonsterTorsoGiblet, 'Bip01 Spine2', Dir, Spread);
			Severed[2] = 1;
			Severed[3] = 1;
			Severed[4] = 1;
			Severed[8] = 1;
			Severed[9] = 1;
			DropStump(2);
			DropStump(3);
			DropStump(4);
			DropStump(8);
			DropStump(9);
			break;
	}

	Spawn(class'KFMod.BrainSplash',,, C.Origin, Rotation);
	if ( Slot == 5 )
		PlaySound(sound'PlayerSounds.NewGibs.NewGib3', SLOT_Misc, 255);
	else
		PlaySound(sound'PlayerSounds.NewGibs.NewGib1', SLOT_Misc, 255);
	Severed[Slot] = 1;
	HideBone(Bone);
	AddStump(Slot, Bone);
}

// Nothing left but pieces: every part still on the body is thrown from where it was.
// The body itself is taken away by whoever called this.
simulated function GibBody( rotator Dir, float Spread )
{
	local int i, Extra;

	if ( bGibbed || Level.NetMode == NM_DedicatedServer || class'GameInfo'.static.UseLowGore() )
		return;
	bGibbed = true;
	bPlayGoreSplash = true;
	Spread = FMax(Spread, 0.5);

	Spawn(class'KFMod.FeedingSpray',,, Location, Rotation);
	Spawn(class'KFMod.BodySplash',,, Location, Rotation);
	PlaySound(sound'PlayerSounds.NewGibs.NewGib4', SLOT_Misc, 255);

	if ( Severed[5] == 0 )
	{
		if ( Severed[4] == 0 )
			GibAt(MonsterHeadGiblet, HeadBone, Dir, Spread);
		if ( Severed[3] == 0 )
			GibAt(MonsterArmGiblet, 'Bip01 L Forearm', Dir, Spread);
		if ( Severed[2] == 0 )
			GibAt(MonsterArmGiblet, 'Bip01 R Forearm', Dir, Spread);
		GibAt(MonsterTorsoGiblet, 'Bip01 Spine2', Dir, Spread);
	}
	GibAt(MonsterLowerTorsoGiblet, 'Bip01 Pelvis', Dir, Spread);
	if ( Severed[0] == 0 )
		GibAt(MonsterThighGiblet, 'Bip01 L Thigh', Dir, Spread);
	if ( Severed[1] == 0 )
		GibAt(MonsterThighGiblet, 'Bip01 R Thigh', Dir, Spread);
	if ( Severed[6] == 0 )
		GibAt(MonsterLegGiblet, 'Bip01 L Calf', Dir, Spread);
	if ( Severed[7] == 0 )
		GibAt(MonsterLegGiblet, 'Bip01 R Calf', Dir, Spread);

	// and a few loose scraps
	if ( !Level.bDropDetail && Level.DetailMode != DM_Low )
	{
		Extra = 2 + Rand(4);
		for ( i = 0; i < Extra; i++ )
		{
			if ( Rand(2) == 0 )
				GibAt(class'KFMod.KFGibBrain', 'Bip01 Spine2', Dir, 1.0);
			else
				GibAt(class'KFMod.KFGibBrainb', 'Bip01 Pelvis', Dir, 1.0);
		}
	}

	for ( i=0; i<ArrayCount(Stumps); i++ )
		DropStump(i);
}

// Takes a body that has been blown to pieces out of the world on the next tick
simulated function RemoveGibbedBody()
{
	bHidden = true;
	SetCollision(false, false, false);
	bDestroyNextTick = true;
	TimeSetDestroyNextTickTime = Level.TimeSeconds;
}

// A corpse comes apart to an explosion most of the time, and to a shotgun up close once in a while
simulated function bool CorpseGibs( Pawn InstigatedBy, class<DamageType> DamageType )
{
	if ( IsPowerHit(DamageType) && !DamageType.default.bLocationalHit )
		return FRand() < 0.7;
	return (DamageType == class'DamTypeShotgun' || DamageType == class'DamTypeDBShotgun') && InstigatedBy != None
		&& VSize(InstigatedBy.Location - Location) < 200.0 && FRand() < 0.05;
}

simulated function SpawnGiblet( class<Gib> GibClass, Vector Location, Rotator Rotation, float GibPerterbation )
{
    local Gib Giblet;
    local Vector Direction, Dummy;

    if( (GibClass == None) || class'GameInfo'.static.UseLowGore() )
        return;

	Instigator = self;
    Giblet = Spawn( GibClass,,, Location, Rotation );

    if( Giblet == None )
        return;
	Giblet.bFlaming = bFlaming;
	Giblet.SpawnTrail();

	Giblet.SetDrawScale(Giblet.DrawScale * GibScale * DrawScale);
	if( GibClass == MonsterHeadGiblet )
		Giblet.SetDrawScale(Giblet.DrawScale * 0.5);
    GibPerterbation *= 32768.0;
    Rotation.Pitch += ( FRand() * 2.0 * GibPerterbation ) - GibPerterbation;
    Rotation.Yaw += ( FRand() * 2.0 * GibPerterbation ) - GibPerterbation;
    Rotation.Roll += ( FRand() * 2.0 * GibPerterbation ) - GibPerterbation;

    GetAxes( Rotation, Dummy, Dummy, Direction );

    Giblet.Velocity = Velocity + Normal(Direction) * (512.0 + FRand() * 256.0);

	//log("Spawned Giblet of class "$Giblet$" at location "$Location$" with size: "$Giblet.DrawScale$ " on pawn "$GetHumanReadableName());
}

// A body that has come to rest leaves Karma's world contacts and gravity. Karma still holds its pose and traces still
// meet its bones, but it costs about an eighth of what it did (32 bodies at rest: 6.4 ms a frame down to 0.8; it was
// most of the frame in big waves). Strong damping stills any limb still moving. Anything that hits it, or a new body
// falling near it, puts it back as it was, all but its shadow: that goes for good when it first settles (about 10 us
// a frame each, and hardly to be seen under a body lying on the floor).
simulated function CheckSettle()
{
	if ( bSettledBody || bDeRes || SettleSpeed <= 0 || Physics != PHYS_KarmaRagdoll )
		return;
	if ( VSize(Velocity) < SettleSpeed )
	{
		SettleChecks++;
		if ( SettleChecks >= SettleChecksNeeded )
			SettleBody();
	}
	else
		SettleChecks = 0;
}

simulated function SettleBody()
{
	local KarmaParamsSkel Skel;

	Skel = KarmaParamsSkel(KParams);
	if ( bSettledBody || Skel == None || Physics != PHYS_KarmaRagdoll || !bBlockKarma )
		return;
	bSettledBody = true;
	SettledLinDamp = Skel.KLinearDamping;
	SettledAngDamp = Skel.KAngularDamping;
	Skel.KLinearDamping = 10;
	Skel.KAngularDamping = 10;
	Skel.KActorGravScale = 0;
	KSetBlockKarma(false);
	if ( PlayerShadow != None )
	{
		PlayerShadow.Destroy();
		PlayerShadow = None;
	}
	if ( RealtimeShadow != None )
	{
		RealtimeShadow.Destroy();
		RealtimeShadow = None;
	}
}

simulated function WakeBody()
{
	local KarmaParamsSkel Skel;
	local bool bWasCollide, bWasBlockActors, bWasBlockPlayers;

	if ( !bSettledBody )
		return;
	Skel = KarmaParamsSkel(KParams);
	if ( Skel == None || Physics != PHYS_KarmaRagdoll || !bCollideActors )
		return;
	bSettledBody = false;
	SettleChecks = 0;
	Skel.KLinearDamping = SettledLinDamp;
	Skel.KAngularDamping = SettledAngDamp;
	Skel.KActorGravScale = RagGravScale;
	// (KSetBlockKarma(true) on a ragdoll that collides fails an engine check: the engine looks at the flag before it
	// sets it. With collision off it only sets the flag, and turning collision on again puts it back in the contacts.)
	bWasCollide = bCollideActors;
	bWasBlockActors = bBlockActors;
	bWasBlockPlayers = bBlockPlayers;
	SetCollision(false, false, false);
	KSetBlockKarma(true);
	SetCollision(bWasCollide, bWasBlockActors, bWasBlockPlayers);
	KWake();
}

simulated function WakeBodiesNear()
{
	local KFMonster M;

	foreach CollidingActors(class'KFMonster', M, 200)
		if ( M != self && M.bSettledBody )
			M.WakeBody();
}

simulated function StartDeRes()
{
	if( Level.NetMode == NM_DedicatedServer )
		return;

	AmbientGlow=0;
	MaxLights=5;

	// Turn off collision when we de-res (avoids rockets etc. hitting corpse!)
	SetCollision(false, false, false);

	// Remove/disallow projectors
	Projectors.Remove(0, Projectors.Length);
	bAcceptsProjectors = false;

	// Remove shadow
	if(PlayerShadow != None)
		PlayerShadow.bShadowActive = false;

	// Remove flames
	RemoveFlamingEffects();

	// Turn off any overlays
	SetOverlayMaterial(None, 0.0f, true);

    bDeRes = true;
}

function bool CanAttack(Actor A)
{
	if (A == none)
		return false;
	if(Stunned())
		return false;
	if(KFHumanPawnZombies(A)!=none && KFHumanPawnZombies(A).bIsDowned)
		return false;
	if(KFDoorMover(A)!=none)
		return true;
	else if(KFHumanPawn(A)!=none && KFHumanPawn(A).Health <= 0)
		return ( VSize(A.Location - Location) < MeleeRange + CollisionRadius);
	else return ( VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius );
}

// True if no other body would be inside this one at its full width
function bool RoomToGrow()
{
	local Pawn P;
	local vector D;

	foreach CollidingActors(class'Pawn', P, PreCrowdShrinkRadius + 30)
	{
		if( P==self || P.Health<=0 || !P.bBlockActors )
			continue;
		D = P.Location - Location;
		if( Abs(D.Z)>=CollisionHeight+P.CollisionHeight )
			continue;
		D.Z = 0;
		if( VSize(D)<PreCrowdShrinkRadius+P.CollisionRadius )
			return false;
	}
	return true;
}

function ShrinkForCrowding()
{
	local float NewRadius;

	if( !bCrowdRadiusShrunk )
	{
		PreCrowdShrinkRadius = CollisionRadius;
		NewRadius = FMax(CrowdShrinkMinRadius, CollisionRadius*CrowdShrinkFactor);
		if( NewRadius<CollisionRadius )
		{
			bCrowdRadiusShrunk = true;
			SetCollisionSize(NewRadius, CollisionHeight);
		}
	}
	CrowdShrinkEndTime = Level.TimeSeconds + CrowdShrinkRestoreDelay;
}

function DoorAttack(Actor A)
{
	if ( bShotAnim || Physics == PHYS_Swimming)
		return;
	else if ( A!=None )
	{
		bShotAnim = true;
		SetAnimAction('Claw');
		PlaySound(sound'Claw2s', SLOT_None);
		return;
	}
}

function CorpseAttack(Actor A)
{
	// (not a model without the feeding, as above for the knock-down)
	if ( bShotAnim || Physics == PHYS_Swimming || !HasAnim('ZombieFeed') )
		return;
	Velocity.X = 0;
	Velocity.Y = 0;
	Acceleration = vect(0,0,0);
	bShotAnim = true;
	SetAnimAction('ZombieFeed');
	Health+=(1+Rand(3));
	Health = Min(Health,Default.Health*1.5);
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
		Controller.bPreparingMove = true;
		Acceleration = vect(0,0,0);
		return;
	}
}
simulated event SetAnimAction(name NewAction)
{
	local int meleeAnimIndex, Channel;

	if( NewAction=='' )
		Return;
	if(NewAction == 'Claw')
	{
		meleeAnimIndex = Rand(3);
		NewAction = meleeAnims[meleeAnimIndex];
		CurrentDamtype = ZombieDamType[meleeAnimIndex];
	}
	Channel = DoAnimAction(NewAction);
	// A flinch does not take over from an action that holds the specimen (a knock-down, an attack, a scream): the
	// flinch's end freed it, and it walked off sliding in the knock-down's pose or attacked from the floor. (Unless
	// that action is no longer playing, so a lost animation end still lets it go.)
	if( !bShotAnim || !IsFlinchAnim(NewAction) || !IsAnimating(ExpectingChannel) )
		ExpectingChannel = Channel;
	if( Channel!=0 )
		bWaitForAnim = true;
	else bPhysicsAnimUpdate = False;
	if( Level.NetMode!=NM_Client )
	{
		AnimAction = NewAction;
		bResetAnimAct = True;
		ResetAnimActTime = Level.TimeSeconds+0.3;
	}
}
simulated function bool IsFlinchAnim( name AnimName )
{
	return AnimName=='HitF' || AnimName=='HitF2' || AnimName=='HitF3' || AnimName==KFHitFront || AnimName==KFHitBack
		|| AnimName==KFHitRight || AnimName==KFHitLeft;
}

simulated function int DoAnimAction( name AnimName )
{
	if( IsFlinchAnim(AnimName) )
	{
		AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
		PlayAnim(AnimName,, 0.0, 1);
		Return 1;
	}
	// (knocked over: an attack under way over the upper body stops, or it swung on, and struck, from the floor)
	if( AnimName=='StunState' )
		StopAnimating(true);
	PlayAnim(AnimName,,0.1);
	Return 0;
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
	Super(xPawn).AnimEnd(Channel);
}

simulated function HandleBumpGlass()
{
	Acceleration = vect(0,0,0);
	Velocity = vect(0,0,0);

	SetAnimAction(MeleeAnims[0]);
	bShotAnim = true;
	controller.GotoState('WaitForAnim');
}


simulated function StoodUp();
simulated function FellDown();

function ClawDamageTarget()
{
	local vector PushDir;

	if(Controller!=none && Controller.Target!=none)
		PushDir = (damageForce * Normal(Controller.Target.Location - Location));
	else PushDir = damageForce * vector(Rotation);
	if ( MeleeDamageTarget( (damageConst + rand(damageRand) ), PushDir))
		PlayZombieAttackHitSound();
}

// TODO: refactor one step further and have a dynamic array of ZombieAttackHitSounds
function PlayZombieAttackHitSound()
{
	local int MeleeAttackSounds;

	MeleeAttackSounds = rand(4) ;
	switch(MeleeAttackSounds)
	{
		case 0:
			PlaySound(sound'KFWeaponSound.Punch3', SLOT_Interact);
			break;
		case 1:
			PlaySound(sound'KFWeaponSound.bullethitflesh5', SLOT_Interact);
			break;
		case 2:
			PlaySound(sound'KFWeaponSound.Punch2', SLOT_Interact);
			break;
		case 3:
			PlaySound(sound'KFWeaponSound.Punch1', SLOT_Interact);
			break;
	}
}

function ZombieMoan() // Moved from Controller to here (so we don't need an own controller for each moan type).
{
	local int MoanSounds;

	MoanSounds = rand(MoanVoice.length);

	PlaySound(MoanVoice[MoanSounds], SLOT_Misc);

}

function RemoveHead()                             
{
	Intelligence = BRAINS_Retarded; // Headless dumbasses!

	bDecapitated  = true;
	DECAP = true;
	DecapTime = Level.TimeSeconds;
	if ( MyHeadCollision != none )
		MyHeadCollision.Destroy();

	if(Health > 0)
	{
		Velocity = vect(0,0,0);
		SetAnimAction('HitF');
		GroundSpeed *= 0.80;
		UpdateRunAnim();
		AirSpeed *= 0.8;
		WaterSpeed *= 0.8;
		BleedOutTime = Level.TimeSeconds +  BleedOutDuration;
		// No more raspy breathin'...cuz he has no throat or mouth :S
		AmbientSound = MiscSound;
		//TODO - Find right place for this
		// He's got no head so biting is out.
		if (MeleeAnims[2] == 'Claw3')
			MeleeAnims[2] = 'Claw2';
		if (MeleeAnims[1] == 'Claw3')
			MeleeAnims[1] = 'Claw1';
	}

	//TODO - do we need to inform the controller that we can't move owing to lack of head,
	//	   or is that handled elsewhere
	if ( Controller != none )
	{
		MonsterController(Controller).Accuracy = -5;  // More chance of missing. (he's headless now, after all) :-D
	}
	// Head explodes, causing additional hurty.

	if( KFPawn(LastDamagedBy)!=None )
        TakeDamage( LastDamageAmount + 0.25 * HealthMax , LastDamagedBy, LastHitLocation, LastMomentum, LastDamagedByType);
	// when no hit followed to carry the news to the other machines
	if ( !bPlayBrainSplash && LastDamagedByType != None )
		DoDamageFX(HeadBone, 0, LastDamagedByType, Rotation);

	PlaySound(DecapSound, SLOT_Misc);
}



function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
	local bool bIsHeadshot;
	local float HeadShotCheckScale;
	local float DamageScore;
	local KFPlayerReplicationInfo KFPRI;

	LastDamagedBy = instigatedBy;
	LastDamagedByType = damageType;
	HitMomentum = VSize(momentum);
	LastHitLocation = hitlocation;
	LastMomentum = momentum;

	// Zeds and fire dont mix.
	if( class<Burned>(damageType)!=none || class<DamTypeFlamethrower>(damageType)!=none)
	{
        if( BurnDown<=0 || Damage > LastBurnDamage )
        {
			LastBurnDamage = Damage;
		}
		Damage *= 1.5;
		if( BurnDown<=0 )
		{
			if( HeatAmount>4 || Damage >= 15 )
			{
				bBurnified = true;
				BurnDown = 10;
				SetGroundSpeed(GroundSpeed);	// (it is slowed in there, now that it burns)
				BurnInstigator = instigatedBy;
				SetTimer(1.0,true);
			}
			else HeatAmount++;
		}
	}

	if ( KFPawn(instigatedBy) != none && instigatedBy.PlayerReplicationInfo != none )
	{
		KFPRI = KFPlayerReplicationInfo(instigatedBy.PlayerReplicationInfo);
	}

	if ( KFPRI != none  )
	{
		if ( KFPRI.ClientVeteranSkill != none )
		{
			Damage = KFPRI.ClientVeteranSkill.Static.AddDamage(self, KFPawn(instigatedBy), Damage, DamageType);
		}
	}

	if ( !bDecapitated )
	{
		HeadShotCheckScale = 1.0;

		// Do larger headshot checks if it is a melee attach
		if( class<DamTypeMelee>(damageType) != none )
		{
			HeadShotCheckScale *= 1.25;
		}

		bIsHeadShot = IsHeadShot(hitlocation, normal(momentum), HeadShotCheckScale);
	}

	if ( (bDecapitated || bIsHeadShot) && class<Burned>(DamageType) == none && class<DamTypeFlamethrower>(DamageType) == none )
	{
		if(class<KFWeaponDamageType>(damageType)!=none)
			Damage = Damage * class<KFWeaponDamageType>(damageType).default.HeadShotDamageMult;
		if( KFPawn(instigatedBy)!=None && class<DamTypeMelee>(damageType)==none )   // Hack for sharpshooter. NO headshot bonuses on melee
			Damage*=KFPawn(instigatedBy).GetVeteran().Static.GetHeadShotDamMulti();
			
		LastDamageAmount = Damage;	

		if( !bDecapitated )
		{
			if( bIsHeadShot )
			{
				//Level.Game.Broadcast(self, "Headshot!");
				if( Level.TimeSeconds - LastHeadShotSoundTime >= 0.1 )
				{
					PlaySound(sound'PlayerSounds.NewGibs.NewGib1', SLOT_None,100);
					LastHeadShotSoundTime = Level.TimeSeconds;
				}
				HeadHealth -= LastDamageAmount;
				if( HeadHealth <= 0 || Damage > Health )
				{
				   RemoveHead();
				}
			}
		}
	}

	if( Health-Damage > 0 && DamageType!=class'DamTypeFrag' && DamageType!=class'DamTypeShotgun' && DamageType!=class'DamTypeDBShotgun' )
		Momentum = vect(0,0,0);
	if(class<DamTypeVomit>(DamageType)!=none) // Same rules apply to zombies as players.
	{
		BileCount=7;
		BileInstigator = instigatedBy;
		if(NextBileTime< Level.TimeSeconds )
			NextBileTime = Level.TimeSeconds+BileFrequency;
	}

	if ( KFPawn(instigatedBy) != none && instigatedBy.PlayerReplicationInfo != none )
	{
		if ( KFZombiesGameType(Level.Game) != none )
			KFZombiesGameType(Level.Game).ScoreMonsterHit(self, instigatedBy, Damage, damageType);
		else
		{
			DamageScore += 1;
			instigatedBy.PlayerReplicationInfo.Score += DamageScore;
			if ( instigatedBy.PlayerReplicationInfo.Team != None )
				instigatedBy.PlayerReplicationInfo.Team.Score += DamageScore;
		}
	}

	Super.takeDamage(Damage, instigatedBy, hitLocation, momentum, damageType);
}

// Modified version of the original Pawn playhit. Set up because we want our blood puffs to be directional based
// On the momentum of the bullet, not out from the center of the player
function OldPlayHit(float Damage, Pawn InstigatedBy, vector HitLocation, class<DamageType> damageType, vector Momentum)
{
	local Vector HitNormal;
	local vector BloodOffset, Mo;
	local class<Effects> DesiredEffect;
	local class<Emitter> DesiredEmitter;
	local PlayerController Hearer;

	if ( DamageType == None )
		return;
	if ( (Damage <= 0) && ((Controller == None) || !Controller.bGodMode) )
		return;

	if (Damage > DamageType.Default.DamageThreshold) //spawn some blood
	{
		HitNormal = Normal(HitLocation - Location);

		// Play any set effect
		if ( EffectIsRelevant(Location,true) )
		{
			DesiredEffect = DamageType.static.GetPawnDamageEffect(HitLocation, Damage, Momentum, self, (Level.bDropDetail || Level.DetailMode == DM_Low));

			if ( DesiredEffect != None )
			{
				BloodOffset = 0.2 * CollisionRadius * HitNormal;
				BloodOffset.Z = BloodOffset.Z * 0.5;

				Mo = Momentum;
				if ( Mo.Z > 0 )
					Mo.Z *= 0.5;
				spawn(DesiredEffect,self,,HitLocation + BloodOffset, rotator(Mo));
			}

			// Spawn any preset emitter
            // Don't spawn the blood when we're zapped as we're spawning the zapped damage emitter elsewhere
			DesiredEmitter = DamageType.Static.GetPawnDamageEmitter(HitLocation, Damage, Momentum, self, (Level.bDropDetail || Level.DetailMode == DM_Low));
			if (DesiredEmitter != None)
			{
				if( InstigatedBy != none )
					HitNormal = Normal((InstigatedBy.Location+(vect(0,0,1)*InstigatedBy.EyeHeight))-HitLocation);

				spawn(DesiredEmitter,,,HitLocation+HitNormal + (-HitNormal * CollisionRadius), Rotator(HitNormal));
			}
		}
	}
	if ( Health <= 0 )
	{
		if ( PhysicsVolume.bDestructive && (PhysicsVolume.ExitActor != None) )
			Spawn(PhysicsVolume.ExitActor);
		return;
	}

	if ( Level.TimeSeconds - LastPainTime > 0.1 )
	{
		if ( InstigatedBy != None && (DamageType != None) && DamageType.default.bDirectDamage )
			Hearer = PlayerController(InstigatedBy.Controller);
		if ( Hearer != None )
			Hearer.bAcuteHearing = true;
		PlayTakeHit(HitLocation,Damage,damageType);
		if ( Hearer != None )
			Hearer.bAcuteHearing = false;
		LastPainTime = Level.TimeSeconds;
	}
}

// New Hit FX for Zombies!
// On a dedicated server the stock test first puts the idle pose on channel 0, as its guess at what clients show (the
// server plays no movement animations). At every hit that cut short a whole-body action playing there (a knock-down,
// an attack, a feed), and the idle's end let the specimen go: clients saw it slide along in the action's pose. Such an
// action plays on the server as well, so a specimen in one is tested in that pose, which is what clients show.
function bool IsHeadShot(vector loc, vector ray, float AdditionalScale)
{
	local coords C;
	local vector HeadLoc, B, M, diff;
	local float t, DotMM, Distance;

	if( Level.NetMode!=NM_DedicatedServer || HeadBone=='' || !IsAnimating(0) )
		return Super.IsHeadShot(loc, ray, AdditionalScale);

	C = GetBoneCoords(HeadBone);
	HeadLoc = C.Origin + (HeadHeight * HeadScale * AdditionalScale * C.XAxis);
	B = loc;
	M = ray * (2.0 * CollisionHeight + 2.0 * CollisionRadius);
	diff = HeadLoc - B;
	t = M Dot diff;
	if( t>0 )
	{
		DotMM = M dot M;
		if( t<DotMM )
			diff = diff - (t / DotMM) * M;
		else
			diff -= M;
	}
	Distance = Sqrt(diff Dot diff);
	return (Distance < (HeadRadius * HeadScale * AdditionalScale));
}

function PlayHit(float Damage, Pawn InstigatedBy, vector HitLocation, class<DamageType> damageType, vector Momentum)
{
	local Vector HitNormal;
	local Vector HitRay ;
	local Name HitBone;
	local float HitBoneDist;
	local PlayerController PC;
	local bool bShowEffects, bRecentHit;
	local BloodSpurt BloodHit;

	bRecentHit = Level.TimeSeconds - LastPainTime < 0.2;

	LastDamageAmount = Damage;

	OldPlayHit(Damage,InstigatedBy,HitLocation,DamageType,Momentum);

	if ( Damage <= 0 )
		return;

	NoteBlast(Damage, DamageType);

	if( Health>0 && Damage>(float(Default.Health)/1.5) )
		FlipOver();

	PC = PlayerController(Controller);
	bShowEffects = ( (Level.NetMode != NM_Standalone) || (Level.TimeSeconds - LastRenderTime < 2.5)
					|| ((InstigatedBy != None) && (PlayerController(InstigatedBy.Controller) != None))
					|| (PC != None) );
	if ( !bShowEffects )
		return;

	if ( BurnDown > 0 && !bBurnified )
		bBurnified = true;

	HitRay = vect(0,0,0);
	if( InstigatedBy != None )
		HitRay = Normal(HitLocation-(InstigatedBy.Location+(vect(0,0,1)*InstigatedBy.EyeHeight)));

	if( DamageType.default.bLocationalHit )
		CalcHitLoc( HitLocation, HitRay, HitBone, HitBoneDist );
	else
	{
		HitLocation = Location ;
		HitBone = 'None';
		HitBoneDist = 0.0f;
	}

	if( DamageType.default.bAlwaysSevers && DamageType.default.bSpecial )
		HitBone = HeadBone;

	// what comes off flies away from a blast, not away from whoever set it off
	if ( !DamageType.default.bLocationalHit && Momentum != vect(0,0,0) )
		HitNormal = Normal( -Normal(Momentum) + VRand() * 0.2 + vect(0,0,2.8) );
	else if( InstigatedBy != None )
		HitNormal = Normal( Normal(InstigatedBy.Location-HitLocation) + VRand() * 0.2 + vect(0,0,2.8) );
	else
		HitNormal = Normal( Vect(0,0,1) + VRand() * 0.2 + vect(0,0,2.8) );

	//log("HitLocation "$Hitlocation) ;

	if ( DamageType.Default.bCausesBlood && DamageType != class 'Burned' && DamageType != class 'DamTypeFlamethrower')
	{
		if ( class'GameInfo'.static.UseLowGore() )
		{
			if ( class'GameInfo'.static.NoBlood() )
				BloodHit = BloodSpurt(Spawn( GibGroupClass.default.NoBloodHitClass,InstigatedBy,, HitLocation ));
			else
				BloodHit = BloodSpurt(Spawn( GibGroupClass.default.LowGoreBloodHitClass,InstigatedBy,, HitLocation ));
		}
		else
		{
			BloodHit = BloodSpurt(Spawn(BloodClassFor(Damage),InstigatedBy,, HitLocation, Rotator(HitNormal)));
			ExitBurst(Damage, InstigatedBy, HitLocation, DamageType, Momentum, HitRay);
		}
		if ( BloodHit != None )
		{
			BloodHit.bMustShow = !bRecentHit;
			if ( Momentum != vect(0,0,0) )
			{
				BloodHit.HitDir = Momentum;
				LastBloodHitDirection = BloodHit.HitDir;
			}
			else
			{
				if ( InstigatedBy != None )
					BloodHit.HitDir = Location - InstigatedBy.Location;
				else
					BloodHit.HitDir = Location - HitLocation;
				BloodHit.HitDir.Z = 0;
			}
		}
	}

	if ( Health <= 0 && !bDeathGoreDone )
	{
		bDeathGoreDone = true;
		DeathGore(HitBone, Damage, DamageType, InstigatedBy, Rotator(HitNormal));
	}
	// the rest of a blast that killed has been counted already; its late pellets add nothing
	else if ( Health > 0 || !IsPowerHit(DamageType) || Level.TimeSeconds - BlastKillTime > BlastWindow )
		DoDamageFX( HitBone, Damage, DamageType, Rotator(HitNormal) );

	if (DamageType.default.DamageOverlayMaterial != None && Damage > 0 ) // additional check in case shield absorbed
		SetOverlayMaterial( DamageType.default.DamageOverlayMaterial, DamageType.default.DamageOverlayTime, false );
}

// The blood off a hit is as big as the hit
function class<Actor> BloodClassFor( float Damage )
{
	if ( Damage >= HeavyHitDamage && HeavyBloodClass != None )
		return HeavyBloodClass;
	return GibGroupClass.default.BloodHitClass;
}

// A power weapon, or any one great blow, bursts out of the far side of the body as well: once for a
// blast, however many pellets it came as.
function ExitBurst( float Damage, Pawn InstigatedBy, vector HitLocation, class<DamageType> DamageType, vector Momentum, vector HitRay )
{
	local vector Dir, Flat, Spot;
	local BloodSpurt Burst;

	if ( BurstBloodClass == None || Level.TimeSeconds - LastBurstTime < 0.3 )
		return;
	if ( IsPowerHit(DamageType) )
	{
		if ( Health > 0 && BlastDamage < BurstBlastDamage )
			return;
	}
	else if ( Damage < BurstHitDamage )
		return;

	Dir = Momentum;
	if ( Dir == vect(0,0,0) )
		Dir = HitRay;
	if ( Dir == vect(0,0,0) )
		return;
	Dir = Normal(Dir);
	// out of the far side, at the height it went in
	Flat = Dir * vect(1,1,0);
	if ( VSize(Flat) > 0.3 )
	{
		Spot = Location + 0.8 * CollisionRadius * Normal(Flat);
		Spot.Z = FClamp(HitLocation.Z, Location.Z - 0.5 * CollisionHeight, Location.Z + 0.8 * CollisionHeight);
	}
	else Spot = HitLocation + CollisionRadius * Dir;

	Burst = BloodSpurt(Spawn(BurstBloodClass, InstigatedBy,, Spot, rotator(Dir)));
	if ( Burst != None )
	{
		Burst.bMustShow = true;
		Burst.HitDir = Dir;
	}
	LastBurstTime = Level.TimeSeconds;
}

// A stun lasts until StunTime. (It used to borrow the timer the burn damage runs on: each blow that stunned
// put the next burn off, and each burn ended the stun early.)
function bool Stunned()
{
	if( bSTUNNED && Level.TimeSeconds >= StunTime )
		bSTUNNED = false;
	return bSTUNNED;
}

function PlayDirectionalHit(Vector HitLoc)
{
	local Vector X,Y,Z, Dir;

	// (the flag was only read by a hit test no weapon uses any more)
	if( bMeleeStunImmune && ClassIsChildOf(LastDamagedbyType,class'DamTypeMelee') )
		return;

	GetAxes(Rotation, X,Y,Z);
	HitLoc.Z = Location.Z;
	Dir = -Normal(Location - HitLoc);

	// random
	if ( VSize(Location - HitLoc) < 1.0 )
		Dir = VRand();
	else Dir = -Normal(Location - HitLoc);

	if ( Dir Dot X > 0.7 || Dir == vect(0,0,0))
	{
		if( LastDamagedBy!=none && LastDamageAmount>0 )
			// (a melee blow that has landed was in reach. The test used to go by the specimen's own reach,
			// so a knife at arm's length did not stun a clot.)
			if (ClassIsChildOf(LastDamagedbyType,class 'DamTypeMelee')
			 && LastDamageAmount > (0.10* default.Health) || LastDamageAmount >= (0.5 * default.Health) )
			{
				SetAnimAction(HitAnims[Rand(3)]);
				bSTUNNED = true;
				StunTime = Level.TimeSeconds + 1.0;
			}
		else SetAnimAction(KFHitFront);
	}
	else if ( Dir Dot X < -0.7 )
		SetAnimAction(KFHitBack);
	else if ( Dir Dot Y > 0 )
		SetAnimAction(KFHitRight);
	else SetAnimAction(KFHitLeft);
}

simulated function HideBone(name boneName)
{
	local int Slot;

	Slot = SeverSlot(boneName);
	if ( Slot >= 0 )
		SetBoneScale(Slot, 0.0, boneName);
}


simulated function PlayDirectionalDeath(Vector HitLoc); // Death animation replaced with ragdoll.

//TODO - log this to hell to find the last ANs,
//	   and look to consolidate any duplicate code,
//	   including multiple !=nones for the same target
function bool MeleeDamageTarget(int hitdamage, vector pushdir)
{
	local vector HitLocation, HitNormal;
	local actor HitActor;
	local Name TearBone;
	local Float dummy;
	local Emitter BloodHit;

	if( Level.NetMode==NM_Client || Controller==None )
		Return False; // Never should be done on client.
	if ( KFHumanPawnZombies(Controller.Target)!=none && KFHumanPawnZombies(Controller.Target).bIsDowned )
	{
		Controller.Target = None;
		Controller.Enemy = None;
		Return False;
	}
	if ( Controller.Target!=none && (Controller.Target.IsA('KFDoorMover') || Controller.Target.IsA('KFBarricadePlank')) )
	{
		Controller.Target.TakeDamage(hitdamage, self ,HitLocation,pushdir, CurrentDamType);
		Return True;
	}

	// check if still in melee range
	if ( (Controller.target != None) && !Stunned() && (DECAP == false) && (VSize(Controller.Target.Location - Location) <= MeleeRange * 1.4 + Controller.Target.CollisionRadius + CollisionRadius)
		&& ((Physics == PHYS_Flying) || (Physics == PHYS_Swimming) || (Abs(Location.Z - Controller.Target.Location.Z)
			<= FMax(CollisionHeight, Controller.Target.CollisionHeight) + 0.5 * FMin(CollisionHeight, Controller.Target.CollisionHeight))) )
	{
		HitActor = Trace(HitLocation, HitNormal, Controller.Target.Location, Location, false);
		if ( HitActor != None )
			return false;


	  if ((Controller.target != None) && KFHumanPawn(Controller.Target)!=none)
	  {
	   //TODO - line below was KFPawn. Does this whole block need to be KFPawn, or is it OK as KFHumanPawn?
	   KFHumanPawn(Controller.Target).TakeDamage(hitdamage, Instigator ,HitLocation,pushdir, CurrentDamType); //class 'KFmod.ZombieMeleeDamage');

		  if (KFHumanPawn(Controller.Target).Health <=0)
		  {
		   BloodHit = Spawn(class'KFMod.FeedingSpray',self,,Controller.Target.Location,rotator(pushdir));	 //
		   KFHumanPawn(Controller.Target).SpawnGibs(rotator(pushdir), 1);
		   TearBone=KFHumanPawn(Controller.Target).GetClosestBone(HitLocation,Velocity,dummy);
		   KFHumanPawn(Controller.Target).HideBone(TearBone);

		   // Give us some Health back

		   if (Health <= (1.0-FeedThreshold)*HealthMax)
		   {
			 Health += FeedThreshold*HealthMax * Health/HealthMax;
		   }
		  }

	  }
		else if (Controller.target != None)
		{
			// Do more damage if you are attacking another zed so that zeds don't just stand there whacking each other forever! - Ramm
            if( KFMonster(Controller.Target) != none )
			{
                hitdamage *= 3;
			}
			Controller.Target.TakeDamage(hitdamage, self ,HitLocation,pushdir, CurrentDamType); //class 'KFmod.ZombieMeleeDamage');
		}
		return true;
	}
	return false;
}

simulated function PlayFakeDyingAnimation(class<DamageType> DamageType, vector HitLoc)
{
	local vector shotDir, hitLocRel, deathAngVel, shotStrength;
	local float maxDim;
	local string RagSkelName;
	local KarmaParamsSkel skelParams;
	local bool PlayersRagdoll;
	local PlayerController pc;

	if ( Level.NetMode != NM_DedicatedServer )
	{
		// Is this the local player's ragdoll?
		if(OldController != None)
			pc = PlayerController(OldController);
		if( pc != None && pc.ViewTarget == self )
			PlayersRagdoll = true;

		// Try and obtain a rag-doll setup. Use optional 'override' one out of player record first, then use the species one.
		if( RagdollOverride != "")
			RagSkelName = RagdollOverride;
		else if(Species != None)
			RagSkelName = Species.static.GetRagSkelName( GetMeshName() );
		else RagSkelName = "Male1"; // Otherwise assume it is Male1 ragdoll were after here.

		KMakeRagdollAvailable();

		if( KIsRagdollAvailable() && RagSkelName != "" )
		{
			skelParams = KarmaParamsSkel(KParams);
			skelParams.KSkeleton = RagSkelName;

			// Stop animation playing.
			StopAnimating(true);

			if( DamageType != None )
			{
				if ( DamageType.default.bLeaveBodyEffect )
					TearOffMomentum = vect(0,0,0);

				if( DamageType.default.bKUseOwnDeathVel )
				{
					RagDeathVel = DamageType.default.KDeathVel;
					RagDeathUpKick = DamageType.default.KDeathUpKick;
				}
			}

			// Set the dude moving in direction he was shot in general
			shotDir = Normal(TearOffMomentum);
			shotStrength = RagDeathVel * shotDir;

			// Calculate angular velocity to impart, based on shot location.
			hitLocRel = TakeHitLocation - Location;

			// We scale the hit location out sideways a bit, to get more spin around Z.
			hitLocRel.X *= RagSpinScale;
			hitLocRel.Y *= RagSpinScale;

			// If the tear off momentum was very small for some reason, make up some angular velocity for the pawn
			if( VSize(TearOffMomentum) < 0.01 )
			{
				//Log("TearOffMomentum magnitude of Zero");
				deathAngVel = VRand() * 18000.0;
			}
			else deathAngVel = RagInvInertia * (hitLocRel Cross shotStrength);

			// Set initial angular and linear velocity for ragdoll.
			// Scale horizontal velocity for characters - they run really fast!
			if ( DamageType.Default.bRubbery )
				skelParams.KStartLinVel = vect(0,0,0);
			if ( Damagetype.default.bKUseTearOffMomentum )
				skelParams.KStartLinVel = TearOffMomentum + Velocity;
			else
			{
				skelParams.KStartLinVel.X = 0.6 * Velocity.X;
				skelParams.KStartLinVel.Y = 0.6 * Velocity.Y;
				skelParams.KStartLinVel.Z = 1.0 * Velocity.Z;
				skelParams.KStartLinVel += shotStrength;
			}
			// If not moving downwards - give extra upward kick
			if( !DamageType.default.bLeaveBodyEffect && !DamageType.Default.bRubbery && (Velocity.Z > -10) )
				skelParams.KStartLinVel.Z += RagDeathUpKick;

			if ( DamageType.Default.bRubbery )
			{
				Velocity = vect(0,0,0);
				skelParams.KStartAngVel = vect(0,0,0);
			}
			else
			{
				skelParams.KStartAngVel = deathAngVel;

				// Set up deferred shot-bone impulse
				maxDim = Max(CollisionRadius, CollisionHeight);

				skelParams.KShotStart = TakeHitLocation - (1 * shotDir);
				skelParams.KShotEnd = TakeHitLocation + (2*maxDim*shotDir);
				skelParams.KShotStrength = RagShootStrength;
			}

			// If this damage type causes convulsions, turn them on here.
			if(DamageType != None && DamageType.default.bCauseConvulsions)
			{
				RagConvulseMaterial=DamageType.default.DamageOverlayMaterial;
				skelParams.bKDoConvulsions = true;
			}

			// Turn on Karma collision for ragdoll.
			KSetBlockKarma(true);

			// Set physics mode to ragdoll.
			// This doesn't actaully start it straight away, it's deferred to the first tick.
			SetPhysics(PHYS_KarmaRagdoll);

			// If viewing this ragdoll, set the flag to indicate that it is 'important'
			if( PlayersRagdoll )
				skelParams.bKImportantRagdoll = true;

			skelParams.bRubbery = DamageType.Default.bRubbery;
			bRubbery = DamageType.Default.bRubbery;

			skelParams.KActorGravScale = RagGravScale;

			WakeBodiesNear();

			return;
		}
		// jag
	}

}

simulated function PlayDyingAnimation(class<DamageType> DamageType, vector HitLoc)
{
	local vector shotDir, hitLocRel, deathAngVel, shotStrength;
	local float maxDim;
	local string RagSkelName;
	local KarmaParamsSkel skelParams;
	local bool PlayersRagdoll;
	local PlayerController pc;

	if( MyExtCollision!=None )
		MyExtCollision.Destroy();
	if( MyHeadCollision!=None )
		MyHeadCollision.Destroy();
	if ( Level.NetMode != NM_DedicatedServer )
	{
		// Is this the local player's ragdoll?
		if(OldController != None)
			pc = PlayerController(OldController);
		if( pc != None && pc.ViewTarget == self )
			PlayersRagdoll = true;

				// In low physics detail, if we were not just controlling this pawn,
		// and it has not been rendered in 3 seconds, just destroy it.

		if( Level.NetMode == NM_ListenServer )
		{
			// For a listen server, use LastSeenOrRelevantTime instead of render time so
			// monsters don't disappear for other players that the host can't see - Ramm
			if( Level.PhysicsDetailLevel != PDL_High && !PlayersRagdoll && (Level.TimeSeconds-Controller.LastSeenTime)>3 ||
				bPlayGoreSplash )
			{
    			// Wait a tick on a listen server so the obliteration can replicate before the pawn is destroyed
                if( Level.NetMode == NM_ListenServer )
    			{
                    bDestroyNextTick = true;
                    TimeSetDestroyNextTickTime = Level.TimeSeconds;
                }
                else
                {
                    Destroy();
    			}
				return;
			}
		}
		else if( Level.PhysicsDetailLevel!=PDL_High && !PlayersRagdoll && (Level.TimeSeconds-LastRenderTime)>3 ||
			bPlayGoreSplash)
		{
			// Wait a tick on a listen server so the obliteration can replicate before the pawn is destroyed
            if( Level.NetMode == NM_ListenServer )
			{
                bDestroyNextTick = true;
                TimeSetDestroyNextTickTime = Level.TimeSeconds;
            }
            else
            {
                Destroy();
			}
			return;
		}


		// Try and obtain a rag-doll setup. Use optional 'override' one out of player record first, then use the species one.
		if( RagdollOverride != "")
			RagSkelName = RagdollOverride;
		else if(Species != None)
			RagSkelName = Species.static.GetRagSkelName( GetMeshName() );
		else RagSkelName = "Male1"; // Otherwise assume it is Male1 ragdoll were after here.

		KMakeRagdollAvailable();

		if( KIsRagdollAvailable() && RagSkelName != "" )
		{
			skelParams = KarmaParamsSkel(KParams);
			skelParams.KSkeleton = RagSkelName;

			// Stop animation playing.
			StopAnimating(true);

			if( DamageType != None )
			{
				if ( DamageType.default.bLeaveBodyEffect )
					TearOffMomentum = vect(0,0,0);

				if( DamageType.default.bKUseOwnDeathVel )
				{
					RagDeathVel = DamageType.default.KDeathVel;
					RagDeathUpKick = DamageType.default.KDeathUpKick;
				}
			}

			// Set the dude moving in direction he was shot in general
			shotDir = Normal(TearOffMomentum);
			shotStrength = RagDeathVel * shotDir;

			// Calculate angular velocity to impart, based on shot location.
			hitLocRel = TakeHitLocation - Location;

			// We scale the hit location out sideways a bit, to get more spin around Z.
			hitLocRel.X *= RagSpinScale;
			hitLocRel.Y *= RagSpinScale;

			// If the tear off momentum was very small for some reason, make up some angular velocity for the pawn
			if( VSize(TearOffMomentum) < 0.01 )
			{
				//Log("TearOffMomentum magnitude of Zero");
				deathAngVel = VRand() * 18000.0;
			}
			else deathAngVel = RagInvInertia * (hitLocRel Cross shotStrength);

			// Set initial angular and linear velocity for ragdoll.
			// Scale horizontal velocity for characters - they run really fast!
			if ( DamageType.Default.bRubbery )
				skelParams.KStartLinVel = vect(0,0,0);
			if ( Damagetype.default.bKUseTearOffMomentum )
				skelParams.KStartLinVel = TearOffMomentum + Velocity;
			else
			{
				skelParams.KStartLinVel.X = 0.6 * Velocity.X;
				skelParams.KStartLinVel.Y = 0.6 * Velocity.Y;
				skelParams.KStartLinVel.Z = 1.0 * Velocity.Z;
				skelParams.KStartLinVel += shotStrength;
			}
			// If not moving downwards - give extra upward kick
			if( !DamageType.default.bLeaveBodyEffect && !DamageType.Default.bRubbery && (Velocity.Z > -10) )
				skelParams.KStartLinVel.Z += RagDeathUpKick;

			if ( DamageType.Default.bRubbery )
			{
				Velocity = vect(0,0,0);
				skelParams.KStartAngVel = vect(0,0,0);
			}
			else
			{
				skelParams.KStartAngVel = deathAngVel;

				// Set up deferred shot-bone impulse
				maxDim = Max(CollisionRadius, CollisionHeight);

				skelParams.KShotStart = TakeHitLocation - (1 * shotDir);
				skelParams.KShotEnd = TakeHitLocation + (2*maxDim*shotDir);
				skelParams.KShotStrength = RagShootStrength;
			}

			// If this damage type causes convulsions, turn them on here.
			if(DamageType != None && DamageType.default.bCauseConvulsions)
			{
				RagConvulseMaterial=DamageType.default.DamageOverlayMaterial;
				skelParams.bKDoConvulsions = true;
			}

			// Turn on Karma collision for ragdoll.
			KSetBlockKarma(true);

			// Set physics mode to ragdoll.
			// This doesn't actaully start it straight away, it's deferred to the first tick.
			SetPhysics(PHYS_KarmaRagdoll);

			// If viewing this ragdoll, set the flag to indicate that it is 'important'
			if( PlayersRagdoll )
				skelParams.bKImportantRagdoll = true;

			skelParams.bRubbery = DamageType.Default.bRubbery;
			bRubbery = DamageType.Default.bRubbery;

			skelParams.KActorGravScale = RagGravScale;

			WakeBodiesNear();

			return;
		}
		// jag
	}
	// non-ragdoll death fallback
	Velocity += TearOffMomentum;
	BaseEyeHeight = Default.BaseEyeHeight;
	SetTwistLook(0, 0);
	SetInvisibility(0.0);
	PlayDirectionalDeath(HitLoc);
	SetPhysics(PHYS_Falling);
}

// Give zombies forward momentum with jumps.
function bool DoJump( bool bUpdating )
{
	if ( !bIsCrouched && !bWantsToCrouch && ((Physics == PHYS_Walking) || (Physics == PHYS_Ladder) || (Physics == PHYS_Spider)) )
	{
		PlayOwnedSound(ZJumpSound, SLOT_Pain, GruntVolume,,80);

		if ( Role == ROLE_Authority )
		{
			if ( (Level.Game != None) && (Level.Game.GameDifficulty > 2) )
				MakeNoise(0.1 * Level.Game.GameDifficulty);
			if ( bCountJumps && (Inventory != None) )
				Inventory.OwnerEvent('Jumped');
		}
		if ( Physics == PHYS_Spider )
			Velocity = JumpZ * Floor;
		else if ( Physics == PHYS_Ladder )
			Velocity.Z = 0;
		else if ( bIsWalking )
		{
			Velocity.Z = Default.JumpZ;
			Velocity.X = (Default.JumpZ * 0.5);
		}
		else
		{
			Velocity.Z = JumpZ;
			Velocity.X = (JumpZ * 0.5);
		}

		if ( (Base != None) && !Base.bWorldGeometry )
		{
			Velocity += Base.Velocity;
		}
		SetPhysics(PHYS_Falling);
		return true;
	}
	return false;
}

simulated function Destroyed()
{
	local int i;

	if( MyExtCollision!=None )
		MyExtCollision.Destroy();
	if( MyHeadCollision!=None )
		MyHeadCollision.Destroy();
	if( PlayerShadow != None )
		PlayerShadow.Destroy();
	if( FlamingFXs!=None )
		FlamingFXs.Destroy();

	if(RealtimeShadow !=none)
		RealtimeShadow.Destroy();

	for ( i=0; i<ArrayCount(Stumps); i++ )
		DropStump(i);
	RemoveFlamingEffects();
	// (what smoke there is hangs a moment where the body was)
	if ( CorpseSmoke != None )
		CorpseSmoke.Kill();
	if ( NeckJet != None )
		NeckJet.Destroy();
	FreeChar();
	Super.Destroyed();
}

// Burnt through. The burnt skin itself comes in by degrees on each machine that draws the body (TickChar).
simulated function ZombieCrispUp()
{
	bAshen = true;
}

function TakeFireDamage(int Damage,pawn Instigator)
{
	local Vector DummyHitLoc,DummyMomentum;

    if (bDeleteMe || Health <= 0 || bPlayedDeath)
        return;

	//Log("Burned");
	TakeDamage(Damage,BurnInstigator,DummyHitLoc,DummyMomentum,class 'DamTypeFlamethrower');
	if (BurnDown > 0)
		BurnDown --; // Decrement the number of FireDamage calls left before our Zombie is extinguished :)

	// Melt em' :)
	if (BurnDown < 5)
		ZombieCrispUp();

	if(BurnDown==0)
	{
		bBurnified = false;
		// back to its own speed (one in a state that keeps its own speed sets it again on leaving it)
		if ( CanSpeedAdjust() )
			SetGroundSpeed(OriginalGroundSpeed);
	}
}

// We can add blood streak decals here, as the Actor's body moves in Ragdoll
event KImpact(actor other, vector pos, vector impactVel, vector impactNorm)
{
	local int numSounds, soundNum;
	local vector WallHit, WallNormal;
	local Actor WallActor;
	local Vector HitDir;
	local KFBloodStreakDecal Streak;

	//Log(VSize(Velocity));
	BloodStreakInterval -= (0.001 * VSize(Velocity));

	HitDir = LastBloodHitDirection;
	numSounds = RagImpactSounds.Length;

	if ( HitDir == vect(0,0,0) )
	{
		if ( Owner != None )
			HitDir = Location - Owner.Location;
		else
			HitDir.Z = -1;
	}
	HitDir = Normal(HitDir);

	WallActor = Trace(WallHit, WallNormal, Location + 50 * Velocity, Location, false);
	if ( WallActor != None && Level.TimeSeconds > LastStreakTime + BloodStreakInterval
		&& Level.TimeSeconds - LastRenderTime < 1.0 )
	{
		Streak= spawn(class 'KFMod.KFBloodStreakDecal',,,WallHit + 20 * (WallNormal + VRand()), rotator(-WallNormal));
		if (Streak != none)
			Streak.SetRotation(Rotator(Velocity));
		LastStreakTime = Level.TimeSeconds;
	}

	//log("ouch! iv:"$VSize(impactVel));
	if(numSounds > 0 && Level.TimeSeconds > RagLastSoundTime + RagImpactSoundInterval)
	{
		soundNum = Rand(numSounds);
		//Log("Play Sound:"$soundNum);
		PlaySound(RagImpactSounds[soundNum], SLOT_Pain, RagImpactVolume);
		RagLastSoundTime = Level.TimeSeconds;
	}
}


simulated function AttachEmitterEffect( class<Emitter> EmitterClass, Name BoneName, Vector Location, Rotator Rotation )
{
	local Actor a;
	local int i;

	if( Level.NetMode==NM_DedicatedServer || bSkeletized || (BoneName == 'None') )
		return;

	for( i = 0; i < Attached.Length; i++ )
	{
		if( Attached[i] == None )
			continue;

		if( Attached[i].AttachmentBone != BoneName )
			continue;

		if( ClassIsChildOf( EmitterClass, Attached[i].Class ) )
			return;
	}

	a = Spawn( EmitterClass,,, Location, Rotation );

	if( !AttachToBone( a, BoneName ) )
	{
		a.Destroy();
		return;
	}

	for( i = 0; i < Attached.length; i++ )
	{
		if( Attached[i] == a )
			break;
	}

	a.SetRelativeRotation( Rotation );
}

simulated function RemoveFlamingEffects()
{
	local int i;

	if ( Level.NetMode == NM_DedicatedServer )
	{
		return;
	}

	for ( i = 0; i < Attached.length; i++ )
	{
		if ( xEmitter(Attached[i]) != none )
		{
			xEmitter(Attached[i]).mRegen = false;
			Attached[i].LifeSpan = 2;
		}
		else if ( Emitter(Attached[i]) != None && ClassIsChildOf(Attached[i].Class, BurnEffect) )
		{
			Emitter(Attached[i]).Kill();
			Attached[i].LifeSpan = 2;
		}
	}
}

simulated function TurnOff()
{
	RemoteRole = ROLE_SimulatedProxy;
}

// this could have been responsible for making the zombies "lethargic" in wander state.
// they should retain the same walk speed at all times.
event SetWalking(bool bNewIsWalking);

function Trigger( actor Other, pawn EventInstigator )
{
	if( Controller!=None )
		Controller.Trigger(Other,EventInstigator);
}

// Laught at victory of boss battle.
function bool SetBossLaught()
{
	Return False; // Normal zeds have no feelings..
}

// Hack to prevent zed gibbing
event EncroachedBy( actor Other )
{
	if ( Pawn(Other)!=None && Vehicle(Other)==None && KFPawn(Other)==None && KFMonster(Other)==None )
	{
		gibbedBy(Other);
		log(GetHumanReadableName()$ " was gibbed by " $Other.GetHumanReadableName());
	}
}

defaultproperties
{
     CrowdShrinkFactor=0.700000
     CrowdShrinkMinRadius=12.000000
     CrowdShrinkRestoreDelay=1.000000
     bCrowdRoomCheck=True
     MeleeAnims(0)="Claw"
     MeleeAnims(1)="Claw2"
     MeleeAnims(2)="Claw3"
     HitAnims(0)="HitF"
     HitAnims(1)="HitF2"
     HitAnims(2)="HitF3"
     BileFrequency=0.500000
     KFHitFront="HitReactionF"
     KFHitBack="HitReactionB"
     KFHitLeft="HitReactionL"
     KFHitRight="HitReactionR"
     HeadStubClass=Class'KFMod.GibHeadStump'
     GibScale=1.000000
     LimbBlast=0.600000
     TorsoBlast=1.500000
     BodyBlast=2.500000
     BlastWindow=0.250000
     CorpseGibHealth=-400
     LimbJoints(0)="Bip01 L UpperArm"
     LimbJoints(1)="Bip01 L Forearm"
     LimbJoints(2)="Bip01 R UpperArm"
     LimbJoints(3)="Bip01 R Forearm"
     LimbJoints(4)="Bip01 L Thigh"
     LimbJoints(5)="Bip01 L Calf"
     LimbJoints(6)="Bip01 R Thigh"
     LimbJoints(7)="Bip01 R Calf"
     LimbEnds(0)="Bip01 L Forearm"
     LimbEnds(1)="Bip01 L Hand"
     LimbEnds(2)="Bip01 R Forearm"
     LimbEnds(3)="Bip01 R Hand"
     LimbEnds(4)="Bip01 L Calf"
     LimbEnds(5)="Bip01 L Foot"
     LimbEnds(6)="Bip01 R Calf"
     LimbEnds(7)="Bip01 R Foot"
     StumpSize(0)=1.800000
     StumpSize(1)=1.800000
     StumpSize(2)=0.850000
     StumpSize(3)=0.850000
     StumpSize(4)=1.000000
     StumpSize(5)=2.300000
     StumpSize(6)=1.100000
     StumpSize(7)=1.100000
     StumpSize(8)=1.100000
     StumpSize(9)=1.100000
     MaxSpineVariation=1000
     MaxContortionPercentage=0.250000
     MinTimeBetweenPainAnims=0.500000
     playedHit=True
     FeedThreshold=0.100000
     CorpseLifeSpan=60.000000
     ZombieDamType(0)=Class'KFMod.ZombieMeleeDamage'
     ZombieDamType(1)=Class'KFMod.ZombieMeleeDamage'
     ZombieDamType(2)=Class'KFMod.ZombieMeleeDamage'
     BurnEffect=Class'KFMod.KFMonsterFlame'
     PuntAnim="PoundPunt"
     BloodStreakInterval=0.500000
     MonsterHeadGiblet=Class'KFMod.ClotGibHead'
     MonsterThighGiblet=Class'KFMod.ClotGibThigh'
     MonsterArmGiblet=Class'KFMod.ClotGibArm'
     MonsterLegGiblet=Class'KFMod.ClotGibLeg'
     MonsterTorsoGiblet=Class'KFMod.ClotGibTorso'
     MonsterLowerTorsoGiblet=Class'KFMod.ClotGibLowerTorso'
     Intelligence=BRAINS_Human
     DeathAnim(0)=
     DeathAnim(1)=
     DeathAnim(2)=
     DeathAnim(3)=
     bCanDodge=False
     DeathSound(0)=Sound'KFPlayerSound.ZombieDie1'
     DeathSound(1)=Sound'KFPlayerSound.ZombieDie2'
     DeathSound(2)=Sound'KFPlayerSound.ZombieDie3'
     DeathSound(3)=Sound'KFPlayerSound.ZombieDie4'
	 DecapSound=Sound'KFPawnDamageSound.MeleeDamageSounds.bathitflesh3'
     ChallengeSound(0)=None
     ChallengeSound(1)=None
     ChallengeSound(2)=None
     ChallengeSound(3)=None
     GruntVolume=50.000000
     FootstepVolume=1.000000
     GibGroupClass=Class'KFMod.KFGibGroup'
     SoundGroupClass=Class'KFMod.KFMaleZombieSounds'
     IdleHeavyAnim="Idle_LargeZombie"
     IdleRifleAnim="Idle_LargeZombie"
     FireHeavyRapidAnim="MeleeAttack"
     FireHeavyBurstAnim="MeleeAttack"
     FireRifleRapidAnim="MeleeAttack"
     FireRifleBurstAnim="MeleeAttack"
     DeResTime=6.000000
     DeResMat0=Texture'KFCharacters.KFDeRez'
     DeResMat1=Texture'KFCharacters.KFDeRez'
     DeResLiftVel=(Points=(,(InVal=0.000000,OutVal=0.000000),(InVal=0.000000,OutVal=0.000000)))
     DeResLiftSoftness=(Points=((OutVal=0.000000),(InVal=0.000000,OutVal=0.000000),(InVal=0.000000,OutVal=0.000000)))
     DeResLateralFriction=0.000000
     RagdollLifeSpan=30.000000
     SettleSpeed=5.000000
     SettleChecksNeeded=2
     RagDeathVel=150.000000
     RagShootStrength=6000.000000
     RagDeathUpKick=170.000000
     RagGravScale=1.500000
     RequiredEquipment(0)="none"
     RequiredEquipment(1)="none"
     bCanSwim=False
     bCanStrafe=False
     bSameZoneHearing=True
     bAdjacentZoneHearing=True
     bMuffledHearing=True
     bAroundCornerHearing=True
     bCanUse=False
     HearingThreshold=20000.000000
     Alertness=1.000000
     SightRadius=20000.000000
     PeripheralVision=-1.000000
     SkillModifier=5.000000
     MeleeRange=50.000000
     JumpZ=320.000000
     WalkingPct=1.000000
     CrouchedPct=1.000000
	 HiddenGroundSpeed=275.000000
	 BurnSpeedScale=0.800000
	 CharTime=5.000000
	 CorpseBurnTime=6.000000
	 CorpseSmokeClass=Class'KFMod.KFCorpseSmoke'
	 HeavyBloodClass=Class'KFMod.KFBloodPuffHeavy'
	 BurstBloodClass=Class'KFMod.KFBloodBurst'
	 HeavyHitDamage=50
	 BurstHitDamage=150
	 BurstBlastDamage=60.000000
	 NeckJetClass=Class'KFMod.KFNeckJet'
	 DripDecalClass=Class'KFMod.KFBloodTrailDrop'
	 MaxDrips=7
	 DripSpacing=75.000000
	 RunAnim="ZombieRun"
	 RunAnimSpeedThreshold=170.000000
     MaxFallSpeed=2500.000000
     //HeadRadius=7.000000
	 HeadScale=1.100000
	 //HeadHeight=6.000000
	 HeadHealth=50.000000
	 BleedOutDuration=6.0
     ControllerClass=Class'KFMod.KFMonsterController'
     TurnLeftAnim="TurnLeft"
     TurnRightAnim="TurnRight"
     IdleCrouchAnim="Idle_LargeZombie"
     IdleWeaponAnim="Idle_LargeZombie"
     IdleRestAnim="Idle_LargeZombie"
     bDramaticLighting=False
     AmbientGlow=0
     bFullVolume=True
     SoundRadius=80.000000
     TransientSoundVolume=100.000000
     CollisionRadius=24.000000
     bBlockKarma=True
     Mass=300.000000
     Begin Object Class=KarmaParamsSkel Name=PawnKParams
         KConvulseSpacing=(Max=2.200000)
         KLinearDamping=0.150000
         KAngularDamping=0.050000
         KBuoyancy=1.000000
         KStartEnabled=True
         KVelDropBelowThreshold=50.000000
         bHighDetailOnly=False
         KFriction=0.600000
         KRestitution=0.300000
         KImpactThreshold=250.000000
     End Object
     KParams=KarmaParamsSkel'KFMod.KFMonster.PawnKParams'

}
