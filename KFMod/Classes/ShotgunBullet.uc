//=============================================================================
// Shotgun Bullet
//=============================================================================
class ShotgunBullet extends Projectile;

var xEmitter Trail;
var float DamageAtten;
var sound ImpactSounds[6];
var () int MaxPenetrations; // Yeah, Hardy har har. It refers in fact to the number of times the bolt can pass through someone and keep going.
var () float PenDamageReduction; // how much damage does it lose with each person it passes through?
var () float PenDamageReductionPerked;
var() float HeadShotDamageMult;

simulated event PreBeginPlay()
{
    Super.PreBeginPlay();

    if( Pawn(Owner) != None )
        Instigator = Pawn( Owner );
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	Velocity = Speed * Vector(Rotation); // starts off slower so combo can be done closer

    //SetTimer(0.4, false);

    if ( Level.NetMode != NM_DedicatedServer )
    {
        if ( !PhysicsVolume.bWaterVolume )
        {

            Trail = Spawn(class'KFTracer',self);
            Trail.Lifespan = Lifespan;
        }

    }
}

simulated function PostNetBeginPlay()
{
	local PlayerController PC;

	Super.PostNetBeginPlay();

	if ( Level.NetMode == NM_DedicatedServer )
		return;

	PC = Level.GetLocalPlayerController();
	if ( (Instigator != None) && (PC == Instigator.Controller) )
		return;
	if ( Level.bDropDetail || (Level.DetailMode == DM_Low) )
	{
		bDynamicLight = false;
		LightType = LT_None;
	}
	else if ( (PC == None) || (PC.ViewTarget == None) || (VSize(PC.ViewTarget.Location - Location) > 3000) )
	{
		bDynamicLight = false;
		LightType = LT_None;
	}
}

simulated function Tick( float DeltaTime )
{
	Super.Tick(DeltaTime);

    if( Physics==PHYS_Projectile )
		Velocity.Z -= DeltaTime * 100.0; // gravity	
}
/*
function Timer()
{
    SetCollisionSize(20, 20);
}
*/
simulated function Destroyed()
{
	if (Trail !=None) Trail.mRegen=False;
        Super.Destroyed();
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
			if (DamageRadius > 0 && Vehicle(Wall) != None && Vehicle(Wall).Health > 0)
				Vehicle(Wall).DriverRadiusDamage(Damage, DamageRadius, InstigatorController, MyDamageType, MomentumTransfer, Location);
			HurtWall = Wall;
		}
		MakeNoise(1.0);
	}
	Explode(Location + ExploWallOut * HitNormal, HitNormal);

	if(Level.NetMode != NM_DedicatedServer)
    {
        Spawn(class'KFHitEffect',Wall,,Location, rotator(HitNormal));
        Spawn(class'InvisBullet',,, Location);
    }
	HurtWall = None;
    if (Trail != None)
    {
        Trail.mRegen=False;
        Trail.SetPhysics(PHYS_None);
        //Trail.mRegenRange[0] = 0.0;//trail.mRegenRange[0] * 0.6;
        //Trail.mRegenRange[1] = 0.0;//trail.mRegenRange[1] * 0.6;
    }
}

simulated function ProcessTouch (Actor Other, vector HitLocation)
{
    local vector X;
    local Pawn HitPawn;

    X = Vector(Rotation);
    if ( Other == none || Other == Instigator || Other.Base == Instigator)
        return;

    // Don't allow hits on people on the same team
    if( KFHumanPawn(Other) != none && Instigator != none && KFHumanPawn(Other).PlayerReplicationInfo.Team.TeamIndex == Instigator.PlayerReplicationInfo.Team.TeamIndex )
        return;

    // Resolve ExtendedZCollision to its owner pawn
    if ( ExtendedZCollision(Other) != None && Pawn(Other.Owner) != None )
        HitPawn = Pawn(Other.Owner);
    else
        HitPawn = Pawn(Other);

    if (HitPawn != none && HitPawn.IsHeadShot(HitLocation, X, 1.0))
        HitPawn.TakeDamage(Damage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType);
    else if (HitPawn != none)
        HitPawn.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType);
    else
        Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType);

    if(KFPawn(Instigator).GetVeteran().default.VeterancyName == "Support Specialist")
        PenDamageReduction = PenDamageReductionPerked;
    else PenDamageReduction = default.PenDamageReduction;
    Damage *= PenDamageReduction;
    Speed = VSize(Velocity);
    if ( (Damage / default.Damage <= PenDamageReduction / MaxPenetrations) || Speed < (default.Speed * 0.25))
        Destroy();
}

defaultproperties
{
    DamageAtten=5.000000
    MaxPenetrations=2
    PenDamageReduction=0.500000
    PenDamageReductionPerked=0.900000
    HeadShotDamageMult=1.500000
    Speed=5500.000000
    MaxSpeed=6000.000000
    bSwitchToZeroCollision=True
    Damage=22.000000
    DamageRadius=4.000000
    MomentumTransfer=50000.000000
    MyDamageType=Class'KFMod.DamTypeShotgun'
    ExplosionDecal=Class'KFMod.ShotgunDecal'
    DrawType=DT_StaticMesh
    StaticMesh=StaticMesh'WeaponStaticMesh.FlakChunk'
    CullDistance=3000.000000
    LifeSpan=3.000000
    DrawScale=5.000000
    Style=STY_Alpha
}
