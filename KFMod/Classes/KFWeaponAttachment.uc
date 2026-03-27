// Tracer Fire

class KFWeaponAttachment extends xWeaponAttachment;

var class<Emitter>      mMuzFlashClass;
var Emitter             mMuzFlash3rd;

var class<Emitter>      mTracerClass;
var() editinline Emitter mTracer;
var() float             mTracerPullback;
var() float             mTracerMinDistance;
var() float             mTracerSpeed;
var byte                OldSpawnHitCount;

var class<xEmitter>     mShellCaseEmitterClass;
var xEmitter            mShellCaseEmitter;
var() vector            mShellEmitterOffset;

var vector  mOldHitLocation;

<<<<<<< HEAD
var () class<KFHitEffect> HitEffectType;
=======
var () class<Actor> HitEffectType;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
                                                        
var() array<name> TPAnims,TPAnimsB; // Custom third person animations.
var() name WeaponIdleMovementAnim,SecondaryWeaponIdleMovementAnim; // Custom holding weapon animation.
var Pawn LastInstig;

var vector OlComprVect;

simulated function name GetThirdPersonAnim()
{
<<<<<<< HEAD
        if( FiringMode==1 && TPAnimsB.Length>0 )
=======
    if( FiringMode==1 && TPAnimsB.Length>0 )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
<<<<<<< HEAD
	else if( mHitLocation!=vect(0,0,0) )
	{
		AddHitFX();
		mHitLocation = vect(0,0,0);
	}
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
<<<<<<< HEAD
	LastInstig = Instigator;
	mHitLocation = vect(0,0,0);
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	if( KFPawn(Instigator)!=None )
	{
		KFPawn(Instigator).UpdateClientAnim(WeaponIdleMovementAnim);
		KFPawn(Instigator).WeaponAttachment = Self;
	}
<<<<<<< HEAD
=======
	LastInstig = Instigator;
	mHitLocation = vect(0,0,0);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
	local float hitDist;
<<<<<<< HEAD
	local Actor A;

	if( Instigator!=None )
	{
		A = Spawn(HitEffectType,,,mHitLocation);
		if( A!=None )
			A.RemoteRole = ROLE_None;
	}

	CheckForSplash();
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	if (mTracer == None)
		mTracer = Spawn(mTracerClass);

	if( mTracer != None )
	{
		SpawnLoc = GetTracerStart();
		mTracer.SetLocation(SpawnLoc);

		hitDist = VSize(mHitLocation - SpawnLoc) - mTracerPullback;

		SpawnDir = Normal(mHitLocation - SpawnLoc);

		if(hitDist > mTracerMinDistance)
		{
			SpawnVel = SpawnDir * mTracerSpeed;
			mTracer.Emitters[0].StartVelocityRange.X.Min = SpawnVel.X;
			mTracer.Emitters[0].StartVelocityRange.X.Max = SpawnVel.X;
			mTracer.Emitters[0].StartVelocityRange.Y.Min = SpawnVel.Y;
			mTracer.Emitters[0].StartVelocityRange.Y.Max = SpawnVel.Y;
			mTracer.Emitters[0].StartVelocityRange.Z.Min = SpawnVel.Z;
			mTracer.Emitters[0].StartVelocityRange.Z.Max = SpawnVel.Z;

			mTracer.Emitters[0].LifetimeRange.Min = hitDist / mTracerSpeed;
			mTracer.Emitters[0].LifetimeRange.Max = mTracer.Emitters[0].LifetimeRange.Min;

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

	Super.Destroyed();
}

simulated function vector GetTracerStart()
{
	local Pawn p;

	p = Pawn(Owner);

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
<<<<<<< HEAD
	local vector V;

	if( Level.NetMode!=NM_StandAlone ) // Skip some processing on single player games
	{
		V.X = int(HitLocation.X);
		V.Y = int(HitLocation.Y);
		V.Z = int(HitLocation.Z);
		if( OlComprVect==V ) // Make sure it dosent replicate same location twice.
			V.Z+=1;
		OlComprVect = V;
		NetUpdateTime = Level.TimeSeconds - 1;
	}
	if( Level.NetMode!=NM_DedicatedServer )
	{
		mHitLocation = HitLocation;
		AddHitFX();
	}
	mHitLocation = V;
=======
	SpawnHitCount++;
	mHitLocation = HitLocation;
	mHitActor = HitActor;
	mHitNormal = HitNormal;
	NetUpdateTime = Level.TimeSeconds - 1;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

simulated event ThirdPersonEffects()
{
	local PlayerController PC;

	if ( (Level.NetMode == NM_DedicatedServer) || (Instigator == None) )
		return;

<<<<<<< HEAD
=======
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
				CheckForSplash();
				AddHitFX();
			}
		}
	}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
<<<<<<< HEAD

=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		DoFlashEmitter();

		if ( (mShellCaseEmitter == None) && (Level.DetailMode != DM_Low) && !Level.bDropDetail )
		{
			mShellCaseEmitter = Spawn(mShellCaseEmitterClass);
			if ( mShellCaseEmitter != None )
			    AttachToBone(mShellCaseEmitter, 'ShellPort');
		}
		if (mShellCaseEmitter != None)
			mShellCaseEmitter.mStartParticles++;
	}
	else
	{
		GotoState('');
		if( KFPawn(Instigator)!=None )
			KFPawn(Instigator).StopFiring();
	}
}

simulated function WeaponLight()
{
    if ( (FlashCount > 0) && !Level.bDropDetail && (Instigator != None)
		&& ((Level.TimeSeconds - LastRenderTime < 0.2) || (PlayerController(Instigator.Controller) != None)) )
    {
		if ( Instigator.IsFirstPerson() )
		{
			LitWeapon = Instigator.Weapon;
			LitWeapon.bDynamicLight = true;
		}
		else
			bDynamicLight = true;
        SetTimer(0.15, false);
    }
    else
		Timer();
}

simulated function DoFlashEmitter()
{
    if (mMuzFlash3rd == None)
    {
        mMuzFlash3rd = Spawn(mMuzFlashClass);
        AttachToBone(mMuzFlash3rd, 'tip');
    }
    if(mMuzFlash3rd != None)
        mMuzFlash3rd.SpawnParticle(1);
}

defaultproperties
{
<<<<<<< HEAD
	mTracerPullback=50.000000
	mTracerSpeed=7500.000000
	HitEffectType=Class'KFMod.KFHitEffect'
	WeaponIdleMovementAnim="Idle_Rifle"
	LightType=LT_Steady
	LightEffect=LE_NonIncidence
	LightHue=30
	LightSaturation=150
	LightBrightness=255.000000
	LightRadius=10.000000
	LightPeriod=3
=======
     mTracerPullback=50.000000
     mTracerSpeed=7500.000000
     HitEffectType=Class'KFMod.KFHitEffect'
     WeaponIdleMovementAnim="Idle_Rifle"
     LightType=LT_Steady
     LightEffect=LE_NonIncidence
     LightHue=30
     LightSaturation=150
     LightBrightness=255.000000
     LightRadius=10.000000
     LightPeriod=3
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
