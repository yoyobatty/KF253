//=============================================================================
// Winchester Fire
//=============================================================================
class WinchesterFire extends KFFire;

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
}

function AimingSpeed()
{
	FireAnim = FireAimingAnim;
}

function NormalSpeed()
{
	FireAnim = default.FireAnim;
}

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
}
