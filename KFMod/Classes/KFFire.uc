class KFFire extends InstantFire
    abstract;

var float LastClickTime;
var float LastFireTime;

var() Name EmptyAnim;
var() float EmptyAnimRate;
var() Name EmptyFireAnim;
var() float EmptyFireAnimRate;
var bool Empty;
var () bool bFiringDoesntAffectMovement;

<<<<<<< HEAD
var int UpKick;
=======
var()           bool            bRandomPitchFireSound;      // Fire sound randomly change pitch (use this instead of lots of multiple sounds to save memory)
var()           float           RandomPitchAdjustAmt;       // How much to randomly adjust the pitch for firing sounds

var() int MaxFireBurst; // Maximum number of shots in a burst, 0 for unlimited

//var int UpKick;

var rotator ViewPunchOffset;      // Current punch offset being applied
var rotator ViewPunchVelocity;    // Velocity at which the punch returns to zero
var rotator LastPunchOffset;	  // Last offset applied to the view (for smooth return)
var() float   ViewPunchDamping;     // Damping factor for smooth return
var() float   ViewPunchSpring;      // Spring force for return
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

function float GetFireSpeed()
{
	if( KFPawn(Instigator)!=None )
		Return KFPawn(Instigator).GetVeteran().Static.GetFireSpeedMod(Weapon);
	Return 1;
}
<<<<<<< HEAD
=======

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated function bool AllowFire()
{
	if(KFWeapon(Weapon).bIsReloading)
		return false;
<<<<<<< HEAD
=======
	if(FireCount >= MaxFireBurst && MaxFireBurst > 0)
		return false;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	if(KFPawn(Instigator).SecondaryItem!=none)
		return false;
	if(KFPawn(Instigator).bThrowingNade)
		return false;

	if(KFWeapon(Weapon).ClipLeft < 1)
	{
		if(Level.TimeSeconds - LastClickTime > FireRate)
		{
<<<<<<< HEAD
			Weapon.PlayOwnedSound(NoAmmoSound, SLOT_Interact, TransientSoundVolume,,,, false);
			LastClickTime = Level.TimeSeconds;
=======
			LastClickTime = Level.TimeSeconds;
			Weapon.PlayOwnedSound(NoAmmoSound, SLOT_Interact, TransientSoundVolume,,,, false);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
			if(Weapon.HasAnim(EmptyAnim))
				weapon.PlayAnim(EmptyAnim, EmptyAnimRate, 0.0);
		}
		if( AIController(Instigator.Controller)!=None )
			KFWeapon(Weapon).ReloadMeNow();
		return false;
	}
<<<<<<< HEAD
	LastClickTime = Level.TimeSeconds;
	return Super.AllowFire();
}

=======

	return Super.AllowFire();
}

function StopFiring()
{
    FireCount = 0;
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

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
function StartBerserk();

function StopBerserk();

simulated function InitEffects()
{
    Super.InitEffects();
<<<<<<< HEAD
=======
	if ( (Level.NetMode == NM_DedicatedServer) || (AIController(Instigator.Controller) != None) )
		return;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
    if ( FlashEmitter != None )
        Weapon.AttachToBone(FlashEmitter, KFWeapon(Weapon).FlashBoneName);
}

function FlashMuzzleFlash()
{
    local rotator r;
    r.Roll = Rand(65536);


    Weapon.SetBoneRotation('Bone_Flash', r, 0, 1.f);


   //log(r);

    Super.FlashMuzzleFlash();
}

event ModeDoFire()
{
<<<<<<< HEAD
	local vector X,Y,Z;
	local rotator ViewRotation;
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	local float Rec;

	if (!AllowFire())
		return;

	if( Instigator==None || Instigator.Controller==none )
<<<<<<< HEAD
		return; 

	if ( Level.TimeSeconds - LastFireTime > 0.5 )
		Spread = Default.Spread;
	else Spread = FMin(Spread+0.02,0.12);
=======
		return;

	if ( Level.TimeSeconds - LastFireTime > 0.5 )
		Spread = Default.Spread;
	else Spread = FMin(Spread+0.01,0.12);

	// Small spread bonus for firing crouched
    if( Instigator != none && Instigator.bIsCrouched )
    {
        Spread *= 0.85;
		KFWeapon(Weapon).UpKick *= 0.85;
    }

	// Spread bonus for firing aiming
    if( KFWeapon(Weapon).bAimingRifle )
    {
        Spread *= 0.5;
		KFWeapon(Weapon).UpKick *= 0.5;
    }

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	Rec = GetFireSpeed();
	FireRate = default.FireRate/Rec;
	FireAnimRate = default.FireAnimRate*Rec;
	ReloadAnimRate = default.ReloadAnimRate*Rec;
	Rec = 1;
<<<<<<< HEAD
	if( KFPawn(Instigator)!=None )
=======

	if( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		Spread*=KFPawn(Instigator).GetVeteran().Static.ModifyRecoilSpread(Self,Rec);

	LastFireTime = Level.TimeSeconds;

<<<<<<< HEAD
	if (Weapon.Owner != none && AllowFire() && !bFiringDoesntAffectMovement)
=======
	if (Weapon.Owner != none && AllowFire() && !bFiringDoesntAffectMovement && Weapon.Owner.Physics != PHYS_Falling )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
<<<<<<< HEAD
		} 
	}
    
	// UpKick
	if( PlayerController(Instigator.Controller)!=None && (Weapon.GetFireMode(0).bIsFiring || (DeagleAltFire(Weapon.GetFireMode(1))!=none
	 && DeagleAltFire(Weapon.GetFireMode(1)).bIsFiring)) && !PlayerController(Instigator.Controller).bBehindView )
	{
		UpKick = KFWeapon(Weapon).UpKick + (VSize(Weapon.Owner.Velocity)* 3) + (Instigator.HealthMax / Instigator.Health * 5);

		GetAxes(Instigator.Rotation,X,Y,Z);
		ViewRotation = Instigator.GetViewRotation();
		ViewRotation.Pitch += UpKick*Rec;
		// Update rotation.
		Instigator.Controller.SetRotation(ViewRotation);
		PlayerController(Instigator.Controller).UpdateRotation(1, 1);
	}  
	Super.ModeDoFire();
}

function float MaxRange()
{
	if (Instigator.Region.Zone.bDistanceFog)
		TraceRange = FClamp(Instigator.Region.Zone.DistanceFogEnd, 8000, default.TraceRange);
	else TraceRange = default.TraceRange;
	return TraceRange;
=======
		}
	}
	//log("ModeDoFire called on "$Weapon.GetHumanReadableName());
	Super.ModeDoFire();

    // Only start a new recoil if not already recoiling
    if (Instigator.IsLocallyControlled())
    {
        HandleRecoil();
        
    }
}

simulated function ModeTick(float DeltaTime)
{
    local PlayerController PC;

    Super.ModeTick(DeltaTime);
	PC = PlayerController(Instigator.Controller);
    if (PC == None)
        return;

    ViewPunchVelocity.Pitch -= ViewPunchOffset.Pitch * ViewPunchSpring * DeltaTime;
    ViewPunchVelocity.Yaw   -= ViewPunchOffset.Yaw   * ViewPunchSpring * DeltaTime;

    ViewPunchVelocity.Pitch -= ViewPunchVelocity.Pitch * ViewPunchDamping * DeltaTime;
    ViewPunchVelocity.Yaw   -= ViewPunchVelocity.Yaw   * ViewPunchDamping * DeltaTime;

    ViewPunchOffset.Pitch += ViewPunchVelocity.Pitch * DeltaTime;
    ViewPunchOffset.Yaw   += ViewPunchVelocity.Yaw   * DeltaTime;

	PC.SetRotation(PC.Rotation - LastPunchOffset + ViewPunchOffset);
    LastPunchOffset = ViewPunchOffset;


    if (Abs(ViewPunchOffset.Pitch) < 1.0 && Abs(ViewPunchVelocity.Pitch) < 1.0 &&
        Abs(ViewPunchOffset.Yaw) < 1.0 && Abs(ViewPunchVelocity.Yaw) < 1.0)
    {
        ViewPunchOffset = rot(0,0,0);
        ViewPunchVelocity = rot(0,0,0);
        LastPunchOffset = rot(0,0,0);
    }
}
function HandleRecoil()
{
    local float PunchPitch, PunchYaw;
	local float DurationFactor;
	local PlayerController PC;

	PC = PlayerController(Instigator.Controller);
    if (PC == None)// || PC.bBehindView)
        return;

	ViewPunchReset(5000.f);
    DurationFactor = FClamp(FireCount / 6.f, 0.0, 2.0);

    // Scale between 1.0x (tap fire) and 2.0x (full auto after RampTime)
    DurationFactor = 1.0 + DurationFactor;  // 1.0 -> 2.0

    PunchPitch = Clamp(0.5*KFWeapon(Weapon).UpKick * (0.5 + FRand()*0.5), 80, 5000); 
    PunchYaw   = (FRand() - 0.5) * 100; 

	PunchPitch *= DurationFactor;
    PunchYaw   *= DurationFactor;

    // Add punch to offset and velocity 
    ViewPunchOffset.Pitch += PunchPitch;
    ViewPunchOffset.Yaw   += PunchYaw;
    ViewPunchVelocity.Pitch += PunchPitch * 10.0;
    ViewPunchVelocity.Yaw   += PunchYaw * 10.0;
}

function ViewPunchReset( float tolerance )
{
	local float check;
    local float PitchVal, YawVal;

	if ( tolerance != 0 )
	{
		tolerance *= tolerance;	// square
        // Compute squared "size" of punch using pitch + yaw components
        PitchVal = ViewPunchOffset.Pitch  + ViewPunchVelocity.Pitch;
        YawVal   = ViewPunchOffset.Yaw    + ViewPunchVelocity.Yaw;

     	check = PitchVal * PitchVal + YawVal * YawVal;
		if ( check > tolerance )
			return;
	}
	ViewPunchOffset = rot(0,0,0);
	ViewPunchVelocity = rot(0,0,0);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

function DoTrace(Vector Start, Rotator Dir)
{
<<<<<<< HEAD
	local Vector X,Y,Z, End, HitLocation, HitNormal, ArcEnd;
	local Actor Other;

	MaxRange();

	Weapon.GetViewAxes(X, Y, Z);
	if ( Weapon.WeaponCentered() )
		ArcEnd = (Instigator.Location + Weapon.EffectOffset.X * X + 1.5 * Weapon.EffectOffset.Z * Z);
	else ArcEnd = (Instigator.Location + Instigator.CalcDrawOffset(Weapon) + Weapon.EffectOffset.X * X + Weapon.Hand * Weapon.EffectOffset.Y * Y +
		 Weapon.EffectOffset.Z * Z);

	X = Vector(Dir);
	End = Start + TraceRange * X;
	Other = Weapon.Trace(HitLocation, HitNormal, End, Start, true);

	if ( Other != None && (Other != Instigator) )
	{
		if ( !Other.bWorldGeometry )
			Other.TakeDamage(DamageMax, Instigator, HitLocation, Momentum*X, DamageType);
		else HitLocation = HitLocation + 2.0 * HitNormal;
=======
	local Vector X, End, HitLocation, HitNormal;
	local Actor Other;
	local KFWeaponAttachment WeapAttach;

	MaxRange();
	//log("Weapon fired max range: " $MaxRange());
	X = Normal(Vector(Dir));
	End = Start + TraceRange * X;
	Other = Instigator.Trace(HitLocation, HitNormal, End, Start, true);
	if ( Other != None && Other != Instigator && Other.Base != Instigator )
	{
		WeapAttach = KFWeaponAttachment(Weapon.ThirdPersonActor);
		if ( !Other.bWorldGeometry )
		{
			// Update hit effect except for pawns
			if ( !Other.IsA('Pawn') && !Other.IsA('HitScanBlockingVolume') && !Other.IsA('ExtendedZCollision') )
			{
				if( WeapAttach != None )
                    WeapAttach.UpdateHit(Other, HitLocation, HitNormal);
			}
			Other.TakeDamage(Lerp(FRand(), DamageMin, DamageMax), Instigator, HitLocation, Momentum*X, DamageType);
		}
		else
		{
			HitLocation = HitLocation + 2.0 * HitNormal;
			if ( WeapAttach != None )
				WeapAttach.UpdateHit(Other,HitLocation,HitNormal);
		}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	}
	else
	{
		HitLocation = End;
		HitNormal = Normal(Start - End);
	}
<<<<<<< HEAD
	if( KFWeaponAttachment(Weapon.ThirdPersonActor)!=None )
		KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
	else if ( (HitNormal != Vect(0,0,0)) && (HitScanBlockingVolume(Other) == None) )
		Weapon.Spawn(class'KFHitEffect',,, HitLocation, rotator(-1 * HitNormal));
}

// Accuracy update based on pawn velocity

simulated function AccuracyUpdate(float Velocity)
{
  if (KFWeapon(Weapon).bSteadyAim)
   return;

 if (Pawn(Weapon.Owner).bIsCrouched)
  Velocity *= 0.6;

  AimError = ((default.AimError * 0.75) + (Velocity * 4 ));   //2
  Spread = ((default.Spread * 0.75) + (Velocity * 0.0010 ));   //.0005



=======

}

// Accuracy update based on pawn velocity
simulated function AccuracyUpdate(float Velocity)
{
	if (KFWeapon(Weapon).bSteadyAim)
		return;

	if (Pawn(Weapon.Owner).bIsCrouched)
		Velocity *= 0.6;

	AimError = ((default.AimError * 0.75) + (Velocity * 2 ));   //2
	Spread = ((default.Spread * 0.75) + (Velocity * 0.0005 ));   //.0005
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

defaultproperties
{
	EmptyAnim="Empty"
	EmptyAnimRate=1.000000
	EmptyFireAnim="EmptyFire"
	EmptyFireAnimRate=1.000000
<<<<<<< HEAD
=======
	bRandomPitchFireSound=True
	RandomPitchAdjustAmt=0.050000
	ViewPunchDamping=6.000000
	ViewPunchSpring=75.000000
	MaxFireBurst=0
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
