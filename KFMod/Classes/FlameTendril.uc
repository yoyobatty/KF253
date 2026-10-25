//=============================================================================
// Flame
//=============================================================================
class FlameTendril extends ShotgunBullet;

var bool bRing,bHitWater,bWaterStart;
var Effects Corona;
var float FlightStart;		// when it left the nozzle
var() float FlightTime;		// how long it flies before it burns out; the perk's ExtraRange adds a share of it
var bool bAirborne;			// it ends in the air (burnt out, or struck a body): its fuel falls (KFFlameFuelDrop)
var Actor LandBase;			// what it struck, when that can move

simulated function PostBeginPlay()
{
	if ( Instigator != None )
		ShooterTeam = Instigator.GetTeamNum();
	SetTimer(0.2, true);
	FlightStart = Level.TimeSeconds;

	// (it is seen as KFFlameStream, so it carries no picture of its own; it carries its shooter's speed)
	Velocity = Speed * Vector(Rotation);
	if ( Role == ROLE_Authority && Instigator != None )
		Velocity += Instigator.Velocity;
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
	Explode(Location,HitNormal);
}

// How long a tendril fired by P flies
static function float FlightFor(Pawn P)
{
	if ( KFPawn(P) != None )
		return default.FlightTime * (1.0 + KFPawn(P).GetVeteran().Static.ExtraRange());
	return default.FlightTime;
}

// Its fuel burns where it struck (FlameGroundFire.Lay), or falls from the air
simulated function Explode(vector HitLocation,vector HitNormal)
{
    if ( Role == ROLE_Authority )
        HurtRadius(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
    else if ( Level.NetMode == NM_Client )
        class'KFMonster'.static.IgniteBodiesNear(self, DamageRadius, HitLocation);
    if ( !PhysicsVolume.bWaterVolume && (Level.NetMode != NM_Client || EffectIsRelevant(Location,false)) )
    {
        if ( bAirborne )
            class'KFFlameFuelDrop'.static.Drop(self, Location, Velocity * 0.3, class'FlameGroundFire'.default.DropFuel);
        else
            class'FlameGroundFire'.static.Lay(self, HitLocation, HitNormal, LandBase);
    }
    SetCollisionSize(0.0, 0.0);
    Destroy();
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
	{
		// (what struck a body runs off it to the floor)
		bAirborne = true;
		Velocity *= 0.25;
		Explode(Location,VRand());
	}

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
	if ( Wall != None && !Wall.bStatic )
		LandBase = Wall;
	Explode(Location + ExploWallOut * HitNormal, HitNormal);
	HurtWall = None;
}

simulated function Timer()
{
	local float Left;

	Velocity =  Default.Speed * Normal(Velocity);

	// Burnt out after its flight time (the last step shortened to land on it: whole 0.2 s steps made the Firebug's +50% a +33%)
	Left = FlightFor(Instigator) - (Level.TimeSeconds - FlightStart);
	if ( Left < 0.01 )
	{
		bAirborne = true;
		Explode(Location,VRand());
	}
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
     DrawType=DT_None
     StaticMesh=None
     Physics=PHYS_Falling
     LifeSpan=5.000000
     Style=STY_None
}
