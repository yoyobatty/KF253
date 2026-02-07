//=============================================================================
// Frag Fire
//=============================================================================
class FragFire extends RocketFire;  //   AssaultGrenade

const               mNumGrenades = 8;
var float           mCurrentRoll;
var float           mBlend;
var float           mRollInc;
var float           mNextRoll;
var float           mDrumRotationsPerSec;
var float           mRollPerSec;
var AssaultRifle    mGun;
var int             mCurrentSlot;
var int             mNextEmptySlot;

var() float         mScale;
var() float         mScaleMultiplier;

var() float         mSpeedMin;
var() float         mSpeedMax;
var() float         mHoldSpeedMin;
var() float         mHoldSpeedMax;
var() float         mHoldSpeedGainPerSec;
var() float         mHoldClampMax;
var float ClickTime;


var() float         mWaitTime;

function PlayFiring()
{
    if ( Weapon.Mesh != None )
    {
        if ( FireCount > 0 )
        {
            if ( Weapon.HasAnim(FireLoopAnim) )
            {
                Weapon.PlayAnim(FireLoopAnim, FireLoopAnimRate, 0.0);
            }
            else
            {
                Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
            }
        }
        else
        {
            Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
        }
    }
    Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,Default.FireAnimRate/FireAnimRate,false);
    ClientPlayForceFeedback(FireForce);  // jdf

    FireCount++;
}

function PostBeginPlay()
{
    Super.PostBeginPlay();
    mRollInc = -1.f * 65536.f / mNumGrenades;
    mRollPerSec = 65536.f * mDrumRotationsPerSec;
    mGun = AssaultRifle(Weapon);
    mHoldClampMax = (mHoldSpeedMax - mHoldSpeedMin) / mHoldSpeedGainPerSec;
}

// Client-side only: update the first person drum rotation

simulated function bool UpdateRoll(float dt)
{
    return true;
}

simulated function ReturnToIdle()
{

}


<<<<<<< HEAD

=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local Grenade g;
    local vector X, Y, Z;
    local float pawnSpeed;

<<<<<<< HEAD
    g = Weapon.Spawn(class'NadeFixed', instigator,, Start, Dir);
=======
    g = Weapon.Spawn(class'Nade', instigator,, Start, Dir);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
    if (g != None)
    {
        Weapon.GetViewAxes(X,Y,Z);
        pawnSpeed = X dot Instigator.Velocity;

        if ( Bot(Instigator.Controller) != None )
            g.Speed = mHoldSpeedMax;
        else
            g.Speed = mHoldSpeedMin + HoldTime*mHoldSpeedGainPerSec;
        g.Speed = FClamp(g.Speed, mHoldSpeedMin, mHoldSpeedMax);
        g.Speed = pawnSpeed + g.Speed;
        g.Velocity = g.Speed * Vector(Dir);

        g.Damage *= DamageAtten;
    }
    return g;
}


<<<<<<< HEAD

function InitEffects()
{


=======
function InitEffects()
{
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

function DoFireEffect()
{
    local Vector StartProj, StartTrace, X,Y,Z;
    local Rotator Aim;
    local Vector HitLocation, HitNormal;
    local Actor Other;
<<<<<<< HEAD

=======
	local int Hand;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

    Instigator.MakeNoise(1.0);
    Weapon.GetViewAxes(X,Y,Z);

    StartTrace = Instigator.Location + Instigator.EyePosition();// + X*Instigator.CollisionRadius;
    StartProj = StartTrace + X*ProjSpawnOffset.X;

<<<<<<< HEAD
    if ( !Weapon.WeaponCentered() )
        StartProj = StartProj + Weapon.Hand * Y*ProjSpawnOffset.Y + Z*ProjSpawnOffset.Z;
=======
	if( PlayerController(Instigator.Controller)!=None )
	{ // We must do this as server dosen't get a chance to set weapon handedness.
		Hand = int(PlayerController(Instigator.Controller).Handedness);
		if( Hand==-1 || Hand==1 )
			StartProj = StartProj + Hand * Y*ProjSpawnOffset.Y + Z*ProjSpawnOffset.Z;
	}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

    // check if projectile would spawn through a wall and adjust start location accordingly
    Other = Weapon.Trace(HitLocation, HitNormal, StartProj, StartTrace, false);
    if (Other != None)
    {
        StartProj = HitLocation;
    }

    Aim = AdjustAim(StartProj, AimError);
<<<<<<< HEAD
    
    //log(StartProj);
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

    SpawnProjectile(StartProj, Aim);
     

}

event ModeDoFire()
{
    if (!AllowFire())
        return;

    if (MaxHoldTime > 0.0)
        HoldTime = FMin(HoldTime, MaxHoldTime);

    // server
    if (Weapon.Role == ROLE_Authority)
    {
        Weapon.ConsumeAmmo(ThisModeNum, Load);
        DoFireEffect();
        HoldTime = 0;   // if bot decides to stop firing, HoldTime must be reset first
        if ( (Instigator == None) || (Instigator.Controller == None) )
            return;

        if ( AIController(Instigator.Controller) != None )
            AIController(Instigator.Controller).WeaponFireAgain(BotRefireRate, true);

        Instigator.DeactivateSpawnProtection();
    }

    // client
    if (Instigator.IsLocallyControlled())
    {
        ShakeView();
        PlayFiring();
        FlashMuzzleFlash();
        StartMuzzleSmoke();
    }
    else // server
    {
        ServerPlayFiring();
    }

    Weapon.IncrementFlashCount(ThisModeNum);

    // set the next firing time. must be careful here so client and server do not get out of sync
    if (bFireOnRelease)
    {
        if (bIsFiring)
            NextFireTime += MaxHoldTime + FireRate;
        else
            NextFireTime = Level.TimeSeconds + FireRate;
    }
    else
    {
        NextFireTime += FireRate;
        NextFireTime = FMax(NextFireTime, Level.TimeSeconds);
    }

    Load = AmmoPerFire;
    HoldTime = 0;

    if (Instigator.PendingWeapon != Weapon && Instigator.PendingWeapon != None)
    {
        bIsFiring = false;
        Weapon.PutDown();
    }
}

<<<<<<< HEAD



=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
state Wait
{
    function BeginState()
    {
        SetTimer(mWaitTime, false);
    }

    function Timer()
    {
        GotoState('LoadNext'); //goto idle if out of ammo?
    }
}

state LoadNext
{
    function BeginState()
    {
        if (Level.NetMode != NM_Client)
            Weapon.PlaySound(ReloadSound,SLOT_None,,,512.0,,false);
        ClientPlayForceFeedback(ReloadForce);
    }

    function ModeTick(float dt)
    {
        if ( Weapon.Mesh != Weapon.OldMesh )
            GotoState('Idle');
        else if (UpdateRoll(dt))
            GotoState('Idle');
    }
}

function PlayFireEnd()
{
    if(weapon.ammoAmount(0) <= 0)
        weapon.DoAutoSwitch() ;
}

defaultproperties
{
<<<<<<< HEAD
	mBlend=1.000000
	mDrumRotationsPerSec=0.400000
	mScale=1.000000
	mScaleMultiplier=0.900000
	mSpeedMin=150.000000
	mSpeedMax=1000.000000
	mHoldSpeedMin=850.000000
	mHoldSpeedMax=1600.000000
	mHoldSpeedGainPerSec=750.000000
	mWaitTime=0.500000
	ProjSpawnOffset=(Y=-20.000000,Z=-7.000000)
	bFireOnRelease=True
	bWaitForRelease=True
	PreFireTime=0.500000
	FireLoopAnim="LoopThrow"
	FireSound=Sound'KFWeaponSound.axe-swish'
	FireRate=1.500000
	AmmoClass=Class'KFMod.FragAmmo'
	ShakeOffsetMag=(X=25.000000,Y=25.000000,Z=25.000000)
	ShakeOffsetRate=(X=0.000000)
	ProjectileClass=Class'KFMod.NadeFixed'
	BotRefireRate=2.500000
	FlashEmitterClass=None
	SpreadStyle=SS_Random
=======
     mBlend=1.000000
     mDrumRotationsPerSec=0.400000
     mScale=1.000000
     mScaleMultiplier=0.900000
     mSpeedMin=150.000000
     mSpeedMax=1000.000000
     mHoldSpeedMin=850.000000
     mHoldSpeedMax=1600.000000
     mHoldSpeedGainPerSec=750.000000
     mWaitTime=0.500000
     ProjSpawnOffset=(Y=-20.000000,Z=-7.000000)
     bFireOnRelease=True
     bWaitForRelease=True
     PreFireTime=0.500000
     FireLoopAnim="LoopThrow"
     FireSound=Sound'KFWeaponSound.axe-swish'
     FireRate=1.500000
     AmmoClass=Class'KFMod.FragAmmo'
     ShakeOffsetMag=(X=25.000000,Y=25.000000,Z=25.000000)
     ShakeOffsetRate=(X=0.000000)
     ProjectileClass=Class'KFMod.Nade'
     BotRefireRate=0.500000
     FlashEmitterClass=None
     SpreadStyle=SS_Random
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
