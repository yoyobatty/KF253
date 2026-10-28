//=============================================================================
// KFCloakView - a cloaked specimen (a Stalker, the Patriarch) seen as bent glass instead of the old cloak: its body
// wears a picture of what is behind it, taken from the viewer's eye just before each frame with the body left out, laid
// back on by where each point of the body is and pulled toward its middle the further it stands out in front (the
// chest more than the arms): the scene behind shows through it pulled out of place by the body's own shape, and the
// pull swells and sinks a little, so it shimmers. Spotted by a Commando (bSpotted) it glows red, still bent glass.
//
// A KFWave without a ring of its own: KFScreenFX sets it up before each frame with the waves (FrameSetup) and has its
// picture taken then. Each viewer's own, on Direct3D with the shock waves on, for the nearest few; others, and anyone
// without, see the old cloak.
//=============================================================================
class KFCloakView extends KFWave;

var KFMonster Body;
var() float Pull;				// how much of the way to the middle, for each unit a point stands out in front
var() float Back;				// how far behind the body's middle the plane it is pulled toward lies
var() float Breath, BreathRate;	// the pull swells and sinks by this share, this fast (radians a second)
var() float Reach;				// seen from farther than this, the old cloak
var() int MaxCloaks;			// at most this many at once
var() bool bGlassCloak;			// at all (off: the user did not like it, 10-28; the old cloak)
var ConstantColor Tint;
var Combiner Tinted;
var FinalBlend Glass;
var array<Material> OldSkins;
var bool bWorn, bOldUnlit;
var float Spot;					// how far the red has come in (0 to 1)
var() bool bPlainGlass;			// (testing) the picture alone, no tint

static function Take( KFMonster M )
{
	local PlayerController P;
	local KFScreenFX F;
	local KFCloakView V;
	local int i, n;

	if ( !default.bGlassCloak || M == None || M.Level.NetMode == NM_DedicatedServer )
		return;
	P = M.Level.GetLocalPlayerController();
	if ( P == None )
		return;
	F = class'KFFrameTap'.static.GetFX(P);
	if ( F == None || !F.bShockWaves )
		return;
	for ( i=0; i<F.Waves.Length; i++ )
	{
		V = KFCloakView(F.Waves[i]);
		if ( V != None && V.Body == M )
			return;
		if ( V != None )
			n++;
	}
	if ( n >= default.MaxCloaks )
		return;
	V = F.Spawn(class'KFCloakView',,, M.Location);
	if ( V == None )
		return;
	V.FX = F;
	V.Body = M;
	F.Waves[F.Waves.Length] = V;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	// (no ring: the body wears the picture)
	Skins[0] = None;
	Tint = ConstantColor(Level.ObjectPool.AllocateObject(class'ConstantColor'));
	Tint.Color.R = 220;
	Tint.Color.G = 228;
	Tint.Color.B = 236;
	Tint.Color.A = 255;
	Tinted = Combiner(Level.ObjectPool.AllocateObject(class'Combiner'));
	Tinted.Material1 = Tint;
	Tinted.Material2 = ViewCoords;
	Tinted.Mask = None;
	Tinted.InvertMask = false;
	Tinted.Modulate2X = false;
	Tinted.Modulate4X = false;
	Tinted.CombineOperation = CO_Multiply;
	Tinted.AlphaOperation = AO_Use_Alpha_From_Material2;
	Glass = FinalBlend(Level.ObjectPool.AllocateObject(class'FinalBlend'));
	if ( bPlainGlass )
		Glass.Material = ViewCoords;
	else
		Glass.Material = Tinted;
	Glass.FrameBufferBlending = FB_Overwrite;
	Glass.ZWrite = true;
	Glass.ZTest = true;
	Glass.AlphaTest = false;
	Glass.TwoSided = false;
}

simulated function Tick( float DT )
{
	bHidden = true;
	if ( Body == None || Body.bDeleteMe || Body.Health <= 0 || !Body.bCloaked )
		Destroy();
}

// The body wears the picture, or what it wore before
simulated function Wear( bool bOn )
{
	local int i;

	if ( bOn == bWorn || Body == None )
		return;
	if ( bOn )
	{
		OldSkins.Length = Body.Skins.Length;
		for ( i=0; i<Body.Skins.Length; i++ )
			OldSkins[i] = Body.Skins[i];
		bOldUnlit = Body.bUnlit;
		for ( i=0; i<Body.Skins.Length; i++ )
			Body.Skins[i] = Glass;
		Body.bUnlit = true;
	}
	else
	{
		for ( i=0; i<OldSkins.Length && i<Body.Skins.Length; i++ )
			if ( Body.Skins[i] == Glass )
				Body.Skins[i] = OldSkins[i];
		Body.bUnlit = bOldUnlit;
	}
	bWorn = bOn;
}

simulated function bool FrameSetup( Canvas C, Actor CamActor, vector CamLocation, rotator CamRotation, float CamFOV )
{
	local vector Mid, N;
	local float Dist, Half, HalfTan, Pixels, K, Angle, HalfView, Red;
	local int FOV, i;

	if ( Body == None || Body.bDeleteMe || Body.Health <= 0 || !Body.bCloaked )
		return false;
	Mid = Body.Location;
	Dist = VSize(Mid - CamLocation);
	Half = Body.CollisionHeight * 1.25 + 20.0;
	// too far, or out of the view: the old cloak
	Angle = Acos(FClamp(((Mid - CamLocation) / FMax(Dist, 1.0)) dot vector(CamRotation), -1.0, 1.0));
	HalfView = Atan(Tan(CamFOV * Pi / 360.0) * Sqrt(1.0 + Square(float(C.SizeY) / float(C.SizeX))), 1.0);
	if ( Dist > Reach || Dist < Half + 10.0 || Angle - Atan(Half, Dist) > HalfView || !FastTrace(Mid, CamLocation) )
	{
		Wear(false);
		return false;
	}
	// (something put its skins back: the cloak swapped, a spot)
	for ( i=0; i<Body.Skins.Length; i++ )
		if ( Body.Skins[i] != Glass )
		{
			bWorn = false;
			break;
		}
	Wear(true);

	// spotted by a Commando: glowing red glass
	if ( Body.bSpotted )
		Spot = FMin(1.0, Spot + 0.06);
	else
		Spot = FMax(0.0, Spot - 0.06);
	Red = Spot * (0.75 + 0.25 * Sin(Level.TimeSeconds * 7.0));
	Tint.Color.R = 220 + int(35.0 * Red);
	Tint.Color.G = 228 - int(120.0 * Red);
	Tint.Color.B = 236 - int(140.0 * Red);
	Tinted.Modulate2X = Spot > 0.05;

	FOV = Clamp(int(Atan(Half * 1.15, Dist) * 360.0 / Pi) + 2, 4, 150);
	HalfTan = Tan(FOV * Pi / 360.0);
	Pixels = HalfTan * C.SizeX / Tan(CamFOV * Pi / 360.0);
	if ( Pixels < 16.0 )
	{
		Wear(false);
		return false;
	}
	N = Normal(CamLocation - Mid);
	K = Pull * (1.0 + Breath * Sin(BreathRate * Level.TimeSeconds)) * (1.0 + 0.6 * Spot);
	TakeView(CamActor, CamLocation, rotator(Mid - CamLocation), FOV, Min(int(Pixels) + 1, TextureSize));
	LayView(CamLocation, ViewRotation, K, N, Mid - N * Back);
	return true;
}

// The picture is of what is behind the body, the body itself left out of it, fog and all: each point of it is as
// fogged as it is in the frame, as far off as it really is (a picture without the fog came out dark: the body in front
// fogs it only for its own distance)
simulated event RenderTexture( ScriptedTexture Tex )
{
	local bool bWas;

	if ( Body == None || ViewActor == None )
		return;
	bWas = Body.bHidden;
	Body.bHidden = true;
	Tex.DrawPortal(0, 0, ViewSize, ViewSize, ViewActor, ViewLocation, ViewRotation, ViewFOV, true);
	Body.bHidden = bWas;
}

simulated function Destroyed()
{
	Wear(false);
	if ( Glass != None )
	{
		Glass.Material = None;
		Tinted.Material1 = None;
		Tinted.Material2 = None;
		Level.ObjectPool.FreeObject(Glass);
		Level.ObjectPool.FreeObject(Tinted);
		Level.ObjectPool.FreeObject(Tint);
		Glass = None;
	}
	Super.Destroyed();
}

defaultproperties
{
     Pull=0.030000
     Back=10.000000
     Breath=0.300000
     BreathRate=4.000000
     Reach=2200.000000
     MaxCloaks=4
     TextureSize=512
     Duration=100000.000000
     StaticMesh=None
     DrawType=DT_None
     LifeSpan=0.000000
}
