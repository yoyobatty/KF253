//=============================================================================
// KFFlameFuelDrop
// Burning fuel on its way down: from where a tendril burnt out in the air or struck a body, or off a burning wall or
// ceiling. It falls (or runs down a wall it meets) and lays a fire where it comes to rest (FlameGroundFire.Lay).
// Each machine runs its own, as with the tendrils.
//=============================================================================
class KFFlameFuelDrop extends Emitter;

var float	Fuel;			// what it carries down
var bool	bRun;			// running down a wall, not falling
var vector	RunNormal;
var float	RunSpeed;
var float	NextWallCheck;
var bool	bDone;

// Off it goes from Spot at V; a run sets off down the wall facing Normal
static function KFFlameFuelDrop Drop( Actor Spawner, vector Spot, vector V, float Amount, optional bool bDownWall, optional vector Normal )
{
	local KFFlameFuelDrop D;

	D = Spawner.Spawn(class'KFFlameFuelDrop', Spawner.Instigator,, Spot);
	if ( D == None )
		return None;
	D.Fuel = Amount;
	if ( bDownWall )
		D.StartRun(Normal);
	else
	{
		D.SetPhysics(PHYS_Falling);
		D.Velocity = V;
	}
	return D;
}

simulated function StartRun( vector Normal )
{
	bRun = true;
	RunNormal = Normal;
	SetPhysics(PHYS_Projectile);
	Velocity = vect(0,0,-1) * RunSpeed;
	// (the burning streak it leaves stays on the wall a while)
	Emitters[0].LifetimeRange.Min = 0.5;
	Emitters[0].LifetimeRange.Max = 0.8;
	Emitters[0].StartVelocityRange.Z.Min = 5;
	Emitters[0].StartVelocityRange.Z.Max = 25;
}

simulated function Tick( float DT )
{
	local vector HL, HN;

	// a run that comes off the bottom of its wall falls
	if ( bRun && !bDone && Level.TimeSeconds >= NextWallCheck )
	{
		NextWallCheck = Level.TimeSeconds + 0.1;
		if ( Trace(HL, HN, Location - RunNormal * 16, Location, false) == None )
		{
			bRun = false;
			SetPhysics(PHYS_Falling);
			Velocity = vect(0,0,-1) * RunSpeed + RunNormal * 20;
		}
	}
}

simulated function Landed( vector HitNormal )
{
	Rest(HitNormal, None);
}

simulated singular function HitWall( vector HitNormal, Actor Wall )
{
	if ( bDone )
		return;
	if ( HitNormal.Z >= 0.6 )
		Rest(HitNormal, Wall);
	else if ( !bRun && HitNormal.Z > -0.4 )
	{
		SetLocation(Location + HitNormal * 4);
		StartRun(HitNormal);
	}
	else
		Rest(HitNormal, Wall);
}

simulated function Rest( vector HitNormal, Actor Wall )
{
	if ( bDone )
		return;
	bDone = true;
	if ( HitNormal.Z >= 0.6 && !PhysicsVolume.bWaterVolume )
		class'FlameGroundFire'.static.Lay(self, Location, HitNormal, Wall, Fuel);
	SetPhysics(PHYS_None);
	Velocity = vect(0,0,0);
	Kill();
	LifeSpan = 1.0;
}

simulated function PhysicsVolumeChange( PhysicsVolume NewVolume )
{
	if ( NewVolume.bWaterVolume )
	{
		bDone = true;
		Kill();
		LifeSpan = 1.0;
	}
}

defaultproperties
{
	RunSpeed=240.000000

	Begin Object Class=SpriteEmitter Name=DropFlames
		UseColorScale=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		Acceleration=(Z=40.000000)
		ColorScale(0)=(Color=(B=140,G=210,R=255))
		ColorScale(1)=(RelativeTime=0.400000,Color=(B=50,G=130,R=245))
		ColorScale(2)=(RelativeTime=0.800000,Color=(B=10,G=35,R=110))
		ColorScale(3)=(RelativeTime=1.000000)
		MaxParticles=24
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		ParticlesPerSecond=40.000000
		InitialParticlesPerSecond=40.000000
		SpinsPerSecondRange=(X=(Min=-0.300000,Max=0.300000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.700000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.400000)
		StartSizeRange=(X=(Min=8.000000,Max=14.000000))
		Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=0.250000,Max=0.450000)
		StartVelocityRange=(X=(Min=-8.000000,Max=8.000000),Y=(Min=-8.000000,Max=8.000000),Z=(Min=10.000000,Max=40.000000))
		SecondsBeforeInactive=0.000000
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFFlameFuelDrop.DropFlames'

	Begin Object Class=SpriteEmitter Name=DropCore
		UseColorScale=True
		UniformSize=True
		ColorScale(0)=(Color=(B=170,G=230,R=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=40,G=120,R=255))
		MaxParticles=6
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		ParticlesPerSecond=40.000000
		InitialParticlesPerSecond=40.000000
		StartSizeRange=(X=(Min=5.000000,Max=7.000000))
		Texture=Texture'EmitterTextures.Flares.EFlareOY'
		LifetimeRange=(Min=0.080000,Max=0.100000)
		SecondsBeforeInactive=0.000000
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFFlameFuelDrop.DropCore'

	bNoDelete=False
	bNotOnDedServer=False
	AutoDestroy=True
	LifeSpan=4.000000
	bCollideWorld=True
	bUseCylinderCollision=True
	CollisionRadius=2.000000
	CollisionHeight=2.000000
}
