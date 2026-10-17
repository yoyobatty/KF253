//ShoveFire as part of the GoodKarma package
//Build 5 Beta 4.5 Release
//By: Jonathan Zepp
//The midified primary fire for the shovegun

class ShoveFire extends ShieldFire ;

var NetKActor AutoHitNetKActor ;

function DoFireEffect()
{
    local Vector HitLocation, HitNormal, StartTrace, EndTrace, X,Y,Z;
    local Rotator Aim;
    local Actor Other;
    local float Scale, Damage, Force;

    Instigator.MakeNoise(1.0);
    Weapon.GetViewAxes(X,Y,Z);
    bAutoRelease = false;

    if ( (AutoHitPawn != None) && (Level.TimeSeconds - AutoHitTime < 0.15))
    {
        Other = AutoHitPawn;
        HitLocation = Other.Location;
        AutoHitPawn = None;
    }
    else if ( (AutoHitNetKActor != None) && (Level.TimeSeconds - AutoHitTime < 0.15))
    {
        Other = AutoHitNetKActor;
        HitLocation = Other.Location;
        AutoHitPawn = None;
    }
    else
    {
        StartTrace = Instigator.Location;
        Aim = AdjustAim(StartTrace, AimError);
        EndTrace = StartTrace + ShieldRange * Vector(Aim);
        Other = Weapon.Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);
    }

    Scale = ((FClamp(HoldTime, MinHoldTime, FullyChargedTime) - MinHoldTime) / (FullyChargedTime - MinHoldTime)) ;
    Damage = MinDamage + Scale * (MaxDamage - MinDamage);
    Force = MinForce + Scale * (MaxForce - MinForce) ;

    Instigator.AmbientSound = None;
    Instigator.SoundVolume = Instigator.Default.SoundVolume;

    if (ChargingEmitter != None)
        ChargingEmitter.mRegenPause = true;

    if ( Other != None && Other != Instigator )
    {
        if ( Pawn(Other) != None || (Decoration(Other) != None && Decoration(Other).bDamageable) )
            Other.TakeDamage(Damage, Instigator, HitLocation, (Force*Scale*X*100), DamageType);
        else if ( NetKActor(Other) != None)
            {
            Other.TakeDamage(Damage, Instigator, HitLocation, (Force*Scale*X), DamageType);
            Other.TakeDamage(Damage, Instigator, HitLocation, (Force*Scale*X), DamageType);
            Other.TakeDamage(Damage, Instigator, HitLocation, (Force*Scale*X), DamageType);
            }
        else
        {
            if ( xPawn(Instigator).bBerserk )
                Force *= 2.0;
            Instigator.TakeDamage(MinSelfDamage+SelfDamageScale*Damage, Instigator, HitLocation, -SelfForceScale*Force*X, DamageType);
            if ( DestroyableObjective(Other) != None )
                Other.TakeDamage(Damage, Instigator, HitLocation, Force*Scale*X, DamageType);
        }
    }

    SetTimer(0, false);
}
function Timer()
{
    local Actor Other;
    local Vector HitLocation, HitNormal, StartTrace, EndTrace;
    local Rotator Aim;
    local float Regen;
    local float ChargeScale;

    if (HoldTime > 0.0 && !bNowWaiting)
    {
        StartTrace = Instigator.Location;
        Aim = AdjustAim(StartTrace, AimError);
        EndTrace = StartTrace + ShieldRange * Vector(Aim);

        Other = Weapon.Trace(HitLocation, HitNormal, EndTrace, StartTrace, true);
        if ( (Pawn(Other) != None) && (Other != Instigator) )
        {
            bAutoRelease = true;
            bIsFiring = false;
            Instigator.AmbientSound = None;
            Instigator.SoundVolume = Instigator.Default.SoundVolume;
            AutoHitPawn = Pawn(Other);
            AutoHitTime = Level.TimeSeconds;
            if (ChargingEmitter != None)
                ChargingEmitter.mRegenPause = true;
        }
        if ( (NetKActor(Other) != None) && (Other != Instigator) )
        {
            bAutoRelease = true;
            bIsFiring = false;
            Instigator.AmbientSound = None;
            Instigator.SoundVolume = Instigator.Default.SoundVolume;
            AutoHitNetKActor = NetKActor(Other);
            AutoHitTime = Level.TimeSeconds;
            if (ChargingEmitter != None)
                ChargingEmitter.mRegenPause = true;
        }
        else
        {
            Instigator.AmbientSound = ChargingSound;
            Instigator.SoundVolume = ChargingSoundVolume;
            ChargeScale = FMin(HoldTime, FullyChargedTime);
            if (ChargingEmitter != None)
            {
                ChargingEmitter.mRegenPause = false;
                Regen = ChargeScale * 10 + 20;
                ChargingEmitter.mRegenRange[0] = Regen;
                ChargingEmitter.mRegenRange[1] = Regen;
                ChargingEmitter.mSpeedRange[0] = ChargeScale * -15.0;
                ChargingEmitter.mSpeedRange[1] = ChargeScale * -15.0;
                Regen = FMax((ChargeScale / 30.0),0.20);
                ChargingEmitter.mLifeRange[0] = Regen;
                ChargingEmitter.mLifeRange[1] = Regen;
            }

            if (!bStartedChargingForce)
            {
                bStartedChargingForce = true;
                ClientPlayForceFeedback( ChargingForce );
            }
        }
    }
    else
    {
        if ( Instigator.AmbientSound == ChargingSound )
        {
            Instigator.AmbientSound = None;
            Instigator.SoundVolume = Instigator.Default.SoundVolume;
        }

        SetTimer(0, false);
    }
}

defaultproperties
{
	DamageType=Class'GoodKarma.DamTypeShoveGun'
	MinHoldTime=0.050000
	MinForce=100000.000000
	MaxForce=250000.000000
	MinDamage=4.000000
	MaxDamage=15.000000
	SelfForceScale=0.050000
	MinSelfDamage=2.000000
	FullyChargedTime=1.250000
	FireRate=0.500000
}
