//=============================================================================
// KFScreenFX - bloom, the hit blur and the eye getting used to the light, all
// made from the frame itself (KFFrameTap). One for the player at this machine,
// in each level.
//
// Bloom: what is bright in the frame (the frame less a grey, doubled) is
// blurred three times over, each at half the size of the one before, and the
// three are added over the screen.
//
// Hit blur: the frame is brought down in three steps, each softer than the
// last. They are laid over the screen one after another by how hard the
// player was hit, so the view goes out of focus and comes back. The steps
// are in the screen's own shape and a set share of its size, so the blur is
// as strong across as down and the same on a small screen as on a large one.
//
// The eye: in a dark place the view slowly brightens, in a bright one it
// dims, and a strong cast of one colour fades toward plain. A script cannot
// read a picture, so it is all done in pictures. The frame is brought down to
// 64 pixels across, that to 8, that to 4: the middle of the last is the
// average of the middle half of the view, as a camera meters. There are two
// of the 4-pixel pictures, and twenty times a second one is drawn from the
// other with the new measure laid over it at a small share: that is what the
// eye is used to. The whole view is then multiplied by a grey less that,
// doubled. Red, green and blue are measured each for itself. With the eye on,
// what counts as bright enough to glow goes by what the eye is used to: less
// in the dark (a dim lamp glows in a cellar), more in the light. The glow and
// the hit blur are multiplied with the view, so coming out of the dark, when
// the view is too bright for a moment, the glow flares with it.
//
// Camera overlays lay both on, after the level is drawn and before the weapon
// and the HUD. The pictures are made when the first overlay asks for them, so
// they are this frame's. That first overlay draws nothing: a picture that is
// made in the middle of a drawing that uses it spoils that drawing.
//
// The engine notes the size of the frame's picture once, when it is first
// made. After a change of resolution its own copy of the frame to the screen
// goes by the old size and comes out stretched or repeated; then the whole
// picture is laid over that copy first (Mend), which puts it right.
//=============================================================================
class KFScreenFX extends Actor
	config(User);

var() globalconfig bool		bBloom, bHitBlur, bEyeAdapt;
var() globalconfig float	BloomGain;			// how strong the glow is
var() globalconfig int		BloomCut;			// what is darker than this, of 255, does not glow
var() float					BlurPerDamage;		// blur from each point of damage (1 is all of it)
var() float					BlurMin;			// the least a hit blurs...
var() float					BlurSmallHit;		// ...unless it took less health than this: then that share of the least
var() float					BlurShrink;			// how many of the screen's pixels, each way, one pixel of the first soft picture stands for
var() float					BlurHold;			// seconds a hit's blur stays before it starts to clear
var() float					BlurFadeTime;		// seconds for a full blur to clear
var() float					AdaptQuick;			// seconds the eye takes to get most of the way used to a change of light
var() float					AdaptEvery;			// seconds between its measurings
var() float					AdaptRest;			// the view is multiplied by twice this, less what the eye is used to
var() float					AdaptPull;			// what the eye is used to: the view's average, this many times over
var() float					AdaptFloor;			// the least the view is ever dimmed to
var() bool					bBloomFixed;		// what glows goes by BloomCut alone, eye or no eye

var KFFrameTap				Tap;
var PlayerController		PC;
var float					LastPrep, BlurLevel, BlurHoldUntil;
var array<CameraOverlay>	Hung;				// the overlays on the player's view now, in order
var CameraOverlay			Mend;
var array<Object>			MendMade;

// Bloom
var ScriptedTexture			Bright, Blur1, Blur2, Blur3, Glow;
var Material				BrightTap, Tap1, Tap2, Tap3, Add1, Add2, Add3, Seen[4];
var ConstantColor			CutTone, Gain[3];
var CameraOverlay			GlowReady, GlowLay;
var array<Object>			BloomMade;
var bool					bBloomMade;

// The eye
var ScriptedTexture			Meter, Small, Used[2], Pane, CutPic;
var array<Material>			MeterLayer, SmallLayer;
var Material				MeterSeen, SmallSeen, UsedSeen[2], CutSeen, Old[2], NewOver, PaneBase, PaneLess, CutBase, CutMore, BrightEye;
var Combiner				PaneMix, CutMix;
var ConstantColor			NewShare, RestTone, LessTone, CutFloor, CutShare, EyeWeight;
var CameraOverlay			EyeReady, EyeLay;
var array<Object>			EyeMade;
var bool					bEyeMade, bEyeFresh;
var int						Cur;				// which of the two the eye is used to now
var float					EyeLast;

// Hit blur
var ScriptedTexture			Soft[3];
var Material				FrameLayer[16], SoftLayer1[9], SoftLayer2[9], SoftSeen[3];
var ConstantColor			Veil[3];
var CameraOverlay			SoftReady, SoftLay[3];
var array<Object>			SoftMade;
var bool					bSoftMade;
var int						SoftW[3], SoftH[3], SoftTaps;
var int						SoftForX, SoftForY;	// the screen size and the shrink the soft pictures were made for
var float					SoftForShrink;

// From the settings menu: kept, and taken up by the game in progress
static function Configure(PlayerController P, bool bNewBloom, bool bNewHitBlur, bool bNewEyeAdapt)
{
	local KFScreenFX FX;

	default.bBloom = bNewBloom;
	default.bHitBlur = bNewHitBlur;
	default.bEyeAdapt = bNewEyeAdapt;
	StaticSaveConfig();
	FX = class'KFFrameTap'.static.GetFX(P);
	if (FX != None)
	{
		FX.bBloom = bNewBloom;
		FX.bHitBlur = bNewHitBlur;
		FX.bEyeAdapt = bNewEyeAdapt;
		if (!bNewHitBlur)
			FX.BlurLevel = 0;
	}
}

simulated function HitBlur(int Damage)
{
	local float Amount;

	if (!bHitBlur)
		return;
	Amount = FMin(1.0, FMax(float(Damage) * BlurPerDamage, BlurMin * FMin(1.0, float(Damage) / BlurSmallHit)));
	if (Amount <= 0.0)
		return;
	// (hits in a row add up slowly: the harder of the two, and a quarter of the other)
	BlurLevel = FMin(1.0, FMax(BlurLevel, Amount) + 0.25 * FMin(BlurLevel, Amount));
	BlurHoldUntil = Level.TimeSeconds + BlurHold;
}

// Before each frame (from KFFrameTap): what is on the view, and the pictures to be made again when it is drawn
simulated function Prep(KFFrameTap T, PlayerController P, Canvas C)
{
	local array<CameraOverlay> Want;
	local float DT;
	local int i, V;

	Tap = T;
	PC = P;
	DT = Level.TimeSeconds - LastPrep;
	LastPrep = Level.TimeSeconds;
	if (BlurLevel > 0.0 && Level.TimeSeconds > BlurHoldUntil)
		BlurLevel = FMax(0.0, BlurLevel - DT / BlurFadeTime);

	// (until the frame's picture has been found once the blur stays on, effect or no effect: see KFFrameTap)
	if (!bBloom && !bEyeAdapt && BlurLevel <= 0.0 && Tap.Frame != None)
	{
		Hang(Want);
		Tap.Unfit(PC);
		return;
	}
	Tap.Fit(PC);
	if (!Tap.Find(C))
		return;

	if (C.SizeX != Tap.Frame.USize || C.SizeY != Tap.Frame.VSize)
	{
		if (Mend == None)
			Mend = Overlay(class'KFFXMat'.static.Paint(MendMade, Level, class'KFFXMat'.static.Mix(MendMade, Level,
				class'KFFXMat'.static.Tone(MendMade, Level, 255, 255), Tap.Frame, 2), 0));
		Want[Want.Length] = Mend;
	}
	if (bEyeAdapt)
	{
		if (!bEyeMade)
			BuildEye();
		LookEye();
		Want[Want.Length] = EyeReady;
	}
	else if (bEyeMade)
		DropEye();
	if (BlurLevel > 0.0)
	{
		if (bSoftMade && (SoftForX != C.SizeX || SoftForY != C.SizeY || SoftForShrink != BlurShrink))
			DropSoft();
		if (!bSoftMade)
			BuildSoft(C.SizeX, C.SizeY);
		Want[Want.Length] = SoftReady;
		// the first third of the blur brings in the sharpest of the three, the last third the softest
		for (i = 0; i < 3; i++)
		{
			V = Clamp(int(255.0 * (BlurLevel * 3.0 - float(i))), 0, 255);
			Veil[i].Color.A = V;
			if (V > 0)
				Want[Want.Length] = SoftLay[i];
			Soft[i].Revision++;
		}
	}
	if (bBloom)
	{
		if (!bBloomMade)
			BuildBloom();
		SetGain();
		Want[Want.Length] = GlowReady;
		Want[Want.Length] = GlowLay;
		Bright.Revision++;
		Blur1.Revision++;
		Blur2.Revision++;
		Blur3.Revision++;
		Glow.Revision++;
	}
	// (last: the glow and the blur are multiplied with the view)
	if (bEyeAdapt)
		Want[Want.Length] = EyeLay;
	Hang(Want);
}

// These overlays, in this order, last of the player's camera effects; any other of ours taken off
simulated function Hang(array<CameraOverlay> Want)
{
	local int i, At;
	local bool bSame;

	At = PC.CameraEffects.Length - Want.Length;
	bSame = (Want.Length == Hung.Length && At >= 0);
	for (i = 0; bSame && i < Want.Length; i++)
		bSame = (Want[i] == Hung[i] && PC.CameraEffects[At + i] == Want[i]);
	if (bSame)
		return;
	for (i = 0; i < Hung.Length; i++)
		PC.RemoveCameraEffect(Hung[i]);
	for (i = 0; i < Want.Length; i++)
		PC.AddCameraEffect(Want[i], true);
	Hung = Want;
}

simulated function CameraOverlay Overlay(Material M)
{
	local CameraOverlay O;

	O = CameraOverlay(Level.ObjectPool.AllocateObject(class'CameraOverlay'));
	O.OverlayMaterial = M;
	O.OverlayColor = class'Canvas'.static.MakeColor(255, 255, 255, 255);
	O.Alpha = 1.0;
	O.FinalEffect = false;
	return O;
}

simulated function Shut(CameraOverlay O)
{
	if (O == None)
		return;
	O.OverlayMaterial = None;
	Level.ObjectPool.FreeObject(O);
}

simulated function BuildBloom()
{
	local int i;

	Bright = class'KFFXMat'.static.Sheet(BloomMade, Level, self, 512, 512);
	Blur1 = class'KFFXMat'.static.Sheet(BloomMade, Level, self, 256, 256);
	Blur2 = class'KFFXMat'.static.Sheet(BloomMade, Level, self, 128, 128);
	Blur3 = class'KFFXMat'.static.Sheet(BloomMade, Level, self, 64, 64);
	Glow = class'KFFXMat'.static.Sheet(BloomMade, Level, self, 256, 256);

	// the frame less the grey, a share of it: the shares of all the samples add up to that doubled
	CutTone = class'KFFXMat'.static.Tone(BloomMade, Level, BloomCut, 128);
	BrightTap = class'KFFXMat'.static.Paint(BloomMade, Level,
		class'KFFXMat'.static.Mix(BloomMade, Level, CutTone, Tap.Frame, 1), 1);
	// a ninth of the picture before: nine are added
	Tap1 = class'KFFXMat'.static.Paint(BloomMade, Level,
		class'KFFXMat'.static.Mix(BloomMade, Level, class'KFFXMat'.static.Tone(BloomMade, Level, 28, 255), Bright, 0), 1);
	Tap2 = class'KFFXMat'.static.Paint(BloomMade, Level,
		class'KFFXMat'.static.Mix(BloomMade, Level, class'KFFXMat'.static.Tone(BloomMade, Level, 28, 255), Blur1, 0), 1);
	Tap3 = class'KFFXMat'.static.Paint(BloomMade, Level,
		class'KFFXMat'.static.Mix(BloomMade, Level, class'KFFXMat'.static.Tone(BloomMade, Level, 28, 255), Blur2, 0), 1);
	for (i = 0; i < 3; i++)
		Gain[i] = class'KFFXMat'.static.Tone(BloomMade, Level, 0, 255);
	Add1 = class'KFFXMat'.static.Paint(BloomMade, Level, class'KFFXMat'.static.Mix(BloomMade, Level, Gain[0], Blur1, 0), 1);
	Add2 = class'KFFXMat'.static.Paint(BloomMade, Level, class'KFFXMat'.static.Mix(BloomMade, Level, Gain[1], Blur2, 0), 1);
	Add3 = class'KFFXMat'.static.Paint(BloomMade, Level, class'KFFXMat'.static.Mix(BloomMade, Level, Gain[2], Blur3, 0), 1);
	Seen[0] = class'KFFXMat'.static.Paint(BloomMade, Level, Bright, 2);
	Seen[1] = class'KFFXMat'.static.Paint(BloomMade, Level, Blur1, 2);
	Seen[2] = class'KFFXMat'.static.Paint(BloomMade, Level, Blur2, 2);
	Seen[3] = class'KFFXMat'.static.Paint(BloomMade, Level, Blur3, 2);

	GlowReady = Overlay(class'KFFXMat'.static.Paint(BloomMade, Level, Glow, 2));
	// (added to what is there, behind a plain colour so that it counts as solid)
	GlowLay = Overlay(class'KFFXMat'.static.Paint(BloomMade, Level,
		class'KFFXMat'.static.Mix(BloomMade, Level, class'KFFXMat'.static.Tone(BloomMade, Level, 255, 255), Glow, 0), 1));
	bBloomMade = true;
}

// The eye's pictures and what is made of them
simulated function BuildEye()
{
	local Combiner M;
	local int i;

	Meter = class'KFFXMat'.static.Sheet(EyeMade, Level, self, 64, 64);
	Small = class'KFFXMat'.static.Sheet(EyeMade, Level, self, 8, 8);
	Used[0] = class'KFFXMat'.static.Sheet(EyeMade, Level, self, 4, 4);
	Used[1] = class'KFFXMat'.static.Sheet(EyeMade, Level, self, 4, 4);
	Pane = class'KFFXMat'.static.Sheet(EyeMade, Level, self, 4, 4);
	CutPic = class'KFFXMat'.static.Sheet(EyeMade, Level, self, 4, 4);
	MeterLayer.Length = 16;
	SmallLayer.Length = 16;
	for (i = 0; i < 16; i++)
	{
		MeterLayer[i] = Ghost(EyeMade, Tap.Frame, 255 / (i + 1));
		SmallLayer[i] = Ghost(EyeMade, Meter, 255 / (i + 1));
	}
	MeterSeen = class'KFFXMat'.static.Paint(EyeMade, Level, Meter, 2);
	SmallSeen = class'KFFXMat'.static.Paint(EyeMade, Level, Small, 2);
	CutSeen = class'KFFXMat'.static.Paint(EyeMade, Level, CutPic, 2);
	for (i = 0; i < 2; i++)
	{
		UsedSeen[i] = class'KFFXMat'.static.Paint(EyeMade, Level, Used[i], 2);
		Old[i] = class'KFFXMat'.static.Paint(EyeMade, Level, Used[i], 5);
	}
	// the new measure, some times over, laid on the old as solid as NewShare says
	NewShare = class'KFFXMat'.static.Tone(EyeMade, Level, 0, 255);
	M = class'KFFXMat'.static.Mix(EyeMade, Level, NewShare, Small, 0, 4);
	M.AlphaOperation = AO_Use_Alpha_From_Material1;
	NewOver = class'KFFXMat'.static.Paint(EyeMade, Level, M, 0);
	// what the view is multiplied by: the rest grey, which then loses its share of what the eye is used to
	RestTone = class'KFFXMat'.static.Tone(EyeMade, Level, 0, 255);
	PaneBase = class'KFFXMat'.static.Paint(EyeMade, Level,
		class'KFFXMat'.static.Mix(EyeMade, Level, RestTone, Texture'Engine.WhiteTexture', 0), 5);
	LessTone = class'KFFXMat'.static.Tone(EyeMade, Level, 0, 255);
	PaneMix = class'KFFXMat'.static.Mix(EyeMade, Level, LessTone, Used[0], 0);
	PaneLess = class'KFFXMat'.static.Paint(EyeMade, Level, PaneMix, 4);
	// what bloom takes from the frame by the eye: a grey, and what the eye is used to added to it
	CutFloor = class'KFFXMat'.static.Tone(EyeMade, Level, 0, 255);
	CutBase = class'KFFXMat'.static.Paint(EyeMade, Level,
		class'KFFXMat'.static.Mix(EyeMade, Level, CutFloor, Texture'Engine.WhiteTexture', 0), 5);
	CutShare = class'KFFXMat'.static.Tone(EyeMade, Level, 0, 255);
	CutMix = class'KFFXMat'.static.Mix(EyeMade, Level, CutShare, Used[0], 0);
	CutMore = class'KFFXMat'.static.Paint(EyeMade, Level, CutMix, 1);
	// the frame less that, a share of it (as BrightTap, with a picture for the grey)
	EyeWeight = class'KFFXMat'.static.Tone(EyeMade, Level, 255, 128);
	BrightEye = class'KFFXMat'.static.Paint(EyeMade, Level, class'KFFXMat'.static.Mix(EyeMade, Level,
		class'KFFXMat'.static.Mix(EyeMade, Level, EyeWeight, CutPic, 2), Tap.Frame, 1), 1);

	EyeReady = Overlay(class'KFFXMat'.static.Paint(EyeMade, Level, Pane, 2));
	EyeLay = Overlay(class'KFFXMat'.static.Paint(EyeMade, Level, Pane, 3));
	bEyeMade = true;
	bEyeFresh = true;
}

// The eye's pictures are given back (it was switched off)
simulated function DropEye()
{
	local array<CameraOverlay> Nothing;

	Hang(Nothing);
	Shut(EyeReady);
	Shut(EyeLay);
	EyeReady = None;
	EyeLay = None;
	BrightEye = None;
	PaneMix = None;
	CutMix = None;
	MeterLayer.Length = 0;
	SmallLayer.Length = 0;
	class'KFFXMat'.static.FreeAll(EyeMade, Level);
	bEyeMade = false;
}

// The greys the eye works with, from the figures (which may be changed while the game runs)
simulated function SetEye()
{
	local float Rest, Take;
	local int V;

	// The view is multiplied by twice (Rest less what the eye is used to). What the eye is used to is the view's
	// average AdaptPull times over, and never more than Take: that leaves the view at AdaptFloor.
	Rest = FClamp(AdaptRest, 0.5, 1.0);
	Take = FClamp(Rest - 0.5 * AdaptFloor, 0.3, Rest);
	// (kept as a share of Take, so that it stops at white where the floor is: the average, Pull / Take times over)
	V = Clamp(int(255.0 * AdaptPull / Take / 4.0), 0, 255);
	NewShare.Color.R = V;
	NewShare.Color.G = V;
	NewShare.Color.B = V;
	V = Clamp(int(255.0 * Rest), 0, 255);
	RestTone.Color = class'Canvas'.static.MakeColor(V, V, V, 255);
	V = Clamp(int(255.0 * Take / Rest), 0, 255);
	LessTone.Color = class'Canvas'.static.MakeColor(V, V, V, 255);
	// Bloom by the eye. The frame bloom reads has not been multiplied yet, so its grey is the one that does the
	// same after the multiplying: with the eye at rest it comes to about BloomCut, less in the dark, more in the light.
	V = Clamp(int(float(BloomCut) * 0.25 / Rest), 0, 255);
	CutFloor.Color = class'Canvas'.static.MakeColor(V, V, V, 255);
	V = Clamp(int(255.0 * Take), 0, 255);
	CutShare.Color = class'Canvas'.static.MakeColor(V, V, V, 255);
}

// Before each frame: every so often the view is measured again and the eye moves a little toward it
simulated function LookEye()
{
	local float Real;

	Real = (Level.TimeSeconds - EyeLast) / FMax(0.1, Level.TimeDilation);
	if (!bEyeFresh && Real < AdaptEvery && Real >= 0.0)
		return;
	SetEye();
	// (the first time, the eye is used to what it sees at once)
	if (bEyeFresh)
		NewShare.Color.A = 255;
	else
		NewShare.Color.A = Clamp(int(255.0 * (1.0 - Exp(-Real / FMax(0.05, AdaptQuick)))), 6, 255);
	bEyeFresh = false;
	EyeLast = Level.TimeSeconds;
	Cur = 1 - Cur;
	PaneMix.Material2 = Used[Cur];
	CutMix.Material2 = Used[Cur];
	Meter.Revision++;
	Small.Revision++;
	Used[Cur].Revision++;
	CutPic.Revision++;
	Pane.Revision++;
}

// How strong the glow is, shared out among the three blurs, and the grey that is taken from the frame
simulated function SetGain()
{
	local int i, V;

	for (i = 0; i < 3; i++)
	{
		if (i == 0)
			V = Clamp(int(255.0 * 0.8 * BloomGain), 0, 255);
		else if (i == 1)
			V = Clamp(int(255.0 * 0.7 * BloomGain), 0, 255);
		else
			V = Clamp(int(255.0 * 0.5 * BloomGain), 0, 255);
		Gain[i].Color = class'Canvas'.static.MakeColor(V, V, V, 255);
	}
	V = Clamp(BloomCut, 0, 255);
	CutTone.Color.R = V;
	CutTone.Color.G = V;
	CutTone.Color.B = V;
}

// The soft pictures are given back (the screen has changed size: they are made again to fit it)
simulated function DropSoft()
{
	local array<CameraOverlay> Nothing;
	local int i;

	Hang(Nothing);
	Shut(SoftReady);
	SoftReady = None;
	for (i = 0; i < 3; i++)
	{
		Shut(SoftLay[i]);
		SoftLay[i] = None;
	}
	class'KFFXMat'.static.FreeAll(SoftMade, Level);
	bSoftMade = false;
}

simulated function BuildSoft(int ScreenX, int ScreenY)
{
	local int i;
	local float Shrink;

	// the first a BlurShrink-th of the screen each way, each one after half the one before
	Shrink = FClamp(BlurShrink, 1.0, 8.0);
	SoftForX = ScreenX;
	SoftForY = ScreenY;
	SoftForShrink = BlurShrink;
	// (a sample takes in two of the frame's pixels each way: enough of them each way that none is left out)
	SoftTaps = Clamp(int(Shrink * 0.5 + 0.99), 1, 4);
	for (i = 0; i < 3; i++)
	{
		SoftW[i] = Max(int(float(ScreenX) / Shrink), 8);
		SoftH[i] = Max(int(float(ScreenY) / Shrink), 8);
		Soft[i] = class'KFFXMat'.static.Sheet(SoftMade, Level, self, SoftW[i], SoftH[i]);
		Shrink *= 2.0;
	}
	// (drawn one after another as the whole, a half, a third... of what is there, pictures come out averaged)
	for (i = 0; i < 16; i++)
		FrameLayer[i] = Ghost(SoftMade, Tap.Frame, 255 / (i + 1));
	for (i = 0; i < 9; i++)
	{
		SoftLayer1[i] = Ghost(SoftMade, Soft[0], 255 / (i + 1));
		SoftLayer2[i] = Ghost(SoftMade, Soft[1], 255 / (i + 1));
	}
	for (i = 0; i < 3; i++)
	{
		SoftSeen[i] = class'KFFXMat'.static.Paint(SoftMade, Level, Soft[i], 2);
		Veil[i] = class'KFFXMat'.static.Tone(SoftMade, Level, 255, 0);
		SoftLay[i] = Overlay(class'KFFXMat'.static.Paint(SoftMade, Level,
			class'KFFXMat'.static.Mix(SoftMade, Level, Veil[i], Soft[i], 2), 0));
	}
	SoftReady = Overlay(SoftSeen[2]);
	bSoftMade = true;
}

// A picture drawn over what is there, as solid as Alpha (of 255) says
simulated function Material Ghost(out array<Object> Made, Material Pic, int Alpha)
{
	return class'KFFXMat'.static.Paint(Made, Level,
		class'KFFXMat'.static.Mix(Made, Level, class'KFFXMat'.static.Tone(Made, Level, 255, Alpha), Pic, 2), 0);
}

simulated function Destroyed()
{
	local array<CameraOverlay> Nothing;
	local int i;

	if (PC != None)
		Hang(Nothing);
	Shut(Mend);
	Shut(GlowReady);
	Shut(GlowLay);
	Shut(SoftReady);
	for (i = 0; i < 3; i++)
		Shut(SoftLay[i]);
	Shut(EyeReady);
	Shut(EyeLay);
	class'KFFXMat'.static.FreeAll(EyeMade, Level);
	bEyeMade = false;
	class'KFFXMat'.static.FreeAll(MendMade, Level);
	class'KFFXMat'.static.FreeAll(BloomMade, Level);
	class'KFFXMat'.static.FreeAll(SoftMade, Level);
	bBloomMade = false;
	bSoftMade = false;
	Super.Destroyed();
}

// Where in the frame the sample i of n is taken, in pixels of the picture being made
simulated function float Spread(int i, int n)
{
	return (float(i) + 0.5) / float(n) - 0.5;
}

// Nine of a picture, each a ninth as bright and a little to one side, added up: the picture blurred, at half the size
simulated function Smear(ScriptedTexture Into, int Size, Material Ninth, int From, float Step)
{
	local Color W;
	local int i, j;

	W = class'Canvas'.static.MakeColor(255, 255, 255, 255);
	for (i = -1; i <= 1; i++)
		for (j = -1; j <= 1; j++)
			Into.DrawTile(Step * i, Step * j, Size, Size, 0, 0, From, From, Ninth, W);
}

// A picture brought down to Size across: each pixel the average of sixteen places in the part of the bigger picture
// that falls on it
simulated function Shrink(ScriptedTexture Into, int Size, float FromW, float FromH, out array<Material> Layers)
{
	local Color W;
	local int i;

	W = class'Canvas'.static.MakeColor(255, 255, 255, 255);
	for (i = 0; i < 16; i++)
		Into.DrawTile(0, 0, Size, Size, Spread(i & 3, 4) * FromW / float(Size), Spread(i / 4, 4) * FromH / float(Size),
			FromW, FromH, Layers[i], W);
}

// The same with nothing lost: nine of a picture averaged. The first covers the whole of it.
simulated function Smooth(ScriptedTexture Into, int Which, int Width, int Height, int FromW, int FromH, float Step)
{
	local Color W;
	local Material M;
	local int i, j, k;

	W = class'Canvas'.static.MakeColor(255, 255, 255, 255);
	for (k = 0; k < 9; k++)
	{
		if (Which == 0)
			M = SoftLayer1[k];
		else
			M = SoftLayer2[k];
		// (the middle one first, then the eight round it)
		i = (k + 4) % 9;
		j = i / 3 - 1;
		i = i % 3 - 1;
		Into.DrawTile(Step * i, Step * j, Width, Height, 0, 0, FromW, FromH, M, W);
	}
}

simulated event RenderTexture(ScriptedTexture Tex)
{
	local Color W;
	local float FW, FH;
	local int i, j, n;
	local Material M;

	if (Tap == None || Tap.Frame == None)
		return;
	W = class'Canvas'.static.MakeColor(255, 255, 255, 255);
	FW = Tap.Frame.USize;
	FH = Tap.Frame.VSize;
	// Each pixel of a picture made from the frame stands for several of the frame's, and a sample takes in two of
	// them each way: two samples each way, four for a big frame, spread evenly, so that none is left out.
	n = 2;
	if (FW > 2048.0 || FH > 2048.0)
		n = 4;

	if (Tex == Glow)
	{
		// (a thing drawn unseen is made ready: each of the four is wanted by the next)
		for (i = 0; i < 4; i++)
			Tex.DrawTile(0, 0, 1, 1, 0, 0, 1, 1, Seen[i], W);
		Tex.DrawTile(0, 0, 256, 256, 0, 0, 256, 256, Add1, W);
		Tex.DrawTile(0, 0, 256, 256, 0, 0, 128, 128, Add2, W);
		Tex.DrawTile(0, 0, 256, 256, 0, 0, 64, 64, Add3, W);
	}
	else if (Tex == Bright)
	{
		CutTone.Color.A = 512 / (n * n);
		M = BrightTap;
		// (by the eye's measure if the eye is on: its pictures for this frame were made before this was asked for)
		if (bEyeAdapt && bEyeMade && !bBloomFixed)
		{
			EyeWeight.Color.A = 512 / (n * n);
			M = BrightEye;
		}
		for (i = 0; i < n; i++)
			for (j = 0; j < n; j++)
				Tex.DrawTile(0, 0, 512, 512, Spread(i, n) * FW / 512.0, Spread(j, n) * FH / 512.0, FW, FH, M, W);
	}
	else if (bEyeMade && Tex == Pane)
	{
		// (a thing drawn unseen is made ready: each of these is made from the one before)
		Tex.DrawTile(0, 0, 1, 1, 0, 0, 1, 1, MeterSeen, W);
		Tex.DrawTile(0, 0, 1, 1, 0, 0, 1, 1, SmallSeen, W);
		Tex.DrawTile(0, 0, 1, 1, 0, 0, 1, 1, UsedSeen[Cur], W);
		Tex.DrawTile(0, 0, 1, 1, 0, 0, 1, 1, CutSeen, W);
		// the rest grey, less its share of the middle of what the eye is used to
		Tex.DrawTile(0, 0, 4, 4, 0, 0, 1, 1, PaneBase, W);
		Tex.DrawTile(0, 0, 4, 4, 2.0, 2.0, 0.01, 0.01, PaneLess, W);
	}
	else if (bEyeMade && Tex == CutPic)
	{
		Tex.DrawTile(0, 0, 4, 4, 0, 0, 1, 1, CutBase, W);
		Tex.DrawTile(0, 0, 4, 4, 2.0, 2.0, 0.01, 0.01, CutMore, W);
	}
	else if (bEyeMade && Tex == Meter)
		Shrink(Tex, 64, FW, FH, MeterLayer);
	else if (bEyeMade && Tex == Small)
		Shrink(Tex, 8, 64.0, 64.0, SmallLayer);
	else if (bEyeMade && Tex == Used[Cur])
	{
		// what the eye was used to, and the new measure over it
		Tex.DrawTile(0, 0, 4, 4, 0, 0, 4, 4, Old[1 - Cur], W);
		Tex.DrawTile(0, 0, 4, 4, 0, 0, 8, 8, NewOver, W);
	}
	else if (Tex == Blur1)
		Smear(Tex, 256, Tap1, 512, 1.2);
	else if (Tex == Blur2)
		Smear(Tex, 128, Tap2, 256, 1.2);
	else if (Tex == Blur3)
		Smear(Tex, 64, Tap3, 128, 1.2);
	else if (Tex == Soft[2])
	{
		Tex.DrawTile(0, 0, 1, 1, 0, 0, 1, 1, SoftSeen[0], W);
		Tex.DrawTile(0, 0, 1, 1, 0, 0, 1, 1, SoftSeen[1], W);
		Smooth(Tex, 1, SoftW[2], SoftH[2], SoftW[1], SoftH[1], 1.2);
	}
	else if (Tex == Soft[1])
		Smooth(Tex, 0, SoftW[1], SoftH[1], SoftW[0], SoftH[0], 1.2);
	else if (Tex == Soft[0])
	{
		n = SoftTaps;
		for (i = 0; i < n; i++)
			for (j = 0; j < n; j++)
				Tex.DrawTile(0, 0, SoftW[0], SoftH[0], Spread(i, n) * FW / float(SoftW[0]), Spread(j, n) * FH / float(SoftH[0]),
					FW, FH, FrameLayer[i * n + j], W);
	}
}

defaultproperties
{
     bBloom=True
     bHitBlur=True
     bEyeAdapt=True
     BloomGain=0.600000
     BloomCut=110
     BlurPerDamage=0.025000
     BlurMin=0.250000
     BlurSmallHit=5.000000
     BlurShrink=3.750000
     BlurHold=0.200000
     BlurFadeTime=1.400000
     AdaptQuick=1.100000
     AdaptEvery=0.050000
     AdaptRest=0.902000
     AdaptPull=1.600000
     AdaptFloor=0.500000
     DrawType=DT_None
     bHidden=True
     RemoteRole=ROLE_None
     bGameRelevant=True
}
