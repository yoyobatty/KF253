//=============================================================================
// KFNightVision - the Commando's night vision. The player switches it by
// holding the flashlight key (KFPlayerController.TorchKey); only a Commando
// has it.
//
// Only on the player's own machine. The HUD draws it every frame after the
// weapon and before the HUD itself (HUDKillingFloor.DrawNightVision):
//   - an illuminator at the eyes, a light only this player has, so what is
//     close shows up in the dark (KFNightLamp);
//   - the view amplified and turned green: green alone is kept, Gain times
//     over (red and blue are dropped). Nothing here can mix red, green and
//     blue, so this is the nearest to one colour: what is lit red or blue
//     goes dark instead of green; any red kept shows through as red or brown;
//   - a dark green floor and moving grain, both most seen where it is dark;
//   - fine scanlines, a faint band rolling down the screen, darker edges;
//   - more glow round lights (KFScreenFX.NightGlow);
//   - switched on, the picture flares and settles.
// Tune with "set KFNightVision Gain 1.8" and so on.
//=============================================================================
class KFNightVision extends Actor;

#exec TEXTURE IMPORT NAME=NVGrain FILE=..\KFMod254\KFMod\Textures\NVGrain.tga MIPS=OFF
#exec TEXTURE IMPORT NAME=NVVignette FILE=..\KFMod254\KFMod\Textures\NVVignette.tga MIPS=OFF ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP

var() float		Gain;				// how many times brighter the green comes out
var() float		TintRed, TintBlue;	// red's and blue's gain, each as a share of green's
var() color		Floor;				// added everywhere: the darkest parts are never quite black
var() color		GrainColor;			// the grain, added
var() float		GrainPixels;		// screen pixels to a speck of grain on a screen 1080 lines high
var() float		GrainRate;			// new grain this many times a second
var() float		ScanLines;			// scanlines down the screen
var() float		ScanDark;			// how much a scanline darkens (1 is to black)
var() float		RollDark;			// how much the rolling band darkens at its middle
var() float		RollHeight;			// its height, as a share of the screen's
var() float		RollTime;			// seconds for it to roll from top to bottom
var() float		EdgeDark;			// how dark the edges and corners go
var() float		FadeTime;			// seconds to come on
var() float		FlareTime;			// seconds for the start-up flare to settle
var() float		FlareGain;			// extra gain at the very start, as a share of Gain
var() color		FlareColor;			// laid over the view at the very start, added
var() float		LampBrightness;		// the illuminator (0 for none)
var() float		LampRadius;

var KFNightLamp	Lamp;
var KFScreenFX	FX;
var float		On, LastDraw, StartTime, GrainU, GrainV, NextGrain;
var bool		bActive;

// The scale of a colour, each part times S
final function color Scaled(color Col, float S)
{
	Col.R = byte(FClamp(float(Col.R) * S, 0.0, 255.0));
	Col.G = byte(FClamp(float(Col.G) * S, 0.0, 255.0));
	Col.B = byte(FClamp(float(Col.B) * S, 0.0, 255.0));
	return Col;
}

// A colour part that multiplies by G in N passes, each doubled (128 leaves it as it is)
final function byte PassPart(float G, int N)
{
	return byte(FClamp(127.5 * (FMax(G, 0.0) ** (1.0 / float(N))), 0.0, 255.0));
}

final function Fill(Canvas C, float Y, float H)
{
	C.SetPos(0, Y);
	C.DrawTile(Texture'Engine.WhiteTexture', C.ClipX, H, 0, 0, 1, 1);
}

function Draw(Canvas C, PlayerController PC)
{
	local float DT, G, Flare, P, H, Y, Top, BandH, A;
	local int i, n;
	local plane OldModulate;
	local color OldColor, Col;
	local byte OldStyle;

	DT = FClamp(Level.TimeSeconds - LastDraw, 0.0, 0.25);
	LastDraw = Level.TimeSeconds;
	if (!bActive)
	{
		bActive = true;
		StartTime = Level.TimeSeconds;
		On = 0.0;
		DT = 0.0;
	}
	On = FMin(1.0, On + DT / FMax(FadeTime, 0.01));
	Flare = FClamp(1.0 - (Level.TimeSeconds - StartTime) / FMax(FlareTime, 0.01), 0.0, 1.0);
	Flare *= Flare;

	LampOn(PC);
	if (FX == None || FX.bDeleteMe)
		FX = class'KFFrameTap'.static.GetFX(PC);
	if (FX != None)
		FX.NightGlow = On;

	OldModulate = C.ColorModulate;
	OldColor = C.DrawColor;
	OldStyle = C.Style;
	C.ColorModulate.X = 1;
	C.ColorModulate.Y = 1;
	C.ColorModulate.Z = 1;
	C.ColorModulate.W = 1;

	// amplified and green: the view multiplied over in as many passes as the gain needs (each at most doubles it)
	G = Lerp(On, 1.0, Gain * (1.0 + FlareGain * Flare));
	n = 1;
	if (G > 4.0)
		n = 3;
	else if (G > 2.0)
		n = 2;
	Col.R = PassPart(G * Lerp(On, 1.0, TintRed), n);
	Col.G = PassPart(G, n);
	Col.B = PassPart(G * Lerp(On, 1.0, TintBlue), n);
	Col.A = 255;
	C.Style = ERenderStyle.STY_Modulated;
	C.DrawColor = Col;
	for (i = 0; i < n; i++)
		Fill(C, 0, C.ClipY);

	// added: the floor, the grain (fresh GrainRate times a second) and the start-up flare
	C.Style = ERenderStyle.STY_Translucent;
	C.DrawColor = Scaled(Floor, On);
	Fill(C, 0, C.ClipY);
	if (Level.TimeSeconds >= NextGrain || Level.TimeSeconds < NextGrain - 1.0)
	{
		GrainU = FRand() * 256.0;
		GrainV = FRand() * 256.0;
		NextGrain = Level.TimeSeconds + 1.0 / FMax(GrainRate, 1.0);
	}
	P = FMax(1.0, GrainPixels * C.ClipY / 1080.0);
	C.DrawColor = Scaled(GrainColor, On * (1.0 + Flare));
	C.SetPos(0, 0);
	C.DrawTile(Texture'KFMod.NVGrain', C.ClipX, C.ClipY, GrainU, GrainV, C.ClipX / P, C.ClipY / P);
	if (Flare > 0.0)
	{
		C.DrawColor = Scaled(FlareColor, Flare);
		Fill(C, 0, C.ClipY);
	}

	// darkened: the scanlines, every P pixels and H high...
	C.Style = ERenderStyle.STY_Alpha;
	if (ScanDark > 0.0)
	{
		C.DrawColor = class'Canvas'.static.MakeColor(0, 0, 0, byte(FClamp(255.0 * ScanDark * On, 0.0, 255.0)));
		P = FMax(2.0, float(int(C.ClipY / FMax(ScanLines, 1.0) + 0.5)));
		H = FMax(1.0, float(int(P / 3.0 + 0.5)));
		for (Y = 0; Y < C.ClipY; Y += P)
			Fill(C, Y, H);
	}
	// ...the band rolling down, soft at both edges (twelve strips)...
	if (RollDark > 0.0 && RollTime > 0.0)
	{
		BandH = C.ClipY * RollHeight;
		Top = ((Level.TimeSeconds % RollTime) / RollTime) * (C.ClipY + BandH) - BandH;
		for (i = 0; i < 12; i++)
		{
			A = RollDark * On * Sin(3.14159 * (float(i) + 0.5) / 12.0);
			C.DrawColor = class'Canvas'.static.MakeColor(0, 0, 0, byte(FClamp(255.0 * A, 0.0, 255.0)));
			Fill(C, Top + BandH * float(i) / 12.0, BandH / 12.0 + 1.0);
		}
	}
	// ...and the edges
	if (EdgeDark > 0.0)
	{
		C.DrawColor = class'Canvas'.static.MakeColor(255, 255, 255, byte(FClamp(255.0 * EdgeDark * On, 0.0, 255.0)));
		C.SetPos(0, 0);
		C.DrawTile(Texture'KFMod.NVVignette', C.ClipX, C.ClipY, 0, 0, 128, 128);
	}

	C.ColorModulate = OldModulate;
	C.DrawColor = OldColor;
	C.Style = OldStyle;
}

// The illuminator, a little ahead of the eyes
function LampOn(PlayerController PC)
{
	if (LampBrightness <= 0.0)
	{
		if (Lamp != None)
			Lamp.bDynamicLight = false;
		return;
	}
	if (Lamp == None)
	{
		Lamp = Spawn(class'KFNightLamp', PC);
		if (Lamp == None)
			return;
	}
	Lamp.LightBrightness = LampBrightness * On;
	Lamp.LightRadius = LampRadius;
	Lamp.bDynamicLight = true;
	Lamp.SetLocation(PC.CalcViewLocation + vector(PC.CalcViewRotation) * 24.0);
}

function Off()
{
	bActive = false;
	On = 0.0;
	if (Lamp != None)
		Lamp.bDynamicLight = false;
	if (FX != None && !FX.bDeleteMe)
		FX.NightGlow = 0.0;
}

simulated function Destroyed()
{
	Off();
	if (Lamp != None)
		Lamp.Destroy();
	Super.Destroyed();
}

defaultproperties
{
     Gain=1.500000
     TintRed=0.000000
     TintBlue=0.050000
     Floor=(R=9,G=14,B=10,A=255)
     GrainColor=(R=22,G=36,B=26,A=255)
     GrainPixels=1.600000
     GrainRate=50.000000
     ScanLines=360.000000
     ScanDark=0.220000
     RollDark=0.060000
     RollHeight=0.220000
     RollTime=7.000000
     EdgeDark=0.800000
     FadeTime=0.120000
     FlareTime=0.600000
     FlareGain=0.800000
     FlareColor=(R=40,G=70,B=45,A=255)
     LampBrightness=20.000000
     LampRadius=48.000000
     DrawType=DT_None
     bHidden=True
     RemoteRole=ROLE_None
}
