//=============================================================================
// Shotgun Fire
//=============================================================================
class ShotgunFire extends KFShotgunFire;

function DoFireEffect()
{
    local Shotgun S;
    S = Shotgun(Weapon);

    if (S != None && S.bExplosiveMode)
    {
        // Fire a single explosive shell instead of the normal pellet spread
        ProjectileClass = class'KFMod.ExplosiveShotgunShell';
    }
    else if (KFPawn(Instigator) != None && ClassIsChildOf(KFPawn(Instigator).GetVeteran(),class'KFVetFirebug'))
        ProjectileCLass = Class'KFMod.ShotgunBulletFire';
    else
        ProjectileCLass = default.ProjectileCLass;

    Super.DoFireEffect();
}

defaultproperties
{
     KickMomentum=(X=-85.000000,Z=15.000000)
     bRandomPitchFireSound=False
     ProjPerFire=12
     bAttachSmokeEmitter=True
     TransientSoundVolume=95.000000
     TransientSoundRadius=500.000000
     FireSound=Sound'KFWeaponSound.HuntingFire'
     FireRate=1.100000
     FireAnimRate=0.900000
     AmmoClass=Class'KFMod.ShotgunAmmo'
     ProjectileClass=Class'KFMod.ShotgunBullet'
     BotRefireRate=0.700000
     FlashEmitterClass=Class'KFMod.ShotgunMuzzFlash'
     aimerror=1.000000
     Spread=1250.000000
}
