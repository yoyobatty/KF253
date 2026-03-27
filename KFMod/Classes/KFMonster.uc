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

<<<<<<< HEAD
var int LookRotPitch,LookRotYaw;
var Pawn LookTarget;

=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
var int HitMomentum;

var class <KFGib> HeadStubClass;
var KFGib HeadStub;

var Vector LastBloodHitDirection;
var Bool bRanged;

var() bool bStunImmune; // is the zombie immune to stun hit effects?
var bool bSTUNNED;
var bool bDecapitated; // has he lost his noggin'!?
var int  Gored; // Has he lost his whole torso?! if so, how much of it?
var bool DECAP;
<<<<<<< HEAD
var() bool bDurableHead; // if true, the zombie's health comes into play when determining a decap.
var bool bBurnified;
var bool bBurnApplied;
var byte HeatAmount;
=======
var bool bBurnified;
var bool bBurnApplied;
var byte HeatAmount;
var()	float	BleedOutDuration;   // How long this zombie survives after losing its head
var		float	BleedOutTime;       // When this zombie will die from bleeding out
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

var() bool bCannibal;  // If true, this enemy will stop to eat corpses it finds.

var float StunTime, LastPuntTime, DecapTime;

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
<<<<<<< HEAD

=======
var	bool bLeftArmGibbed;			// LeftArm is already blown off
var	bool bRightArmGibbed;		// RightArm is already blown off
var	bool bLeftLegGibbed;			// LeftLeg is already blown off
var	bool bRightLegGibbed;		// RightLeg is already blown off
var	bool bHeadGibbed;		    // Head is already blown off
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
var bool bPlayBrainSplash;
var bool bPlayGoreSplash;
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
<<<<<<< HEAD

=======
var() float HeadHealth;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
var() bool bMeleeStunImmune; // if true, this monster cannot be stunned or staggered by melee blows

// Fire Related

var int BurnDown ; // Number of times our zombie must suffer Fire Damage.
var bool bAshen; // is our Zed crispy yet?
var class<Emitter> BurnEffect;  // The appearance of the flames we are attaching to our Zed.
var int LastBurnDamage; // Record the last amount of Fire damage the pawn suffered.


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
<<<<<<< HEAD
=======
var bool SavedExtCollision;          // Saved original state of the external collision

var float LastViewCheckTime;      // internal use, used to see how long its been since we checked if there was line of site between this Zed and the local player controller
var float OriginalGroundSpeed;// The difficulty adjusted ground speed (need to store this off, because we have to restore this value at certain times)
var() float HiddenGroundSpeed;      // How fast this Zed should move when it's out of view;

var bool bDestroyNextTick; // Destroy this pawn next tick because destroying it now will cause problems
var float TimeSetDestroyNextTickTime; // The time we set the bDestroyNextTick flag

var bool    bDestroyAfterRagDollTick;   // Wait until the ragdoll tick has happened and then destroy. Prevents crashes where we try and destroy the actor right after initializing ragdoll
var bool    bProcessedRagTickDestroy;   // Already called destroy for a bDestroyAfterRagDollTick setting

var() Sound DecapSound;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

replication
{
	reliable if(Role == ROLE_Authority)
<<<<<<< HEAD
		bDecapitated,Gored,LookTarget,bBurnified,bAshen,FeedThreshold,bCannibal,bDiffAdjusted,bCloaked;
=======
		bDecapitated,Gored,bBurnified,bAshen,FeedThreshold,bCannibal,bDiffAdjusted,bCloaked;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

function bool MakeGrandEntry()
{
	Return False;
}
function bool Cloaked()
{ 
	return bCloaked;
}
simulated Function PostNetBeginPlay()
{
<<<<<<< HEAD
	if( bUseExtendedCollision && Health>0 )
	{
		MyExtCollision = Spawn(Class'ExtendedZCollision',Self,,Location+ColOffset);
		MyExtCollision.Offset = ColOffset;
		MyExtCollision.SetCollisionSize(ColRadius,ColHeight);
	}
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
<<<<<<< HEAD

=======
	local KFMonster KFMonst;


	KFMonst = KFMonster(Other);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
<<<<<<< HEAD
=======
	if( KFMonst!=None && Pawn(Other).Health>0 )
	{
		if(bBurnified && bBurnApplied && !KFMonst.bBurnApplied && !KFMonst.bBurnified)
		{
			Other.TakeDamage(15, self, Other.Location,Vect(0,0,0), class'Burned');
			//log("Enemy caught fire" $self);
		}
	}
        
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
<<<<<<< HEAD
=======
	local vector AttachPos;
	local float ScalingFactor;

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	if(ROLE==ROLE_Authority)
	{
		if ( (ControllerClass != None) && (Controller == None) )
			Controller = spawn(ControllerClass);
		
		if ( Controller != None )
			Controller.Possess(self);

<<<<<<< HEAD
=======
		if (Controller != none)
        	MyAmmo = spawn(AmmunitionClass);

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		SplashTime = 0;
		SpawnTime = Level.TimeSeconds;
		EyeHeight = BaseEyeHeight;
		OldRotYaw = Rotation.Yaw;
		if( HealthModifer!=0 )
			Health = HealthModifer;
<<<<<<< HEAD
	}

=======

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
	}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

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
		// Some randomization to their walk speeds.
		GroundSpeed = default.GroundSpeed - (0.5*default.Groundspeed) + (rand(default.groundspeed*0.5) + (0.25 * default.groundspeed));
<<<<<<< HEAD

		GroundSpeed += (Level.Game.GameDifficulty * 3);
		AirSpeed += (Level.Game.GameDifficulty * 3);
		WaterSpeed += (Level.Game.GameDifficulty * 3);

		Health *= (Level.Game.GameDifficulty / 3);
		HealthMax *= (Level.Game.GameDifficulty / 3);
		damageConst *= (Level.Game.GameDifficulty / 3);
		damageRand *= (Level.Game.GameDifficulty / 3);

		SpinDamConst *= (Level.Game.GameDifficulty / 3);
		SpinDamRand *= (Level.Game.GameDifficulty / 3);
	
		ScreamDamage *= (Level.Game.GameDifficulty / 3);
	
		bDiffAdjusted = true;
	}
      if( Level.NetMode!=NM_DedicatedServer )
=======
		if (Level.Game.GameDifficulty <= 3)
		{
			ScalingFactor = 0.75 + (Level.Game.GameDifficulty - 1) * 0.125;
		}
		else
		{
			ScalingFactor = 1.0 + (Level.Game.GameDifficulty - 3) * 0.3;
		}
		GroundSpeed += (Level.Game.GameDifficulty * 3);
		AirSpeed += (Level.Game.GameDifficulty * 3);
		WaterSpeed += (Level.Game.GameDifficulty * 3);
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
		if ( Level.Game.GameDifficulty >= 5.0 ) // Hard/Skilled
		{
			Intelligence = BRAINS_Human;
			//log(GetHumanReadableName()$" monster Intelligence is: "$Intelligence);
		}
	
		bDiffAdjusted = true;
	}
    if( Level.NetMode!=NM_DedicatedServer )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	{
		AdditionalWalkAnims[AdditionalWalkAnims.length] = default.MovementAnims[0];
		MovementAnims[0] = AdditionalWalkAnims[Rand(AdditionalWalkAnims.length)]; 
	}
}

<<<<<<< HEAD
simulated function bool IsMoreThanHalf ( int AngleRot )
{
	if ( AngleRot > 32768 )
		return True;
	else return False;
=======
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
				NumEnemies+= 0.5; // Bots count as half a player
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
    GroundSpeed = NewGroundSpeed;
}

// Setters for extra collision cylinders
simulated function ToggleAuxCollision(bool newbCollision)
{
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

simulated function Tick(float DeltaTime)
{
<<<<<<< HEAD
	local float GibPerterbation;
	local BrainSplash SplatExplosion;
	local GibExplosion GibbedExplosion;
	local Vector SplatLocation;
	local Rotator R;
=======
	local Controller C;
	local Pawn PawnCheck;
	local float Dist;
	local bool bSeen;

	if (Level.NetMode != NM_Client && CanSpeedAdjust())
	{
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	if( bResetAnimAct && ResetAnimActTime<Level.TimeSeconds )
	{
		AnimAction = '';
		bResetAnimAct = True;
	}
<<<<<<< HEAD
	if(Controller!=None && Controller.Enemy != none )
		LookTarget = Controller.Enemy;

	//SPLATTER!!!!!!!!!
	//TODO - can we work this into Epic's gib code?
	//Will we see enough improvement in efficiency to be worth the effort?
	if( Level.NetMode!=NM_DedicatedServer )
	{
		if( LookTarget!=None )
		{
			R = Normalize(rotator(LookTarget.Location-Location)-Rotation);
			R.Pitch = 0;
			R.Roll = 0;
			if( R.Yaw>18000 )
				R.Yaw = 18000;
			else if( R.Yaw<-18000 )
				R.Yaw = -18000;
			R.Pitch = R.Yaw;
			R.Yaw = 0;
			SetBoneDirection('Bip01 Head',R*-1.8,,0.5);
		}
		else SetBoneDirection('Bip01 Head',rot(0,0,0),,0.5);
		if( bBurnified && !bBurnApplied )
			StartBurnFX();
=======

	// If the Zed has been bleeding long enough, make it die
	if ( Role == ROLE_Authority && bDecapitated )
	{
		if ( BleedOutTime > 0 && Level.TimeSeconds - BleedOutTime >= 0 )
		{
			Died(LastDamagedBy.Controller,class'DamTypeMelee',Location);
			BleedOutTime=0;
		}

	}

	if( Level.NetMode!=NM_DedicatedServer )
	{
		TickFX(DeltaTime);

		if( bBurnified && !bBurnApplied )
		{
			if ( !bGibbed )
			{
				StartBurnFX();
			}
		}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		else if( !bBurnified && bBurnApplied )
			StopBurnFX();

		if( bAshen && Level.NetMode==NM_Client )
		{
			ZombieCrispUp();
			bAshen = False;
		}
<<<<<<< HEAD

		if(bDecapitated && !bPlayBrainSplash )
		{
			SplatLocation = self.Location;
			SplatLocation.z += CollisionHeight;
			GibPerterbation = 0.060000; // damageType.default.GibPerterbation;
			HideBone('bip01 head');
			if (HeadStub == none && HeadStubClass != none)
			{
				HeadStub = Spawn(HeadStubClass,Self,'',Location);
				AttachToBone( HeadStub,'Bip01 head');
			}
			if ( EffectIsRelevant(Location,false) )
			{
				SpawnGiblet( class 'KFMod.KFGibBrain',SplatLocation, self.Rotation, GibPerterbation ) ;
				SpawnGiblet( class 'KFMod.KFGibBrainb',SplatLocation, self.Rotation, GibPerterbation ) ;
				SpawnGiblet( class 'KFMod.KFGibBrain',SplatLocation, self.Rotation, GibPerterbation ) ;
			}
			SplatExplosion = Spawn(class 'BrainSplash',self,, SplatLocation );
			bPlayBrainSplash = true;
		}
		if (Gored>0 && !bPlayGoreSplash)
		{
			SplatLocation = self.Location;
			SplatLocation.z += (CollisionHeight - (CollisionHeight * 0.5));
			GibPerterbation = 0.060000; //damageType.default.GibPerterbation;
			if (Gored == 1)
				HideBone('Bip01 L Clavicle');   // off with his left arm then!
			else if (Gored == 2)
				HideBone('Bip01 R Clavicle');   // or his right!
			else if (Gored == 3)
			{
				HideBone('Bip01 Spine2');  // or the whole bleedin' upper body.
				if (GoredMat != none)
					Skins[0] = GoredMat;
			}
			else if (Gored == 4)
				HideBone('Bip01 Spine1'); // or everything but the legs!!!! :)

			//Log("I WAS GORED! SHOWING FX");

                        if ( EffectIsRelevant(Location,false) && Gored < 5 )
			{
				Spawn(class'KFMod.BrainSplash',,,SplatLocation,Self.Rotation);
				SpawnGiblet( class 'KFMod.KFGibBrain',SplatLocation, self.Rotation, GibPerterbation ) ;
				SpawnGiblet( class 'KFMod.KFGibBrainb',SplatLocation, self.Rotation, GibPerterbation ) ;
				SpawnGiblet( class 'KFMod.KFGibBrain',SplatLocation, self.Rotation, GibPerterbation ) ;
			}
			else if ( EffectIsRelevant(Location,false) && Gored == 5 )
			{
			//	Log("CHUNKED UP!");


                                Spawn(class'KFMod.BodySplash',,,SplatLocation,Self.Rotation);

				if (!bDecapitated)
					SpawnGiblet(MonsterHeadGiblet,SplatLocation, self.Rotation, GibPerterbation ) ;

				SpawnGiblet(MonsterTorsoGiblet,SplatLocation, self.Rotation, GibPerterbation ) ;
				SpawnGiblet(MonsterLowerTorsoGiblet,SplatLocation, self.Rotation, GibPerterbation ) ;

				SpawnGiblet(MonsterArmGiblet,SplatLocation, self.Rotation, GibPerterbation ) ;
				SpawnGiblet(MonsterArmGiblet,SplatLocation, self.Rotation, GibPerterbation ) ;

				SpawnGiblet(MonsterThighGiblet,SplatLocation, self.Rotation, GibPerterbation ) ;
				SpawnGiblet(MonsterThighGiblet,SplatLocation, self.Rotation, GibPerterbation ) ;

				SpawnGiblet(MonsterLegGiblet,SplatLocation, self.Rotation, GibPerterbation ) ;
				SpawnGiblet(MonsterLegGiblet,SplatLocation, self.Rotation, GibPerterbation ) ;
				
				GibbedExplosion = Spawn(class 'GibExplosion',self,, SplatLocation );
			//	bPlayGibSplash = true;


			}
			SplatExplosion = Spawn(class 'BrainSplash',self,, SplatLocation );
			bPlayGoreSplash = true;
		}
	}
=======
	}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
<<<<<<< HEAD

	if(Health <= 0)
         Disable('Tick');
	
=======
    if( Physics == PHYS_KarmaRagdoll && bDestroyAfterRagDollTick &&
        !bProcessedRagTickDestroy )
    {
        bProcessedRagTickDestroy = true;
        Destroy();
    }
    // If we've flagged this character to be destroyed next tick, handle that
    else if( bDestroyNextTick && TimeSetDestroyNextTickTime < Level.TimeSeconds )
    {
        Destroy();
    }
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

function TakeBileDamage()
{
<<<<<<< HEAD
=======
    if (bDeleteMe || Health <= 0)
        return;

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	Super.TakeDamage(2+Rand(3), BileInstigator, Location, vect(0,0,0), class'DamTypeVomit');
}

simulated function StartBurnFX()
{
<<<<<<< HEAD
=======
    if( bDeleteMe )
    {
        return;
    }

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	if( FlamingFXs==None )
		FlamingFXs = Spawn(BurnEffect);
	FlamingFXs.SetBase(Self);
	FlamingFXs.Emitters[0].SkeletalMeshActor = self;
<<<<<<< HEAD
=======
	FlamingFXs.Emitters[0].UseSkeletalLocationAs = PTSU_SpawnOffset;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	AttachEmitterEffect(BurnEffect,'Bip01 head',Location,Rotation);
	bBurnApplied = True;
}

simulated function StopBurnFX()
{
	RemoveFlamingEffects();
	if( FlamingFXs!=None )
		FlamingFXs.Kill();
	bBurnApplied = False;
}

// High damage was taken, make em fall over.
function bool FlipOver()
{
	if( Physics==PHYS_Falling )
<<<<<<< HEAD
		SetPhysics(PHYS_Walking);
	bShotAnim = true;
	SetAnimAction('KnockDown');
	Acceleration = vect(0,0,0);
=======
	{
		SetPhysics(PHYS_Walking);
	}

	bShotAnim = true;
	SetAnimAction('KnockDown');
	Acceleration = vect(0, 0, 0);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	Velocity.X = 0;
	Velocity.Y = 0;
	Controller.GoToState('WaitForAnim');
	KFMonsterController(Controller).bUseFreezeHack = True;
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
	else if (DamageType.name == 'DamTypeShotgun' || DamageType.name == 'DamTypeDBShotgun' || DamageType.name == 'DamTypeFrag')
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

simulated function DoDamageFX( Name boneName, int Damage, class<DamageType> DamageType, Rotator r )
{
	local float DismemberProbability;
<<<<<<< HEAD
	local bool bExtraGib;
	local float PertDummy;
	//local float GibPerterbation;

	PertDummy = 1;

	if ( FRand() > 0.3f || Damage > 30 || Health <= 0 || DamageType == class 'DamTypeCrossbowHeadshot')
	{
		HitFX[HitFxTicker].damtype = DamageType;

		if( Health <= 0 || DamageType == class 'DamTypeCrossbowHeadshot')
		{
			switch( boneName )
			{
=======
	local int RandBone;
	local bool bExtraGib;

	if ( (FRand() > 0.3f || Damage > 30 || Health <= 0) )
	{
		HitFX[HitFxTicker].damtype = DamageType;

		if( Health <= 0 )
		{
			switch( boneName )
			{
				case 'Bip01 Neck':
					boneName = HeadBone;
					break;

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
				case 'Bip01 L Foot':
					boneName = 'Bip01 L Thigh';
					break;

				case 'Bip01 R Foot':
					boneName = 'Bip01 R Thigh';
					break;

				case 'Bip01 R Hand':
<<<<<<< HEAD
					boneName = 'rfarm';
=======
					boneName = 'Bip01 R Forearm';
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
					break;

				case 'Bip01 L Hand':
					boneName = 'Bip01 L Forearm';
					break;

<<<<<<< HEAD
				case 'Bip01 R Clavicle':
				case 'Bip01 L Clavicle':
					boneName = 'Bip01 Spine';
=======
				case 'None':
				case 'Bip01 Spine':
					boneName = FireRootBone;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
					break;
			}

			if( DamageType.default.bAlwaysSevers || (Damage == 1000) )
			{
				HitFX[HitFxTicker].bSever = true;
<<<<<<< HEAD
				if ( boneName == 'None' )
				{
					boneName = 'Bip01 R Forearm';
					bExtraGib = true;
				}
			}
				  else if( (Damage*DamageType.Default.GibModifier > 50+120*FRand()-9999999999) && (Damage >= 0) ) // total gib prob
			{
				HitFX[HitFxTicker].bSever = true;
				boneName = 'Bip01 R Forearm';
				bExtraGib = true;
			}
			else
			{

								//boneCoords = GetBoneCoords( HitFX[SimHitFxTicker].bone );
								//Spawn(class'KFMod.BrainSplash',,,boneCoords.Origin,Self.Rotation);	 //hacked


								DismemberProbability = Abs( (Health - Damage*DamageType.Default.GibModifier) / 130.0f );
				switch( boneName )
				{
					case 'Bip01 L Thigh':
					case 'Bip01 R Thigh':
					case 'Bip01 R Forearm':
					case 'Bip01 L Forearm':
					case 'Bip01 Spine':
					case 'Bip01 Head':
						if( FRand() < DismemberProbability )
							HitFX[HitFxTicker].bSever = true;
						break;


					case 'Bip01 Head':
						boneName = 'Bip01 Head';
					 case 'Bip01 Head':
						if( FRand() < DismemberProbability * 0.3 )
						{
							HitFX[HitFxTicker].bSever = true;
							if ( FRand() < 0.65 )
								bExtraGib = true;
						}
						break;
=======
				bExtraGib = true;
				//Level.Game.broadcast(self, "1000 Dam Extra gib on "$GetHumanReadableName());
				if ( boneName == 'None' )
				{
					boneName = FireRootBone;
				}
			}
			else if( DamageType.Default.GibModifier > 0.0 )
			{
	            DismemberProbability = Abs( (Health - Damage*DamageType.Default.GibModifier) / 130.0f );

				if( FRand() < DismemberProbability )
				{
					HitFX[HitFxTicker].bSever = true;
					bExtraGib = true;
					//log("GibModifier Extra gib on "$GetHumanReadableName()$" at bone "$boneName$" bsever is "$HitFX[HitFxTicker].bSever$" DismemberProbability is "$DismemberProbability);
					//Level.Game.broadcast(self, "Extra gib on "$GetHumanReadableName());
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
				}
			}
		}

		if ( DamageType.default.bNeverSevers || class'GameInfo'.static.UseLowGore()
<<<<<<< HEAD
		 || (Level.Game != None && Level.Game.PreventSever(self, boneName, Damage, DamageType)) )
		{
		HitFX[HitFxTicker].bSever = false;
		bExtraGib = false;
	}
=======
			|| (Level.Game != None && Level.Game.PreventSever(self, boneName, Damage, DamageType)) )
		{
			HitFX[HitFxTicker].bSever = false;
			bExtraGib = false;
		}

		if ( HitFX[HitFxTicker].bSever )
		{
	        if( !DamageType.default.bLocationalHit && (boneName == 'None' || boneName == FireRootBone ||
				boneName == 'Bip01 Spine' ))
	        {
	        	RandBone = Rand(4);

				switch( RandBone )
	            {
	                case 0:
						boneName = 'Bip01 L Thigh';
						break;
	                case 1:
						boneName = 'Bip01 R Thigh';
						break;
	                case 2:
						boneName = 'Bip01 L Forearm';
	                    break;
	                case 3:
						boneName = 'Bip01 R Forearm';
	                    break;
					case 4:
						boneName = 'Bip01 Head';
	                    break;
	                default:
	                	boneName = 'Bip01 L Thigh';
	            }
	        }
		}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

		HitFX[HitFxTicker].bone = boneName;
		HitFX[HitFxTicker].rotDir = r;
		HitFxTicker = HitFxTicker + 1;
		if( HitFxTicker > ArrayCount(HitFX)-1 )
			HitFxTicker = 0;
<<<<<<< HEAD
		if ( bExtraGib )
		{
		if ( FRand() < 0.25 )
		{
			DoDamageFX('Bip01 L Forearm',1000,DamageType,r);
			DoDamageFX('Bip01 R Forearm',1000,DamageType,r);
		}
		else if ( FRand() < 0.35 )
			DoDamageFX('Bip01 L Thigh',1000,DamageType,r);
		else if ( FRand() < 0.5 )
			DoDamageFX('Bip01 Head',1000,DamageType,r);

		else
		 DoDamageFX('Bip01 Head',1000,DamageType,r);


		}
=======
        if ( bExtraGib && !DamageType.default.bLocationalHit && Damage > 200 && Damage != 1000 && !class'GameInfo'.static.UseLowGore() )
        {
			//Level.Game.Broadcast(self, "bExtraGib called on "$GetHumanReadableName()$" at bone "$boneName);
            if ( Damage > 400 && FRand() < 0.3 )
            {
                if ( FRand() < 0.35 )
                    DoDamageFX('Bip01 Head', 1000, DamageType, r);

                if ( FRand() < 0.25 )
                {
                    DoDamageFX('Bip01 L Thigh',   1000, DamageType, r);
                    DoDamageFX('Bip01 R Thigh',   1000, DamageType, r);
                }

                if ( FRand() < 0.20 )
                {
                    DoDamageFX('Bip01 L Forearm', 1000, DamageType, r);
                    DoDamageFX('Bip01 R Forearm', 1000, DamageType, r);
                }
            }
			if ( FRand() < 0.25 )
			{
				DoDamageFX('Bip01 L Forearm', 1000, DamageType, r);
				DoDamageFX('Bip01 R Forearm', 1000, DamageType, r);
			}
			else if ( FRand() < 0.60 )
			{
				if ( FRand() < 0.5 )
					DoDamageFX('Bip01 L Thigh', 1000, DamageType, r);
				else
					DoDamageFX('Bip01 R Thigh', 1000, DamageType, r);
			}
			else
			{
				DoDamageFX('Bip01 Head', 1000, DamageType, r);
			}
        }
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	}
}

//Stops the green shit when a player dies.
simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	local float frame, rate;
	local name seq;
	local LavaDeath LD;
	local MiscEmmiter BE;
	
	//make sure dismemberments etc aquired while alive carry onto corpse
	if(bDecapitated)
	{
		HideBone('bip01 head');
	  
		if (HeadStub == none && HeadStubClass != none)
		{
			HeadStub = Spawn(HeadStubClass,Self,'',Location);
			AttachToBone( HeadStub,'Bip01 head');
		}
	}

<<<<<<< HEAD
	if (Gored>0)
	{
		if (Gored == 1)
			HideBone('Bip01 L Clavicle');   // off with his left arm then!
		else if (Gored == 2)
			HideBone('Bip01 R Clavicle');   // or his right!
		else if (Gored == 3)
			HideBone('Bip01 Spine2');  // or the whole bleedin' upper body.
		else if (Gored == 4)
			HideBone('Bip01 Spine1'); // or everything but the legs!!!! :)
		else if (Gored == 5)
		{
			HideBone('Bip01');
			bHidden = true;
		}
	}

=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	AmbientSound = None;
	bCanTeleport = false; // sjs - fix karma going crazy when corpses land on teleporters
	bReplicateMovement = false;
	bTearOff = true;
	bPlayedDeath = true;
	StopBurnFX();

	if (CurrentCombo != None)
		CurrentCombo.Destroy();

	HitDamageType = DamageType; // these are replicated to other clients
	TakeHitLocation = HitLoc;

	bSTUNNED = false;
	bMovable = true;
			 
	if (DamageType == class 'Burned' ||  DamageType == class 'DamTypeFlamethrower')
		ZombieCrispUp();
<<<<<<< HEAD
	ProcessHitFX() ;
=======

	ProcessHitFX();
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

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

<<<<<<< HEAD
	
	// Try to adjust around performance
	
	//log(Level.DetailMode);

=======
	LifeSpan = RagdollLifeSpan;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

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
		SetPhysics(PHYS_None);
		SetCollision(false, false, false);

		if ( !IsAnimating(0) )
			LandThump();
<<<<<<< HEAD
		Super.Landed(HitNormal);
	}
	simulated function Timer()
	{
		if( Level.NetMode==NM_DedicatedServer )
		{
			Destroy();
			Return;
		}
		if( Physics!=PHYS_None )
		{
			if( VSize(Velocity)>10 )
			{
				SetTimer(1,False);
				Return;
			}
			Disable('TakeDamage');
			SetPhysics(PHYS_None);
			SetTimer(30,False);
			if(PlayerShadow != None)
				PlayerShadow.bShadowActive = false;
		}
		else if( (Level.TimeSeconds-LastRenderTime)>40 || Level.bDropDetail )
			Destroy();
		else SetTimer(5,False);
	}
	simulated function BeginState()
	{
		if( Controller!=None )
			Controller.Destroy();
		if( Level.NetMode==NM_DedicatedServer )
			SetTimer(1,False);
		SetTimer(5,False);
	}
}
=======
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
			StartDeRes();
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
		local emitter BloodHit;
		local Vector HitNormal, shotDir;
		local Vector PushLinVel, PushAngVel;
		local rotator HitRotation;
		local bool bIsHeadshot;
		local vector HitRay;
		local Name HitBone;
		local float HitBoneDist;

		if( Physics == PHYS_KarmaRagdoll )
		{
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

				if( bIsHeadShot )
					RemoveHead();

				HitRay = vect(0,0,0);
				if( InstigatedBy != none )
					HitRay = Normal(HitLocation-(InstigatedBy.Location+(vect(0,0,1)*InstigatedBy.EyeHeight)));

				CalcHitLoc( HitLocation, HitRay, HitBone, HitBoneDist );

				if( InstigatedBy != None )
					HitNormal = Normal( Normal(InstigatedBy.Location-HitLocation) + VRand() * 0.2 + vect(0,0,2.8) );
				else
					HitNormal = Normal( Vect(0,0,1) + VRand() * 0.2 + vect(0,0,2.8) );

				HitRotation = Rotator(HitNormal);
				PlayHit(Damage,InstigatedBy,HitLocation,DamageType,Momentum);
				DoDamageFX( HitBone, Damage, DamageType, Rotator(HitNormal) );
				if (!bPlayGoreSplash && Health <= -400 && (	(FRand() < 0.05 && VSize(instigatedBy.location - Location) < 200.f && (DamageType == class 'DamTypeShotgun' || DamageType == class 'DamTypeDBShotgun')) || FRand() < 0.7 && DamageType == class 'DamTypeFrag') )
				{
					//Level.Game.Broadcast(self, "Gibbing corpse "$GetHumanReadableName());
					// Gibbed
					bPlayGoreSplash = true;

					bFlaming = DamageType.default.bFlaming || bBurnApplied;

					BloodHit = Spawn(class'KFMod.FeedingSpray',InstigatedBy,,Hitlocation,Rotation);

					Spawn(class'KFMod.BodySplash',,,Hitlocation,Rotation);

					if (!bDecapitated)
						SpawnGiblet(MonsterHeadGiblet,Hitlocation, HitRotation, 1.0 ) ;
					HitLocation.Z += (CollisionHeight * 0.4); //Spawn a little up from ground
					SpawnGiblet(MonsterTorsoGiblet,Hitlocation, HitRotation, 1.0 ) ;
					SpawnGiblet(MonsterLowerTorsoGiblet,Hitlocation, HitRotation, 1.0 ) ;
					SpawnGiblet(MonsterArmGiblet,Hitlocation, HitRotation, 1.0 ) ;
					SpawnGiblet(MonsterArmGiblet,Hitlocation, HitRotation, 1.0 ) ;
					SpawnGiblet(MonsterThighGiblet,Hitlocation, HitRotation, 1.0 ) ;
					SpawnGiblet(MonsterThighGiblet,Hitlocation, HitRotation, 1.0 ) ;
					SpawnGiblet(MonsterLegGiblet,Hitlocation, HitRotation, 1.0 ) ;
					SpawnGiblet(MonsterLegGiblet,Hitlocation, HitRotation, 1.0 ) ;
					if( Physics == PHYS_KarmaRagdoll )
					{
						bDestroyAfterRagDollTick = true;
					}
					else
					{
						Destroy();
					}
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
				if ( Momentum == vect(0,0,0) )
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

simulated function Timer()
{
	/*local int RandomNumber;
	local Rotator DefaultTorsoRotation;*/

	// lets see if this helps the soldier bots pick up on the fact that there's a growling zombie right behind them
	MakeNoise(1.0);

	bSTUNNED = false;

<<<<<<< HEAD


	if (BurnDown > 0)
		TakeFireDamage(LastBurnDamage + rand(2) + 3 , LastDamagedBy);
=======
	if (BurnDown > 0)
	{
		TakeFireDamage(LastBurnDamage + rand(2) + 3 , LastDamagedBy);
		SetTimer(1.0,false); // Sets timer function to be executed each second
	}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
	local float GibPerterbation;
<<<<<<< HEAD

	j = 0 ;
	i = 0 ;
=======
	
	//log("ProcessHitFX");
	//Level.Game.Broadcast(self, "ProcessHitFX called on "$GetHumanReadableName());
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	if( (Level.NetMode == NM_DedicatedServer) || bSkeletized || (Mesh == SkeletonMesh) )
	{
		SimHitFxTicker = HitFxTicker;
		return;
	}

	for ( SimHitFxTicker = SimHitFxTicker; SimHitFxTicker != HitFxTicker; SimHitFxTicker = (SimHitFxTicker + 1) % ArrayCount(HitFX) )
	{
		j++;
		//log("complex for loop "$j) ;
		if ( j > 30 )
		{
			SimHitFxTicker = HitFxTicker;
			return;
		}

		if( (HitFX[SimHitFxTicker].damtype == None) || (Level.bDropDetail && (Level.TimeSeconds - LastRenderTime > 3) && !IsHumanControlled()) )
			continue;

		boneCoords = GetBoneCoords( HitFX[SimHitFxTicker].bone );

<<<<<<< HEAD
				//log("brains") ;																//Simply a hack, sorry.
				//Spawn(class'KFMod.BrainSplash',,,boneCoords.Origin,Self.Rotation);
=======
                //log("brains") ;                                                                //Simply a hack, sorry.
                //Spawn(class'KFMod.BrainSplash',,,boneCoords.Origin,Self.Rotation);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

		if ( !Level.bDropDetail && !bSkeletized )
		{
			AttachEffect( GibGroupClass.static.GetBloodEmitClass(), HitFX[SimHitFxTicker].bone, boneCoords.Origin, HitFX[SimHitFxTicker].rotDir );

<<<<<<< HEAD

=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
			HitFX[SimHitFxTicker].damtype.static.GetHitEffects( HitEffects, Health );

			if( !PhysicsVolume.bWaterVolume ) // don't attach effects under water
			{
				for( i = 0; i < ArrayCount(HitEffects); i++ )
				{
					if( HitEffects[i] == None )
						continue;

<<<<<<< HEAD
					  AttachEffect( HitEffects[i], HitFX[SimHitFxTicker].bone, boneCoords.Origin, HitFX[SimHitFxTicker].rotDir );
				}
			}
		}
		//if ( class'GameInfo'.static.UseLowGore() )
		//	HitFX[SimHitFxTicker].bSever = false;
=======
					AttachEffect( HitEffects[i], HitFX[SimHitFxTicker].bone, boneCoords.Origin, HitFX[SimHitFxTicker].rotDir );
				}
			}
		}
		if ( class'GameInfo'.static.UseLowGore() )
			HitFX[SimHitFxTicker].bSever = false;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

		if( HitFX[SimHitFxTicker].bSever )
		{
			GibPerterbation = HitFX[SimHitFxTicker].damtype.default.GibPerterbation;
<<<<<<< HEAD
			bFlaming = HitFX[SimHitFxTicker].DamType.Default.bFlaming;
=======
			bFlaming = HitFX[SimHitFxTicker].DamType.Default.bFlaming || bBurnApplied;

                        //log("brains") ;
                        //Spawn(class'KFMod.BrainSplash',,,boneCoords.Origin,Self.Rotation);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

			switch( HitFX[SimHitFxTicker].bone )
			{
				case 'Bip01 L Thigh':
<<<<<<< HEAD
				case 'Bip01 R Thigh':
					Spawn(class'KFMod.BrainSplash',,,boneCoords.Origin,Self.Rotation);
					SpawnGiblet( GetGibClass(EGT_Calf), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					SpawnGiblet( GetGibClass(EGT_Calf), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					PlaySound(sound'PlayerSounds.NewGibs.NewGib1', SLOT_Misc,255);
					GibCountCalf -= 2;
					break;
				case 'Bip01 R Forearm':
				case 'Bip01 L Forearm':
					Spawn(class'KFMod.BrainSplash',,,boneCoords.Origin,Self.Rotation);
					SpawnGiblet( GetGibClass(EGT_UpperArm), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					SpawnGiblet( GetGibClass(EGT_Forearm), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					PlaySound(sound'PlayerSounds.NewGibs.NewGib2', SLOT_Misc,255);
					GibCountForearm--;
					GibCountUpperArm--;
					break;
				case 'Bip01 Head':
					Spawn(class'KFMod.BrainSplash',,,boneCoords.Origin,Self.Rotation);
					SpawnGiblet( GetGibClass(EGT_Head), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					PlaySound(sound'PlayerSounds.NewGibs.NewGib2', SLOT_Misc,255);
					GibCountTorso--;
					break;
				case 'Bip01 Spine':
				case 'Bip01 Spine':
					SpawnGiblet( GetGibClass(EGT_Torso), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					PlaySound(sound'PlayerSounds.NewGibs.NewGib3', SLOT_Misc,255);
					GibCountTorso--;
					bGibbed = true;
					while( GibCountHead-- > 0 )
						SpawnGiblet( GetGibClass(EGT_Head), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					while( GibCountForearm-- > 0 )
						SpawnGiblet( GetGibClass(EGT_UpperArm), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					while( GibCountUpperArm-- > 0 )
						SpawnGiblet( GetGibClass(EGT_Forearm), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					if ( !bFlaming && !Level.bDropDetail && (Level.DetailMode != DM_Low) && PlayerCanSeeMe() )
					{
						// extra gibs!!!
						GibPerterbation = FMin(1.0, 1.5 * GibPerterbation);
						PlaySound(sound'PlayerSounds.NewGibs.NewGib4', SLOT_Misc,255);
												SpawnGiblet( GetGibClass(EGT_Calf), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						SpawnGiblet( GetGibClass(EGT_Calf), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						SpawnGiblet( GetGibClass(EGT_UpperArm), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						SpawnGiblet( GetGibClass(EGT_Forearm), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					}
					break;
			}
			if (!bDecapitated)
				HideBone(HitFX[SimHitFxTicker].bone);
=======
					if( !bLeftLegGibbed )
					{
						Spawn(class'KFMod.BrainSplash',,,boneCoords.Origin,Self.Rotation);
						SpawnGiblet(class'KFMod.ClotGibThigh', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						SpawnGiblet(class'KFMod.ClotGibLeg', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						PlaySound(sound'PlayerSounds.NewGibs.NewGib1', SLOT_Misc,255);
						GibCountCalf--;
						bLeftLegGibbed=true;
					}
					break;
				case 'Bip01 R Thigh':
					if( !bRightLegGibbed )
					{
						Spawn(class'KFMod.BrainSplash',,,boneCoords.Origin,Self.Rotation);
						SpawnGiblet(class'KFMod.ClotGibThigh', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						SpawnGiblet(class'KFMod.ClotGibLeg', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						PlaySound(sound'PlayerSounds.NewGibs.NewGib1', SLOT_Misc,255);
						GibCountCalf--;
						bRightLegGibbed=true;
					}
					break;

				case 'Bip01 R Forearm':
					if( !bRightArmGibbed )
					{
						Spawn(class'KFMod.BrainSplash',,,boneCoords.Origin,Self.Rotation);
						SpawnGiblet(class'KFMod.ClotGibArm', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						PlaySound(sound'PlayerSounds.NewGibs.NewGib1', SLOT_Misc,255);
						GibCountUpperArm--;
						bRightArmGibbed=true;
					}
				case 'Bip01 L Forearm':
					if( !bLeftArmGibbed )
					{
						Spawn(class'KFMod.BrainSplash',,,boneCoords.Origin,Self.Rotation);
						SpawnGiblet(class'KFMod.ClotGibArm', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						PlaySound(sound'PlayerSounds.NewGibs.NewGib1', SLOT_Misc,255);
						GibCountUpperArm--;
						bLeftArmGibbed=true;
					}
					break;

				case 'Bip01 Head':
					if( !bHeadGibbed)
					{
						Spawn(class'KFMod.BrainSplash',,,boneCoords.Origin,Self.Rotation);
						SpawnGiblet(class'KFMod.ClotGibHead', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						PlaySound(sound'PlayerSounds.NewGibs.NewGib2', SLOT_Misc,255);
						GibCountHead--;
						bHeadGibbed=true;
					}
					break;
				/* 
				case 'Bip01 Spine':
				case 'Bip01 Spine1':
					if(!bGibbed)
					{
						Level.Game.Broadcast(self, "Torso gib on "$GetHumanReadableName());
						SpawnGiblet(class'KFMod.ClotGibLowerTorso', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						GibCountTorso--;
						PlaySound(sound'PlayerSounds.NewGibs.NewGib3', SLOT_Misc,255);
						bGibbed = true;
						while( GibCountHead-- > 0 )
							SpawnGiblet(class'KFMod.ClotGibHead', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						while( GibCountForearm-- > 0 )
							SpawnGiblet(class'KFMod.ClotGibArm', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						while( GibCountTorso-- > 0 )
							SpawnGiblet(class'KFMod.ClotGibTorso', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						if ( !Level.bDropDetail && (Level.DetailMode != DM_Low) && PlayerCanSeeMe() )
						{
							// extra gibs!!!
							GibPerterbation = FMin(1.0, 1.5 * GibPerterbation);
							PlaySound(sound'PlayerSounds.NewGibs.NewGib4', SLOT_Misc,255);
							SpawnGiblet(class'KFMod.ClotGibLeg', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation);
							SpawnGiblet(class'KFMod.ClotGibLeg', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation);
							SpawnGiblet(class'KFMod.ClotGibArm', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation);
							SpawnGiblet(class'KFMod.ClotGibArm', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						}
					}
					break;*/
			}
			//HideBone(HitFX[SimHitFxTicker].bone);
			if( HitFX[SimHitFXTicker].bone != 'Bip01 Spine' && HitFX[SimHitFXTicker].bone != FireRootBone && HitFX[SimHitFXTicker].bone != 'head' && Health <=0 )
				HideBone(HitFX[SimHitFXTicker].bone);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		}
	}
}

<<<<<<< HEAD
=======
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

	Giblet.SetDrawScale(Giblet.DrawScale * (CollisionRadius*CollisionHeight)/1100); // 1100 = 25 * 44
    GibPerterbation *= 32768.0;
    Rotation.Pitch += ( FRand() * 2.0 * GibPerterbation ) - GibPerterbation;
    Rotation.Yaw += ( FRand() * 2.0 * GibPerterbation ) - GibPerterbation;
    Rotation.Roll += ( FRand() * 2.0 * GibPerterbation ) - GibPerterbation;

    GetAxes( Rotation, Dummy, Dummy, Direction );

    Giblet.Velocity = Velocity + Normal(Direction) * (512.0 + FRand() * 256.0);
}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated function StartDeRes()
{
	if( Level.NetMode == NM_DedicatedServer )
		return;

	AmbientGlow=0;
	MaxLights=5;

	if( Physics == PHYS_KarmaRagdoll )
	{
		// Remove flames
		RemoveFlamingEffects();
		KSetBlockKarma(true);
		// Turn off any overlays
		SetOverlayMaterial(None, 0.0f, true);
		SetCollision(true, true, true);
	}
}

function bool CanAttack(Actor A)
{
	if (A == none)
		return false;
	if(bSTUNNED)
		return false;
	if(KFDoorMover(A)!=none)
		return true;
	else if(KFHumanPawn(A)!=none && KFHumanPawn(A).Health <= 0)
		return ( VSize(A.Location - Location) < MeleeRange + CollisionRadius);
	else return ( VSize(A.Location - Location) < MeleeRange + CollisionRadius + A.CollisionRadius );
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
	if ( bShotAnim || Physics == PHYS_Swimming)
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
	local int meleeAnimIndex;

	if( NewAction=='' )
		Return;
	if(NewAction == 'Claw')
	{
		meleeAnimIndex = Rand(3);
		NewAction = meleeAnims[meleeAnimIndex];
		CurrentDamtype = ZombieDamType[meleeAnimIndex];
	}
	ExpectingChannel = DoAnimAction(NewAction);
	if( ExpectingChannel!=0 )
		bWaitForAnim = true;
	else bPhysicsAnimUpdate = False;
	if( Level.NetMode!=NM_Client )
	{
		AnimAction = NewAction;
		bResetAnimAct = True;
		ResetAnimActTime = Level.TimeSeconds+0.3;
	}
}
simulated function int DoAnimAction( name AnimName )
{
	if( AnimName=='HitF' || AnimName=='HitF2' || AnimName=='HitF3' || AnimName==KFHitFront || AnimName==KFHitBack || AnimName==KFHitRight
	 || AnimName==KFHitLeft )
	{
		AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
		PlayAnim(AnimName,, 0.0, 1);
		Return 1;
	}
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

<<<<<<< HEAD
=======
simulated function HandleBumpGlass()
{
	Acceleration = vect(0,0,0);
	Velocity = vect(0,0,0);

	SetAnimAction(MeleeAnims[0]);
	bShotAnim = true;
	controller.GotoState('WaitForAnim');
}


>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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

<<<<<<< HEAD
	Velocity = vect(0,0,0);
	SetAnimAction('HitF');
	GroundSpeed *= 0.8;
	AirSpeed *= 0.8;
	WaterSpeed *= 0.8;

	// No more raspy breathin'...cuz he has no throat or mouth :S
	AmbientSound = MiscSound;

	//TODO - do we need to inform the controller that we can't move owing to lack of head,
	//	   or is that handled elsewhere
	MonsterController(Controller).Accuracy = -5;  // More chance of missing. (he's headless now, after all) :-D
	
	// Head explodes, causing additional hurty.

	if( KFPawn(LastDamagedBy)!=None )
          TakeDamage( LastDamageAmount + 0.25 * HealthMax , LastDamagedBy, LastHitLocation, LastMomentum, LastDamagedByType);

	//TODO - Find right place for this
	// He's got no head so biting is out.
	if (MeleeAnims[2] == 'Claw3')
		MeleeAnims[2] = 'Claw2';
	if (MeleeAnims[1] == 'Claw3')
		MeleeAnims[1] = 'Claw1';
=======
	if(Health > 0)
	{
		Velocity = vect(0,0,0);
		SetAnimAction('HitF');
		SetGroundSpeed(GroundSpeed *= 0.80);
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
	UpdateSplatterFX(LastDamagedByType);

	PlaySound(DecapSound, SLOT_Misc);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

function BodyPartRemoval(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
<<<<<<< HEAD
    local float Threshold;
=======
    local float Threshold, OverkillFrac;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	// Torso Sever... This is what happens when Overkill occurs.  Nasty.
	if ( Health - Damage < 0)
	{
<<<<<<< HEAD
		if( DamageType.name != 'DamTypeShotgun' &&
                 DamageType.name != 'DamTypeDBShotgun' &&
                DamageType.name != 'DamTypeAxe')
                 Threshold = 0.5;
                else
                 Threshold = 0.25;

                // How Splatty was it?
		if ((Health - Damage) < (0-(Threshold * HealthMax)) &&
                (Health - Damage) > (0-((Threshold * 1.2) * HealthMax)) )
			Gored = rand(4)+1;
                else
                if ((Health - Damage) <= (0-(1.0 * HealthMax))
                && damageType == class 'DamTypeFrag')
			Gored = 5;

               if(Gored > 0)
               {
                // Sorry, not even zombies are getting back up from this.
		//Health = 0;
		if( instigatedBy!=None )
			Died(instigatedBy.Controller,damageType,hitlocation);
		else Died(None,damageType,hitlocation);
               }
               
              // log(Gored);

	}
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
	local bool bIsHeadshot;

	LastDamagedBy = instigatedBy;
	LastDamagedByType = damageType;
	LastDamageAmount = Damage;
=======
		//Level.Game.Broadcast(self, GetHumanReadableName()@" BodyPartRemoval called", 'Say');
		if( DamageType != class'DamTypeShotgun' && DamageType != class'DamTypeDBShotgun' && DamageType != class'DamTypeAxe')
            Threshold = 0.5;
        else
            Threshold = 0.25;
        // How Splatty was it?
		OverkillFrac = float(Damage - Health) / HealthMax;
		// Extreme frag overkill: full-body gib.
		if (DamageType == class'DamTypeFrag' && OverkillFrac >= 1.0)
			Gored = 5;
		// Normal overkill: 1–4, scaled by how excessive it was.
		else if (OverkillFrac >= Threshold)
		{
			if (OverkillFrac >= Threshold * 2.0)
				Gored = Rand(2) + 3;   // 3–4 for very heavy overkill
			else
				Gored = Rand(2) + 1;   // 1–2 for moderate overkill
		}
		if(Gored > 0)
			UpdateSplatterFX(damageType);            
	}
}

simulated function UpdateSplatterFX(class<DamageType> damageType)
{
    local Vector SplatLocation;
    local float GibPerterbation;
    local BrainSplash SplatExplosion;
    //local GibExplosion GibbedExplosion;

    if( bBurnified && !bBurnApplied )
    {
        if ( !bGibbed )
        {
            StartBurnFX();
        }
    }
    else if( !bBurnified && bBurnApplied )
        StopBurnFX();

    if( bAshen && Level.NetMode==NM_Client )
    {
        ZombieCrispUp();
        bAshen = False;
    }

    if(bDecapitated && !bPlayBrainSplash )
    {
        SplatLocation = Location;
        SplatLocation.z += CollisionHeight;
        GibPerterbation = 0.060000; // damageType.default.GibPerterbation;
        HideBone('bip01 head');
        if (HeadStub == none && HeadStubClass != none)
        {
            HeadStub = Spawn(HeadStubClass,Self,'',Location);
            AttachToBone( HeadStub,'Bip01 head');
        }
        if ( EffectIsRelevant(Location,false) )
        {
            SpawnGiblet( class 'KFMod.KFGibBrain',SplatLocation, Rotation, GibPerterbation ) ;
            SpawnGiblet( class 'KFMod.KFGibBrainb',SplatLocation, Rotation, GibPerterbation ) ;
            //SpawnGiblet( class 'KFMod.KFGibBrain',SplatLocation, Rotation, GibPerterbation ) ;
        }
        SplatExplosion = Spawn(class 'BrainSplash',self,, SplatLocation );
        bPlayBrainSplash = true;
    }
    if (Gored>0)
    {
		bFlaming = damageType.Default.bFlaming || bBurnApplied;
        SplatLocation = Location;
        SplatLocation.z += (CollisionHeight - (CollisionHeight * 0.5));
        GibPerterbation = 0.060000; //damageType.default.GibPerterbation;
		if (Gored >= 4)
			HideBone('Bip01 Spine1');
		else if (Gored >= 3)
			HideBone('Bip01 Spine2');
		else if (Gored >= 2)
			HideBone('Bip01 R Clavicle');
		else if (Gored >= 1)
			HideBone('Bip01 L Clavicle');

        if ( EffectIsRelevant(Location,false) && Gored < 5 )
        {
            Spawn(class'KFMod.BrainSplash',,,SplatLocation,Rotation);
            SpawnGiblet( class 'KFMod.KFGibBrain',SplatLocation, Rotation, GibPerterbation ) ;
            SpawnGiblet( class 'KFMod.KFGibBrainb',SplatLocation, Rotation, GibPerterbation ) ;
            SpawnGiblet( class 'KFMod.KFGibBrain',SplatLocation, Rotation, GibPerterbation ) ;
        }
        else if ( EffectIsRelevant(Location,false) && Gored == 5 )
        {
            Spawn(class'KFMod.BodySplash',,,SplatLocation,Rotation);

            if (!bDecapitated)
                SpawnGiblet(MonsterHeadGiblet,SplatLocation, Rotation, GibPerterbation ) ;

            SpawnGiblet(MonsterTorsoGiblet,SplatLocation, Rotation, GibPerterbation ) ;
            SpawnGiblet(MonsterLowerTorsoGiblet,SplatLocation, Rotation, GibPerterbation ) ;

            SpawnGiblet(MonsterArmGiblet,SplatLocation, Rotation, GibPerterbation ) ;
            SpawnGiblet(MonsterArmGiblet,SplatLocation, Rotation, GibPerterbation ) ;

            SpawnGiblet(MonsterThighGiblet,SplatLocation, Rotation, GibPerterbation ) ;
            SpawnGiblet(MonsterThighGiblet,SplatLocation, Rotation, GibPerterbation ) ;

            SpawnGiblet(MonsterLegGiblet,SplatLocation, Rotation, GibPerterbation ) ;
            SpawnGiblet(MonsterLegGiblet,SplatLocation, Rotation, GibPerterbation ) ;
            
        }
        SplatExplosion = Spawn(class 'BrainSplash',self,, SplatLocation );
        //bPlayGoreSplash = true;
    }
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
	local bool bIsHeadshot;
	local float HeadShotCheckScale;
	local KFPlayerReplicationInfo KFPRI;

	LastDamagedBy = instigatedBy;
	LastDamagedByType = damageType;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	HitMomentum = VSize(momentum);
	LastHitLocation = hitlocation;
	LastMomentum = momentum;

	// Zeds and fire dont mix.
	if( class<Burned>(damageType)!=none ||  class<DamTypeFlamethrower>(damageType)!=none)
	{
		LastBurnDamage = Damage;
		Damage *= 1.5;
		if( BurnDown<=0 )
		{
			if( HeatAmount>4 || Damage >= 15 )
			{
				bBurnified = true;
				BurnDown = 10;
				GroundSpeed *= 0.80;
				BurnInstigator = instigatedBy;
				SetTimer(1.0,true);
			}
			else HeatAmount++;
		}
	}

<<<<<<< HEAD
	if ( !bDecapitated )
		bIsHeadShot = IsHeadShot(hitlocation, normal(momentum), 1.0);

	if(bDecapitated || bIsHeadShot )
=======
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	{
		if(class<KFWeaponDamageType>(damageType)!=none)
			Damage = Damage * class<KFWeaponDamageType>(damageType).default.HeadShotDamageMult;
		if( KFPawn(instigatedBy)!=None && class<DamTypeMelee>(damageType)==none )   // Hack for sharpshooter. NO headshot bonuses on melee
			Damage*=KFPawn(instigatedBy).GetVeteran().Static.GetHeadShotDamMulti();
			
		LastDamageAmount = Damage;	

<<<<<<< HEAD
		if (bDurableHead)
		{
			if(bIsHeadShot && Damage > (Health / HealthMax * 100))
				RemoveHead();
		}
		else if(bIsHeadShot && damageType != class 'Burned' && damageType != class 'DamTypeFlamethrower')
			RemoveHead();
	}

	// Client check for Gore FX
	BodyPartRemoval(Damage,instigatedBy,hitlocation,momentum,damageType);
=======
		if( !bDecapitated )
		{
			if( bIsHeadShot )
			{
				PlaySound(sound'PlayerSounds.NewGibs.NewGib1', SLOT_None,255);
				HeadHealth -= LastDamageAmount;
				if( HeadHealth <= 0 || Damage > Health )
				{
				   RemoveHead();
				}
			}
		}
	}

	// Client check for Gore FX
	//BodyPartRemoval(Damage,instigatedBy,hitlocation,momentum,damageType);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	if( Health-Damage > 0 && DamageType!=class'DamTypeFrag' && DamageType!=class'DamTypeShotgun' && DamageType!=class'DamTypeDBShotgun' )
		Momentum = vect(0,0,0);
	if(class<DamTypeVomit>(DamageType)!=none) // Same rules apply to zombies as players.
	{
		BileCount=7;
		BileInstigator = instigatedBy;
		if(NextBileTime< Level.TimeSeconds )
			NextBileTime = Level.TimeSeconds+BileFrequency;
	}
	Super.takeDamage(Damage, instigatedBy, hitLocation, momentum, damageType);
}

<<<<<<< HEAD
=======
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

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
// New Hit FX for Zombies!
function PlayHit(float Damage, Pawn InstigatedBy, vector HitLocation, class<DamageType> damageType, vector Momentum)
{
	local Vector HitNormal;
	local Vector HitRay ;
	local Name HitBone;
	local float HitBoneDist;
	local PlayerController PC;
	local bool bShowEffects, bRecentHit;
	local BloodSpurt BloodHit;

<<<<<<< HEAD
	bRecentHit = Level.TimeSeconds - LastPainTime < 0.45;

	Super.PlayHit(Damage,InstigatedBy,HitLocation,DamageType,Momentum);
=======
	bRecentHit = Level.TimeSeconds - LastPainTime < 0.2;

	LastDamageAmount = Damage;

	OldPlayHit(Damage,InstigatedBy,HitLocation,DamageType,Momentum);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	if ( Damage <= 0 )
		return;

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
<<<<<<< HEAD
		HitBone = 'Bip01 Spine';
=======
		HitBone = FireRootBone;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		HitBoneDist = 0.0f;
	}

	if( DamageType.default.bAlwaysSevers && DamageType.default.bSpecial )
		HitBone = 'head';

	if( InstigatedBy != None )
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
		else BloodHit = BloodSpurt(Spawn(GibGroupClass.default.BloodHitClass,InstigatedBy,, HitLocation, Rotator(HitNormal)));
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

<<<<<<< HEAD
	// hack for Gibbing  :D
	if ( (DamageType.name == 'DamTypeShotgun' || DamageType.name == 'DamTypeDBShotgun' || DamageType.name == 'DamTypeFrag') && (Health < 0) && (InstigatedBy != None) && (VSize(InstigatedBy.Location - Location) < 350) )
		DoDamageFX( HitBone, 800*Damage, DamageType, Rotator(HitNormal) );
	else
		DoDamageFX( HitBone, Damage, DamageType, Rotator(HitNormal) );
=======
	DoDamageFX( HitBone, Damage, DamageType, Rotator(HitNormal) );
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	if (DamageType.default.DamageOverlayMaterial != None && Damage > 0 ) // additional check in case shield absorbed
		SetOverlayMaterial( DamageType.default.DamageOverlayMaterial, DamageType.default.DamageOverlayTime, false );
}
<<<<<<< HEAD
=======

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
function PlayDirectionalHit(Vector HitLoc)
{
	local Vector X,Y,Z, Dir;

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
			if (VSize(LastDamagedBy.Location - Location) <= (MeleeRange * 2) && ClassIsChildOf(LastDamagedbyType,class 'DamTypeMelee')
			 && LastDamageAmount > (0.10* default.Health) || LastDamageAmount >= (0.5 * default.Health) )
			{
				SetAnimAction(HitAnims[Rand(3)]);
				bSTUNNED = true;
				SetTimer(1.0,false);
			}
		else SetAnimAction(KFHitFront);
	}
	else if ( Dir Dot X < -0.7 )
		SetAnimAction(KFHitBack);
	else if ( Dir Dot Y > 0 )
		SetAnimAction(KFHitRight);
	else SetAnimAction(KFHitLeft);
}

<<<<<<< HEAD
=======
simulated function HideBone(name boneName)
{
	local int BoneScaleSlot;
	local bool bValidBoneToHide;

	if( boneName == 'Bip01 L Thigh' )
	{
		boneScaleSlot = 0;
		bValidBoneToHide = true;
	}
	else if ( boneName == 'Bip01 R Thigh' )
	{
		boneScaleSlot = 1;
		bValidBoneToHide = true;
	}
	else if( boneName == 'Bip01 R Forearm' )
	{
		boneScaleSlot = 2;
		bValidBoneToHide = true;
	}
	else if ( boneName == 'Bip01 L Forearm' )
	{
		boneScaleSlot = 3;
		bValidBoneToHide = true;
	}
	else if ( boneName == 'Bip01 Head' )
	{
		boneScaleSlot = 4;
		bValidBoneToHide = true;
	}
	else if ( boneName == 'Bip01 Spine' )
	{
		boneScaleSlot = 5;
		bValidBoneToHide = true;
	}

	// Only hide the bone if it is one of the arms, legs, or head, don't hide other misc bones
	if(bValidBoneToHide)
		SetBoneScale(BoneScaleSlot, 0.0, BoneName);
}


>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
	if ( Controller.Target!=none && Controller.Target.IsA('KFDoorMover'))
	{
		Controller.Target.TakeDamage(hitdamage, self ,HitLocation,pushdir, CurrentDamType);
		Return True;
	}

	// check if still in melee range
	if ( (Controller.target != None) && (bSTUNNED == false) && (DECAP == false) && (VSize(Controller.Target.Location - Location) <= MeleeRange * 1.4 + Controller.Target.CollisionRadius + CollisionRadius)
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
<<<<<<< HEAD
		   TearBone=KFPawn(Controller.Target).GetClosestBone(HitLocation,Velocity,dummy);
		   HideBone(TearBone);
=======
		   TearBone=KFHumanPawn(Controller.Target).GetClosestBone(HitLocation,Velocity,dummy);
		   KFHumanPawn(Controller.Target).HideBone(TearBone);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

		   // Give us some Health back

		   if (Health <= (1.0-FeedThreshold)*HealthMax)
		   {
			 Health += FeedThreshold*HealthMax * Health/HealthMax;
		   }
		  }

	  }
		else if (Controller.target != None)
<<<<<<< HEAD
			Controller.Target.TakeDamage(hitdamage, self ,HitLocation,pushdir, CurrentDamType); //class 'KFmod.ZombieMeleeDamage');
=======
		{
			// Do more damage if you are attacking another zed so that zeds don't just stand there whacking each other forever! - Ramm
            if( KFMonster(Controller.Target) != none )
			{
                hitdamage *= 3;
			}
			Controller.Target.TakeDamage(hitdamage, self ,HitLocation,pushdir, CurrentDamType); //class 'KFmod.ZombieMeleeDamage');
		}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		return true;
	}
	return false;
}

<<<<<<< HEAD
=======
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

			return;
		}
		// jag
	}

}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
	if ( Level.NetMode != NM_DedicatedServer )
	{
		// Is this the local player's ragdoll?
		if(OldController != None)
			pc = PlayerController(OldController);
		if( pc != None && pc.ViewTarget == self )
			PlayersRagdoll = true;

		// In low physics detail, if we were not just controlling this pawn,
		// and it has not been rendered in 3 seconds, just destroy it.
		if( Level.PhysicsDetailLevel!=PDL_High && !PlayersRagdoll && (Level.TimeSeconds-LastRenderTime)>3 )
		{
			Destroy();
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
<<<<<<< HEAD
			Velocity.Z += Base.Velocity.Z;
			Velocity.X += Base.Velocity.X;
=======
			Velocity += Base.Velocity;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		}
		SetPhysics(PHYS_Falling);
		return true;
	}
	return false;
}

simulated function Destroyed()
{
	if( MyExtCollision!=None )
		MyExtCollision.Destroy();
	if( PlayerShadow != None )
		PlayerShadow.Destroy();
	if( FlamingFXs!=None )
<<<<<<< HEAD
		FlamingFXs.Destroy();
=======
	{
		FlamingFXs.Emitters[0].SkeletalMeshActor = none;
		FlamingFXs.Destroy();
	}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	if(RealtimeShadow !=none)
		RealtimeShadow.Destroy();
	  
	// Hack to get rid of our head stump, if the ragdoll dissapears.
	if (HeadStub != none)
		HeadStub.Destroy();
	RemoveFlamingEffects();
	Super.Destroyed();
}

simulated function ZombieCrispUp()
{
	bAshen = true;
	if( Level.NetMode==NM_DedicatedServer )
		Return;
	Skins[0]=Texture 'PatchTex.Common.ZedBurnSkin';
	Skins[1]=Texture 'PatchTex.Common.ZedBurnSkin';
	Skins[2]=Texture 'PatchTex.Common.ZedBurnSkin';
	Skins[3]=Texture 'PatchTex.Common.ZedBurnSkin';
}

function TakeFireDamage(int Damage,pawn Instigator)
{
	local Vector DummyHitLoc,DummyMomentum;

<<<<<<< HEAD
=======
    if (bDeleteMe || Health <= 0 || bPlayedDeath)
        return;

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
		GroundSpeed = default.GroundSpeed;
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
	if ( WallActor != None && Level.TimeSeconds > LastStreakTime + BloodStreakInterval)
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

<<<<<<< HEAD
	if( Level.NetMode == NM_DedicatedServer )
		return;

	for( i=0; i<Attached.length; i++ )
	{
		if( xEmitter(Attached[i])!=None )
			xEmitter(Attached[i]).mRegen = false;
		else if( Emitter(Attached[i])!=None )
			Emitter(Attached[i]).Kill();
		Attached[i].LifeSpan = 2;
=======
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
		else if ( Emitter(Attached[i]) != None && !Attached[i].IsA('DismembermentJet') )
		{
			Emitter(Attached[i]).Kill();
			Attached[i].LifeSpan = 2;
		}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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

defaultproperties
{
<<<<<<< HEAD
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
	MaxSpineVariation=1000
	MaxContortionPercentage=0.250000
	MinTimeBetweenPainAnims=0.500000
	playedHit=True
	FeedThreshold=0.100000
	CorpseLifeSpan=120.000000
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
	ChallengeSound(0)=None
	ChallengeSound(1)=None
	ChallengeSound(2)=None
	ChallengeSound(3)=None
	GruntVolume=50.000000
	FootstepVolume=1.000000
	GibGroupClass=Class'KFMod.KFNoGibGroup'
	SoundGroupClass=Class'KFMod.KFMaleZombieSounds'
	IdleHeavyAnim="Idle_LargeZombie"
	IdleRifleAnim="Idle_LargeZombie"
	FireHeavyRapidAnim="MeleeAttack"
	FireHeavyBurstAnim="MeleeAttack"
	FireRifleRapidAnim="MeleeAttack"
	FireRifleBurstAnim="MeleeAttack"
	DeResTime=0.000000
	DeResMat0=Texture'KFCharacters.KFDeRez'
	DeResMat1=Texture'KFCharacters.KFDeRez'
	DeResLiftVel=(Points=(,(InVal=0.000000,OutVal=0.000000),(InVal=0.000000,OutVal=0.000000)))
	DeResLiftSoftness=(Points=((OutVal=0.000000),(InVal=0.000000,OutVal=0.000000),(InVal=0.000000,OutVal=0.000000)))
	DeResLateralFriction=0.000000
	RagdollLifeSpan=0.000000
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
	bMuffledHearing=False
	bAroundCornerHearing=True
	bCanUse=False
	HearingThreshold=20000.000000
	Alertness=1.000000
	SightRadius=20000.000000
	PeripheralVision=360.000000
	SkillModifier=5.000000
	MeleeRange=50.000000
	JumpZ=250.000000
	WalkingPct=1.000000
	CrouchedPct=1.000000
	MaxFallSpeed=600.000000
	HeadRadius=7.000000
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
	CollisionRadius=26.000000
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
=======
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
     MaxSpineVariation=1000
     MaxContortionPercentage=0.250000
     MinTimeBetweenPainAnims=0.500000
     playedHit=True
     FeedThreshold=0.100000
     CorpseLifeSpan=120.000000
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
     bMuffledHearing=False
     bAroundCornerHearing=True
     bCanUse=False
     HearingThreshold=20000.000000
     Alertness=1.000000
     SightRadius=20000.000000
     PeripheralVision=360.000000
     SkillModifier=5.000000
     MeleeRange=50.000000
     JumpZ=320.000000
     WalkingPct=1.000000
     CrouchedPct=1.000000
	 HiddenGroundSpeed=300.000000
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
     CollisionRadius=26.000000
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

}
