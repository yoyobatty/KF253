//=============================================================================
// BoomStick Fire: one barrel. BoomStickAltFire fires both.
//=============================================================================
class BoomStickFire extends KFShotgunFire;

var() bool bBothBarrels;               // this mode fires both barrels
var() class<Projectile> SlugClass;     // projectile when slugs are loaded
var() name BothAnim, RightAnim, LeftAnim;
var() float BothFireRate;              // delay after a both-barrel shot
var() float SingleKick;                // view kick of one barrel as a fraction of both
var() float SingleSoundPitch;          // one barrel sounds lighter
var bool bFiringBoth;                  // the shot being fired uses both barrels

simulated function bool AllowFire()
{
	local KFWeapon W;

	W = KFWeapon(Weapon);
	if ( W == None || W.bIsReloading || Clip() < 1 )
		return false;
	if ( KFPawn(Instigator) != None && (KFPawn(Instigator).SecondaryItem != None || KFPawn(Instigator).bThrowingNade) )
		return false;
	return KFWeapon(Weapon).FireAmmo(ThisModeNum) > 0;
}

// Shells loaded for this shot (KFWeapon.FireClip: on a network client, those at the press)
simulated function int Clip()
{
	return KFWeapon(Weapon).FireClip(ThisModeNum);
}

function float MaxRange()
{
	if ( ProjectileClass == SlugClass )
		return 3000;
	return 1500;
}

// Buckshot or slugs for this mode's next shots.
function SetShells(bool bSlugs, int SlugsPerShell)
{
	if ( bSlugs )
	{
		ProjectileClass = SlugClass;
		ProjPerFire = SlugsPerShell;
		SpreadStyle = SS_Line;
	}
	else
	{
		ProjectileClass = default.ProjectileClass;
		ProjPerFire = default.ProjPerFire;
		SpreadStyle = default.SpreadStyle;
	}
	SavedFireProperties.bInitialized = false;
}

event ModeDoFire()
{
	local KFWeapon W;

	if ( !AllowFire() )
		return;

	W = KFWeapon(Weapon);
	bFiringBoth = Clip() > 1 && (bBothBarrels || (BoomStick(Weapon) != None && BoomStick(Weapon).BotWantsBoth()));
	if ( bFiringBoth )
	{
		Load = 2;
		FireAnim = BothAnim;
	}
	else
	{
		Load = 1;
		if ( Clip() > 1 )
			FireAnim = RightAnim;     // the right barrel goes first
		else
			FireAnim = LeftAnim;
	}

	Super.ModeDoFire();

	// a bot's both-barrel shot comes from the single-barrel mode
	if ( bFiringBoth && !bBothBarrels )
		NextFireTime += BothFireRate - default.FireRate;
}

function PlayFiring()
{
	if ( Weapon.Mesh != None )
		Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
	Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,FireSoundPitch(),false);
	ClientPlayForceFeedback(FireForce);
	FireCount++;
}

function ServerPlayFiring()
{
	Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,FireSoundPitch(),false);
}

function float FireSoundPitch()
{
	local float Pitch;

	Pitch = 1.0 + RandomPitchAdjustAmt * (2.0 * FRand() - 1.0);
	if ( !bFiringBoth )
		Pitch *= SingleSoundPitch;
	return Pitch;
}

// The parent skips the shake once the gun is empty, which here is every both-barrel shot.
function ShakeView()
{
	Super(WeaponFire).ShakeView();
}

function HandleRecoil()
{
	if ( bFiringBoth )
		KickScale = 1.0;
	else
		KickScale = SingleKick;
	Super.HandleRecoil();
}

function DoFireEffect()
{
    local Vector StartProj, StartTrace, X,Y,Z;
    local Rotator R, Aim;
    local Vector HitLocation, HitNormal;
    local Actor Other;
    local int p;
    local int SpawnCount;

    Instigator.MakeNoise(1.0);
    Weapon.GetViewAxes(X,Y,Z);

    StartTrace = Instigator.Location + Instigator.EyePosition();// + X*Instigator.CollisionRadius;
    StartProj = StartTrace + X*ProjSpawnOffset.X;
    if ( !Weapon.WeaponCentered() )
	    StartProj = StartProj + Weapon.Hand * Y*ProjSpawnOffset.Y + Z*ProjSpawnOffset.Z;

    // check if projectile would spawn through a wall and adjust start location accordingly
    Other = Weapon.Trace(HitLocation, HitNormal, StartProj, StartTrace, false);
    if (Other != None)
    {
        StartProj = HitLocation;
    }

    Aim = AdjustAim(StartProj, AimError);

    SpawnCount = Max(1, ProjPerFire * int(Load));

    switch (SpreadStyle)
    {
    case SS_Random:
        X = Vector(Aim);
        for (p = 0; p < SpawnCount; p++)
        {
            R.Yaw = Spread * (FRand()-0.5);
            R.Pitch = Spread * (FRand()-0.5);
            R.Roll = Spread * (FRand()-0.5);
            SpawnProjectile(StartProj, Rotator(X >> R));
        }
        break;
    case SS_Line:
        X = Vector(Aim);
        for (p = 0; p < SpawnCount; p++)
        {
            R.Yaw = Spread * ((FRand()-0.5) * 0.1);
            R.Pitch = 0;
            R.Roll = 0;
            SpawnProjectile(StartProj, Rotator(X >> R));
        }
        break;
    default:
        SpawnProjectile(StartProj, Aim);
    }
}

defaultproperties
{
    SlugClass=Class'KFMod.BoomStickSlug'
    BothAnim="Fire"
    RightAnim="FireRight"
    LeftAnim="FireLeft"
    BothFireRate=0.500000
    SingleKick=0.600000
    SingleSoundPitch=1.120000
    KickMomentum=(X=-105.000000,Z=55.000000)
    ProjPerFire=20
    bAttachSmokeEmitter=True
    TransientSoundVolume=150.000000
    TransientSoundRadius=500.000000
    FireSound=Sound'KFWeaponSound.DBFire'
    FireRate=0.350000
    TweenTime=0.020000
    AmmoClass=Class'KFMod.DBShotgunAmmo'
    AmmoPerFire=1
    ProjectileClass=Class'KFMod.BoomStickBullet'
    BotRefireRate=0.700000
    FlashEmitterClass=Class'KFMod.ShotgunMuzzFlash'
    aimerror=2.000000
    Spread=2500.000000
}
