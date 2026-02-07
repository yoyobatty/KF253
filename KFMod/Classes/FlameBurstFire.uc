//
//=============================================================================
<<<<<<< HEAD
class FlameBurstFire extends CrossbowFire ;
=======
class FlameBurstFire extends CrossbowFire;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

var byte FlockIndex;
var int MaxLoad;

function Recoil( float Multi );

simulated function bool AllowFire()
{
	if(KFWeapon(Weapon).bIsReloading)
		return false;
	if(KFWeapon(Weapon).ClipLeft < 1)
	{
		if(Level.TimeSeconds - LastClickTime > FireRate)
		{
			Weapon.PlayOwnedSound(NoAmmoSound, SLOT_Interact, TransientSoundVolume,,,, false);
			LastClickTime = Level.TimeSeconds;
			if(Weapon.HasAnim(EmptyAnim))
				weapon.PlayAnim(EmptyAnim, EmptyAnimRate, 0.0);
		}
		return false;
	}
	LastClickTime = Level.TimeSeconds;
	return Super.AllowFire();
}

function DoFireEffect()
{
    local Vector StartProj, StartTrace, X,Y,Z;
    local Rotator Aim;
    local Vector HitLocation, HitNormal,FireLocation;
    local Actor Other;
    local int p, SpawnCount;
    local FlameTendril FiredRockets[4];

    if ( (SpreadStyle == SS_Line) || (Load < 2) )
    {
        Super.DoFireEffect();
        return;
    }
    
    Instigator.MakeNoise(1.0);
    Weapon.GetViewAxes(X,Y,Z);

    StartTrace = Instigator.Location + Instigator.EyePosition();
    StartProj = StartTrace + X*ProjSpawnOffset.X + Z*ProjSpawnOffset.Z;
    if ( !Weapon.WeaponCentered() )
        StartProj = StartProj + Weapon.Hand * Y*ProjSpawnOffset.Y;

    // check if projectile would spawn through a wall and adjust start location accordingly
    Other = Weapon.Trace(HitLocation, HitNormal, StartProj, StartTrace, false);
    if (Other != None)
    {
        StartProj = HitLocation;
    }
    
    Aim = AdjustAim(StartProj, AimError);

	SpawnCount = Max(1, int(Load));

	for ( p=0; p<SpawnCount; p++ )
	{
		Firelocation = StartProj - 2*((Sin(p*2*PI/MaxLoad)*8 - 7)*Y - (Cos(p*2*PI/MaxLoad)*8 - 7)*Z) - X * 8 * FRand();
		FiredRockets[p] = FlameTendril(SpawnProjectile(FireLocation, Aim));
	}
}

function float MaxRange()
{
<<<<<<< HEAD
    return 1500;
=======
    return 2000;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

defaultproperties
{
<<<<<<< HEAD
	MaxLoad=3
	EffectiveRange=1500.000000
	ProjSpawnOffset=(X=0.000000)
	bSplashDamage=True
	bRecommendSplashDamage=True
	bAttachSmokeEmitter=True
	TransientSoundVolume=95.000000
	TransientSoundRadius=500.000000
	FireSound=Sound'KFWeaponSound.FlameThrowerFire'
	FireRate=0.070000
	AmmoClass=Class'KFMod.FlameAmmo'
	ShakeRotMag=(X=0.000000,Y=0.000000,Z=0.000000)
	ShakeRotRate=(X=0.000000,Y=0.000000,Z=0.000000)
	ShakeOffsetMag=(X=0.000000,Y=0.000000,Z=0.000000)
	ShakeOffsetRate=(X=0.000000,Y=0.000000,Z=0.000000)
	ProjectileClass=Class'KFMod.FlameTendril'
	BotRefireRate=0.070000
	FlashEmitterClass=Class'KFMod.KFFlameMuzzFlash'
	aimerror=0.000000
	Spread=0.000000
	SpreadStyle=SS_Random
=======
    MaxLoad=3
    ProjSpawnOffset=(X=65.000000,Y=10.000000,Z=-15.000000)
    bSplashDamage=True
    bRecommendSplashDamage=True
    bAttachSmokeEmitter=True
    TransientSoundVolume=95.000000
    TransientSoundRadius=500.000000
    FireSound=Sound'KFWeaponSound.FlameThrowerFire'
    FireRate=0.070000
    AmmoClass=Class'KFMod.FlameAmmo'
    ShakeRotMag=(X=0.000000,Y=0.000000,Z=0.000000)
    ShakeRotRate=(X=0.000000,Y=0.000000,Z=0.000000)
    ShakeOffsetMag=(X=0.000000,Y=0.000000,Z=0.000000)
    ShakeOffsetRate=(X=0.000000,Y=0.000000,Z=0.000000)
    ProjectileClass=Class'KFMod.FlameTendril'
    BotRefireRate=0.990000
    FlashEmitterClass=Class'KFMod.KFFlameMuzzFlash'
    aimerror=0.000000
    Spread=0.000000
    SpreadStyle=SS_Random
    bWaitForRelease=False
    ViewPunchDamping=4.000000
    ViewPunchSpring=50.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
