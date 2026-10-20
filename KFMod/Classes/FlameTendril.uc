//=============================================================================
// Flame
//=============================================================================
class FlameTendril extends ShotgunBullet;

var bool bRing,bHitWater,bWaterStart;
var Effects Corona;
var Emitter FlameTrail;
var float FlightStart;		// when it left the nozzle
var() float FlightTime;		// how long it flies before it burns out; the perk's ExtraRange adds a share of it

simulated function PostBeginPlay()
{
	if ( Instigator != None )
		ShooterTeam = Instigator.GetTeamNum();
	SetTimer(0.2, true);
	FlightStart = Level.TimeSeconds;

	Velocity = Speed * Vector(Rotation); // starts off slower so combo can be done closer

	if ( Level.NetMode != NM_DedicatedServer )
	{
		if (!PhysicsVolume.bWaterVolume)
		{
			FlameTrail = Spawn(class'FlameThrowerFlameB',self);
			Trail = Spawn(class'FlameThrowerFlame',self);
		}
	}
	Velocity.z += TossZ;
}

simulated function PostNetBeginPlay()
{
	local PlayerController PC;

	Super.PostNetBeginPlay();

	if ( Level.NetMode == NM_DedicatedServer )
	{
		return;
	}

	if ( Level.bDropDetail || (Level.DetailMode == DM_Low) )
	{
		bDynamicLight = false;
		LightType = LT_None;
	}
	else
	{
		PC = Level.GetLocalPlayerController();
		if ( (Instigator != None) && (PC == Instigator.Controller) )
		{
			return;
		}

		if ( (PC == None) || (PC.ViewTarget == None) || (VSize(PC.ViewTarget.Location - Location) > 3000) )
		{
			bDynamicLight = false;
			LightType = LT_None;
		}
	}
}

simulated function Landed( vector HitNormal )
{
	Scorch(HitNormal);
	Explode(Location,HitNormal);
}

// How long a tendril fired by P flies
static function float FlightFor(Pawn P)
{
	if ( KFPawn(P) != None )
		return default.FlightTime * (1.0 + KFPawn(P).GetVeteran().Static.ExtraRange());
	return default.FlightTime;
}

// A scorch mark on the floor or wall it hit, aimed into it (it was aimed along the shot: smeared on a floor)
simulated function Scorch(vector HitNormal)
{
	if ( ExplosionDecal != None && EffectIsRelevant(Location,false) )
		Spawn(ExplosionDecal,self,,Location, rotator(-HitNormal));
}

simulated function bool CanSpawnFuelFlameNear(int MaxPerArea, float Radius)
{
    local FuelFlameHurting F;
    local int Count;

    foreach RadiusActors(class'FuelFlameHurting', F, Radius, Location)
    {
        // (one dying down does no harm any more: counted, it kept the spot under a held stream dark for 3 s)
        if (F.Instigator == Instigator && !F.bDyingDown)
        {
            Count++;
            if (Count >= MaxPerArea)
                return false; // already enough nearby flames from this instigator
        }
    }
    return true;
}

simulated function Explode(vector HitLocation,vector HitNormal)
{
    local bool bRelevant;

    if ( Role == ROLE_Authority )
        HurtRadius(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
    bRelevant = EffectIsRelevant(Location,false);
    if ( (bRelevant || Level.NetMode != NM_Client) && CanSpawnFuelFlameNear(3, 36.0) )
        Spawn(class'FlameGroundFire',Instigator,,Location + vect(0,0,1));
    SetCollisionSize(0.0, 0.0);
    Destroy();
}

simulated function Destroyed()
{
	if (Trail != None)
	{
		Trail.mRegen=False;
		Trail.SetPhysics(PHYS_None);
	}
	if (FlameTrail != None)
	{
		FlameTrail.Kill();
		//FlameTrail.SetPhysics(PHYS_None);
	}
	Super.Destroyed();
}

simulated function ProcessTouch (Actor Other, vector HitLocation)
{
    local vector X;

    X = Vector(Rotation);
    if ( Other == none || Other == Instigator || Other.Base == Instigator) // dont want to hit ourself :)
        return;

    // Don't allow hits on people on the same team
    if( class'KFHumanPawn'.static.OnShootersTeam(Other, Instigator, ShooterTeam) )
        return;

    Other.TakeDamage(Damage, Instigator, HitLocation, vect(0,0,0), MyDamageType);
    Damage *= PenDamageReduction; // Keep going, but lose effectiveness each time.
    // if we've struck through more than the max number of foes, destroy.
    //Speed = VSize(Velocity);
	//Speed *= 0.8; //slow down as we pass through
    //if ( (Damage / default.Damage <= PenDamageReduction / MaxPenetrations) || Speed < (default.Speed * 0.25))
    //    Explode(Location,VRand());
	if (FlameTendril(Other)==None && FuelFlameHurting(Other)==None)
		Explode(Location,VRand());

}

simulated singular function HitWall(vector HitNormal, actor Wall)
{
	if ( Role == ROLE_Authority )
	{
		if ( !Wall.bStatic && !Wall.bWorldGeometry )
		{
			if ( Instigator == None || Instigator.Controller == None )
				Wall.SetDelayedDamageInstigatorController( InstigatorController );
			Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);
			HurtWall = Wall;
		}
		MakeNoise(1.0);
	}
	Scorch(HitNormal);
	Explode(Location + ExploWallOut * HitNormal, HitNormal);
	HurtWall = None;
}

simulated function Timer()
{
	local float Left;

	Velocity =  Default.Speed * Normal(Velocity);

	if (Trail != none)
	{
		Trail.mSizeRange[0] *= 1.8;
		Trail.mSizeRange[1] *= 1.8;
	}
	if (FlameTrail != none)
		FlameTrail.SetDrawScale(FlameTrail.DrawScale * 1.5);
	// Burnt out after its flight time (the last step shortened to land on it: whole 0.2 s steps made the Firebug's +50% a +33%)
	Left = FlightFor(Instigator) - (Level.TimeSeconds - FlightStart);
	if ( Left < 0.01 )
		Explode(Location,VRand());
	else if ( Left < 0.2 )
		SetTimer(Left, false);
}

defaultproperties
{
     FlightTime=0.600000
     MaxPenetrations=3
     PenDamageReduction=0.750000
     HeadShotDamageMult=1.000000
     Speed=2300.000000
     MaxSpeed=2400.000000
     TossZ=200.000000
     Damage=12.000000
     DamageRadius=150.000000
     MomentumTransfer=0.000000
     MyDamageType=Class'KFMod.DamTypeFlamethrower'
     ExplosionDecal=Class'KFMod.KFScorchMark'
     DrawType=DT_None
     StaticMesh=None
     Physics=PHYS_Falling
     LifeSpan=5.000000
     Style=STY_None
}
