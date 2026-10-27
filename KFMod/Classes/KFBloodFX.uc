//=============================================================================
// KFBloodFX
// The blood thrown off a hit, made of the game's own blood pictures (KFX): a soft dark mist, droplets drawn along
// their flight, small tumbling flecks and, for a heavy blow, a short dark spatter. Thrown along Dir in a cone, the
// lot scaled by Size; the flecks and droplets fall. Made on each drawing machine by the hit's own effect
// (KFBloodPuff.Tick), in its first update (an emitter's layers are made then; what is thrown before is lost).
//=============================================================================
class KFBloodFX extends Emitter;

var vector	Dir;			// which way it is thrown
var float	Size;
var bool	bHeavy;			// (the spatter: a heavy blow's only)
var bool	bNoMist;		// (another hit's mist is already there: KFBloodPuff.Tick)
var bool	bThrown;
var() int	Counts[4];		// each layer's particles for a Size 1 hit
var() float	Speeds[4];		// ...how fast each flies along Dir
var() float	Spreads[4];		// ...and how far off it
var() float	UpLift;			// blood comes off a body a little upwards

simulated function Tick( float DT )
{
	local int i, j, n;
	local float K;
	local vector V;

	if ( bThrown )
	{
		Disable('Tick');
		return;
	}
	bThrown = true;
	if ( VSize(Dir) < 0.1 )
		Dir = vector(Rotation);
	Dir = Normal(Normal(Dir) + vect(0,0,1) * UpLift);
	K = Sqrt(FMax(Size, 0.1));
	for ( i = 0; i < Emitters.Length && i < ArrayCount(Counts); i++ )
	{
		n = int(Counts[i] * Size + FRand());
		if ( (i == 3 && !bHeavy) || (i == 0 && bNoMist) )
			n = 0;
		if ( n > 1 && (Level.bDropDetail || Level.DetailMode == DM_Low) )
			n = (n + 1) / 2;
		Emitters[i].StartSizeRange.X.Min *= K;
		Emitters[i].StartSizeRange.X.Max *= K;
		Emitters[i].StartSizeRange.Y.Min *= K;
		Emitters[i].StartSizeRange.Y.Max *= K;
		// (an emitter throws in the world's terms: each particle gets its own way out of the cone)
		for ( j = 0; j < n; j++ )
		{
			V = Normal(Dir + VRand() * Spreads[i]) * Speeds[i] * K * (0.55 + 0.7 * FRand());
			Emitters[i].StartVelocityRange.X.Min = V.X;
			Emitters[i].StartVelocityRange.X.Max = V.X;
			Emitters[i].StartVelocityRange.Y.Min = V.Y;
			Emitters[i].StartVelocityRange.Y.Max = V.Y;
			Emitters[i].StartVelocityRange.Z.Min = V.Z;
			Emitters[i].StartVelocityRange.Z.Max = V.Z;
			Emitters[i].SpawnParticle(1);
		}
	}
}

defaultproperties
{
	Counts(0)=2
	Counts(1)=7
	Counts(2)=4
	Counts(3)=1
	Speeds(0)=45.000000
	Speeds(1)=230.000000
	Speeds(2)=150.000000
	Speeds(3)=12.000000
	Spreads(0)=0.500000
	Spreads(1)=0.450000
	Spreads(2)=0.700000
	Spreads(3)=0.300000
	UpLift=0.350000

	// a soft dark mist where it struck, swelling and fading
	Begin Object Class=SpriteEmitter Name=BloodMist
		UseColorScale=True
		FadeOut=True
		FadeOutStartTime=0.100000
		RespawnDeadParticles=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		AutomaticInitialSpawning=False
		Acceleration=(Z=-60.000000)
		ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
		ColorMultiplierRange=(X=(Min=0.380000,Max=0.480000),Y=(Min=0.300000,Max=0.380000),Z=(Min=0.300000,Max=0.380000))
		MaxParticles=8
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-0.150000,Max=0.150000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.600000)
		StartSizeRange=(X=(Min=4.000000,Max=6.500000),Y=(Min=4.000000,Max=6.500000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'KFX.KFBloodPuff'
		LifetimeRange=(Min=0.400000,Max=0.600000)
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFBloodFX.BloodMist'

	// droplets, drawn along their flight, falling
	Begin Object Class=SpriteEmitter Name=BloodDrops
		UseDirectionAs=PTDU_Up
		FadeOut=True
		FadeOutStartTime=0.300000
		RespawnDeadParticles=False
		ScaleSizeYByVelocity=True
		AutomaticInitialSpawning=False
		Acceleration=(Z=-950.000000)
		ColorMultiplierRange=(X=(Min=0.480000,Max=0.620000),Y=(Min=0.420000,Max=0.520000),Z=(Min=0.420000,Max=0.520000))
		MaxParticles=24
		StartSizeRange=(X=(Min=6.000000,Max=9.000000),Y=(Min=6.000000,Max=9.000000))
		ScaleSizeByVelocityMultiplier=(Y=0.004000)
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'KFX.BloodDrops'
		LifetimeRange=(Min=0.450000,Max=0.700000)
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFBloodFX.BloodDrops'

	// small flecks, tumbling as they fall
	Begin Object Class=SpriteEmitter Name=BloodFlecks
		FadeOut=True
		FadeOutStartTime=0.350000
		RespawnDeadParticles=False
		SpinParticles=True
		UniformSize=True
		AutomaticInitialSpawning=False
		UseRandomSubdivision=True
		Acceleration=(Z=-800.000000)
		ColorMultiplierRange=(X=(Min=0.450000,Max=0.580000),Y=(Min=0.400000,Max=0.480000),Z=(Min=0.400000,Max=0.480000))
		MaxParticles=16
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-1.500000,Max=1.500000))
		StartSizeRange=(X=(Min=2.000000,Max=3.800000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'KFX.BloodSplash'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=0.500000,Max=0.800000)
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFBloodFX.BloodFlecks'

	// a heavy blow's dark spatter, gone in a moment
	Begin Object Class=SpriteEmitter Name=BloodSpatter
		FadeOut=True
		FadeOutStartTime=0.080000
		RespawnDeadParticles=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		AutomaticInitialSpawning=False
		ColorMultiplierRange=(X=(Min=1.000000,Max=1.000000),Y=(Min=1.000000,Max=1.000000),Z=(Min=1.000000,Max=1.000000))
		MaxParticles=2
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.600000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.600000)
		StartSizeRange=(X=(Min=10.000000,Max=14.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'KFX.BloodSplashHuge'
		LifetimeRange=(Min=0.180000,Max=0.260000)
	End Object
	Emitters(3)=SpriteEmitter'KFMod.KFBloodFX.BloodSpatter'

	bNoDelete=False
	RemoteRole=ROLE_None
	LifeSpan=2.000000
}
