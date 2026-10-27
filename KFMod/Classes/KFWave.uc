//=============================================================================
// KFWave
// The wave a blast throws out (KFBlast): the air bends round the burst as it runs out, pushing what is seen through it
// outward. Ported from Vanilla Extract's shock wave (VXShockwave, VXViewPicture).
//
// The wave is a sphere growing round the burst. What shows of it is its rim as the viewer sees it: a ring that faces
// them, wearing a picture of the scene behind it, so that a flat ring would change nothing on screen. The ring's mesh
// bulges toward the viewer across its width, and the picture is pulled toward the ring's centre by a point's height
// above the ring's plane: it bends where the mesh bulges, most just behind the front of the wave, and joins the scene
// at both edges.
//
// The picture is the scene drawn again from the viewer's eye into a ScriptedTexture, laid back on with projected
// texture coordinates worked out from where each point is in the world. It must not have the waves in it, and a
// texture matrix is read before a ScriptedTexture's owner is asked to draw it; so neither is left to the moment the wave
// itself is drawn: KFScreenFX.DoWaves sets every one up before each frame (FrameSetup) and has the pictures taken then,
// with all of them hidden. While a wave is in view the part of the scene behind it is drawn twice; one behind a wall
// costs nothing. Each viewer's own, on Direct3D only (as the other screen effects).
//=============================================================================
class KFWave extends Actor;

#exec NEW StaticMesh File="..\KFMod254\KFMod\Models\KFWaveRing.ase" Name="KFWaveRing"
#exec TEXTURE IMPORT NAME=KFWaveMask FILE=..\KFMod254\KFMod\Textures\KFWaveMask.tga MIPS=OFF ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP

var() int	TextureSize;
var() float	StartRadius, EndRadius;	// the wave's radius at its start and at its end
var() float	Duration;
var() float	Strength;				// how far the view is pulled toward the centre at the start, as a part of the ring's radius
var() float	RingScale;				// the ring's outer edge, as a part of the rim's radius
var() float	FadeFrom, FadeOver;		// the wave begins to fade this part of the way to the viewer, and is gone this much further on

var KFScreenFX		FX;				// the viewer's screen effects, which set it up each frame
var vector			Centre;
var float			Age;
var float			PlacedTime;		// level time of the last frame the ring was placed for
var bool			bShown;			// (set by KFScreenFX from FrameSetup: the wave is in this frame)
var bool			bNeedsView;		// (set by TakeView: View has to be drawn for this frame)

var ScriptedTexture	View;			// the picture
var TexMatrix		ViewCoords;		// world position to View coordinates
var FinalBlend		Unseen;			// draws View without changing the screen (KFScreenFX does, to have it drawn)
var TexMatrix		MaskCoords;		// slides the mask to fade the ring
var Combiner		Masked;			// View's colour with the mask's alpha
var FinalBlend		Blend;			// the ring's skin

// the camera View is drawn from
var Actor	ViewActor;
var vector	ViewLocation;
var rotator	ViewRotation;
var int		ViewFOV, ViewSize;

// the mesh: its outer radius and how far it bulges
const MeshRadius = 100.0;
const MeshBulge = 8.0;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	Centre = Location;

	View = ScriptedTexture(Level.ObjectPool.AllocateObject(class'ScriptedTexture'));
	View.SetSize(TextureSize, TextureSize);
	View.Client = self;

	ViewCoords = TexMatrix(Level.ObjectPool.AllocateObject(class'TexMatrix'));
	ViewCoords.Material = View;
	ViewCoords.TexCoordSource = TCS_WorldCoords;
	ViewCoords.TexCoordCount = TCN_3DCoords;
	ViewCoords.TexCoordProjected = true;

	Unseen = FinalBlend(Level.ObjectPool.AllocateObject(class'FinalBlend'));
	Unseen.Material = View;
	Unseen.FrameBufferBlending = FB_Invisible;
	Unseen.ZWrite = false;
	Unseen.ZTest = false;
	Unseen.AlphaTest = false;
	Unseen.TwoSided = false;

	MaskCoords = TexMatrix(Level.ObjectPool.AllocateObject(class'TexMatrix'));
	MaskCoords.Material = Texture'KFWaveMask';
	MaskCoords.TexCoordSource = TCS_Stream0;
	MaskCoords.TexCoordCount = TCN_2DCoords;
	MaskCoords.TexCoordProjected = false;

	Masked = Combiner(Level.ObjectPool.AllocateObject(class'Combiner'));
	Masked.Material1 = ViewCoords;
	Masked.Material2 = MaskCoords;
	Masked.Mask = None;
	Masked.CombineOperation = CO_Use_Color_From_Material1;
	Masked.AlphaOperation = AO_Use_Alpha_From_Material2;
	Masked.InvertMask = false;
	Masked.Modulate2X = false;
	Masked.Modulate4X = false;

	Blend = FinalBlend(Level.ObjectPool.AllocateObject(class'FinalBlend'));
	Blend.Material = Masked;
	Blend.FrameBufferBlending = FB_AlphaBlend;
	Blend.ZWrite = false;
	Blend.ZTest = true;
	Blend.AlphaTest = false;
	Blend.TwoSided = true;

	Skins[0] = Blend;
}

// S: the blast's size (a rocket's is 1)
simulated function SetSize(float S)
{
	StartRadius = default.StartRadius * S;
	EndRadius = default.EndRadius * S;
	Duration = 0.30 + 0.08 * S;
}

simulated function Destroyed()
{
	if (FX != None)
		FX.WaveGone(self);
	FX = None;
	ViewActor = None;
	if (ViewCoords != None)
	{
		Skins[0] = None;
		MaskCoords.Material = None;
		Masked.Material1 = None;
		Masked.Material2 = None;
		Blend.Material = None;
		Level.ObjectPool.FreeObject(MaskCoords);
		Level.ObjectPool.FreeObject(Masked);
		Level.ObjectPool.FreeObject(Blend);
		ViewCoords.Material = None;
		Level.ObjectPool.FreeObject(ViewCoords);
		ViewCoords = None;
		View.Client = None;
		Unseen.Material = None;
		Level.ObjectPool.FreeObject(View);
		Level.ObjectPool.FreeObject(Unseen);
		View = None;
	}
	Super.Destroyed();
}

simulated function Tick(float DT)
{
	// (shown again by KFScreenFX if the next frame has it)
	bHidden = true;
	Age += DT;
	if (Age >= Duration)
		Destroy();
}

// how far out the wave is now: out, quickly at first
simulated function float RadiusNow()
{
	local float T;

	T = FClamp(Age / Duration, 0.0, 1.0);
	return StartRadius + (EndRadius - StartRadius) * (1.0 - Square(1.0 - T));
}

// Places the ring for a frame seen from CamLocation, and bends the view behind it; false if it is not in the frame
simulated function bool FrameSetup(Canvas C, Actor CamActor, vector CamLocation, rotator CamRotation, float CamFOV)
{
	local float T, Radius, Dist, Rim, Fade, PlaneDist, RingRadius, Pull, HalfTan, Pixels, Angle, HalfView;
	local vector N;
	local int FOV;
	local bool bOver;

	T = FClamp(Age / Duration, 0.0, 1.0);
	Radius = RadiusNow();
	Dist = VSize(CamLocation - Centre);
	if (Dist < 1.0)
		return false;

	// the wave fades out at its end and as it reaches the viewer
	Rim = Radius / Dist;
	Fade = FMin(1.0, 4.0 * (1.0 - T)) * FClamp((FadeFrom + FadeOver - Rim) / FadeOver, 0.0, 1.0);
	if (Fade < 0.02)
		return false;

	// off screen
	Angle = Acos(FClamp(((Centre - CamLocation) / Dist) dot vector(CamRotation), -1.0, 1.0));
	HalfView = Atan(Tan(CamFOV * Pi / 360.0) * Sqrt(1.0 + Square(float(C.SizeY) / float(C.SizeX))), 1.0);
	if (Angle - Asin(FMin(1.0, RingScale * Rim)) > HalfView)
		return false;

	// the sphere's rim as seen from the eye is a circle in front of its centre
	N = (CamLocation - Centre) / Dist;

	// With its middle in plain sight the wave is drawn over whatever it runs into: a floor or a wall cutting the ring
	// off along a line is what gives it away as a flat thing standing in the air. With its middle out of sight it is
	// hidden by what hides it, as anything is: round a corner, only the part past the corner shows.
	bOver = FastTrace(Centre + N * FMin(40.0, 0.5 * Dist), CamLocation);
	if (Blend.ZTest == bOver)
		Blend.ZTest = !bOver;
	PlaneDist = Dist * (1.0 - Rim * Rim);
	RingRadius = RingScale * Radius * Sqrt(1.0 - Rim * Rim);

	// The picture: from the eye toward the ring's centre, just wide enough to hold the ring, at about the screen's
	// resolution
	FOV = Clamp(int(Atan(1.08 * RingRadius, PlaneDist) * 360.0 / Pi) + 2, 4, 150);
	HalfTan = Tan(FOV * Pi / 360.0);
	Pixels = HalfTan * C.SizeX / Tan(CamFOV * Pi / 360.0);
	if (Pixels < 24.0)
		return false;

	SetLocation(CamLocation - N * PlaneDist);
	SetRotation(rotator(N));
	SetDrawScale(RingRadius / MeshRadius);
	N = vector(Rotation);

	// The picture is only taken if the ring was drawn in the frame before: it may be behind a wall. Until then the
	// ring is there but clear.
	if (PlacedTime <= 0.0 || LastRenderTime < PlacedTime)
	{
		PlacedTime = Level.TimeSeconds;
		SetFade(0.0);
		return true;
	}
	PlacedTime = Level.TimeSeconds;
	SetFade(Fade);

	Pull = Strength * (1.0 - T);
	TakeView(CamActor, CamLocation, rotator(Location - CamLocation), FOV, Min(int(Pixels) + 1, TextureSize));
	LayView(CamLocation, ViewRotation, Pull / ((1.0 - Pull) * MeshBulge * DrawScale), N, Location);
	return true;
}

// the mask's alpha grows along V, and the mesh has V = 0
simulated function SetFade(float Fade)
{
	local Matrix M;

	M.XPlane.X = 1.0;
	M.YPlane.Y = 1.0;
	M.ZPlane.Y = Fade;
	M.ZPlane.Z = 1.0;
	M.WPlane.W = 1.0;
	MaskCoords.Matrix = M;
}

// Have the picture taken for this frame: from the eye, looking along Aim, FOV degrees wide and Size pixels square
simulated function TakeView(Actor CamActor, vector CamLocation, rotator Aim, int FOV, int Size)
{
	bNeedsView = true;
	ViewActor = CamActor;
	ViewLocation = CamLocation;
	ViewRotation = Aim;
	ViewFOV = FOV;
	ViewSize = Size;
	View.Revision++;
}

// Lays the picture on by world position, as a camera at Eye looking along Aim with the picture's field of view would
// see it: with the eye and the aim it was taken with, just where it was. With K above nothing the picture bends: a
// point at height H above the plane through Toward whose normal is N takes the coordinates of a point K * H / (1 + K *
// H) of the way to Toward.
simulated function LayView(vector Eye, rotator Aim, optional float K, optional vector N, optional vector Toward)
{
	local vector X, Y, Z, U, V, T;
	local float HalfTan, Scale, Offset, CU, CV, CQ, NC;
	local Matrix M;

	// world position to texture coordinates, as (u * depth, v * depth, depth)
	GetAxes(Aim, X, Y, Z);
	HalfTan = Tan(ViewFOV * Pi / 360.0);
	Scale = float(ViewSize) / float(TextureSize);
	Offset = 0.5 * Scale + 0.5 / float(TextureSize);
	U = Y * (0.5 * Scale / HalfTan) + X * Offset;
	V = Z * (-0.5 * Scale / HalfTan) + X * Offset;

	T = Toward - Eye;
	CU = T dot U;
	CV = T dot V;
	CQ = T dot X;
	NC = N dot Toward;

	M.XPlane.X = U.X + K * N.X * CU;
	M.XPlane.Y = V.X + K * N.X * CV;
	M.XPlane.Z = X.X + K * N.X * CQ;
	M.YPlane.X = U.Y + K * N.Y * CU;
	M.YPlane.Y = V.Y + K * N.Y * CV;
	M.YPlane.Z = X.Y + K * N.Y * CQ;
	M.ZPlane.X = U.Z + K * N.Z * CU;
	M.ZPlane.Y = V.Z + K * N.Z * CV;
	M.ZPlane.Z = X.Z + K * N.Z * CQ;
	M.WPlane.X = -(Eye dot U) - K * NC * CU;
	M.WPlane.Y = -(Eye dot V) - K * NC * CV;
	M.WPlane.Z = -(Eye dot X) - K * NC * CQ;
	M.WPlane.W = 1.0;
	ViewCoords.Matrix = M;
}

// The picture is drawn with the level's distance fog off: the ring itself is drawn under that fog, which puts it back
// as it is at the ring's distance (about the blast's, where what is seen through it lies). A picture with the fog in it
// came out fogged twice, a pale disc on a dark map.
simulated event RenderTexture(ScriptedTexture Tex)
{
	local ZoneInfo Z;
	local PhysicsVolume V;
	local bool bZoneFog, bVolumeFog;

	if (ViewActor == None)
		return;
	Z = ViewActor.Region.Zone;
	if (Z != None)
	{
		bZoneFog = Z.bDistanceFog;
		Z.bDistanceFog = false;
	}
	if (Pawn(ViewActor) != None)
		V = Pawn(ViewActor).HeadVolume;
	if (V != None)
	{
		bVolumeFog = V.bDistanceFog;
		V.bDistanceFog = false;
	}
	Tex.DrawPortal(0, 0, ViewSize, ViewSize, ViewActor, ViewLocation, ViewRotation, ViewFOV, true);
	if (Z != None)
		Z.bDistanceFog = bZoneFog;
	if (V != None)
		V.bDistanceFog = bVolumeFog;
}

defaultproperties
{
	TextureSize=1024
	StartRadius=20.000000
	EndRadius=250.000000
	Duration=0.380000
	Strength=0.110000
	RingScale=1.150000
	FadeFrom=0.550000
	FadeOver=0.250000
	StaticMesh=StaticMesh'KFWaveRing'
	LifeSpan=3.000000
	DrawType=DT_StaticMesh
	bHidden=True
	bUnlit=True
	// (drawn after the other see-through things, so it has them in its picture; laid over them, not added: an added
	// picture lightens the ring on a dark map)
	Style=STY_Alpha
	bAcceptsProjectors=False
	bShadowCast=False
	bCollideActors=False
	bCollideWorld=False
	bBlockActors=False
	bBlockPlayers=False
	RemoteRole=ROLE_None
	bGameRelevant=True
}
