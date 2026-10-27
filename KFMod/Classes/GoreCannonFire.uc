//=============================================================================
// GoreCannonFire
// The Gore Cannon's fire button: the last thing it swallowed thrown out (GoreCannon.TakeRound): a body whole
// (KFGoreBodyShot), or a meat round as a spread of giblets (KFGoreGibShot). From the hip, held down it keeps throwing.
//=============================================================================
class GoreCannonFire extends KFShotgunFire;

#exec OBJ LOAD FILE=..\Sounds\WeaponSounds.uax

var() int	GibCount;		// giblets in a meat round
var() int	GibSpread;		// ...across how much, in rotation units

function projectile SpawnProjectile( Vector Start, Rotator Dir )
{
	local GoreCannon W;
	local class<KFMonster> B;
	local KFGoreBodyShot S;
	local Projectile P;
	local rotator R;
	local int i;

	W = GoreCannon(Weapon);
	if ( W == None )
		return None;
	B = W.TakeRound();
	if ( B != None )
	{
		S = Weapon.Spawn(class'KFGoreBodyShot', Instigator,, Start, Dir);
		if ( S != None )
			S.Carry(B);
		return S;
	}
	for ( i = 0; i < GibCount; i++ )
	{
		R = Dir;
		R.Yaw += int((FRand() - 0.5) * GibSpread);
		R.Pitch += int((FRand() - 0.5) * GibSpread);
		P = Weapon.Spawn(class'KFGoreGibShot', Instigator,, Start, R);
	}
	return P;
}

defaultproperties
{
     GibCount=6
     GibSpread=2400
     ProjPerFire=1
     ProjSpawnOffset=(X=40.000000,Z=-6.000000)
     bWaitForRelease=False
     FireAnim="Idle"
     FireSound=Sound'WeaponSounds.BaseFiringSounds.BBioRifleFire'
     FireRate=0.550000
     AmmoClass=Class'KFMod.GoreAmmo'
     AmmoPerFire=1
     ProjectileClass=Class'KFMod.KFGoreGibShot'
     KickMomentum=(X=-80.000000,Z=30.000000)
     ShakeRotMag=(X=150.000000,Y=150.000000,Z=150.000000)
     ShakeOffsetMag=(X=20.000000,Y=20.000000,Z=20.000000)
     Spread=0.010000
     BotRefireRate=0.700000
     TransientSoundVolume=2.000000
}
