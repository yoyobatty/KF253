// Base Zombie Class.
Class KFMonster extends Skaarj
	hidecategories(AnimTweaks,DeRes,Force,Gib,Karma,Udamage,UnrealPawn)
	Abstract;

#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax
#exec OBJ LOAD FILE=PatchSounds.uax
#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
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
// Health and damage by difficulty: Easy, Normal, Skilled, Elite, Suicidal (retail Killing Floor's Beginner to Hell on Earth)
var() float DifficultyHealthScales[5], DifficultyDamageScales[5];
var bool bLastHitHead;				// the last blow that hurt us was a headshot
var bool bNoHitPush;				// no push from a hit that leaves us alive, whatever it was (the Fleshpound)
var bool bHeadDirFix;				// (test switch) the Fleshpound's headshot test sees the shot's direction
var float NextHeadStaggerTime;		// when a melee headshot can stagger us again (HeadStagger)
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
var bool bPlayBrainSplash;
var vector TraumaRay;
var bool bCutBody;				// (each machine that draws it) cut through by KFTrauma: its skins are KFCutBody's (or KFHoleBody's)
var KFHoleBody HoleBody;		// (each machine that draws it) the holes right through it

// (KFTrauma.NoteWound, KFWound) The wounds hits leave, as the server tells every machine: the bone (of KFTrauma's
// fourteen), the kind, where the wound is cast from against the bone's axes, which way and its picture's top (both a
// hundred times over: a vector goes over the net in whole numbers), its size
struct WoundNote
{
	var byte Bone, Kind, Size;
	var vector Spot, Dir, Up;
};
var WoundNote WoundNotes[8];
var byte WoundTick, SimWoundTick;
var array<KFWound> Wounds;			// (each machine that draws it) the wounds on it, oldest first
var() int MaxWounds;				// ...no more than this many; the oldest goes
var float LastCavityTime, LastPelletWound;

// (Endless, Doom style) Knocked low, it staggers and glows, open for a few seconds to a glory kill: a blow by hand or the
// use key within reach tears it apart and gives the one who did it health, ammunition and armour (StartGlory, GloryKill)
var bool bGloryReady;
var bool bGloryDone;
var float GloryUntil;
var byte GloryFinish;					// how it comes apart (GloryGore)
var vector GloryFrom;					// where the one finishing it stood
var KFGloryGlow GloryGlow;			// (server) the line of the hit being dealt, for what it does to the head (HeadLossKind)		// every machine has been told the head is gone
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
var byte DeathElement;		// killed by an upgraded weapon: its element (KFElementDeath); shown so here
var float TurnedUntil;
var() bool bClimbs;			// climbs onto a table, a crate or a low wall in its way, no higher than itself and ClimbMax,
var() float ClimbMax;		// ...with no animation of its own: up the edge, then onto the top (StartClimb)
var() float ClimbSpeed, ClimbOverSpeed;
var byte ClimbStage;		// (1 rising, 2 stepping onto the top)
var vector ClimbTo, ClimbDir;
var float ClimbUntil;		// (the server: turned by a special ammo, it fights for the players until then: KFAmmoMod)
var bool bElementShown;
var class<Emitter> BurnEffect;  // The appearance of the flames we are attaching to our Zed.
var int LastBurnDamage; // Record the last amount of Fire damage the pawn suffered.
var bool bBurnTick;		// the harm being taken is its own burning (TakeFireDamage), not fresh fire
var() float BurnSpeedScale;				// a specimen on fire moves this much slower

// A body chars for as long as it burns: each machine drawing it lets the burnt skin come in over CharTime
// seconds of fire, and one the server calls burnt through (bAshen) always goes all the way.
var float CharLevel;					// how far the burnt skin has come in, 0 to 1
var() int AshCrumbleDamage;				// a blow this hard on a body burnt through crumbles it to ash (AshCrumble)
var bool bAshCrumbling;					// (AshCrumble) its giblets are ash: no blood (KFGib.Ashen)
var() float CharTime;
var bool bCharDone;
var Combiner CharSkins[4];				// the blend standing in for each skin on the way
var ConstantColor CharMask;				// how much of the skin is left
var array<Object> CharMade;				// from the level's pool, to be given back
var() float GibCharShare;				// giblets and stumps of a charred body char this share of the way

// The dead burn on for CorpseBurnTime seconds where they fall, or where fire reaches them, and then smoke
var() float CorpseBurnTime;
var float CorpseBurnEnd;				// when the fire on the body goes out; 0 for a body that is not burning
var bool bCorpseSmoked;
var Emitter CorpseSmoke;
var() class<Emitter> CorpseSmokeClass;

// Blood by the size of the hit: HeavyHitDamage and over gets the heavy puff. A blow of BurstHitDamage,
// or a power weapon that has done BurstBlastDamage in one blast, bursts out of the far side as well.
// A blade's hit is BladeBloodClass, whatever its size.
var() class<Actor> HeavyBloodClass, BurstBloodClass, BladeBloodClass;
var() int HeavyHitDamage, BurstHitDamage;
var() float BurstBlastDamage;
var float LastBurstTime;
var float LastMistTime, LastFleshSound;
var() class<BloodSpurt> MistBloodClass;		// a round's small mist out of the far side (ExitMist)
var() int MistHitDamage;					// ...from a hit of this much on
var() Sound FleshHitSounds[4];				// a round striking flesh
var() float FleshHitVolume;

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
var() float ObliterateShare;	// the most often a blast that kills with plenty to spare blows the body away (else it tears it up)
var() float OverkillShare;		// how often an arc flash, BFG or rail kill with plenty to spare blows the body away
var() float CorpseBlastGib;		// how often a blast blows a body that is down away (else it may tear a limb off)
var() float CorpseBlastLimb;	// ...how often it tears a limb off instead
var() float AshCrumbleChance;	// how often a hard blow on a body burnt through crumbles it to ash
var() float BlastThrowScale;	// a blast kill throws the body this much harder than its damage type says
var float BlastDamage, BlastTime, BlastKillTime;
var bool bDeathGoreDone;				// the killing blow has had its say
var() int CorpseGibHealth;				// a body knocked down to this health can be blown to pieces

// The blow a blade is striking now (KFMeleeFire.Strike): where it meets the body, which way it goes, the line
// of its edge, and the way the body is to be thrown if it dies of it (its length is how hard)
var vector BladeSpot, BladeMotion, BladeEdge, BladeThrow;
var float BladeTime;
var() float DownCutReach;				// a blade landing on a body lying down takes a part this near where it lands
var() float SmackSpeed;					// a body a blade has thrown smacks into what it hits this fast
var() int SmackMarks;					// smacks a thrown body has in it
var() array<Sound> SmackSounds;
var int SmacksLeft;
var float LastSmackTime;
var() bool bOwnLimbs;					// a limb or head that comes off is this specimen's own (KFLimbGib), not a clot's giblet

var bool bDiffAdjusted; // has this monster had it's stats adjusted for the server's difficulty? Do once.

var bool bCloaked;
var bool bSpotted; // if true , use the "revealed" shader, instead of the cloak effect
var Emitter FlamingFXs;
var bool bLootCarrier;		// (Endless) this one carries a power-up: it glows, and drops it where it dies (KFEndlessGameType.LootCheck)
var Emitter LootGlow;
var bool bZapped;			// struck by lightning just now (the upgraded flamethrower): held shaking where it stands, arcs all over it (Electrocute)
var float ZapUntil;
var Emitter ZapFX;
var float ZapSince, NextZapDrop;
var() float ZapDropAfter;	// in the current this long, an ordinary one goes down and convulses on the floor (BlastStagger)
var bool bZapDeath;			// electrocuted to death (by the lightning, or by anything while in the current): it seizes where it falls (KFZapDeath)
var bool bZapDeathShown;
var bool bBlueFire;			// set alight by the upgraded flamethrower: its fire burns blue, alive and dead (BlueBodyFire)
var bool bFrozen;			// frozen solid by the cryo cannon (Freeze): still as a statue, glazed with ice; killed, it shatters
var bool bFrozenShown;
var float FrozenUntil;
var() float FrozenDamageScale;	// frozen, it is brittle
var Material IceGlaze;		// (each machine that draws it) the glaze, made once for all (IceLook)
var float SoakFuel;			// fuel on it from the flamethrower's gas mode (Soak): it drips where it goes, and burns the harder
var Pawn SoakStarter;
var bool bSoaked;
var Emitter SoakFX;
var bool bBlueFireShown;

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

var KFLimbGib LastLimb;					// (ThrowLimb) the part it threw last
// (NoteSlash) the Executioner's flying cut about to strike: the plane its blade lies in, which way across it the blade
// reaches and how far, which way it flies, and when
var vector SlashSpot, SlashNormal, SlashAcross, SlashFly;
var float SlashHalfSpan, SlashTime;
var bool bSlashDebug;					// logs what the flying cut takes off
var() float SplitBand;					// an upright cut this near the middle of the trunk cleaves it from the head down
var float BFGHeld;						// (each machine that draws it) seconds a BFG ball has had this body in its grip
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
		bDecapitated,Gored,bBurnified,bAshen,FeedThreshold,bCannibal,bDiffAdjusted,bCloaked,DeathElement,bLootCarrier,bZapped,bZapDeath,bBlueFire,bSoaked,bFrozen;
	reliable if(Role == ROLE_Authority)
		WoundNotes, WoundTick, bGloryReady;
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
	 && Location.Z > Other.Location.Z - (CollisionHeight * 0.5) && Base!=None && Base!=Other && Base.bStatic
	 && normal(X) dot normal(Other.Location - Location) >= 0.7)
	{
		if( KActor(Other).KGetMass()>=0.5 && MonsterController(Controller)!=None && !MonsterController(Controller).CanAttack(Controller.Enemy) )
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
	// (a notify from the kick animation: by then the specimen may be dead, with no controller, or the prop gone)
	if ( KickTarget == None || KFMonsterController(Controller) == None )
		return;
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
	local float HealthScale, DamageScale;
	local float Difficulty, Climb;
	local KFEndlessGameType E;

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

	// Difficulty scaling, as retail Killing Floor: health and damage from the game's difficulty alone, the same in every
	// wave (DifficultyHealthScales, DifficultyDamageScales); walk speeds spread 10% either way (was 25%, with a scale that
	// grew 0.3 a difficulty step without end and with each wave's WaveDifficulty on top)
	if (Level.Game != none && !bDiffAdjusted)
	{
		Difficulty = Level.Game.GameDifficulty;

		GroundSpeed = default.GroundSpeed * (0.9 + 0.2 * FRand());
		HealthScale = DifficultyHealthScales[DifficultyIndex(Difficulty)];
		DamageScale = DifficultyDamageScales[DifficultyIndex(Difficulty)];
		// Endless and Zombies modes grow harder wave by wave, each at its own pace (their AdjustedDifficulty climbs 0.1 a
		// wave: Climb is the waves climbed)
		E = KFEndlessGameType(Level.Game);
		if ( E != None )
		{
			Climb = FMax(E.AdjustedDifficulty - Difficulty, 0.0) * 10.0;
			HealthScale += E.WaveHealthClimb * Climb;
			if ( E.DamageClimbWaves > 0 )
				Climb = FMin(Climb, E.DamageClimbWaves);
			DamageScale += E.WaveDamageClimb * Climb;
		}
		if ( KFGameType(Level.Game) != None )
			HiddenGroundSpeed *= KFGameType(Level.Game).HiddenSpeedScale;
		GroundSpeed += (Difficulty * 3);
		AirSpeed += (Difficulty * 3);
		WaterSpeed += (Difficulty * 3);
		Health *= HealthScale;
		Health *= NumPlayersHealthModifer();
		HealthMax *= HealthScale;
		HealthMax *= NumPlayersHealthModifer();
		HeadHealth *= HealthScale * NumPlayersHealthModifer();
		damageConst *= DamageScale;
		if( Level.Game.NumPlayers == 1 ) damageConst *= 0.75;
		damageRand *= DamageScale;
		if ( Level.Game.NumPlayers == 1 ) damageRand *= 0.75;
		SpinDamConst *= DamageScale;
		if ( Level.Game.NumPlayers == 1 ) SpinDamConst *= 0.75;
		SpinDamRand *= DamageScale;
		if ( Level.Game.NumPlayers == 1 ) SpinDamRand *= 0.75;
		ScreamDamage *= DamageScale;
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

// The row of DifficultyHealthScales and DifficultyDamageScales for a game difficulty, by retail Killing Floor's bounds:
// Easy (1.5), Normal (3), Skilled (4), Elite (5), Suicidal (7)
static function int DifficultyIndex( float Difficulty )
{
	if ( Difficulty < 2.0 )
		return 0;
	if ( Difficulty < 4.0 )
		return 1;
	if ( Difficulty < 5.0 )
		return 2;
	if ( Difficulty < 7.0 )
		return 3;
	return 4;
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
	// one on fire is slowed, whatever speed it is told to take (the more so when a Firebug lit it)
	if ( bBurnified )
	{
		if ( KFPawn(BurnInstigator) != None && KFPawn(BurnInstigator).GetVeteran() != None )
			NewGroundSpeed *= KFPawn(BurnInstigator).GetVeteran().static.BurnSlow(BurnSpeedScale);
		else
			NewGroundSpeed *= BurnSpeedScale;
	}
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
	// (climbing onto something in its way)
	if ( ClimbStage > 0 && Role == ROLE_Authority )
		ClimbTick();
	// (the element of the kill may come after the death; so may the electrocution)
	if ( bPlayedDeath && DeathElement != 0 && !bElementShown )
		ElementDeath();
	if ( bPlayedDeath && bZapDeath && !bZapDeathShown )
		ZapDeath();
	// (electrocuted, until the current runs out)
	if ( bZapped && Role == ROLE_Authority )
		ZapTick();
	// (frozen, until it thaws; and on each machine the look of it)
	if ( bFrozen && Role == ROLE_Authority )
		FrozenTick();
	if ( bFrozen != bFrozenShown && !bPlayedDeath )
		FreezeLook(bFrozen);
	// (a turned one's time is up)
	if ( TurnedUntil > 0.0 && Role == ROLE_Authority && Level.TimeSeconds >= TurnedUntil && Health > 0 )
	{
		TurnedUntil = 0.0;
		TakeDamage(Health + 1000, None, Location, vect(0,0,0), class'DamTypeMelee');
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

		// (Endless) the glow of one open to a glory kill: orange when the one watching is in reach
		if( bGloryReady && !bPlayedDeath && !bDeleteMe && Health > 0 )
		{
			if( GloryGlow == None )
			{
				GloryGlow = Spawn(class'KFGloryGlow');
				if( GloryGlow != None )
					GloryGlow.SetBase(Self);
			}
			if( GloryGlow != None && Level.TimeSeconds - LastRenderTime < 1.0 )
			{
				OverBody(GloryGlow);
				GloryGlow.Near(GloryNearLocal());
			}
		}
		else if( GloryGlow != None )
		{
			GloryGlow.Kill();
			GloryGlow.LifeSpan = 1.0;
			GloryGlow = None;
		}

		// (Endless) the glow of one carrying a power-up, while it lives
		if( bLootCarrier && !bPlayedDeath && !bDeleteMe )
		{
			if( LootGlow == None )
			{
				LootGlow = Spawn(class'KFLootGlow');
				if( LootGlow != None )
					LootGlow.SetBase(Self);
			}
			if( LootGlow != None && Level.TimeSeconds - LastRenderTime < 1.0 )
				OverBody(LootGlow);
		}
		else if( LootGlow != None )
			StopLootGlow();

		// (electrocuted) arcs and sparks over it, and it shakes, while the current lasts
		if( bZapped && !bPlayedDeath && !bDeleteMe )
		{
			if( ZapFX == None )
			{
				ZapFX = Spawn(class'KFZapBody');
				if( ZapFX != None )
					ZapFX.SetBase(Self);
			}
			if( Level.TimeSeconds - LastRenderTime < 1.0 )
			{
				if( ZapFX != None )
					OverBody(ZapFX);
				ZapShake(true);
			}
		}
		else if( ZapFX != None )
			StopZapFX();

		// (soaked in fuel) drops running off it
		if( bSoaked && !bPlayedDeath && !bDeleteMe )
		{
			if( SoakFX == None )
			{
				SoakFX = Spawn(class'KFFuelDrips');
				if( SoakFX != None )
					SoakFX.SetBase(Self);
			}
			if( SoakFX != None && Level.TimeSeconds - LastRenderTime < 1.0 )
				OverBody(SoakFX);
		}
		else if( SoakFX != None )
		{
			SoakFX.Kill();
			SoakFX = None;
		}

		// Skip all client visual updates for monsters not rendered recently
		if( Level.TimeSeconds - LastRenderTime < 1.0 )
		{
			TickFX(DeltaTime);
			if ( WoundTick != SimWoundTick && Role < ROLE_Authority )
				ReadWounds();

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
			{
				OverBody(FlamingFXs);
				if( bBlueFire && !bBlueFireShown )
					BlueBodyFire();
			}
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
	if( bGloryReady && Role == ROLE_Authority && Level.TimeSeconds > GloryUntil )
		bGloryReady = false;
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
	{
		FlamingFXs = Spawn(BurnEffect);
		bBlueFireShown = false;
	}
	if( FlamingFXs!=None )
	{
		FlamingFXs.SetBase(Self);
		OverBody(FlamingFXs);
		if( bBlueFire )
			BlueBodyFire();
	}
	bBurnApplied = True;
}

// Sprayed with the flamethrower's unlit fuel (FlameAltFire): soaked, it drips where it goes and burns the harder
function Soak( float Amount, Pawn Starter )
{
	if ( Health <= 0 )
		return;
	SoakFuel = FMin(SoakFuel + Amount, 6.0);
	SoakStarter = Starter;
	if ( !bSoaked )
	{
		bSoaked = true;
		NetUpdateTime = Level.TimeSeconds - 1;
	}
	// burning already: it flares up
	if ( bBurnified && BurnDown > 0 && BurnDown < 10 )
		BurnDown += 2;
}

// (KFFireGrid) Its fuel drips off, a little at a time; burning, it burns off the faster
function DripSoak( float Amount )
{
	SoakFuel -= Amount;
	if ( bBurnified )
		SoakFuel -= Amount * 2;
	if ( SoakFuel <= 0 )
	{
		SoakFuel = 0;
		bSoaked = false;
		NetUpdateTime = Level.TimeSeconds - 1;
	}
}

// Struck by the upgraded flamethrower's lightning (FlameBurstFire.Zap): hurt, and held for a moment, shaking where it stands
function Electrocute( Pawn ZapInstigator, int Damage )
{
	if ( Health <= 0 )
		return;
	TakeDamage(Damage, ZapInstigator, Location, vect(0,0,0), class'DamTypeZap');
	if ( Health <= 0 || bDeleteMe )
		return;
	ZapUntil = Level.TimeSeconds + 0.35;
	if ( !bZapped )
	{
		bZapped = true;
		ZapSince = Level.TimeSeconds;
		NetUpdateTime = Level.TimeSeconds - 1;
	}
	// held in the current long enough, an ordinary one goes down and convulses there (it gets up when its fall is over;
	// still in the current then, it goes down again)
	if ( default.Health < 1000 && Level.TimeSeconds - ZapSince >= ZapDropAfter && Level.TimeSeconds >= NextZapDrop
		&& ZapInstigator != None && BlastStagger(ZapInstigator.Location) )
		NextZapDrop = Level.TimeSeconds + 1.0;
}

// While it lasts it hardly moves (the big ones are only slowed)
function ZapTick()
{
	local float Cap, V;

	if ( Level.TimeSeconds >= ZapUntil || Health <= 0 )
	{
		bZapped = false;
		NetUpdateTime = Level.TimeSeconds - 1;
		return;
	}
	if ( Physics != PHYS_Walking )
		return;
	if ( default.Health >= 1000 )
		Cap = 0.7 * GroundSpeed;
	else
		Cap = 0.25 * GroundSpeed;
	V = Sqrt(Square(Velocity.X) + Square(Velocity.Y));
	if ( V > Cap && V > 0.0 )
	{
		Velocity.X *= Cap / V;
		Velocity.Y *= Cap / V;
	}
}

// (CryoBolt) Frozen solid for Duration (the big ones for half as long): its mind held as a stagger holds it, its body
// still, its pose kept
function Freeze( Pawn By, float Duration )
{
	// (not the Patriarch: his own states are not to be broken into)
	if ( Health <= 0 || bDeleteMe || bBoss )
		return;
	if ( default.Health >= 1000 )
		Duration *= 0.5;
	FrozenUntil = FMax(FrozenUntil, Level.TimeSeconds + Duration);
	if ( bFrozen )
		return;
	bFrozen = true;
	NetUpdateTime = Level.TimeSeconds - 1;
	HoldFrozen();
}

function HoldFrozen()
{
	bShotAnim = true;
	Acceleration = vect(0,0,0);
	Velocity.X = 0;
	Velocity.Y = 0;
	if ( KFMonsterController(Controller) != None && !Controller.IsInState('WaitForAnim') )
	{
		Controller.GoToState('WaitForAnim');
		KFMonsterController(Controller).bUseFreezeHack = true;
	}
}

function FrozenTick()
{
	if ( Health <= 0 )
		return;
	if ( Level.TimeSeconds >= FrozenUntil )
	{
		bFrozen = false;
		bShotAnim = false;
		NetUpdateTime = Level.TimeSeconds - 1;
		return;
	}
	HoldFrozen();
}

// Its pose kept and its body glazed with ice (bOn), or let go
simulated function FreezeLook( bool bOn )
{
	bFrozenShown = bOn;
	if ( bOn )
	{
		bPhysicsAnimUpdate = false;
		StopAnimating();
		if ( Level.NetMode != NM_DedicatedServer )
		{
			SetOverlayMaterial(IceLook(), 999.0, true);
			PlaySound(Sound'PatchSounds.GlassImpact2', SLOT_None, 1.2,, 600, 1.3 + 0.2 * FRand());
		}
	}
	else
	{
		bPhysicsAnimUpdate = default.bPhysicsAnimUpdate;
		if ( Level.NetMode != NM_DedicatedServer )
		{
			SetOverlayMaterial(None, 0.0, true);
			PlaySound(Sound'PatchSounds.GlassImpact3', SLOT_None, 0.8,, 500, 1.5);
		}
	}
}

// The ice glaze: a pale blue sheen, mottled like frost
simulated function Material IceLook()
{
	local Shader S;
	local Combiner C;
	local ConstantColor CC;

	if ( class'KFMonster'.default.IceGlaze != None )
		return class'KFMonster'.default.IceGlaze;
	CC = new class'ConstantColor';
	CC.Color.R = 95;
	CC.Color.G = 150;
	CC.Color.B = 215;
	CC.Color.A = 255;
	C = new class'Combiner';
	C.CombineOperation = CO_Multiply;
	C.Material1 = Texture'AW-2004Particles.Weapons.DustSmoke';
	C.Material2 = CC;
	S = new class'Shader';
	S.Specular = C;
	class'KFMonster'.default.IceGlaze = S;
	return S;
}

// The jolts of the current through its back, neck, head and arms
simulated function ZapShake( bool bOn )
{
	if ( bOn )
	{
		SetBoneRotation('Bip01 Spine1', ZapJolt(3600),, 1.0);
		SetBoneRotation('Bip01 Neck', ZapJolt(4000),, 1.0);
		SetBoneRotation(HeadBone, ZapJolt(5000),, 1.0);
		SetBoneRotation('Bip01 L UpperArm', ZapJolt(9000),, 1.0);
		SetBoneRotation('Bip01 R UpperArm', ZapJolt(9000),, 1.0);
		SetBoneRotation('Bip01 L Forearm', ZapJolt(8000),, 1.0);
		SetBoneRotation('Bip01 R Forearm', ZapJolt(8000),, 1.0);
	}
	else
	{
		SetBoneRotation('Bip01 Spine1', rot(0,0,0),, 0.0);
		SetBoneRotation('Bip01 Neck', rot(0,0,0),, 0.0);
		SetBoneRotation(HeadBone, rot(0,0,0),, 0.0);
		SetBoneRotation('Bip01 L UpperArm', rot(0,0,0),, 0.0);
		SetBoneRotation('Bip01 R UpperArm', rot(0,0,0),, 0.0);
		SetBoneRotation('Bip01 L Forearm', rot(0,0,0),, 0.0);
		SetBoneRotation('Bip01 R Forearm', rot(0,0,0),, 0.0);
	}
}

simulated function rotator ZapJolt( int Range )
{
	local rotator R;

	R.Pitch = Rand(Range) - Range / 2;
	R.Yaw = Rand(Range) - Range / 2;
	R.Roll = Rand(Range) - Range / 2;
	return R;
}

// Electrocuted to death: it seizes where it falls (on each machine that draws it)
simulated function ZapDeath()
{
	bZapDeathShown = true;
	StopZapFX();
	if ( Level.NetMode != NM_DedicatedServer )
		Spawn(class'KFZapDeath', self,, Location);
}

// (Blue Inferno) Its fire burns blue, as the upgraded flamethrower's own does (KFFlameStream.BlueFlame)
simulated function BlueBodyFire()
{
	local int i;

	bBlueFireShown = true;
	if ( FlamingFXs == None )
		return;
	for ( i=0; i<FlamingFXs.Emitters.Length && i<BurnEffect.default.Emitters.Length; i++ )
		class'KFFlameStream'.static.BlueFlame(FlamingFXs.Emitters[i], BurnEffect.default.Emitters[i], true);
	FlamingFXs.LightHue = 160;
	FlamingFXs.LightSaturation = 60;
}

simulated function StopZapFX()
{
	if( ZapFX != None )
	{
		ZapFX.AmbientSound = None;
		ZapFX.Kill();
		ZapFX = None;
	}
	ZapShake(false);
}

simulated function StopLootGlow()
{
	if( LootGlow != None )
	{
		LootGlow.Kill();
		LootGlow.LifeSpan = 2;
		LootGlow = None;
	}
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

// Fire has reached a body on this machine (each machine keeps its own): it burns, or burns on for longer
simulated function IgniteBody()
{
	if ( !bPlayedDeath || bGibbed || bSkeletized || bDeRes || Level.NetMode == NM_DedicatedServer )
		return;
	if ( Level.TimeSeconds >= CorpseBurnEnd )
	{
		bCorpseSmoked = false;
		if ( CorpseSmoke != None )
		{
			CorpseSmoke.Kill();
			CorpseSmoke = None;
		}
		Enable('Tick');
	}
	CorpseBurnEnd = FMax(CorpseBurnEnd, Level.TimeSeconds + CorpseBurnTime * (0.75 + 0.5 * FRand()));
}

// A network client's fires light its own bodies themselves: the server's fire damage never reaches them
static function IgniteBodiesNear( Actor Fire, float Radius, vector Spot )
{
	local KFMonster M;

	foreach Fire.VisibleCollidingActors(class'KFMonster', M, Radius, Spot)
		if ( M.bPlayedDeath )
			M.IgniteBody();
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
	if ( CharLevel <= 0.0 || bCloaked || bCutBody || Level.TimeSeconds - LastRenderTime > 1.0 )
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
	CharStumps();
}

simulated function CharStumps()
{
	local int i;

	for ( i=0; i<ArrayCount(Stumps); i++ )
		if ( Stumps[i] != None )
			Stumps[i].CharTo(CharLevel * GibCharShare);
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
	CharStumps();
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

// A blast left it on its feet (Nade): it stumbles where it stands, its attack cut short, and does nothing more until the
// stumble ends. Knocked off its feet by the push it is set down first, as FlipOver does; not when already knocked over or
// stumbling, not without the animation.
function bool BlastStagger( vector BlastSpot )
{
	local name Action, Seq;
	local float Frame, Rate;
	local vector X, Y, Z, Dir;

	if( Health <= 0 || KFMonsterController(Controller) == None )
		return false;
	GetAnimParams(0, Seq, Frame, Rate);
	if( bShotAnim && IsAnimating(0) && (Seq=='StunState' || Seq==StaggerAnim('BlastStaggerF')) )
		return false;
	GetAxes(Rotation, X, Y, Z);
	Dir = BlastSpot - Location;
	Dir.Z = 0;
	Dir = Normal(Dir);
	if( Dir Dot X > 0.7 )
		Action = 'BlastStaggerF';
	else if( Dir Dot X < -0.7 )
		Action = 'BlastStaggerB';
	else if( Dir Dot Y > 0 )
		Action = 'BlastStaggerR';
	else Action = 'BlastStaggerL';
	if( StaggerAnim(Action)=='' || !HasAnim(StaggerAnim(Action)) )
		return false;
	if( Physics==PHYS_Falling )
		SetPhysics(PHYS_Walking);
	bShotAnim = true;
	SetAnimAction(Action);
	Acceleration = vect(0, 0, 0);
	Velocity.X = 0;
	Velocity.Y = 0;
	Controller.GoToState('WaitForAnim');
	KFMonsterController(Controller).bUseFreezeHack = True;
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

// How hard a frag throws the body: the push it took over the push at the heart of a grenade's blast (TearOffMomentum is
// that push over the mass), so one killed at the edge drops where it stood
simulated function float BlastFling( class<DamageType> DamageType )
{
	if ( class<DamTypeFrag>(DamageType) == None )
		return 1;
	return FClamp(VSize(TearOffMomentum) * Mass / class'Nade'.default.MomentumTransfer, 0, 1);
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
		if ( HeadLossKind(Damage, DamageType) == 'headtop' )
			PostHitFX('headtop', DamageType, rotator(TraumaRay), CanSever(HeadBone, Damage, DamageType));
		else
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

	if ( DamageType == class'DamTypeGlory' )
	{
		GloryGore(DamageType);
		return;
	}
	// frozen, it shatters whatever killed it
	if ( bFrozen && !DamageType.default.bNeverSevers )
	{
		DoDamageFX('obliterate', 1000, DamageType, r);
		return;
	}
	// (the Executioner's flying cut) in two at the waist, the top half thrown on along the cut
	if ( DamageType == class'DamTypeAxeSlash' )
	{
		if ( SlashTime == Level.TimeSeconds )
			SlashGore(DamageType);
		else
			DoDamageFX('Bip01 Spine1', 1000, DamageType, SlashFlight(SlashFly));
		return;
	}
	if ( BladeFresh(DamageType) )
	{
		BladeGore(Damage, DamageType);
		return;
	}
	// (Blue Inferno) an arc flash that kills outright with plenty to spare blows it apart
	if ( (DamageType == class'DamTypeArcFlash' && Damage >= default.Health / 2) || (DamageType == class'DamTypeBFG' && Damage >= default.Health / 4)
		|| (DamageType == class'DamTypeRailgun' && Damage >= default.Health / 2) )
	{
		if ( FRand() < OverkillShare )
			DoDamageFX('obliterate', 1000, DamageType, r);
		else
			TearUp(DamageType, r);
		return;
	}
	if ( IsPowerHit(DamageType) && Level.TimeSeconds - BlastTime <= BlastWindow )
	{
		BlastDamage += PelletsStillComing(InstigatedBy);
		// the same blast does not always do the same thing
		Force = BlastDamage / float(default.Health) * (0.6 + 0.8 * FRand());
	}
	bBlast = !DamageType.default.bLocationalHit;
	i = JointIndex(HitBone);

	// blown away only now and then, the more likely the more there is to spare; else torn up, and thrown (PlayDyingAnimation)
	if ( bBlast && Force >= BodyBlast )
	{
		if ( FRand() < ObliterateShare * FMin((Force - BodyBlast) / (2.0 * BodyBlast), 1.0) )
			DoDamageFX('obliterate', 1000, DamageType, r);
		else
			TearUp(DamageType, r);
	}
	else if ( Force >= TorsoBlast && (bBlast || i < 4) )
	{
		// blown in half; an explosion may take a leg or an arm as well
		DoDamageFX('Bip01 Spine1', 1000, DamageType, r);
		if ( bBlast && FRand() < 0.6 )
			DoDamageFX(LimbJoints[4 + 2 * Rand(2)], 1000, DamageType, r);
		if ( bBlast && FRand() < 0.3 )
			DoDamageFX(LimbJoints[2 * Rand(2)], 1000, DamageType, r);
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
		if ( bBlast && FRand() < 0.55 )
			DoDamageFX(LimbJoints[2 * Rand(4)], 1000, DamageType, r);
		if ( bBlast && !bDecapitated && FRand() < 0.35 )
			DoDamageFX(HeadBone, 1000, DamageType, r);
	}
	else
		DoDamageFX(HitBone, Damage, DamageType, r);
}

// Which way the top half of a body the flying cut kills goes: on, away from the one who threw it, and up
function rotator SlashFlight( vector Fly )
{
	local rotator R;

	Fly.Z = 0;
	if ( VSize(Fly) < 0.01 )
		Fly = vect(1,0,0);
	R = rotator(Normal(Normal(Fly) + vect(0,0,0.45)));
	// (a part flies along the up axis of the rotation it is given)
	R.Pitch -= 16384;
	return R;
}

// The Executioner's flying cut is about to strike (KFAxeSlash.Sweep): the plane its blade lies in, which way across it
// the blade reaches and how far, which way it flies. A kill it makes is cut where the blade goes (SlashGore).
function NoteSlash( vector Spot, vector Normal, vector Across, float HalfSpan, vector Fly )
{
	SlashSpot = Spot;
	SlashNormal = Normal;
	SlashAcross = Across;
	SlashHalfSpan = HalfSpan;
	SlashFly = Fly;
	SlashTime = Level.TimeSeconds;
}

// A kill by the flying cut comes apart where its blade went through: every limb the blade's plane crosses within its
// span comes off at the joint above the crossing, the head if it crosses the neck or head, and the body in two if it
// crosses the trunk (the limbs first, so they fly as parts of their own). One it only grazed is cut in two.
function SlashGore( class<DamageType> DamageType )
{
	local rotator Fly;
	local vector Pelvis, Neck, Head, Top;
	local bool bAny, bUpright;
	local name Graze;

	Fly = SlashFlight(SlashFly);
	Pelvis = GetBoneCoords('Bip01 Pelvis').Origin;
	Neck = GetBoneCoords('Bip01 Neck').Origin;
	Head = GetBoneCoords(HeadBone).Origin;
	Top = Head + (Head - Neck) * 1.5;
	bUpright = Abs(SlashNormal.Z) < 0.5;
	// upright through the middle of the trunk: cleaved from the head down
	if ( bUpright && Abs((Pelvis - SlashSpot) dot SlashNormal) < SplitBand && Abs((Neck - SlashSpot) dot SlashNormal) < SplitBand )
	{
		if ( bSlashDebug )
			log("SLASHCUT" @ Name @ "cleaved");
		SplitCut(DamageType);
		return;
	}
	if ( LimbCut('Bip01 L UpperArm', 'Bip01 L Forearm', 'Bip01 L Hand', Fly, DamageType) )
		bAny = true;
	if ( LimbCut('Bip01 R UpperArm', 'Bip01 R Forearm', 'Bip01 R Hand', Fly, DamageType) )
		bAny = true;
	if ( LimbCut('Bip01 L Thigh', 'Bip01 L Calf', 'Bip01 L Foot', Fly, DamageType) )
		bAny = true;
	if ( LimbCut('Bip01 R Thigh', 'Bip01 R Calf', 'Bip01 R Foot', Fly, DamageType) )
		bAny = true;
	if ( !bDecapitated && SlashCrosses(Neck, Top) )
	{
		if ( bSlashDebug )
			log("SLASHCUT" @ Name @ "head");
		if ( !PlaneHeadTrauma(SlashSpot, SlashNormal, Fly, DamageType) )
			DoDamageFX(HeadBone, 1000, DamageType, Fly);
		bAny = true;
	}
	// the trunk: an upright cut through it cleaves it from the head down, a flat one cuts it in two
	if ( SlashCrosses(Pelvis, Neck) )
	{
		if ( bSlashDebug )
			log("SLASHCUT" @ Name @ "trunk, upright" @ bUpright);
		if ( bUpright )
			SplitCut(DamageType);
		else
			DoDamageFX('Bip01 Spine1', 1000, DamageType, Fly);
		return;
	}
	if ( bAny )
		return;
	// only grazed: the part the blade went nearest
	if ( bUpright )
		Graze = 'split';
	else if ( SlashSpot.Z > Neck.Z && !bDecapitated )
		Graze = HeadBone;
	else if ( SlashSpot.Z < Pelvis.Z )
		Graze = 'legs';
	else
		Graze = 'Bip01 Spine1';
	if ( bSlashDebug )
		log("SLASHCUT" @ Name @ "grazed:" @ Graze);
	if ( Graze == 'split' )
		SplitCut(DamageType);
	else if ( Graze == 'legs' )
	{
		DoDamageFX('Bip01 L Thigh', 1000, DamageType, Fly);
		DoDamageFX('Bip01 R Thigh', 1000, DamageType, Fly);
	}
	else
		DoDamageFX(Graze, 1000, DamageType, Fly);
}

// Cleaved from the head down by an upright cut through the middle: in two along the cut (KFTrauma.Cleave; where that
// cannot be drawn, the head off and the body in two across)
function SplitCut( class<DamageType> DamageType )
{
	bDecapitated = true;
	bPlayBrainSplash = true;
	PostHitFX('cleave', DamageType, rotator(SlashNormal), CanSever('Bip01 Spine1', 1000, DamageType));
}

// The part from Joint through Mid to End: off at Joint if the cut crosses the first stretch, at Mid if the second
function bool LimbCut( name Joint, name Mid, name End, rotator Fly, class<DamageType> DamageType )
{
	local vector J, M, E;

	J = GetBoneCoords(Joint).Origin;
	M = GetBoneCoords(Mid).Origin;
	E = GetBoneCoords(End).Origin;
	if ( SlashCrosses(J, M) )
	{
		if ( bSlashDebug )
			log("SLASHCUT" @ Name @ Joint);
		DoDamageFX(Joint, 1000, DamageType, Fly);
		return true;
	}
	if ( SlashCrosses(M, E) )
	{
		if ( bSlashDebug )
			log("SLASHCUT" @ Name @ Mid);
		DoDamageFX(Mid, 1000, DamageType, Fly);
		return true;
	}
	return false;
}

// Whether the flying cut's blade passes between A and B: its plane between them, where it crosses within the blade
function bool SlashCrosses( vector A, vector B )
{
	local float SA, SB;
	local vector X;

	SA = (A - SlashSpot) dot SlashNormal;
	SB = (B - SlashSpot) dot SlashNormal;
	if ( SA * SB > 0.0 )
		return false;
	X = A;
	if ( SA != SB )
		X = A + (B - A) * (SA / (SA - SB));
	return Abs((X - SlashSpot) dot SlashAcross) <= SlashHalfSpan + 8.0;
}

// Torn up by a kill with plenty to spare, instead of blown away: in half more often than not, a limb or two off and
// often the head
function TearUp( class<DamageType> DamageType, rotator r )
{
	local int i, n;

	// (the limbs and head first, so they fly as whole parts before the trunk goes)
	n = 1 + Rand(2);
	for ( i = 0; i < n; i++ )
		DoDamageFX(LimbJoints[2 * Rand(4)], 1000, DamageType, r);
	if ( !bDecapitated && FRand() < 0.45 )
		DoDamageFX(HeadBone, 1000, DamageType, r);
	if ( FRand() < 0.55 )
		DoDamageFX('Bip01 Spine1', 1000, DamageType, r);
}

// A blade's blow is about to land (KFMeleeFire.Strike, CorpseHit). What it does to the body is worked out from it.
simulated function NoteBlade( vector Spot, vector Motion, vector Edge, vector Throw )
{
	BladeSpot = Spot;
	BladeMotion = Normal(Motion);
	BladeEdge = Normal(Edge);
	BladeThrow = Throw;
	BladeTime = Level.TimeSeconds;
}

// The melee weapons with gore of their own: the knife, axe and pipe, the ones that throw what they kill
simulated function bool BladeGoreType( class<DamageType> DamageType )
{
	return class<DamTypeMelee>(DamageType) != None && DamageType.default.bKUseOwnDeathVel;
}

// The hit being dealt is the blow just noted
simulated function bool BladeFresh( class<DamageType> DamageType )
{
	return BladeTime == Level.TimeSeconds && BladeGoreType(DamageType);
}

// What comes off a body to a blade flies on along the blow, and up
simulated function rotator BladeFlight()
{
	local rotator R;

	R = rotator(Normal(Normal(BladeThrow) + vect(0,0,0.7)));
	R.Pitch -= 16384;			// a giblet flies along the up axis of the rotation it is given
	return R;
}

// Killed by a blade's blow and thrown along it (PlayDying), as every machine sees it
simulated function bool BladeThrown()
{
	return class<DamTypeMelee>(HitDamageType) != None && VSize(TearOffMomentum) > 50.0;
}

// A cutting blow that kills slings a streak of blood off along it, onto the floor or wall beyond the body
simulated function BladeMark()
{
	local vector Dir, HitLoc, HitNorm, Along;
	local class<DamTypeMelee> DamageType;

	DamageType = class<DamTypeMelee>(HitDamageType);
	if ( Level.NetMode == NM_DedicatedServer || DamageType == None || DamageType.default.CutChance <= 0
		|| class'GameInfo'.static.UseLowGore() || !EffectIsRelevant(TakeHitLocation, false) )
		return;
	Dir = Normal(Normal(TearOffMomentum) - vect(0,0,0.5));
	if ( Trace(HitLoc, HitNorm, TakeHitLocation + 250.0 * Dir, TakeHitLocation, false) == None )
		return;
	// laid along the way it was flung
	Along = Dir - HitNorm * (Dir dot HitNorm);
	if ( VSize(Along) < 0.1 )
		Along = HitNorm cross vect(0,0,1);
	if ( VSize(Along) < 0.1 )
		Along = vect(1,0,0);
	Along = Normal(Along);
	Spawn(class'KFBladeStreak',,, HitLoc + 20.0 * HitNorm, OrthoRotation(-HitNorm, Along, -HitNorm cross Along));
}

// (KFTrauma) A wound for every machine that draws the body: Spot, Dir and Up are in the world here
simulated function PostWound( int BoneIndex, byte Kind, vector Spot, vector Dir, vector Up, float Size )
{
	local coords C;
	local vector BX, BY, BZ;
	local int i;

	C = GetBoneCoords(class'KFTrauma'.default.WoundBones[BoneIndex]);
	BX = Normal(C.XAxis);
	BY = Normal(C.YAxis);
	BZ = Normal(C.ZAxis);
	i = WoundTick % ArrayCount(WoundNotes);
	WoundNotes[i].Bone = BoneIndex;
	WoundNotes[i].Kind = Kind;
	WoundNotes[i].Size = Clamp(int(Size), 1, 255);
	WoundNotes[i].Spot = class'KFCutPiece'.static.InBone(Spot - C.Origin, BX, BY, BZ);
	WoundNotes[i].Dir = 100.0 * class'KFCutPiece'.static.InBone(Dir, BX, BY, BZ);
	WoundNotes[i].Up = 100.0 * class'KFCutPiece'.static.InBone(Up, BX, BY, BZ);
	WoundTick++;
	// (this machine draws it too)
	if ( Level.NetMode != NM_DedicatedServer )
		ReadWounds();
}

// The wounds told of since last time, made on this machine
simulated function ReadWounds()
{
	local KFWound W;
	local int i, j;
	local float Depth;

	if ( WoundTick - SimWoundTick > ArrayCount(WoundNotes) || (WoundTick < SimWoundTick && WoundTick + 256 - SimWoundTick > ArrayCount(WoundNotes)) )
		SimWoundTick = WoundTick - ArrayCount(WoundNotes);
	for ( j=0; SimWoundTick != WoundTick && j < 16; j++ )
	{
		i = SimWoundTick % ArrayCount(WoundNotes);
		SimWoundTick++;
		if ( WoundNotes[i].Bone >= ArrayCount(class'KFTrauma'.default.WoundBones) )
			continue;
		// a hole right through (its size in tenths of a unit)
		if ( WoundNotes[i].Kind == 4 )
		{
			class'KFHoleBody'.static.Make(self, class'KFTrauma'.default.WoundBones[WoundNotes[i].Bone], WoundNotes[i].Spot,
				WoundNotes[i].Dir / 100.0, float(WoundNotes[i].Size) / 10.0);
			continue;
		}
		Depth = class'KFTrauma'.default.WoundStandOff + 2.2 * class'KFTrauma'.default.WoundRadii[WoundNotes[i].Bone] * GibScale;
		W = class'KFWound'.static.Make(self, class'KFTrauma'.default.WoundBones[WoundNotes[i].Bone], class'KFTrauma'.default.WoundJoints[WoundNotes[i].Bone],
			WoundNotes[i].Spot, WoundNotes[i].Dir / 100.0, WoundNotes[i].Up / 100.0, WoundNotes[i].Kind, WoundNotes[i].Size, Depth);
		if ( W == None )
			continue;
		Wounds[Wounds.Length] = W;
		while ( Wounds.Length > MaxWounds )
		{
			if ( Wounds[0] != None )
				Wounds[0].Destroy();
			Wounds.Remove(0, 1);
		}
	}
}

// (KFTrauma) The server's word of a head split or its top taken off: every machine drawing the body cuts it
function PostTrauma( name Kind, rotator Dir, class<DamageType> DamageType )
{
	bDecapitated = true;
	bPlayBrainSplash = true;
	PostHitFX(Kind, DamageType, Dir, CanSever(HeadBone, 1000, DamageType));
}

// What a head shot that takes the head off does to it: a heavy round now and then takes the top of the skull off
function name HeadLossKind( int Damage, class<DamageType> DamageType )
{
	if ( class<KFWeaponDamageType>(DamageType) == None || !DamageType.default.bLocationalHit || IsPowerHit(DamageType)
		|| class<DamTypeMelee>(DamageType) != None || Damage < class'KFTrauma'.default.HeadTopDamage || TraumaRay == vect(0,0,0)
		|| FRand() >= class'KFTrauma'.default.HeadTopChance )
		return HeadBone;
	return 'headtop';
}

// A chopping blade's cut through the head: upright through its middle it splits it; across it above the middle it takes
// the top off. False for a cut it leaves to the usual (the head off at the neck)
function bool BladeHeadTrauma( class<DamageType> DamageType )
{
	local vector N;

	if ( class<DamTypeMelee>(DamageType) == None || !class<DamTypeMelee>(DamageType).default.bChops )
		return false;
	N = BladeEdge cross BladeMotion;
	if ( VSize(N) < 0.1 )
		return false;
	return PlaneHeadTrauma(BladeSpot, Normal(N), BladeFlight(), DamageType);
}

// A cut along the plane through Spot square to N: upright through the head's middle it splits it (the halves fall away
// either side of the plane), flat through its upper half it takes the top off (flying on Fly's way). False otherwise.
function bool PlaneHeadTrauma( vector Spot, vector N, rotator Fly, class<DamageType> DamageType )
{
	local coords C;
	local vector Up, Mid, X, Y, Z;
	local float R, Off, Lean, T;

	if ( bDecapitated || !class'KFTrauma'.default.bTrauma )
		return false;
	C = GetBoneCoords(HeadBone);
	Up = Normal(C.XAxis);
	R = HeadRadius * HeadScale;
	Mid = C.Origin + Up * (HeadHeight * HeadScale);
	Off = (Mid - Spot) dot N;
	Lean = Abs(N dot Up);
	if ( Lean < 0.7 )
	{
		if ( Abs(Off) > class'KFTrauma'.default.SplitReach * R )
			return false;
		PostTrauma('headsplit', rotator(N), DamageType);
		return true;
	}
	// where the plane crosses the head's own up line, above its middle
	T = ((Spot - Mid) dot N) / (Up dot N);
	if ( T < -0.15 * R || T > 0.75 * R )
		return false;
	// (a part's flight is the up axis of Fly)
	GetAxes(Fly, X, Y, Z);
	PostTrauma('headtop', rotator(Z), DamageType);
	return true;
}

// (each machine that draws it) The head split, or its top taken off, as the server said: false where it cannot be drawn
simulated function bool HeadTrauma( name Kind, rotator Dir, class<DamageType> DamageType )
{
	if ( Kind == 'headsplit' )
		return class'KFTrauma'.static.SplitHead(self, Dir, DamageType);
	return class'KFTrauma'.static.TopHead(self, Dir, DamageType);
}

// A blade takes the part its edge goes through, if it takes one at all; otherwise it only draws blood
function BladeGore( int Damage, class<DamageType> DamageType )
{
	local name Cut;

	Cut = BladeCut(class<DamTypeMelee>(DamageType));
	if ( Cut == HeadBone && BladeHeadTrauma(DamageType) )
		return;
	if ( Cut == 'cleave' )
	{
		bDecapitated = true;
		bPlayBrainSplash = true;
		PostHitFX('cleave', DamageType, rotator(Normal(BladeEdge cross BladeMotion)), CanSever('Bip01 Spine1', 1000, DamageType));
		return;
	}
	if ( Cut != 'None' )
		DoDamageFX(Cut, 1000, DamageType, BladeFlight());
	else
		DoDamageFX('None', Damage, DamageType, BladeFlight());
}

// The part a blade's edge comes to first on its way through the body, as the joint it comes off at, when it is
// one the blade can take. The cut is the plane the edge sweeps. The trunk stops it, and a part the cut runs
// along rather than across is split, not taken off.
function name BladeCut( class<DamTypeMelee> DamageType )
{
	local vector N;
	local float Best, At, Reach;
	local byte Across, BestAcross;
	local coords C;
	local name Cut;
	local int i;
	local byte TrunkAcross;

	if ( DamageType == None || DamageType.default.CutChance <= 0 || FRand() >= DamageType.default.CutChance )
		return 'None';
	N = BladeEdge cross BladeMotion;
	if ( VSize(N) < 0.1 )
		return 'None';
	N = Normal(N);
	// (a body lying down is struck where the blade lands, not swept through)
	if ( bPlayedDeath )
		return DownCut(DamageType, N);
	Reach = 2.0 * CollisionRadius + 30.0;
	Best = 100000.0;
	Cut = 'None';
	if ( Severed[5] == 0 && EdgeMeets(GetBoneCoords('Bip01 Pelvis').Origin, GetBoneCoords('Bip01 Neck').Origin, N, 9.0 * GibScale, Reach, At, Across) )
	{
		Best = At;
		TrunkAcross = Across;
	}
	// a head this same blow has burst is still there to be met
	if ( Severed[4] == 0 && (!bDecapitated || DecapTime == Level.TimeSeconds) )
	{
		C = GetBoneCoords(HeadBone);
		if ( EdgeMeets(GetBoneCoords('Bip01 Neck').Origin, C.Origin + 2.0 * HeadHeight * HeadScale * C.XAxis, N, 4.0 * GibScale, Reach, At, Across) && At < Best )
		{
			Best = At;
			Cut = HeadBone;
			BestAcross = Across;
		}
	}
	for ( i=0; i<ArrayCount(LimbJoints); i++ )
	{
		if ( Severed[SeverSlot(LimbJoints[i])] == 0
			&& EdgeMeets(GetBoneCoords(LimbJoints[i]).Origin, GetBoneCoords(LimbEnds[i]).Origin, N, 3.0 * GibScale, Reach, At, Across) && At < Best )
		{
			Best = At;
			Cut = LimbJoints[i];
			BestAcross = Across;
		}
	}
	// (KFTrauma) a chopping blade through the trunk, killing, goes on through it: across it, in two at the waist; down
	// along it, often cleaving the body in two
	if ( Cut == 'None' && Best < 100000.0 && DamageType.default.bChops && class'KFTrauma'.default.bTrauma )
	{
		if ( TrunkAcross != 0 )
			return 'Bip01 Spine1';
		if ( FRand() < class'KFTrauma'.default.CleaveChance )
			return 'cleave';
	}
	if ( BestAcross == 0 )
		return 'None';
	// a knife only gets through a forearm or the neck
	if ( !DamageType.default.bChops && Cut != HeadBone && Cut != 'Bip01 L Forearm' && Cut != 'Bip01 R Forearm' )
		return 'None';
	return Cut;
}

// The part of a body lying down that a blade lands on, as the joint it comes off at, when it is one the blade
// can take: the part nearest where it lands, if the cut goes across it. The trunk, when it is nearest, keeps it.
function name DownCut( class<DamTypeMelee> DamageType, vector N )
{
	local float Best, D;
	local byte Across, BestAcross;
	local coords C;
	local name Cut;
	local int i;

	Best = DownCutReach;
	Cut = 'None';
	if ( Severed[5] == 0 )
		Best = FMin(Best, LandsOn(GetBoneCoords('Bip01 Pelvis').Origin, GetBoneCoords('Bip01 Neck').Origin, N, 9.0 * GibScale, Across));
	if ( Severed[4] == 0 && (!bDecapitated || DecapTime == Level.TimeSeconds) )
	{
		C = GetBoneCoords(HeadBone);
		D = LandsOn(GetBoneCoords('Bip01 Neck').Origin, C.Origin + 2.0 * HeadHeight * HeadScale * C.XAxis, N, 4.0 * GibScale, Across);
		if ( D < Best )
		{
			Best = D;
			Cut = HeadBone;
			BestAcross = Across;
		}
	}
	for ( i=0; i<ArrayCount(LimbJoints); i++ )
	{
		if ( Severed[SeverSlot(LimbJoints[i])] != 0 )
			continue;
		D = LandsOn(GetBoneCoords(LimbJoints[i]).Origin, GetBoneCoords(LimbEnds[i]).Origin, N, 3.0 * GibScale, Across);
		if ( D < Best )
		{
			Best = D;
			Cut = LimbJoints[i];
			BestAcross = Across;
		}
	}
	if ( BestAcross == 0 )
		return 'None';
	if ( !DamageType.default.bChops && Cut != HeadBone && Cut != 'Bip01 L Forearm' && Cut != 'Bip01 R Forearm' )
		return 'None';
	return Cut;
}

// How far from where the blade lands the bone from A to B (Thick about it) is, and whether the cut, the plane
// through BladeSpot across N, goes across it
function float LandsOn( vector A, vector B, vector N, float Thick, out byte Across )
{
	local float DA, DB, u;
	local vector E;

	DA = (A - BladeSpot) dot N;
	DB = (B - BladeSpot) dot N;
	Across = 0;
	if ( (DA > 0) != (DB > 0) && Abs(DA - DB) >= 0.25 * VSize(B - A) )
		Across = 1;
	E = B - A;
	if ( (E dot E) > 0.001 )
		u = FClamp(((BladeSpot - A) dot E) / (E dot E), 0.0, 1.0);
	return VSize(A + E * u - BladeSpot) - Thick;
}

// Whether the blade's cut, the plane through BladeSpot across N, meets the bone from A to B (Thick about it) within
// Reach of the spot. At is how far along the blow it is met; Across is 1 when the cut goes across it, not along it.
function bool EdgeMeets( vector A, vector B, vector N, float Thick, float Reach, out float At, out byte Across )
{
	local float DA, DB;
	local vector C;

	DA = (A - BladeSpot) dot N;
	DB = (B - BladeSpot) dot N;
	Across = 0;
	if ( (DA > 0) != (DB > 0) && Abs(DA - DB) >= 0.25 * VSize(B - A) )
	{
		C = A + (B - A) * (DA / (DA - DB));
		Across = 1;
	}
	else if ( Abs(DA) <= Thick && (Abs(DB) > Thick || ((B - A) dot BladeMotion) > 0) )
		C = A;
	else if ( Abs(DB) <= Thick )
		C = B;
	else if ( (DA > 0) != (DB > 0) )
		C = A + (B - A) * (DA / (DA - DB));
	else
		return false;
	if ( Abs((C - BladeSpot) dot BladeEdge) > Reach || Abs((C - BladeSpot) dot BladeMotion) > Reach )
		return false;
	At = ((C - BladeSpot) dot BladeMotion) - Thick;
	return true;
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
// (the server: an upgraded weapon's kill is in its element, on every machine: ElementDeath)
function Died( Controller Killer, class<DamageType> DamageType, vector HitLocation )
{
	if ( DeathElement == 0 )
		DeathElement = class'KFElementDeath'.static.ElementOf(Killer);
	if ( DamageType == class'DamTypeZap' || bZapped )
		bZapDeath = true;
	Super.Died(Killer, DamageType, HitLocation);
}

// Something in its way it may climb onto (the server; KFMonsterController.NotifyHitWall): the lowest height, over a
// step and within reach, at which it can move on over the top with room to stand there and nothing overhead. The
// heights are from where it stands: the walk's step-up has it raised a step when it meets the edge
function bool StartClimb( vector Dir )
{
	local vector Ext, Feet, Above, Over, HitLoc, HitNorm;
	local float Rise, Reach;

	if ( !bClimbs || ClimbStage > 0 || Health <= 0 || Physics != PHYS_Walking )
		return false;
	Dir.Z = 0;
	if ( VSize(Dir) < 0.1 )
		return false;
	Dir = Normal(Dir);
	Ext.X = CollisionRadius;
	Ext.Y = CollisionRadius;
	Ext.Z = CollisionHeight;
	Feet = Location;
	if ( Trace(HitLoc, HitNorm, Location - vect(0,0,48), Location, false, Ext) != None )
		Feet = HitLoc;
	Reach = FMin(ClimbMax, 2.0 * CollisionHeight);
	// (from a little back off the edge: a trace that starts touching something passes through it)
	for ( Rise = 40.0; Rise <= Reach; Rise += 8.0 )
	{
		Above = Feet + vect(0,0,1) * Rise;
		if ( Above.Z > Location.Z && Trace(HitLoc, HitNorm, Above, Location - Dir * 6.0, false, Ext) != None )
			return false;
		Over = Above + Dir * (CollisionRadius + 20.0);
		if ( Trace(HitLoc, HitNorm, Over, Above - Dir * 6.0, false, Ext) != None )
			continue;
		// the top it would stand on (a lip lower down, a step it could walk, is looked past: higher up)
		if ( Trace(HitLoc, HitNorm, Over - vect(0,0,1) * (Rise + 4.0), Over, false, Ext) == None || HitNorm.Z < 0.7
			|| HitLoc.Z - Feet.Z < 36.0 )
			continue;
		ClimbTo = HitLoc + vect(0,0,2);
		ClimbDir = Dir;
		ClimbStage = 1;
		ClimbUntil = Level.TimeSeconds + 1.5;
		SetPhysics(PHYS_Flying);
		Velocity = vect(0,0,1) * ClimbSpeed;
		Acceleration = vect(0,0,0);
		return true;
	}
	return false;
}

// Up the edge at ClimbSpeed, pressed to it, then onto the top (velocity set each frame: pawn Tick runs before physics,
// and the movement reaches the other machines as flying, smoothly)
function ClimbTick()
{
	local vector Left;

	if ( Health <= 0 || Physics != PHYS_Flying || Level.TimeSeconds > ClimbUntil )
	{
		EndClimb();
		return;
	}
	if ( ClimbStage == 1 && Location.Z >= ClimbTo.Z )
		ClimbStage = 2;
	if ( ClimbStage == 1 )
	{
		Velocity = vect(0,0,1) * ClimbSpeed + ClimbDir * 20.0;
		return;
	}
	Left = ClimbTo - Location;
	Left.Z = 0;
	if ( (Left Dot ClimbDir) <= 0.0 )
	{
		EndClimb();
		return;
	}
	Velocity = ClimbDir * ClimbOverSpeed;
	Velocity.Z = FClamp((ClimbTo.Z - Location.Z) * 6.0, 0.0, 80.0);
}

function EndClimb()
{
	ClimbStage = 0;
	if ( Health > 0 && Physics == PHYS_Flying )
	{
		SetPhysics(PHYS_Falling);
		Velocity = ClimbDir * ClimbOverSpeed * 0.5;
	}
}

// Turned by a special ammo: on the players' side a while (KFAmmoMod.Turn)
function bool IsTurned()
{
	return TurnedUntil > 0.0 && Health > 0;
}

// Killed by an upgraded weapon: it dies in that weapon's element; fire's burns on where it falls
simulated function ElementDeath()
{
	bElementShown = true;
	if ( Level.NetMode == NM_DedicatedServer )
		return;
	class'KFElementDeath'.static.Make(self, DeathElement);
	if ( (DeathElement == 1 || DeathElement == 2) && CorpseBurnEnd <= 0.0 )
	{
		CorpseBurnEnd = Level.TimeSeconds + CorpseBurnTime * (0.75 + 0.5 * FRand());
		StartBurnFX();
	}
}

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
	if ( DeathElement != 0 && !bElementShown )
		ElementDeath();
	if ( bZapDeath && !bZapDeathShown )
		ZapDeath();

	HitDamageType = DamageType; // these are replicated to other clients
	TakeHitLocation = HitLoc;
	// a body a blade has killed goes along the blow; how hard is carried in the length (PlayDyingAnimation),
	// which comes through in whole units to the other machines
	if ( Level.NetMode != NM_Client && BladeFresh(DamageType) )
		TearOffMomentum = 100.0 * BladeThrow;

	// Noted on every machine, because each keeps and hits its own copy of the body: the killing blow
	// is past, and the rest of a blast that killed is about to land on the corpse
	bDeathGoreDone = true;
	if ( IsPowerHit(DamageType) )
		BlastKillTime = Level.TimeSeconds;

	bSTUNNED = false;
	bMovable = true;
			 
	if (DamageType == class 'Burned' ||  DamageType == class 'DamTypeFlamethrower')
		ZombieCrispUp();
	// blood pools under the body when it comes to rest (not under a burnt one: KFBloodPool looks again then)
	if ( Level.NetMode != NM_DedicatedServer && !class'GameInfo'.static.UseLowGore() && CharLevel < 0.5 )
		Spawn(class'KFBloodPool', self,, Location);

	ProcessHitFX();
	// a head lost while alive stays lost
	if ( bDecapitated )
		SeverHead(false);
	if ( BladeThrown() )
	{
		SmacksLeft = SmackMarks;
		BladeMark();
	}

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

		if ( class<Burned>(damageType) != None || class<DamTypeFlamethrower>(damageType) != None )
			IgniteBody();

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

				// a body burnt through crumbles under a hard blow (no blood left in it)
				if ( !bPlayGoreSplash && CharLevel >= 1.0 && Damage >= AshCrumbleDamage && !class'GameInfo'.static.UseLowGore()
					&& class<DamTypeFlamethrower>(DamageType) == None && class<Burned>(DamageType) == None && FRand() < AshCrumbleChance )
				{
					AshCrumble(Momentum);
					RemoveGibbedBody();
					return;
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
				// a blast that does not blow it away tears a limb off it, now and then the head
				if ( !bPlayGoreSplash && IsPowerHit(DamageType) && !DamageType.default.bLocationalHit && FRand() < CorpseBlastLimb )
					DoDamageFX(RandomJoint(), 1000, DamageType, Rotator(Momentum));
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

	// water puts it out
	if ( BurnDown > 0 && PhysicsVolume.bWaterVolume )
	{
		BurnDown = 0;
		bBurnified = false;
		if ( CanSpeedAdjust() )
			SetGroundSpeed(OriginalGroundSpeed);
	}
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

		// (KFTrauma) a head split down the middle, the top of a skull taken off; where the cuts cannot be drawn the head
		// comes off as before
		if ( Bone == 'cleave' )
		{
			if ( HitFX[SimHitFxTicker].bSever && !class'KFTrauma'.static.Cleave(self, HitFX[SimHitFxTicker].rotDir, HitFX[SimHitFxTicker].damtype) )
			{
				if ( Severed[4] == 0 )
					SeverHead(true, HitFX[SimHitFxTicker].rotDir, 0.3, HitFX[SimHitFxTicker].damtype);
				Sever('Bip01 Spine1', HitFX[SimHitFxTicker].rotDir, 0.3, HitFX[SimHitFxTicker].damtype);
			}
			if ( bGibbed )
			{
				SimHitFxTicker = HitFxTicker;
				return;
			}
			continue;
		}
		if ( Bone == 'headsplit' || Bone == 'headtop' )
		{
			if ( HitFX[SimHitFxTicker].bSever && Severed[4] == 0 && !HeadTrauma(Bone, HitFX[SimHitFxTicker].rotDir, HitFX[SimHitFxTicker].damtype) )
				SeverHead(true, HitFX[SimHitFxTicker].rotDir, HitFX[SimHitFxTicker].damtype.default.GibPerterbation, HitFX[SimHitFxTicker].damtype);
			continue;
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
			Sever(Bone, HitFX[SimHitFxTicker].rotDir, HitFX[SimHitFxTicker].damtype.default.GibPerterbation, HitFX[SimHitFxTicker].damtype);
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
	Stumps[Slot].CharTo(CharLevel * GibCharShare);
	Stumps[Slot].bHidden = bCloaked && Health > 0;
}

// What a limb that comes off wears for skin i: the body's, but never a cloak (a cloaked Stalker's limb was invisible but
// for its stump, which lay about as a giant lone chunk; KFLimbGib.TakeLimb)
simulated function Material LimbSkin( int i )
{
	if ( bCloaked && i < default.Skins.Length && default.Skins[i] != None )
		return default.Skins[i];
	return Skins[i];
}

// Its stumps drawn with the body or hidden with it (a cloaked specimen's)
simulated function HideStumps( bool bHide )
{
	local int i;

	for ( i = 0; i < ArrayCount(Stumps); i++ )
		if ( Stumps[i] != None )
			Stumps[i].bHidden = bHide;
}

simulated function DropStump( int Slot )
{
	if ( Stumps[Slot] != None )
		Stumps[Slot].Destroy();
	Stumps[Slot] = None;
}

// The head goes: hidden, the neck capped. bThrow adds the head and bits of brain flying off; without
// it the head is simply gone, for a machine that learns of it late.
simulated function SeverHead( bool bThrow, optional rotator Dir, optional float Spread, optional class<DamageType> DamageType )
{
	local coords C;
	local bool bCut, bBurst;

	if ( Severed[4] != 0 || Level.NetMode == NM_DedicatedServer || class'GameInfo'.static.UseLowGore() )
		return;
	Severed[4] = 1;
	if ( bThrow )
	{
		C = GetBoneCoords(HeadBone);
		if ( BlastCut(DamageType) )
			class'KFBloodBlast'.static.Make(self, C.Origin, 0.3 * BloodBlastSize(), 0.5 * vector(Dir));
		// a blade takes the head off whole and a pipe bursts it; anything else throws a piece of it
		bCut = (BladeGoreType(DamageType) && class<DamTypeMelee>(DamageType).default.CutChance > 0) || class<DamTypeAxeSlash>(DamageType) != None;
		bBurst = BladeGoreType(DamageType) && !bCut;
		// (a clean cut bleeds from the neck and the head, not as a mist)
		if ( !bCut || !ThrowLimb(HeadBone, Dir, Spread) )
		{
			Spawn(class'KFMod.BrainSplash',,, C.Origin, Rotation);
			if ( !bBurst )
				SpawnGiblet(MonsterHeadGiblet, C.Origin, Dir, Spread);
			if ( EffectIsRelevant(Location, false) )
			{
				SpawnGiblet(class'KFMod.KFGibBrain', C.Origin, Rotation, 0.06);
				SpawnGiblet(class'KFMod.KFGibBrainb', C.Origin, Rotation, 0.06);
				if ( bBurst )
				{
					SpawnGiblet(class'KFMod.KFGibBrain', C.Origin, Dir, 0.3);
					SpawnGiblet(class'KFMod.KFGibBrainb', C.Origin, Dir, 0.3);
				}
			}
		}
		PlaySound(sound'PlayerSounds.NewGibs.NewGib2', SLOT_Misc, class'KFBloodBlast'.static.GoreVol(255),, class'KFBloodBlast'.static.GoreRadius(255, TransientSoundRadius));
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
simulated function Sever( name Bone, rotator Dir, float Spread, optional class<DamageType> DamageType )
{
	local coords C;
	local int Slot, Below;
	local bool bWhole;

	Slot = SeverSlot(Bone);
	if ( Slot < 0 || Severed[Slot] != 0 )
		return;
	if ( Slot == 4 )
	{
		SeverHead(true, Dir, Spread, DamageType);
		return;
	}
	C = GetBoneCoords(Bone);

	// (KFTrauma) in two across the waist, the top half its own whole self, the cut faces raw
	if ( Slot == 5 && class'KFTrauma'.static.CutWaist(self, Dir, DamageType) )
	{
		if ( !BladeGoreType(DamageType) )
			Spawn(class'KFMod.BrainSplash',,, C.Origin, Rotation);
		PlaySound(sound'PlayerSounds.NewGibs.NewGib3', SLOT_Misc, class'KFBloodBlast'.static.GoreVol(255),, class'KFBloodBlast'.static.GoreRadius(255, TransientSoundRadius));
		class'KFBloodBlast'.static.Make(self, GetBoneCoords('Bip01 Spine2').Origin, 0.6 * BloodBlastSize(), 0.5 * vector(Dir));
		return;
	}
	// (the Executioner's flying cut) the top half off whole
	if ( Slot == 5 && class<DamTypeAxeSlash>(DamageType) != None && CutInTwo(Dir) )
		bWhole = true;
	// the limb itself when it can be shown, and what still hangs from it goes with it;
	// otherwise a clot's giblets stand in for it
	else if ( Slot != 5 && ThrowLimb(Bone, Dir, Spread) )
	{
		bWhole = true;
		Below = SeverSlot(LimbBelow(Bone));
		if ( Below >= 0 )
		{
			Severed[Below] = 1;
			DropStump(Below);
		}
	}
	else
	{
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
	}

	// (a blade's clean cut bleeds from the stump and the part, not as a mist)
	if ( !bWhole || !BladeGoreType(DamageType) )
		Spawn(class'KFMod.BrainSplash',,, C.Origin, Rotation);
	if ( Slot == 5 )
		PlaySound(sound'PlayerSounds.NewGibs.NewGib3', SLOT_Misc, class'KFBloodBlast'.static.GoreVol(255),, class'KFBloodBlast'.static.GoreRadius(255, TransientSoundRadius));
	else
		PlaySound(sound'PlayerSounds.NewGibs.NewGib1', SLOT_Misc, class'KFBloodBlast'.static.GoreVol(255),, class'KFBloodBlast'.static.GoreRadius(255, TransientSoundRadius));
	// blown in half, or a part torn off by a blast: a burst of blood
	if ( Slot == 5 )
		class'KFBloodBlast'.static.Make(self, GetBoneCoords('Bip01 Spine2').Origin, 0.6 * BloodBlastSize(), 0.5 * vector(Dir));
	else if ( BlastCut(DamageType) )
		class'KFBloodBlast'.static.Make(self, C.Origin, 0.28 * BloodBlastSize(), 0.5 * vector(Dir));
	Severed[Slot] = 1;
	HideBone(Bone);
	AddStump(Slot, Bone);
}

// The part that hangs from Joint thrown whole: this specimen's own arm, leg or head (KFLimbGib)
simulated function bool ThrowLimb( name Joint, rotator Dir, float Spread )
{
	local KFLimbGib L;
	local vector X, Y, Z;
	local name Below;

	if ( !bOwnLimbs || Level.bDropDetail || Level.DetailMode == DM_Low || Mesh == None )
		return false;
	Below = LimbBelow(Joint);
	if ( Below != 'None' && Severed[SeverSlot(Below)] == 0 )
		Below = 'None';
	Instigator = self;
	L = Spawn(class'KFLimbGib',,, GetBoneCoords(Joint).Origin, Rotation);
	if ( L == None )
		return false;
	if ( !L.TakeLimb(self, Joint, LimbTip(Joint), Below, StumpSize[SeverSlot(Joint)] * GibScale * DrawScale) )
	{
		L.Destroy();
		return false;
	}
	L.bFlaming = bFlaming;
	L.SpawnTrail();
	Spread *= 32768.0;
	Dir.Pitch += (FRand() * 2.0 - 1.0) * Spread;
	Dir.Yaw += (FRand() * 2.0 - 1.0) * Spread;
	Dir.Roll += (FRand() * 2.0 - 1.0) * Spread;
	GetAxes(Dir, X, Y, Z);
	L.Velocity = Velocity + Z * (350.0 + 200.0 * FRand());
	LastLimb = L;
	return true;
}

// The top half thrown off whole (the Executioner's flying cut): this body's own trunk, arms and head, less what is gone
// already; the arms and head go from the body with it
simulated function bool CutInTwo( rotator Dir )
{
	local vector X, Y, Z;

	if ( !ThrowLimb('Bip01 Spine1', Dir, 0.1) || LastLimb == None || LastLimb.Piece == None )
		return false;
	if ( Severed[4] != 0 )
		LastLimb.Piece.SetBoneScale(3, 0.0, HeadBone);
	if ( Severed[2] != 0 )
		LastLimb.Piece.SetBoneScale(4, 0.0, 'Bip01 R Forearm');
	if ( Severed[3] != 0 )
		LastLimb.Piece.SetBoneScale(5, 0.0, 'Bip01 L Forearm');
	if ( Severed[8] != 0 )
		LastLimb.Piece.SetBoneScale(6, 0.0, 'Bip01 L UpperArm');
	if ( Severed[9] != 0 )
		LastLimb.Piece.SetBoneScale(7, 0.0, 'Bip01 R UpperArm');
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
	GetAxes(Dir, X, Y, Z);
	LastLimb.Velocity += Z * 120.0;
	return true;
}

// The far end of the part that comes off at Joint; None for the head
simulated function name LimbTip( name Joint )
{
	switch ( Joint )
	{
		case 'Bip01 L UpperArm':
		case 'Bip01 L Forearm':		return 'Bip01 L Hand';
		case 'Bip01 R UpperArm':
		case 'Bip01 R Forearm':		return 'Bip01 R Hand';
		case 'Bip01 L Thigh':
		case 'Bip01 L Calf':		return 'Bip01 L Foot';
		case 'Bip01 R Thigh':
		case 'Bip01 R Calf':		return 'Bip01 R Foot';
		case 'Bip01 Spine1':		return 'Bip01 Neck';
	}
	return 'None';
}

// The joint further down the part that comes off at Joint, where a part of it can come off on its own
simulated function name LimbBelow( name Joint )
{
	switch ( Joint )
	{
		case 'Bip01 L UpperArm':	return 'Bip01 L Forearm';
		case 'Bip01 R UpperArm':	return 'Bip01 R Forearm';
		case 'Bip01 L Thigh':		return 'Bip01 L Calf';
		case 'Bip01 R Thigh':		return 'Bip01 R Calf';
	}
	return 'None';
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

	// frozen solid, it breaks like glass: ice and frozen chunks, no blood
	if ( bFrozen )
		Spawn(class'KFIceShatter',,, Location, Rotation);
	else
	{
		Spawn(class'KFMod.FeedingSpray',,, Location, Rotation);
		Spawn(class'KFMod.BodySplash',,, Location, Rotation);
		PlaySound(sound'PlayerSounds.NewGibs.NewGib4', SLOT_Misc, class'KFBloodBlast'.static.GoreVol(255),, class'KFBloodBlast'.static.GoreRadius(255, TransientSoundRadius));
		class'KFBloodBlast'.static.Make(self, Location, BloodBlastSize(), 0.5 * vector(Dir));
	}

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

// A body burnt through crumbling: ash and embers, and a few charred lumps (no blood left in it)
simulated function AshCrumble( vector Push )
{
	local rotator Dir;
	local float KeepShare;
	local int i;

	if ( bGibbed || Level.NetMode == NM_DedicatedServer || class'GameInfo'.static.UseLowGore() )
		return;
	bGibbed = true;
	bPlayGoreSplash = true;
	Spawn(class'KFAshBurst',,, Location, Rotation);
	PlaySound(sound'PlayerSounds.NewGibs.NewGib4', SLOT_Misc, class'KFBloodBlast'.static.GoreVol(160),, class'KFBloodBlast'.static.GoreRadius(160, TransientSoundRadius), 0.6);
	if ( Push != vect(0,0,0) )
		Dir = rotator(Normal(Normal(Push) + vect(0,0,1.5)));
	else
		Dir = rotator(vect(0,0,1));
	KeepShare = GibCharShare;
	GibCharShare = 1.0 / FMax(CharLevel, 0.01);
	bAshCrumbling = true;
	if ( Severed[5] == 0 )
		GibAt(MonsterTorsoGiblet, 'Bip01 Spine2', Dir, 0.5);
	GibAt(MonsterLowerTorsoGiblet, 'Bip01 Pelvis', Dir, 0.5);
	if ( Severed[4] == 0 && FRand() < 0.6 )
		GibAt(MonsterHeadGiblet, HeadBone, Dir, 0.5);
	if ( Severed[0] == 0 && FRand() < 0.5 )
		GibAt(MonsterThighGiblet, 'Bip01 L Thigh', Dir, 0.5);
	for ( i=0; i<ArrayCount(Stumps); i++ )
		DropStump(i);
	GibCharShare = KeepShare;
	bAshCrumbling = false;
}

// How big a burst of blood this body makes blown apart (KFBloodBlast): a clot's is 1
simulated function float BloodBlastSize()
{
	return FClamp(CollisionRadius * CollisionHeight / (24.0 * 44.0), 0.8, 2.2);
}

// A part taken off by a blast or a great overkill, which bursts in blood (not a bullet's or a blade's)
simulated function bool BlastCut( class<DamageType> DamageType )
{
	return DamageType != None && ((IsPowerHit(DamageType) && !DamageType.default.bLocationalHit)
		|| DamageType == class'DamTypeArcFlash' || DamageType == class'DamTypeBFG' || DamageType == class'DamTypeRailgun'
		|| DamageType == class'DamTypeAxeSlash');
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
		return FRand() < CorpseBlastGib;
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
	if ( KFGib(Giblet) != None )
		KFGib(Giblet).CharTo(CharLevel * GibCharShare);
	if ( bAshCrumbling && KFGib(Giblet) != None )
		KFGib(Giblet).Ashen();
	if ( bFrozen && KFGib(Giblet) != None )
		KFGib(Giblet).Iced();

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

// The four directions of a blast's stumble (BlastStagger), sent to every machine as the action's name
simulated function bool IsStaggerAction( name AnimName )
{
	return AnimName=='BlastStaggerF' || AnimName=='BlastStaggerB' || AnimName=='BlastStaggerL' || AnimName=='BlastStaggerR';
}

// The stumble a blast plays: the knock-back stumble, else the whole-body hit reaction from that side (Bloat, Siren)
simulated function name StaggerAnim( name Action )
{
	if( HasAnim('KnockDown') )
		return 'KnockDown';
	switch( Action )
	{
		case 'BlastStaggerF':	return KFHitFront;
		case 'BlastStaggerB':	return KFHitBack;
		case 'BlastStaggerL':	return KFHitLeft;
		case 'BlastStaggerR':	return KFHitRight;
	}
	return '';
}

simulated function int DoAnimAction( name AnimName )
{
	// a blast's stumble takes the whole body: an attack, a scream or a grab under way stops
	if( IsStaggerAction(AnimName) )
	{
		StopAnimating(true);
		PlayAnim(StaggerAnim(AnimName),, 0.1);
		Return 0;
	}
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
	if ( Controller == None )
		return;
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

	// (a re-packed weapon's hit may set off its special ammo, a moment after: KFAmmoMod)
	if ( Role == ROLE_Authority && instigatedBy != None && Health > 0 && damageType != class'Burned' )
		class'KFAmmoMod'.static.Hit(self, instigatedBy, hitlocation, damageType);
	// (Endless) one staggered and glowing, struck by hand within reach, is finished: a glory kill
	if ( bGloryReady && Health > 0 && KFHumanPawn(instigatedBy) != None && class<DamTypeMelee>(damageType) != None
		&& damageType != class'DamTypeGlory' && VSize(instigatedBy.Location - Location) < GloryReach() )
	{
		GloryKill(instigatedBy);
		return;
	}
	// (frozen, it is brittle)
	if ( bFrozen && Health > 0 && damageType != class'DamTypeCryo' )
		Damage = int(float(Damage) * FrozenDamageScale);
	LastDamagedBy = instigatedBy;
	LastDamagedByType = damageType;
	HitMomentum = VSize(momentum);
	LastHitLocation = hitlocation;
	LastMomentum = momentum;

	// Zeds and fire dont mix.
	if( class<Burned>(damageType)!=none || class<DamTypeFlamethrower>(damageType)!=none)
	{
		// (soaked in fuel it burns the harder; and fire spreads from it as SS13's does: KFFireGrid)
		if ( bSoaked )
			Damage *= 1.6;
		class'KFFireGrid'.static.Get(self, true);
		if ( !bBlueFire && instigatedBy != None && FlameThrower(instigatedBy.Weapon) != None && FlameThrower(instigatedBy.Weapon).bUpgraded )
			bBlueFire = true;
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
				BurnDown = BurnTime(instigatedBy);
				SetGroundSpeed(GroundSpeed);	// (it is slowed in there, now that it burns)
				BurnInstigator = instigatedBy;
				SetTimer(1.0,true);
			}
			else HeatAmount++;
		}
		// fresh fire on one already burning keeps it burning longer
		else if ( !bBurnTick && BurnDown < BurnTime(instigatedBy) )
			BurnDown++;
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
	bLastHitHead = bIsHeadShot;

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

	if( Health-Damage > 0 && (bNoHitPush || (DamageType!=class'DamTypeFrag' && DamageType!=class'DamTypeShotgun' && DamageType!=class'DamTypeDBShotgun')) )
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
	if ( Health > 0 && !bGloryReady && !bGloryDone )
		MaybeGlory(instigatedBy);
}

// (KFBossBrain) A boss prototype's abilities, each tick on the server (ZombieKingFleshpound, ZombieAbomination)
function BossThink( float DeltaTime );

// ---- (Endless, Doom style) glory kills

// The player at this machine is within reach of finishing it
simulated function bool GloryNearLocal()
{
	local PlayerController PC;

	PC = Level.GetLocalPlayerController();
	return PC != None && PC.Pawn != None && VSize(PC.Pawn.Location - Location) < 110.0 + CollisionRadius;
}

function float GloryReach()
{
	if ( KFEndlessGameType(Level.Game) != None )
		return KFEndlessGameType(Level.Game).GloryReach + CollisionRadius;
	return 0;
}

// Knocked low enough by a player's hit, it staggers and glows, open to a glory kill for a few seconds
function MaybeGlory( Pawn InstigatedBy )
{
	local KFEndlessGameType G;

	G = KFEndlessGameType(Level.Game);
	if ( G == None || !G.bGloryKills || bBoss || bDecapitated || bFrozen || KFHumanPawn(InstigatedBy) == None
		|| float(Health) > G.GloryShare * HealthMax )
		return;
	bGloryReady = true;
	GloryUntil = Level.TimeSeconds + G.GloryWindow;
	BlastStagger(Location + vector(Rotation) * 100.0);
}

// Finished by hand (a blow, or the use key: KFPlayerController.ServerUse): pulled in to it, the one who did it is given
// health, ammunition and armour (KFEndlessGameType.GloryReward, KFGloryBurst), and it comes apart (GloryGore)
function GloryKill( Pawn Killer )
{
	local KFEndlessGameType G;
	local vector Pull;

	if ( !bGloryReady || Health <= 0 || Killer == None )
		return;
	bGloryReady = false;
	bGloryDone = true;
	GloryFinish = Rand(5);
	GloryFrom = Killer.Location;
	G = KFEndlessGameType(Level.Game);
	if ( G != None )
		G.GloryReward(Killer, self);
	// lunged in to it
	Pull = Location - Killer.Location;
	Pull.Z = 0;
	if ( VSize(Pull) > CollisionRadius + Killer.CollisionRadius + 20.0 )
		Killer.Velocity = Normal(Pull) * FMin(900.0, 4.0 * (VSize(Pull) - CollisionRadius - Killer.CollisionRadius)) + vect(0,0,120);
	PlaySound(Sound'KFPawnDamageSound.MeleeDamageSounds.axehitflesh', SLOT_Pain, 2.0,, 600.0, 0.8);
	TakeDamage(Health + 1000, Killer, Location, Normal(Location - Killer.Location) * 30000.0, class'DamTypeGlory');
}

// How a glory kill tears it apart: split, cleaved, cut in two, the top of the skull off, or the arms torn off and the
// head split
function GloryGore( class<DamageType> DamageType )
{
	local vector Toward, Side, Away;

	Toward = Location - GloryFrom;
	Toward.Z = 0;
	if ( VSize(Toward) < 1.0 )
		Toward = vector(Rotation);
	Toward = Normal(Toward);
	Side = Normal(Toward cross vect(0,0,1));
	Away = Normal(Toward + vect(0,0,1.2));
	bDecapitated = true;
	bPlayBrainSplash = true;
	switch ( GloryFinish )
	{
		case 0:
			PostHitFX('headsplit', DamageType, rotator(Side), true);
			break;
		case 1:
			PostHitFX('cleave', DamageType, rotator(Side), true);
			break;
		case 2:
			// (a part flies along the up axis of the rotation it is given)
			PostHitFX('headtop', DamageType, rotator(Away), true);
			DoDamageFX('Bip01 Spine1', 1000, DamageType, rotator(Away) - rot(16384,0,0));
			break;
		case 3:
			PostHitFX('headtop', DamageType, rotator(Away), true);
			break;
		default:
			DoDamageFX('Bip01 L UpperArm', 1000, DamageType, rotator(Normal(Away - Side)) - rot(16384,0,0));
			DoDamageFX('Bip01 R UpperArm', 1000, DamageType, rotator(Normal(Away + Side)) - rot(16384,0,0));
			PostHitFX('headsplit', DamageType, rotator(Side), true);
	}
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
	TraumaRay = HitRay;
	if ( TraumaRay == vect(0,0,0) )
		TraumaRay = Normal(Momentum);

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

	// frozen solid, it chips like ice (and its killing blow shatters it: DeathGore)
	if ( bFrozen )
	{
		Spawn(class'KFIceHit',,, HitLocation, Rotator(HitNormal));
		if ( Health > 0 )
			return;
	}
	else if ( DamageType.Default.bCausesBlood && DamageType != class 'Burned' && DamageType != class 'DamTypeFlamethrower')
	{
		// a round striking flesh (not a blade's blow, nor a blast)
		if ( DamageType.default.bLocationalHit && !BladeGoreType(DamageType) && !IsPowerHit(DamageType)
			&& Level.TimeSeconds - LastFleshSound > 0.06 && FleshHitSounds[0] != None )
		{
			LastFleshSound = Level.TimeSeconds;
			PlaySound(FleshHitSounds[Rand(4)], SLOT_None, FleshHitVolume, false, 700.0, 0.9 + 0.2 * FRand());
		}
		if ( class'GameInfo'.static.UseLowGore() )
		{
			if ( class'GameInfo'.static.NoBlood() )
				BloodHit = BloodSpurt(Spawn( GibGroupClass.default.NoBloodHitClass,InstigatedBy,, HitLocation ));
			else
				BloodHit = BloodSpurt(Spawn( GibGroupClass.default.LowGoreBloodHitClass,InstigatedBy,, HitLocation ));
		}
		else
		{
			BloodHit = BloodSpurt(Spawn(BloodClassFor(Damage, DamageType),InstigatedBy,, HitLocation, Rotator(HitNormal)));
			if ( !ExitBurst(Damage, InstigatedBy, HitLocation, DamageType, Momentum, HitRay) )
				ExitMist(Damage, InstigatedBy, HitLocation, DamageType, HitRay);
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

	// (KFTrauma) the hole it leaves
	if ( !bFrozen && DamageType.default.bCausesBlood && DamageType.default.bLocationalHit && class<Burned>(DamageType) == None
		&& class<DamTypeFlamethrower>(DamageType) == None && !class'GameInfo'.static.UseLowGore() )
		class'KFTrauma'.static.NoteWound(self, HitLocation, TraumaRay, Damage, DamageType, InstigatedBy);

	if ( Health <= 0 && !bDeathGoreDone )
	{
		bDeathGoreDone = true;
		DeathGore(HitBone, Damage, DamageType, InstigatedBy, Rotator(HitNormal));
	}
	// a blade cuts a body that is down as it cuts one it kills
	else if ( Health <= 0 && BladeFresh(DamageType) )
		BladeGore(Damage, DamageType);
	// the rest of a blast that killed has been counted already; its late pellets add nothing
	else if ( Health > 0 || !IsPowerHit(DamageType) || Level.TimeSeconds - BlastKillTime > BlastWindow )
		DoDamageFX( HitBone, Damage, DamageType, Rotator(HitNormal) );

	if (DamageType.default.DamageOverlayMaterial != None && Damage > 0 ) // additional check in case shield absorbed
		SetOverlayMaterial( DamageType.default.DamageOverlayMaterial, DamageType.default.DamageOverlayTime, false );
}

// The blood off a hit is as big as the hit. A blade's is small: it is struck at arm's length, where a puff
// fills the view of the one swinging it, and its own spray is its big blood (KFMeleeFire.BladeSpray).
function class<Actor> BloodClassFor( float Damage, class<DamageType> DamageType )
{
	if ( BladeGoreType(DamageType) && BladeBloodClass != None )
		return BladeBloodClass;
	if ( Damage >= HeavyHitDamage && HeavyBloodClass != None )
		return HeavyBloodClass;
	return GibGroupClass.default.BloodHitClass;
}

// A power weapon, or any one great blow, bursts out of the far side of the body as well: once for a
// blast, however many pellets it came as.
function bool ExitBurst( float Damage, Pawn InstigatedBy, vector HitLocation, class<DamageType> DamageType, vector Momentum, vector HitRay )
{
	local vector Dir;
	local BloodSpurt Burst;

	// (a blade's blow sprays along the swing instead, KFMeleeFire.BladeSpray)
	if ( BurstBloodClass == None || Level.TimeSeconds - LastBurstTime < 0.3 || BladeGoreType(DamageType) )
		return false;
	if ( IsPowerHit(DamageType) )
	{
		if ( Health > 0 && BlastDamage < BurstBlastDamage )
			return false;
	}
	else if ( Damage < BurstHitDamage )
		return false;

	Dir = Momentum;
	if ( Dir == vect(0,0,0) )
		Dir = HitRay;
	if ( Dir == vect(0,0,0) )
		return false;
	Dir = Normal(Dir);
	Burst = BloodSpurt(Spawn(BurstBloodClass, InstigatedBy,, ExitSpot(HitLocation, Dir), rotator(Dir)));
	if ( Burst != None )
	{
		Burst.bMustShow = true;
		Burst.HitDir = Dir;
	}
	LastBurstTime = Level.TimeSeconds;
	return true;
}

// Out of the far side of the body, at the height the round went in
function vector ExitSpot( vector HitLocation, vector Dir )
{
	local vector Flat, Spot;

	Flat = Dir * vect(1,1,0);
	if ( VSize(Flat) > 0.3 )
	{
		Spot = Location + 0.8 * CollisionRadius * Normal(Flat);
		Spot.Z = FClamp(HitLocation.Z, Location.Z - 0.5 * CollisionHeight, Location.Z + 0.8 * CollisionHeight);
	}
	else Spot = HitLocation + CollisionRadius * Dir;
	return Spot;
}

// A round less than a burst leaves a small dark mist out of the far side (KFExitMist), not over and over in a burst
function ExitMist( float Damage, Pawn InstigatedBy, vector HitLocation, class<DamageType> DamageType, vector HitRay )
{
	local BloodSpurt Mist;

	if ( MistBloodClass == None || HitRay == vect(0,0,0) || Damage < MistHitDamage || Level.TimeSeconds - LastMistTime < 0.12
		|| !DamageType.default.bLocationalHit || BladeGoreType(DamageType) || IsPowerHit(DamageType) )
		return;
	Mist = Spawn(MistBloodClass, InstigatedBy,, ExitSpot(HitLocation, HitRay), rotator(HitRay));
	if ( Mist != None )
		Mist.HitDir = HitRay;
	LastMistTime = Level.TimeSeconds;
}

// A stun lasts until StunTime. (It used to borrow the timer the burn damage runs on: each blow that stunned
// put the next burn off, and each burn ended the stun early.)
function bool Stunned()
{
	if( bSTUNNED && Level.TimeSeconds >= StunTime )
		bSTUNNED = false;
	return bSTUNNED;
}

// A melee headshot from a perk that staggers what melee cannot stun otherwise (KFVeterancyTypes.HeadStaggerGap), now and then
function bool HeadStagger()
{
	local float Gap;

	if( !bLastHitHead || KFPawn(LastDamagedBy) == None || Level.TimeSeconds < NextHeadStaggerTime )
		return false;
	Gap = KFPawn(LastDamagedBy).GetVeteran().static.HeadStaggerGap(self);
	if( Gap <= 0 )
		return false;
	NextHeadStaggerTime = Level.TimeSeconds + Gap;
	return true;
}

function PlayDirectionalHit(Vector HitLoc)
{
	local Vector X,Y,Z, Dir;

	// (the flag was only read by a hit test no weapon uses any more)
	if( bMeleeStunImmune && ClassIsChildOf(LastDamagedbyType,class'DamTypeMelee') && !HeadStagger() )
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
	local KFHumanPawn Victim;

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


	  // (the victim held here: a blow that kills makes the controller let go of its target)
	  Victim = KFHumanPawn(Controller.Target);
	  if (Victim != None)
	  {
	   Victim.TakeDamage(hitdamage, Instigator ,HitLocation,pushdir, CurrentDamType); //class 'KFmod.ZombieMeleeDamage');

		  // (a killing blow can gib the body and remove it at once)
		  if (Victim == None || Victim.Health <=0)
		  {
		   if (Victim != None)
		   {
			BloodHit = Spawn(class'KFMod.FeedingSpray',self,,Victim.Location,rotator(pushdir));	 //
			Victim.SpawnGibs(rotator(pushdir), 1);
			TearBone=Victim.GetClosestBone(HitLocation,Velocity,dummy);
			Victim.HideBone(TearBone);
		   }

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
					RagDeathVel = DamageType.default.KDeathVel * BlastFling(DamageType);
					RagDeathUpKick = DamageType.default.KDeathUpKick * BlastFling(DamageType);
					// (bodies a blast kills fly further)
					if ( IsPowerHit(DamageType) && !DamageType.default.bLocationalHit )
					{
						RagDeathVel *= BlastThrowScale;
						RagDeathUpKick *= BlastThrowScale;
					}
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
					RagDeathVel = DamageType.default.KDeathVel * BlastFling(DamageType);
					RagDeathUpKick = DamageType.default.KDeathUpKick * BlastFling(DamageType);
					// (bodies a blast kills fly further)
					if ( IsPowerHit(DamageType) && !DamageType.default.bLocationalHit )
					{
						RagDeathVel *= BlastThrowScale;
						RagDeathUpKick *= BlastThrowScale;
					}
				}
			}

			// Set the dude moving in direction he was shot in general
			shotDir = Normal(TearOffMomentum);
			shotStrength = RagDeathVel * shotDir;
			// a blade's blow throws harder from behind, or on the run (KFMeleeFire.BodyThrow)
			if ( BladeThrown() )
				shotStrength *= FClamp(VSize(TearOffMomentum) / 100.0, 1.0, 2.0);

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

	StopLootGlow();
	StopZapFX();
	if ( SoakFX != None )
		SoakFX.Destroy();
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
	for ( i=0; i<Wounds.Length; i++ )
		if ( Wounds[i] != None )
			Wounds[i].Destroy();
	Wounds.Length = 0;
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
	bBurnTick = true;
	TakeDamage(Damage,BurnInstigator,DummyHitLoc,DummyMomentum,class 'DamTypeFlamethrower');
	bBurnTick = false;
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

	// a streak on the wall or floor a moving body is up against, now and then
	if ( VSize(Velocity) > 150 && Level.TimeSeconds > LastStreakTime + BloodStreakInterval && Level.TimeSeconds - LastRenderTime < 1.0 )
		WallActor = Trace(WallHit, WallNormal, Location + 60 * Normal(Velocity), Location, false);
	if ( WallActor != None )
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
	Smack(pos, impactVel, impactNorm);
}

// A body a blade has thrown smacks into what it comes down on: a thud, louder the harder it hits, and a little
// blood where it hit, the first few times. Only the speed into the surface counts; a body sliding or
// dragging its feet along it does not smack.
simulated function Smack( vector Pos, vector ImpactVel, vector ImpactNorm )
{
	local vector HitLoc, HitNorm;
	local float Into;

	Into = ImpactVel dot ImpactNorm;
	if ( SmacksLeft <= 0 || Into < SmackSpeed || Level.TimeSeconds - LastSmackTime < 0.25 )
		return;
	SmacksLeft--;
	LastSmackTime = Level.TimeSeconds;
	if ( SmackSounds.Length > 0 )
		PlaySound(SmackSounds[Rand(SmackSounds.Length)], SLOT_None, FMin(Into / SmackSpeed, 2.0) * RagImpactVolume);
	if ( Level.TimeSeconds - LastRenderTime > 1.0 || class'GameInfo'.static.UseLowGore() )
		return;
	if ( Trace(HitLoc, HitNorm, Pos - 40.0 * ImpactNorm, Pos + 20.0 * ImpactNorm, false) != None )
		Spawn(class'KFBloodSmack',,, HitLoc + 20.0 * HitNorm, rotator(-HitNorm));
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

// How many seconds a specimen set alight by From burns: longer in an upgraded flamethrower's fire
function int BurnTime( Pawn From )
{
	if ( From != None && FlameThrower(From.Weapon) != None && FlameThrower(From.Weapon).bUpgraded )
		return 15;
	return 10;
}

// Heat from an upgraded gun's incendiary round: enough of it and the specimen burns, as from a flame (one burning
// already burns longer). No harm of its own.
function TakeIncendiary( int Heat, Pawn From )
{
	if ( Health <= 0 || bDeleteMe )
		return;
	if ( BurnDown > 0 )
	{
		if ( !bBurnTick && BurnDown < 10 )
			BurnDown++;
		return;
	}
	HeatAmount += Heat;
	if ( HeatAmount <= 4 )
		return;
	LastBurnDamage = Max(LastBurnDamage, 5);
	bBurnified = true;
	BurnDown = 10;
	SetGroundSpeed(GroundSpeed);
	BurnInstigator = From;
	SetTimer(1.0, true);
}

// The blow of an upgraded double barrel: a light specimen is thrown off its feet and back (Push), a heavy one stumbles
function KnockBack( vector From, vector Push )
{
	local name Seq;
	local float Frame, Rate;

	if ( Health <= 0 || KFMonsterController(Controller) == None )
		return;
	GetAnimParams(0, Seq, Frame, Rate);
	if ( bShotAnim && IsAnimating(0) && Seq == 'StunState' )
		return;
	if ( default.Health < 400 && FlipOver() )
	{
		AddVelocity(Push);
		return;
	}
	BlastStagger(From);
}

defaultproperties
{
	bClimbs=True
	ClimbMax=90.000000
	ClimbSpeed=240.000000
	ClimbOverSpeed=160.000000
	MistBloodClass=Class'KFMod.KFExitMist'
	MistHitDamage=15
	FleshHitSounds(0)=Sound'KFWeaponSound.bullethitflesh2'
	FleshHitSounds(1)=Sound'KFWeaponSound.bullethitflesh3'
	FleshHitSounds(2)=Sound'KFWeaponSound.bullethitflesh4'
	FleshHitSounds(3)=Sound'KFWeaponSound.bullethitflesh5'
	FleshHitVolume=1.200000
     SoundOcclusion=OCCLUSION_StaticMeshes
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
     MaxWounds=14
     LimbBlast=0.500000
     TorsoBlast=1.300000
     BodyBlast=2.500000
     ObliterateShare=0.300000
     SplitBand=14.000000
     OverkillShare=0.250000
     CorpseBlastGib=0.250000
     CorpseBlastLimb=0.600000
     AshCrumbleChance=0.500000
     BlastThrowScale=1.350000
     BlastWindow=0.250000
     CorpseGibHealth=-400
     DownCutReach=12.000000
     SmackSpeed=300.000000
     SmackMarks=2
     SmackSounds(0)=Sound'PlayerSounds.ImpactSounds.BodyHit3'
     SmackSounds(1)=Sound'PlayerSounds.ImpactSounds.BodyHit4'
     SmackSounds(2)=Sound'PlayerSounds.ImpactSounds.BodyHit5'
     SmackSounds(3)=Sound'PlayerSounds.ImpactSounds.BodyHit6'
     bOwnLimbs=True
     ZapDropAfter=0.600000
     AshCrumbleDamage=30
     FrozenDamageScale=1.500000
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
     bHeadDirFix=True
     DifficultyHealthScales(0)=0.500000
     DifficultyHealthScales(1)=1.000000
     DifficultyHealthScales(2)=1.350000
     DifficultyHealthScales(3)=1.550000
     DifficultyHealthScales(4)=1.750000
     DifficultyDamageScales(0)=0.300000
     DifficultyDamageScales(1)=1.000000
     DifficultyDamageScales(2)=1.250000
     DifficultyDamageScales(3)=1.500000
     DifficultyDamageScales(4)=1.750000
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
	 GibCharShare=0.500000
	 CorpseSmokeClass=Class'KFMod.KFCorpseSmoke'
	 HeavyBloodClass=Class'KFMod.KFBloodPuffHeavy'
	 BurstBloodClass=Class'KFMod.KFBloodBurst'
	 BladeBloodClass=Class'KFMod.KFBladeHitPuff'
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
