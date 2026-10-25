//=============================================================================
// FlameGroundFire
// The fire the flamethrower's burning fuel makes where it comes to rest (Lay). It burns on fuel, counted in seconds
// of burning: fuel landing by a fire feeds it rather than starting another, so a spot held under the stream grows one
// fire up to 2.5 times its size and longer, and a sweep leaves a line of small ones. It burns faster on stone, metal
// and glass, slower on wood and grass, and not at all on water. On a wall or a ceiling it burns briefly and its fuel
// runs or drips down to the floor. On wood and grass it may light the ground beside it, twice over at most. It rides
// what it lies on. KFFlameFireControl does the harm: once a tick to each one standing in any of them.
//=============================================================================
class FlameGroundFire extends FuelFlameHurting;

var float	Fuel;
var() float	StartFuel, FeedFuel, MaxFuel;	// a new floor fire's, each landing's, the most a floor fire holds
var() float	WallFuel, WallMaxFuel;			// a wall or ceiling fire's
var() float	DropFuel;					// a fire started by fuel that fell or ran down
var() float	SurfaceBurn[11];			// fuel burnt a second on each surface (ESurfaceTypes)
var float	BurnRate;
var byte	Face;			// 0 floor, 1 wall, 2 ceiling
var byte	Surface;
var float	Size, ShownSize;	// 1 to 2.5 with its fuel; its flames and reach go with it
var() float	FlameRate, SmokeRate, EmberRate;	// a second, at size 1
var float	NextShed;		// a wall or ceiling fire: its fuel runs or drips down
var KFFlameFuelDrop	Shed;
var int		Generation;		// how many times fire spread to get here (wood, grass)
var float	NextCreep;
var() float	FlameLift;		// its flames rise from this far off the surface, at size 1 (lower, the floor cut them off)
var() class<Projector>	ScorchClass;

static function byte FaceOf( vector Normal )
{
	if ( Normal.Z >= 0.6 )
		return 0;
	if ( Normal.Z <= -0.6 )
		return 2;
	return 1;
}

// Burning fuel comes to rest at Spot on a surface facing Normal (on Base, when that can move): it feeds the fire there,
// or starts one with Start fuel (0: the usual for that surface). Each machine does this for itself.
static function Lay( Actor Spawner, vector Spot, vector Normal, Actor Base, optional float Start )
{
	local FlameGroundFire F, Best;
	local float D, BestD;
	local byte Face;

	Face = FaceOf(Normal);
	BestD = 100;
	foreach Spawner.RadiusActors(class'FlameGroundFire', F, 100, Spot)
		if ( !F.bDyingDown && !F.bDeleteMe && F.Face == Face )
		{
			D = VSize(F.Location - Spot);
			if ( D < F.FeedRadius() && D < BestD )
			{
				Best = F;
				BestD = D;
			}
		}
	if ( Best != None )
	{
		Best.AddFuel(default.FeedFuel);
		return;
	}
	F = Spawner.Spawn(class'FlameGroundFire', Spawner.Instigator,, Spot + Normal * 2, rotator(Normal));
	if ( F != None && !F.bDeleteMe )
	{
		if ( Start > 0 )
			F.Fuel = FMin(Start, F.MostFuel());
		if ( Base != None )
			F.RideOn(Base);
	}
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	Settle(vector(Rotation));
	if ( bDeleteMe )
		return;
	if ( Level.NetMode != NM_Client )
		class'KFFlameFireControl'.static.Add(self);
	Scorch();
}

// One mark for each fire, not for each landing (those stacked up black)
simulated function Scorch()
{
	if ( ScorchClass != None && Base == None && Level.NetMode != NM_DedicatedServer )
		Spawn(ScorchClass, self,, Location, rotator(-vector(Rotation)));
}

// What it burns on and how
simulated function Settle( vector Normal )
{
	local vector HL, HN;
	local Material Mat;
	local Actor A;

	Face = FaceOf(Normal);
	A = Trace(HL, HN, Location - Normal * 16, Location + Normal * 4, false,, Mat);
	if ( A != None && !A.IsA('LevelInfo') && A.SurfaceType != EST_Default )
		Surface = A.SurfaceType;
	else if ( Mat != None )
		Surface = Mat.SurfaceType;
	if ( Surface == 9 || PhysicsVolume.bWaterVolume )	// water
	{
		Destroy();
		return;
	}
	if ( Surface < ArrayCount(SurfaceBurn) )
		BurnRate = SurfaceBurn[Surface];
	else
		BurnRate = 1.0;
	if ( A != None )
		RideOn(A);
	if ( Face == 0 )
		Fuel = StartFuel;
	else
	{
		Fuel = WallFuel;
		NextShed = Level.TimeSeconds + 0.2;
	}
	ApplySize();
}

// A lift, a door, a prop: it goes where that goes
simulated function RideOn( Actor A )
{
	if ( A == None || A.bDeleteMe || Pawn(A) != None || A.IsA('LevelInfo') )
		return;
	if ( Mover(A) != None || (!A.bStatic && !A.bWorldGeometry) )
	{
		bHardAttach = true;
		SetBase(A);
	}
}

simulated function float MostFuel()
{
	if ( Face == 0 )
		return MaxFuel;
	return WallMaxFuel;
}

simulated function float FeedRadius()
{
	if ( Face == 0 )
		return 28 + 16 * Size;
	return 30;
}

simulated function AddFuel( float Amount )
{
	Fuel = FMin(Fuel + Amount, MostFuel());
}

simulated function bool BurnOut( float DT )
{
	Fuel -= DT * BurnRate;
	return Fuel <= 0;
}

simulated function Rate( int i, float PPS )
{
	if ( i < Emitters.Length && Emitters[i] != None )
	{
		Emitters[i].ParticlesPerSecond = PPS;
		Emitters[i].InitialParticlesPerSecond = PPS;
		if ( PPS > 0 )
			Emitters[i].AllParticlesDead = false;
	}
}

// Its flames, smoke, embers and reach for its size
simulated function ApplySize()
{
	local float S, G, F;

	ShownSize = Size;
	S = Size;
	if ( Face != 0 )
		S = 0.75;
	G = S ** 0.85;
	// (a bigger fire is more flames over more ground, more than bigger flames: one big ball otherwise)
	F = S ** 0.6;
	Emitters[0].StartSizeRange.X.Min = default.Emitters[0].StartSizeRange.X.Min * F;
	Emitters[0].StartSizeRange.X.Max = default.Emitters[0].StartSizeRange.X.Max * F;
	Emitters[0].StartSizeRange.Y.Min = default.Emitters[0].StartSizeRange.Y.Min * F;
	Emitters[0].StartSizeRange.Y.Max = default.Emitters[0].StartSizeRange.Y.Max * F;
	Emitters[0].StartLocationRange.X.Min = default.Emitters[0].StartLocationRange.X.Min * S;
	Emitters[0].StartLocationRange.X.Max = default.Emitters[0].StartLocationRange.X.Max * S;
	Emitters[0].StartLocationRange.Y.Min = default.Emitters[0].StartLocationRange.Y.Min * S;
	Emitters[0].StartLocationRange.Y.Max = default.Emitters[0].StartLocationRange.Y.Max * S;
	Emitters[0].StartLocationOffset = FlameLift * F * vector(Rotation);
	Emitters[1].StartSizeRange.X.Min = default.Emitters[1].StartSizeRange.X.Min * G;
	Emitters[1].StartSizeRange.X.Max = default.Emitters[1].StartSizeRange.X.Max * G;
	Emitters[1].StartLocationOffset.Z = default.Emitters[1].StartLocationOffset.Z * F;
	Emitters[2].SphereRadiusRange.Max = default.Emitters[2].SphereRadiusRange.Max * S;
	Rate(0, FlameRate * (0.5 + 0.5 * S));
	Rate(1, SmokeRate * (0.7 + 0.3 * S));
	Rate(2, EmberRate * S);
	DamageRadius = default.DamageRadius * (0.5 + 0.5 * S);
	FlameDamage = int(float(default.FlameDamage) * (0.6 + 0.4 * S) + 0.5);
}

simulated function Tick( float DT )
{
	Super.Tick(DT);
	if ( bDyingDown || bDeleteMe )
		return;
	if ( Face == 0 )
		Size = 1.0 + 1.5 * FClamp((Fuel - StartFuel) / (MaxFuel - StartFuel), 0.0, 1.0);
	if ( Abs(Size - ShownSize) > 0.05 )
		ApplySize();
	if ( Face != 0 && Level.TimeSeconds >= NextShed && Fuel > 0.4 && (Shed == None || Shed.bDeleteMe || Shed.bDone) )
		ShedFuel();
}

// Some of a wall fire's fuel runs down the wall, a ceiling fire's drips
simulated function ShedFuel()
{
	NextShed = Level.TimeSeconds + 0.35 + 0.2 * FRand();
	if ( Level.NetMode == NM_Client && !EffectIsRelevant(Location, false) )
		return;
	Fuel -= 0.3;
	if ( Face == 1 )
		Shed = class'KFFlameFuelDrop'.static.Drop(self, Location + vector(Rotation) * 4 - vect(0,0,10), vect(0,0,0), DropFuel, true, vector(Rotation));
	else
		Shed = class'KFFlameFuelDrop'.static.Drop(self, Location - vect(0,0,8), vect(0,0,-50), DropFuel);
}

simulated function Timer()
{
	if ( PhysicsVolume.bWaterVolume )
		return;
	if ( Level.NetMode == NM_Client )
	{
		class'KFMonster'.static.IgniteBodiesNear(self, DamageRadius, Location);
		return;
	}
	if ( Face == 0 && Generation < 2 && Fuel > 1.2 && (Surface == 4 || Surface == 5) && Level.TimeSeconds >= NextCreep )
	{
		NextCreep = Level.TimeSeconds + 0.8 + 0.6 * FRand();
		if ( FRand() < 0.5 )
			Creep();
	}
}

// The fire lights the wood or grass beside it, unless that burns already or enough burns near
function Creep()
{
	local vector Dir, P, HL, HN;
	local Material Mat;
	local Actor A;
	local FlameGroundFire F;
	local int n;
	local byte S;

	Dir = VRand();
	Dir.Z = 0;
	if ( VSize(Dir) < 0.1 )
		return;
	Dir = Normal(Dir);
	P = Location + Dir * (40 + 30 * FRand()) + vect(0,0,24);
	if ( !FastTrace(P, Location + vect(0,0,24)) )
		return;
	A = Trace(HL, HN, P - vect(0,0,72), P, false,, Mat);
	if ( A == None || HN.Z < 0.6 )
		return;
	if ( !A.IsA('LevelInfo') && A.SurfaceType != EST_Default )
		S = A.SurfaceType;
	else if ( Mat != None )
		S = Mat.SurfaceType;
	if ( S != 4 && S != 5 )	// wood, grass
		return;
	foreach RadiusActors(class'FlameGroundFire', F, 150, HL)
		if ( !F.bDyingDown )
		{
			if ( VSize(F.Location - HL) < 40 )
				return;
			if ( ++n >= 6 )
				return;
		}
	F = Spawn(class'FlameCreepFire', Instigator,, HL + HN * 2, rotator(HN));
	if ( F != None )
		F.Generation = Generation + 1;
}

defaultproperties
{
	StartFuel=2.100000
	FeedFuel=0.300000
	MaxFuel=6.000000
	WallFuel=1.200000
	WallMaxFuel=2.500000
	DropFuel=1.600000
	SurfaceBurn(0)=1.000000
	SurfaceBurn(1)=1.250000
	SurfaceBurn(2)=1.000000
	SurfaceBurn(3)=1.400000
	SurfaceBurn(4)=0.650000
	SurfaceBurn(5)=0.650000
	SurfaceBurn(6)=1.000000
	SurfaceBurn(7)=2.000000
	SurfaceBurn(8)=2.000000
	SurfaceBurn(9)=1.000000
	SurfaceBurn(10)=1.400000
	BurnRate=1.000000
	Size=1.000000
	FlameRate=18.000000
	SmokeRate=2.600000
	EmberRate=4.000000
	DieDownTime=1.800000
	FlameLift=20.000000
	ScorchClass=Class'KFMod.KFScorchMark'

	Begin Object Class=SpriteEmitter Name=GroundFireFlames
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		FadeOut=True
		FadeIn=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UseRandomSubdivision=True
		Acceleration=(Z=85.000000)
		ColorScale(0)=(Color=(B=40,G=90,R=200))
		ColorScale(1)=(RelativeTime=0.250000,Color=(B=150,G=225,R=255))
		ColorScale(2)=(RelativeTime=0.700000,Color=(B=40,G=135,R=255))
		ColorScale(3)=(RelativeTime=1.000000,Color=(B=10,G=30,R=110))
		ColorMultiplierRange=(Y=(Min=0.850000,Max=1.000000),Z=(Min=0.600000,Max=0.900000))
		FadeOutStartTime=0.600000
		FadeInEndTime=0.150000
		MaxParticles=48
		StartLocationRange=(X=(Min=-18.000000,Max=18.000000),Y=(Min=-18.000000,Max=18.000000),Z=(Max=8.000000))
		SpinsPerSecondRange=(X=(Min=-0.040000,Max=0.040000))
		StartSpinRange=(X=(Min=-0.060000,Max=0.060000))
		SizeScale(0)=(RelativeSize=0.700000)
		SizeScale(1)=(RelativeTime=0.250000,RelativeSize=1.000000)
		SizeScale(2)=(RelativeTime=1.000000,RelativeSize=0.400000)
		StartSizeRange=(X=(Min=26.000000,Max=36.000000),Y=(Min=40.000000,Max=56.000000))
		Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.750000,Max=1.200000)
		StartVelocityRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=18.000000,Max=55.000000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.FlameGroundFire.GroundFireFlames'

	Begin Object Class=SpriteEmitter Name=GroundFireSmoke
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		FadeOut=True
		FadeIn=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		Acceleration=(Z=20.000000)
		ColorScale(0)=(Color=(B=28,G=30,R=34,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=50,G=50,R=52,A=255))
		Opacity=0.500000
		FadeOutStartTime=1.200000
		FadeInEndTime=0.500000
		MaxParticles=14
		StartLocationOffset=(Z=70.000000)
		StartLocationShape=PTLS_Sphere
		SphereRadiusRange=(Max=15.000000)
		SpinsPerSecondRange=(X=(Min=-0.050000,Max=0.050000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.800000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.400000)
		StartSizeRange=(X=(Min=45.000000,Max=70.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'EmitterTextures.MultiFrame.smoke_a2'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=2.000000,Max=2.400000)
		StartVelocityRange=(X=(Min=-15.000000,Max=15.000000),Y=(Min=-15.000000,Max=15.000000),Z=(Min=50.000000,Max=90.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.FlameGroundFire.GroundFireSmoke'

	Begin Object Class=SpriteEmitter Name=GroundFireEmbers
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		FadeOut=True
		UniformSize=True
		Acceleration=(Z=60.000000)
		ColorScale(0)=(Color=(B=110,G=210,R=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=10,G=40,R=150))
		FadeOutStartTime=0.800000
		MaxParticles=16
		StartLocationShape=PTLS_Sphere
		SphereRadiusRange=(Max=25.000000)
		StartSizeRange=(X=(Min=3.000000,Max=5.000000))
		Texture=Texture'EmitterTextures.Flares.EFlareOY'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=1.000000,Max=1.600000)
		StartVelocityRange=(X=(Min=-30.000000,Max=30.000000),Y=(Min=-30.000000,Max=30.000000),Z=(Min=60.000000,Max=140.000000))
		DetailMode=DM_High
	End Object
	Emitters(2)=SpriteEmitter'KFMod.FlameGroundFire.GroundFireEmbers'
}
