//=============================================================================
// ShotgunBulletDragon
// A pellet of an upgraded pump shotgun (Dragon's Breath): it burns as it flies, heats a specimen it strikes until it
// catches fire (KFMonster.TakeIncendiary), and on a floor it leaves a little fire (FlameGroundFire), on each machine as
// the flamethrower's fuel does.
//=============================================================================
class ShotgunBulletDragon extends ShotgunBullet;

var Emitter FireTrail;
var() float MergeRadius;	// a floor fire this near takes its fuel instead of a fire of its own (Explode)

simulated function PostBeginPlay()
{
	Super(Projectile).PostBeginPlay();
	if ( Instigator != None )
		ShooterTeam = Instigator.GetTeamNum();
	Velocity = Speed * Vector(Rotation);
	if ( Level.NetMode != NM_DedicatedServer && !PhysicsVolume.bWaterVolume )
	{
		FireTrail = Spawn(class'KFDragonTrail', self);
		if ( FireTrail != None )
			FireTrail.SetBase(self);
	}
}

simulated function ProcessTouch( Actor Other, vector HitLocation )
{
	local KFMonster M;
	local int i;
	local bool bNew;

	M = KFMonster(Other);
	if ( M == None && ExtendedZCollision(Other) != None )
		M = KFMonster(Other.Owner);
	bNew = M != None;
	for ( i = 0; bNew && i < HurtPawns.Length; i++ )
		if ( HurtPawns[i] == M )
			bNew = false;
	Super.ProcessTouch(Other, HitLocation);
	if ( bNew && Role == ROLE_Authority && M.Health > 0 )
		M.TakeIncendiary(2, Instigator);
}

// It struck a wall or a floor (ShotgunBullet.HitWall): a floor takes a little fire, or feeds one the blast's other
// pellets laid near by (one blast's twelve laid up to eight fires of their own)
simulated function Explode( vector HitLocation, vector HitNormal )
{
	local FlameGroundFire F, Near;

	if ( HitNormal.Z >= 0.6 && !PhysicsVolume.bWaterVolume && (Level.NetMode != NM_Client || EffectIsRelevant(Location, false)) )
	{
		foreach RadiusActors(class'FlameGroundFire', F, MergeRadius)
			if ( !F.bDyingDown && !F.bDeleteMe && F.Face == 0 )
				Near = F;
		if ( Near != None )
			Near.AddFuel(class'FlameGroundFire'.default.FeedFuel);
		else
			class'FlameGroundFire'.static.Lay(self, Location, HitNormal, None, 0.9);
	}
	Super.Explode(HitLocation, HitNormal);
}

simulated function Destroyed()
{
	if ( FireTrail != None )
	{
		FireTrail.SetBase(None);
		FireTrail.Kill();
	}
	Super.Destroyed();
}

defaultproperties
{
     MergeRadius=90.000000
}
