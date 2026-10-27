//=============================================================================
// BFGFire
// The BFG 9000's fire: a charging whine, then the ball (BFGBall) with a crack and a kick. Unlike the LAW it was built on
// it fires from the hip, and has no back blast. A press starts the charge and the shot goes when it is done, held or let
// go (the LAW's wait for release left a press made during the cooldown and held doing nothing); held, it fires again
// each time it can.
//=============================================================================
class BFGFire extends LAWFire;

#exec OBJ LOAD FILE=..\Sounds\WeaponSounds.uax
#exec OBJ LOAD FILE=..\Sounds\ONSBPSounds.uax

var() Sound ChargeSound;
var bool bCharged;			// a press has started a charge: the shot goes at ChargeShotAt, held or not
var float ChargeShotAt;
var bool bWasFiring;

function bool AllowFire()
{
	return KFWeapon(Weapon).FireAmmo(ThisModeNum) >= AmmoPerFire;
}

// The charge: it is raised to the shoulder (from the hip) as it whines up
function PlayPreFire()
{
	if ( !KFWeapon(Weapon).bAimingRifle )
		Super.PlayPreFire();
	if ( ChargeSound != None )
		Weapon.PlayOwnedSound(ChargeSound, SLOT_Interact, 2.0,, 800, 1.1);
}

event ModeTick( float DT )
{
	Super.ModeTick(DT);
	// (a fresh press)
	if ( bIsFiring && !bWasFiring )
	{
		bCharged = true;
		ChargeShotAt = NextFireTime;
	}
	bWasFiring = bIsFiring;
	// let go before the charge was done: it goes anyway
	if ( bCharged && !bIsFiring && Level.TimeSeconds > ChargeShotAt )
	{
		bCharged = false;
		ModeDoFire();
	}
}

function ModeDoFire()
{
	bCharged = false;
	Super.ModeDoFire();
}

// (no LAW rocket to set alight)
function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
	return Super(KFShotgunFire).SpawnProjectile(Start, Dir);
}

defaultproperties
{
     ChargeSound=Sound'WeaponSounds.LightningGun.LightningGunChargeUp'
     FrontBlastRange=0.000000
     BackBlastRange=0.000000
     PreFireTime=0.850000
     bWaitForRelease=False
     PreFireAnim="raise"
     PreFireAnimRate=1.250000
     FireSound=Sound'ONSBPSounds.ShockTank.ShockBallFire'
     ProjectileClass=Class'KFMod.BFGBall'
     ProjSpawnOffset=(X=60.000000,Z=0.000000)
     AmmoClass=Class'KFMod.BFGAmmo'
     FireRate=1.500000
     Spread=0.010000
     KickMomentum=(X=-120.000000,Z=40.000000)
     ShakeRotMag=(X=200.000000,Y=200.000000,Z=200.000000)
     ShakeOffsetMag=(X=30.000000,Y=30.000000,Z=30.000000)
     BotRefireRate=0.900000
}
