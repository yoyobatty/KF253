//=============================================================================
// BoomStick Fire
//=============================================================================
class BoomStickFire extends KFShotgunFire;

simulated function bool AllowFire()
{
	return ( Weapon.AmmoAmount(ThisModeNum) >= AmmoPerFire);
}

function float MaxRange()
{
	return 1500;
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
    KickMomentum=(X=-105.000000,Z=55.000000)
    ProjPerFire=20
    bAttachSmokeEmitter=True
    TransientSoundVolume=150.000000
    TransientSoundRadius=500.000000
    FireSound=Sound'KFWeaponSound.DBFire'
    FireRate=2.500000
    AmmoClass=Class'KFMod.DBShotgunAmmo'
    AmmoPerFire=2
    ProjectileClass=Class'KFMod.BoomStickBullet'
    BotRefireRate=0.700000
    FlashEmitterClass=Class'KFMod.ShotgunMuzzFlash'
    aimerror=2.000000
    Spread=2500.000000
}
