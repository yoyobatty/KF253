//=============================================================================
class ShotgunExplosiveFire extends KFShotgunFire;

simulated function bool AllowFire()
{
    return false;
}

defaultproperties
{
    AmmoClass=Class'KFMod.ExplosiveShotgunAmmo'
    AmmoPerFire=1
    ProjectileClass=Class'KFMod.ExplosiveShotgunShell'
    FireRate=1.500000
    ProjPerFire=7
}
