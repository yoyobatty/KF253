//=============================================================================
// KFBFGLens
// The BFG ball bends the view round it the way a mass bends the light that passes it, and throbs with its plasma; when
// it bursts the pull surges for an instant and lets go. Ported from Vanilla Extract's gravity lens (VXDGravityLens),
// made a bubble round the ball instead of the whole view, and drawn by KFScreenFX with the blast waves it is one of.
//
// Seen from the eye, a thing that would have been seen at a slope of f from the line to the ball is seen at a slope
// s, where
//
//     f = s - E * E / s          E * E = 2 LightMass * Back / (D * (D + Back))
//
// D being how far off the ball is and Back how far behind it the thing is. E is the Einstein radius: the one point
// straight behind the ball is seen as a ring that wide; outside the ring everything is pushed outward, inside it is
// the far side, the other way up.
//
// A texture matrix can do nothing like one over s, but the lens is a model with texture coordinates: KFBFGLens.ase is
// a flat disc of rings whose every point carries where its light came from (Models/make_bfglens.py). The disc is held
// square to the line from the eye to the ball, a little way in front of the eye, sized so that its ring is E wide;
// the matrix has only to say where on the picture a place on the disc is, which from one flat thing to another a
// matrix can. The picture is the scene drawn again toward the ball, just wide enough for the disc, without the ball's
// own glow in it: that is drawn after the lens, over its middle. Each viewer's own, on Direct3D only.
//=============================================================================
class KFBFGLens extends KFWave;

#exec NEW StaticMesh File="..\KFMod254\KFMod\Models\KFBFGLens.ase" Name="KFBFGLens"

var BFGBall		Ball;
var() float		Near;				// how far in front of the eye the disc is drawn
var() float		Reach;				// how far behind the ball to look for what is seen round it
var() float		LightMass;			// how hard the ball bends light (its radius, were it a black hole)
var() float		Throb, ThrobRate;	// how much of that comes and goes with the plasma, and how often a second
var() float		GrowTime;			// how long the bend takes to come up after the shot
var() float		MaxRing;			// the widest the ring gets, as a slope
var() float		BurstGrow, BurstPeak, BurstTime;	// the burst: how much harder it pulls at its peak, when, and when it is gone
var float		Seen;				// 0 to 1: the ball can be seen from the eye
var float		Back;				// how far behind the ball what is seen round it is (eased)
var float		LastTime;
var bool		bBursting;
var float		Ring;				// (for a test's log) the ring's size in the last frame, as a slope
var vector		BurstSpot;

var ConstantColor	Tint;
var Combiner		Lit;

const RingUnit = 10.0;				// the model's units to an Einstein radius
const FarX = 400.0;					// where the model's far point is
const DiscOut = 8.0;				// the disc's rim, in Einstein radii

// A ball's lens, for the player at this machine if blast waves are on
static function KFBFGLens Make( BFGBall B )
{
	local PlayerController P;
	local KFScreenFX F;
	local KFBFGLens L;

	if ( B == None || B.Level.NetMode == NM_DedicatedServer )
		return None;
	P = B.Level.GetLocalPlayerController();
	if ( P == None )
		return None;
	F = class'KFFrameTap'.static.GetFX(P);
	if ( F == None || !F.bShockWaves || F.Waves.Length >= F.MaxWaves )
		return None;
	L = F.Spawn(class'KFBFGLens',,, B.Location);
	if ( L == None )
		return None;
	L.FX = F;
	L.Ball = B;
	F.Waves[F.Waves.Length] = L;
	return L;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	// (looked up by the model's own texture coordinates, not by where each point is)
	ViewCoords.TexCoordSource = TCS_Stream0;
	View.UClampMode = TC_Clamp;
	View.VClampMode = TC_Clamp;

	Tint = ConstantColor(Level.ObjectPool.AllocateObject(class'ConstantColor'));
	Tint.Color = class'Canvas'.static.MakeColor(255, 255, 255, 0);
	Lit = Combiner(Level.ObjectPool.AllocateObject(class'Combiner'));
	Lit.Material1 = ViewCoords;
	Lit.Material2 = Tint;
	Lit.Mask = None;
	Lit.CombineOperation = CO_Use_Color_From_Material1;
	Lit.AlphaOperation = AO_Use_Alpha_From_Material2;
	Lit.InvertMask = false;
	Lit.Modulate2X = false;
	Lit.Modulate4X = false;
	Blend.Material = Lit;
	Blend.ZTest = false;
}

// The ball has burst at Spot: the pull surges and goes
simulated function Burst( vector Spot )
{
	bBursting = true;
	BurstSpot = Spot;
	Age = 0.0;
	Ball = None;
}

simulated function Destroyed()
{
	if ( Lit != None )
	{
		Blend.Material = None;
		Lit.Material1 = None;
		Lit.Material2 = None;
		Level.ObjectPool.FreeObject(Lit);
		Level.ObjectPool.FreeObject(Tint);
		Lit = None;
	}
	// (the pool's objects go back as they were given)
	if ( ViewCoords != None )
	{
		ViewCoords.TexCoordSource = TCS_WorldCoords;
		View.UClampMode = TC_Wrap;
		View.VClampMode = TC_Wrap;
	}
	Super.Destroyed();
}

simulated function Tick( float DT )
{
	// (shown again by KFScreenFX if the next frame has it)
	bHidden = true;
	Age += DT;
	if ( bBursting )
	{
		if ( Age >= BurstTime )
			Destroy();
	}
	else if ( Ball == None || Ball.bDeleteMe )
		Destroy();
}

// How hard it bends light now
simulated function float MassNow()
{
	local float T;

	if ( bBursting )
	{
		if ( Age < BurstPeak )
			return LightMass * (1.0 + BurstGrow * Age / BurstPeak);
		T = FClamp((Age - BurstPeak) / (BurstTime - BurstPeak), 0.0, 1.0);
		return LightMass * (1.0 + BurstGrow) * Square(1.0 - T);
	}
	T = FMin(Age / GrowTime, 1.0);
	return LightMass * T * T * (3.0 - 2.0 * T) * (1.0 + Throb * Sin(Age * ThrobRate * 2.0 * Pi) * Sin(Age * ThrobRate * 1.3 * Pi));
}

simulated function bool FrameSetup( Canvas C, Actor CamActor, vector CamLocation, rotator CamRotation, float CamFOV )
{
	local vector Hole, A, X, Y, Z, HL, HN, S3;
	local float D, DT, B, E, S, HalfTan, Pixels, Angle, HalfView;
	local rotator Rot;
	local int FOV;

	if ( bBursting )
		Hole = BurstSpot;
	else if ( Ball != None && !Ball.bDeleteMe )
		Hole = Ball.Location;
	else
		return false;
	A = Hole - CamLocation;
	D = VSize(A);
	if ( D < 30.0 )
		return false;
	A = A / D;

	DT = FClamp(Level.TimeSeconds - LastTime, 0.0, 0.1);
	LastTime = Level.TimeSeconds;
	// (a wall between the eye and the ball: the bending goes, and comes back)
	if ( FastTrace(Hole, CamLocation) )
		Seen = FMin(1.0, Seen + 5.0 * DT);
	else
		Seen = FMax(0.0, Seen - 5.0 * DT);

	// how far behind the ball the things seen round it are
	B = Reach;
	if ( Trace(HL, HN, Hole + A * Reach, Hole, false) != None )
		B = VSize(HL - Hole);
	if ( Back <= 0.0 )
		Back = B;
	else
		Back += (B - Back) * FMin(1.0, 5.0 * DT);

	// the ring's size, as a slope from the line to the ball
	E = Sqrt(2.0 * MassNow() * Back / (D * (D + Back))) * Seen * (2.0 - Seen);
	E = FMin(E, MaxRing);
	Ring = E;
	if ( E < 0.004 )
		return false;

	// off the screen: nothing to bend
	Angle = Acos(FClamp(A dot vector(CamRotation), -1.0, 1.0));
	HalfView = Atan(Tan(CamFOV * Pi / 360.0) * Sqrt(1.0 + Square(float(C.SizeY) / float(C.SizeX))), 1.0);
	if ( Angle - Atan(DiscOut * E, 1.0) > HalfView )
		return false;

	// The picture: from the eye toward the ball, just wide enough for the disc, at about the screen's resolution
	FOV = Clamp(int(Atan(1.08 * DiscOut * E, 1.0) * 360.0 / Pi) + 2, 4, 150);
	HalfTan = Tan(FOV * Pi / 360.0);
	Pixels = HalfTan * C.SizeX / Tan(CamFOV * Pi / 360.0);
	if ( Pixels < 24.0 )
		return false;

	// The disc: a little way in front of the eye and square to the line to the ball, its ring as big as it is to
	// look. For the order things are drawn in it counts as being just beyond the ball, so the ball's glow is drawn
	// over it (the renderer goes by the middle of the model's box, and the model's far point is stretched to twice
	// that).
	Rot = rotator(A);
	GetAxes(Rot, X, Y, Z);
	S = Near * E / RingUnit;
	SetLocation(CamLocation + A * Near);
	SetRotation(Rot);
	SetDrawScale(S);
	S3.X = 2.0 * FMax(1.0, D + 8.0 - Near) / (FarX * S);
	S3.Y = 1.0;
	S3.Z = 1.0;
	SetDrawScale3D(S3);

	Tint.Color.A = 255;
	TakeView(CamActor, CamLocation, Rot, FOV, Min(int(Pixels) + 1, TextureSize));
	Lay(A, Y, Z, E);
	return true;
}

// Where on the picture a place on the disc is: for the model's texture coordinates (u, v), in Einstein radii from the
// disc's middle along its own Y and Z, the picture's (x * depth, y * depth, depth) of the way A + E * (u Y + v Z) from
// the eye. (A texture matrix is given a model's two coordinates as (u, v, 1, 0): the third row is what is added. It is
// put in the fourth as well, for a renderer that gives (u, v, 0, 1).)
simulated function Lay( vector A, vector Y, vector Z, float E )
{
	local vector PX, PY, PZ, U, V;
	local float HalfTan, Scale, Offset;
	local Matrix M;

	GetAxes(ViewRotation, PX, PY, PZ);
	HalfTan = Tan(ViewFOV * Pi / 360.0);
	Scale = float(ViewSize) / float(TextureSize);
	Offset = 0.5 * Scale + 0.5 / float(TextureSize);
	U = PY * (0.5 * Scale / HalfTan) + PX * Offset;
	V = PZ * (-0.5 * Scale / HalfTan) + PX * Offset;

	M.XPlane.X = E * (Y dot U);
	M.XPlane.Y = E * (Y dot V);
	M.XPlane.Z = E * (Y dot PX);
	M.YPlane.X = E * (Z dot U);
	M.YPlane.Y = E * (Z dot V);
	M.YPlane.Z = E * (Z dot PX);
	M.ZPlane.X = A dot U;
	M.ZPlane.Y = A dot V;
	M.ZPlane.Z = A dot PX;
	M.WPlane.X = M.ZPlane.X;
	M.WPlane.Y = M.ZPlane.Y;
	M.WPlane.Z = M.ZPlane.Z;
	M.WPlane.W = 1.0;
	ViewCoords.Matrix = M;
}

// The view drawn again for the lens, as the eye sees it (fog and all: the disc is drawn close to the eye), without
// the ball's own glow, which is drawn over the lens's middle afterwards
simulated event RenderTexture( ScriptedTexture Tex )
{
	local Actor Glow;
	local bool bWas;

	if ( ViewActor == None )
		return;
	if ( Ball != None )
		Glow = Ball.FX;
	if ( Glow != None )
	{
		bWas = Glow.bHidden;
		Glow.bHidden = true;
	}
	Tex.DrawPortal(0, 0, ViewSize, ViewSize, ViewActor, ViewLocation, ViewRotation, ViewFOV, true);
	if ( Glow != None )
		Glow.bHidden = bWas;
}

defaultproperties
{
	TextureSize=1024
	Near=64.000000
	Reach=3000.000000
	LightMass=5.600000
	Throb=0.220000
	ThrobRate=5.000000
	GrowTime=0.150000
	MaxRing=0.250000
	BurstGrow=3.500000
	BurstPeak=0.060000
	BurstTime=0.400000
	Duration=100.000000
	StaticMesh=StaticMesh'KFBFGLens'
	LifeSpan=12.000000
	// (blended by the tint's alpha, which is all of it: what is blended is drawn late, after the scene it bends)
	Style=STY_Alpha
}
