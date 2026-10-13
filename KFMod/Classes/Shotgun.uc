//=============================================================================
// Shotgun Inventory class
//=============================================================================
class Shotgun extends KFWeaponShotgun;

// True while explosive shell mode is active
var bool bExplosiveMode;

// Saved state restored when switching back to regular mode
var Ammunition SavedRegularAmmo;
var int SavedClipLeft;

// Saved explosive tube state so switching away and back doesn't refill it
var int SavedExplosiveClipLeft;
var bool bHasExplosiveState;

// How many explosive shells the tube can hold at once
var() int ExplosiveClipCount;

replication
{
    reliable if (Role < ROLE_Authority)
        ServerChangeShotgunMode;
    reliable if (Role == ROLE_Authority)
        bExplosiveMode;
}

function bool RecommendLongRangedAttack()
{
    return true;
}

function byte BestMode()
{
    local Bot B;
    local float Dist;

    B = Bot(Instigator.Controller);
    if (B == None || B.Enemy == None)
        return 0;

    Dist = VSize(Instigator.Location - B.Enemy.Location);
    if (!bExplosiveMode && AmmoAmount(1) > 0 && Dist > 600.0)
    {
        bExplosiveMode = true;
        ApplyExplosiveMode(true);
    }
    else if (bExplosiveMode && (AmmoAmount(1) <= 0 || Dist < 400.0))
    {
        bExplosiveMode = false;
        ApplyExplosiveMode(false);
    }
    return 0;
}

// Right-click toggles fire mode instead of firing
simulated function AltFire(float F)
{
    DoToggle();
}

exec simulated function SwitchModes()
{
    DoToggle();
}

simulated function DoToggle()
{
    local PlayerController PC;

    if (IsFiring())
        return;

    PC = Level.GetLocalPlayerController();

    if (!bExplosiveMode)
    {
        // Require at least one explosive shell before switching
        if (Ammo[1] == None || Ammo[1].AmmoAmount <= 0)
        {
            if (PC != None)
                PC.ReceiveLocalizedMessage(class'KFMod.ShotgunModeSwitchMessage', 2);
            return;
        }
        bExplosiveMode = true;
        ApplyExplosiveMode(true);
        if (PC != None)
            PC.ReceiveLocalizedMessage(class'KFMod.ShotgunModeSwitchMessage', 0);
    }
    else
    {
        bExplosiveMode = false;
        ApplyExplosiveMode(false);
        if (PC != None)
            PC.ReceiveLocalizedMessage(class'KFMod.ShotgunModeSwitchMessage', 1);
    }

    Super.DoToggle();
    ServerChangeShotgunMode(bExplosiveMode);
}

simulated function ApplyExplosiveMode(bool bExplosive)
{
    if (bExplosive)
    {
        SavedRegularAmmo = Ammo[0];
        SavedClipLeft    = ClipLeft;

        // Redirect primary ammo slot to the explosive pool
        Ammo[0] = Ammo[1];

        // UpdateMagCapacity now routes through our override and sets ClipCount = ExplosiveClipCount
        if (Instigator != None)
            UpdateMagCapacity(Instigator.PlayerReplicationInfo);
        else
            ClipCount = ExplosiveClipCount;

        // Restore saved tube state, or fill to max on the very first entry
        if (bHasExplosiveState)
            ClipLeft = Min(SavedExplosiveClipLeft, Ammo[0].AmmoAmount);
        else
            ClipLeft = Min(Ammo[0].AmmoAmount, ClipCount);

        // Retune FireMode[0] for a single tight explosive shot
        ShotgunFire(FireMode[0]).ProjPerFire = 5;
    }
    else
    {
        // Remember exactly how many explosive shells are loaded so re-entry restores them
        SavedExplosiveClipLeft = ClipLeft;
        bHasExplosiveState = true;

        Ammo[0]  = SavedRegularAmmo;
        ClipLeft = SavedClipLeft;

        // Restore regular ClipCount (bExplosiveMode is already false so super path runs)
        if (Instigator != None)
            UpdateMagCapacity(Instigator.PlayerReplicationInfo);
        else
            ClipCount = default.ClipCount;

        // Restore FireMode[0] defaults
        FireMode[0].Spread      = FireMode[0].default.Spread;
        FireMode[0].SpreadStyle = FireMode[0].default.SpreadStyle;
        FireMode[0].FireRate    = FireMode[0].default.FireRate;
        ShotgunFire(FireMode[0]).ProjPerFire = ShotgunFire(FireMode[0]).default.ProjPerFire;
    }
}

simulated function InsertBullet()
{
    if (AmmoAmount(0) > 0 && ClipLeft < ClipCount)
        ClipLeft++;
    if (!bHoldToReload)
        ClientForceKFAmmoUpdate(ClipLeft, AmmoAmount(0));
}

function ServerChangeShotgunMode(bool bNewExplosiveMode)
{
    if (bExplosiveMode == bNewExplosiveMode)
        return;
    bExplosiveMode = bNewExplosiveMode;
    ApplyExplosiveMode(bExplosiveMode);
}

function DropFrom(vector StartLocation)
{
    if (bExplosiveMode && bCanThrow)
    {
        bExplosiveMode = false;
        ApplyExplosiveMode(false);
    }
    Super.DropFrom(StartLocation);
}

simulated function Destroyed()
{
    if (Role == ROLE_Authority && bExplosiveMode && SavedRegularAmmo != None)
    {
        bExplosiveMode = false;
        ApplyExplosiveMode(false);
    }
    Super.Destroyed();
}

simulated function UpdateMagCapacity(PlayerReplicationInfo PRI)
{
    if (bExplosiveMode)
    {
        ClipCount = ExplosiveClipCount;
        return;
    }
    Super.UpdateMagCapacity(PRI);
}

defaultproperties
{
    ExplosiveClipCount=4
    ClipCount=8
    ReloadRate=0.750000
    ReloadAnim="Reload"
    ReloadAnimRate=1.450000
    Weight=8.000000
    UpKick=900
    FireModeClass(0)=Class'KFMod.ShotgunFire'
    FireModeClass(1)=Class'KFMod.ShotgunExplosiveFire'
    PutDownAnim="PutDown"
    SelectSound=Sound'KFPlayerSound.getweaponout'
    AIRating=0.600000
    CurrentRating=0.600000
    bShowChargingBar=True
    OldCenteredOffsetY=0.000000
    OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
    OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
    OldPlayerViewPivot=(Pitch=400)
    Description="A rugged tactical pump action shotgun common to police divisions the world over. It accepts a maximum of 8 shells and can fire in rapid succession. "
    DisplayFOV=85.000000
    Priority=15
    SmallViewOffset=(X=-35.000000,Y=20.000000,Z=-10.000000)
    InventoryGroup=3
    GroupOffset=3
    PickupClass=Class'KFMod.ShotgunPickup'
    PlayerViewOffset=(X=4.000000,Y=5.500000,Z=-6.000000)
    PlayerViewPivot=(Pitch=400)
    BobDamping=4.000000
    AttachmentClass=Class'KFMod.ShotgunAttachment'
    IconCoords=(X1=169,Y1=172,X2=245,Y2=208)
    ItemName="Shotgun"
    Mesh=SkeletalMesh'KFWeaponModels.Shotgun'
    TransientSoundVolume=1.000000
    WallPivotRot=(Pitch=0,Yaw=0,Roll=0)
	WallPivotOffset=(x=-50,y=0,z=-10)
}
