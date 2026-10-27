class LAWProj extends Projectile
	DependsOn(KFFarSound);

var() float BlastSize;	// how big a blast it makes round it (KFBlast)

var bool bNapalm;	// from an upgraded LAW: its fuel burns where it bursts (Napalm)

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		bNapalm;
}

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
    local Actor FX;

    //log("LAW Explode at: " $ HitLocation);
    class'KFBlastSound'.static.Play(self, sound'ONSVehicleSounds-S.TankFire01', 255+TransientSoundVolume);
    if ( Role == ROLE_Authority )
        class'KFFarSound'.static.Loud(self, HitLocation + HitNormal*24, FAR_Blast);
    if ( EffectIsRelevant(Location,false) )
    {
        FX = Spawn(class'KFNadeExplosion',,,HitLocation + HitNormal*16,rotator(HitNormal) + rot(-16384,0,0)); //Fixes explosion rotation
        if ( FX != None )
            FX.RemoteRole = ROLE_None;
        Spawn(class'KFLawFireExplosion',,,HitLocation + HitNormal*16, rotator(HitNormal) + rot(-16384,0,0));
        Spawn(class'ExplosionCrap',,, HitLocation + HitNormal*16, rotator(HitNormal));
        if ( (ExplosionDecal != None) && (Level.NetMode != NM_DedicatedServer) )
		    Spawn(ExplosionDecal,self,,Location, rotator(-HitNormal));
        class'KFBlast'.static.Go(self, HitLocation, HitNormal, BlastSize);
    }
    else
        class'KFBlast'.static.Far(self, HitLocation, BlastSize);

    // Shake nearby players screens
    LocalPlayer = Level.GetLocalPlayerController();
    if ( (LocalPlayer != None) && (VSize(Location - LocalPlayer.ViewTarget.Location) < DamageRadius) )       
        LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

    for ( C=Level.ControllerList; C!=None; C=C.NextController )
        if ( (PlayerController(C) != None) && (C != LocalPlayer)
            && (VSize(Location - PlayerController(C).ViewTarget.Location) < DamageRadius) )
            C.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);

    if ( bNapalm )
        Napalm(HitLocation, HitNormal);

    BlowUp(HitLocation);
    Destroy();
}

// An upgraded LAW's rocket: a ball of fire, and its fuel left burning on the ground in the middle and around (each
// machine lays its own fires, as the flamethrower's tendrils do)
simulated function Napalm( vector Spot, vector Up )
{
	local int i;
	local vector Way, P, HL, HN;
	local Actor A;

	if ( EffectIsRelevant(Location, false) )
		Spawn(class'KFIncendiaryExplosion',,, Spot + 16 * Up, rotator(Up));
	if ( PhysicsVolume.bWaterVolume || (Level.NetMode == NM_Client && !EffectIsRelevant(Location, false)) )
		return;
	class'FlameGroundFire'.static.Lay(self, Spot, Up, None, 5.0);
	for ( i = 0; i < 6; i++ )
	{
		Way.X = Cos(i * Pi / 3.0);
		Way.Y = Sin(i * Pi / 3.0);
		Way.Z = 0;
		P = Spot + 30 * Up + 125 * Way;
		if ( !FastTrace(P, Spot + 30 * Up) )
			continue;
		A = Trace(HL, HN, P - vect(0,0,180), P, false);
		if ( A != None && HN.Z >= 0.6 )
			class'FlameGroundFire'.static.Lay(self, HL, HN, A, 3.0);
	}
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
    // Don't allow hits on poeple on the same team
    //log("LAW Hit by: " $ instigatedBy.GetHumanReadableName() );
    if ( KFHumanPawn(instigatedBy) != None )
        return;
    //log("LAW Taking Damage: " $ Damage);
    Explode(HitLocation, vect(0,0,0));
}

simulated function Destroyed()
{
    //log("LAW Projectile Destroyed");
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
    // (a blast sets off fuel vapour and fuel in its reach: KFFireGrid)
    if ( Role == ROLE_Authority )
        class'KFFireGrid'.static.Heat(self, HitLocation, DamageRadius, 3.0);

    // A rocket that hit a specimen's extra collision hit the specimen
    if ( ExtendedZCollision(LastTouched) != None )
        LastTouched = LastTouched.Owner;

    foreach VisibleCollidingActors (class 'Actor', Victims, DamageRadius, HitLocation)
    {
        // don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
        if( Victims !=None && Victims != self && Hurtwall != Victims && Victims.Role == ROLE_Authority && !Victims.IsA('FluidSurfaceInfo') && !Victims.IsA('ExtendedZCollision') )
        {
            dirs = Victims.Location - HitLocation;
            dist = FMax(1,VSize(dirs));
            dirs = dirs/dist;
            damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
            if ( Instigator == None || Instigator.Controller == None )
                Victims.SetDelayedDamageInstigatorController( InstigatorController );
            if ( Victims == LastTouched )
                LastTouched = None;
            if( AIController(InstigatorController) != None && Victims == Instigator )
                DamageScale *= 0.5; // half damage to self from AI weapons
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
    if ( (LastTouched != None) && (LastTouched != self) && (LastTouched.Role == ROLE_Authority) && !LastTouched.IsA('FluidSurfaceInfo') && KFBloatVomit(LastTouched)==None )
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

// ProcessTouch lands the hit on every machine, a client's own bodies included, so the stock
// second hit on a client's body is left out.
simulated function ClientSideTouch(Actor Other, Vector HitLocation);

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
     BlastSize=1.000000
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
    MyDamageType=Class'KFMod.DamTypeLAW'
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
}
