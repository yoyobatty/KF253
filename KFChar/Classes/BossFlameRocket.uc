// The Patriarch's flame rocket: a smaller blast that sets the ground round it alight (the incendiary grenade's fires),
// with a trail of fire to tell it by
class BossFlameRocket extends BossLAWProj;

var() int GroundFires;					// fires left round where it lands, besides the one at its heart
var() float FireSpreadMin, FireSpreadMax;	// how far from where it lands they go
var Emitter FlameTrail;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( Level.NetMode != NM_DedicatedServer && !PhysicsVolume.bWaterVolume )
		FlameTrail = Spawn(class'FlameThrowerFlameB', self);
}

simulated function Destroyed()
{
	if ( FlameTrail != None )
		FlameTrail.Kill();
	Super.Destroyed();
}

simulated function Explode( vector HitLocation, vector HitNormal )
{
	class'KFBlastSound'.static.Play(self, sound'KFWeaponSound.FlameThrowerFire', 2.0*TransientSoundVolume);
	class'KFBlastSound'.static.Play(self, sound'ONSVehicleSounds-S.TankFire01', 0.6*TransientSoundVolume);
	if ( Role == ROLE_Authority )
		class'KFFarSound'.static.Loud(self, HitLocation + HitNormal*24, FAR_Blast);
	if ( EffectIsRelevant(Location, false) )
	{
		Spawn(class'KFIncendiaryExplosion',,, HitLocation + HitNormal*16, rotator(vect(0,0,1)));
		if ( ExplosionDecal != None && Level.NetMode != NM_DedicatedServer )
			Spawn(ExplosionDecal, self,, Location, rotator(-HitNormal));
	}
	if ( Role == ROLE_Authority )
		SpawnGroundFires(HitLocation + HitNormal*16);
	BlowUp(HitLocation);
	Destroy();
}

// One fire where it lands and GroundFires round it, each on the floor below its spot
function SpawnGroundFires( vector Centre )
{
	local int i;
	local float Angle;
	local vector Spot, HitLocation, HitNormal;
	local Actor A;

	for ( i = 0; i <= GroundFires; i++ )
	{
		Spot = Centre;
		if ( i > 0 )
		{
			Angle = 2 * Pi * (float(i) + FRand() * 0.4) / GroundFires;
			Spot += (vect(1,0,0) * Cos(Angle) + vect(0,1,0) * Sin(Angle)) * RandRange(FireSpreadMin, FireSpreadMax);
		}
		if ( Trace(HitLocation, HitNormal, Spot - vect(0,0,512), Spot + vect(0,0,128), false) == None )
			continue;
		A = Spawn(class'KFMod.KFNadeFire', Instigator,, HitLocation + vect(0,0,5), rotator(HitNormal));
		if ( A != None )
			A.RemoteRole = ROLE_SimulatedProxy;
	}
}

defaultproperties
{
	GroundFires=5
	FireSpreadMin=60.000000
	FireSpreadMax=170.000000
	Speed=2000.000000
	MaxSpeed=2200.000000
}
