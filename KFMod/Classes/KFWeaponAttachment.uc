// Tracer Fire

class KFWeaponAttachment extends xWeaponAttachment;

var class<Emitter>      mMuzFlashClass;
var Emitter             mMuzFlash3rd;

var class<Emitter>      mTracerClass;
var() editinline Emitter mTracer;
var float               mTracerInterval;
var() float             mTracerIntervalPrimary;
var() float             mTracerIntervalSecondary;
var() float             mTracerPullback;
var() float             mTracerMinDistance;
var() float             mTracerSpeed;
var float               mLastTracerTime;
var byte                OldSpawnHitCount;

var float               mCurrentRoll;
var float               mRollInc;
var float               mRollUpdateTime;

var class<xEmitter>     mShellCaseEmitterClass;
var xEmitter            mShellCaseEmitter;
var() vector            mShellEmitterOffset;

var vector  mOldHitLocation;

var () class<KFHitEffect> HitEffectType;
                                                        
var() array<name> TPAnims,TPAnimsB; // Custom third person animations.
var() name WeaponIdleMovementAnim,SecondaryWeaponIdleMovementAnim; // Custom holding weapon animation.
var Pawn LastInstig;

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
                  	if (FiringMode == 0)
                          KFPawn(Instigator).UpdateClientAnim(WeaponIdleMovementAnim);

                }

	}
}
simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	LastInstig = Instigator;
	if( KFPawn(Instigator)!=None )
	{
		if (FiringMode == 0)
                          KFPawn(Instigator).UpdateClientAnim(WeaponIdleMovementAnim);
	}
	bNetNotify = True;
}


simulated function ChangeIdleToSecondary()
{
 LastInstig = Instigator;
	if( KFPawn(Instigator)!=None )
	{
         KFPawn(Instigator).UpdateClientAnim(SecondaryWeaponIdleMovementAnim);
         bNetNotify = True;
        }        

}

simulated function UpdateTracer()
{
	local vector SpawnLoc, SpawnDir, SpawnVel;
	local float hitDist;

	if (Level.NetMode == NM_DedicatedServer)
		return;

	if (mTracer == None)
		mTracer = Spawn(mTracerClass);

	if (mTracer != None && Level.TimeSeconds > mLastTracerTime + mTracerInterval)
	{
		SpawnLoc = GetTracerStart();
		mTracer.SetLocation(SpawnLoc);

		hitDist = VSize(mHitLocation - SpawnLoc) - mTracerPullback;

		// If we have a hit but the hit location has not changed
		if(mHitLocation == mOldHitLocation)
			SpawnDir = vector( Instigator.GetViewRotation() );
		else SpawnDir = Normal(mHitLocation - SpawnLoc);

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
		mLastTracerTime = Level.TimeSeconds;
	}
	mOldHitLocation = mHitLocation;
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

	// 3rd person
	if ( mMuzFlash3rd != None )
		return mMuzFlash3rd.Location;
	else return Location;
}

function UpdateHit(Actor HitActor, vector HitLocation, vector HitNormal)
{
	NetUpdateTime = Level.TimeSeconds - 1;
	SpawnHitCount++;
	mHitLocation = HitLocation;
	mHitActor = HitActor;
	mHitNormal = HitNormal;
}

simulated event ThirdPersonEffects()
{
	local PlayerController PC;

	if ( (Level.NetMode == NM_DedicatedServer) || (Instigator == None) )
		return;



  
  	if ( FlashCount>0 )
	{
		if( KFPawn(Instigator)!=None )
		{
			if (FiringMode == 0)
				KFPawn(Instigator).StartFiringX(bHeavy,bRapidFire,GetThirdPersonAnim());
			else KFPawn(Instigator).StartFiringX(bHeavy,bAltRapidFire,GetThirdPersonAnim());
		}
		PC = Level.GetLocalPlayerController();
		if ( OldSpawnHitCount != SpawnHitCount )
		{
			OldSpawnHitCount = SpawnHitCount;
			GetHitInfo();
			PC = Level.GetLocalPlayerController();
			if ( (Instigator.Controller == PC) || (VSize(PC.ViewTarget.Location - mHitLocation) < 2000) )
			{
				if ( FiringMode == 0 )
					Spawn(HitEffectType,,, mHitLocation, rotator(mHitLocation - (Instigator.Location + Instigator.EyePosition())));
				else
					Spawn(HitEffectType,,, mHitLocation, rotator(mHitLocation - (Instigator.Location + Instigator.EyePosition())));
				CheckForSplash();
			}
		}

		if ( (Level.TimeSeconds - LastRenderTime > 0.2) && (Instigator.Controller != PC) )
			return;

		WeaponLight();

		if (FiringMode == 0)
		{
			mTracerInterval = mTracerIntervalPrimary;
			mRollInc = 65536.f*3.f;
		}
		else
		{
			mTracerInterval = mTracerIntervalSecondary;
			mRollInc = 65536.f;
		}

		if ( Level.bDropDetail || Level.DetailMode == DM_Low )
			mTracerInterval *= 2.0;

		UpdateTracer();

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
}
