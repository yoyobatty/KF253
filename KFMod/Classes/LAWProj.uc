class LAWProj extends Projectile;

#exec OBJ LOAD FILE=WeaponSounds.uax


// camera shakes //
var() vector ShakeRotMag;           // how far to rot view
var() vector ShakeRotRate;          // how fast to rot view
var() float  ShakeRotTime;          // how much time to rot the instigator's view
var() vector ShakeOffsetMag;        // max view offset vertically
var() vector ShakeOffsetRate;       // how fast to offset view vertically
var() float  ShakeOffsetTime;       // how much time to offset view

var() vector RotMag;            // how far to rot view
var() vector RotRate;           // how fast to rot view
var() float  RotTime;           // how much time to rot the instigator's view
var() vector OffsetMag;         // max view offset vertically
var() vector OffsetRate;        // how fast to offset view vertically
var() float  OffsetTime;        // how much time to offset view

var xEmitter SmokeTrail;
var vector Dir;
var bool bRing,bHitWater,bWaterStart;

<<<<<<< HEAD

 function ShakeView()
    {
        local Controller C;
        local PlayerController PC;
        local float Dist, Scale;

        for ( C=Level.ControllerList; C!=None; C=C.NextController )
        {
            PC = PlayerController(C);
            if ( PC != None && PC.ViewTarget != None )
            {
                Dist = VSize(Location - PC.ViewTarget.Location);
                if ( Dist < DamageRadius * 2.0)
                {
                    if (Dist < DamageRadius)
                        Scale = 1.0;
                    else
                        Scale = (DamageRadius*2.0 - Dist) / (DamageRadius);
                    C.ShakeView(ShakeRotMag*Scale, ShakeRotRate, ShakeRotTime, ShakeOffsetMag*Scale, ShakeOffsetRate, ShakeOffsetTime);
                }
            }
        }
    }



 simulated function Explode(vector HitLocation, vector HitNormal)
{
    local Controller C;
    local PlayerController PC;
    local PlayerController  LocalPlayer;


    PlaySound(sound'ONSVehicleSounds-S.TankFire01',,255+TransientSoundVolume);
    if ( EffectIsRelevant(Location,false) )
    {
        Spawn(class'KFNadeExplosion',,,HitLocation + HitNormal*20,rotator(HitNormal));
        PC = Level.GetLocalPlayerController();
        if ( (PC.ViewTarget != None) && VSize(PC.ViewTarget.Location - Location) < 5000 )
            Spawn(class'ExplosionCrap',,, HitLocation + HitNormal*20, rotator(HitNormal));
//		if ( (ExplosionDecal != None) && (Level.NetMode != NM_DedicatedServer) )
//			Spawn(ExplosionDecal,self,,Location, rotator(-HitNormal));
    }

    BlowUp(HitLocation);
    Destroy();
    
    
      // Shake nearby players screens

     LocalPlayer = Level.GetLocalPlayerController();
=======
function ShakeView()
{
    local Controller C;
    local PlayerController PC;
    local float Dist, Scale;

    for ( C=Level.ControllerList; C!=None; C=C.NextController )
    {
        PC = PlayerController(C);
        if ( PC != None && PC.ViewTarget != None )
        {
            Dist = VSize(Location - PC.ViewTarget.Location);
            if ( Dist < DamageRadius * 2.0)
            {
                if (Dist < DamageRadius)
                    Scale = 1.0;
                else
                    Scale = (DamageRadius*2.0 - Dist) / (DamageRadius);
                C.ShakeView(ShakeRotMag*Scale, ShakeRotRate, ShakeRotTime, ShakeOffsetMag*Scale, ShakeOffsetRate, ShakeOffsetTime);
            }
        }
    }
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
    local Controller C;
    local PlayerController  LocalPlayer;

    //log("LAW Explode at: " $ HitLocation);
    PlaySound(sound'ONSVehicleSounds-S.TankFire01',,255+TransientSoundVolume);
    if ( EffectIsRelevant(Location,false) )
    {
        Spawn(class'KFNadeExplosion',,,HitLocation + HitNormal*16,rotator(HitNormal));
        Spawn(class'ExplosionCrap',,, HitLocation + HitNormal*16, rotator(HitNormal));
        if ( (ExplosionDecal != None) && (Level.NetMode != NM_DedicatedServer) )
		    Spawn(ExplosionDecal,self,,Location, rotator(-HitNormal));
    }

    // Shake nearby players screens
    LocalPlayer = Level.GetLocalPlayerController();
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
    if ( (LocalPlayer != None) && (VSize(Location - LocalPlayer.ViewTarget.Location) < DamageRadius) )       
        LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

    for ( C=Level.ControllerList; C!=None; C=C.NextController )
        if ( (PlayerController(C) != None) && (C != LocalPlayer)
            && (VSize(Location - PlayerController(C).ViewTarget.Location) < DamageRadius) )
            C.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);
<<<<<<< HEAD
=======

    BlowUp(HitLocation);
    Destroy();
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

simulated function PostBeginPlay()
{
    if ( Level.NetMode != NM_DedicatedServer)
    {
        SmokeTrail = Spawn(class'GrenadeSmokeTrail',self);
        //Corona = Spawn(class'KFMod.KFLAWCorona',self);
    }

    Dir = vector(Rotation);
    Velocity = speed * Dir;
    if (PhysicsVolume.bWaterVolume)
    {
        bHitWater = True;
        Velocity=0.6*Velocity;
    }
    Super.PostBeginPlay();
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
<<<<<<< HEAD
=======
    // Don't allow hits on poeple on the same team
    //log("LAW Hit by: " $ instigatedBy.GetHumanReadableName() );
    if ( KFHumanPawn(instigatedBy) != None )
        return;
    //log("LAW Taking Damage: " $ Damage);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
    Explode(HitLocation, vect(0,0,0));
}

simulated function Destroyed()
{
<<<<<<< HEAD
=======
    //log("LAW Projectile Destroyed");
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
    if ( SmokeTrail != None )
        SmokeTrail.mRegen = False;
    Super.Destroyed();
}

/* HurtRadius()
 Hurt locally authoritative actors within the radius.
*/
simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
    local actor Victims;
    local float damageScale, dist;
    local vector dirs;

    if ( bHurtEntry )
        return;

    bHurtEntry = true;

<<<<<<< HEAD

   // foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
   // It'll be slower, but let's see if this helps the grenades deal damage properly in a radius.

    foreach RadiusActors (class 'Actor', Victims, DamageRadius, HitLocation)
    {
        // don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
        if( (Victims != self) && (Hurtwall != Victims) && (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo')
		 && ExtendedZCollision(Victims)==None )
=======
    foreach VisibleCollidingActors (class 'Actor', Victims, DamageRadius, HitLocation)
    {
        // don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
        if( Victims !=None && Victims != self && Hurtwall != Victims && Victims.Role == ROLE_Authority && !Victims.IsA('FluidSurfaceInfo') && !Victims.IsA('ExtendedZCollision') )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
        {
            dirs = Victims.Location - HitLocation;
            dist = FMax(1,VSize(dirs));
            dirs = dirs/dist;
            damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
            if ( Instigator == None || Instigator.Controller == None )
                Victims.SetDelayedDamageInstigatorController( InstigatorController );
            if ( Victims == LastTouched )
                LastTouched = None;
            Victims.TakeDamage
            (
                damageScale * DamageAmount,
                Instigator,
                Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dirs,
                (damageScale * Momentum * dirs),
                DamageType
            );
            if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
                Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);

        }
    }
<<<<<<< HEAD
    if ( (LastTouched != None) && (LastTouched != self) && (LastTouched.Role == ROLE_Authority) && !LastTouched.IsA('FluidSurfaceInfo') )
=======
    if ( (LastTouched != None) && (LastTouched != self) && (LastTouched.Role == ROLE_Authority) && !LastTouched.IsA('FluidSurfaceInfo') && KFBloatVomit(LastTouched)==None )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
    {
        Victims = LastTouched;
        LastTouched = None;
        dirs = Victims.Location - HitLocation;
        dist = FMax(1,VSize(dirs));
        dirs = dirs/dist;
        damageScale = FMax(Victims.CollisionRadius/(Victims.CollisionRadius + Victims.CollisionHeight),1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius));
        if ( Instigator == None || Instigator.Controller == None )
            Victims.SetDelayedDamageInstigatorController(InstigatorController);
        Victims.TakeDamage
        (
            damageScale * DamageAmount,
            Instigator,
            Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dirs,
            (damageScale * Momentum * dirs),
            DamageType
        );
        if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
            Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);
    }

    bHurtEntry = false;
}

<<<<<<< HEAD
defaultproperties
{
	ShakeRotMag=(Z=250.000000)
	ShakeRotRate=(Z=2500.000000)
	ShakeRotTime=6.000000
	ShakeOffsetMag=(Z=10.000000)
	ShakeOffsetRate=(Z=200.000000)
	ShakeOffsetTime=10.000000
	RotMag=(X=100.000000,Y=100.000000,Z=100.000000)
	RotRate=(X=500.000000,Y=500.000000,Z=500.000000)
	RotTime=3.000000
	OffsetMag=(X=40.000000,Y=40.000000,Z=40.000000)
	OffsetRate=(X=500.000000,Y=500.000000,Z=500.000000)
	OffsetTime=3.000000
	Speed=2600.000000
	MaxSpeed=3000.000000
	Damage=650.000000
	DamageRadius=200.000000
	MomentumTransfer=200000.000000
	MyDamageType=Class'KFMod.DamTypeFrag'
	ExplosionDecal=Class'KFMod.KFScorchMark'
	LightHue=25
	LightSaturation=100
	LightBrightness=250.000000
	LightRadius=10.000000
	DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'KillingFloorStatics.LAWRocket'
	LifeSpan=10.000000
	DrawScale=0.700000
	bUnlit=False
	ForceRadius=300.000000
	ForceScale=10.000000
=======
//this will make bots and us stop suiciding for once
simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
    //log("LAW Hit: " $ Other.GetHumanReadableName() );
	// Don't let it hit this player, or blow up on another player
	if ( Other == Instigator || Other.Base == Instigator )
		return;

    // Don't allow hits on poeple on the same team
    if ( KFHumanPawn(Other) != None )
        return;

    if ( KFGlassMover(Other) != None )
    {
        if( Level.NetMode!=NM_Client )
            Other.TakeDamage(Damage, Instigator, HitLocation, vect(0,0,0), MyDamageType);
        return;
    }

	Explode(HitLocation,Normal(HitLocation-Other.Location));
}

defaultproperties
{
    ShakeRotMag=(Z=250.000000)
    ShakeRotRate=(Z=2500.000000)
    ShakeRotTime=6.000000
    ShakeOffsetMag=(Z=10.000000)
    ShakeOffsetRate=(Z=200.000000)
    ShakeOffsetTime=10.000000
    RotMag=(X=100.000000,Y=100.000000,Z=100.000000)
    RotRate=(X=500.000000,Y=500.000000,Z=500.000000)
    RotTime=3.000000
    OffsetMag=(X=40.000000,Y=40.000000,Z=40.000000)
    OffsetRate=(X=500.000000,Y=500.000000,Z=500.000000)
    OffsetTime=3.000000
    Speed=2600.000000
    MaxSpeed=3000.000000
    Damage=825.000000 //Was 950
    DamageRadius=450.000000 //Was 400
    MomentumTransfer=125000.000000
    MyDamageType=Class'KFMod.DamTypeFrag'
    ExplosionDecal=Class'KFMod.KFScorchMark'
    LightHue=25
    LightSaturation=100
    LightBrightness=250.000000
    LightRadius=10.000000
    DrawType=DT_StaticMesh
    StaticMesh=StaticMesh'KillingFloorStatics.LAWRocket'
    LifeSpan=10.000000
    DrawScale=0.700000
    bUnlit=False
    bNetNotify=True
    ForceRadius=300.000000
    ForceScale=10.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
