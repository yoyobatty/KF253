class ExplosiveShotgunShell extends Projectile;

var class<DamageType> ExplosiveDamageType;

var() vector ShakeRotMag;
var() vector ShakeRotRate;
var() float  ShakeRotTime;
var() vector ShakeOffsetMag;
var() vector ShakeOffsetRate;
var() float  ShakeOffsetTime;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();
    Velocity = Speed * Vector(Rotation);
}

simulated function Tick(float DeltaTime)
{
    Super.Tick(DeltaTime);
    if (Physics == PHYS_Projectile)
        Velocity.Z -= DeltaTime * 150.0;
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
    local Controller C;
    local PlayerController LocalPlayer;

    PlaySound(Sound'KFWeaponSound.Bang1',,100.5*TransientSoundVolume);
    if (EffectIsRelevant(Location, false))
    {
        Spawn(class'KFMiniExplosion',,,HitLocation + HitNormal*20, rotator(HitNormal)+rot(-16384,0,0));
        LocalPlayer = Level.GetLocalPlayerController();
        if (LocalPlayer != None && LocalPlayer.ViewTarget != None
            && VSize(LocalPlayer.ViewTarget.Location - Location) < 5000)
            Spawn(class'ExplosionCrap',,,HitLocation + HitNormal*20, rotator(HitNormal));
    }

    BlowUp(HitLocation);

    LocalPlayer = Level.GetLocalPlayerController();
    for (C = Level.ControllerList; C != None; C = C.NextController)
    {
        if (PlayerController(C) != None && PlayerController(C).ViewTarget != None
            && VSize(Location - PlayerController(C).ViewTarget.Location) < DamageRadius)
            C.ShakeView(ShakeRotMag, ShakeRotRate, ShakeRotTime, ShakeOffsetMag, ShakeOffsetRate, ShakeOffsetTime);
    }

    Destroy();
}

simulated function BlowUp(vector HitLocation)
{
    HurtRadius(Damage, DamageRadius, ExplosiveDamageType, MomentumTransfer * 5, HitLocation);
    if (Role == ROLE_Authority)
        MakeNoise(1.0);
}

simulated function HitWall(vector HitNormal, actor Wall)
{
    Explode(Location + ExploWallOut * HitNormal, HitNormal);
}

// ProcessTouch lands the hit on every machine, a client's own bodies included, so the stock
// second hit on a client's body is left out.
simulated function ClientSideTouch(Actor Other, Vector HitLocation);

simulated function ProcessTouch(Actor Other, vector HitLocation)
{
    local vector X;

    if (Other == None || Other == Instigator || Other.Base == Instigator)
        return;

    if (KFHumanPawn(Other) != None && Instigator != None
        && KFHumanPawn(Other).PlayerReplicationInfo != None && KFHumanPawn(Other).PlayerReplicationInfo.Team != None
        && Instigator.PlayerReplicationInfo != None && Instigator.PlayerReplicationInfo.Team != None
        && KFHumanPawn(Other).PlayerReplicationInfo.Team.TeamIndex == Instigator.PlayerReplicationInfo.Team.TeamIndex)
        return;

    Explode(HitLocation, -X);
}

simulated function Landed(vector HitNormal)
{
    Explode(Location, HitNormal);
}

defaultproperties
{
    ExplosiveDamageType=Class'KFMod.DamTypeExplosiveShotgun'
    ShakeRotMag=(X=250,Y=0,Z=250)
    ShakeRotRate=(X=2500,Y=2500,Z=2500)
    ShakeRotTime=6.0
    ShakeOffsetMag=(X=0,Y=0,Z=8)
    ShakeOffsetRate=(X=100,Y=100,Z=100)
    ShakeOffsetTime=6.0
    Speed=8000.000000
    MaxSpeed=8000.000000
    Damage=60.000000
    DamageRadius=100.000000
    MomentumTransfer=10000.000000
    MyDamageType=Class'KFMod.DamTypeExplosiveShotgun'
    DrawType=DT_StaticMesh
    StaticMesh=StaticMesh'WeaponStaticMesh.FlakChunk'
    CullDistance=3000.000000
    LifeSpan=4.000000
    DrawScale=8.000000
    bNetTemporary=True
    Style=STY_Alpha
}
