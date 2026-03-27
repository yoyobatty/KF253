// Base Zombie Class.

Class KFMonster extends Skaarj;

#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=KFPlayerSound.uax
#exec OBJ LOAD FILE=PlayerSounds.uax
//#exec OBJ LOAD FILE=22CharTex.utx


var name MeleeAnims[3];
var name HitAnims[3];

var array<sound> MoanVoice;

var name KFHitFront;
var name KFHitBack;
var name KFHitLeft;
var name KFHitRight;

var int LookRotPitch,LookRotYaw;
var Pawn LookTarget;

var int HitMomentum;

var class <KFGib> HeadStubClass;
var KFGib HeadStub;

var Vector LastBloodHitDirection;
var Bool bRanged;

var () bool bStunImmune; // is the zombie immune to stun hit effects?
var bool bSTUNNED;
var bool bDecapitated; // has he lost his noggin'!?
var int  Gored; // Has he lost his whole torso?! if so, how much of it?
var bool DECAP;
var () bool bDurableHead; // if true, the zombie's health comes into play when determining a decap.
var bool bBurnified;
var bool bBurnApplied;
var byte HeatAmount;

var() bool bCannibal;  // If true, this enemy will stop to eat corpses it finds.
var() float FeedThreshold; // default 0.15   This is the percent of health that must be missing before a zombie can feed.

var float StunTime, LastPuntTime, DecapTime;

var Rotator NewTorsoRotation;
//var int MaxTorsoYaw,MaxTorsoPitch,MaxTorsoRoll;  // limits on SetBoneRot for hit reactions.

var () int MaxSpineVariation; // Maximum base amount the bone can bend. Set in defprops.
var () bool bContorts ;  // Does this guy do the LIiiiMBO!!!
var () float MaxContortionPercentage; // def. 0.25

var int damageRand;
var int damageConst;
var int damageForce;
var float LastPainAnim;
var ()  float MinTimeBetweenPainAnims;
var bool playedHit;
var vector KickLocation, ImpactVector;
var actor KickTarget;

var bool bPlayBrainSplash;
var bool bPlayGoreSplash;

var float CorpseStaticTime;   // The level.timeseconds record of when the corpse has stopped moving, and should soon go static.  1 second later, it will.
var bool bCorpsePositionSet;
var () float CorpseLifeSpan;  // The time the zombie corpse will be around for.

var (Sounds) Sound ZJumpSound;

var pawn LastDamagedBy;
var class<damagetype> LastDamagedByType;
var int LastDamageAmount;
var vector LastHitLocation,LastMomentum ;
var float TorsoReturnAlpha;

var bool bFatAss; // HACK for pathfinding

var ()string KFRagdollName;

var class<DamTypeZombieAttack> ZombieDamType[3];
var class<DamTypeZombieAttack> CurrentDamType;

var Sound MiscSound; //

var float SpinDamConst;
var float SpinDamRand;
var () int ScreamDamage;

var () bool bMeleeStunImmune; // if true, this monster cannot be stunned or staggered by melee blows

// Fire Related

var int BurnDown ; // Number of times our zombie must suffer Fire Damage.
var bool bAshen; // is our Zed crispy yet?
var class<Emitter> BurnEffect;  // The appearance of the flames we are attaching to our Zed.
var int LastBurnDamage; // Record the last amount of Fire damage the pawn suffered.


var Effect_ShadowController RealtimeShadow;
var () bool bRealtimeShadows; // Advanced Shadows care of Squirrelzero's code.

var () Name PuntAnim; // The animation to play when a zombie punts a karma object


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

var bool bKnockedDown;

// Better Gore

var () Material GoredMat;  // Swap this in when he's blown in half.

var bool bDiffAdjusted; // has this monster had it's stats adjusted for the server's difficulty? Do once.

var bool bCloaked;
var bool bSpotted; // if true , use the "revealed" shader, instead of the cloak effect
var Emitter FlamingFXs;

var Pawn BurnInstigator;

replication
{
	reliable if(Role == ROLE_Authority)
		bDecapitated,Gored,LookTarget,bBurnified,bAshen,FeedThreshold,bCannibal,bDiffAdjusted,bCloaked;

}


function bool Cloaked()
{ 
  return bCloaked;
}

simulated Function PostNetBeginPlay()
{
	EnableChannelNotify ( 1,1);
	AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
	AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Head');
	super.PostNetBeginPlay();
}

function PlayVictory()
{
	SetPhysics(PHYS_Falling);
	Controller.bPreparingMove = true;
	Acceleration = vect(0,0,0);
	bShotAnim = true;
}

// move karma objects by a kick
// The Kick animation will ONLY be called if the Zombie is On level ground with the KActor,
// and is facing it.
event Bump(actor Other)
{
	local Vector X,Y,Z, Dir;
	GetAxes(Rotation, X,Y,Z);

	super.Bump(Other);
	
	if( Other==none )
		return;
	
	
	// Lots of conditions here!
	//1. Make sure what we've bumped is, in fact a moveable object
	//2. Make sure we're not floating or falling
	//3. Make sure we're not above or below it
	//4. Make sure we're not standing on it
	//5. Make sure our feet are planted on an unmovable object or surface (BSP or SM)
	//6. Make sure we're going slow enough we'd care about what's in our way. 
	//7. Make sure it's actually in front of us.

	if(Other.IsA('NetKActor')
	 && Physics != PHYS_Falling
	 && Location.Z < Other.Location.Z + CollisionHeight
	 && Location.Z > Other.Location.Z - (CollisionHeight * 0.5)
	 && Base!= Other
	 && Base.bStatic
	 && normal(X) dot normal(Other.Location - Location) >= 0.7)
	{
		if(KActor(Other).KGetMass() >= 0.5 && !MonsterController(Controller).CanAttack(Controller.Enemy)
		 && Dir dot X > 0.7 || Dir == vect(0,0,0))
		{
			// Store kick impact data

			ImpactVector = Vector(controller.Rotation)*15000 + (velocity * (Mass / 2) )  ;   // 30
			KickLocation = Other.Location;
			KickTarget = Other;
			KFMonsterController(Controller).KickTarget = KActor(Other);
			SetAnimAction(PuntAnim);
		}
	}
}

// No more File cabinet surfing zombies please..
singular event BaseChange()
{
	Super.BaseChange();
	if ( KActor(Base) != None )
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
	//*** Calling super with new shadow code running == crash  	local KarmaParamsSkel skelParams;
	//Super.PostBeginPlay();
	
	if(ROLE==ROLE_Authority)
	{

          if ( (ControllerClass != None) && (Controller == None) )
			Controller = spawn(ControllerClass);
		
                if ( Controller != None )
			Controller.Possess(self);


		if ( Level.bStartup && !bNoDefaultInventory )
			AddDefaultInventory();

		SplashTime = 0;
		SpawnTime = Level.TimeSeconds;
		EyeHeight = BaseEyeHeight;
		OldRotYaw = Rotation.Yaw;
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

                // Some randomization to their walk speeds.
                GroundSpeed = default.GroundSpeed - (0.5*default.Groundspeed) + (rand(default.groundspeed*0.5) + (0.25 * default.groundspeed));

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
     {
          AdditionalWalkAnims[AdditionalWalkAnims.length] = default.MovementAnims[0];
          MovementAnims[0] = AdditionalWalkAnims[Rand(AdditionalWalkAnims.length)]; 
     }
}

simulated function bool IsMoreThanHalf ( int AngleRot )
{
	if ( AngleRot > 32768 )
		return True;
	else return False;
}

simulated function Tick(float DeltaTime)
{
	local float GibPerterbation;
	local BrainSplash SplatExplosion;
	local GibExplosion GibbedExplosion;
	local Vector SplatLocation;
	local Rotator R;

	if(Controller!=None && Controller.Enemy != none )
		LookTarget = Controller.Enemy;

	if (AnimAction == 'KnockDown')
	{
		Acceleration = vect(0,0,0);
		Velocity = vect(0,0,0);
	}

	//bOrientOnSlope = bKnockedDown;
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
		else if( !bBurnified && bBurnApplied )
			StopBurnFX();

		if( bAshen && Level.NetMode==NM_Client )
		{
			ZombieCrispUp();
			bAshen = False;
		}

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
	if( DECAP )
	{
		if(Level.TimeSeconds>(DecapTime + 2.0) && Controller!=none)
		{
			DECAP = false;
			MonsterController(Controller).ExecuteWhatToDoNext();
		}
	}
	

	if(Health <= 0)
         Disable('Tick');
	
}

simulated function StartBurnFX()
{
	if( FlamingFXs==None )
		FlamingFXs = Spawn(BurnEffect);
	FlamingFXs.SetBase(Self);
	FlamingFXs.Emitters[0].SkeletalMeshActor = self;
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
	bShotAnim = true;
	SetAnimAction('KnockDown');
	Acceleration = vect(0,0,0);
	Controller.GoToState('WaitForAnim');
	KFMonsterController(Controller).bUseFreezeHack = True;
	Return True;
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
	
	  if (DamageType != class 'Burned')
		PlaySound(HitSound[Rand(4)], SLOT_Pain,2*TransientSoundVolume,,400);
}

simulated function DoDerezEffect(); // fuck no!

simulated function DoDamageFX( Name boneName, int Damage, class<DamageType> DamageType, Rotator r )
{
	local float DismemberProbability;
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
				case 'Bip01 L Foot':
					boneName = 'Bip01 L Thigh';
					break;

				case 'Bip01 R Foot':
					boneName = 'Bip01 R Thigh';
					break;

				case 'Bip01 R Hand':
					boneName = 'rfarm';
					break;

				case 'Bip01 L Hand':
					boneName = 'Bip01 L Forearm';
					break;

				case 'Bip01 R Clavicle':
				case 'Bip01 L Clavicle':
					boneName = 'Bip01 Spine';
					break;
			}

			if( DamageType.default.bAlwaysSevers || (Damage == 1000) )
			{
				HitFX[HitFxTicker].bSever = true;
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
				}
			}
		}

		if ( DamageType.default.bNeverSevers || class'GameInfo'.static.UseLowGore()
		 || (Level.Game != None && Level.Game.PreventSever(self, boneName, Damage, DamageType)) )
		{
		HitFX[HitFxTicker].bSever = false;
		bExtraGib = false;
	}

		HitFX[HitFxTicker].bone = boneName;
		HitFX[HitFxTicker].rotDir = r;
		HitFxTicker = HitFxTicker + 1;
		if( HitFxTicker > ArrayCount(HitFX)-1 )
			HitFxTicker = 0;
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
			 
	if (DamageType == class 'Burned')
		ZombieCrispUp();
	ProcessHitFX() ;

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

	
	// Try to adjust around performance
	
	//log(Level.DetailMode);


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

simulated function Timer()
{
	local int RandomNumber;  // Random negative or positive value for our Bone bending;
	local Rotator DefaultTorsoRotation;

	// lets see if this helps the soldier bots pick up on the fact that there's a growling zombie right behind them
	MakeNoise(1.0);

	bSTUNNED = false;



	if (BurnDown > 0)
		TakeFireDamage(LastBurnDamage + rand(2) + 3 , LastDamagedBy);
	else
	{
		RemoveFlamingEffects();
		StopBurnFX();
		SetTimer(0, false);
	}
	if (bContorts)
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
	}
	

}

simulated function ProcessHitFX()
{
	local Coords boneCoords;
	local class<xEmitter> HitEffects[4];
	local int i,j;
	local float GibPerterbation;

	j = 0 ;
	i = 0 ;

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

				//log("brains") ;																//Simply a hack, sorry.
				//Spawn(class'KFMod.BrainSplash',,,boneCoords.Origin,Self.Rotation);

		if ( !Level.bDropDetail && !bSkeletized )
		{
			AttachEffect( GibGroupClass.static.GetBloodEmitClass(), HitFX[SimHitFxTicker].bone, boneCoords.Origin, HitFX[SimHitFxTicker].rotDir );


			HitFX[SimHitFxTicker].damtype.static.GetHitEffects( HitEffects, Health );

			if( !PhysicsVolume.bWaterVolume ) // don't attach effects under water
			{
				for( i = 0; i < ArrayCount(HitEffects); i++ )
				{
					if( HitEffects[i] == None )
						continue;

					  AttachEffect( HitEffects[i], HitFX[SimHitFxTicker].bone, boneCoords.Origin, HitFX[SimHitFxTicker].rotDir );
				}
			}
		}
		//if ( class'GameInfo'.static.UseLowGore() )
		//	HitFX[SimHitFxTicker].bSever = false;

		if( HitFX[SimHitFxTicker].bSever )
		{
			GibPerterbation = HitFX[SimHitFxTicker].damtype.default.GibPerterbation;
			bFlaming = HitFX[SimHitFxTicker].DamType.Default.bFlaming;

			switch( HitFX[SimHitFxTicker].bone )
			{
				case 'Bip01 L Thigh':
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
		}
	}
}

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
	else if ( CanAttack(A) )
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
	else if ( CanAttack(A) )
	{
		bShotAnim = true;
		SetAnimAction('ZombieFeed');
	}
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

	if (bWaitForAnim)
	{
		AnimAction = NewAction;
		if ( AnimAction == 'HitF' )
		{
			AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'HitF2' )
		{
			AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'HitF3' )
		{
			AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
		}
	}
	if (!bWaitForAnim)
	{
		AnimAction = NewAction;
		if ( AnimAction == 'HitF' )
		{
			AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'HitF2' )
		{
			AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'HitF3' )
		{
			AnimBlendParams(1, 1.0, 0.0,, 'Bip01 Spine1');
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == KFHitFront )
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
		else if(AnimAction == 'Claw')
		{
			if( Controller != none &&  Controller.Enemy != none && Controller.Enemy.Health<=0 )
				AnimAction = 'ZombieFeed';
			else
			{
				meleeAnimIndex = Rand(3);
				AnimAction = meleeAnims[meleeAnimIndex];
			}
			CurrentDamtype = ZombieDamType[meleeAnimIndex];
		}
		else if(NewAction == 'ZombieFeed')
		{
			AnimAction = NewAction;
			LoopAnim(AnimAction,,0.1);
		}
		else AnimAction = NewAction;

		if ( PlayAnim(AnimAction,,0.1) && AnimAction != KFHitFront && AnimAction != KFHitBack && AnimAction != KFHitLeft && AnimAction != KFHitRight )
		{
			if ( Physics != PHYS_None )
				bWaitForAnim = true;
		}
	}
}
simulated function StoodUp()
{
	bKnockedDown = false;
	SetPhysics(PHYS_Walking);
}
simulated function FellDown()
{
	SetPhysics(PHYS_Falling);
	bKnockedDown = true;
}
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
	bDecapitated  = true;
	DECAP = true;
	DecapTime = Level.TimeSeconds;

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
}

function BodyPartRemoval(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
    local float Threshold;

	// Torso Sever... This is what happens when Overkill occurs.  Nasty.
	if ( Health - Damage < 0)
	{
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
	HitMomentum = VSize(momentum);
	LastHitLocation = hitlocation;
	LastMomentum = momentum;

	// Zeds and fire dont mix.
	if( class<Burned>(damageType)!=none )
	{
		LastBurnDamage = Damage;
		Damage *= 1.5;
		if( BurnDown<=0 )
		{
			if( HeatAmount>5 )
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

	bIsHeadShot = IsHeadShot(hitlocation, normal(momentum), 1.0);
	
	if (bDecapitated)
	 bIsHeadShot = false;


	if(bDecapitated || bIsHeadShot )
	{
		if(class<KFWeaponDamageType>(damageType)!=none)
			Damage = Damage * class<KFWeaponDamageType>(damageType).default.HeadShotDamageMult;
		if( KFPawn(instigatedBy)!=None && class<DamTypeMelee>(damageType)== none)   // Hack for sharpshooter. NO headshot bonuses on melee
			Damage*=KFPawn(instigatedBy).GetVeteran().Static.GetHeadShotDamMulti();
			
		LastDamageAmount = Damage;	

		if (bDurableHead)
		{
			if(bIsHeadShot && Damage > (Health / HealthMax * 100))
				RemoveHead();
		}
		else if(bIsHeadShot && damageType != class 'Burned')
			RemoveHead();
	}
	if (damageType == class 'DamTypeVomit')
		Damage = 0; // nulled

	// Client check for Gore FX
	BodyPartRemoval(Damage,instigatedBy,hitlocation,momentum,damageType);

	/*
        // Flying ragdolls
	if(Health - Damage <= 0 && DamageType == class 'DamTypeFrag')
	{
		RagDeathVel *= 5;
		RagDeathUpKick *= 1.5;
	}
	*/
	
	    if (Health - Damage > 0 &&
         DamageType != class 'DamTypeFrag' &&
          DamageType != class 'DamTypeShotgun' &&
           DamageType != class 'DamTypeDBShotgun' )
         Momentum = vect(0,0,0) ;


	Super.takeDamage(Damage, instigatedBy, hitLocation, momentum, damageType);
}

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

	bRecentHit = Level.TimeSeconds - LastPainTime < 0.45;

	Super.PlayHit(Damage,InstigatedBy,HitLocation,DamageType,Momentum);

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
		HitBone = 'Bip01 Spine';
		HitBoneDist = 0.0f;
	}

	if( DamageType.default.bAlwaysSevers && DamageType.default.bSpecial )
		HitBone = 'head';

	if( InstigatedBy != None )
		HitNormal = Normal( Normal(InstigatedBy.Location-HitLocation) + VRand() * 0.2 + vect(0,0,2.8) );
	else
		HitNormal = Normal( Vect(0,0,1) + VRand() * 0.2 + vect(0,0,2.8) );

	//log("HitLocation "$Hitlocation) ;

	if ( DamageType.Default.bCausesBlood && DamageType != class 'Burned' )
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

	// hack for Gibbing  :D
	if ( (DamageType.name == 'DamTypeShotgun' || DamageType.name == 'DamTypeDBShotgun' || DamageType.name == 'DamTypeFrag') && (Health < 0) && (InstigatedBy != None) && (VSize(InstigatedBy.Location - Location) < 350) )
		DoDamageFX( HitBone, 800*Damage, DamageType, Rotator(HitNormal) );
	else
		DoDamageFX( HitBone, Damage, DamageType, Rotator(HitNormal) );

	if (DamageType.default.DamageOverlayMaterial != None && Damage > 0 ) // additional check in case shield absorbed
		SetOverlayMaterial( DamageType.default.DamageOverlayMaterial, DamageType.default.DamageOverlayTime, false );
}
simulated function PlayDirectionalHit(Vector HitLoc)
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
		   TearBone=KFPawn(Controller.Target).GetClosestBone(HitLocation,Velocity,dummy);
		   HideBone(TearBone);

		   // Give us some Health back

		   if (Health <= (1.0-FeedThreshold)*HealthMax)
		   {
			 Health += FeedThreshold*HealthMax * Health/HealthMax;
		   }
		  }

	  }
		else if (Controller.target != None)
			Controller.Target.TakeDamage(hitdamage, self ,HitLocation,pushdir, CurrentDamType); //class 'KFmod.ZombieMeleeDamage');
		return true;
	}
	return false;
}

function PlayDyingAnimation(class<DamageType> DamageType, vector HitLoc)
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
			Velocity.Z += Base.Velocity.Z;
			Velocity.X += Base.Velocity.X;
		}
		SetPhysics(PHYS_Falling);
		return true;
	}
	return false;
}

simulated function Destroyed()
{
	if( PlayerShadow != None )
		PlayerShadow.Destroy();
	if( FlamingFXs!=None )
		FlamingFXs.Destroy();

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

	//Log("Burned");
	TakeDamage(Damage,BurnInstigator,DummyHitLoc,DummyMomentum,class 'Burned');
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

	if( Level.NetMode == NM_DedicatedServer )
		return;

	for( i=0; i<Attached.length; i++ )
	{
		if( xEmitter(Attached[i])!=None )
			xEmitter(Attached[i]).mRegen = false;
		else if( Emitter(Attached[i])!=None )
			Emitter(Attached[i]).Kill();
		Attached[i].LifeSpan = 2;
	}
}

// this could have been responsible for making the zombies "lethargic" in wander state.
// they should retain the same walk speed at all times.
event SetWalking(bool bNewIsWalking);

defaultproperties
{
     MeleeAnims(0)="Claw"
     MeleeAnims(1)="Claw2"
     MeleeAnims(2)="Claw3"
     HitAnims(0)="HitF"
     HitAnims(1)="HitF2"
     HitAnims(2)="HitF3"
     KFHitFront="HitReactionF"
     KFHitBack="HitReactionB"
     KFHitLeft="HitReactionL"
     KFHitRight="HitReactionR"
     HeadStubClass=Class'KFMod.GibHeadStump'
     FeedThreshold=0.100000
     MaxSpineVariation=1000
     MaxContortionPercentage=0.250000
     MinTimeBetweenPainAnims=0.500000
     playedHit=True
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

}
