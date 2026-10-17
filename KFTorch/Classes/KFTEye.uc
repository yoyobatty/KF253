//=============================================================================
// KFTEye - one of the three pictures the tactical light (KFTLight) takes from
// where it is, each frame, looking the way it points.
//
// None is a picture of how far away things are; the engine has no such
// picture to give. But two are taken in fog, which thickens evenly from the
// light to the end of its reach: one in white fog, one in black. In white fog
// a thing's colour is pulled toward white by how far away it is; in black fog
// toward black by the same amount. Take the black picture from the white one
// and the thing's own colour is gone from the answer: what is left is how far
// away it is, and nothing else.
//
// The third is taken without fog: what the light falls on, each way it looks.
//
// All three are in plain textures with none of the level's lighting (the
// render mode the editor calls Textured, set on the viewer for the length of
// the picture). The fog is the zone's own distance fog, set for the length of
// the picture and put back after it.
//=============================================================================
class KFTEye extends Actor;

var KFTLight		Lamp;
var bool			bWhite;			// the white fog's picture (else the black's)
var bool			bPlain;			// neither: no fog
var int				Size;
var ScriptedTexture	View;			// the picture
var FinalBlend		Unseen;			// draws View without changing the screen (the screen hook does, to have it drawn)
var Actor			CamActor;		// whose eyes the picture is taken with (what that one does not see of itself is not in it)

simulated function Init(KFTLight L, int S)
{
	Lamp = L;
	Size = S;
	View = ScriptedTexture(Level.ObjectPool.AllocateObject(class'ScriptedTexture'));
	View.SetSize(Size, Size);
	View.Client = self;

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
		Unseen.Material = None;
		Unseen.FrameBufferBlending = FB_Overwrite;
		Unseen.ZWrite = true;
		Unseen.ZTest = true;
		Level.ObjectPool.FreeObject(View);
		Level.ObjectPool.FreeObject(Unseen);
		View = None;
		Unseen = None;
	}
	Lamp = None;
	Super.Destroyed();
}

// The picture is wanted for this frame: it is drawn when something is next drawn with it
simulated function Take(Actor Cam)
{
	// (it stands where the light is, so that the zone whose fog it sets is the light's)
	SetLocation(Lamp.Apex);
	CamActor = Cam;
	View.Revision++;
}

simulated event RenderTexture(ScriptedTexture Tex)
{
	local ZoneInfo Z;
	local bool bWasFog, bWasClear;
	local float WasStart, WasEnd, WasBlend, WasSince, WasReach;
	local color WasColor, Fog;
	local int WasMap, WasZone;
	local PlayerController PC;

	if (Lamp == None || CamActor == None || Tex != View)
		return;
	PC = Lamp.PC;
	Z = Region.Zone;
	if (Z == None || PC == None)
	{
		Tex.DrawPortal(0, 0, Size, Size, CamActor, Lamp.Apex, rotator(Lamp.Aim), Lamp.FOV, true);
		Lamp.After(self);
		return;
	}
	// (the renderer blends fog as the viewer goes from zone to zone, and takes a picture from another zone for the
	// viewer going there: what it keeps for that is put back after)
	WasZone = PC.LastZone;
	WasSince = PC.TimeSinceLastFogChange;
	// (and how far it last drew: a view is cut off at the larger of the zone's fog end and that. Left as a picture
	// without fog leaves it, the player's own view, drawn next, was cut off nowhere, and all that the fog hides was
	// drawn behind it. Set to nothing for the picture, so that the picture ends where its own fog does.)
	WasReach = PC.CurrentDistanceFogEnd;
	if ((Lamp.Skip & 512) == 0)
		PC.CurrentDistanceFogEnd = 0.0;
	bWasFog = Z.bDistanceFog;
	bWasClear = Z.bClearToFogColor;
	WasStart = Z.DistanceFogStart;
	WasEnd = Z.DistanceFogEnd;
	WasBlend = Z.DistanceFogBlendTime;
	WasColor = Z.DistanceFogColor;

	if (bWhite)
	{
		Fog.R = 255;
		Fog.G = 255;
		Fog.B = 255;
	}
	Fog.A = 255;
	Z.bDistanceFog = !bPlain;
	Z.bClearToFogColor = !bPlain;
	Z.DistanceFogStart = Lamp.FogStart;
	Z.DistanceFogEnd = Lamp.Range;
	// (The picture of what the light falls on has no fog to tell distance by, but it need not go on past where the
	// light ends: black fog that begins a few units short of there and ends there leaves all before it as it is,
	// and the renderer draws nothing past a fog's end.)
	if (bPlain && Lamp.PlainEnd > 0.0 && (Lamp.Skip & 1024) == 0)
	{
		Z.bDistanceFog = true;
		Z.bClearToFogColor = true;
		Z.DistanceFogStart = Lamp.PlainEnd - 8.0;
		Z.DistanceFogEnd = Lamp.PlainEnd;
	}
	Z.DistanceFogBlendTime = 0.0;
	Z.DistanceFogColor = Fog;

	// (sparks, glows and smoke are left out: in fog a bright one passes for something solid, and throws a shadow)
	Lamp.Veil(true);
	// (and the fog of a volume the player stands in, which would be put in place of the zone's)
	Lamp.FogVolumes(true);
	// (and from the picture of what the light falls on, the bodies that are lit in their own colours)
	if (bPlain)
		Lamp.Bare(true);
	// (6 is plain textures; what it was is lit ones)
	WasMap = PC.RendMap;
	PC.RendMap = 6;
	Tex.DrawPortal(0, 0, Size, Size, CamActor, Lamp.Apex, rotator(Lamp.Aim), Lamp.FOV, true);
	PC.RendMap = WasMap;
	if (bPlain)
		Lamp.Bare(false);
	Lamp.FogVolumes(false);
	Lamp.Veil(false);

	Z.bDistanceFog = bWasFog;
	Z.bClearToFogColor = bWasClear;
	Z.DistanceFogStart = WasStart;
	Z.DistanceFogEnd = WasEnd;
	Z.DistanceFogBlendTime = WasBlend;
	Z.DistanceFogColor = WasColor;
	PC.LastZone = WasZone;
	PC.TimeSinceLastFogChange = WasSince;
	if ((Lamp.Skip & 512) == 0)
		PC.CurrentDistanceFogEnd = WasReach;

	Lamp.After(self);
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
