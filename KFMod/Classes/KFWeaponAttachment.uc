// Tracer Fire

class KFWeaponAttachment extends xWeaponAttachment;

var class<Emitter>      mMuzFlashClass;
var Emitter             mMuzFlash3rd;

var class<Emitter>      mTracerClass;
var() editinline Emitter mTracer;
var() float             mTracerPullback;
var() float             mTracerMinDistance;
var() float             mTracerSpeed;
var() int               TracerEvery;	// one round in so many is a tracer (none set: every one)
var int                 TracerRounds;
var byte                OldSpawnHitCount;

var class<xEmitter>     mShellCaseEmitterClass;
var xEmitter            mShellCaseEmitter;
var() vector            mShellEmitterOffset;

var vector  mOldHitLocation;

var () class<Actor> HitEffectType;
var() float	SmokeHeat;		// how much a shot heats the gun for its smoke (KFGunSmoke); none for guns without
var() float	GunLightRadius, GunLightBrightness;	// the first-person gun's own light while a shot's light lights the room (GunLight)
var KFGunSmoke	GunSmoke;
var byte	SmokeFlashCount;	// the shots its smoke has had
                                                        
var() array<name> TPAnims,TPAnimsB; // Custom third person animations.
var() name WeaponIdleMovementAnim,SecondaryWeaponIdleMovementAnim; // Custom holding weapon animation.
var Pawn LastInstig;

var vector OlComprVect;

var class<Weapon> WeaponClass;	// the gun this is the third-person model of; a client needs its damage figures
var bool bUpgraded, bUpgradeShown;	// its weapon is upgraded (KFWeapon.Upgrade); shown so here
var byte UpgradeElement;			// ...its element (KFElement)
var byte CorpseHitSeen;			// the last shot from the server that was tried against this machine's bodies
var byte CorpseShotCount, CorpseShotSeen;	// shots the server saw stop on a dead specimen, and the last one tried here
var vector CorpseShotLoc;		// where the last of those stopped
var() float CorpseHitReach;		// how far past the server's hit point a client looks for its own body

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		WeaponClass;
	reliable if ( bNetDirty && Role == ROLE_Authority )
		CorpseShotCount, CorpseShotLoc, bUpgraded, UpgradeElement;
}

simulated function Tick( float DT )
{
	Super.Tick(DT);
	if ( bUpgraded && !bUpgradeShown )
		ShowUpgrade();
	else if ( bUpgraded && Level.NetMode != NM_DedicatedServer && OverlayMaterial != class'KFWeapon'.static.UpgradeLookOf(UpgradeElement) )
	{
		SetOverlayMaterial(class'KFWeapon'.static.UpgradeLookOf(UpgradeElement), 1000000.0, true);
		TintTracer();
	}
}

// Its weapon is upgraded (KFWeapon.Upgrade): drawn so, its tracers tinted
simulated function ShowUpgrade()
{
	bUpgradeShown = true;
	if ( Level.NetMode == NM_DedicatedServer )
		return;
	SetOverlayMaterial(class'KFWeapon'.static.UpgradeLookOf(UpgradeElement), 1000000.0, true);
	TintTracer();
}

simulated function TintTracer()
{
	local int i;
	local color C;

	if ( mTracer == None )
		return;
	C = class'KFWeapon'.default.UpgradeTint;
	if ( class'KFElement'.static.Has(UpgradeElement) )
		C = class'KFElement'.static.Glow(UpgradeElement);
	for ( i = 0; i < mTracer.Emitters.Length; i++ )
		if ( mTracer.Emitters[i] != None )
		{
			mTracer.Emitters[i].ColorMultiplierRange.X.Min = C.R / 255.0;
			mTracer.Emitters[i].ColorMultiplierRange.X.Max = C.R / 255.0;
			mTracer.Emitters[i].ColorMultiplierRange.Y.Min = C.G / 255.0;
			mTracer.Emitters[i].ColorMultiplierRange.Y.Max = C.G / 255.0;
			mTracer.Emitters[i].ColorMultiplierRange.Z.Min = C.B / 255.0;
			mTracer.Emitters[i].ColorMultiplierRange.Z.Max = C.B / 255.0;
		}
}

function InitFor(Inventory I)
{
	Super.InitFor(I);
	WeaponClass = class<Weapon>(I.Class);
}

// A shot that stopped on a dead specimen here. No wall was hit, so no hit effect goes out with it.
function UpdateCorpseHit(vector HitLocation)
{
	CorpseShotCount++;
	CorpseShotLoc = HitLocation;
	NetUpdateTime = Level.TimeSeconds - 1;
}

// A dead specimen is handed over to each machine, which keeps its own ragdoll; a dedicated server has
// none. So each client lands a shot on its own bodies, from where the server says the shot ended:
// on the world, or on the server's own idea of a dead specimen.
simulated function HitCorpse( vector ShotEnd )
{
	local class<InstantFire> F;
	local vector Start, Dir, HitLoc, HitNorm;
	local Actor A;

	if ( Instigator == None || WeaponClass == None )
		return;
	F = class<InstantFire>(WeaponClass.default.FireModeClass[0]);
	if ( F == None )
		return;
	Start = Instigator.Location + Instigator.EyePosition();
	Dir = Normal(ShotEnd - Start);
	A = Instigator.Trace(HitLoc, HitNorm, ShotEnd + Dir * CorpseHitReach, Start, true);
	if ( KFMonster(A) != None && A.bTearOff && KFMonster(A).Health <= 0 )
		A.TakeDamage(Lerp(FRand(), F.default.DamageMin, F.default.DamageMax), Instigator, HitLoc,
			F.default.Momentum * Dir, F.default.DamageType);
}

simulated function name GetThirdPersonAnim()
{
    if( FiringMode==1 && TPAnimsB.Length>0 )
		Return TPAnimsB[Rand(TPAnimsB.Length)];
	if( TPAnims.Length==0 )
		Return '';
	else if( TPAnims.Length==1 )
		Return TPAnims[0];
	Return TPAnims[Rand(TPAnims.Length)];
}
simulated function PostNetReceive()
{
	if( Instigator!=LastInstig )
	{
		LastInstig = Instigator;
		if( KFPawn(Instigator)!=None )
		{
			KFPawn(Instigator).UpdateClientAnim(WeaponIdleMovementAnim);
			KFPawn(Instigator).WeaponAttachment = Self;
		}
	}
	if ( SpawnHitCount != CorpseHitSeen )
	{
		CorpseHitSeen = SpawnHitCount;
		if ( Level.NetMode == NM_Client )
			HitCorpse(mHitLocation);
	}
	if ( CorpseShotCount != CorpseShotSeen )
	{
		CorpseShotSeen = CorpseShotCount;
		if ( Level.NetMode == NM_Client )
			HitCorpse(CorpseShotLoc);
	}
}
simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	if( KFPawn(Instigator)!=None )
	{
		KFPawn(Instigator).UpdateClientAnim(WeaponIdleMovementAnim);
		KFPawn(Instigator).WeaponAttachment = Self;
	}
	LastInstig = Instigator;
	mHitLocation = vect(0,0,0);
	CorpseHitSeen = SpawnHitCount;
	CorpseShotSeen = CorpseShotCount;
	bNetNotify = True;
}

simulated function ChangeIdleToPrimary()
{
	WeaponIdleMovementAnim = Default.WeaponIdleMovementAnim;
	if( KFPawn(Instigator)!=None )
		KFPawn(Instigator).UpdateClientAnim(WeaponIdleMovementAnim);
}
simulated function ChangeIdleToSecondary()
{
	WeaponIdleMovementAnim = SecondaryWeaponIdleMovementAnim;
	if( KFPawn(Instigator)!=None )
		KFPawn(Instigator).UpdateClientAnim(SecondaryWeaponIdleMovementAnim);
}
simulated function UpdateTacBeam( float Dist );
simulated function TacBeamGone();

simulated function AddHitFX()
{
	local vector SpawnLoc, SpawnDir, SpawnVel;
	local float hitDist, Half;
	local int i;

	if (mTracer == None)
	{
		mTracer = Spawn(mTracerClass);
		if ( bUpgraded )
			TintTracer();
	}

	TracerRounds++;
	if ( TracerEvery > 1 && TracerRounds % TracerEvery != 1 )
		return;

	if( mTracer != None )
	{
		SpawnLoc = GetTracerStart();
		SpawnDir = Normal(mHitLocation - SpawnLoc);
		hitDist = VSize(mHitLocation - SpawnLoc) - mTracerPullback;
		// (a streak is drawn about its middle: it starts half its length out, so that its tail is at the muzzle and
		// none of it reaches back past the gun, or past the eye of the one firing)
		if ( KFRoundTracer(mTracer) != None )
		{
			Half = 0.5 * FMax(KFRoundTracer(mTracer).CoreLen, KFRoundTracer(mTracer).GlowLen) * mTracerSpeed / KFRoundTracer(mTracer).RefSpeed;
			SpawnLoc += SpawnDir * Half;
			hitDist -= Half;
		}
		mTracer.SetLocation(SpawnLoc);

		if(hitDist > mTracerMinDistance)
		{
			SpawnVel = SpawnDir * mTracerSpeed;
			// (every layer of the tracer flies the same line)
			for ( i = 0; i < mTracer.Emitters.Length; i++ )
			{
				mTracer.Emitters[i].StartVelocityRange.X.Min = SpawnVel.X;
				mTracer.Emitters[i].StartVelocityRange.X.Max = SpawnVel.X;
				mTracer.Emitters[i].StartVelocityRange.Y.Min = SpawnVel.Y;
				mTracer.Emitters[i].StartVelocityRange.Y.Max = SpawnVel.Y;
				mTracer.Emitters[i].StartVelocityRange.Z.Min = SpawnVel.Z;
				mTracer.Emitters[i].StartVelocityRange.Z.Max = SpawnVel.Z;

				mTracer.Emitters[i].LifetimeRange.Min = hitDist / mTracerSpeed;
				mTracer.Emitters[i].LifetimeRange.Max = mTracer.Emitters[i].LifetimeRange.Min;
			}

			mTracer.SpawnParticle(1);
		}
	}
}

function Destroyed()
{
	if (mTracer != None)
		mTracer.Destroy();

	if (mMuzFlash3rd != None)
		mMuzFlash3rd.Destroy();

	if (mShellCaseEmitter != None)
		mShellCaseEmitter.Destroy();

	if ( GunSmoke != None )
		GunSmoke.GunGone();

	Super.Destroyed();
}

simulated function vector GetTracerStart()
{
	local Pawn p;

	p = Pawn(Owner);

	if ( (p != None) && p.IsFirstPerson() && KFWeapon(p.Weapon) != None )
		return KFWeapon(p.Weapon).ShotMuzzle();
	if ( (p != None) && p.IsFirstPerson() && p.Weapon != None )
		return p.Weapon.GetEffectStart();

	if( Instigator!=None && (Level.TimeSeconds-LastRenderTime)>2 )
		Return Instigator.Location;
	// 3rd person
	if ( mMuzFlash3rd != None )
		return mMuzFlash3rd.Location;
	else return Location;
}

function UpdateHit(Actor HitActor, vector HitLocation, vector HitNormal)
{
	SpawnHitCount++;
	mHitLocation = HitLocation;
	mHitActor = HitActor;
	mHitNormal = HitNormal;
	NetUpdateTime = Level.TimeSeconds - 1;
}

simulated event ThirdPersonEffects()
{
	local PlayerController PC;

	if ( (Level.NetMode == NM_DedicatedServer) || (Instigator == None) )
		return;

		// new Trace FX - Ramm
	if (FiringMode == 0)
	{
		if ( OldSpawnHitCount != SpawnHitCount )
		{
			OldSpawnHitCount = SpawnHitCount;
			GetHitInfo();
			PC = Level.GetLocalPlayerController();
			if ( ((Instigator != None) && (Instigator.Controller == PC)) || (VSize(PC.ViewTarget.Location - mHitLocation) < 4000) )
			{
				Spawn(HitEffectType,mHitActor,, mHitLocation, Rotator(mHitNormal));
				if ( bUpgraded && class'KFElement'.static.Has(UpgradeElement) )
					ElementHit();
				CheckForSplash();
				AddHitFX();
			}
		}
	}

  	if ( FlashCount>0 )
	{
		if( KFPawn(Instigator)!=None )
		{
			if (FiringMode == 0)
				KFPawn(Instigator).StartFiringX(bHeavy,bRapidFire,GetThirdPersonAnim());
			else KFPawn(Instigator).StartFiringX(bHeavy,bAltRapidFire,GetThirdPersonAnim());
		}
		PC = Level.GetLocalPlayerController();

		if ( (Level.TimeSeconds - LastRenderTime > 0.2) && (Instigator.Controller != PC) )
			return;

		WeaponLight();
		DoFlashEmitter();
		if ( SmokeHeat > 0 && Level.DetailMode != DM_Low )
			Smoke();

		if ( (mShellCaseEmitter == None) && (Level.DetailMode != DM_Low) && !Level.bDropDetail && !OwnBrassShown() )
		{
			mShellCaseEmitter = Spawn(mShellCaseEmitterClass);
			if ( mShellCaseEmitter != None )
			    AttachToBone(mShellCaseEmitter, 'ShellPort');
		}
		if (mShellCaseEmitter != None && !OwnBrassShown())
			mShellCaseEmitter.mStartParticles++;
	}
	else
	{
		SmokeFlashCount = 0;
		GotoState('');
		if( KFPawn(Instigator)!=None )
			KFPawn(Instigator).StopFiring();
	}
}

// The shots since the last, for the gun's smoke (several may come in one network update)
simulated function Smoke()
{
	local int Shots;

	Shots = FlashCount - SmokeFlashCount;
	if ( Shots <= 0 )
		Shots = 1;
	SmokeFlashCount = FlashCount;
	if ( GunSmoke == None || GunSmoke.bDeleteMe )
		GunSmoke = Spawn(class'KFGunSmoke', self);
	if ( GunSmoke != None )
		GunSmoke.Shot(Min(Shots, 4), SmokeHeat);
}

simulated function WeaponLight()
{
    if ( (FlashCount > 0) && !Level.bDropDetail && (Instigator != None)
		&& ((Level.TimeSeconds - LastRenderTime < 0.2) || (PlayerController(Instigator.Controller) != None)) )
    {
		if ( Instigator.IsFirstPerson() )
		{
			LitWeapon = Instigator.Weapon;
			GunLight(LitWeapon);
			LitWeapon.bDynamicLight = true;
		}
		else
			bDynamicLight = true;
        SetTimer(0.15, false);
    }
    else
		Timer();
}

// The first-person gun's own light for a shot, in its flash's colour. While a shot's light thrown ahead lights the
// room (KFWeapon.ShotLight) it reaches only the gun and the hands holding it.
simulated function GunLight( Actor W )
{
	local class<KFFlash> F;

	W.LightRadius = W.default.LightRadius;
	W.LightBrightness = W.default.LightBrightness;
	if ( KFWeapon(W) != None && KFWeapon(W).MuzzleLight != None && !KFWeapon(W).MuzzleLight.bDeleteMe )
	{
		W.LightRadius = GunLightRadius;
		W.LightBrightness = GunLightBrightness;
	}
	F = class<KFFlash>(mMuzFlashClass);
	if ( bUpgraded && class'KFElement'.static.Has(UpgradeElement) )
	{
		W.LightHue = class'KFElement'.default.Hues[UpgradeElement];
		W.LightSaturation = class'KFElement'.default.Sats[UpgradeElement];
	}
	else if ( F != None )
	{
		W.LightHue = F.default.FlashHue;
		W.LightSaturation = F.default.FlashSat;
	}
}

// An upgraded gun's round strikes in its element's colour
simulated function ElementHit()
{
	local KFElementHit H;

	H = Spawn(class'KFElementHit', self,, mHitLocation + mHitNormal * 2, Rotator(mHitNormal));
	if ( H != None )
	{
		H.Tint = class'KFElement'.static.Glow(UpgradeElement);
		H.bTint = true;
	}
}

simulated function DoFlashEmitter()
{
    if (mMuzFlash3rd == None)
    {
        mMuzFlash3rd = Spawn(mMuzFlashClass);
        if ( KFFlash(mMuzFlash3rd) != None )
            KFFlash(mMuzFlash3rd).bThird = true;
        AttachToBone(mMuzFlash3rd, 'tip');
    }
    if ( KFFlash(mMuzFlash3rd) != None && bUpgraded && class'KFElement'.static.Has(UpgradeElement) )
        KFFlash(mMuzFlash3rd).SetTint(class'KFElement'.static.Glow(UpgradeElement));
    if ( KFFlash(mMuzFlash3rd) != None )
        KFFlash(mMuzFlash3rd).Flash();
    else if(mMuzFlash3rd != None)
        mMuzFlash3rd.SpawnParticle(1);
}

// The shooter in first person sees the casings out of the gun in their hands (KFWeapon.EjectBrass), not out of the body
simulated function bool OwnBrassShown()
{
	return Instigator != None && Instigator.IsFirstPerson() && KFWeapon(Instigator.Weapon) != None && KFWeapon(Instigator.Weapon).BrassClass != None;
}

defaultproperties
{
     mTracerPullback=50.000000
     GunLightRadius=2.200000
     GunLightBrightness=170.000000
     mTracerSpeed=7500.000000
     HitEffectType=Class'KFMod.KFHitEffect'
     CorpseHitReach=300.000000
     WeaponIdleMovementAnim="Idle_Rifle"
     LightType=LT_Steady
     LightEffect=LE_NonIncidence
     LightHue=30
     LightSaturation=150
     LightBrightness=255.000000
     LightRadius=10.000000
     LightPeriod=3
}
