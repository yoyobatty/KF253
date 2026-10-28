//=============================================================================
// KFShieldBubble - the King Fleshpound's shield (ZombieKingFleshpound.bShielded): a ball of red glass round it. The ball
// wears a picture of the scene behind it, the King inside included, taken from the viewer's eye just before each
// frame and pulled in toward the ball's middle, so everything seen through it is bent as through a glass ball; it
// throbs, and flashes as it is struck. Each viewer's own, on Direct3D with the shock waves on (KFScreenFX sets it up
// before each frame, as it does the waves); without, a plain red glow.
//=============================================================================
class KFShieldBubble extends KFWave;

var Actor Boss;
var KFShieldSphere Ball;
var() float Pull, Grow;
var ConstantColor Tint;
var Combiner Tinted;
var FinalBlend Glass;
var float Radius, Hit;

static function KFShieldBubble Make( Actor B, float R )
{
	local PlayerController P;
	local KFScreenFX F;
	local KFShieldBubble S;

	if ( B == None || B.Level.NetMode == NM_DedicatedServer )
		return None;
	P = B.Level.GetLocalPlayerController();
	if ( P == None )
		return None;
	F = class'KFFrameTap'.static.GetFX(P);
	if ( F == None || !F.bShockWaves )
		return None;
	S = F.Spawn(class'KFShieldBubble',,, B.Location);
	if ( S == None )
		return None;
	S.FX = F;
	S.Boss = B;
	S.Radius = R;
	F.Waves[F.Waves.Length] = S;
	return S;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	Skins[0] = None;
	Tint = ConstantColor(Level.ObjectPool.AllocateObject(class'ConstantColor'));
	Tint.Color.R = 240;
	Tint.Color.G = 140;
	Tint.Color.B = 120;
	Tint.Color.A = 255;
	Tinted = Combiner(Level.ObjectPool.AllocateObject(class'Combiner'));
	Tinted.Material1 = Tint;
	Tinted.Material2 = ViewCoords;
	Tinted.Mask = None;
	Tinted.InvertMask = false;
	Tinted.Modulate2X = true;
	Tinted.Modulate4X = false;
	Tinted.CombineOperation = CO_Multiply;
	Tinted.AlphaOperation = AO_Use_Alpha_From_Material2;
	Glass = FinalBlend(Level.ObjectPool.AllocateObject(class'FinalBlend'));
	Glass.Material = Tinted;
	Glass.FrameBufferBlending = FB_Overwrite;
	Glass.ZWrite = true;
	Glass.ZTest = true;
	Glass.AlphaTest = false;
	Glass.TwoSided = false;
	Ball = Spawn(class'KFShieldSphere',,, Location);
	if ( Ball != None )
		Ball.Skins[0] = Glass;
}

// Struck: it flashes
simulated function Struck()
{
	Hit = 1.0;
}

simulated function Tick( float DT )
{
	bHidden = true;
	Grow = FMin(1.0, Grow + DT * 4.0);
	Hit = FMax(0.0, Hit - DT * 4.0);
	if ( Boss == None || Boss.bDeleteMe )
		Destroy();
}

simulated function bool FrameSetup( Canvas C, Actor CamActor, vector CamLocation, rotator CamRotation, float CamFOV )
{
	local vector Mid, N;
	local float Dist, R, HalfTan, Pixels, Throb, Angle, HalfView;
	local int FOV;

	if ( Boss == None || Boss.bDeleteMe || Ball == None )
		return false;
	Mid = Boss.Location;
	Throb = 1.0 + 0.05 * Sin(Level.TimeSeconds * 6.0) + 0.08 * Hit;
	R = Radius * Grow * Throb;
	Ball.SetLocation(Mid);
	Ball.SetDrawScale(FMax(0.01, R / 32.0));
	Tint.Color.R = 240;
	Tint.Color.G = Clamp(int(140.0 + 100.0 * Hit), 0, 255);
	Tint.Color.B = Clamp(int(120.0 + 100.0 * Hit), 0, 255);
	Dist = VSize(Mid - CamLocation);
	Angle = Acos(FClamp(((Mid - CamLocation) / FMax(Dist, 1.0)) dot vector(CamRotation), -1.0, 1.0));
	HalfView = Atan(Tan(CamFOV * Pi / 360.0) * Sqrt(1.0 + Square(float(C.SizeY) / float(C.SizeX))), 1.0);
	// inside it, or it out of view: no picture (the ball shows its last)
	if ( Dist < R + 20.0 || Angle - Atan(R, Dist) > HalfView )
		return false;
	FOV = Clamp(int(Atan(R * 1.15, Dist) * 360.0 / Pi) + 2, 4, 150);
	HalfTan = Tan(FOV * Pi / 360.0);
	Pixels = HalfTan * C.SizeX / Tan(CamFOV * Pi / 360.0);
	if ( Pixels < 16.0 )
		return false;
	N = Normal(CamLocation - Mid);
	TakeView(CamActor, CamLocation, rotator(Mid - CamLocation), FOV, Min(int(Pixels) + 1, TextureSize));
	LayView(CamLocation, ViewRotation, Pull * (1.0 + 0.3 * Sin(Level.TimeSeconds * 3.0)), N, Mid - N * R);
	return true;
}

// The picture is of what is behind the ball and in it, the King included, fog and all: the ball itself is left out
simulated event RenderTexture( ScriptedTexture Tex )
{
	local bool bWas;

	if ( ViewActor == None || Ball == None )
		return;
	bWas = Ball.bHidden;
	Ball.bHidden = true;
	Tex.DrawPortal(0, 0, ViewSize, ViewSize, ViewActor, ViewLocation, ViewRotation, ViewFOV, true);
	Ball.bHidden = bWas;
}

simulated function Destroyed()
{
	if ( Ball != None )
	{
		Ball.Skins[0] = None;
		Ball.Destroy();
	}
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
     Pull=0.012000
     TextureSize=512
     Duration=100000.000000
     StaticMesh=None
     DrawType=DT_None
     LifeSpan=0.000000
}
