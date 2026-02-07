//=============================================================================
// Winchester Fire
//=============================================================================
class WinchesterFire extends KFFire;

<<<<<<< HEAD
//var float HeadShotDamageMult;
//var class<DamageType> DamageTypeHeadShot;

var float ClickTime;

var float AimedAmount;

var name FireAimingAnim;



function Recoil()
{
    local Rotator NewRotation;
    local float NewPitch, NewYaw;

    if ( (Instigator != None) && Instigator.IsFirstPerson()){
    NewPitch = int(Frand()*300); NewYaw = int(Frand()*550);
    if (Frand() > 0.5) NewYaw *= -1;
    if (Frand() > 0.5) NewPitch *= -1;
    NewRotation = Instigator.GetViewRotation();
    NewRotation.Pitch += NewPitch;
    NewRotation.Yaw += NewYaw;
    Instigator.SetViewRotation(NewRotation);}
=======
var name FireAimingAnim;

simulated function bool AllowFire()
{
	if( KFWeapon(Weapon).bIsReloading && KFWeapon(Weapon).ClipLeft < 2 )
		return false;
	if(KFPawn(Instigator).SecondaryItem!=none)
		return false;    
	if( KFPawn(Instigator).bThrowingNade )
		return false;

	if( Level.TimeSeconds - LastClickTime>FireRate )
	{
		LastClickTime = Level.TimeSeconds;
	}

	if( KFWeapon(Weapon).ClipLeft < 1 )
	{
		return false;
	}

	return super(WeaponFire).AllowFire();
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

function AimingSpeed()
{
	FireAnim = FireAimingAnim;
}

function NormalSpeed()
{
	FireAnim = default.FireAnim;
}

<<<<<<< HEAD
event ModeDoFire()
{
	local vector X,Y,Z;
	local rotator ViewRotation;

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
		else NextFireTime = Level.TimeSeconds + FireRate;
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
    
	if (Weapon.Owner != none && AllowFire())
	{
		if (FireRate > 0.25)
			Weapon.Owner.Velocity *= 0.1;
		else Weapon.Owner.Velocity *= 0.5;
	}
    
	// UpKick
	if( Weapon.GetFireMode(0).bIsFiring && PlayerController(Instigator.Controller)!=None && !PlayerController(Instigator.Controller).bBehindView )
	{
		UpKick = KFWeapon(Weapon).UpKick + (3 * VSize(Instigator.Velocity));

		GetAxes(Weapon.Owner.Rotation,X,Y,Z);
		ViewRotation = Instigator.Controller.GetViewRotation();
		ViewRotation.Pitch += UpKick;

		// Update rotation.
		Instigator.Controller.SetRotation(ViewRotation);
	}
}

defaultproperties
{
	FireAimingAnim="AimFire"
	UpKick=700
	DamageType=Class'KFMod.DamTypeWinchester'
	DamageMin=110
	DamageMax=140
	Momentum=18000.000000
	bPawnRapidFireAnim=True
	bModeExclusive=False
	bAttachSmokeEmitter=True
	TransientSoundVolume=100.000000
	FireLoopAnim=
	FireEndAnim=
	FireSound=Sound'KFWeaponSound.WinchesterFire'
	FireForce="ShockRifleFire"
	FireRate=1.100000
	AmmoClass=Class'KFMod.WinchesterAmmo'
	AmmoPerFire=1
	ShakeRotMag=(X=100.000000,Y=500.000000,Z=100.000000)
	ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
	ShakeRotTime=2.000000
	ShakeOffsetMag=(X=12.000000,Y=12.000000,Z=12.000000)
	ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
	ShakeOffsetTime=2.000000
	BotRefireRate=0.650000
	FlashEmitterClass=Class'KFMod.ShotgunMuzzFlash'
	aimerror=0.000000
=======
function DoTrace(Vector Start, Rotator Dir)
{
	local Vector X,Y,Z, End, HitLocation, HitNormal, ArcEnd;
	local Actor Other;
	local byte HitCount,HCounter;
	local float HitDamage;
	local KFPawn HitPawn;
	local array<Actor>	IgnoreActors;
	local Actor DamageActor;
	local int i;

	MaxRange();

	Weapon.GetViewAxes(X, Y, Z);
	if ( Weapon.WeaponCentered() )
	{
		ArcEnd = (Instigator.Location + Weapon.EffectOffset.X * X + 1.5 * Weapon.EffectOffset.Z * Z);
	}
	else
    {
        ArcEnd = (Instigator.Location + Instigator.CalcDrawOffset(Weapon) + Weapon.EffectOffset.X * X +
		 Weapon.Hand * Weapon.EffectOffset.Y * Y + Weapon.EffectOffset.Z * Z);
    }

	X = Vector(Dir);
	End = Start + TraceRange * X;
	HitDamage = DamageMax;
	While( (HitCount++)<10 )
	{
        DamageActor = none;

		Other = Instigator.Trace(HitLocation, HitNormal, End, Start, True);
		if( Other==None )
		{
			Break;
		}
		else if( Other==Instigator || Other.Base == Instigator )
		{
			IgnoreActors[IgnoreActors.Length] = Other;
			Other.SetCollision(false);
			Start = HitLocation;
			Continue;
		}

		if( ExtendedZCollision(Other)!=None && Other.Owner!=None )
		{
            IgnoreActors[IgnoreActors.Length] = Other;
            IgnoreActors[IgnoreActors.Length] = Other.Owner;
			Other.SetCollision(false);
			Other.Owner.SetCollision(false);
			DamageActor = Pawn(Other.Owner);
		}

		if ( !Other.bWorldGeometry && Other!=Level )
		{
			HitPawn = KFPawn(Other);

	    	if ( HitPawn != none )
	    	{
                 // Hit detection debugging
				 /*log("PreLaunchTrace hit "$HitPawn.PlayerReplicationInfo.PlayerName);
				 HitPawn.HitStart = Start;
				 HitPawn.HitEnd = End;*/
                 if(!HitPawn.bDeleteMe)
				 	HitPawn.TakeDamage(int(HitDamage), Instigator, HitLocation, Momentum*X,DamageType);

                 // Hit detection debugging
				 /*if( Level.NetMode == NM_Standalone)
				 	  HitPawn.DrawBoneLocation();*/

                IgnoreActors[IgnoreActors.Length] = Other;
    			Other.SetCollision(false);
    			DamageActor = Other;
			}
            else
            {
    			if( KFMonster(Other)!=None )
    			{
                    IgnoreActors[IgnoreActors.Length] = Other;
        			Other.SetCollision(false);
        			DamageActor = Other;
    			}
    			else if( DamageActor == none )
    			{
                    DamageActor = Other;
    			}
    			Other.TakeDamage(int(HitDamage), Instigator, HitLocation, Momentum*X, DamageType);
			}
			if( (HCounter++)>=4 || Pawn(DamageActor)==None )
			{
				Break;
			}
			HitDamage/=2;
			Start = HitLocation;
		}
		else if ( HitScanBlockingVolume(Other)==None )
		{
			if( KFWeaponAttachment(Weapon.ThirdPersonActor)!=None )
		      KFWeaponAttachment(Weapon.ThirdPersonActor).UpdateHit(Other,HitLocation,HitNormal);
			Break;
		}
	}

    // Turn the collision back on for any actors we turned it off
	if ( IgnoreActors.Length > 0 )
	{
		for (i=0; i<IgnoreActors.Length; i++)
		{
			if (IgnoreActors[i] != None)
				IgnoreActors[i].SetCollision(true);
		}
	}
}


defaultproperties
{
     FireAimingAnim="AimFire"
     DamageType=Class'KFMod.DamTypeWinchester'
     DamageMin=300
     DamageMax=350
     Momentum=18000.000000
     bPawnRapidFireAnim=True
     bWaitForRelease=True
     bModeExclusive=False
     bAttachSmokeEmitter=True
     TransientSoundVolume=100.000000
     FireLoopAnim=
     FireEndAnim=
     FireSound=Sound'KFWeaponSound.WinchesterFire'
     FireForce="ShockRifleFire"
     FireRate=1.100000
     AmmoClass=Class'KFMod.WinchesterAmmo'
     AmmoPerFire=1
     ShakeRotMag=(X=100.000000,Y=500.000000,Z=100.000000)
     ShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
     ShakeRotTime=2.000000
     ShakeOffsetMag=(X=12.000000,Y=12.000000,Z=12.000000)
     ShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
     ShakeOffsetTime=2.000000
     BotRefireRate=0.650000
     FlashEmitterClass=Class'KFMod.ShotgunMuzzFlash'
     aimerror=0.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
