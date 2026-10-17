//=============================================================================
// KFAOEye - one of the two pictures of the player's own view that the
// shading in corners (KFScreenFX, ambient occlusion) is worked out from.
//
// The view is taken again, the screen's shape and smaller, in fog that
// thickens evenly from the eye to AORange: once in white fog, once in black.
// A thing's colour is pulled toward the fog's by how far off it is, so the
// white picture less the black has nothing of the thing's own colour left in
// it: it is how far away everything is.
//
// Both are in plain textures with none of the level's lighting, and without
// what glows or is laid on surfaces (sparks, smoke, flares, decals, the
// torch). The fog is the eye's zone's own, set for the length of the picture
// and put back after; the sky's zone is given fog that is solid at once, so
// the sky reads as far as anything can be, and so does all that the picture's
// far end cuts off.
//=============================================================================
class KFAOEye extends Actor;

var KFScreenFX		FX;
var bool			bGrey;			// the white fog's picture (else the black's)
var int				W, H;
var ScriptedTexture	View;
var FinalBlend		Unseen;			// draws View without changing the screen (drawing it has it made)
var Actor			CamActor;
var rotator			CamRot;
var int				CamFOV;

// What the renderer leaves out of a view at a word: particle systems, the flares round lamps, everything projected
const VeilShow = 0x21400000;

simulated function Init(KFScreenFX F, int Width, int Height, bool bIsGrey)
{
	FX = F;
	W = Width;
	H = Height;
	bGrey = bIsGrey;
	View = ScriptedTexture(Level.ObjectPool.AllocateObject(class'ScriptedTexture'));
	View.SetSize(W, H);
	View.Client = self;
	View.UClampMode = TC_Clamp;
	View.VClampMode = TC_Clamp;

	Unseen = FinalBlend(Level.ObjectPool.AllocateObject(class'FinalBlend'));
	Unseen.Material = View;
	Unseen.FrameBufferBlending = FB_Invisible;
	Unseen.ZWrite = false;
	Unseen.ZTest = false;
	Unseen.AlphaTest = false;
	Unseen.TwoSided = false;
}

simulated event Destroyed()
{
	CamActor = None;
	if (View != None)
	{
		View.Client = None;
		View.UClampMode = TC_Wrap;
		View.VClampMode = TC_Wrap;
		Unseen.Material = None;
		Unseen.FrameBufferBlending = FB_Overwrite;
		Unseen.ZWrite = true;
		Unseen.ZTest = true;
		Level.ObjectPool.FreeObject(View);
		Level.ObjectPool.FreeObject(Unseen);
		View = None;
		Unseen = None;
	}
	FX = None;
	Super.Destroyed();
}

// The picture is wanted for this frame: it is drawn when something is next drawn with it
simulated function Take(Actor Cam, vector Eye, rotator Rot, int FOV)
{
	// (it stands at the eye, so that the zone whose fog it sets is the eye's)
	SetLocation(Eye);
	CamActor = Cam;
	CamRot = Rot;
	CamFOV = FOV;
	View.Revision++;
}

simulated event RenderTexture(ScriptedTexture Tex)
{
	local ZoneInfo Z, S;
	local bool bWasFog, bWasClear, bSkyFog, bSkyClear;
	local float WasStart, WasEnd, WasBlend, WasSince, WasReach, SkyStart, SkyEnd, SkyBlend;
	local color WasColor, SkyColor, Fog;
	local int WasMap, WasZone, WasShown;
	local PlayerController PC;

	if (FX == None || CamActor == None || Tex != View)
		return;
	PC = FX.PC;
	Z = Region.Zone;
	if (Z == None || PC == None)
		return;
	if (bGrey)
	{
		Fog.R = 255;
		Fog.G = 255;
		Fog.B = 255;
	}
	Fog.A = 255;
	// (the renderer blends fog as the viewer goes from zone to zone: what it keeps for that is put back after; and
	// how far it last drew, which would cut this picture off at the view's own far end)
	WasZone = PC.LastZone;
	WasSince = PC.TimeSinceLastFogChange;
	WasReach = PC.CurrentDistanceFogEnd;
	PC.CurrentDistanceFogEnd = 0.0;
	bWasFog = Z.bDistanceFog;
	bWasClear = Z.bClearToFogColor;
	WasStart = Z.DistanceFogStart;
	WasEnd = Z.DistanceFogEnd;
	WasBlend = Z.DistanceFogBlendTime;
	WasColor = Z.DistanceFogColor;
	Z.bDistanceFog = true;
	Z.bClearToFogColor = true;
	Z.DistanceFogStart = 0.0;
	Z.DistanceFogEnd = FMax(FX.AORange, 100.0);
	Z.DistanceFogBlendTime = 0.0;
	Z.DistanceFogColor = Fog;
	// (the sky is as far away as anything can be: fog that is solid from the first step)
	S = Z.SkyZone;
	if (S == Z)
		S = None;
	if (S != None)
	{
		bSkyFog = S.bDistanceFog;
		bSkyClear = S.bClearToFogColor;
		SkyStart = S.DistanceFogStart;
		SkyEnd = S.DistanceFogEnd;
		SkyBlend = S.DistanceFogBlendTime;
		SkyColor = S.DistanceFogColor;
		S.bDistanceFog = true;
		S.bClearToFogColor = true;
		S.DistanceFogStart = 0.0;
		S.DistanceFogEnd = 1.0;
		S.DistanceFogBlendTime = 0.0;
		S.DistanceFogColor = Fog;
	}
	// (sparks, smoke, flares and what is laid on surfaces are left out: in fog a bright one passes for something
	// solid; and the fog of a volume the player stands in, which would be put in place of the zone's)
	WasShown = PC.ShowFlags & VeilShow;
	PC.ShowFlags = PC.ShowFlags & ~VeilShow;
	FX.FogVolumes(true);
	// (6 is plain textures: no lighting, and cheaper)
	WasMap = PC.RendMap;
	PC.RendMap = 6;
	Tex.DrawPortal(0, 0, W, H, CamActor, Location, CamRot, CamFOV, true);
	PC.RendMap = WasMap;
	FX.FogVolumes(false);
	PC.ShowFlags = PC.ShowFlags | WasShown;

	if (S != None)
	{
		S.bDistanceFog = bSkyFog;
		S.bClearToFogColor = bSkyClear;
		S.DistanceFogStart = SkyStart;
		S.DistanceFogEnd = SkyEnd;
		S.DistanceFogBlendTime = SkyBlend;
		S.DistanceFogColor = SkyColor;
	}
	Z.bDistanceFog = bWasFog;
	Z.bClearToFogColor = bWasClear;
	Z.DistanceFogStart = WasStart;
	Z.DistanceFogEnd = WasEnd;
	Z.DistanceFogBlendTime = WasBlend;
	Z.DistanceFogColor = WasColor;
	PC.LastZone = WasZone;
	PC.TimeSinceLastFogChange = WasSince;
	PC.CurrentDistanceFogEnd = WasReach;
}

defaultproperties
{
     DrawType=DT_None
     bHidden=True
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
     RemoteRole=ROLE_None
     bGameRelevant=True
}
