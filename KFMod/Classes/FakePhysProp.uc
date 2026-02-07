class FakePhysProp extends Actor
    placeable;

var() float DampenFactor;       // how much velocity is preserved after bounce
var() float MinStopSpeed;       // below this, prop will “settle”
var() float SpinRate;           // maximum random spin per bounce
var() bool  bStartAsleep;       // if true, starts with PHYS_None instead of falling

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if ( bStartAsleep )
        SetPhysics(PHYS_None);
    else if ( Physics == PHYS_None )
        SetPhysics(PHYS_Falling);
}

simulated final function RandSpin(float InSpinRate)
{
    DesiredRotation = RotRand();
    RotationRate.Yaw   = InSpinRate * 2 * FRand() - InSpinRate;
    RotationRate.Pitch = InSpinRate * 2 * FRand() - InSpinRate;
    RotationRate.Roll  = InSpinRate * 2 * FRand() - InSpinRate;
}

simulated function Landed(vector HitNormal)
{
    HitWall(HitNormal, None);
}

simulated function HitWall(vector HitNormal, Actor Wall)
{
    local float Speed;

    // Simple pseudo-physics bounce: reflect & damp velocity
    Velocity = DampenFactor * ((Velocity dot HitNormal) * HitNormal * (-2.0) + Velocity);
    RandSpin(SpinRate);
    Speed = VSize(Velocity);

    if ( Speed < MinStopSpeed )
    {
        bBounce = false;
        SetPhysics(PHYS_None);
        RotationRate = rot(0,0,0);
    }
}

defaultproperties
{
    DrawType=DT_StaticMesh
    Physics=PHYS_Falling
    RemoteRole=ROLE_None

    bCollideWorld=true
    //bUseCylinderCollision=true
    bBlockActors=true
    bBlockPlayers=true
    bProjTarget=true
    bBounce=true
    bFixedRotationDir=true
    bStatic=false
    bMovable=true

    Mass=30.0
    DampenFactor=0.650000
    MinStopSpeed=20.000000
    SpinRate=100000.000000
    bStartAsleep=false
}