//=============================================================================
// KFPawn
//=============================================================================
class KFPawn extends xPawn;

var string KFBSkin;
var string KFFSkin;
var mesh  KFSMesh;

var float healthToGive, lastHealTime;

var bool bResetingAnimAct;
var float NextBileTime, BileFrequency, AnimActResetTime;
var int BileCount;
var Pawn BileInstigator;

var name ClientIdleWeaponAnim;

var bool bThrowingNade; // ARE WE ALREADY THROWING ONE?

var Inventory SecondaryItem;

// Player Health Bar textures
var Texture TeamBeaconTexture, NoEntryTexture;
var Material TeamBeaconBorderMaterial;

var class<DamageType> LastHitDamType; // records the last kind of damge you took (for siren hack)

var (Global) Mesh SafeMesh;

// Fire Related

var int BurnDown ; // Number of times our zombie must suffer Fire Damage.
var bool bAshen; // is our Zed crispy yet?
var class<Emitter> BurnEffect;  // The appearance of the flames we are attaching to our Zed.
var int LastBurnDamage; // Record the last amount of Fire damage the pawn suffered.
var Emitter ItBUURRNNNS;

var bool bBurnified;
var bool bBurnApplied;

var pawn LastDamagedBy,BurnInstigator;

var() globalconfig bool bRealtimeShadows,bRealDeathType; // Advanced Shadows care of Squirrelzero's code. (This is only place to rate this!)

var KFLevelRules LevRls;
var PlayerReplicationInfo OwnerPRI;

replication
{
	reliable if(Role == ROLE_Authority)
		bBurnified;

	reliable if(Role < ROLE_Authority)
		ServerBuyWeapon,ServerSellWeapon,ServerBuyKevlar,ServerBuyFirstAid,ServerBuyAmmo,ServerSellAmmo;

	reliable if(Role < ROLE_Authority)
		SecondaryItem,TossCash;
}

function PossessedBy(Controller C)
{
	Super.PossessedBy(C);
	if ( C.PlayerReplicationInfo != None )
		OwnerPRI = C.PlayerReplicationInfo;
}

simulated Function PostNetBeginPlay()
{
	EnableChannelNotify(1,1);
	EnableChannelNotify(2,1);
	super.PostNetBeginPlay();
}

simulated function string GetDefaultCharacter()
{
	Return "Jacob";
}

simulated function Setup(xUtil.PlayerRecord rec, optional bool bLoadNow)
{
	Species = rec.Species;
	RagdollOverride = rec.Ragdoll;
	if ( Species!=None && !Species.static.Setup(self,rec) )
	{
		if ( !Species.static.Setup(self,rec) )
			return;
	}
	ResetPhysicsBasedAnim();
}

simulated function DoDerezEffect();

simulated event PostNetReceive()
{
    if ( PlayerReplicationInfo != None )
    {
        Setup(class'xUtil'.static.FindPlayerRecord(PlayerReplicationInfo.CharacterName));
        bNetNotify = false;
    }
    else if ( (DrivenVehicle != None) && (DrivenVehicle.PlayerReplicationInfo != None) )
    {
        Setup(class'xUtil'.static.FindPlayerRecord(DrivenVehicle.PlayerReplicationInfo.CharacterName));
        bNetNotify = false;
    }
}
function DoDamageFX( Name boneName, int Damage, class<DamageType> DamageType, Rotator r )
{
	local float DismemberProbability;
	local bool bExtraGib;

	if ( FRand() > 0.3f || Damage > 30 || Health <= 0 )
	{
		HitFX[HitFxTicker].damtype = DamageType;

		if( Health <= 0 )
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
				DismemberProbability = Abs( (Health - Damage*DamageType.Default.GibModifier) / 130.0f );
				switch( boneName )
				{
					case 'Bip01 L Thigh':
					case 'Bip01 R Thigh':
					case 'Bip01 R Forearm':
					case 'Bip01 L Forearm':
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
	//bFrozenBody = true;
	
	SafeMesh = Mesh;

	if (CurrentCombo != None)
		CurrentCombo.Destroy();

	HitDamageType = DamageType; // these are replicated to other clients
	TakeHitLocation = HitLoc;

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
	//LifeSpan = RagdollLifeSpan;

	GotoState('Dying');
	if ( BE != None )
		return;

	PlayDyingAnimation(DamageType, HitLoc);
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
			GoTo'NonRagdoll';
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

NonRagdoll:
	// non-ragdoll death fallback
	Velocity += TearOffMomentum;
	BaseEyeHeight = Default.BaseEyeHeight;
	SetTwistLook(0, 0);
	SetInvisibility(0.0);
	PlayDirectionalDeath(HitLoc);
	SetPhysics(PHYS_Falling);
}

simulated function bool ForceDefaultCharacter()
{
	return false;
}

simulated function ProcessHitFX()
{
	local Coords boneCoords;
	local class<xEmitter> HitEffects[4];
	local int i,j;
	local float GibPerterbation;

	if( (Level.NetMode == NM_DedicatedServer) || bSkeletized || (Mesh == SkeletonMesh) )
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

		boneCoords = GetBoneCoords( HitFX[SimHitFxTicker].bone );

		if ( !Level.bDropDetail && !bSkeletized )
		{
			
                        if (BurnDown > 0)
                        {
	                 AttachEmitterEffect( BurnEffect, 'Bip01', boneCoords.Origin, HitFX[SimHitFxTicker].rotDir );
                        }


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
		if ( class'GameInfo'.static.UseLowGore() )
			HitFX[SimHitFxTicker].bSever = false;

		if( HitFX[SimHitFxTicker].bSever )
		{
			GibPerterbation = HitFX[SimHitFxTicker].damtype.default.GibPerterbation;
			bFlaming = HitFX[SimHitFxTicker].DamType.Default.bFlaming;

			switch( HitFX[SimHitFxTicker].bone )
			{
				case 'Bip01 L Thigh':
				case 'Bip01 R Thigh':
					SpawnGiblet( GetGibClass(EGT_Calf), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					SpawnGiblet( GetGibClass(EGT_Calf), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					GibCountCalf -= 2;
					break;

				case 'Bip01 R Forearm':
				case 'Bip01 L Forearm':
					SpawnGiblet( GetGibClass(EGT_UpperArm), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					SpawnGiblet( GetGibClass(EGT_Forearm), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					GibCountForearm--;
					GibCountUpperArm--;
					break;

				case 'Bip01 Head':
					SpawnGiblet( GetGibClass(EGT_Head), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					GibCountTorso--;
					break;

				case 'Bip01 Spine':
				case 'Bip01 Spine':
					SpawnGiblet( GetGibClass(EGT_Torso), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					GibCountTorso--;
					bGibbed = true;
					while( GibCountHead-- > 0 )
						SpawnGiblet( GetGibClass(EGT_Head), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					while( GibCountForearm-- > 0 )
						SpawnGiblet( GetGibClass(EGT_UpperArm), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					while( GibCountUpperArm-- > 0 )
						SpawnGiblet( GetGibClass(EGT_Forearm), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
					if ( !bFlaming && !Level.bDropDetail && (Level.DetailMode != DM_Low) && (Level.TimeSeconds-LastRenderTime)<5 )
					{
						// extra gibs!!!
						GibPerterbation = FMin(1.0, 1.5 * GibPerterbation);
						SpawnGiblet( GetGibClass(EGT_Calf), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						SpawnGiblet( GetGibClass(EGT_Calf), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						SpawnGiblet( GetGibClass(EGT_UpperArm), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						SpawnGiblet( GetGibClass(EGT_Forearm), boneCoords.Origin, HitFX[SimHitFxTicker].rotDir, GibPerterbation );
						Spawn(Class'BodySplashFX');
					}
					break;
			}

                      // Haxxors!

		      if (LastHitDamType == class 'SirenScreamDamage')
		       HideBone(HeadBone);
		      else
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

	// DeResFX = Spawn(class'DeResPart', self, , Location);
	//Skins[0] = DeResMat0;
	//Skins[1] = DeResMat1;

	if( Physics == PHYS_KarmaRagdoll )
	{
		// Remove flames
		RemoveFlamingEffects();
		// Turn off any overlays
		SetOverlayMaterial(None, 0.0f, true);
	}
}

// Remove Shield Sounds , Randomize for Human Pain sound.

function int ShieldAbsorb( int dam )
{
	local float Interval, damage, Remaining;
	local int PainSound;

	damage = dam;

	if ( ShieldStrength == 0 )
		return damage;

      // Super.ShieldAbsorb(dam);
	//SetOverlayMaterial( ShieldHitMat, ShieldHitMatTime, false );

	// Randomize Painsounds on Armor hit
	PainSound = rand(6);
	if (PainSound == 0)
		PlaySound(sound'KFPlayerSound.hpain3', SLOT_Pain,2*TransientSoundVolume,,400);
	else if (PainSound == 1)
		PlaySound(sound'KFPlayerSound.hpain2', SLOT_Pain,2*TransientSoundVolume,,400);
	else if (PainSound == 2)
		PlaySound(sound'KFPlayerSound.hpain1', SLOT_Pain,2*TransientSoundVolume,,400);
	else if (PainSound == 3)
		PlaySound(sound'KFPlayerSound.hpain3', SLOT_Pain,2*TransientSoundVolume,,400);
	else if (PainSound == 4)
		PlaySound(sound'KFPlayerSound.hpain2', SLOT_Pain,2*TransientSoundVolume,,400);
	else if (PainSound == 5)
		PlaySound(sound'KFPlayerSound.hpain1', SLOT_Pain,2*TransientSoundVolume,,400);

	if ( ShieldStrength == 100 )
	{
		Interval = ShieldStrength - 100;
		if ( Interval >= damage )
		{
			ShieldStrength -= damage;
			return 0;
		}
		else
		{
			ShieldStrength = 100;
			damage -= Interval;
		}
	}  
	if ( ShieldStrength > SmallShieldStrength )
	{
		Interval = ShieldStrength - SmallShieldStrength;
		if ( Interval >= 0.75 * damage )
		{
			ShieldStrength -= 0.75 * damage;
			if ( ShieldStrength < SmallShieldStrength )
				SmallShieldStrength = ShieldStrength;
			return (0.25 * Damage);
		}
		else
		{
			ShieldStrength = SmallShieldStrength;
			damage -= Interval;
			Remaining = 0.33 * Interval;
			if ( Remaining <= damage )
				return damage;
			damage -= Remaining;
		}
	}
	if ( ShieldStrength >= 0.5 * damage )
	{
		ShieldStrength -= damage ;
		SmallShieldStrength = ShieldStrength;
		return Remaining + (0.25 * damage);   // 0.5
	}
	else
	{
		damage -= ShieldStrength;
		ShieldStrength = 0;
		SmallShieldStrength = 0;
	}
	return damage + Remaining;
}

// Fixed to make it online compatible.
simulated function StartFiringX(bool bHeavy, bool bRapid, optional name TPAnim )
{
	local name FireAnim;

	AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);

	if ( HasUDamage() && (Level.TimeSeconds - LastUDamageSoundTime > 0.25) )
	{
		LastUDamageSoundTime = Level.TimeSeconds;
		PlaySound(UDamageSound, SLOT_None, 1.5*TransientSoundVolume,,700);
	}
	//if (Physics == PHYS_Swimming)
	//	return;

	if( TPAnim!='' && HasAnim(TPAnim) )
		FireAnim = TPAnim;
	else if( bRapid )
	{
		if( bHeavy )
			FireAnim = FireHeavyRapidAnim;
		else FireAnim = FireRifleRapidAnim;
	}
	else if( bHeavy )
		FireAnim = FireHeavyBurstAnim;
	else FireAnim = FireRifleBurstAnim;

	PlayAnim(FireAnim,, 0.0, 1);
	FireState = FS_PlayOnce;

	IdleTime = Level.TimeSeconds;
}

simulated function StopFiring()
{
    if (FireState == FS_Looping)
        FireState = FS_PlayOnce;
    IdleTime = Level.TimeSeconds;
}


function RemoveInventorySP( class<inventory> ItemClass )
{
    // If this item is in our inventory chain, unlink it.
    local actor Link;
    local int Count;
    local inventory Item ;

    Item = spawn(ItemClass) ;

    if ( ItemClass == Weapon.class )
        Weapon = None;
    if ( ItemClass == SelectedItem.class )
        SelectedItem = None;
    for( Link = Self; Link!=None; Link=Link.Inventory )
    {
        if( Link.Inventory.class == ItemClass )
        {
            Link.Inventory = Item.Inventory;
            Item.Inventory = None;
            Link.NetUpdateTime = Level.TimeSeconds - 1;
            Item.NetUpdateTime = Level.TimeSeconds - 1;
            break;
        }
        if ( Level.NetMode == NM_Client )
        {
        Count++;
        if ( Count > 1000 )
            break;
    }
    }
    Item.SetOwner(None);
}

// another one cut-n-pasted to remove must-have-ammo fetish
exec function SwitchToLastWeapon()
{
	if ( (Weapon != None) && (Weapon.OldWeapon != None) ) // && Weapon.OldWeapon.HasAmmo() )
	{
		PendingWeapon = Weapon.OldWeapon;
		Weapon.PutDown();
	}
}

// TODO: GetWeapon

simulated function AddHealth()
{
    local int tempHeal ;
    if((level.TimeSeconds - lastHealTime) >= 0.1)
    {
        if(Health < HealthMax)
        {
            tempHeal = int(10 * (level.TimeSeconds - lastHealTime)) ;
            if(tempHeal>0)
              lastHealTime = level.TimeSeconds ;

            Health = Min(Health+tempHeal, HealthMax);
            HealthToGive -= tempHeal ;
        }
        else
        {
            lastHealTime = level.timeSeconds ;
            // if we are all healed, there's gonna be no more healing
            HealthToGive = 0 ;
        }
    }
}

function bool GiveHealth(int HealAmount, int HealMax)
{
	if(healAmount >= 50)
		healAmount = 50;
	if( Health<HealMax )
	{
		HealthToGive+=HealAmount;
		lastHealTime = level.timeSeconds;
		return true;
	}
	Return False;
}

function ThrowGrenade()
{
  local inventory inv;
  local Frag aFrag;


  for(inv=inventory; inv!=none; inv=inv.Inventory)
  {

    aFrag=Frag(inv);

    if(aFrag!=none && aFrag.HasAmmo() && !bThrowingNade )
    {
     if(Weapon != none && Weapon.GetFireMode(0).NextFireTime - Level.TimeSeconds > 0.1 ||
     KFWeapon(Weapon).bIsReloading)
      return;
      
      //TODO: cache this without setting SecItem yet
      //SecondaryItem = aFrag;
      Weapon.PutDown();
      //aFrag.StartThrow();
    }
  }
}

function WeaponDown()
{
	local inventory inv;
	local Frag aFrag;

  for(inv=inventory; inv!=none; inv=inv.Inventory)
  {

    aFrag=Frag(inv);

    if(aFrag!=none && aFrag.HasAmmo() )
    {
      SecondaryItem = aFrag;
      aFrag.StartThrow();
      SetAnimAction('NadeToss');
    }
  }
}

simulated function ThrowGrenadeFinished()
{
  SecondaryItem = none;
  Weapon.BringUp();
  bThrowingNade = false;

}


//Player Jumped
function bool DoJump( bool bUpdating )
{
	if ( Super.DoJump(bUpdating) )
	{
           // If non berserk class, jumps slow us down.
           if (GetVeteran().default.VeterancyName != "Berserker")
           {
            Velocity.X*=0.5;
	    Velocity.Y*=0.5;
           }

            Return True;
        }
	Return False;
}

simulated function Tick(float DeltaTime)
{
	// IN other words - we're moving, we've got a piece, but we're not firing or reloading, or jumping / falling Faust:Perhaps we need that later: VSize(Acceleration) != 0 &&
	if (level.NetMode != NM_DEDICATEDSERVER)
	{
		if(bBurnified && !bBurnApplied)
			StartBurnFX();
		else if(!bBurnified && bBurnApplied)
			StopBurnFX();
	}

       // CheckFlashLightAnims();

	if( bResetingAnimAct && (AnimActResetTime<Level.TimeSeconds) ) // Reset replication.
	{
		bResetingAnimAct = False;
		AnimAction = '';
	}
	if(healthToGive > 0 && health > 0)  //
		AddHealth() ;
	else if(healthToGive < 0)
		healthToGive = 0 ;

	if(BileCount>0 && NextBileTime<level.TimeSeconds)
	{
		--BileCount;
		NextBileTime+=BileFrequency;
		TakeBileDamage();
	}
	Super.Tick(deltaTime);
}

simulated event SetAnimAction(name NewAction)
{
	if( NewAction=='' )
		Return;
	if (!bWaitForAnim)
	{
		AnimAction = NewAction;

		if ( AnimAction == 'Weapon_Switch' )
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'Reload' )
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'AxeAttack' )
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'ChainSawAttack' )
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'DeagleHold' )
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			LoopAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'DualiesAttackLeft' )
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'DualiesAttackRight' )
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'DualiesHold' )
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			LoopAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'NadeToss' )
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			PlayAnim(NewAction,, 0.0, 1);
			bThrowingNade = true;
		}
		else if ( AnimAction == 'ShotgunFire' )
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			PlayAnim(NewAction,, 0.0, 1);
		}
		else if ( AnimAction == 'DeagleBlast' )
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			PlayAnim(NewAction,, 0.0, 1);
		} // Reloads
		else if ( AnimAction == 'Reload1' )
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			PlayAnim(NewAction,, 0.0, 1);
			FireState = FS_Ready;
		}
		else if ( AnimAction == 'ReloadBullpup' )
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			PlayAnim(NewAction,, 0.0, 1);
			FireState = FS_Ready;
		}
		else if ( AnimAction == 'ReloadPistol' )
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			PlayAnim(NewAction,, 0.0, 1);
			FireState = FS_Ready;
		}
		else if ( ((Physics == PHYS_None)|| ((Level.Game != None) && Level.Game.IsInState('MatchOver'))) && (DrivenVehicle == None) )
		{
			PlayAnim(AnimAction,,0.1);
			AnimBlendToAlpha(1,0.0,0.05);
		}
		else if ( (DrivenVehicle != None) || (Physics == PHYS_Falling) || ((Physics == PHYS_Walking) && (Velocity.Z != 0)) )
		{
			if ( CheckTauntValid(AnimAction) )
			{
				if (FireState == FS_None || FireState == FS_Ready)
				{
					AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
					PlayAnim(NewAction,, 0.1, 1);
					FireState = FS_Ready;
				}
			}
			else if ( HasAnim(AnimAction) && PlayAnim(AnimAction) )
			{
				if ( Physics != PHYS_None )
					bWaitForAnim = true;
			}
			else AnimAction = NewAction;
		}
		else if (bIsIdle && !bIsCrouched && (Bot(Controller) == None) ) // standing taunt
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			PlayAnim(AnimAction,,0.1,1);
		}
		else if (FireState == FS_None || FireState == FS_Ready)
		{
			AnimBlendParams(1, 1.0, 0.0, 0.2, FireRootBone);
			PlayAnim(NewAction,, 0.1, 1);
			FireState = FS_Ready;
		}
	}
	if( Level.NetMode!=NM_Client )
	{
		// Reset to fix replication.
		bResetingAnimAct = True;
		AnimActResetTime = Level.TimeSeconds+0.45;
	}
}
simulated function AnimEnd(int Channel)
{
	local name TempName;
	local float Dummy;

	if( Level.NetMode!=NM_DedicatedServer && ClientIdleWeaponAnim!='' )
	{
		if( Channel!=1 && IsAnimating(1) )
			Return;
		GetAnimParams(1,TempName,Dummy,Dummy);
		if( TempName==ClientIdleWeaponAnim )
			Return;
		AnimBlendParams(1, 1.0,,, FireRootBone);
		LoopAnim(ClientIdleWeaponAnim,0.8,0.3,1);
	}
}
simulated function UpdateClientAnim( name NewCAnim )
{
	if( !HasAnim(NewCAnim) )
		Return;
	ClientIdleWeaponAnim = NewCAnim;
	AnimBlendParams(1, 1.0,,, FireRootBone);
	LoopAnim(NewCAnim,0.8,0.3,1);
}

simulated function StartBurnFX()
{
	if( ItBUURRNNNS==None )
	{
		ItBUURRNNNS = Spawn(BurnEffect);
		ItBUURRNNNS.SetBase(Self);
		ItBUURRNNNS.Emitters[0].SkeletalMeshActor = self;
	}
	bBurnApplied = True;
}

simulated function StopBurnFX()
{
	RemoveFlamingEffects();
	if( ItBUURRNNNS!=None )
		ItBUURRNNNS.Kill();
	bBurnApplied = False;
}


function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
	LastHitDamType = damageType;
	LastDamagedBy = instigatedBy;

	super.TakeDamage(Damage, instigatedBy, hitLocation, momentum, damageType);

	healthtoGive-=5;

	if (class<Burned>(damageType)!=none || class<DamTypeFlamethrower>(damageType)!=none)
	{
		if( TeamGame(Level.Game)!=None && TeamGame(Level.Game).FriendlyFireScale==0 && instigatedBy!=None && instigatedBy!=Self
		 && instigatedBy.GetTeamNum()==GetTeamNum()  )
			Return;
		LastBurnDamage = Damage;
		
                

                if (BurnDown <= 0 )
		{
			bBurnified = true;
			BurnDown = 5;
			BurnInstigator = instigatedBy;
			SetTimer(1.5,true);
		}
	}


	if(class<DamTypeVomit>(DamageType)!=none)
	{
		BileCount=7;
		BileInstigator = instigatedBy;
		if(NextBileTime< Level.TimeSeconds )
			NextBileTime = Level.TimeSeconds+BileFrequency;
	}
}

function TakeBileDamage()
{
	Super.TakeDamage(2+Rand(3), BileInstigator, Location, vect(0,0,0), class'DamTypeVomit');
	healthtoGive-=5;
}

function bool AddShieldStrength(int ShieldAmount)
{
	if(ShieldStrength >= 100)
		return false;

	ShieldStrength+=ShieldAmount;
	if(ShieldStrength > 100)
		ShieldStrength = 100;
	return true ;
}

function TakeFireDamage(int Damage,pawn BInstigator)
{
         if(!GetVeteran().Static.FlamingNades())
          TakeDamage(Damage,BInstigator,Location,vect(0,0,0),class 'Burned');


        if (BurnDown > 0)
		BurnDown --; // Decrement the number of FireDamage calls left before our Zombie is extinguished :)

	if(BurnDown==0)
		bBurnified = false;
}


// This may help show the hit effects when zombies hit players

function PlayHit(float Damage, Pawn InstigatedBy, vector HitLocation, class<DamageType> damageType, vector Momentum)
{
    local Vector HitNormal;
    local Vector HitRay;
    local Name HitBone;
    local float HitBoneDist;
    local PlayerController PC;
    local bool bShowEffects, bRecentHit;
    local BloodSpurt BloodHit;

    bRecentHit = Level.TimeSeconds - LastPainTime < 0.5;
    Super.PlayHit(Damage,InstigatedBy,HitLocation,DamageType,Momentum);
    if ( Damage <= 0 )
        return;


    PC = PlayerController(Controller);
    bShowEffects = ( (Level.NetMode != NM_Standalone) || (Level.TimeSeconds - LastRenderTime < 2.5)
                    || ((InstigatedBy != None)) );
    if ( !bShowEffects )
        return;
        
     if (BurnDown > 0)
     {
	                 AttachEmitterEffect( BurnEffect, 'Bip01',HitLocation, Rotation);
     }
        


    HitRay = vect(0,0,0);
    if( InstigatedBy != None )
        HitRay = Normal(HitLocation-(InstigatedBy.Location+(vect(0,0,1)*InstigatedBy.EyeHeight)));

    if( DamageType.default.bLocationalHit )
        CalcHitLoc( HitLocation, HitRay, HitBone, HitBoneDist );
    else
    {
        HitLocation = Location;
        HitBone = 'None';
        HitBoneDist = 0.0f;
    }

    if( DamageType.default.bAlwaysSevers && DamageType.default.bSpecial )
        HitBone = 'head';

    if( InstigatedBy != None )
        HitNormal = Normal( Normal(InstigatedBy.Location-HitLocation) + VRand() * 0.2 + vect(0,0,2.8) );
    else
        HitNormal = Normal( Vect(0,0,1) + VRand() * 0.2 + vect(0,0,2.8) );

    if ( DamageType.Default.bCausesBlood )
    {
      // Log("The damagetype does cause blood");

        if ( class'GameInfo'.static.UseLowGore() )
        {
            if ( class'GameInfo'.static.NoBlood() )
            {
               // Log("sorry, no blood");
                BloodHit = BloodSpurt(Spawn( GibGroupClass.default.NoBloodHitClass,InstigatedBy,, HitLocation ));
            }
            else
            {
               // Log("Low blood");
                BloodHit = BloodSpurt(Spawn( GibGroupClass.default.LowGoreBloodHitClass,InstigatedBy,, HitLocation ));
            }
        }
        else
        {
           // Log("BLOOD WEEE!");
            BloodHit = BloodSpurt(Spawn(GibGroupClass.default.BloodHitClass,InstigatedBy,, HitLocation, Rotator(HitNormal)));
        }
        if ( BloodHit != None )
        {
            BloodHit.bMustShow = !bRecentHit;
            if ( Momentum != vect(0,0,0) )
                BloodHit.HitDir = Momentum;
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

    // hack for flak cannon gibbing
    if ( (DamageType.name == 'DamTypeFlakChunk') && (Health < 0) && (InstigatedBy != None) && (VSize(InstigatedBy.Location - Location) < 350) )
        DoDamageFX( HitBone, 8*Damage, DamageType, Rotator(HitNormal) );
    else
        DoDamageFX( HitBone, Damage, DamageType, Rotator(HitNormal) );

    if (DamageType.default.DamageOverlayMaterial != None && Damage > 0 ) // additional check in case shield absorbed
                SetOverlayMaterial( DamageType.default.DamageOverlayMaterial, DamageType.default.DamageOverlayTime, false );


}


simulated function AttachEffect( class<xEmitter> EmitterClass, Name BoneName, Vector Location, Rotator Rotation )
{
    local Actor a;
    local int i;

    if( bSkeletized || (BoneName == 'None') )
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
    
    if (a == none) 
     return;

    if( !AttachToBone( a, BoneName ) )
    {
        log( "Couldn't attach "$EmitterClass$" to "$BoneName, 'Error' );
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

State Dying
{
	simulated function AnimEnd( int Channel );

	simulated function bool SpecialCalcView( out Actor ViewActor, out vector CameraLocation, out rotator CameraRotation )
	{
		local Coords Co;
		local vector HL,HN;

		ViewActor = Self;
		Co = GetBoneCoords('Bip01 Head');
		CameraLocation = Co.Origin+Co.XAxis*8;
		// Make sure camera dosent show through world geometry.
		if( Trace(HL,HN,CameraLocation+vect(0,0,25),CameraLocation,False)!=None )
			CameraLocation+=HN*25;
		if( Trace(HL,HN,CameraLocation-vect(0,0,25),CameraLocation,False)!=None )
			CameraLocation+=HN*25;
		if( Trace(HL,HN,CameraLocation+vect(25,0,0),CameraLocation,False)!=None )
			CameraLocation+=HN*25;
		if( Trace(HL,HN,CameraLocation-vect(25,0,0),CameraLocation,False)!=None )
			CameraLocation+=HN*25;
		if( Trace(HL,HN,CameraLocation+vect(0,25,0),CameraLocation,False)!=None )
			CameraLocation+=HN*25;
		if( Trace(HL,HN,CameraLocation-vect(0,25,0),CameraLocation,False)!=None )
			CameraLocation+=HN*25;
		GetAxes(GetBoneRotation('Bip01 Head'),Co.XAxis,Co.YAxis,Co.ZAxis);
		CameraRotation = OrthoRotation(-Co.YAxis,Co.ZAxis,Co.XAxis); // Turns the camera by 90 degrees.
		Return True;
	}
	event FellOutOfWorld(eKillZType KillType)
	{
		local LavaDeath LD;

		// If we fall past a lava killz while dead- burn off skin.
		if( KillType == KILLZ_Lava )
		{
			if ( !bSkeletized )
			{
				if ( SkeletonMesh != None )
				{
					LinkMesh(SkeletonMesh, true);
					Skins.Length = 0;
				}
				bSkeletized = true;

				LD = spawn(class'LavaDeath', , , Location + vect(0, 0, 10), Rotation );
				if ( LD != None )
					LD.SetBase(self);
				// This should destroy itself once its finished.
				PlaySound( sound'WeaponSounds.BExplosion5', SLOT_None, 1.5*TransientSoundVolume );
			}
			return;
		}
		Super.FellOutOfWorld(KillType);
	}

	simulated function TakeDamage( int Damage, Pawn InstigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> damageType)
	{
		local emitter BloodHit;
      
		Health -= Damage;

		if (Health <= -200)
		{
			// Gibbed
			BloodHit = Spawn(class'KFMod.FeedingSpray',InstigatedBy,,Location,Rotation);

			SpawnGiblet(class 'ClotGibHead',HitLocation, self.Rotation, 0.06 ) ;

			SpawnGiblet(class 'ClotGibTorso',HitLocation, self.Rotation, 0.06) ;
			SpawnGiblet(class 'ClotGibLowerTorso',HitLocation, self.Rotation, 0.06 ) ;

			SpawnGiblet(class 'ClotGibArm',HitLocation, self.Rotation, 0.06 ) ;
			SpawnGiblet(class 'ClotGibArm',HitLocation, self.Rotation, 0.06 ) ;

			SpawnGiblet(class 'ClotGibThigh',HitLocation, self.Rotation, 0.06 ) ;
			SpawnGiblet(class 'ClotGibThigh',HitLocation, self.Rotation, 0.06 ) ;

			SpawnGiblet(class 'ClotGibLeg',HitLocation, self.Rotation, 0.06 ) ;
			SpawnGiblet(class 'ClotGibLeg',HitLocation, self.Rotation, 0.06 ) ;
			Destroy();
		}
	}

	simulated function BeginState()
	{
		local int i;

		bSpecialCalcView = Class'KFPawn'.Default.bRealDeathType;
		if ( Controller != None )
		{
			if ( Controller.bIsPlayer )
				Controller.PawnDied(self);
			else Controller.Destroy();
		}
		for (i = 0; i < Attached.length; i++)
			if (Attached[i] != None)
				Attached[i].PawnBaseDied();
		AmbientSound = None;
		if( Level.NetMode==NM_DedicatedServer )
			SetTimer(1,False);
		SetTimer(5,False);
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

	// We shorten the lifetime when the guys comes to rest.
	// Alex: No , you dont.
	event KVelDropBelow()
	{
	}
}

simulated function Destroyed()
{
	if( ItBUURRNNNS!=None )
		ItBUURRNNNS.Destroy();
	Super.Destroyed();
}

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	local Vector            TossVel;
	local Trigger           T;
	local NavigationPoint   N;
	local PlayerDeathMark D;
	local Projectile PP;
	local FakePlayerPawn FP;

	if ( bDeleteMe || Level.bLevelChange || Level.Game == None )
		return; // already destroyed, or level is being cleaned up

	if ( DamageType.default.bCausedByWorld && (Killer == None || Killer == Controller) && LastHitBy != None )
		Killer = LastHitBy;

	// mutator hook to prevent deaths
	// WARNING - don't prevent bot suicides - they suicide when really needed
	if ( Level.Game.PreventDeath(self, Killer, damageType, HitLocation) )
	{
		Health = max(Health, 1); //mutator should set this higher
		return;
    	}

	// Hack fix for team-killing.
	if( KFPlayerReplicationInfo(PlayerReplicationInfo)!=None )
	{
		FP = KFPlayerReplicationInfo(PlayerReplicationInfo).GetBlamePawn();
		if( FP!=None )
		{
			ForEach DynamicActors(Class'Projectile',PP)
			{
				if( PP.Instigator==Self )
					PP.Instigator = FP;
			}
		}
	}

	D = Spawn(Class'PlayerDeathMark');
	if( D!=None )
		D.Velocity = Velocity;
    
	Health = Min(0, Health);

	if ( Weapon != None && (DrivenVehicle == None || DrivenVehicle.bAllowWeaponToss) )
	{
		if ( Controller != None )
			Controller.LastPawnWeapon = Weapon.Class;
		Weapon.HolderDied();
		TossVel = Vector(GetViewRotation());
		TossVel = TossVel * ((Velocity Dot TossVel) + 500) + Vect(0,0,200);
		TossWeapon(TossVel);
	}
	if ( DrivenVehicle != None )
	{
		Velocity = DrivenVehicle.Velocity;
		DrivenVehicle.DriverDied();
	}

	if ( Controller != None )
	{
		Controller.WasKilledBy(Killer);
		Level.Game.Killed(Killer, Controller, self, damageType);
	}
	else Level.Game.Killed(Killer, Controller(Owner), self, damageType);

	DrivenVehicle = None;

	if ( Killer != None )
		TriggerEvent(Event, self, Killer.Pawn);
	else TriggerEvent(Event, self, None);

	// make sure to untrigger any triggers requiring player touch
	if ( IsPlayerPawn() || WasPlayerPawn() )
	{
		PhysicsVolume.PlayerPawnDiedInVolume(self);
		ForEach TouchingActors(class'Trigger',T)
			T.PlayerToucherDied(self);

		// event for HoldObjectives
		ForEach TouchingActors(class'NavigationPoint', N)
			if ( N.bReceivePlayerToucherDiedNotify )
				N.PlayerToucherDied( Self );
	}
	// remove powerup effects, etc.
	RemovePowerups();

	Velocity.Z *= 1.3;

	if ( IsHumanControlled() )
		PlayerController(Controller).ForceDeathUpdate();

	NetUpdateFrequency = Default.NetUpdateFrequency;
	PlayDying(DamageType, HitLocation);
	if ( !bPhysicsAnimUpdate && !IsLocallyControlled() )
		ClientDying(DamageType, HitLocation);
}

simulated function ChunkUp( Rotator HitRotation, float ChunkPerterbation )
{
  /*
    if ( (Level.NetMode != NM_Client) && (Controller != None) )
    {
        if ( Controller.bIsPlayer )
            Controller.PawnDied(self);
        else
            Controller.Destroy();
    }

    bTearOff = true;
    HitDamageType = class'Gibbed'; // make sure clients gib also
    if ( (Level.NetMode == NM_DedicatedServer) || (Level.NetMode == NM_ListenServer) )
        GotoState('TimingOut');
    if ( Level.NetMode == NM_DedicatedServer )
        return;
    if ( class'GameInfo'.static.UseLowGore() )
    {
        Destroy();
        return;
    }
    SpawnGibs(HitRotation,ChunkPerterbation);

    if ( Level.NetMode != NM_ListenServer )
        Destroy();
        */
}


// toss some of your cash away. (to help a cash-strapped ally or perhaps just to party like its 1994)
exec function TossCash( int Amount )
{
	local Vector X,Y,Z;
	local CashPickup CashPickup ;
	local Vector TossVel;

	if( Amount<=0 )
		Amount = 50;
	Controller.PlayerReplicationInfo.Score = int(Controller.PlayerReplicationInfo.Score); // To fix issue with throwing 0 pounds.
	if( Controller.PlayerReplicationInfo.Score<=0 || Amount<=0 )
		return;
	Amount = Min(Amount,int(Controller.PlayerReplicationInfo.Score));

	GetAxes(Rotation,X,Y,Z);
    
	TossVel = Vector(GetViewRotation());
	TossVel = TossVel * ((Velocity Dot TossVel) + 500) + Vect(0,0,200);

	CashPickup = Spawn(class'CashPickup',,, Location + 0.8 * CollisionRadius * X - 0.5 * CollisionRadius * Y);

	if(CashPickup != none)
	{
		CashPickup.CashAmount = Amount;
		CashPickup.bDroppedCash = true;
		CashPickup.RespawnTime = 0;   // Dropped cash doesnt respawn. For obvious reasons.
		CashPickup.Velocity = TossVel;
		CashPickup.InitDroppedPickupFor(None);
		Controller.PlayerReplicationInfo.Score -= Amount;
		Controller.PlayerReplicationInfo.Team.Score -= Amount;
	}
}

simulated function AttachEmitterEffect( class<Emitter> EmitterClass, Name BoneName, Vector Location, Rotator Rotation )
{
    local Actor a;
    local int i;

    if( bSkeletized || (BoneName == 'None') )
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
        log( "Couldn't attach "$EmitterClass$" to "$BoneName, 'Error' );
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
        if( Attached[i].IsA('xEmitter') && !Attached[i].IsA('BloodJet'))
        {
            xEmitter(Attached[i]).mRegen = false;
        }
        
         if( Attached[i].IsA('KFMonsterFlame'))
        {
          Attached[i].LifeSpan = 0.1;
        }
    }
}

simulated function class<KFVeterancyTypes> GetVeteran()
{
	if( KFPlayerReplicationInfo(PlayerReplicationInfo)!=None && KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill!=None )
		Return KFPlayerReplicationInfo(PlayerReplicationInfo).ClientVeteranSkill;
	Return Class'KFVeterancyTypes'; // The base neutral class.
}

function bool CanCarry( float Weight )
{
	Return True;
}

// Validate that client is not hacking.
function bool CanBuyNow()
{
	local ShopVolume Sh;

	if( KFGameType(Level.Game)==None || KFGameType(Level.Game).bWaveInProgress || PlayerReplicationInfo==None )
		Return False;
	ForEach TouchingActors(Class'ShopVolume',Sh)
		Return True;
	Return False;
}
function bool ItemIsBuyable( Class<Pickup> IC )
{
	local int i;

	if( LevRls==None )
	{
		ForEach DynamicActors(Class'KFLevelRules',LevRls)
			Break;
		if( LevRls==None )
			Return False;
	}
	For( i=0; i<25; i++ )
	{
		if( LevRls.ItemForSale[i]==IC )
			Return True;
	}
	Return False;
}

function ServerBuyWeapon( Class<Weapon> WClass )
{
	local Inventory I;
	local float Price;

	if( !CanBuyNow() || Class<KFWeapon>(WClass)==None || Class<KFWeaponPickup>(WClass.Default.PickupClass)==None )
		Return;
	Price = int(float(Class<KFWeaponPickup>(WClass.Default.PickupClass).Default.Cost)*GetCostScaling(Level.Game.GameDifficulty));
	if( PlayerReplicationInfo.Score<Price )
		Return; // Not enough CASH.
	For( I=Inventory; I!=None; I=I.Inventory )
	{
		if( I.Class==WClass )
			Return; // Already has weapon.
	}
	if( !CanCarry(Class<KFWeapon>(WClass).Default.Weight) || !ItemIsBuyable(WClass.Default.PickupClass) )
		Return;
	PlayerReplicationInfo.Score-=Price;
	I = Spawn(WClass);
	if( I!=None )
	{
	        KFWeapon(I).FillToInitialAmmo();
                I.GiveTo(self);
        }
}
function ServerSellWeapon( Class<Weapon> WClass )
{
	local Inventory I;
	local Single J;

	if( !CanBuyNow() || Class<KFWeapon>(WClass)==None || Class<KFWeaponPickup>(WClass.Default.PickupClass)==None )
		Return;
	For( I=Inventory; I!=None; I=I.Inventory )
	{
		if( I.Class==WClass )
		{
			PlayerReplicationInfo.Score+=(Class<KFWeaponPickup>(WClass.Default.PickupClass).Default.Cost*0.75);
			if( Dualies(I)!=None )
			{
				J = Spawn(Class'Single');
				J.GiveTo(Self);
			}
			I.Destroy();
			Return;
		}
	}
}

function ServerBuyKevlar()
{
	local float Cost;

	if( !CanBuyNow() || ShieldStrength==100 )
		Return;
	Cost = int(300*GetCostScaling(Level.Game.GameDifficulty));
	if( PlayerReplicationInfo.Score<Cost )
		Return;
	PlayerReplicationInfo.Score-=Cost;
	ShieldStrength = 100;
}

function ServerBuyFirstAid()
{
	local float Cost;

	if( !CanBuyNow() || Health==100 )
		Return;
	Cost = int(150*GetCostScaling(Level.Game.GameDifficulty));
	if( PlayerReplicationInfo.Score<Cost )
		Return;
	PlayerReplicationInfo.Score-=Cost;
	GiveHealth(100,100);
}

function ServerBuyAmmo( Class<Ammunition> AClass, bool bOnlyClip )
{
	local Inventory I;
	local float Price;
	local Ammunition AM;
	local KFWeapon KW;
	local int c;

	if( !CanBuyNow() || AClass==None )
		Return;
	For( I=Inventory; I!=None; I=I.Inventory )
	{
		if( I.Class==AClass )
			AM = Ammunition(I);
		else if( KW==None && KFWeapon(I)!=None && (Weapon(I).AmmoClass[0]==AClass || Weapon(I).AmmoClass[1]==AClass) )
			KW = KFWeapon(I);
	}
	AM.MaxAmmo = AM.Default.MaxAmmo*GetVeteran().Static.AddExtraAmmoFor(AClass);
	if( (AM==None && KW==None) || AM.AmmoAmount>=AM.MaxAmmo )
		Return;
	Price = int(Class<KFWeaponPickup>(KW.PickupClass).Default.AmmoCost*GetCostScaling(Level.Game.GameDifficulty)); // Clip price.
	if( bOnlyClip )
		c = KW.Default.ClipCount;
	else c = (AM.MaxAmmo-AM.AmmoAmount);
	Price = float(c)/float(KW.Default.ClipCount)*Price;
	if( PlayerReplicationInfo.Score<Price )
		Return; // Not enough CASH.
	PlayerReplicationInfo.Score-=Price;
	AM.AddAmmo(c);
}

function ServerSellAmmo( Class<Ammunition> AClass )
{
	local Inventory I;
	local float Price;
	local Ammunition AM;
	local KFWeapon KW;
	local int c;

	if( !CanBuyNow() || AClass==None )
		Return;
	For( I=Inventory; I!=None; I=I.Inventory )
	{
		if( I.Class==AClass )
			AM = Ammunition(I);
		else if( KW==None && KFWeapon(I)!=None && (Weapon(I).AmmoClass[0]==AClass || Weapon(I).AmmoClass[1]==AClass) )
			KW = KFWeapon(I);
	}
	if( (AM==None && KW==None) || AM.AmmoAmount==AM.MaxAmmo )
		Return;
	Price = int(Class<KFWeaponPickup>(KW.PickupClass).Default.AmmoCost*GetCostScaling(Level.Game.GameDifficulty)); // Clip price.
	c = KW.Default.ClipCount;
	if( c>AM.AmmoAmount )
		c = AM.AmmoAmount;
	Price = float(c)/float(KW.Default.ClipCount)*Price*0.75;
	PlayerReplicationInfo.Score+=Price;
	AM.AmmoAmount-=c;
}

simulated static function float GetCostScaling( float Difficulty )
{
	return FClamp(Difficulty/3,0.8,4);
}

// Allow players spawn on top of each other.
event bool EncroachingOn( actor Other )
{
	if ( Other.bWorldGeometry || Other.bBlocksTeleport )
		return true;

	if ( (Vehicle(Other) != None) && (Weapon != None) && Weapon.IsA('Translauncher') )
		return true;

	return false;
}
event EncroachedBy( actor Other )
{
	if ( Pawn(Other)!=None && Vehicle(Other)==None && KFPawn(Other)==None )
		gibbedBy(Other);
}

defaultproperties
{
	BileFrequency=0.500000
	BurnEffect=Class'KFMod.KFMonsterFlame'
	bRealDeathType=True
	ShieldStrengthMax=100.000000
	ShieldHitMat=None
	FootstepVolume=1.000000
	GibGroupClass=Class'KFMod.KFHumanGibGroup'
	SoundGroupClass=Class'KFMod.KFMaleSoundGroup'
	TeleportFXClass=None
	TransEffects(0)=None
	TransEffects(1)=None
	DeResTime=0.000000
	DeResMat0=Texture'KFCharacters.KFDeRez'
	DeResMat1=Texture'KFCharacters.KFDeRez'
	DeResLiftVel=(Points=(,(InVal=0.000000,OutVal=0.000000),(InVal=0.000000,OutVal=0.000000)))
	DeResLiftSoftness=(Points=((OutVal=0.000000),(InVal=0.000000,OutVal=0.000000),(InVal=0.000000,OutVal=0.000000)))
	DeResLateralFriction=0.000000
	RagdollLifeSpan=9999.000000
	RagDeathVel=75.000000
	RagShootStrength=6000.000000
	RagDeathUpKick=100.000000
	TransOutEffect(0)=None
	TransOutEffect(1)=None
	RequiredEquipment(0)="none"
	RequiredEquipment(1)="none"
	bScriptPostRender=True
	MeleeRange=80.000000
	GroundSpeed=240.000000
	WaterSpeed=180.000000
	AirSpeed=240.000000
	JumpZ=300.000000
	BaseEyeHeight=54.000000
	EyeHeight=54.000000
	DodgeSpeedFactor=1.000000
	DodgeSpeedZ=0.000000
	SwimAnims(0)="WalkF"
	SwimAnims(1)="WalkB"
	SwimAnims(2)="WalkL"
	SwimAnims(3)="WalkR"
	AmbientGlow=0
	bClientAnim=True
	CollisionRadius=26.000000
	CollisionHeight=40.000000
	bBlockKarma=True
	Mass=400.000000
}
