//=============================================================================
// Nade
//=============================================================================
class Nade extends Grenade;

var() vector RotMag;            // how far to rot view
var() vector RotRate;           // how fast to rot view
var() float  RotTime;           // how much time to rot the instigator's view
var() vector OffsetMag;         // max view offset vertically
var() vector OffsetRate;        // how fast to offset view vertically
var() float  OffsetTime;        // how much time to offset view
var() class<Projectile> ShrapnelClass;

// Shoot nades in mid-air
// Alex

simulated function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
 Explode(hitlocation,momentum);
}



// cut-n-paste to remove grenade smoke trail
simulated function PostBeginPlay()
{
	//local PlayerController PC;

    super(Projectile).PostBeginPlay();

    //if ( Level.NetMode != NM_DedicatedServer)
    //{
	//	PC = Level.GetLocalPlayerController();
	//	if ( (PC.ViewTarget != None) && VSize(PC.ViewTarget.Location - Location) < 5500 )
	//		Trail = Spawn(class'GrenadeSmokeTrail', self,, Location, Rotation);
    //}

    if ( Role == ROLE_Authority )
    {
        Velocity = Speed * Vector(Rotation);
        RandSpin(25000);
        bCanHitOwner = false;
        if (Instigator.HeadVolume.bWaterVolume)
        {
            bHitWater = true;
            Velocity = 0.6*Velocity;
        }
    }
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
    local Controller        C;
    local PlayerController  LocalPlayer;
    local Rotator AdjustedRotation;
    local Projectile p;

    AdjustedRotation = self.Rotation;

    AdjustedRotation.Pitch += (rand(5000) + 2000);  // Random spray of shrapnel.

    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Pitch =  -AdjustedRotation.Pitch;
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Yaw += (rand(5000) + 3000);
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Yaw =  -AdjustedRotation.Yaw;
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Roll += (rand(5000) + 3000);
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Roll = -AdjustedRotation.Roll;
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);

    // Second shrapnel Wave

        AdjustedRotation.Pitch += (rand(5000) + 2000);  // Random spray of shrapnel.
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Pitch =  -AdjustedRotation.Pitch;
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Yaw += (rand(5000) + 3000);
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Yaw =  -AdjustedRotation.Yaw;
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Roll += (rand(5000) + 3000);
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);
    AdjustedRotation.Roll = -AdjustedRotation.Roll;
    p = Spawn(ShrapnelClass,,, self.Location, AdjustedRotation);


    BlowUp(HitLocation);
    PlaySound(sound'KFWeaponSound.Bang1',,100.5*TransientSoundVolume);
    if ( EffectIsRelevant(Location,false) )
    {
        Spawn(Class'KFmod.KFNadeExplosion',,, HitLocation, rotator(vect(0,0,1)));
        Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
    }


    // Shake nearby players screens

     LocalPlayer = Level.GetLocalPlayerController();
    if ( (LocalPlayer != None) && (VSize(Location - LocalPlayer.ViewTarget.Location) < (DamageRadius * 1.5)) )
        LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

    for ( C=Level.ControllerList; C!=None; C=C.NextController )
        if ( (PlayerController(C) != None) && (C != LocalPlayer)
            && (VSize(Location - PlayerController(C).ViewTarget.Location) < (DamageRadius * 1.5)) )
            C.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);
            
    Destroy();

}

simulated function Destroyed()
{
    if ( Trail != None )
        Trail.mRegen = false; // stop the emitter from regenerating
    Super.Destroyed();
}

/*
simulated function PostBeginPlay()
{
    local PlayerController PC;

    Super.PostBeginPlay();

    if ( Level.NetMode != NM_DedicatedServer)
    {
        PC = Level.GetLocalPlayerController();
    }

    if ( Role == ROLE_Authority )
    {
        Velocity = Speed * Vector(Rotation);
        RandSpin(25000);
        bCanHitOwner = false;
        if (Instigator.HeadVolume.bWaterVolume)
        {
            bHitWater = true;
            Velocity = 0.6*Velocity;
        }
    }
}
*/
simulated function ProcessTouch( actor Other, vector HitLocation )
{
   // if ( !Other.bWorldGeometry && (Other != Instigator || bCanHitOwner) )
    //{
      //  Explode(HitLocation, Normal(HitLocation-Other.Location));
   // }

   // more realistic interactions with karma objects.
   if (Other.IsA('NetKActor'))
    KAddImpulse(Velocity,HitLocation,);


   // Stop the grenade in its tracks if it hits an enemy.
   if ( !Other.bWorldGeometry && (Other != Instigator || bCanHitOwner) )
    Velocity = Vect(0,0,0);


}


//final iterator function RadiusActors  ( class<actor> BaseClass, out actor Actor, float Radius, optional vector Loc );


/* HurtRadius()
 Hurt locally authoritative actors within the radius.
*/
simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
    local actor Victims;
    local float damageScale, dist;
    local vector dir;

    if ( bHurtEntry )
        return;

    bHurtEntry = true;


   // foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
   // It'll be slower, but let's see if this helps the grenades deal damage properly in a radius.

    foreach RadiusActors (class 'Actor', Victims, DamageRadius, HitLocation)
    {
        // don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
        if( (Victims != self) && (Hurtwall != Victims) && (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo') )
        {
            dir = Victims.Location - HitLocation;
            dist = FMax(1,VSize(dir));
            dir = dir/dist;
            damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
            if ( Instigator == None || Instigator.Controller == None )
                Victims.SetDelayedDamageInstigatorController( InstigatorController );
            if ( Victims == LastTouched )
                LastTouched = None;
            Victims.TakeDamage
            (
                damageScale * DamageAmount,
                Instigator,
                Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
                (damageScale * Momentum * dir),
                DamageType
            );
            if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
                Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);

        }
    }
    if ( (LastTouched != None) && (LastTouched != self) && (LastTouched.Role == ROLE_Authority) && !LastTouched.IsA('FluidSurfaceInfo') )
    {
        Victims = LastTouched;
        LastTouched = None;
        dir = Victims.Location - HitLocation;
        dist = FMax(1,VSize(dir));
        dir = dir/dist;
        damageScale = FMax(Victims.CollisionRadius/(Victims.CollisionRadius + Victims.CollisionHeight),1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius));
        if ( Instigator == None || Instigator.Controller == None )
            Victims.SetDelayedDamageInstigatorController(InstigatorController);
        Victims.TakeDamage
        (
            damageScale * DamageAmount,
            Instigator,
            Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
            (damageScale * Momentum * dir),
            DamageType
        );
        if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
            Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);
    }

    bHurtEntry = false;
}

defaultproperties
{
     RotMag=(X=100.000000,Y=100.000000,Z=100.000000)
     RotRate=(X=500.000000,Y=500.000000,Z=500.000000)
     RotTime=3.000000
     OffsetMag=(X=40.000000,Y=40.000000,Z=40.000000)
     OffsetRate=(X=500.000000,Y=500.000000,Z=500.000000)
     OffsetTime=3.000000
     ShrapnelClass=Class'KFMod.KFShrapnel'
     DampenFactor=0.250000
     DampenFactorParallel=0.400000
     HitEffectClass=None
     Speed=160.000000
     MaxSpeed=350.000000
     Damage=250.000000
     DamageRadius=350.000000
     MomentumTransfer=150000.000000
     MyDamageType=Class'KFMod.DamTypeFrag'
     ExplosionDecal=Class'KFMod.KFScorchMark'
     StaticMesh=StaticMesh'KillingFloorStatics.FragProjectile'
     DrawScale=0.400000
     AmbientGlow=0
     bUnlit=False
     TransientSoundVolume=200.000000
}
