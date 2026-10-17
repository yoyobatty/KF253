class KFShotgunFire extends FlakFire;

var float LastClickTime;

var() Name EmptyAnim;
var() float EmptyAnimRate;

var() float MaxAccuracyBonus,CrouchedAccuracyBonus;  // Lower number = higher bonus .  1.0  =  no bonus  ,   0.1   =  90% bonus.

var() vector KickMomentum;
var() bool bFiringDoesntAffectMovement;

//var() int UpKick;

var()           bool            bRandomPitchFireSound;      // Fire sound randomly change pitch (use this instead of lots of multiple sounds to save memory)
var()           float           RandomPitchAdjustAmt;       // How much to randomly adjust the pitch for firing sounds

// View punch stuff (the punch itself lives in KFPlayerController)
var float   ViewPunchDamping;     // Damping factor for smooth return
var float   ViewPunchSpring;      // Spring force for return
var float   KickScale;            // This shot's share of the weapon's UpKick

var bool    bNoShotLight;         // its muzzle flash throws no light ahead (KFWeapon.ShotLight): the flamethrower's is its pilot flame

// (on the machine of whoever fires, as the flash is shown)
function FlashMuzzleFlash()
{
	Super.FlashMuzzleFlash();
	if ( FlashEmitterClass != None && !bNoShotLight && KFWeapon(Weapon) != None )
		KFWeapon(Weapon).ShotLight();
}

function float GetFireSpeed()
{
	if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
	{
		return KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetFireSpeedMod(Weapon);
	}

	if( KFPawn(Instigator)!=None )
		Return KFPawn(Instigator).GetFireSpeedScale();
	Return 1;
}

event ModeDoFire()
{
	local float Rec;

	if (!AllowFire())
		return;
	
	Spread = Default.Spread;

	Rec = GetFireSpeed();
	FireRate = default.FireRate/Rec;
	FireAnimRate = default.FireAnimRate*Rec;
	ReloadAnimRate = default.ReloadAnimRate*Rec;
	Rec = 1;

	if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
	{
		Spread *= KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.ModifyRecoilSpread(self, Rec);
	}

	if (Weapon.Owner != none && AllowFire() && !bFiringDoesntAffectMovement && Weapon.Owner.Physics != PHYS_Falling )
	{
		if ( KFPawn(Weapon.Owner) != None )
		{
			if (FireRate > 0.25)
				KFPawn(Weapon.Owner).WeaponBrake(0.1);
			else
				KFPawn(Weapon.Owner).WeaponBrake(0.5);
		}
		else if (FireRate > 0.25)
		{
			Weapon.Owner.Velocity.x *= 0.1;
			Weapon.Owner.Velocity.y *= 0.1;
		}
		else
		{
			Weapon.Owner.Velocity.x *= 0.5;
			Weapon.Owner.Velocity.y *= 0.5;
		}
	}
	//log("ModeDoFire called on "$Weapon.GetHumanReadableName());
	Super.ModeDoFire();

    // client
    if (Instigator.IsLocallyControlled())
    {
        HandleRecoil();
    }
}

// Call this on each shot
function HandleRecoil()
{
	KFWeapon(Weapon).ViewKick(KickScale, 1.0, ViewPunchDamping, ViewPunchSpring);
}

// A projectile made inside an enemy is used up on the spot: it never flies, pushes nothing back and
// passes through nothing. So when something shootable is nearer than the muzzle, start just short of it.
function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
	local vector HitLocation, HitNormal;

	if ( Instigator.Trace(HitLocation, HitNormal, Start, Instigator.Location + Instigator.EyePosition(), true) != None )
		Start = HitLocation;
	return Super.SpawnProjectile(Start, Dir);
}

simulated function bool AllowFire()
{
	if( KFWeaponShotgun(Weapon).bIsReloading && KFWeaponShotgun(Weapon).ClipLeft < 2 )
	{
		//log(Instigator.GetHumanReadableName()$" couldn't fire because reload and small clip count on: "$Weapon.GetHumanReadableName());
		return false;
	}
	if(KFPawn(Instigator).SecondaryItem!=none)
		return false;    
	if( KFPawn(Instigator).bThrowingNade )
		return false;


	if( Level.TimeSeconds - LastClickTime>FireRate )
	{
		LastClickTime = Level.TimeSeconds;
	}

	if( KFWeaponShotgun(Weapon).ClipLeft < 1 )
	{
		//log(Instigator.GetHumanReadableName()$" couldn't fire because small clip count "$Weapon.GetHumanReadableName());
		return false;
	}

	return super(WeaponFire).AllowFire();
}

function PlayFiring()
{
	local float RandPitch;

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

    if( bRandomPitchFireSound )
    {
        RandPitch = FRand() * RandomPitchAdjustAmt;

        if( FRand() < 0.5 )
        {
            RandPitch *= -1.0;
        }
    }

    Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,(1.0 + RandPitch),false);
    //Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,Default.FireAnimRate/FireAnimRate,false);
    ClientPlayForceFeedback(FireForce);  // jdf

    FireCount++;
}

function float MaxRange()
{
	return 2000;
}

// Accuracy update based on pawn velocity
simulated function AccuracyUpdate(float Velocity)
{
	if (KFWeapon(Weapon).bSteadyAim)
		return;

	if (Pawn(Weapon.Owner).bIsCrouched)
		Velocity *= CrouchedAccuracyBonus;

	Spread = ((default.Spread * MaxAccuracyBonus) + (Velocity * 10 ));

	ShakeRotMag.x = ((default.ShakeRotMag.x * MaxAccuracyBonus) + (Velocity * 5));     //5
	ShakeRotMag.y = ((default.ShakeRotMag.y * MaxAccuracyBonus) + (Velocity * 5 ));
	ShakeRotMag.z = ((default.ShakeRotMag.z * MaxAccuracyBonus) + (Velocity * 5 ));
}

function ShakeView()
{
	if (!AllowFire())
		return;
	Super.ShakeView();
}

defaultproperties
{
	MaxAccuracyBonus=0.750000
	CrouchedAccuracyBonus=0.600000
	bRandomPitchFireSound=True
	RandomPitchAdjustAmt=0.050000
	bWaitForRelease=True
	ShakeRotMag=(X=50.000000,Y=600.000000,Z=50.000000)
	ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
	ShakeOffsetMag=(X=10.000000,Y=10.000000,Z=10.000000)
	ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
	ProjSpawnOffset=(X=21,Y=5,Z=-6)
	Spread=3000.000000
	ViewPunchDamping=9.000000
	ViewPunchSpring=65.000000
	KickScale=1.000000
}
