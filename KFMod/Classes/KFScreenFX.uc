//=============================================================================
// KFScreenFX - bloom, the hit blur and vivid colour, all made from the frame
// itself (KFFrameTap). One for the player at this machine, in each level.
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
// Vivid: more colour over the whole view, by one number of a hundred (100 is
// the view as it is). Nothing here can mix red, green and blue, so it is not
// a saturation control: it is a curve on each alone that lets the strong pull
// ahead of the weak. The view is multiplied by a grey plus a share of the
// frame itself, doubled, so each colour comes out as
//     Low * colour + Rich * colour * colour
// The squared part counts for more the brighter the colour is: the dark parts
// keep the colour they had and are dimmed a little (Low), the middle and the
// bright parts gain colour and light. Low is worked out so that a thing as
// bright as VividRest is left as bright as it was. Under 100 a plain grey is
// laid over the view instead, as solid as the number is short of 100. Bloom
// is made from the frame as it was drawn and added afterwards, unchanged.
//
// Shading in corners (ambient occlusion): two more pictures of the view are
// taken before each frame, small, in white fog and in black (KFAOEye); the
// one less the other is how far away everything is. A point is in a crease where
// two of its neighbours on opposite sides are, between them, nearer than it
// is: by more than a step (on a flat surface the two even out), and by less
// than a share of its distance (or it is the background behind an edge).
// Four pairs of neighbours are looked at in each of several rings, each ring
// twice as far out as the one before. What is found is softened and the
// level as drawn is darkened by it, before the weapon and the HUD.
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

var() globalconfig bool		bBloom, bHitBlur, bVivid;
var() globalconfig int		VividMuch;			// how much colour, of a hundred: 100 is the view as it is, up to 160 for more, down to 0 for less
var() globalconfig float	VividRest;			// how bright a thing is left as bright as it was (and the grey the view fades to under 100)
var() globalconfig float	BloomGain;			// how strong the glow is
var() globalconfig int		BloomCut;			// what is darker than this, of 255, does not glow
var() float					BlurPerDamage;		// blur from each point of damage (1 is all of it)
var() float					BlurMin;			// the least a hit blurs...
var() float					BlurSmallHit;		// ...unless it took less health than this: then that share of the least
var() float					BlurShrink;			// how many of the screen's pixels, each way, one pixel of the first soft picture stands for
var() float					BlurHold;			// seconds a hit's blur stays before it starts to clear
var() float					BlurFadeTime;		// seconds for a full blur to clear
var() float					BlurPeak;			// the most a hit, or hits in a row, can blur (1 is all of it)
var() float					VividPerRich;		// how many of VividMuch, over 100, add the whole of the view's own square
var bool					bMenu;				// in a level with no game's HUD (the main menu's): more colour only, no glow
var() globalconfig bool		bAO;				// shading in corners and creases (ambient occlusion)
var() globalconfig bool		bTorch;				// the player's own tactical light worked out at every pixel, with shadows (KFTorch reads it)
var() globalconfig float	AOStrength;			// how dark the deepest crease is made, of 1
var() float					AOShrink;			// the pictures it is worked out from are this many times smaller than the screen each way
var() float					AORange;			// how far the pictures tell distance; nothing past it is shaded, and less the further off
var() int					AOBias;				// how much nearer two neighbours must be, in the pictures' steps of distance (255 over AORange)
var() float					AORing;				// how far the first ring of neighbours is from a point, in the pictures' pixels
var() int					AORings;			// how many rings (each twice as far out as the one before, four pairs in each)
var() float					AOWindow;			// how much nearer two neighbours may be and still make a crease, in steps of distance past AOBias, at the first ring (twice that at each after)
var() int					AOShow;				// (a tool) 1 the shading alone, 2 how far away everything is; 3 the grey picture, 4 the black, 5 the distance less a step, 6 and 7 the two sums, 8 the creases

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

// Vivid
var ScriptedTexture			VividGrey;
var ConstantColor			VividShare, VividKeep, VividVeil;
var Material				VividFill, VividMat;
var CameraOverlay			VividReady, VividLay, VividFade;
var array<Object>			VividMade;
var bool					bVividMade;
var int						VividNow;			// the number in force this frame (100 when it is off)

// Shading in corners
var KFAOEye					AOEyeG, AOEyeB;
var ScriptedTexture			AODep, AOCen, AOLow, AOFar[6], AOWeight, AOPlus, AOMinus, AOFade, AOPic, AOSoft;
var ConstantColor			AOBiasK, AOFarK[6], AOTapK, AOStrK, AOHalfK;
var Material				AODepOver, AOCenOver, AOLowOver, AOFarOver[6], AOWeightOver, AOFadeOver, AOPicOver, AOClear;
var Material				AODepSeen, AOCenSeen, AOLowSeen, AOFarSeen[6], AOWeightSeen, AOPlusSeen, AOMinusSeen, AOFadeSeen, AOPicSeen, AOSoftSeen;
var array<Material>			AOPlusTap, AOMinusTap, AOSoftLayer;
var CameraOverlay			AOLay, AOShowLay[8];
var array<Object>			AOMade;
var bool					bAOMade;
var int						AOW, AOH, AOForX, AOForY, AOForRings;
var float					AOForShrink, AOForRing;
var array<PhysicsVolume>	FogVols;			// the level's volumes, whose fog is put aside for the length of the pictures
var array<byte>				FogVolWas;
var bool					bFogVolsFound, bFogVolsOff;

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
static function Configure(PlayerController P, bool bNewBloom, bool bNewHitBlur, bool bNewVivid, bool bNewAO)
{
	local KFScreenFX FX;

	default.bBloom = bNewBloom;
	default.bHitBlur = bNewHitBlur;
	default.bVivid = bNewVivid;
	default.bAO = bNewAO;
	StaticSaveConfig();
	FX = class'KFFrameTap'.static.GetFX(P);
	if (FX != None)
	{
		FX.bBloom = bNewBloom;
		FX.bHitBlur = bNewHitBlur;
		FX.bVivid = bNewVivid;
		FX.bAO = bNewAO;
		if (!bNewHitBlur)
			FX.BlurLevel = 0;
	}
}

simulated function HitBlur(int Damage)
{
	local float Amount;

	if (!bHitBlur)
		return;
	Amount = FMin(BlurPeak, FMax(float(Damage) * BlurPerDamage, BlurMin * FMin(1.0, float(Damage) / BlurSmallHit)));
	if (Amount <= 0.0)
		return;
	// (hits in a row add up slowly: the harder of the two, and a quarter of the other)
	BlurLevel = FMin(BlurPeak, FMax(BlurLevel, Amount) + 0.25 * FMin(BlurLevel, Amount));
	BlurHoldUntil = Level.TimeSeconds + BlurHold;
}

// Before each frame (from KFFrameTap): what is on the view, and the pictures to be made again when it is drawn
simulated function Prep(KFFrameTap T, PlayerController P, Canvas C)
{
	local array<CameraOverlay> Want;
	local float DT;
	local int i, V;
	local bool bGlow;

	Tap = T;
	PC = P;
	DT = Level.TimeSeconds - LastPrep;
	LastPrep = Level.TimeSeconds;
	if (BlurLevel > 0.0 && Level.TimeSeconds > BlurHoldUntil)
		BlurLevel = FMax(0.0, BlurLevel - DT / BlurFadeTime);

	VividNow = 100;
	if (bVivid)
		VividNow = Clamp(VividMuch, 0, 100 + int(2.0 * VividPerRich));
	bGlow = bBloom && !bMenu;

	// (until the frame's picture has been found once the blur stays on, effect or no effect: see KFFrameTap)
	if (!bGlow && !bAO && VividNow == 100 && BlurLevel <= 0.0 && Tap.Frame != None)
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
	// (the shading in corners first: it darkens the level as it was drawn)
	if (bAO)
	{
		if (bAOMade && (AOForX != C.SizeX || AOForY != C.SizeY || AOForShrink != AOShrink || AOForRings != AORings || AOForRing != AORing))
			DropAO();
		if (!bAOMade)
			BuildAO(C.SizeX, C.SizeY);
		if (TakeAO(C))
		{
			if (AOShow >= 1 && AOShow <= 8)
				Want[Want.Length] = AOShowLay[AOShow - 1];
			else
				Want[Want.Length] = AOLay;
		}
	}
	else if (bAOMade)
		DropAO();
	if (VividNow != 100)
	{
		if (!bVividMade)
			BuildVivid();
		SetVivid();
	}
	// (more colour goes on before the blur's soft pictures, which are given the same colours as they are made)
	if (VividNow > 100)
	{
		VividGrey.Revision++;
		Want[Want.Length] = VividReady;
		Want[Want.Length] = VividLay;
	}
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
	// (less colour is a veil over all of it)
	if (VividNow < 100)
		Want[Want.Length] = VividFade;
	if (bGlow)
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

// The volumes' fog is put aside for the length of the shading's pictures: a volume the eye is in would give them its
// fog in place of the grey and the black
simulated function FogVolumes(bool bOff)
{
	local PhysicsVolume V;
	local int i;

	if (!bFogVolsFound)
	{
		bFogVolsFound = true;
		foreach AllActors(class'PhysicsVolume', V)
			FogVols[FogVols.Length] = V;
	}
	if (bOff == bFogVolsOff)
		return;
	bFogVolsOff = bOff;
	for (i = 0; i < FogVols.Length; i++)
	{
		if (FogVols[i] == None || FogVols[i].bDeleteMe)
			continue;
		if (bOff)
		{
			FogVolWas[i] = byte(FogVols[i].bDistanceFog);
			FogVols[i].bDistanceFog = false;
		}
		else if (FogVolWas[i] != 0)
			FogVols[i].bDistanceFog = true;
	}
}

simulated function BuildAO(int ScreenX, int ScreenY)
{
	local TexMatrix Sp, Sm;
	local Material A, M;
	local Combiner X;
	local float R, Ang, DU, DV;
	local int j, d, Rings;

	AOForX = ScreenX;
	AOForY = ScreenY;
	AOForShrink = AOShrink;
	AOForRings = AORings;
	AOForRing = AORing;
	Rings = Clamp(AORings, 1, 6);
	AOW = Max(int(float(ScreenX) / FClamp(AOShrink, 1.0, 8.0)), 16);
	AOH = Max(int(float(ScreenY) / FClamp(AOShrink, 1.0, 8.0)), 16);
	AOEyeG = Spawn(class'KFAOEye', self);
	AOEyeB = Spawn(class'KFAOEye', self);
	if (AOEyeG == None || AOEyeB == None)
	{
		if (AOEyeG != None)
			AOEyeG.Destroy();
		if (AOEyeB != None)
			AOEyeB.Destroy();
		AOEyeG = None;
		AOEyeB = None;
		return;
	}
	AOEyeG.Init(self, AOW, AOH, true);
	AOEyeB.Init(self, AOW, AOH, false);

	// (Every Combiner here has a plain picture on one side at least: one made of two made ones, or of a plain colour
	// and a made one, is not drawn at all, and the engine's stand-in texture is drawn in its place.)

	// how far away everything is: the white fog's picture less the black's
	AODep = class'KFFXMat'.static.Sheet(AOMade, Level, self, AOW, AOH);
	AODepOver = class'KFFXMat'.static.Paint(AOMade, Level, class'KFFXMat'.static.Mix(AOMade, Level, AOEyeB.View, AOEyeG.View, 1), 4);
	AODepSeen = class'KFFXMat'.static.Paint(AOMade, Level, AODep, 2);
	AOCen = AODep;
	// a point's distance less a step or so: what its two neighbours, between them, must be nearer than
	AOBiasK = class'KFFXMat'.static.Tone(AOMade, Level, 2, 255);
	AOLow = class'KFFXMat'.static.Sheet(AOMade, Level, self, AOW, AOH);
	AOLowOver = class'KFFXMat'.static.Paint(AOMade, Level, class'KFFXMat'.static.Mix(AOMade, Level, AOBiasK, AOCen, 1), 4);
	AOLowSeen = class'KFFXMat'.static.Paint(AOMade, Level, AOLow, 2);
	// the point's distance less more steps, ring by ring: what the two may not be nearer than
	for (j = 0; j < Rings; j++)
	{
		AOFarK[j] = class'KFFXMat'.static.Tone(AOMade, Level, 255, 255);
		AOFar[j] = class'KFFXMat'.static.Sheet(AOMade, Level, self, AOW, AOH);
		AOFarOver[j] = class'KFFXMat'.static.Paint(AOMade, Level, class'KFFXMat'.static.Mix(AOMade, Level, AOFarK[j], AOCen, 1), 4);
		AOFarSeen[j] = class'KFFXMat'.static.Paint(AOMade, Level, AOFar[j], 2);
	}
	// each pair's share of the whole, as a small picture (a plain colour cannot stand against a made thing)
	AOTapK = class'KFFXMat'.static.Tone(AOMade, Level, 255 / (4 * Rings), 255);
	AOWeight = class'KFFXMat'.static.Sheet(AOMade, Level, self, 4, 4);
	AOWeightOver = class'KFFXMat'.static.Paint(AOMade, Level, class'KFFXMat'.static.Mix(AOMade, Level, AOTapK, Texture'Engine.WhiteTexture', 0), 4);
	AOWeightSeen = class'KFFXMat'.static.Paint(AOMade, Level, AOWeight, 2);

	// Each pair of neighbours: their average (the one laid over the other at half), taken from the point's distance
	// less a step; times sixty-four, so that it is a crease or it is not; times the pair's share, added. And the
	// same against the point's distance less more steps: what is in that is too deep for a crease (the background
	// behind an edge), and is taken away again.
	AOHalfK = class'KFFXMat'.static.Tone(AOMade, Level, 255, 128);
	AOPlusTap.Length = 0;
	AOMinusTap.Length = 0;
	R = FMax(AORing, 0.5);
	for (j = 0; j < Rings; j++)
	{
		for (d = 0; d < 4; d++)
		{
			Ang = float(d) * Pi * 0.25 + float(j) * Pi * 0.125;
			DU = R * Cos(Ang) / float(AOW);
			DV = R * Sin(Ang) / float(AOH);
			Sp = class'KFFXMat'.static.Shift(AOMade, Level, AODep);
			class'KFFXMat'.static.Moved(Sp, DU, DV);
			Sm = class'KFFXMat'.static.Shift(AOMade, Level, AODep);
			class'KFFXMat'.static.Moved(Sm, -DU, -DV);
			A = class'KFFXMat'.static.Fade(AOMade, Level, Sp, Sm, AOHalfK);
			M = class'KFFXMat'.static.Gained(AOMade, Level, class'KFFXMat'.static.Mix(AOMade, Level, A, AOLow, 1), 3);
			X = class'KFFXMat'.static.Mix(AOMade, Level, M, AOWeight, 0);
			X.AlphaOperation = AO_Use_Alpha_From_Material2;
			AOPlusTap[AOPlusTap.Length] = class'KFFXMat'.static.Paint(AOMade, Level, X, 1);
			M = class'KFFXMat'.static.Gained(AOMade, Level, class'KFFXMat'.static.Mix(AOMade, Level, A, AOFar[j], 1), 3);
			X = class'KFFXMat'.static.Mix(AOMade, Level, M, AOWeight, 0);
			X.AlphaOperation = AO_Use_Alpha_From_Material2;
			AOMinusTap[AOMinusTap.Length] = class'KFFXMat'.static.Paint(AOMade, Level, X, 1);
		}
		R *= 2.0;
	}
	AOClear = class'KFFXMat'.static.Paint(AOMade, Level, Texture'Engine.BlackTexture', 4);
	AOPlus = class'KFFXMat'.static.Sheet(AOMade, Level, self, AOW, AOH);
	AOPlusSeen = class'KFFXMat'.static.Paint(AOMade, Level, AOPlus, 2);
	AOMinus = class'KFFXMat'.static.Sheet(AOMade, Level, self, AOW, AOH);
	AOMinusSeen = class'KFFXMat'.static.Paint(AOMade, Level, AOMinus, 2);

	// less the further off (nothing at the pictures' far end): one less the distance
	AOFade = class'KFFXMat'.static.Sheet(AOMade, Level, self, AOW, AOH);
	AOFadeOver = class'KFFXMat'.static.Paint(AOMade, Level, class'KFFXMat'.static.Mix(AOMade, Level, AOCen, Texture'Engine.WhiteTexture', 1), 4);
	AOFadeSeen = class'KFFXMat'.static.Paint(AOMade, Level, AOFade, 2);
	// the creases, doubled, times that
	AOPic = class'KFFXMat'.static.Sheet(AOMade, Level, self, AOW, AOH);
	X = class'KFFXMat'.static.Mix(AOMade, Level, class'KFFXMat'.static.Mix(AOMade, Level, AOMinus, AOPlus, 1), AOFade, 0);
	X.Modulate2X = true;
	AOPicOver = class'KFFXMat'.static.Paint(AOMade, Level, X, 4);
	AOPicSeen = class'KFFXMat'.static.Paint(AOMade, Level, AOPic, 2);
	// softened: nine of it averaged, each a pixel to one side
	AOSoft = class'KFFXMat'.static.Sheet(AOMade, Level, self, AOW, AOH);
	AOSoftSeen = class'KFFXMat'.static.Paint(AOMade, Level, AOSoft, 2);
	AOSoftLayer.Length = 0;
	for (j = 0; j < 9; j++)
		AOSoftLayer[j] = class'KFFXMat'.static.Paint(AOMade, Level,
			class'KFFXMat'.static.Mix(AOMade, Level, class'KFFXMat'.static.Tone(AOMade, Level, 255, 255 / (j + 1)), AOPic, 2), 0);

	// the level as drawn, less that share of itself
	AOStrK = class'KFFXMat'.static.Tone(AOMade, Level, 150, 255);
	AOLay = Overlay(class'KFFXMat'.static.Paint(AOMade, Level, class'KFFXMat'.static.Mix(AOMade, Level, AOStrK, AOSoft, 0), 5));
	// (tools: the shading alone, white where there is none; how far away everything is; the steps on the way)
	AOShowLay[0] = Overlay(class'KFFXMat'.static.Paint(AOMade, Level,
		class'KFFXMat'.static.Mix(AOMade, Level, AOSoft, Texture'Engine.WhiteTexture', 1), 4));
	AOShowLay[1] = Overlay(class'KFFXMat'.static.Paint(AOMade, Level, AOCen, 4));
	AOShowLay[2] = Overlay(class'KFFXMat'.static.Paint(AOMade, Level, AOEyeG.View, 4));
	AOShowLay[3] = Overlay(class'KFFXMat'.static.Paint(AOMade, Level, AOEyeB.View, 4));
	AOShowLay[4] = Overlay(class'KFFXMat'.static.Paint(AOMade, Level, AOLow, 4));
	AOShowLay[5] = Overlay(class'KFFXMat'.static.Paint(AOMade, Level, AOPlus, 4));
	AOShowLay[6] = Overlay(class'KFFXMat'.static.Paint(AOMade, Level, AOMinus, 4));
	AOShowLay[7] = Overlay(class'KFFXMat'.static.Paint(AOMade, Level, AOPic, 4));
	bAOMade = true;
}

simulated function DropAO()
{
	local array<CameraOverlay> Nothing;
	local int i;

	if (PC != None)
		Hang(Nothing);
	Shut(AOLay);
	AOLay = None;
	for (i = 0; i < 8; i++)
	{
		Shut(AOShowLay[i]);
		AOShowLay[i] = None;
	}
	if (AOEyeG != None)
		AOEyeG.Destroy();
	if (AOEyeB != None)
		AOEyeB.Destroy();
	AOEyeG = None;
	AOEyeB = None;
	AODep = None;
	AOCen = None;
	AOWeight = None;
	AOFade = None;
	AOLow = None;
	for (i = 0; i < 6; i++)
		AOFar[i] = None;
	AOPlus = None;
	AOMinus = None;
	AOPic = None;
	AOSoft = None;
	AOPlusTap.Length = 0;
	AOMinusTap.Length = 0;
	AOSoftLayer.Length = 0;
	class'KFFXMat'.static.FreeAll(AOMade, Level);
	bAOMade = false;
}

// The numbers the shading goes by this frame
simulated function SetAO()
{
	local float K;
	local int j, V;

	V = Clamp(AOBias, 0, 255);
	AOBiasK.Color = class'Canvas'.static.MakeColor(V, V, V, 255);
	K = FMax(AOWindow, 0.0);
	for (j = 0; j < Clamp(AORings, 1, 6); j++)
	{
		V = Clamp(int(float(AOBias) + K + 0.5), 0, 255);
		AOFarK[j].Color = class'Canvas'.static.MakeColor(V, V, V, 255);
		K *= 2.0;
	}
	V = Clamp(int(255.0 * AOStrength + 0.5), 0, 255);
	AOStrK.Color = class'Canvas'.static.MakeColor(V, V, V, 255);
}

// One of the pictures made from others: drawn now, before anything is drawn with it
simulated function Make(Canvas C, ScriptedTexture T, Material Seen)
{
	T.Revision++;
	C.SetPos(0, 0);
	C.DrawTile(Seen, 1, 1, 0, 0, 1, 1);
	C.DrawActor(None, false, false);
}

// Before the frame: the two pictures of the view taken from where it is seen this frame, and the shading made from
// them
simulated function bool TakeAO(Canvas C)
{
	local Actor Cam;
	local vector Eye;
	local rotator Rot;
	local int j;

	if (AOEyeG == None || AOEyeB == None || PC == None)
		return false;
	PC.PlayerCalcView(Cam, Eye, Rot);
	if (Cam == None)
		Cam = PC;
	AOEyeG.Take(Cam, Eye, Rot, int(PC.FOVAngle + 0.5));
	AOEyeB.Take(Cam, Eye, Rot, int(PC.FOVAngle + 0.5));
	C.SetPos(0, 0);
	C.DrawTile(AOEyeG.Unseen, 1, 1, 0, 0, 1, 1);
	C.SetPos(0, 0);
	C.DrawTile(AOEyeB.Unseen, 1, 1, 0, 0, 1, 1);
	C.DrawActor(None, false, false);
	SetAO();
	Make(C, AODep, AODepSeen);
	Make(C, AOLow, AOLowSeen);
	for (j = 0; j < Clamp(AORings, 1, 6); j++)
		Make(C, AOFar[j], AOFarSeen[j]);
	Make(C, AOWeight, AOWeightSeen);
	Make(C, AOPlus, AOPlusSeen);
	Make(C, AOMinus, AOMinusSeen);
	Make(C, AOFade, AOFadeSeen);
	Make(C, AOPic, AOPicSeen);
	Make(C, AOSoft, AOSoftSeen);
	return true;
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

simulated function BuildVivid()
{
	local Combiner M;

	// more: the frame times a share, and a grey. A row of materials may have one plain colour, so the grey is a
	// small picture of its own, filled with one.
	VividGrey = class'KFFXMat'.static.Sheet(VividMade, Level, self, 4, 4);
	VividKeep = class'KFFXMat'.static.Tone(VividMade, Level, 0, 255);
	VividFill = class'KFFXMat'.static.Paint(VividMade, Level,
		class'KFFXMat'.static.Mix(VividMade, Level, VividKeep, Texture'Engine.WhiteTexture', 0), 4);
	VividShare = class'KFFXMat'.static.Tone(VividMade, Level, 0, 255);
	VividMat = class'KFFXMat'.static.Paint(VividMade, Level, class'KFFXMat'.static.Mix(VividMade, Level,
		class'KFFXMat'.static.Mix(VividMade, Level, VividShare, Tap.Frame, 0), VividGrey, 3), 3);
	VividReady = Overlay(class'KFFXMat'.static.Paint(VividMade, Level, VividGrey, 2));
	VividLay = Overlay(VividMat);
	// less: a plain grey, as solid as it is told
	VividVeil = class'KFFXMat'.static.Tone(VividMade, Level, 64, 0);
	M = class'KFFXMat'.static.Mix(VividMade, Level, VividVeil, Texture'Engine.WhiteTexture', 0);
	M.AlphaOperation = AO_Use_Alpha_From_Material1;
	VividFade = Overlay(class'KFFXMat'.static.Paint(VividMade, Level, M, 0));
	bVividMade = true;
}

// The greys vivid works with, from the number and the brightness that is left as it is
simulated function SetVivid()
{
	local float Rich, Low, Rest;
	local int V;

	Rest = FClamp(VividRest, 0.05, 0.6);
	if (VividNow > 100)
	{
		Rich = FClamp(float(VividNow - 100) / FMax(1.0, VividPerRich), 0.0, 2.0);
		Low = FMax(0.0, 1.0 - Rest * Rich);
		// (the overlay doubles what it multiplies by: half of each goes in)
		V = Clamp(int(127.5 * Rich + 0.5), 0, 255);
		VividShare.Color = class'Canvas'.static.MakeColor(V, V, V, 255);
		V = Clamp(int(127.5 * Low + 0.5), 0, 255);
		VividKeep.Color = class'Canvas'.static.MakeColor(V, V, V, 255);
	}
	else
	{
		V = Clamp(int(255.0 * Rest + 0.5), 0, 255);
		VividVeil.Color = class'Canvas'.static.MakeColor(V, V, V, Clamp(int(2.55 * float(100 - VividNow) + 0.5), 0, 255));
	}
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
		FrameLayer[i] = Ghost(Tap.Frame, 255 / (i + 1));
	for (i = 0; i < 9; i++)
	{
		SoftLayer1[i] = Ghost(Soft[0], 255 / (i + 1));
		SoftLayer2[i] = Ghost(Soft[1], 255 / (i + 1));
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
simulated function Material Ghost(Material Pic, int Alpha)
{
	return class'KFFXMat'.static.Paint(SoftMade, Level,
		class'KFFXMat'.static.Mix(SoftMade, Level, class'KFFXMat'.static.Tone(SoftMade, Level, 255, Alpha), Pic, 2), 0);
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
	Shut(VividReady);
	Shut(VividLay);
	Shut(VividFade);
	if (bAOMade)
		DropAO();
	class'KFFXMat'.static.FreeAll(VividMade, Level);
	bVividMade = false;
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

// The shading's pictures, drawn when they are asked for
simulated function bool RenderAO(ScriptedTexture Tex, Color W)
{
	local int i, j;

	if (Tex == AODep)
		Tex.DrawTile(0, 0, AOW, AOH, 0, 0, AOW, AOH, AODepOver, W);
	else if (Tex == AOFade)
		Tex.DrawTile(0, 0, AOW, AOH, 0, 0, AOW, AOH, AOFadeOver, W);
	else if (Tex == AOWeight)
		Tex.DrawTile(0, 0, 4, 4, 0, 0, 4, 4, AOWeightOver, W);
	else if (Tex == AOLow)
		Tex.DrawTile(0, 0, AOW, AOH, 0, 0, AOW, AOH, AOLowOver, W);
	else if (Tex == AOPlus || Tex == AOMinus)
	{
		Tex.DrawTile(0, 0, AOW, AOH, 0, 0, 1, 1, AOClear, W);
		for (i = 0; i < AOPlusTap.Length; i++)
		{
			if (Tex == AOPlus)
				Tex.DrawTile(0, 0, AOW, AOH, 0, 0, AOW, AOH, AOPlusTap[i], W);
			else
				Tex.DrawTile(0, 0, AOW, AOH, 0, 0, AOW, AOH, AOMinusTap[i], W);
		}
	}
	else if (Tex == AOPic)
		Tex.DrawTile(0, 0, AOW, AOH, 0, 0, AOW, AOH, AOPicOver, W);
	else if (Tex == AOSoft)
	{
		// (the middle one first, then the eight round it)
		for (i = 0; i < 9; i++)
		{
			j = i + 4;
			if (j >= 9)
				j -= 9;
			Tex.DrawTile(0, 0, AOW, AOH, j - (j / 3) * 3 - 1, j / 3 - 1, AOW, AOH, AOSoftLayer[i], W);
		}
	}
	else
	{
		for (i = 0; i < 6; i++)
			if (AOFar[i] != None && Tex == AOFar[i])
			{
				Tex.DrawTile(0, 0, AOW, AOH, 0, 0, AOW, AOH, AOFarOver[i], W);
				return true;
			}
		return false;
	}
	return true;
}

simulated event RenderTexture(ScriptedTexture Tex)
{
	local Color W;
	local float FW, FH;
	local int i, j, n;

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

	if (bAOMade && RenderAO(Tex, W))
		return;
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
		for (i = 0; i < n; i++)
			for (j = 0; j < n; j++)
				Tex.DrawTile(0, 0, 512, 512, Spread(i, n) * FW / 512.0, Spread(j, n) * FH / 512.0, FW, FH, BrightTap, W);
	}
	else if (bVividMade && Tex == VividGrey)
		Tex.DrawTile(0, 0, 4, 4, 0, 0, 1, 1, VividFill, W);
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
		// (the colours the sharp view has: the two softer pictures are made from this one)
		if (bVividMade && VividNow > 100)
			Tex.DrawTile(0, 0, SoftW[0], SoftH[0], 0, 0, FW, FH, VividMat, W);
	}
}

defaultproperties
{
     bBloom=True
     bHitBlur=True
     bVivid=True
     bAO=True
     bTorch=True
     AOStrength=0.600000
     AOShrink=2.000000
     AORange=700.000000
     AOBias=1
     AORing=8.000000
     AORings=4
     AOWindow=3.000000
     VividMuch=120
     VividRest=0.250000
     VividPerRich=30.000000
     BloomGain=0.600000
     BloomCut=110
     BlurPerDamage=0.025000
     BlurMin=0.250000
     BlurSmallHit=5.000000
     BlurShrink=3.750000
     BlurHold=0.200000
     BlurFadeTime=1.400000
     BlurPeak=0.850000
     DrawType=DT_None
     bHidden=True
     RemoteRole=ROLE_None
     bGameRelevant=True
}
