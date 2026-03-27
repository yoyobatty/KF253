//=============================================================================
// Flame
//=============================================================================
class FlameTendril extends ShotgunBullet;

var bool bRing,bHitWater,bWaterStart;
var Effects Corona;
var Emitter FlameTrail;
var byte KillCalculator;

simulated function PostBeginPlay()
{
	SetTimer(0.2, true);
<<<<<<< HEAD
	tempStartLoc = Location;
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
    
	Velocity = Speed * Vector(Rotation); // starts off slower so combo can be done closer

	if ( Level.NetMode != NM_DedicatedServer )
	{
<<<<<<< HEAD
		if ( !PhysicsVolume.bWaterVolume )
=======
		if (!PhysicsVolume.bWaterVolume)
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
<<<<<<< HEAD
		return;
=======
	{
		return;
	}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	if ( Level.bDropDetail || (Level.DetailMode == DM_Low) )
	{
		bDynamicLight = false;
		LightType = LT_None;
	}
	else
	{
		PC = Level.GetLocalPlayerController();
		if ( (Instigator != None) && (PC == Instigator.Controller) )
<<<<<<< HEAD
			return;
=======
		{
			return;
		}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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

<<<<<<< HEAD
=======
simulated function bool CanSpawnFuelFlameNear(int MaxPerArea, float Radius)
{
    local FuelFlameHurting F;
    local int Count;

    foreach RadiusActors(class'FuelFlameHurting', F, Radius, Location)
    {
        if (F.Instigator == Instigator)
        {
            Count++;
            if (Count >= MaxPerArea)
                return false; // already enough nearby flames from this instigator
        }
    }
    return true;
}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated function Explode(vector HitLocation,vector HitNormal)
{
	if ( Role == ROLE_Authority )
		HurtRadius(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
<<<<<<< HEAD
	if (KFHumanPawn(Instigator) != none)
	{
		if ( EffectIsRelevant(Location,false) )
		{
			Spawn(ExplosionDecal,,, Location);
			Spawn(class'FuelFlame',Instigator,,Location);
=======
	if ( EffectIsRelevant(Location,false) )
	{
		Spawn(ExplosionDecal,self,, Location);
		if ( CanSpawnFuelFlameNear(3, 36.0) )
		{
			Spawn(class'FuelFlameHurting',Instigator,,Location + vect(0,0,1)).BurnTime = 3.0;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		}
	}
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
<<<<<<< HEAD
		FlameTrail.SetPhysics(PHYS_None);
=======
		//FlameTrail.SetPhysics(PHYS_None);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	}
	Super.Destroyed();
}

<<<<<<< HEAD
function ProcessTouch (Actor Other, vector HitLocation)
{
	if (Other != Instigator && !Other.IsA('FlameTendril') && !Other.IsA('FuelFlame') && !Other.IsA('PhysicsVolume') )
		Explode(self.Location,self.Location);
}

=======
simulated function ProcessTouch (Actor Other, vector HitLocation)
{
    local vector X;

    X = Vector(Rotation);
    if ( Other == none || Other == Instigator || Other.Base == Instigator) // dont want to hit ourself :)
        return;

    // Don't allow hits on people on the same team
    if (
        KFHumanPawn(Other) != none &&
        KFHumanPawn(Other).Controller != none &&
        Instigator != none &&
        Instigator.Controller != none &&
        KFHumanPawn(Other).Controller.SameTeamAs(Instigator.Controller)
    )
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

simulated singular function HitWall(vector HitNormal, actor Wall)
{
	local PlayerController PC;

	if ( Role == ROLE_Authority )
	{
		if ( !Wall.bStatic && !Wall.bWorldGeometry )
		{
			if ( Instigator == None || Instigator.Controller == None )
				Wall.SetDelayedDamageInstigatorController( InstigatorController );
			Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);
<<<<<<< HEAD
			if (DamageRadius > 0 && Vehicle(Wall) != None && Vehicle(Wall).Health > 0)
				Vehicle(Wall).DriverRadiusDamage(Damage, DamageRadius, InstigatorController, MyDamageType, MomentumTransfer, Location);
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
			HurtWall = Wall;
		}
		MakeNoise(1.0);
	}
	Explode(Location + ExploWallOut * HitNormal, HitNormal);
	if ( (ExplosionDecal != None) && (Level.NetMode != NM_DedicatedServer)  )
	{
		if ( ExplosionDecal.Default.CullDistance != 0 )
		{
			PC = Level.GetLocalPlayerController();
			if ( !PC.BeyondViewDistance(Location, ExplosionDecal.Default.CullDistance) )
				Spawn(ExplosionDecal,self,,Location, rotator(-HitNormal));
			else if ( (Instigator != None) && (PC == Instigator.Controller) && !PC.BeyondViewDistance(Location, 2*ExplosionDecal.Default.CullDistance) )
				Spawn(ExplosionDecal,self,,Location, rotator(-HitNormal));
		}
	}
	HurtWall = None;
}

simulated function Timer()
{
	Velocity =  Default.Speed * Normal(Velocity);

	if (Trail != none)
	{
		Trail.mSizeRange[0] *= 1.8;
		Trail.mSizeRange[1] *= 1.8;
	}
	if (FlameTrail != none)
		FlameTrail.SetDrawScale(FlameTrail.DrawScale * 1.5);
	if( (KillCalculator++)>=2+KFPawn(Instigator).GetVeteran().Static.ExtraRange() )
		Explode(Location,VRand());
}

defaultproperties
{
<<<<<<< HEAD
	MaxPenetrations=3
	PenDamageReduction=0.000000
	HeadShotDamageMult=1.000000
	Speed=2300.000000
	MaxSpeed=2400.000000
	TossZ=200.000000
	Damage=6.000000
	DamageRadius=150.000000
	MomentumTransfer=0.000000
	MyDamageType=Class'GamePlay.Burned'
	ExplosionDecal=Class'KFMod.KFScorchMark'
	DrawType=DT_None
	StaticMesh=None
	Physics=PHYS_Falling
	LifeSpan=5.000000
	Style=STY_None
=======
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
