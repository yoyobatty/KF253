class FleshPoundBoss extends ZombieFleshpound;

var int RageCount;              // Tracks how many times we've raged
var float LastGroundPoundTime;  // Cooldown for ground pound
var float GroundPoundRadius;    // AOE radius for ground pound
var int GroundPoundDamage;      // Damage for ground pound
var float GroundPoundForce;     // Knockback force for ground pound
var bool bEnraged;              // Permanent enrage below health threshold

// Boss-tier view shake (stronger than normal FP)
var() vector BossRotMag;
var() vector BossRotRate;
var() float  BossRotTime;
var() vector BossOffsetMag;
var() vector BossOffsetRate;
var() float  BossOffsetTime;

replication
{
    reliable if(Role == ROLE_Authority)
        bEnraged;
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
    Super.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType);

    // Permanent enrage below 40% health
    if( Health > 0 && Health < HealthMax * 0.4 && !bEnraged )
    {
        bEnraged = true;
        // Permanent speed and damage boost
        OriginalGroundSpeed *= 1.3;
        damageConst = damageConst * 1.5;
        damageRand = damageRand * 1.5;
        SpinDamConst *= 1.5;
        SpinDamRand *= 1.5;
        RageDamageThreshold *= 0.5; // Rages much more easily
    }
}

function RangedAttack(Actor A)
{
    local float Dist;

    if ( bShotAnim || Physics == PHYS_Swimming)
        return;

    Dist = VSize(A.Location - Location);

    // Ground pound AOE when multiple players are nearby
    if( Dist < GroundPoundRadius && Level.TimeSeconds > LastGroundPoundTime && !bDecapitated )
    {
        if( CountNearbyEnemies(GroundPoundRadius) >= 2 )
        {
            LastGroundPoundTime = Level.TimeSeconds + 12.0 + FRand() * 8.0;
            bShotAnim = true;
            Acceleration = vect(0,0,0);
            SetAnimAction('PoundRage');
            Controller.GoToState('WaitForAnim');
            KFMonsterController(Controller).bUseFreezeHack = True;
            GoToState('GroundPounding');
            return;
        }
    }

    // Normal melee if in range
    if( CanAttack(A) )
    {
        bShotAnim = true;
        SetAnimAction('Claw');
        PlaySound(sound'Claw2s', SLOT_None);
        return;
    }
}

function int CountNearbyEnemies(float Radius)
{
    local Controller C;
    local int Count;

    for( C = Level.ControllerList; C != None; C = C.NextController )
    {
        if( C.bIsPlayer && C.Pawn != None && C.Pawn.Health > 0
            && VSize(C.Pawn.Location - Location) < Radius )
        {
            Count++;
        }
    }
    return Count;
}

// AOE ground pound that damages and flings nearby players
function GroundPound()
{
    local Actor Victims;
    local float DamageScale, Dist;
    local vector Dir;
    local PlayerController PC;

    // Screen shake for all nearby players
    PC = Level.GetLocalPlayerController();
    if( PC != None && PC.ViewTarget != None && VSize(Location - PC.ViewTarget.Location) < GroundPoundRadius )
        PC.ShakeView(BossRotMag, BossRotRate, BossRotTime, BossOffsetMag, BossOffsetRate, BossOffsetTime);

    if( Level.NetMode == NM_Client )
        return;

    foreach VisibleCollidingActors(class'Actor', Victims, GroundPoundRadius, Location)
    {
        if( Victims == Self || Victims.IsA('KFMonster') || Victims.IsA('ExtendedZCollision')
            || Victims.IsA('FluidSurfaceInfo') )
            continue;

        Dir = Victims.Location - Location;
        Dist = FMax(1, VSize(Dir));
        Dir = Dir / Dist;
        DamageScale = 1.0 - FMax(0, (Dist - Victims.CollisionRadius) / GroundPoundRadius);

        // Upward knockback component
        Dir.Z = FMax(Dir.Z, 0.5);
        Dir = Normal(Dir);

        Victims.TakeDamage(
            DamageScale * GroundPoundDamage,
            Self,
            Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * Dir,
            DamageScale * GroundPoundForce * Dir,
            class'KFMod.DamTypePoundCrushed'
        );
    }
}

State GroundPounding
{
    Ignores StartCharging;

    function bool CanSpeedAdjust()
    {
        return false;
    }
    function Tick(float Delta)
    {
        Acceleration = vect(0, 0, 0);
        Global.Tick(Delta);
    }
Begin:
    Sleep(1.5);
    GroundPound();
    Sleep(0.5);
    GoToState('');
}

// Boss rage lasts longer and charges faster
State RageCharging
{
    function BeginState()
    {
        Super.BeginState();
        RageCount++;
    }
    function Tick(float Delta)
    {
        if( !bShotAnim )
        {
            // Boss charges faster than normal FP, and escalates with each rage
            SetGroundSpeed(OriginalGroundSpeed * FMin(2.5 + (RageCount * 0.2), 3.5));
            if( !bFrustrated && Level.TimeSeconds > RageStartTime )
                GoToState('');
        }
    }
    // Boss does massive damage on charge hit
    function bool MeleeDamageTarget(int hitdamage, vector pushdir)
    {
        local bool RetVal, bWasEnemy;

        bWasEnemy = (Controller.Target == Controller.Enemy);
        RetVal = Super(KFMonster).MeleeDamageTarget(hitdamage * 2.5, pushdir * 5);
        if( RetVal && bWasEnemy )
            GoToState('');
        return RetVal;
    }
}

// Override PostNetReceive to handle enraged visuals
simulated function PostNetReceive()
{
    Super.PostNetReceive();

    if( bEnraged && Health > 0 )
    {
        // Keep device red permanently when enraged
        DeviceGoRed();
    }
}

function bool FlipOver()
{
    return false;
}

defaultproperties
{
    RageDamageThreshold=150
    SpinDamConst=30.000000
    SpinDamRand=20.000000
    Intelligence=BRAINS_Human
    HeadHealth=1400.000000
    ScoringValue=350
    HealthMax=2500.000000
    Health=2500
    DrawScale=1.200000
    PrePivot=(Z=11.000000)
    MeleeRange=65.000000
    GroundSpeed=150.000000
    WaterSpeed=150.000000
    MenuName="Flesh Pound Boss"
    Skins(0)=Texture'22CharTex.GibletsSkin'
    GroundPoundRadius=500.000000
    GroundPoundDamage=40
    GroundPoundForce=80000.000000
    BossRotMag=(X=500.000000,Y=500.000000,Z=500.000000)
    BossRotRate=(X=500.000000,Y=500.000000,Z=500.000000)
    BossRotTime=3.000000
    BossOffsetMag=(X=40.000000,Y=40.000000,Z=40.000000)
    BossOffsetRate=(X=400.000000,Y=400.000000,Z=400.000000)
    BossOffsetTime=3.500000
    damageConst=35
    damageRand=25
    damageForce=25000
    BlockDamageReduction=0.300000
}