//=============================================================================
// Shotgun Bullet
//=============================================================================
class ShotgunBullet extends Projectile;
<<<<<<< HEAD
=======

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
var xEmitter Trail;
var float DamageAtten;
var sound ImpactSounds[6];
var () int MaxPenetrations; // Yeah, Hardy har har. It refers in fact to the number of times the bolt can pass through someone and keep going.
var () float PenDamageReduction; // how much damage does it lose with each person it passes through?
<<<<<<< HEAD
var() float HeadShotDamageMult;


var Vector tempStartLoc;

=======
var () float PenDamageReductionPerked;
var() float HeadShotDamageMult;

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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

<<<<<<< HEAD
    SetTimer(0.4, false);
    tempStartLoc = Location;

=======
    //SetTimer(0.4, false);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

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

<<<<<<< HEAD
=======
simulated function Tick( float DeltaTime )
{
	Super.Tick(DeltaTime);

    if( Physics==PHYS_Projectile )
		Velocity.Z -= DeltaTime * 100.0; // gravity	
}
/*
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
function Timer()
{
    SetCollisionSize(20, 20);
}
<<<<<<< HEAD

simulated function Destroyed()
{

	if (Trail !=None) Trail.mRegen=False;
         Super.Destroyed();

}

/*

simulated function DestroyTrails()
{

}

*/

simulated function Explode(vector HitLocation,vector HitNormal)
{
    local KFHitEffect S;
    
    if ( Role == ROLE_Authority )
    {
        HurtRadius(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
    }

   	PlaySound(ImpactSound, SLOT_Misc);
	if ( HitNormal != Vect(0,0,0))
	{
	   if (pawn(Owner) != none && pawn(Owner).Weapon!= none) 
            S = pawn(Owner).Weapon.Spawn(class'KFHitEffectLarge',,, HitLocation, rotator(-1 * HitNormal));
	}
    SetCollisionSize(0.0, 0.0);
	Destroy();
}
simulated singular function HitWall(vector HitNormal, actor Wall)
{
	local PlayerController PC;

	 if(Level.NetMode != NM_DedicatedServer)
        Spawn(class'KFHitEffectLarge');
        Spawn(class'InvisBullet',,, Location);
=======
*/
simulated function Destroyed()
{
	if (Trail !=None) Trail.mRegen=False;
        Super.Destroyed();
}

simulated singular function HitWall(vector HitNormal, actor Wall)
{
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
<<<<<<< HEAD
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
		else
			//Spawn(class'ShotgunWallHitEffect',self,,Location, rotator(-HitNormal));
            Spawn(class'InvisBullet',,, Location);
	}
	HurtWall = None;


=======

	if(Level.NetMode != NM_DedicatedServer)
    {
        Spawn(class'KFHitEffect',Wall,,Location, rotator(HitNormal));
        Spawn(class'InvisBullet',,, Location);
    }
	HurtWall = None;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
    if (Trail != None)
    {
        Trail.mRegen=False;
        Trail.SetPhysics(PHYS_None);
        //Trail.mRegenRange[0] = 0.0;//trail.mRegenRange[0] * 0.6;
        //Trail.mRegenRange[1] = 0.0;//trail.mRegenRange[1] * 0.6;
    }
}

<<<<<<< HEAD




=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated function ProcessTouch (Actor Other, vector HitLocation)
{
    local vector X;

    X = Vector(Rotation);
<<<<<<< HEAD


    if ( Other != none && Other != Instigator) // dont want to hit ourself :)
    {
         speed = VSize(Velocity);


           if (Pawn(Other) != none && Pawn(Other).IsHeadShot(HitLocation, X, 1.0))
             Pawn(Other).TakeDamage(Damage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType);
            else
             Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType);




               Damage *= PenDamageReduction; // Keep going, but lose effectiveness each time.

              // if we've struck through more than the max number of foes, destroy.

               if ( (Damage / default.Damage * 100) <= ((PenDamageReduction / MaxPenetrations) * 100))
                Destroy();



   }
=======
    if ( Other == none || Other == Instigator || Other.Base == Instigator) // dont want to hit ourself :)
        return;

    // Don't allow hits on people on the same team
    if (KFHumanPawn(Other) != none)
        return;

    if (Pawn(Other) != none && Pawn(Other).IsHeadShot(HitLocation, X, 1.0))
        Pawn(Other).TakeDamage(Damage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType);
    else
        Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * Normal(Velocity), MyDamageType);
    if(KFPawn(Instigator).GetVeteran().default.VeterancyName == "Support Specialist")
        PenDamageReduction = PenDamageReductionPerked; //80% better shotty penetration
    else PenDamageReduction = default.PenDamageReduction;
    Damage *= PenDamageReduction; // Keep going, but lose effectiveness each time.
    // if we've struck through more than the max number of foes, destroy.
    Speed = VSize(Velocity);
    if ( (Damage / default.Damage <= PenDamageReduction / MaxPenetrations) || Speed < (default.Speed * 0.25))
        Destroy();

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

defaultproperties
{
<<<<<<< HEAD
	DamageAtten=5.000000
	MaxPenetrations=2
	PenDamageReduction=0.500000
	HeadShotDamageMult=1.500000
	Speed=3500.000000
	MaxSpeed=4000.000000
	bSwitchToZeroCollision=True
	Damage=35.000000
	DamageRadius=0.000000
	MomentumTransfer=50000.000000
	MyDamageType=Class'KFMod.DamTypeShotgun'
	ExplosionDecal=Class'KFMod.ShotgunDecal'
	DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'WeaponStaticMesh.FlakChunk'
	CullDistance=3000.000000
	LifeSpan=3.000000
	DrawScale=5.000000
	Style=STY_Alpha
=======
    DamageAtten=5.000000
    MaxPenetrations=2
    PenDamageReduction=0.500000
    PenDamageReductionPerked=0.900000
    HeadShotDamageMult=1.500000
    Speed=5500.000000
    MaxSpeed=6000.000000
    bSwitchToZeroCollision=True
    Damage=21.000000
    DamageRadius=0.000000
    MomentumTransfer=50000.000000
    MyDamageType=Class'KFMod.DamTypeShotgun'
    ExplosionDecal=Class'KFMod.ShotgunDecal'
    DrawType=DT_StaticMesh
    StaticMesh=StaticMesh'WeaponStaticMesh.FlakChunk'
    CullDistance=3000.000000
    LifeSpan=3.000000
    DrawScale=5.000000
    Style=STY_Alpha
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
