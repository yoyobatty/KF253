//=============================================================================
// KFTraderTrail - the way to the trader drawn on the floor, after Dead Space's
// locator: a light runs from the player's feet along the walk to the trader,
// and the line it leaves fades out behind it. Only on the player's own machine
// (KFTraderPath). The line is a trail lying flat (MaxTrailTwistAngle 0).
// Tune with "set KFTraderTrail RunTime 2" and so on.
//=============================================================================
class KFTraderTrail extends Emitter;

#exec TEXTURE IMPORT NAME=TraderLine FILE=..\KFMod254\KFMod\Textures\TraderLine.tga VCLAMPMODE=CLAMP
#exec TEXTURE IMPORT NAME=TraderGlow FILE=..\KFMod254\KFMod\Textures\TraderGlow.tga UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP

var array<vector> Line;		// the way, a point every SampleStep, just above the floor
var array<float> LineAt;	// how far along the way each point is
var int At;					// the stretch of it the light is on
var float Run, Speed;		// how far the light has come, units a second
var bool bRunning;

var() float SampleStep;		// the floor is looked for this often along the way
var() float LineHeight;		// the line's height above it
var() float CornerRadius;	// corners turn as curves starting this far before them
var() int CornerSteps;
var() float RunTime;		// seconds the light takes to reach the trader, held within MinSpeed and MaxSpeed
var() float MinSpeed, MaxSpeed;
var() float TrailLife;		// seconds the line lasts after the light has passed
var() float HeadFade;		// seconds the light takes to go out at the trader
var() float MoteRate;		// sparks a second shed by the light
var() byte HeadLight;		// brightness of the light it casts round itself

// Draws the way through these points (at standing height: the player, path nodes)
simulated function Lay( array<vector> Route )
{
	local array<vector> Way;
	local float Travel;

	RoundCorners(Route, Way);
	ToFloor(Way);
	if ( Line.Length < 2 )
	{
		Destroy();
		return;
	}
	Speed = FClamp(LineAt[Line.Length-1] / RunTime, MinSpeed, MaxSpeed);
	Travel = LineAt[Line.Length-1] / Speed;
	SetLocation(Line[0]);
	TrailEmitter(Emitters[0]).PointLifeTime = TrailLife;
	Emitters[0].LifetimeRange.Min = Travel + TrailLife + 1;
	Emitters[0].LifetimeRange.Max = Emitters[0].LifetimeRange.Min;
	Emitters[0].SpawnParticle(1);
	Emitters[1].LifetimeRange.Min = Travel + HeadFade;
	Emitters[1].LifetimeRange.Max = Emitters[1].LifetimeRange.Min;
	Emitters[1].SpawnParticle(1);
	Emitters[2].InitialParticlesPerSecond = MoteRate;
	Emitters[2].ParticlesPerSecond = MoteRate;
	LightBrightness = HeadLight;
	bDynamicLight = (HeadLight > 0);
	bRunning = true;
}

// Way: the points with each corner turned as a curve
simulated function RoundCorners( array<vector> P, out array<vector> Way )
{
	local vector A, B;
	local float R, T;
	local int i, k;

	Way.Length = 0;
	Way[0] = P[0];
	for ( i=1; i<P.Length-1; i++ )
	{
		A = P[i-1] - P[i];
		B = P[i+1] - P[i];
		R = FMin(CornerRadius, 0.45 * FMin(VSize(A), VSize(B)));
		if ( R < 4 || (Normal(A) Dot Normal(B)) < -0.985 )
		{
			Way[Way.Length] = P[i];
			continue;
		}
		A = P[i] + Normal(A) * R;
		B = P[i] + Normal(B) * R;
		// (a curve from A to B that the corner pulls towards itself)
		for ( k=0; k<=CornerSteps; k++ )
		{
			T = float(k) / CornerSteps;
			Way[Way.Length] = (1-T)*(1-T)*A + 2*(1-T)*T*P[i] + T*T*B;
		}
	}
	Way[Way.Length] = P[P.Length-1];
}

// Line: the way with a point every SampleStep, each LineHeight above the floor under it. Steps and drops become slopes,
// never below the floor.
simulated function ToFloor( array<vector> Way )
{
	local array<vector> Spot;
	local array<float> Floor;
	local vector Leg;
	local float Len, Pos, Left, Z, Sum;
	local int i, j, n;

	Spot[0] = Way[0];
	Left = SampleStep;
	for ( i=0; i<Way.Length-1 && Spot.Length<1000; i++ )
	{
		Leg = Way[i+1] - Way[i];
		Len = VSize(Leg);
		Pos = 0;
		while ( Pos + Left <= Len )
		{
			Pos += Left;
			Spot[Spot.Length] = Way[i] + Leg * (Pos / Len);
			Left = SampleStep;
		}
		Left -= Len - Pos;
	}
	if ( VSize(Spot[Spot.Length-1] - Way[Way.Length-1]) > 4 )
		Spot[Spot.Length] = Way[Way.Length-1];

	// (with no floor found, as the last one; at the start, under the player's feet)
	Floor.Length = Spot.Length;
	for ( i=0; i<Spot.Length; i++ )
		if ( !FloorUnder(Spot[i], Floor[i]) )
		{
			if ( i > 0 )
				Floor[i] = Floor[i-1];
			else Floor[i] = Spot[i].Z - 50;
		}

	Line.Length = Spot.Length;
	LineAt.Length = Spot.Length;
	for ( i=0; i<Spot.Length; i++ )
	{
		Sum = 0;
		n = 0;
		for ( j=Max(0, i-2); j<=Min(Spot.Length-1, i+2); j++ )
		{
			Sum += Floor[j];
			n++;
		}
		Z = FMax(Floor[i], Sum / n);
		Line[i] = Spot[i];
		Line[i].Z = Z + LineHeight;
		if ( i == 0 )
			LineAt[i] = 0;
		else LineAt[i] = LineAt[i-1] + VSize(Line[i] - Line[i-1]);
	}
}

// Height of the floor under a spot at standing height
simulated function bool FloorUnder( vector Spot, out float Z )
{
	local vector HitLocation, HitNormal;

	if ( Trace(HitLocation, HitNormal, Spot - vect(0,0,200), Spot + vect(0,0,16), false) == None )
		return false;
	Z = HitLocation.Z;
	return true;
}

// The spot D along the line
simulated function vector PointAt( float D )
{
	while ( At < Line.Length-2 && LineAt[At+1] < D )
		At++;
	return Line[At] + (Line[At+1] - Line[At]) * ((D - LineAt[At]) / FMax(LineAt[At+1] - LineAt[At], 0.01));
}

simulated function Tick( float DeltaTime )
{
	// (the line begins where the light is when the engine starts it, so the light waits for that)
	if ( !bRunning || Emitters[0].ActiveParticles == 0 )
		return;
	Run += Speed * DeltaTime;
	if ( Run >= LineAt[Line.Length-1] )
	{
		SetLocation(Line[Line.Length-1]);
		bRunning = false;
		bDynamicLight = false;
		Kill();
		return;
	}
	SetLocation(PointAt(Run));
}

// Put out at once (a new line is being laid): what is drawn fades as it would
simulated function Stop()
{
	if ( !bRunning )
		return;
	bRunning = false;
	bDynamicLight = false;
	Emitters[1].Disabled = true;
	Kill();
}

defaultproperties
{
	Begin Object Class=TrailEmitter Name=LineTrail
		TrailShadeType=PTTST_PointLife
		TrailLocation=PTTL_FollowEmitter
		MaxPointsPerTrail=800
		DistanceThreshold=12.000000
		MaxTrailTwistAngle=0
		PointLifeTime=2.000000
		UseColorScale=True
		ColorScale(0)=(Color=(B=255,G=255,R=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255))
		MaxParticles=1
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		StartSizeRange=(X=(Min=9.000000,Max=9.000000),Y=(Min=9.000000,Max=9.000000),Z=(Min=9.000000,Max=9.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'KFMod.TraderLine'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=30.000000,Max=30.000000)
	End Object
	Emitters(0)=TrailEmitter'KFMod.KFTraderTrail.LineTrail'

	Begin Object Class=SpriteEmitter Name=HeadGlow
		CoordinateSystem=PTCS_Relative
		UseColorScale=True
		ColorScale(0)=(Color=(B=0,G=0,R=0))
		ColorScale(1)=(RelativeTime=0.040000,Color=(B=255,G=215,R=170))
		ColorScale(2)=(RelativeTime=0.880000,Color=(B=255,G=215,R=170))
		ColorScale(3)=(RelativeTime=1.000000,Color=(B=0,G=0,R=0))
		MaxParticles=1
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		StartLocationOffset=(Z=7.000000)
		UniformSize=True
		StartSizeRange=(X=(Min=20.000000,Max=20.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'KFMod.TraderGlow'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=2.000000,Max=2.000000)
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFTraderTrail.HeadGlow'

	Begin Object Class=SpriteEmitter Name=Motes
		UseColorScale=True
		ColorScale(0)=(Color=(B=255,G=200,R=130))
		ColorScale(1)=(RelativeTime=0.500000,Color=(B=200,G=140,R=70))
		ColorScale(2)=(RelativeTime=1.000000,Color=(B=0,G=0,R=0))
		MaxParticles=80
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		InitialParticlesPerSecond=0.000000
		ParticlesPerSecond=0.000000
		StartLocationShape=PTLS_Box
		StartLocationRange=(X=(Min=-5.000000,Max=5.000000),Y=(Min=-5.000000,Max=5.000000),Z=(Min=0.000000,Max=3.000000))
		StartVelocityRange=(X=(Min=-12.000000,Max=12.000000),Y=(Min=-12.000000,Max=12.000000),Z=(Min=8.000000,Max=30.000000))
		UniformSize=True
		StartSizeRange=(X=(Min=2.000000,Max=3.500000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'KFMod.TraderGlow'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.500000,Max=1.100000)
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFTraderTrail.Motes'

	SampleStep=24.000000
	LineHeight=3.000000
	CornerRadius=64.000000
	CornerSteps=5
	RunTime=2.500000
	MinSpeed=900.000000
	MaxSpeed=2000.000000
	TrailLife=2.000000
	HeadFade=0.250000
	MoteRate=45.000000
	HeadLight=90
	LightType=LT_Steady
	LightHue=150
	LightSaturation=90
	LightRadius=5.000000
	bDynamicLight=False
	bNoDelete=False
}
