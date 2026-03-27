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

var rotator ViewPunchOffset;      // Current punch offset being applied
var rotator ViewPunchVelocity;    // Velocity at which the punch returns to zero
var rotator LastPunchOffset;	  // Last offset applied to the view (for smooth return)
var float   ViewPunchDamping;     // Damping factor for smooth return
var float   ViewPunchSpring;      // Spring force for return

function float GetFireSpeed()
{
	if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
	{
		return KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetFireSpeedMod(Weapon);
	}

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
		if (FireRate > 0.25)
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

// Call this every tick
simulated function ModeTick(float DeltaTime)
{
    local PlayerController PC;

    Super.ModeTick(DeltaTime);

    PC = PlayerController(Instigator.Controller);
    if (PC == None)
        return;

    // HL2-style view punch return (spring-damper)
    // Calculate spring force toward zero
    ViewPunchVelocity.Pitch -= ViewPunchOffset.Pitch * ViewPunchSpring * DeltaTime;
    ViewPunchVelocity.Yaw   -= ViewPunchOffset.Yaw   * ViewPunchSpring * DeltaTime;
    // Apply damping
    ViewPunchVelocity.Pitch -= ViewPunchVelocity.Pitch * ViewPunchDamping * DeltaTime;
    ViewPunchVelocity.Yaw   -= ViewPunchVelocity.Yaw   * ViewPunchDamping * DeltaTime;
    // Integrate velocity
    ViewPunchOffset.Pitch += ViewPunchVelocity.Pitch * DeltaTime;
    ViewPunchOffset.Yaw   += ViewPunchVelocity.Yaw   * DeltaTime;

	PC.SetRotation(PC.Rotation - LastPunchOffset + ViewPunchOffset);
    LastPunchOffset = ViewPunchOffset;

    // Snap to zero if all axes are very close, to prevent endless drift
    if (Abs(ViewPunchOffset.Pitch) < 1.0 && Abs(ViewPunchVelocity.Pitch) < 1.0 &&
        Abs(ViewPunchOffset.Yaw) < 1.0 && Abs(ViewPunchVelocity.Yaw) < 1.0)
    {
        ViewPunchOffset = rot(0,0,0);
        ViewPunchVelocity = rot(0,0,0);
        LastPunchOffset = rot(0,0,0);
    }
}

// Call this on each shot
function HandleRecoil()
{
    local float PunchPitch, PunchYaw;
	local PlayerController PC;

	PC = PlayerController(Instigator.Controller);
    if (PC == None)// || PC.bBehindView)
        return;

    // HL2: Each shot instantly punches the view by a small, random amount
    PunchPitch = Clamp(0.5*KFWeapon(Weapon).UpKick * (0.5 + FRand()*0.5), 80, 5000); 
    PunchYaw   = (FRand() - 0.5) * 100; // -100 to +100

    // Add punch to offset and velocity (velocity for snappier response)
    ViewPunchOffset.Pitch += PunchPitch;
    ViewPunchOffset.Yaw   += PunchYaw;
    ViewPunchVelocity.Pitch += PunchPitch * 10.0;
    ViewPunchVelocity.Yaw   += PunchYaw * 10.0;
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
	ViewPunchDamping=6.000000
	ViewPunchSpring=75.000000
}
