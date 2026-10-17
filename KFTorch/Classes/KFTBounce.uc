//=============================================================================
// KFTBounce - the light a lit surface throws back into the room: point the
// tactical light (KFTLight) at a red wall and the floor, the ceiling and
// whoever stands near the lit place are faintly red.
//
// One bounce, from one place. What the light throws (its Flux picture: the
// colours of what it falls on, times its pattern) is brought down to its
// average colour, which is how much light leaves the lit place and in what
// colour. No script can read a picture, so it is never a number: it is
// averaged by drawing. The picture is drawn into one 64 across, sixteen times
// over at a sixteenth each, every copy moved a little, so that each pixel is
// the average of what falls on it; that one into one 8 across the same way;
// that into one 2 across; and the middle of that, where its four pixels meet,
// is the average of everything.
//
// That colour, in a soft round patch, is thrown by a second projector that
// stands just off the lit surface, where the middle of the beam lands, and
// looks back out along the surface's normal, very wide. The lit surface
// itself is behind it and gets none: a wall is not lit by its own bounce.
// It is the plain kind of projector:
// the renderer draws what is in its wide cone again with the patch laid on,
// times each surface's own texture, added; and it falls away with distance
// from the lit place. It is as strong as the light is where it lands.
//
// What it is not: it comes from the one place, the middle of the beam,
// whatever the rest of the beam lands on; nothing throws a shadow in it; and
// a wall thinner than its reach does not stop it.
//=============================================================================
class KFTBounce extends Projector;

var KFTLight		Lamp;
var ScriptedTexture	Small, Tiny, Two;		// what the light throws, 64, 8 and 2 pixels across
var ScriptedTexture	Patch;					// what is thrown back: its average colour in a soft round patch
var array<Material>	FromFlux, FromSmall, FromTiny;	// each picture as the first, second, third... of so many to be averaged
var Material		SmallSeen, TinySeen, TwoSeen, PatchSeen;
var Material		Mean, Rounded, Twice, Dim;
var ConstantColor	Shade;					// (its alpha: how much is taken off again)
var array<Object>	Made;
var vector			Spot, Facing;			// where the middle of the beam lands, and the way that surface faces
var float			Strength, Want;
var bool			bAimed, bOn;
var float			LandedAt;				// (when the middle of the beam was last put somewhere)
var() float			Gain;					// how much of it, at the lit place
var() float			Back;					// how far behind the projector its cone's tip is
var() float			Off;					// how far off the lit surface the tip is
var() float			Far;					// how far out from the lit place it reaches
var int				FullLength, FadeLength;	// its cone's length; and how far along its middle the light is gone
var() float			Longer;					// how much longer than the light's reach the cone is laid
var() float			FadeSpare;				// how far past the cone's far end the light would be gone, as a share

// (not put on anything as it is made, nor on whatever touches it)
simulated event PostBeginPlay();
simulated event Touch(Actor Other);
simulated event Untouch(Actor Other);

simulated function Init(KFTLight L)
{
	local int i;
	local float Wide;

	Lamp = L;
	Small = class'KFTMat'.static.Sheet(Made, Level, self, 64);
	Tiny = class'KFTMat'.static.Sheet(Made, Level, self, 8);
	Two = class'KFTMat'.static.Sheet(Made, Level, self, 2);
	Patch = class'KFTMat'.static.Sheet(Made, Level, self, 64);
	Patch.UClampMode = TC_Clamp;
	Patch.VClampMode = TC_Clamp;
	// (drawn one after another as the whole, a half, a third... of what is there, pictures come out averaged)
	for (i = 0; i < 16; i++)
	{
		FromFlux[i] = class'KFTMat'.static.Ghost(Made, Level, L.FluxHalf, 255 / (i + 1));
		FromSmall[i] = class'KFTMat'.static.Ghost(Made, Level, Small, 255 / (i + 1));
		FromTiny[i] = class'KFTMat'.static.Ghost(Made, Level, Tiny, 255 / (i + 1));
	}
	SmallSeen = class'KFTMat'.static.Paint(Made, Level, Small, 2);
	TinySeen = class'KFTMat'.static.Paint(Made, Level, Tiny, 2);
	TwoSeen = class'KFTMat'.static.Paint(Made, Level, Two, 2);
	PatchSeen = class'KFTMat'.static.Paint(Made, Level, Patch, 2);
	Mean = class'KFTMat'.static.Paint(Made, Level, Two, 0);
	// (what is there times this, doubled)
	Rounded = class'KFTMat'.static.Paint(Made, Level, Texture'KFTorchTex.KFTGlow', 3);
	Twice = class'KFTMat'.static.Paint(Made, Level, Texture'Engine.WhiteTexture', 3);
	// black, as solid as Shade's alpha says: what is there loses that share
	Shade = class'KFTMat'.static.Hue(Made, Level, 255, 255, 255);
	Dim = class'KFTMat'.static.Mix(Made, Level, Shade, Texture'Engine.BlackTexture', 0);
	Combiner(Dim).CombineOperation = CO_Use_Color_From_Material2;
	Combiner(Dim).AlphaOperation = AO_Use_Alpha_From_Material1;
	Dim = class'KFTMat'.static.Paint(Made, Level, Dim, 0);
	FinalBlend(Dim).FrameBufferBlending = FB_AlphaBlend;

	ProjTexture = Patch;
	// (the cone's tip is behind a projector by half its picture's width over the tangent of half its angle)
	SetDrawScale(Back * 2.0 * Tan(float(FOV) * Pi / 360.0) / 64.0);
	// (A cone's far end is a flat face square to its middle, set where its corner edges are as long as asked: nearer
	// than its length by the cosine of the corner's angle over the cosine of half the cone's. This wide, three
	// tenths nearer.)
	Wide = Tan(float(FOV) * Pi / 360.0);
	FullLength = int((Back + Far) * Longer);
	FadeLength = int(float(FullLength) * Sqrt((1.0 + Wide * Wide) / (1.0 + 2.0 * Wide * Wide)) * FadeSpare);
	MaxTraceDistance = FullLength;
}

simulated event Destroyed()
{
	DetachProjector(true);
	ProjTexture = Texture'KFTorchTex.KFTGlow';
	if (Patch != None)
	{
		Patch.UClampMode = TC_Wrap;
		Patch.VClampMode = TC_Wrap;
	}
	FromFlux.Length = 0;
	FromSmall.Length = 0;
	FromTiny.Length = 0;
	Shade = None;
	class'KFTMat'.static.FreeAll(Made, Level);
	Lamp = None;
	Super.Destroyed();
}

simulated function Dark()
{
	if (bOn)
		DetachProjector(true);
	bOn = false;
}

// Before the light's pictures are taken: where the middle of the beam lands this frame (Dist under nothing: nowhere)
simulated function Lands(vector Hit, vector HitNormal, float Dist)
{
	local float Share;
	local bool bWasAimed;

	bWasAimed = bAimed;
	bAimed = Dist > 0.0;
	if (!bAimed)
	{
		Want = 0.0;
		return;
	}
	// (where it comes from is eased toward where the middle of the beam lands now: left to itself it jumped from a
	// near thing to the wall behind it as the beam crossed the thing's edge, and the whole room's light with it.
	// Over a third of the way a thirtieth of a second; at once if there was none before, or it is a long way.)
	Share = FClamp((Level.TimeSeconds - LandedAt) * 12.0, 0.0, 1.0);
	if (!bWasAimed || Level.TimeSeconds - LandedAt > 0.5 || VSize(Hit - Spot) > 1200.0)
		Share = 1.0;
	LandedAt = Level.TimeSeconds;
	Spot += (Hit - Spot) * Share;
	Facing = Normal(Facing + (HitNormal - Facing) * Share);
	if (Facing == vect(0,0,0))
		Facing = HitNormal;
	// (as strong as the light is there: it falls away evenly to nothing at its reach)
	Want = FClamp(1.0 - Dist / Lamp.Throw, 0.0, 1.0);
	// (past where the light is gone there is none to throw back)
	if (Dist > Lamp.FarMost)
		Want = 0.0;
}

// One of the pictures: drawn now
simulated function Make(Canvas C, ScriptedTexture T, Material Seen)
{
	T.Revision++;
	C.SetPos(0, 0);
	C.DrawTile(Seen, 1, 1, 0, 0, 1, 1);
	C.DrawActor(None, false, false);
}

// After the light has made what it throws (from the light, before the frame)
simulated function Prep(Canvas C)
{
	// (eased, so that it does not jump as the beam crosses an edge)
	Strength += (Want - Strength) * 0.25;
	if (Lamp == None || Strength * Gain * Lamp.Bright < 0.02)
	{
		Dark();
		return;
	}
	Make(C, Small, SmallSeen);
	Make(C, Tiny, TinySeen);
	Make(C, Two, TwoSeen);
	Make(C, Patch, PatchSeen);
	if (!bAimed)
		return;
	SetLocation(Spot + Facing * (Off + Back));
	SetRotation(rotator(Facing));
	// On the level's own surfaces the renderer fades this with distance by a figure it reads off the projector as it
	// draws: gone at the cone's length. But a cone's far end is nearer than its length, and the light stopped there
	// with three tenths of its strength left, at a line across every wall. So the cone is laid a fifth longer
	// (Longer), and the length is then given as just past where its far end is (FadeSpare): on walls the fall is
	// all but what it was, and what is left at the end is a thirteenth, which nobody sees. On models the fall is
	// laid over the cone's whole length when it is put on, so there it is a little slower than it was.
	MaxTraceDistance = FullLength;
	// (taken off first: putting on what is already on leaves the first on the level for good, see KFTLight.HoldShadows)
	DetachProjector(true);
	AttachProjector();
	MaxTraceDistance = FadeLength;
	bOn = true;
}

// A picture N across made from one S across: each pixel the average of sixteen places in the part of the big one
// that falls on it
simulated function Average(ScriptedTexture Tex, float N, float S, array<Material> From)
{
	local Color K;
	local float Step;
	local int i;

	K = class'Canvas'.static.MakeColor(255, 255, 255, 255);
	Step = S / N;
	for (i = 0; i < 16; i++)
		Tex.DrawTile(0, 0, N, N, ((float(i & 3) + 0.5) * 0.25 - 0.5) * Step, ((float(i / 4) + 0.5) * 0.25 - 0.5) * Step, S, S, From[i], K);
}

simulated event RenderTexture(ScriptedTexture Tex)
{
	local Color K;

	if (Lamp == None || Lamp.EyeA == None)
		return;
	if (Tex == Small)
		Average(Tex, 64.0, Lamp.EyeA.Size, FromFlux);
	else if (Tex == Tiny)
		Average(Tex, 8.0, 64.0, FromSmall);
	else if (Tex == Two)
		Average(Tex, 2.0, 8.0, FromTiny);
	else if (Tex == Patch)
	{
		K = class'Canvas'.static.MakeColor(255, 255, 255, 255);
		// the middle of the smallest, where its four pixels meet: the average of all of it
		Tex.DrawTile(0, 0, 64, 64, 0.99, 0.99, 0.02, 0.02, Mean, K);
		// in a round patch (and doubled), and doubled twice more
		Tex.DrawTile(0, 0, 64, 64, 0, 0, 64, 64, Rounded, K);
		Tex.DrawTile(0, 0, 64, 64, 0, 0, 1, 1, Twice, K);
		Tex.DrawTile(0, 0, 64, 64, 0, 0, 1, 1, Twice, K);
		// and as much of that as it is to be
		Shade.Color.A = Clamp(int(255.0 * (1.0 - FClamp(Strength * Gain, 0.0, 1.0))), 0, 255);
		Tex.DrawTile(0, 0, 64, 64, 0, 0, 1, 1, Dim, K);
	}
}

defaultproperties
{
     Gain=1.000000
     Back=30.000000
     Off=6.000000
     Far=420.000000
     Longer=1.200000
     FadeSpare=1.080000
     MaterialBlendingOp=PB_Modulate
     FrameBufferBlendingOp=PB_Add
     ProjTexture=Texture'KFTorchTex.KFTGlow'
     FOV=150
     MaxTraceDistance=450
     bDynamicAttach=True
     bProjectActor=True
     bProjectStaticMesh=True
     bProjectOnBackfaces=True
     bClipBSP=False
     bProjectOnUnlit=True
     bGradient=True
     GradientTexture=Texture'KFTorchTex.KFTFall'
     bProjectOnAlpha=True
     bProjectOnParallelBSP=True
     bStatic=False
     bHidden=False
     DrawType=DT_None
     RemoteRole=ROLE_None
     bGameRelevant=True
     LifeSpan=0.000000
}
