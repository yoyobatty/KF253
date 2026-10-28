//=============================================================================
// KFTLight - the tactical light on the 9mm, as a light worked out at every
// pixel: a hot middle, an even pool and a dim wide spill, in the colours of
// what it falls on; falling away with distance and as a surface turns from
// it; and stopped by what it hits, so that whatever stands in the beam throws
// a shadow. It takes the place of the mod's own projector and its glow.
//
// No shader and no depth picture from the engine. How it is done:
//
//   Three pictures are taken from the light each frame, looking the way it
//   points (KFTEye), all in plain textures with none of the level's lighting:
//   one in white fog, one in black, one in none.
//
//   The white less the black is how far the light can see, each way it looks
//   (Depth). Every point the projector draws knows how far along the beam it
//   is: a ramp laid on it by its place (KFTRamp). How far the light sees,
//   less how far the point is, is more than nothing if the point is what the
//   light sees there, and nothing if something nearer is in the way. That is
//   multiplied by sixty-four, to make all-or-nothing of it (Gate).
//
//   The third picture times the light's pattern and the bulb's colour is what
//   the light throws (Flux): each way it looks, the colour of the first thing
//   it meets that way, which is the thing it lights. So it does not matter
//   what a surface is made of.
//
//   Gate times Flux is the projector's material. It is the kind of projector
//   the renderer looks up for itself each frame, which it weighs by how
//   squarely a surface faces the light: on a model at every pixel, on the
//   level's own walls and floors from the wall's one normal, measured against
//   the middle of the beam. That leaves a floor the beam runs along all but
//   dark, so the light is thrown in two halves (Lean): one weighed, and one,
//   from a second projector (Fill), on whatever the beam reaches.
//
//   Players and creatures are lit by a third projector, fixed each frame to
//   the bodies in the beam (Shade), and in their own colours: that one is
//   laid on each body's own skin, and what it throws is the light's pattern
//   where the body is what the light sees. So the bodies are left out of the
//   picture of what the light falls on. Were they in it, whatever stood just
//   behind one (nearer than a shadow can start) would be lit with its face.
//   A body whose skin is made of several textures cannot be lit so: it is
//   left in that picture and lit from it, as the level is (ShadeX).
//
//   The fog the pictures are taken in ends a little past what the beam lands
//   on, so that the 256 steps of distance a picture holds are spent on the
//   room: a shadow starts 10 units behind what throws it where the beam lands
//   near, 45 at the light's full reach.
//
//   A shadow's edge is soft, as it is from a light that has some width: just
//   outside a shadow part of the light is hidden. How much, a point cannot ask
//   as it is drawn (every texture unit is spoken for), so it is worked out
//   beforehand, in the light's own view, for the one thing the light sees each
//   way it looks (Pen): twenty places round about are looked at in the picture
//   of how far the light sees, in four rings, and each where something stands
//   nearer takes a share of the light. How much nearer it has to be goes by
//   the ring and by the distance (Need): the further to one side, the bigger
//   the gap has to be. So an edge is all but hard where a shadow falls just
//   behind what throws it, and widens with the gap. Whoever holds the light
//   sees a shadow only by as much as the light is to one side of the eye,
//   which is less the further off the thing that throws it, so with distance
//   the soft edge takes up more and more of what is seen of a shadow. It is
//   wider again on a failing battery. All of it is multiplied into what the
//   light throws, so it costs no drawing of the scene: two dozen flat
//   pictures a frame, under a tenth of a thousandth of a second.
//   (It is the outer half of a soft edge only: a shadow grows by it. The dark
//   middle is as it was, since nothing but the first thing the light sees
//   each way can be lit in part.)
//
//   What can be seen through (plastic sheeting, glass, a stain or writing
//   laid over a wall) is none of the light's pictures' business: a picture
//   has such a thing and what is behind it run together, in colour and in
//   distance. So these are found once in the level, left out of the pictures
//   (the light goes through them), kept clear of the light's own cones, and
//   lit by cones of their own, as bodies are, by how solid they are: in their
//   own colours (Sheen) or, where that cannot be done, in the light's
//   (SheenX). What is cut out and not seen through, a wire fence, stays in
//   the pictures and throws the shadow of its wires. Where the cut is one
//   the renderer cannot follow when it lays a cone on the thing (a bush of
//   cards cut out by a FinalBlend), the cones are kept off it: it throws its
//   shadow and is not lit.
//
// Where the light is: on the weapon. After each frame the screen hook
// (KFTHud) notes where the weapon's light bone was from the eye, and which
// way it pointed; before the next frame the light is put there from where the
// eye then is. So it follows the view with no lag and sways with the weapon.
//
// What it costs: the scene drawn three more times from the light, and what is
// in the cone drawn twice more with the light on it. With a dozen creatures
// in a corridor that was 4.7 thousandths of a second a frame, 3 of them the
// three pictures. Thrift: the pictures are taken every other frame, and the
// light stays for a frame where it was when they were taken (it trails the
// weapon by a frame). 0 never, 1 always, 2 when frames are slow and the view
// is all but still (in a turn a light that stays behind every other frame is
// seen to judder).
//
// This machine's own: it is made for the light of whoever plays here
// (KFTBeam), and nobody else sees it. PictureSize, Soft, bThrowBack,
// BounceGain, Thrift, SheerGain and Edge (with Spread, EdgeDark, FadeBy and
// DimSoft, which Edge goes by) are kept in the mod's user ini, under
// [KFTorch.KFTLight].
//=============================================================================
class KFTLight extends Projector
	config(User);

var PlayerController	PC;
var Pawn			Holder;				// whose light it is
var bool			bLit;				// switched on
var float			Bright;				// 0 to 1: what the battery gives
var float			Warm;				// 0 to 1: how far the bulb has gone toward amber
var() float			Reach;				// from the light itself to where its cone begins to light
var vector			Apex, Aim;			// where the light is and the way it points, this frame
var vector			Rel, RelAim;		// where it was from the eye, and the way it pointed, when the weapon was last drawn
var bool			bRel;
var() config int	PictureSize;		// the light's pictures, pixels across
var() config int	Cone;				// the light's whole cone, degrees: 100 as its pattern was drawn, less and all of it is narrower (pool, hot middle and spill alike)
var() config array<string>	Omit;		// see-through models the light is to leave alone: parts of their names ("mutate torch omit")
var() config int	DepthSize;			// the pictures of how far the light sees, pixels across (no more than PictureSize)
var int				SoftSize;			// the soft edge's own pictures, pixels across (no more than 1024)
var float			FogStart;			// where the fog begins this frame: a little short of the nearest thing in the beam, spill and all
var float			NearLines;			// (the nearest that the lines through the beam landed this frame)
var float			EdgeNear[8];		// (how near the level is along eight lines round the spill's edge, as last looked at)
var int				EdgeTurn;			// (which of them is looked at next)
var vector			EdgeAim;			// (the way the light pointed when they were last all thrown away)
var float			NearAt;				// (when the fog's start was last pulled in)
var() float			NearShare, NearLess;	// the fog begins this share of the way to the nearest thing, less this much
var() int			FloorSteps;			// how many of the 256 steps of distance stand for "nearer than where the fog begins"
var ConstantColor	FloorK, StartK[4];
var Material		FloorOver, StartOver[4];
var() config int	Soft;				// how the light is weighed by the way a surface faces it (Lean)
var() config bool	bThrowBack;			// the light a lit surface throws back into the room (KFTBounce)
var() config float	BounceGain;			// ...and how much of it
var() config int	Thrift;				// the pictures taken every other frame: 0 never, 1 always, 2 when frames take long
var bool			bSparing;			// (they are being taken every other frame just now)
var bool			bSkipped;			// (and were not taken in the last frame)
var bool			bYield;				// (another light takes its pictures this frame: these are left as they are, see KFTHud)
var float			LastFrame, Pace;	// when the last frame was, and how long frames take (eased)
var vector			ShotEye, ShotWay;	// where the view was, and the way it looked, when the pictures were last taken
var rotator			ShotTurn;
var config int		Skip;				// (a tool, for timing: 1 no light on bodies, 2 the pictures taken once and kept, 4 no unweighed half, 8 no weighed half,
										// 16 no light on what can be seen through, 32 what such things are made of to the log, 64 they are handled as anything else,
										// 128 the picture of what the light falls on kept, 256 the two fog pictures kept,
										// 512 and 1024 the pictures taken as they were before 2026-10-13: the view's far end left alone, no end to the plain picture,
										// 2048 the cones on the level always their full length, 8192 no light of its own on terrain)
var bool			bHavePictures;
var bool			bShow;				// (a tool: the light's pictures are drawn in the corner of the screen)
var int				ShowPick;			// (a tool: with bShow, one picture alone, as tall as the screen: 1 what the light falls on, 2 the white fog's, 3 the black fog's, 4 how far it sees, 5 what it throws, 6 what a body is lit with, 7 the soft edges)
var() float			Throw;				// how far the light would reach, falling away evenly from the bulb to nothing there
var float			FarMost;			// how far it does reach: where its cones end at their longest. It falls away faster over the last of the way
var int				FallBend, FallEnd;	// (the rows of the fall's picture where that begins, and where the light is gone)
var() float			MaxRange, MinRange;	// the most and the least the fog is ever set to end at
var float			Range;				// where the fog ends this frame
var float			PlainEnd;			// where the picture of what the light falls on ends this frame, from the light
var float			FarLit;				// how far from the light its cones on the level reach this frame
var float			Deepest5;			// (the furthest the five lines down the middle of the beam went this frame)
var vector			Deepest5At;			// (...and where that was)
var vector			FarAt;				// the furthest place the beam has been found to land on, kept while it is in the beam and in sight
var bool			bFarAt;
var int				FarQuiet;			// (how many frames since the cones last had to reach further)
var float			FarGrew;			// (when they last had to reach further)
var bool			bSpillLine;			// (the second of this frame's two chance lines goes through the spill, not the pool)
var float			ConeShare;			// how far along its middle a cone's far end is, as a share of its length
var() float			FarSpare, FarMore, FarLeast;	// the cones reach this many times as far as the beam goes, and this much more; and never less than this
var() float			FarHold;			// how long the cones stay as long as they are after the beam last went that far
var() int			FarFrames;			// ...and for how many frames at the least
var() float			PoolWide, SpillWide;	// how far out a chance line goes, for one along the beam: in the pool, and in the spill round it
var() int			Slack;				// how many of the 256 steps of distance a lit point may read too far by
var() config float	Edge;				// how soft a shadow's edge is: 0 as hard as the pictures give it, 1 the usual
var() config float	Spread;				// the angle the light is taken to fill, seen from what it lights, in degrees: what a soft edge's width comes from
var() config float	EdgeDark;			// the share of the light that each nearer thing found to one side takes
var() config float	FadeBy;				// how far from the light the soft edge would have faded to nothing (it guards what is far off and seen edge on)
var() config float	DimSoft;			// how much wider the soft edge is on a battery all but spent (1: twice)

var KFTEye			EyeW, EyeB, EyeA;	// the pictures: white fog, black fog, none
var ScriptedTexture	Depth;				// how far the light sees, each way it looks
var ScriptedTexture	FluxFull, FluxHalf;	// what the light throws each way: the plain picture times its pattern; and half that
var ConstantColor	Tint;				// the bulb: its colour, and how bright
var Material		Diff, Gate;
var Material		DepthOver, DepthSeen, FullOver, FullSeen, HalfOver, HalfSeen;
var Material		LitFull, LitHalf;	// the light's material: whole, and at half strength
var Material		Cookie;				// the light's pattern: the hot middle, the pool and the spill (a muzzle flash has its own)
var ScriptedTexture	Pattern;			// the light's pattern in the bulb's colour, for what is lit in its own colours
var Material		PatternOver, PatternSeen;
var Material		LitBody;			// the light's material for a body: where it is what the light sees, the pattern
var color			PatternFor;			// (the bulb's colour the pattern was last made in)
var bool			bPatternMade;
var ScriptedTexture	Need[4];			// how much nearer than what the light sees a thing has to be to take light from it, ring by ring
var ScriptedTexture	Deep;				// the share each such thing takes
var ScriptedTexture	Pen;				// how much of the light gets past the things beside its way, each way it looks
var ConstantColor	NeedK[4], BiasK, DeepK, FadeK;
var Combiner		NeedMix[4];
var Material		NeedOver[4], NeedSeen[4], BiasOver, DeepOver, FadeOver, DeepSeen, PenClear, PenSeen;
var array<Material>	TapOver;			// one for each of the places looked at
var Material		FullOverSoft, HalfOverSoft, PatternOverSoft;	// what the light throws, times Pen
var() int			RingTaps[4];		// how many places are looked at in each ring: 1, 2, 4 and 8 1024ths of the picture out
var() float			RingTurn[4];		// (and how far round the first of them is, in shares of the step between them)
var bool			bSoftNow;			// (the edges are being softened this frame)
var bool			bPatternSoft;		// (the pattern was last made with Pen in it)
var TexMatrix		RampLay;
var ScriptedTexture	FallPic;			// how the light falls away with distance, as a picture a material can take colour from
var Material		FallClear, FallOver, FallSeen;
var TexMatrix		FallLay;			// ...laid along the beam
var Material		LitFullFall, LitHalfFall;	// the light's material with that in it
var array<Object>	Made;
var KFTBody			Shade;				// the light on bodies, in their own colours
var KFTBody			ShadeX;				// the light on bodies whose skins are made of several textures
var KFTBody			Ground;				// the light on terrain, on its own colours
var KFTBody			Fill;				// the half of the light that is not weighed by how a surface faces it
var KFTBounce		Bounce;				// what the lit place throws back
var bool			bDressed;
var bool			bOff;				// the projectors are off the level while the pictures are taken
var bool			bGotW, bGotB, bGotA;
var float			LastOn, NextBodies;
var array<Actor>	Bodies;				// who is in the beam
var array<byte>		Plain;				// (which of them are lit in their own colours)
var array<byte>		Bared;				// (which of them are hidden for the length of a picture)
var array<Actor>	Glows;				// sparks, glows and smoke near the beam
var array<byte>		Veiled;				// (which of them are hidden for the length of a picture)
var int				WasShown;			// (what the renderer was showing before a picture)
var bool			bVeiled;
var array<Projector>	Held;			// the game's own shadows, off the level while the pictures are taken
var KFTBody			Sheen;				// the light on what can be seen through, in its own colours
var KFTBody			SheenX;				// ...and on what of it cannot be lit so, in the light's colour
var() config float	SheerGain;			// how much of the light such a thing takes, lit in the light's colour
var() config float	Gain;				// how many times as strong as the bulb at full the light is, 1 to 4 (a muzzle flash is more)
var array<Combiner>	Gained;				// (the last step of each of the light's materials, where whole times over are put on)
var Combiner		LitFullX;			// (the light's material, whole, for bodies of several textures: LitFull's own is in LitFullFall)
var ScriptedTexture	Faint;				// the light's pattern, that much of it
var ConstantColor	FaintK;
var Material		FaintOver, FaintSeen, LitFaint;
var array<Actor>	AllSheer;			// every model in the level that can be seen through
var array<byte>		AllSheerKind;		// (1 lit in its own colours, 2 lit in the light's colour, 3 not lit, 4 solid with parts seen through, lit in its own colours, 5 cut out where the cones cannot follow: in the pictures, not lit)
var bool			bSheerFound;
var array<Actor>	Sheer;				// those of them within the light's reach
var array<byte>		SheerKind;
var array<byte>		SheerHid;			// (which of them are hidden for the length of a picture)
var array<byte>		SheerShun;			// (which of them have the light's cones kept off them for the length of a frame)
var bool			bShunned, bSheerHidden;
var array<Actor>	HolderHid;			// (whoever holds the light, and what they carry, hidden for the length of the pictures)
var array<PhysicsVolume>	FogVols;	// the level's volumes, whose fog is put aside for the length of each of the light's pictures
var array<byte>		FogVolWas;			// (which of them had fog on)
var bool			bFogVolsFound, bFogVolsOff;
var array<StaticMesh>	ThroughMesh;	// models looked at for whether light goes through them somewhere, and what was found
var array<Shader>	SheerShaders;		// what see-through models are made of, made invisible for the length of the light's pictures
var array<byte>		SheerShaderWas;
var array<FinalBlend>	SheerBlends;
var array<byte>		SheerBlendWas;
var bool			bSheerMatsOff;
var FinalBlend		Vanish;				// drawn as nothing: worn by a moving model's see-through parts for the length of the light's pictures
var array<Actor>	SkinOn;				// (the models wearing it just now; for each, which part,
var array<int>		SkinAt;
var array<Material>	SkinWas;			// what it wore there,
var array<int>		SkinLen;			// and how many skins it had)
var array<byte>		ThroughYes;
var float			NextSheer;
var array<StaticMesh>	KnownMesh;		// the models looked at so far, and what was found
var array<string>	KnownKinds;			// (a figure for each of a model's materials)

// What the renderer leaves out of a view at a word: particle systems, the flares round lamps, everything projected;
// and the sky. (Seen through a skylight, the sky is drawn first across the whole picture, so whatever lay past the
// pictures' far end showed the sky, which takes no fog: it read as nearer than anything, and the light threw a
// shadow with straight edges over it. Without the sky a skylight is drawn as the ceiling it is.)
const VeilShow = 0x21400004;

simulated event PostBeginPlay()
{
	local int Wide;
	local KFTHud Hud;

	if (Level.NetMode == NM_DedicatedServer)
		return;
	PC = Level.GetLocalPlayerController();
	// (the pattern is a picture as wide as the cone: a narrower cone is the same pattern, smaller)
	FOV = Clamp(Cone, 60, 100);
	Dress();
	// (a projector finds the players and models in its cone only if it is one that things can touch)
	SetCollision(true, false, false);
	// (the cone's point is behind the projector by half its picture's width over the tangent of half its angle)
	Wide = ProjTexture.MaterialUSize();
	if (Wide < 1)
		Wide = 256;
	SetDrawScale(Reach * 2.0 * Tan(float(FOV) * Pi / 360.0) / float(Wide));
	Hud = class'KFTHud'.static.Of(PC, true);
	if (Hud != None)
		Hud.Add(self);
}

simulated function Dress()
{
	local int S, D;
	local float Wide;

	// (how far the light sees needs no more than 1024: a shadow's edge is stepped by that picture's pixels, and they
	// are small. What it throws is as sharp as its picture of what it falls on.)
	S = Clamp(PictureSize, 256, 2048);
	D = Clamp(DepthSize, 256, S);
	SoftSize = Min(D, 1024);
	EyeW = Spawn(class'KFTEye');
	EyeB = Spawn(class'KFTEye');
	EyeA = Spawn(class'KFTEye');
	if (EyeW == None || EyeB == None || EyeA == None)
	{
		// (no pictures to be had: no light)
		if (EyeW != None)
			EyeW.Destroy();
		if (EyeB != None)
			EyeB.Destroy();
		if (EyeA != None)
			EyeA.Destroy();
		EyeW = None;
		EyeB = None;
		EyeA = None;
		return;
	}
	EyeW.Init(self, D);
	EyeW.bWhite = true;
	EyeB.Init(self, D);
	EyeA.Init(self, S);
	EyeA.bPlain = true;
	Range = MaxRange;
	MaxTraceDistance = int(Throw);
	// (A cone's far end is a flat face square to its middle, set where its corner edges are as long as asked: nearer
	// than its length by the cosine of the corner's angle over the cosine of half the cone's.)
	Wide = Tan(float(FOV) * Pi / 360.0);
	ConeShare = Sqrt((1.0 + Wide * Wide) / (1.0 + 2.0 * Wide * Wide));
	// (the pool's edge and the spill's, for the chance lines: shares of the cone's half width)
	PoolWide = Wide * 0.436;
	SpillWide = Wide * 0.92;
	// (So a cone as long as the light's reach ends four fifths of the way there, and that is as far as the light
	// has ever gone on the level's own surfaces. It is as far as it goes now on everything; over the last part of
	// the way it falls to nothing, where it used to stop short with a fifth of its strength.)
	FarMost = Reach + ConeShare * Throw;
	FallEnd = int(0.969 + 62.0 * ConeShare);
	FallBend = int(float(FallEnd) * 0.82);
	FarLit = FarMost;

	// how far the light sees, in a picture of its own (a Combiner taking away gives its second less its first)
	Diff = class'KFTMat'.static.Mix(Made, Level, EyeB.View, EyeW.View, 1);
	Depth = class'KFTMat'.static.Sheet(Made, Level, self, D);
	DepthOver = class'KFTMat'.static.Paint(Made, Level, Diff, 0);
	DepthSeen = class'KFTMat'.static.Paint(Made, Level, Depth, 2);
	// (What is nearer than where the fog begins would read as no distance at all, the same as the ramp's own
	// nothing, and be taken for shadowed. So every reading is raised a few steps: added, never past white.)
	FloorK = class'KFTMat'.static.Grey(Made, Level, 0);
	FloorOver = class'KFTMat'.static.Paint(Made, Level, class'KFTMat'.static.Mix(Made, Level, FloorK, Texture'Engine.WhiteTexture', 0), 5);

	// what the light throws each way it looks: what it falls on, in plain textures, times the bulb's colour, times
	// its pattern, doubled (as the renderer doubles a projector laid on a surface's own texture); and the same not
	// doubled, which is half
	Tint = class'KFTMat'.static.Hue(Made, Level, 255, 255, 255);
	FluxFull = class'KFTMat'.static.Sheet(Made, Level, self, S);
	FullOver = class'KFTMat'.static.Paint(Made, Level, class'KFTMat'.static.Mix(Made, Level,
		class'KFTMat'.static.Mix(Made, Level, Tint, EyeA.View, 0), Cookie, 0, 2), 0);
	FullSeen = class'KFTMat'.static.Paint(Made, Level, FluxFull, 2);
	FluxHalf = class'KFTMat'.static.Sheet(Made, Level, self, S);
	HalfOver = class'KFTMat'.static.Paint(Made, Level, class'KFTMat'.static.Mix(Made, Level,
		class'KFTMat'.static.Mix(Made, Level, Tint, EyeA.View, 0), Cookie, 0), 0);
	HalfSeen = class'KFTMat'.static.Paint(Made, Level, FluxHalf, 2);

	// How far along the beam a point is: a ramp laid by what the projector hands every texture in its material, not
	// by a point's place in the world (on a model the renderer puts the projector's own matrix in front of this
	// one, and a place in the world would be turned by it into nonsense).
	RampLay = TexMatrix(Level.ObjectPool.AllocateObject(class'TexMatrix'));
	RampLay.Material = Texture'KFTorchTex.KFTRamp';
	RampLay.TexCoordSource = TCS_NoChange;
	RampLay.TexCoordCount = TCN_2DCoords;
	RampLay.TexCoordProjected = false;

	// how far the light sees less how far the point is, times sixty-four: lit or not. The last of the three
	// times-fours is by a white picture with a black edge that does not repeat: the pictures made here do repeat,
	// and a model is not cut to the cone as a wall is, so without it a big model had a pool of light for every
	// time the picture came round.
	Gate = class'KFTMat'.static.Gained(Made, Level, class'KFTMat'.static.Mix(Made, Level, RampLay, Depth, 1), 2);
	Gate = class'KFTMat'.static.Mix(Made, Level, Gate, Texture'KFTorchTex.KFTWindow', 0, 4);
	LitFull = class'KFTMat'.static.Mix(Made, Level, Gate, FluxFull, 0);
	LitHalf = class'KFTMat'.static.Mix(Made, Level, Gate, FluxHalf, 0);
	// How the light falls away with distance, for the two cones the renderer looks up for itself. The renderer can
	// lay that on, but only from one end of a cone to the other: a cone cut short would have the light gone at its
	// end, and a cone at full length has every model within the light's whole reach drawn again, however near the
	// beam lands. (And its far end is nearer than its length, see ConeShare: on the level's own surfaces the light
	// stopped a fifth short of its reach, with a fifth of its strength left.) So the fall is a picture of the
	// light's own (KFTFall's alpha, in colour), laid along the beam as the ramp is, over the light's whole reach
	// whatever the cone's length. (In that picture the last of the fall is squeezed into the rows before the cones'
	// end: see RenderTexture.)
	FallPic = class'KFTMat'.static.Sheet(Made, Level, self, 64);
	FallPic.UClampMode = TC_Clamp;
	FallPic.VClampMode = TC_Clamp;
	FallClear = class'KFTMat'.static.Paint(Made, Level, Texture'Engine.BlackTexture', 0);
	FallOver = class'KFTMat'.static.Paint(Made, Level, Texture'KFTorchTex.KFTFall', 0);
	FinalBlend(FallOver).FrameBufferBlending = FB_AlphaBlend;
	FallSeen = class'KFTMat'.static.Paint(Made, Level, FallPic, 2);
	FallLay = TexMatrix(Level.ObjectPool.AllocateObject(class'TexMatrix'));
	FallLay.Material = FallPic;
	FallLay.TexCoordSource = TCS_NoChange;
	FallLay.TexCoordCount = TCN_2DCoords;
	FallLay.TexCoordProjected = false;
	class'KFTMat'.static.Fall(FallLay, Throw, Reach);
	LitFullFall = class'KFTMat'.static.Mix(Made, Level, LitFull, FallLay, 0);
	LitHalfFall = class'KFTMat'.static.Mix(Made, Level, LitHalf, FallLay, 0);
	bGradient = false;
	// the pattern in the bulb's colour, in a picture of its own (a plain colour has to be the first thing in a
	// material, and the light's material begins with the ramp)
	Pattern = class'KFTMat'.static.Sheet(Made, Level, self, 512);
	Pattern.UClampMode = TC_Clamp;
	Pattern.VClampMode = TC_Clamp;
	PatternOver = class'KFTMat'.static.Paint(Made, Level, class'KFTMat'.static.Mix(Made, Level, Tint, Cookie, 0), 0);
	PatternSeen = class'KFTMat'.static.Paint(Made, Level, Pattern, 2);
	LitBody = class'KFTMat'.static.Mix(Made, Level, Gate, Pattern, 0);
	// (and the pattern again, fainter, for what is lit in the light's own colour: that much is taken from it after
	// it is drawn)
	Faint = class'KFTMat'.static.Sheet(Made, Level, self, 512);
	Faint.UClampMode = TC_Clamp;
	Faint.VClampMode = TC_Clamp;
	FaintK = class'KFTMat'.static.Grey(Made, Level, 100);
	FaintOver = class'KFTMat'.static.Paint(Made, Level, class'KFTMat'.static.Mix(Made, Level, FaintK, Texture'Engine.WhiteTexture', 0), 4);
	FaintSeen = class'KFTMat'.static.Paint(Made, Level, Faint, 2);
	LitFaint = class'KFTMat'.static.Mix(Made, Level, Gate, Faint, 0);
	LitFullX = class'KFTMat'.static.Mix(Made, Level, Gate, FluxFull, 0);
	// (the gain goes on last, after the fall, so that nothing is cut at white before it is dimmed)
	Gained.Length = 0;
	Gained[0] = Combiner(LitFullFall);
	Gained[1] = Combiner(LitHalfFall);
	Gained[2] = Combiner(LitBody);
	Gained[3] = Combiner(LitFaint);
	Gained[4] = LitFullX;
	Vanish = class'KFTMat'.static.Paint(Made, Level, Texture'Engine.WhiteTexture', 2);
	Soften(SoftSize);
	ProjTexture = LitFullFall;
	bDressed = true;

	Shade = Spawn(class'KFTBody');
	if (Shade != None)
	{
		// (laid on each body's own skin, and doubled as the renderer doubles that; every texture unit is spoken
		// for, so it is not weighed by how the skin faces the light: whoever holds the light sees no skin that
		// is turned from it)
		Shade.MaterialBlendingOp = PB_Modulate;
		Shade.bProjectOnBackfaces = true;
		Shade.Fit(LitBody, Reach, FOV, int(Throw));
	}
	ShadeX = Spawn(class'KFTBody');
	if (ShadeX != None)
		ShadeX.Fit(LitFullX, Reach, FOV, int(Throw));
	Ground = Spawn(class'KFTBody');
	if (Ground != None)
	{
		// (terrain is drawn lit in the light's plain picture, so what the light takes from that is dark at night: it is
		// lit as a body is, on its own colours. It is fixed to the terrain, not looked up by the renderer: that kind
		// is put on the level's own surfaces too, whatever it is told. Slopes turned from the light are left to the
		// shadow test; skipped, they cut the pool along the terrain's triangles.)
		Ground.MaterialBlendingOp = PB_Modulate;
		Ground.bProjectTerrain = true;
		Ground.bProjectOnBackfaces = true;
		Ground.Fit(LitBody, Reach, FOV, int(Throw));
	}
	Sheen = Spawn(class'KFTBody');
	if (Sheen != None)
	{
		// (as on a body: laid on the thing's own texture, and by how solid that is. That takes one texture unit
		// more, so this one does not fall away with distance.)
		Sheen.MaterialBlendingOp = PB_Modulate;
		Sheen.bProjectOnBackfaces = true;
		Sheen.bGradient = false;
		Sheen.Fit(LitBody, Reach, FOV, int(Throw));
	}
	SheenX = Spawn(class'KFTBody');
	if (SheenX != None)
	{
		// (laid on nothing of the thing's own but how solid it is)
		SheenX.bProjectOnBackfaces = true;
		SheenX.Fit(LitFaint, Reach, FOV, int(Throw));
	}
	Fill = Spawn(class'KFTBody');
	if (Fill != None)
	{
		// (this one the renderer looks up for itself, as it does the light: the level's surfaces and its models)
		Fill.bDynamicAttach = true;
		Fill.bProjectStaticMesh = true;
		Fill.bProjectOnBackfaces = true;
		Fill.bGradient = false;
		Fill.Fit(LitHalfFall, Reach, FOV, int(Throw));
	}
	Bounce = Spawn(class'KFTBounce');
	if (Bounce != None)
	{
		Bounce.Init(self);
		Bounce.Gain = BounceGain;
	}
	Lean(Soft);
	Glowing(1.0, 0.0);
}

// The soft edge of a shadow: its pictures, D across, and what they are drawn with.
simulated function Soften(int D)
{
	local TexMatrix T;
	local Material M;
	local float A, Far;
	local int i, j, n;

	// How much nearer a thing has to be, ring by ring: how far the light sees, times a number for the ring (set each
	// frame); and three steps of distance more, which is as much as the pictures are out by (added, as near as
	// makes no difference).
	BiasK = class'KFTMat'.static.Grey(Made, Level, 3);
	BiasOver = class'KFTMat'.static.Paint(Made, Level, class'KFTMat'.static.Mix(Made, Level, BiasK, Texture'Engine.WhiteTexture', 0), 5);
	for (j = 0; j < 4; j++)
	{
		NeedK[j] = class'KFTMat'.static.Grey(Made, Level, 255);
		Need[j] = class'KFTMat'.static.Sheet(Made, Level, self, D);
		NeedMix[j] = class'KFTMat'.static.Mix(Made, Level, NeedK[j], Depth, 0);
		NeedOver[j] = class'KFTMat'.static.Paint(Made, Level, NeedMix[j], 0);
		NeedSeen[j] = class'KFTMat'.static.Paint(Made, Level, Need[j], 2);
		StartK[j] = class'KFTMat'.static.Grey(Made, Level, 0);
		StartOver[j] = class'KFTMat'.static.Paint(Made, Level, class'KFTMat'.static.Mix(Made, Level, StartK[j], Texture'Engine.WhiteTexture', 0), 5);
	}

	// the share of the light each takes: a number, less as much of it as the distance says
	DeepK = class'KFTMat'.static.Grey(Made, Level, 64);
	FadeK = class'KFTMat'.static.Grey(Made, Level, 0);
	Deep = class'KFTMat'.static.Sheet(Made, Level, self, D);
	DeepOver = class'KFTMat'.static.Paint(Made, Level, class'KFTMat'.static.Mix(Made, Level, DeepK, Texture'Engine.WhiteTexture', 0), 0);
	FadeOver = class'KFTMat'.static.Paint(Made, Level, class'KFTMat'.static.Mix(Made, Level, FadeK, Depth, 0), 4);
	DeepSeen = class'KFTMat'.static.Paint(Made, Level, Deep, 2);

	// How much of the light gets past: white, and then for each place looked at, what is there loses the share,
	// where: how far the light sees here, less how far it sees there, less what is needed, is more than nothing
	// (times sixty-four: it is, or it is not).
	Pen = class'KFTMat'.static.Sheet(Made, Level, self, D);
	PenClear = class'KFTMat'.static.Paint(Made, Level, Texture'Engine.WhiteTexture', 0);
	PenSeen = class'KFTMat'.static.Paint(Made, Level, Pen, 2);
	TapOver.Length = 0;
	Far = 1.0;
	for (j = 0; j < 4; j++)
	{
		n = RingTaps[j];
		for (i = 0; i < n; i++)
		{
			A = (float(i) + RingTurn[j]) * 2.0 * Pi / float(n);
			T = class'KFTMat'.static.Shift(Made, Level, Depth);
			class'KFTMat'.static.Moved(T, Cos(A) * Far / 1024.0, Sin(A) * Far / 1024.0);
			M = class'KFTMat'.static.Mix(Made, Level, T, Need[j], 2);
			M = class'KFTMat'.static.Mix(Made, Level, M, Depth, 1);
			M = class'KFTMat'.static.Gained(Made, Level, M, 3);
			M = class'KFTMat'.static.Mix(Made, Level, M, Deep, 0);
			TapOver[TapOver.Length] = class'KFTMat'.static.Paint(Made, Level, M, 4);
		}
		Far *= 2.0;
	}
	// (none of these comes round again at its edge)
	Depth.UClampMode = TC_Clamp;
	Depth.VClampMode = TC_Clamp;
	Deep.UClampMode = TC_Clamp;
	Deep.VClampMode = TC_Clamp;
	Pen.UClampMode = TC_Clamp;
	Pen.VClampMode = TC_Clamp;
	for (j = 0; j < 4; j++)
	{
		Need[j].UClampMode = TC_Clamp;
		Need[j].VClampMode = TC_Clamp;
	}

	// what the light throws, times it
	FullOverSoft = class'KFTMat'.static.Paint(Made, Level, class'KFTMat'.static.Mix(Made, Level, class'KFTMat'.static.Mix(Made, Level,
		class'KFTMat'.static.Mix(Made, Level, Tint, EyeA.View, 0), Cookie, 0, 2), Pen, 0), 0);
	HalfOverSoft = class'KFTMat'.static.Paint(Made, Level, class'KFTMat'.static.Mix(Made, Level, class'KFTMat'.static.Mix(Made, Level,
		class'KFTMat'.static.Mix(Made, Level, Tint, EyeA.View, 0), Cookie, 0), Pen, 0), 0);
	PatternOverSoft = class'KFTMat'.static.Paint(Made, Level, class'KFTMat'.static.Mix(Made, Level,
		class'KFTMat'.static.Mix(Made, Level, Tint, Cookie, 0), Pen, 0), 0);
}

// The numbers the soft edge goes by this frame. A place looked at is so far to one side, as the light sees (Ring, an
// angle). A light that fills the angle Wide, seen from a point, is partly hidden from it by a thing so far to one
// side if that thing is nearer than the point by more than the share Ring / Wide of the point's distance. So the
// edge is as wide as the gap between a shadow and what throws it, times Wide: next to nothing where the two all but
// touch. And whoever holds the light sees a shadow only by as much as the light is to one side of the eye, which is
// less the further off the thing that throws it; the edge does not shrink so, and takes up more and more of the
// shadow with distance.
simulated function SoftNumbers()
{
	local float Wide, Ring, S, Span, Fl, More;
	local int j, V;

	Wide = FMax(0.05, Spread * Edge * (1.0 + DimSoft * (1.0 - Bright))) * Pi / 180.0;
	// (a 1024th of the picture's width, as an angle, in the middle of the picture)
	Ring = 2.0 * Tan(float(FOV) * Pi / 360.0) / 1024.0;
	// (A reading is no longer the distance over the fog's end: it is the distance past where the fog begins, over
	// what is between there and the end, on top of the few steps that stand for "nearer". What is asked of a gap
	// goes by the whole distance, so the part the reading leaves out is put back, ring by ring.)
	Span = FMax(Range - FogStart, 1.0);
	Fl = NearFloor();
	for (j = 0; j < 4; j++)
	{
		S = Ring / Wide;
		More = S * ((1.0 - Fl) * FogStart / Span - Fl);
		V = Clamp(int(255.0 * More + 0.5), 0, 255);
		StartK[j].Color.R = V;
		StartK[j].Color.G = V;
		StartK[j].Color.B = V;
		// (the number is no more than one: over that, it is a quarter as much, times four)
		NeedMix[j].Modulate4X = (S > 1.0);
		if (S > 1.0)
			S *= 0.25;
		V = Clamp(int(255.0 * S + 0.5), 1, 255);
		NeedK[j].Color.R = V;
		NeedK[j].Color.G = V;
		NeedK[j].Color.B = V;
		Ring *= 2.0;
	}
	V = Clamp(int(255.0 * EdgeDark * FClamp(1.0 - FogStart / FMax(FadeBy, 100.0), 0.0, 1.0)), 0, 255);
	DeepK.Color.R = V;
	DeepK.Color.G = V;
	DeepK.Color.B = V;
	V = Clamp(int(255.0 * Span / FMax(FadeBy - FogStart, 100.0)), 0, 255);
	FadeK.Color.R = V;
	FadeK.Color.G = V;
	FadeK.Color.B = V;
}

// How the light is weighed by the way a surface faces it.
//   0  as the renderer weighs it, all of it: by how squarely a surface faces the middle of the beam. A floor the
//      beam runs along gets next to nothing.
//   1  half weighed so, half on whatever the beam reaches. A floor along the beam gets half the light, a wall
//      square to the beam all of it. (The far side of a wall thinner than the shadows' start gets that half too.)
//   2  not weighed at all: everything the beam reaches is lit alike.
simulated function Lean(int How)
{
	Soft = Clamp(How, 0, 2);
	if (!bDressed)
		return;
	if (Soft == 1)
		ProjTexture = LitHalfFall;
	else
		ProjTexture = LitFullFall;
	bProjectOnBackfaces = (Soft == 2);
}

// The bulb: how bright (the battery), and how far toward amber (a filament going cold). Gain over one is put on as
// two or four times over at the end of the light's materials, and the bulb dimmed by what that overshoots.
simulated function Glowing(float HowBright, float HowWarm)
{
	local float G, K;
	local int Times, i;

	Bright = FClamp(HowBright, 0.0, 1.0);
	Warm = FClamp(HowWarm, 0.0, 1.0);
	if (Tint == None)
		return;
	G = FClamp(Gain, 1.0, 4.0);
	if (G > 2.0)
		Times = 4;
	else if (G > 1.0)
		Times = 2;
	else
		Times = 1;
	for (i = 0; i < Gained.Length; i++)
	{
		if (Gained[i] == None)
			continue;
		Gained[i].Modulate2X = (Times == 2);
		Gained[i].Modulate4X = (Times == 4);
	}
	K = Bright * G / float(Times);
	Tint.Color.R = Clamp(int(255.0 * K), 0, 255);
	Tint.Color.G = Clamp(int(255.0 * K * (1.0 - 0.28 * Warm)), 0, 255);
	Tint.Color.B = Clamp(int(255.0 * K * (1.0 - 0.62 * Warm)), 0, 255);
	Tint.Color.A = 255;
}

// Whether a body can be lit in its own colours: each part of its skin, as far as it can be read, comes down to one
// plain texture. (A projector whose own material is several textures can be laid on a plain texture, on a Shader
// whose colour is one, the renderer takes that colour and leaves the rest, and on such a thing moved, turned or
// blended. On a skin that is itself several textures put together the renderer gives up and draws the skin again
// by itself, bright all over.)
simulated function bool OwnColours(Actor A)
{
	local int i, n;
	local Material M;

	for (i = 0; i < A.Skins.Length; i++)
	{
		M = A.Skins[i];
		for (n = 0; n < 6 && M != None && BitmapMaterial(M) == None; n++)
		{
			if (Shader(M) != None)
				M = Shader(M).Diffuse;
			else if (Modifier(M) != None)
				M = Modifier(M).Material;
			else
				return false;
		}
		if (M != None && BitmapMaterial(M) == None)
			return false;
	}
	return true;
}

// What can be seen through: plastic sheeting, glass, writing and stains laid over a wall. In a picture taken from the
// light such a thing is neither here nor there: the picture has it and what is behind it run together, in colour and
// in distance both. Lit from that picture it had a second picture of whatever was behind it laid on it, out of
// place, and what was behind it stood in its shadow or not by how solid it happened to be. So these are left out of
// the light's pictures altogether (the light goes through them), the light's own cones are kept off them, and they
// are lit as a body is, by how solid they are: in their own colours where that can be done (Sheen), in the light's
// own colour where it cannot (SheenX), and not at all where the thing is not solid in any measure.
//
// What a material is:
//   0  solid; or cut out, which a picture shows rightly (a wire fence throws the shadow of its wires)
//   1  seen through, and lit in its own colours: one texture that says how solid it is too
//   2  seen through, and lit in the light's colour: its colours are several textures, how solid it is is one
//   3  seen through and not lit: what darkens, brightens or glows over what is behind it
//   5  cut out where the light's cones cannot follow the cut: by a FinalBlend's alpha test, or a cut-out texture under
//      a modifier. (A projector finds how solid a surface is only in its own texture or Shader; on anything else it lays
//      itself whole. On KF-WickedCity's bushes the light lay on the whole of each card, a sheet of the street behind.)
//      In the pictures as cut out, so it throws its shadow, and kept clear of the cones: not lit.
simulated function int MatKind(Material M)
{
	local Shader Sh;
	local int n;
	local bool bMoving, bUnder;

	for (n = 0; n < 6 && M != None; n++)
	{
		Sh = Shader(M);
		if (Sh != None)
		{
			if (Sh.OutputBlending == OB_Masked || Sh.OutputBlending == OB_Invisible)
				return 0;
			if (Sh.OutputBlending != OB_Normal)
				return 3;
			if (Sh.Opacity == None)
				return 0;
			if (!OneTexture(Sh.Opacity))
				return 3;
			// (mist, a stream of light under a lamp: lit, it stood in the beam as a bright sheet)
			if (bMoving || Moves(Sh.Diffuse))
				return 3;
			if (OneTexture(Sh.Diffuse))
				return 1;
			return 2;
		}
		if (FinalBlend(M) != None)
		{
			if (FinalBlend(M).AlphaTest)
				return 5;
			if (FinalBlend(M).FrameBufferBlending != FB_Overwrite && FinalBlend(M).FrameBufferBlending != FB_Invisible)
				return 3;
			// (drawn solid whatever is under it)
			bUnder = false;
			M = FinalBlend(M).Material;
		}
		else if (Texture(M) != None)
		{
			if (Texture(M).bMasked && bUnder)
				return 5;
			if (Texture(M).bMasked || !Texture(M).bAlphaTexture)
				return 0;
			if (bMoving)
				return 3;
			return 1;
		}
		else if (Modifier(M) != None)
		{
			if (Moves(M))
				bMoving = true;
			bUnder = true;
			M = Modifier(M).Material;
		}
		else
			return 0;
	}
	return 0;
}

// Whether a material's picture moves: slides, turns or sways. What can be seen through and moves is mist, smoke, a
// stream of light: not a thing a light lands on. It is left unlit and the light goes through it.
simulated function bool Moves(Material M)
{
	local int n;

	for (n = 0; n < 6 && M != None; n++)
	{
		if (TexPanner(M) != None || TexRotator(M) != None || TexOscillator(M) != None || VariableTexPanner(M) != None)
			return true;
		if (Modifier(M) == None)
			break;
		M = Modifier(M).Material;
	}
	return false;
}

// Whether a see-through model is one the player has said the light is to leave alone
simulated function bool Omitted(Actor A)
{
	local string S;
	local int i;

	if (Omit.Length == 0 || A.StaticMesh == None)
		return false;
	S = Caps(string(A.StaticMesh));
	for (i = 0; i < Omit.Length; i++)
		if (Omit[i] != "" && InStr(S, Caps(Omit[i])) >= 0)
			return true;
	return false;
}

// The see-through model nearest the middle of the beam that is lit now, by name; nothing if there is none within a
// fifth of the way round. (For "mutate torch omit": point the lit torch at the thing.)
simulated function string OmitAhead()
{
	local vector To;
	local float Near, Best;
	local int i, Pick;

	Pick = -1;
	Best = 0.94;
	for (i = 0; i < Sheer.Length; i++)
	{
		if (Sheer[i] == None || Sheer[i].StaticMesh == None || SheerKind[i] == 3 || SheerKind[i] == 5)
			continue;
		To = Sheer[i].Location - Apex;
		Near = Normal(To) dot Aim;
		if (Near > Best)
		{
			Best = Near;
			Pick = i;
		}
	}
	if (Pick < 0)
		return "";
	return string(Sheer[Pick].StaticMesh);
}

// What can be seen through is looked for again (the list of what to leave alone has changed)
simulated function Relook()
{
	Shun(false);
	SheerMats(false);
	SheerShaders.Length = 0;
	SheerShaderWas.Length = 0;
	SheerBlends.Length = 0;
	SheerBlendWas.Length = 0;
	bSheerFound = false;
	AllSheer.Length = 0;
	AllSheerKind.Length = 0;
	Sheer.Length = 0;
	SheerKind.Length = 0;
	KnownMesh.Length = 0;
	KnownKinds.Length = 0;
	NextSheer = 0.0;
}

// What a see-through model is made of, noted to be made invisible for the length of the light's pictures. (Hiding the
// model is not enough: the level keeps its fixed models in batches that take no notice of a model being hidden. A
// plain texture cannot be made invisible so, and is left: those are stains and writing laid flat on a wall, where
// it makes no difference.)
simulated function KeepSheerMats(Actor A)
{
	local string S, Ref;
	local int i, j;

	for (i = 0; i < A.Skins.Length; i++)
		KeepSheerMat(A.Skins[i]);
	if (A.StaticMesh == None)
		return;
	S = A.StaticMesh.GetPropertyText("Materials");
	for (j = 0; j < 64; j++)
	{
		i = InStr(S, "Material=");
		if (i < 0)
			break;
		S = Mid(S, i + 9);
		i = InStr(S, "'");
		if (Left(S, 4) ~= "None" || i < 0)
			continue;
		Ref = Mid(S, i + 1);
		i = InStr(Ref, "'");
		if (i <= 0)
			continue;
		KeepSheerMat(Material(DynamicLoadObject(Left(Ref, i), class'Material', true)));
	}
}

simulated function KeepSheerMat(Material M)
{
	local int i, n;

	if (M == None || MatKind(M) == 0 || MatKind(M) == 5)
		return;
	for (n = 0; n < 6 && M != None; n++)
	{
		if (FinalBlend(M) != None)
		{
			for (i = 0; i < SheerBlends.Length; i++)
				if (SheerBlends[i] == M)
					return;
			SheerBlends[SheerBlends.Length] = FinalBlend(M);
			return;
		}
		if (Shader(M) != None)
		{
			for (i = 0; i < SheerShaders.Length; i++)
				if (SheerShaders[i] == M)
					return;
			SheerShaders[SheerShaders.Length] = Shader(M);
			return;
		}
		if (Modifier(M) == None)
			return;
		M = Modifier(M).Material;
	}
}

// Those materials made invisible, or put back as they were
simulated function SheerMats(bool bOff)
{
	local int i;

	if (bOff == bSheerMatsOff)
		return;
	bSheerMatsOff = bOff;
	for (i = 0; i < SheerShaders.Length; i++)
	{
		if (SheerShaders[i] == None)
			continue;
		if (bOff)
		{
			SheerShaderWas[i] = SheerShaders[i].OutputBlending;
			SheerShaders[i].OutputBlending = OB_Invisible;
		}
		else
			SheerShaders[i].OutputBlending = EOutputBlending(SheerShaderWas[i]);
	}
	for (i = 0; i < SheerBlends.Length; i++)
	{
		if (SheerBlends[i] == None)
			continue;
		if (bOff)
		{
			SheerBlendWas[i] = SheerBlends[i].FrameBufferBlending;
			SheerBlends[i].FrameBufferBlending = FB_Invisible;
		}
		else
			SheerBlends[i].FrameBufferBlending = EFrameBufferBlending(SheerBlendWas[i]);
	}
}

// The fog of the level's volumes, put aside for the length of one of the light's pictures and put back after it. A
// volume with fog of its own (the mist in a tunnel) gives its fog to everything drawn while the player's eye is in
// it, the light's pictures too, in place of the zone's fog the light sets: the white picture and the black came out
// alike, read as no distance anywhere, and the light lit nothing while the player stood in the mist.
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

// Whether a body is to be seen through: a stalker while cloaked, or anything whose every skin is see-through
simulated function bool SeeThroughBody(Actor A)
{
	local int i;

	if (A.GetPropertyText("bCloaked") ~= "True")
		return true;
	if (A.Skins.Length == 0)
		return false;
	for (i = 0; i < A.Skins.Length; i++)
		if (A.Skins[i] == None || MatKind(A.Skins[i]) == 0 || MatKind(A.Skins[i]) == 5)
			return false;
	return true;
}

// Whether a material comes down to one plain texture, moved or turned as it may be
simulated function bool OneTexture(Material M)
{
	local int n;

	for (n = 0; n < 6 && M != None && BitmapMaterial(M) == None; n++)
	{
		if (Modifier(M) != None && FinalBlend(M) == None)
			M = Modifier(M).Material;
		else
			return false;
	}
	return BitmapMaterial(M) != None;
}

// What a model's materials are, one figure for each in their order. (A script cannot ask a model for them, but can
// ask for them written out, as the editor shows them.) Each model is looked at once.
simulated function string MeshKinds(StaticMesh M)
{
	local string S, Ref, Kinds;
	local int i, j;

	for (i = 0; i < KnownMesh.Length; i++)
		if (KnownMesh[i] == M)
			return KnownKinds[i];
	S = M.GetPropertyText("Materials");
	for (j = 0; j < 64; j++)
	{
		i = InStr(S, "Material=");
		if (i < 0)
			break;
		S = Mid(S, i + 9);
		// (written as Class'Package.Group.Name'; one that has none is written None, and is drawn solid)
		i = InStr(S, "'");
		if (Left(S, 4) ~= "None" || i < 0)
		{
			Kinds = Kinds $ "0";
			continue;
		}
		Ref = Mid(S, i + 1);
		i = InStr(Ref, "'");
		if (i <= 0)
		{
			Kinds = Kinds $ "0";
			continue;
		}
		Kinds = Kinds $ string(MatKind(Material(DynamicLoadObject(Left(Ref, i), class'Material', true))));
	}
	// (a tool: what each such model is made of, to the log)
	if ((Skip & 32) != 0 && Kinds != "" && InStr(Kinds, "0") < 0)
		Log("KFTorch: model" @ M @ "kinds" @ Kinds @ Tells(M));
	i = KnownMesh.Length;
	KnownMesh[i] = M;
	KnownKinds[i] = Kinds;
	return Kinds;
}

// (a tool: the materials of a model, each with what decides its kind)
simulated function string Tells(StaticMesh M)
{
	local string S, Ref, Said;
	local Material Mat;
	local int i, j;

	S = M.GetPropertyText("Materials");
	for (j = 0; j < 64; j++)
	{
		i = InStr(S, "Material=");
		if (i < 0)
			break;
		S = Mid(S, i + 9);
		i = InStr(S, "'");
		if (Left(S, 4) ~= "None" || i < 0)
			continue;
		Ref = Mid(S, i + 1);
		i = InStr(Ref, "'");
		if (i <= 0)
			continue;
		Mat = Material(DynamicLoadObject(Left(Ref, i), class'Material', true));
		if (Shader(Mat) != None)
			Said = Said @ "[" $ Mat.Name @ "kind" @ MatKind(Mat) @ "blending" @ Shader(Mat).OutputBlending @ "colour" @ Shader(Mat).Diffuse @ "solid by" @ Shader(Mat).Opacity $ "]";
		else if (Texture(Mat) != None)
			Said = Said @ "[" $ Mat.Name @ "kind" @ MatKind(Mat) @ "alpha" @ Texture(Mat).bAlphaTexture @ "cut out" @ Texture(Mat).bMasked $ "]";
		else if (FinalBlend(Mat) != None)
			Said = Said @ "[" $ Mat.Name @ "kind" @ MatKind(Mat) @ "blend" @ FinalBlend(Mat).FrameBufferBlending @ "cut out" @ FinalBlend(Mat).AlphaTest @ "of" @ FinalBlend(Mat).Material $ "]";
		else if (Mat != None)
			Said = Said @ "[" $ Mat.Name @ Mat.Class @ "kind" @ MatKind(Mat) $ "]";
	}
	return Said;
}

// What a thing in the level is: by each part of its model, or by what it wears over that part. One solid part makes
// the whole of it solid: it cannot be left out of the light's pictures in part, and a van is not to be seen through
// for its windows. Of the ways it can be lit, the least that any part allows.
simulated function int SheerKindOf(Actor A)
{
	local string Kinds;
	local int i, n, K, Most;
	local bool bSolid, bCut;

	if (A.StaticMesh == None)
		return 0;
	Kinds = MeshKinds(A.StaticMesh);
	n = Max(Len(Kinds), A.Skins.Length);
	if (n == 0)
		return 0;
	for (i = 0; i < n; i++)
	{
		if (i < A.Skins.Length && A.Skins[i] != None)
			K = MatKind(A.Skins[i]);
		else if (i < Len(Kinds))
			K = int(Mid(Kinds, i, 1));
		else
			continue;
		if (K == 5)
		{
			bCut = true;
			continue;
		}
		if (K == 0)
			bSolid = true;
		Most = Max(Most, K);
	}
	// (A part cut out where the cones cannot follow the cut keeps them off the whole of it, solid parts too; with no
	// solid part and see-through ones, it is left out of the pictures and unlit as well.)
	if (bCut)
	{
		if (!bSolid && Most != 0)
			return 3;
		return 5;
	}
	// (A solid model with parts seen through and lit in their own colours, a door with a pane of glass, is kind 4
	// if all of it can be lit so. Lit from the light's pictures, the pane had the room behind it laid on it a second
	// time, out of place: what was behind the pane was in the picture through it. Anything else with a solid part is
	// lit as the level is.)
	if (bSolid)
	{
		if (Most == 1 && !Omitted(A) && PlainParts(A))
			return 4;
		return 0;
	}
	if (Most != 0 && Omitted(A))
		return 3;
	return Most;
}

// Whether each part of a model, as far as it can be read, comes down to one plain texture (as OwnColours asks of a
// body): the light's material for what is lit in its own colours can be laid on it
simulated function bool PlainParts(Actor A)
{
	local string S, Ref;
	local Material M;
	local int i, j;

	S = A.StaticMesh.GetPropertyText("Materials");
	for (j = 0; j < 64; j++)
	{
		i = InStr(S, "Material=");
		if (i < 0)
			break;
		S = Mid(S, i + 9);
		M = None;
		if (j < A.Skins.Length && A.Skins[j] != None)
			M = A.Skins[j];
		else
		{
			i = InStr(S, "'");
			if (Left(S, 4) ~= "None" || i < 0)
				continue;
			Ref = Mid(S, i + 1);
			i = InStr(Ref, "'");
			if (i <= 0)
				continue;
			M = Material(DynamicLoadObject(Left(Ref, i), class'Material', true));
		}
		for (i = 0; i < 6 && M != None && BitmapMaterial(M) == None; i++)
		{
			if (Shader(M) != None)
				M = Shader(M).Diffuse;
			else if (Modifier(M) != None)
				M = Modifier(M).Material;
			else
				return false;
		}
		if (M != None && BitmapMaterial(M) == None)
			return false;
	}
	return true;
}

// A moving model's see-through parts, left out of the light's pictures by wearing nothing there until UnclearParts.
// (The level's fixed models are drawn in batches that take no notice of what they wear; on those the pane stays in
// the pictures, and what is behind it is lit as seen through it.)
simulated function ClearParts(Actor A)
{
	local string Kinds;
	local int i, n, Was;

	if (Vanish == None || A.StaticMesh == None)
		return;
	Kinds = MeshKinds(A.StaticMesh);
	Was = A.Skins.Length;
	n = Max(Len(Kinds), Was);
	for (i = 0; i < n; i++)
	{
		if (i < Was && A.Skins[i] != None)
		{
			if (MatKind(A.Skins[i]) == 0)
				continue;
		}
		else if (i >= Len(Kinds) || Mid(Kinds, i, 1) == "0")
			continue;
		SkinOn[SkinOn.Length] = A;
		SkinAt[SkinAt.Length] = i;
		SkinLen[SkinLen.Length] = Was;
		if (i < Was)
			SkinWas[SkinWas.Length] = A.Skins[i];
		else
			SkinWas[SkinWas.Length] = None;
		A.Skins[i] = Vanish;
	}
}

// What ClearParts took off, put back (last first, so that each model ends with as many skins as it had)
simulated function UnclearParts()
{
	local int i;

	for (i = SkinOn.Length - 1; i >= 0; i--)
	{
		if (SkinOn[i] == None || SkinOn[i].bDeleteMe)
			continue;
		SkinOn[i].Skins[SkinAt[i]] = SkinWas[i];
		SkinOn[i].Skins.Length = SkinLen[i];
	}
	SkinOn.Length = 0;
	SkinAt.Length = 0;
	SkinWas.Length = 0;
	SkinLen.Length = 0;
}

// Every model in the level that can be seen through, found once
simulated function FindSheer()
{
	local Actor A;
	local int K, n;

	// (a tool: how long this takes, to the log)
	if ((Skip & 32) != 0)
		StopWatch(false);
	bSheerFound = true;
	AllSheer.Length = 0;
	AllSheerKind.Length = 0;
	foreach AllActors(class'Actor', A)
	{
		if (A.DrawType != DT_StaticMesh || A.StaticMesh == None)
			continue;
		K = SheerKindOf(A);
		if (K == 0)
			continue;
		n = AllSheer.Length;
		AllSheer[n] = A;
		AllSheerKind[n] = K;
		KeepSheerMats(A);
	}
	if ((Skip & 32) != 0)
	{
		StopWatch(true);
		Log("KFTorch: looked through the level for what can be seen through; found" @ AllSheer.Length @ "among" @ KnownMesh.Length @ "kinds of model");
	}
}

// Before a frame is drawn, and after it (from the screen hook): the light's cones are kept off what can be seen
// through for the length of the frame. (The renderer asks each thing whether it takes projectors as it draws it; a
// mark on the wall that was fixed there earlier stays.) Which of them are within reach is looked up here, several
// times a second, and nowhere else: the list must be the same from the first of these to the second.
simulated function Shun(bool bOn)
{
	local Actor A;
	local int i, n, Lo, Hi, m;
	local float D;
	local array<float> Near;

	HideSheer(false);
	if (bShunned)
	{
		for (i = 0; i < Sheer.Length; i++)
			if (SheerShun[i] != 0 && Sheer[i] != None && !Sheer[i].bDeleteMe)
				Sheer[i].bAcceptsProjectors = true;
		bShunned = false;
	}
	if (!bOn || !bLit || !bDressed || (Skip & 64) != 0)
		return;
	if (!bSheerFound)
		FindSheer();
	if (Level.TimeSeconds >= NextSheer)
	{
		NextSheer = Level.TimeSeconds + 0.25;
		Sheer.Length = 0;
		SheerKind.Length = 0;
		for (i = 0; i < AllSheer.Length; i++)
		{
			A = AllSheer[i];
			// (every one within reach, whichever way the light points: one that came into this as the light turned
			// would change from the one way of being lit to the other in full view)
			if (A == None || A.bDeleteMe || A.bHidden)
				continue;
			D = VSize(A.Location - Apex);
			if (D > MaxRange || (n >= 128 && D >= Near[n - 1]))
				continue;
			// (the 128 nearest, in order: in a city every puddle and stain is one, and taken as the level lists them
			// those by the light were left out)
			Lo = 0;
			Hi = n;
			while (Lo < Hi)
			{
				m = (Lo + Hi) / 2;
				if (Near[m] < D)
					Lo = m + 1;
				else
					Hi = m;
			}
			Sheer.Insert(Lo, 1);
			SheerKind.Insert(Lo, 1);
			Near.Insert(Lo, 1);
			Sheer[Lo] = A;
			SheerKind[Lo] = AllSheerKind[i];
			Near[Lo] = D;
			n = Min(n + 1, 128);
			Sheer.Length = n;
			SheerKind.Length = n;
			Near.Length = n;
		}
	}
	for (i = 0; i < Sheer.Length; i++)
	{
		SheerShun[i] = 0;
		if (Sheer[i] == None || Sheer[i].bDeleteMe)
			continue;
		SheerShun[i] = byte(Sheer[i].bAcceptsProjectors);
		Sheer[i].bAcceptsProjectors = false;
	}
	bShunned = true;
}

// A tool: who is in the beam and how each is lit, to the log
simulated function Who()
{
	local int i, j;
	local string S;

	for (i = 0; i < Bodies.Length; i++)
	{
		if (Bodies[i] == None)
			continue;
		S = "";
		for (j = 0; j < Bodies[i].Skins.Length; j++)
			S = S @ Bodies[i].Skins[j];
		Log("KFTorch: body" @ Bodies[i] @ "own colours" @ (Plain[i] != 0) @ "skins" $ S);
	}
	for (i = 0; i < Sheer.Length; i++)
		if (Sheer[i] != None)
			Log("KFTorch: seen through" @ Sheer[i] @ Sheer[i].StaticMesh @ "kind" @ SheerKind[i]);
}

// The bodies that are lit in their own colours are left out of the picture of what the light falls on (from that
// picture, just before it is taken and just after)
simulated function Bare(bool bOn)
{
	local int i;

	for (i = 0; i < Bodies.Length; i++)
	{
		if (Bodies[i] == None || Bodies[i].bDeleteMe || Plain[i] == 0)
			continue;
		if (bOn)
		{
			Bared[i] = byte(!Bodies[i].bHidden);
			Bodies[i].bHidden = true;
		}
		else if (Bared[i] != 0)
			Bodies[i].bHidden = false;
	}
}

simulated function SetLit(bool bOn)
{
	if (bLit == bOn)
		return;
	bLit = bOn;
	if (!bLit)
		Dark();
}

// Off the level, all of it
simulated function Dark()
{
	DetachProjector(true);
	if (Shade != None)
		Shade.DetachProjector(true);
	if (ShadeX != None)
		ShadeX.DetachProjector(true);
	if (Ground != None)
		Ground.DetachProjector(true);
	if (Sheen != None)
		Sheen.DetachProjector(true);
	if (SheenX != None)
		SheenX.DetachProjector(true);
	if (Fill != None)
		Fill.DetachProjector(true);
	if (Bounce != None)
		Bounce.Dark();
	bOff = false;
}

// (it is not fixed to whatever touches it, as a projector otherwise is)
simulated event Touch(Actor Other);
simulated event Untouch(Actor Other);

simulated function Undress()
{
	local int i;

	if (EyeW != None)
		EyeW.Destroy();
	if (EyeB != None)
		EyeB.Destroy();
	if (EyeA != None)
		EyeA.Destroy();
	EyeW = None;
	EyeB = None;
	EyeA = None;
	if (Shade != None)
		Shade.Destroy();
	Shade = None;
	if (ShadeX != None)
		ShadeX.Destroy();
	ShadeX = None;
	if (Ground != None)
		Ground.Destroy();
	Ground = None;
	Shun(false);
	UnclearParts();
	if (Sheen != None)
		Sheen.Destroy();
	Sheen = None;
	if (SheenX != None)
		SheenX.Destroy();
	SheenX = None;
	Sheer.Length = 0;
	AllSheer.Length = 0;
	bSheerFound = false;
	KnownMesh.Length = 0;
	KnownKinds.Length = 0;
	if (Fill != None)
		Fill.Destroy();
	Fill = None;
	if (Bounce != None)
		Bounce.Destroy();
	Bounce = None;
	Veil(false);
	HoldShadows(false);
	if (bDressed)
	{
		bDressed = false;
		ProjTexture = Texture'KFTorchTex.KFTCookie';
		Diff = None;
		Gate = None;
		LitFull = None;
		LitHalf = None;
		LitBody = None;
		LitFullX = None;
		Gained.Length = 0;
		Tint = None;
		if (Pattern != None)
		{
			Pattern.UClampMode = TC_Wrap;
			Pattern.VClampMode = TC_Wrap;
		}
		Pattern = None;
		Faint = None;
		FaintK = None;
		Deep = None;
		Pen = None;
		for (i = 0; i < 4; i++)
		{
			Need[i] = None;
			NeedMix[i] = None;
			NeedK[i] = None;
		}
		TapOver.Length = 0;
		RampLay.Material = None;
		Level.ObjectPool.FreeObject(RampLay);
		RampLay = None;
		FallPic = None;
		LitFullFall = None;
		LitHalfFall = None;
		if (FallLay != None)
		{
			FallLay.Material = None;
			Level.ObjectPool.FreeObject(FallLay);
			FallLay = None;
		}
		class'KFTMat'.static.FreeAll(Made, Level);
		Vanish = None;
	}
	Bodies.Length = 0;
	Glows.Length = 0;
}

simulated event Destroyed()
{
	local KFTHud Hud;

	DetachProjector(true);
	// (what see-through models are made of is shared by the whole level: never left invisible)
	SheerMats(false);
	Hud = class'KFTHud'.static.Of(Level.GetLocalPlayerController());
	if (Hud != None)
		Hud.Remove(self);
	Undress();
	Holder = None;
	Super.Destroyed();
}

// How much nearer than what the light sees a point has to be, as a share of the fog's reach, to be lit in full: a
// sixty-fourth (the difference is multiplied by that) and the slack
simulated function float Margin()
{
	return 1.0 / 64.0 + float(Slack) / 256.0;
}

// The light's pictures are taken without what glows (from each picture, just before it is taken and just after).
// The renderer leaves out the newer kind of particle system, the flares, the projectors and the sky when the viewer's
// show flags say so; the older kind of particle system and lone sprites are hidden one by one.
simulated function Veil(bool bOn)
{
	local int i;

	if (bOn && !bVeiled && PC != None)
	{
		WasShown = PC.ShowFlags & VeilShow;
		PC.ShowFlags = PC.ShowFlags & ~VeilShow;
		bVeiled = true;
	}
	else if (!bOn && bVeiled)
	{
		if (PC != None)
			PC.ShowFlags = PC.ShowFlags | WasShown;
		bVeiled = false;
	}
	for (i = 0; i < Glows.Length; i++)
	{
		if (Glows[i] == None || Glows[i].bDeleteMe)
			continue;
		if (bOn)
		{
			Veiled[i] = byte(!Glows[i].bHidden);
			Glows[i].bHidden = true;
		}
		else if (Veiled[i] != 0)
			Glows[i].bHidden = false;
	}
}

// What can be seen through is left out of the light's pictures: hidden before the first of the three is taken, and
// shown again after the last (the three are taken one after another, before anything else is drawn).
simulated function HideSheer(bool bOn)
{
	local int i;

	if (bOn == bSheerHidden)
		return;
	bSheerHidden = bOn;
	// (what such things are made of as well: see KeepSheerMats)
	SheerMats(bOn && (Skip & 64) == 0);
	if (!bOn)
		UnclearParts();
	for (i = 0; i < Sheer.Length; i++)
	{
		if (Sheer[i] == None || Sheer[i].bDeleteMe)
			continue;
		// (cut out as the cones cannot follow: in the pictures whole)
		if (SheerKind[i] == 5)
		{
			SheerHid[i] = 0;
			continue;
		}
		// (a solid model with see-through parts stays in the pictures, but for those parts where it can be so)
		if (SheerKind[i] == 4)
		{
			SheerHid[i] = 0;
			if (bOn && !Sheer[i].bStatic && (Skip & 64) == 0)
				ClearParts(Sheer[i]);
			continue;
		}
		if (bOn)
		{
			SheerHid[i] = byte(!Sheer[i].bHidden);
			Sheer[i].bHidden = true;
		}
		else if (SheerHid[i] != 0)
			Sheer[i].bHidden = false;
	}
	// (And, seen from outside, whoever holds the light and what they carry. Held in the first person the pictures
	// are taken with their eyes, which do not see their own body; from outside they are taken with the light's,
	// and the body the light is held in front of threw its shadow out along the beam.)
	if (bOn)
	{
		HolderHid.Length = 0;
		if (Holder != None && PC != None && (PC.ViewTarget != Holder || PC.bBehindView))
		{
			HideHeld(Holder);
			if (xPawn(Holder) != None)
				HideHeld(xPawn(Holder).WeaponAttachment);
			for (i = 0; i < Holder.Attached.Length; i++)
				HideHeld(Holder.Attached[i]);
		}
	}
	else
	{
		for (i = 0; i < HolderHid.Length; i++)
			if (HolderHid[i] != None && !HolderHid[i].bDeleteMe)
				HolderHid[i].bHidden = false;
		HolderHid.Length = 0;
	}
}

simulated function HideHeld(Actor A)
{
	if (A == None || A.bDeleteMe || A.bHidden)
		return;
	A.bHidden = true;
	HolderHid[HolderHid.Length] = A;
}

// The shadow the game gives a player or a creature is a picture too, of its owner seen from above, and it is drawn
// when it is first needed in a frame. That must not be while one of the light's pictures is being taken: those are
// taken in plain textures, and the shadow would come out as a picture of its owner in colour, on the floor, for the
// whole frame. So the shadows that are due to be drawn this frame are taken off the level until the light's
// pictures are done, and put back. (One that is due is one its own code has just put on: it marks the picture as
// due in the same breath. Marking the picture as done would not do: one that has never been drawn stops the game
// when the renderer comes to it.)
simulated function HoldShadows(bool bHold)
{
	local Projector Pr;
	local ShadowBitmapMaterial M;
	local ShadowProjector SP;
	local int i;

	for (i = 0; i < Held.Length; i++)
	{
		Pr = Held[i];
		if (Pr == None || Pr.bDeleteMe)
			continue;
		SP = ShadowProjector(Pr);
		// (Back on, if it would still be put on now. Taken off first: two lights in one frame, the torch and the muzzle
		// flash, both hold the same shadow and both put it back, and the engine's AttachProjector never lets go of the
		// one it had. That one stays on the level for good, pointing at the shadow; once the shadow is gone the next
		// picture of the level stops the game, and before that enough of them crowd the light out of the 256 the
		// renderer draws.)
		if (SP != None)
		{
			if (SP.bShadowActive && SP.ShadowActor != None && !SP.ShadowActor.bHidden && SP.ShadowTexture != None)
			{
				SP.DetachProjector(true);
				SP.AttachProjector();
			}
		}
		else if (Pr.Instigator != None && !Pr.Instigator.bHidden)
		{
			Pr.DetachProjector(true);
			Pr.AttachProjector();
		}
	}
	Held.Length = 0;
	if (!bHold)
		return;
	foreach DynamicActors(class'Projector', Pr)
	{
		M = ShadowBitmapMaterial(Pr.ProjTexture);
		if (M != None && M.Dirty)
		{
			Pr.DetachProjector(true);
			Held[Held.Length] = Pr;
		}
	}
}

// How far the fog should reach this frame: a little past what the beam lands on, as five lines from the light find
// it (down the middle, and four part way out). The furthest of the five is left out: one line through a doorway
// should not spend the steps of distance on the next room. What is past the fog's end is lit all the same, and is
// still in the shadow of anything nearer; only what stands out there throws no shadow of its own.
simulated function float Reach5(out vector MidHit, out vector MidNormal, out float MidDist)
{
	local vector X, Y, Z, HL, HN, Way, At2;
	local float Far, Second, D, DD, F;
	local Actor Hit;
	local int i;

	GetAxes(rotator(Aim), X, Y, Z);
	MidDist = -1.0;
	Deepest5 = 0.0;
	NearLines = Throw;
	for (i = 0; i < 5; i++)
	{
		Way = X;
		if (i == 1)
			Way = X + Y * 0.22;
		else if (i == 2)
			Way = X - Y * 0.22;
		else if (i == 3)
			Way = X + Z * 0.22;
		else if (i == 4)
			Way = X - Z * 0.22;
		Way = Normal(Way);
		Hit = Trace(HL, HN, Apex + Way * Throw, Apex, false);
		if (Hit != None)
		{
			D = (HL - Apex) dot X;
			NearLines = FMin(NearLines, D);
			if (i == 0)
			{
				MidHit = HL;
				MidNormal = HN;
				MidDist = VSize(HL - Apex);
			}
			// (how deep the beam goes along this line: on through a wire fence or a window to what is behind it)
			DD = D;
			At2 = HL;
			if (LetsThrough(Hit))
				DD = Through(Way, Throw, X, F, At2);
			if (DD > Deepest5)
			{
				Deepest5 = DD;
				Deepest5At = At2;
			}
		}
		else
		{
			D = MaxRange;
			Deepest5 = Throw;
			Deepest5At = Apex + Way * Throw;
		}
		if (D > Far)
		{
			Second = Far;
			Far = D;
		}
		else if (D > Second)
			Second = D;
	}
	return FClamp(Second * 1.3 + 60.0, MinRange, MaxRange);
}

// How far the light's cones on the level have to reach, by this frame's reckoning: a little past the furthest thing
// the beam lands on, as the five lines down its middle find it and two more thrown through it at random; no further
// than the fog lets anything be seen; never past where the light is gone (FarMost). Seven lines miss things: a doorway at the
// far end of a room, to one side of the middle. So the cones grow at once to what any frame finds; the furthest
// place found is looked at again every frame for as long as it is in the beam and in sight, so that what a chance
// line found once is not lost again; and the cones shrink only when no frame has found as much for a while (FarHold,
// and FarFrames). Past the cones' end nothing is lit, and the end is a flat face: what a cone cut too short would
// show is a room lit to a line across its floor and dark beyond.
simulated function float Farthest()
{
	local vector X, Y, Z, HL, HN, Way, To, At;
	local float Want, FogEnd, Out, Round, D, F;
	local int k;

	if ((Skip & 2048) != 0)
		return FarMost;
	GetAxes(rotator(Aim), X, Y, Z);
	Want = Deepest5;
	At = Deepest5At;
	for (k = 0; k < 2; k++)
	{
		// (evenly over the pool's disc; every other frame the second goes through the ring of spill round it)
		Out = PoolWide * Sqrt(FRand());
		if (k == 1 && bSpillLine)
			Out = PoolWide + (SpillWide - PoolWide) * FRand();
		Round = 2.0 * Pi * FRand();
		// (as far along the beam as the light reaches, which along a line to one side is further than that)
		Way = X + Y * (Out * Cos(Round)) + Z * (Out * Sin(Round));
		// (on through a wire fence or a window, to what is lit behind it; and the first thing met is the nearest)
		D = Through(Way, FarMost, X, F, HL);
		if (F >= 0.0)
			NearLines = FMin(NearLines, F);
		if (D > Want)
		{
			Want = D;
			At = HL;
		}
	}
	bSpillLine = !bSpillLine;
	// the furthest place found before: still in the beam, and nothing in the way?
	if (bFarAt)
	{
		To = FarAt - Apex;
		D = To dot X;
		if (D > 0.0 && VSize(To - X * D) < D * SpillWide && Clear(FarAt - Normal(To) * 12.0))
		{
			if (D > Want)
			{
				Want = D;
				At = FarAt;
			}
		}
		else
			bFarAt = false;
	}
	FarAt = At;
	bFarAt = true;
	Want = FMin(Want, FarMost) * FarSpare + FarMore;
	// (what the fog hides needs no light: the view's own fog, or that of the water or mist whoever holds it stands in)
	if (Holder != None && Holder.PhysicsVolume != None && Holder.PhysicsVolume.bDistanceFog)
		FogEnd = Holder.PhysicsVolume.DistanceFogEnd;
	else if (PC != None)
		FogEnd = PC.CurrentDistanceFogEnd;
	if (FogEnd > 0.0)
		Want = FMin(Want, FogEnd * 1.03 + 80.0);
	return FClamp(Want, FarLeast, FarMost);
}

// The share of the pictures' steps of distance that stand for "nearer than where the fog begins"
simulated function float NearFloor()
{
	if ((Skip & 4096) != 0)
		return 0.0;
	return float(Clamp(FloorSteps, 0, 64)) / 256.0;
}

// Where the fog of the two pictures should begin this frame: a little short of the nearest thing in the beam, spill
// and all, as the lines through it find the level and as the bodies in the beam stand. The pictures hold 256 steps
// of distance, and from the light to the nearest thing there is nothing to spend them on. The nearest thing is most
// often where the spill's edge meets the floor or a wall beside the light, so eight lines are thrown round that
// edge besides the ones through the beam. (At first the pool alone was gone by, which put the start further out
// and left the floor under the spill's edge nearer than it; the user chose the surer way on 2026-10-13.) What a
// line has yet to meet and is nearer all the same is lit, and throws its shadow from where the fog begins.
simulated function float Nearest()
{
	local vector X, Y, Z, HL, HN, Way;
	local float Near, D, Long, Round;
	local int i, k;

	if ((Skip & 4096) != 0)
		return 0.0;
	// (what the eight lines found is thrown away when the light has turned from where they were found: the fog
	// begins at the light until they have all been looked at again)
	if ((Aim dot EdgeAim) < 0.9945)
	{
		EdgeAim = Aim;
		for (i = 0; i < 8; i++)
			EdgeNear[i] = 0.0;
	}
	GetAxes(rotator(Aim), X, Y, Z);
	// (no further than could move the fog's start)
	Long = (Range * 0.5 + NearLess) / FMax(NearShare, 0.1) + 50.0;
	for (k = 0; k < 2; k++)
	{
		i = EdgeTurn;
		EdgeTurn = (EdgeTurn + 3) % 8;
		Round = float(i) * Pi * 0.25;
		Way = X + (Y * Cos(Round) + Z * Sin(Round)) * (SpillWide * 0.98);
		if (Trace(HL, HN, Apex + Way * Long, Apex, false) != None)
			EdgeNear[i] = (HL - Apex) dot X;
		else
			EdgeNear[i] = Throw;
	}
	Near = NearLines;
	for (i = 0; i < 8; i++)
		Near = FMin(Near, EdgeNear[i]);
	for (i = 0; i < Bodies.Length; i++)
		if (Bodies[i] != None && !Bodies[i].bDeleteMe)
		{
			D = ((Bodies[i].Location - Apex) dot Aim) - Bodies[i].CollisionRadius;
			Near = FMin(Near, D);
		}
	return FClamp(Near * NearShare - NearLess, 0.0, Range * 0.5);
}

// Along a line from the light: how far along the beam (X) the first thing it meets is (First; under nothing if it
// meets nothing), and how far the first thing that stops light is, going on through what is cut out or can be seen
// through (returned, and where that is: At; the line's end if nothing stops it)
simulated function float Through(vector Way, float Long, vector X, out float First, out vector At)
{
	local vector HL, HN, Start, End;
	local Actor A;
	local int n;

	Start = Apex;
	End = Apex + Way * Long;
	First = -1.0;
	for (n = 0; n < 4; n++)
	{
		A = Trace(HL, HN, End, Start, false);
		if (A == None)
			break;
		if (First < 0.0)
			First = (HL - Apex) dot X;
		if (!LetsThrough(A))
		{
			At = HL;
			return (HL - Apex) dot X;
		}
		Start = HL + Normal(Way) * 4.0;
		if (((End - Start) dot Way) <= 0.0)
			break;
	}
	At = End;
	return (End - Apex) dot X;
}

// Whether nothing that stops light stands between the light and a place
simulated function bool Clear(vector P)
{
	local vector Way, At;
	local float First;

	Way = Normal(P - Apex);
	Through(Way, VSize(P - Apex), Way, First, At);
	return VSize(At - P) < 2.0;
}

// Whether light goes through a thing somewhere: a model with a part that is cut out (a wire fence) or can be seen
// through (a window). The level's own walls and floors never do.
simulated function bool LetsThrough(Actor A)
{
	local string S, Ref;
	local int i, j;
	local byte Yes;

	if (A == None || A.StaticMesh == None || LevelInfo(A) != None)
		return false;
	for (i = 0; i < A.Skins.Length; i++)
		if (A.Skins[i] != None && Holey(A.Skins[i]))
			return true;
	for (i = 0; i < ThroughMesh.Length; i++)
		if (ThroughMesh[i] == A.StaticMesh)
			return ThroughYes[i] != 0;
	S = A.StaticMesh.GetPropertyText("Materials");
	for (j = 0; j < 64 && Yes == 0; j++)
	{
		i = InStr(S, "Material=");
		if (i < 0)
			break;
		S = Mid(S, i + 9);
		i = InStr(S, "'");
		if (Left(S, 4) ~= "None" || i < 0)
			continue;
		Ref = Mid(S, i + 1);
		i = InStr(Ref, "'");
		if (i <= 0)
			continue;
		if (Holey(Material(DynamicLoadObject(Left(Ref, i), class'Material', true))))
			Yes = 1;
	}
	i = ThroughMesh.Length;
	ThroughMesh[i] = A.StaticMesh;
	ThroughYes[i] = Yes;
	return Yes != 0;
}

// Whether a material lets light through anywhere: cut out, or see-through in some measure
simulated function bool Holey(Material M)
{
	local int n;

	if (M == None)
		return false;
	if (MatKind(M) != 0)
		return true;
	for (n = 0; n < 6 && M != None; n++)
	{
		if (Shader(M) != None)
		{
			if (Shader(M).OutputBlending == OB_Masked || Shader(M).Opacity != None)
				return true;
			M = Shader(M).Diffuse;
		}
		else if (FinalBlend(M) != None)
		{
			if (FinalBlend(M).AlphaTest)
				return true;
			M = FinalBlend(M).Material;
		}
		else if (Texture(M) != None)
			return Texture(M).bMasked || Texture(M).bAlphaTexture;
		else if (Modifier(M) != None)
			M = Modifier(M).Material;
		else
			return false;
	}
	return false;
}

// Where the light is this frame; false if there is nobody to hold it
simulated function bool Place()
{
	local Actor Cam;
	local vector Eye, X, Y, Z;
	local rotator Rot;
	local Coords B;
	local xPawn XP;

	if (PC == None)
		PC = Level.GetLocalPlayerController();
	if (PC == None || Holder == None || Holder.bDeleteMe || Holder.Health <= 0)
		return false;
	if (PC.ViewTarget == Holder && !PC.bBehindView)
	{
		// held up in front of the eye: where the weapon's light was from the eye when the weapon was last drawn
		PC.PlayerCalcView(Cam, Eye, Rot);
		if (bRel)
		{
			Apex = Eye + (Rel >> Rot);
			Aim = Normal(RelAim >> Rot);
		}
		else
		{
			GetAxes(Rot, X, Y, Z);
			Apex = Eye + Y * 7.0 - Z * 8.0;
			Aim = X;
		}
	}
	else
	{
		// seen from outside: on the weapon in the holder's hand
		XP = xPawn(Holder);
		if (XP != None && XP.WeaponAttachment != None && Level.TimeSeconds - XP.LastRenderTime < 1.0)
		{
			B = XP.WeaponAttachment.GetBoneCoords('FlashLight');
			Aim = Normal(B.XAxis);
			Apex = B.Origin + Aim * 10.0;
		}
		else
		{
			Aim = vector(Holder.GetViewRotation());
			Apex = Holder.Location + Holder.EyePosition() + Aim * 20.0;
		}
	}
	SetLocation(Apex + Aim * Reach);
	SetRotation(rotator(Aim));
	return true;
}

// After a frame is drawn (from the screen hook): where the light on the weapon in hand was, as the eye saw it. The
// weapon in hand is drawn with the frame, where the view then is, so its bones are known only afterwards.
simulated function Aimed()
{
	local KFWeapon W;
	local Coords B;
	local Actor Cam;
	local vector Eye, At;
	local rotator Rot;

	bRel = false;
	if (PC == None || Holder == None || PC.ViewTarget != Holder || PC.bBehindView)
		return;
	W = KFWeapon(Holder.Weapon);
	if (W == None || W.Mesh == None || Level.TimeSeconds - W.LastRenderTime > 0.3)
		return;
	B = W.GetBoneCoords('LightBone');
	if (B.XAxis == vect(0,0,0))
		return;
	PC.PlayerCalcView(Cam, Eye, Rot);
	// (as the mod's own light finds it: the weapon in hand is drawn at a fifth of its size about its own place)
	At = W.Location + (B.Origin - W.Location) * 0.2
		+ B.XAxis * W.FirstPersonFlashlightOffset.X + B.YAxis * W.FirstPersonFlashlightOffset.Y + B.ZAxis * W.FirstPersonFlashlightOffset.Z;
	Rel = (At - Eye) << Rot;
	RelAim = Normal(B.XAxis) << Rot;
	// (the bulb stays inside whoever holds it, or it would look through the wall they lean on; and it never points
	// back past their shoulder)
	if (VSize(Rel) > 14.0)
		Rel = Normal(Rel) * 14.0;
	if (RelAim.X < 0.2)
		return;
	bRel = true;
}

// Whether the view is where it was when the pictures were last taken, near enough: under a sixth of a degree round
// and a unit and a half off
simulated function bool Steady()
{
	local Actor Cam;
	local vector Eye;
	local rotator Rot;

	if (PC == None)
		return false;
	PC.PlayerCalcView(Cam, Eye, Rot);
	return (vector(Rot) dot ShotWay) > 0.999996 && VSize(Eye - ShotEye) < 1.5;
}

// Before a frame (from the screen hook): the light is put where it is this frame, its projectors are taken off the
// level, and its three pictures are asked for. They must not have the light in them.
simulated function bool Frame(Canvas C)
{
	local float Want, MidDist;
	local vector MidHit, MidNormal;
	local Actor Cam;

	if (!bDressed || !bLit)
		return false;
	// How long frames take; and with that, whether this is a frame the pictures are left as they are, and the light
	// where it is. (Taken up at 12 thousandths of a second a frame and dropped again at 9, so that it does not
	// flutter.)
	if (LastFrame > 0.0)
		Pace += (FClamp(Level.TimeSeconds - LastFrame, 0.0, 0.1) - Pace) * 0.08;
	LastFrame = Level.TimeSeconds;
	if (Thrift == 1)
		bSparing = true;
	else if (Thrift != 2)
		bSparing = false;
	else if (Pace > 0.012)
		bSparing = true;
	else if (Pace < 0.009)
		bSparing = false;
	// (When it is left to the light, 2, a frame is passed over only while the view is all but still: a light that
	// stays behind for every other frame of a turn is seen to judder.)
	if (bYield && bHavePictures)
	{
		bYield = false;
		bSkipped = true;
		return false;
	}
	bYield = false;
	if (bSparing && bHavePictures && !bSkipped && (Skip & 2) == 0 && (Thrift == 1 || Steady()))
	{
		bSkipped = true;
		return false;
	}
	bSkipped = false;
	DetachProjector(true);
	if (Shade != None)
		Shade.DetachProjector(true);
	if (ShadeX != None)
		ShadeX.DetachProjector(true);
	if (Ground != None)
		Ground.DetachProjector(true);
	if (Sheen != None)
		Sheen.DetachProjector(true);
	if (SheenX != None)
		SheenX.DetachProjector(true);
	if (Fill != None)
		Fill.DetachProjector(true);
	if (Bounce != None)
		Bounce.Dark();
	bOff = false;
	if (!Place())
		return false;
	// (the reach is eased toward what is wanted, so that the shadows do not jump as it changes)
	Want = Reach5(MidHit, MidNormal, MidDist);
	if (Want > Range)
		Range = Want;
	else
		Range += (Want - Range) * 0.15;

	// (and so is how far the cones reach, when it shrinks: at once when it grows)
	Want = Farthest();
	if (Want >= FarLit)
	{
		FarLit = Want;
		FarGrew = Level.TimeSeconds;
		FarQuiet = 0;
	}
	else if (++FarQuiet > FarFrames && Level.TimeSeconds - FarGrew > FarHold)
		FarLit += (Want - FarLit) * 0.1;
	MaxTraceDistance = int((FarLit - Reach) / ConeShare) + 1;
	PlainEnd = FarLit + 30.0;
	// (and where the fog begins: pulled in at once, let out slowly and only after a while)
	Want = Nearest();
	if (Want <= FogStart)
	{
		FogStart = Want;
		NearAt = Level.TimeSeconds;
	}
	else if (Level.TimeSeconds - NearAt > FarHold)
		FogStart += (Want - FogStart) * 0.05;
	FogStart = FClamp(FogStart, 0.0, Range * 0.5);
	FloorK.Color.R = Clamp(int(NearFloor() * 256.0 + 0.5), 0, 255);
	FloorK.Color.G = FloorK.Color.R;
	FloorK.Color.B = FloorK.Color.R;
	class'KFTMat'.static.RampFrom(RampLay, FogStart, Range, NearFloor(), 1.0 / 16.0 + 4.0 / 256.0 - Margin());
	if (Bounce != None)
		Bounce.Lands(MidHit, MidNormal, MidDist);
	bOff = true;
	bGotW = false;
	bGotB = false;
	bGotA = false;

	if ((Skip & 2) != 0 && bHavePictures)
	{
		bOff = false;
		Join();
		return false;
	}
	bHavePictures = true;
	PC.PlayerCalcView(Cam, ShotEye, ShotTurn);
	ShotWay = vector(ShotTurn);
	HoldShadows(true);
	HideSheer(true);
	// (held, the light sees as its holder sees, who is not in the picture)
	Cam = self;
	if (PC.ViewTarget == Holder && !PC.bBehindView)
		Cam = Holder;
	// (a tool: some of the pictures kept, to time the others)
	if ((Skip & 256) != 0)
	{
		bGotW = true;
		bGotB = true;
	}
	else
	{
		EyeW.Take(Cam);
		EyeB.Take(Cam);
	}
	if ((Skip & 128) != 0)
		bGotA = true;
	else
		EyeA.Take(Cam);
	if ((Skip & 384) == 384)
	{
		HoldShadows(false);
		HideSheer(false);
		bOff = false;
		Join();
		return false;
	}
	// (a picture made by script is drawn when something is drawn with it: one pixel that changes nothing)
	C.SetPos(0, 0);
	C.DrawTile(EyeW.Unseen, 1, 1, 0, 0, 1, 1);
	C.SetPos(0, 0);
	C.DrawTile(EyeB.Unseen, 1, 1, 0, 0, 1, 1);
	C.SetPos(0, 0);
	C.DrawTile(EyeA.Unseen, 1, 1, 0, 0, 1, 1);
	return true;
}

// Whether a thing is in the light's cone or near enough to it to be worth laying the light on (a model's place may
// be at one end of it; past the cone's edge there is no light to lay)
simulated function bool InCone(Actor A)
{
	local vector To;
	local float D;

	if (A == None || A.bDeleteMe)
		return false;
	To = A.Location - Apex;
	D = To dot Aim;
	return D > -300.0 && D < Throw + 300.0 && VSize(To - Aim * D) < FMax(D, 0.0) * 1.4 + 400.0;
}

// The projectors back on the level: this one and its other half for the renderer to look up, the bodies' fixed to
// the bodies in the beam
simulated function Join()
{
	local Actor A;
	local vector To;
	local float D, Wide;
	local int i;

	// (each taken off before it is put on: putting on what is already on leaves the first on the level for good, see
	// HoldShadows)
	if ((Skip & 8) == 0)
	{
		DetachProjector(true);
		AttachProjector();
	}
	LastOn = Level.TimeSeconds;
	if (Fill != None && Soft == 1 && (Skip & 4) == 0)
	{
		Fill.SetLocation(Location);
		Fill.SetRotation(Rotation);
		Fill.MaxTraceDistance = MaxTraceDistance;
		Fill.DetachProjector(true);
		Fill.AttachProjector();
	}
	if (Shade != None)
	{
		Shade.SetLocation(Location);
		Shade.SetRotation(Rotation);
		Shade.DetachProjector(true);
		Shade.AttachProjector();
	}
	if (ShadeX != None)
	{
		ShadeX.SetLocation(Location);
		ShadeX.SetRotation(Rotation);
		ShadeX.DetachProjector(true);
		ShadeX.AttachProjector();
	}
	if (Ground != None && (Skip & 8192) == 0)
	{
		Ground.SetLocation(Location);
		Ground.SetRotation(Rotation);
		Ground.DetachProjector(true);
		Ground.AttachProjector();
	}
	if (Sheen != None && (Skip & 16) == 0)
	{
		Sheen.SetLocation(Location);
		Sheen.SetRotation(Rotation);
		Sheen.DetachProjector(true);
		Sheen.AttachProjector();
		for (i = 0; i < Sheer.Length; i++)
			if ((SheerKind[i] == 1 || SheerKind[i] == 4) && InCone(Sheer[i]))
				Sheen.AttachActor(Sheer[i]);
	}
	if (SheenX != None && (Skip & 16) == 0)
	{
		SheenX.SetLocation(Location);
		SheenX.SetRotation(Rotation);
		SheenX.DetachProjector(true);
		SheenX.AttachProjector();
		for (i = 0; i < Sheer.Length; i++)
			if (SheerKind[i] == 2 && InCone(Sheer[i]))
				SheenX.AttachActor(Sheer[i]);
	}
	// (who and what is in the beam is looked for several times a second, not every frame)
	if (Level.TimeSeconds >= NextBodies)
	{
		NextBodies = Level.TimeSeconds + 0.1;
		Bodies.Length = 0;
		Glows.Length = 0;
		Wide = Tan(float(FOV) * Pi / 360.0) * 1.1;
		foreach DynamicActors(class'Actor', A)
		{
			if (A.bHidden)
				continue;
			To = A.Location - Apex;
			if (A.DrawType == DT_Particle || A.DrawType == DT_Sprite)
			{
				// (anywhere near: what one throws out goes a long way from where it is)
				if (Glows.Length < 96 && VSize(To) < Throw + 400.0)
					Glows[Glows.Length] = A;
				continue;
			}
			if (A.DrawType != DT_Mesh)
				continue;
			// (what is fixed to something and touches nothing is lit with what it is fixed to: a weapon in a hand)
			if (!A.bCollideActors && A.Base != None)
				continue;
			// (whoever holds the light is behind it, and so is what they carry)
			if (A == Holder || A.Owner == Holder)
				continue;
			D = To dot Aim;
			// (in front, in reach, and within the cone with room to spare for how big they are)
			if (D < -40.0 || D > FarMost + 100.0 || VSize(To - Aim * D) > D * Wide + 120.0)
				continue;
			// (a cloaked stalker is all but invisible, and stood in the beam as a black shape: its shadow, right
			// behind it. It is left out of the light's pictures, as a glow is, and not lit.)
			if (SeeThroughBody(A))
			{
				if (Glows.Length < 96)
					Glows[Glows.Length] = A;
				continue;
			}
			if (!A.bAcceptsProjectors || Bodies.Length >= 40)
				continue;
			if (A.Style != STY_Normal && A.Style != STY_Masked)
				continue;
			i = Bodies.Length;
			Bodies[i] = A;
			Plain[i] = byte(Shade != None && OwnColours(A));
		}
	}
	if ((Skip & 1) == 0)
		for (i = 0; i < Bodies.Length; i++)
			if (Bodies[i] != None && !Bodies[i].bDeleteMe)
			{
				if (Plain[i] != 0)
					Shade.AttachActor(Bodies[i]);
				else if (ShadeX != None)
					ShadeX.AttachActor(Bodies[i]);
			}
}

// A picture is taken: after all three, the projectors go back on
simulated function After(KFTEye Eye)
{
	if (Eye == EyeW)
		bGotW = true;
	else if (Eye == EyeB)
		bGotB = true;
	else
		bGotA = true;
	if (bOff && bGotW && bGotB && bGotA)
	{
		bOff = false;
		// (what see-through models are made of is put back before the bodies are looked at)
		SheerMats(false);
		if (bLit)
			Join();
	}
}

// One of the pictures made from the light's three: drawn now, before anything is drawn with it
simulated function Make(Canvas C, ScriptedTexture T, Material Seen)
{
	T.Revision++;
	C.SetPos(0, 0);
	C.DrawTile(Seen, 1, 1, 0, 0, 1, 1);
	C.DrawActor(None, false, false);
}

// Before the frame, after the light's pictures are taken (from the screen hook)
simulated function Prep(Canvas C)
{
	local int i, j;

	HoldShadows(false);
	HideSheer(false);
	if (!bDressed || !bLit)
		return;
	Make(C, Depth, DepthSeen);
	bSoftNow = (Edge > 0.01 && Pen != None);
	if (bSoftNow)
	{
		SoftNumbers();
		for (j = 0; j < 4; j++)
			Make(C, Need[j], NeedSeen[j]);
		Make(C, Deep, DeepSeen);
		Make(C, Pen, PenSeen);
	}
	// (the pattern for bodies has the soft edges in it, so it is made each frame; without them, when the bulb changes)
	if (bSoftNow || bPatternSoft || !bPatternMade || PatternFor != Tint.Color)
	{
		bPatternMade = true;
		bPatternSoft = bSoftNow;
		PatternFor = Tint.Color;
		Make(C, Pattern, PatternSeen);
		i = Clamp(int(255.0 * (1.0 - SheerGain)), 0, 255);
		FaintK.Color.R = i;
		FaintK.Color.G = i;
		FaintK.Color.B = i;
		Make(C, Faint, FaintSeen);
	}
	// (made every frame, though it never changes: a picture made here is lost when the screen's size is changed)
	Make(C, FallPic, FallSeen);
	Make(C, FluxFull, FullSeen);
	if (Soft == 1 || (bThrowBack && Bounce != None))
		Make(C, FluxHalf, HalfSeen);
	if (bThrowBack && Bounce != None)
		Bounce.Prep(C);
}

simulated event RenderTexture(ScriptedTexture Tex)
{
	local int i, j;

	if (!bDressed || EyeW == None)
		return;
	if (Tex == Pattern || Tex == Faint)
	{
		if (bSoftNow)
			Whole(Tex, 512, PatternOverSoft);
		else
			Whole(Tex, 512, PatternOver);
		if (Tex == Faint)
			Whole(Tex, 512, FaintOver);
	}
	else if (Tex == Depth)
	{
		Whole(Tex, EyeW.Size, DepthOver);
		Whole(Tex, EyeW.Size, FloorOver);
	}
	else if (Tex == FallPic)
	{
		// black; the fall as it is down to the row where it bends; and the rest of it, all the way to nothing,
		// squeezed into the rows from there to where the cones end
		Whole(Tex, 64, FallClear);
		Tex.DrawTile(0, 0, 64, FallBend, 0, 0, 4, FallBend, FallOver, class'Canvas'.static.MakeColor(255, 255, 255, 255));
		Tex.DrawTile(0, FallBend, 64, FallEnd - FallBend, 0, FallBend, 4, 64 - FallBend, FallOver, class'Canvas'.static.MakeColor(255, 255, 255, 255));
	}
	else if (Tex == FluxFull)
	{
		if (bSoftNow)
			Whole(Tex, EyeA.Size, FullOverSoft);
		else
			Whole(Tex, EyeA.Size, FullOver);
	}
	else if (Tex == FluxHalf)
	{
		if (bSoftNow)
			Whole(Tex, EyeA.Size, HalfOverSoft);
		else
			Whole(Tex, EyeA.Size, HalfOver);
	}
	else if (Tex == Deep)
	{
		Whole(Tex, SoftSize, DeepOver);
		Whole(Tex, SoftSize, FadeOver);
	}
	else if (Tex == Pen)
	{
		Whole(Tex, SoftSize, PenClear);
		for (i = 0; i < TapOver.Length; i++)
			Whole(Tex, SoftSize, TapOver[i]);
	}
	else
	{
		for (j = 0; j < 4; j++)
			if (Tex == Need[j])
			{
				Whole(Tex, SoftSize, NeedOver[j]);
				Whole(Tex, SoftSize, BiasOver);
				Whole(Tex, SoftSize, StartOver[j]);
			}
	}
}

// A picture drawn over the whole of the one being made. (All of it, whatever sizes the pictures it is put together
// from are: the widest of them is what the drawing measures by.)
simulated function Whole(ScriptedTexture Tex, float Size, Material M)
{
	Tex.DrawTile(0, 0, Size, Size, 0, 0, M.MaterialUSize(), M.MaterialVSize(), M, class'Canvas'.static.MakeColor(255, 255, 255, 255));
}

simulated function Tick(float DT)
{
	if (Holder == None || Holder.bDeleteMe)
	{
		Destroy();
		return;
	}
	// (if the pictures have stopped coming, the light stays where it was)
	if (bLit && bOff && Level.TimeSeconds - LastOn > 0.3)
	{
		bOff = false;
		Join();
	}
}

// A tool: the light's pictures, small, along the top of the screen: what it falls on, how far it sees, what it
// throws, and what a body is lit with
simulated function Show(Canvas C)
{
	local float S;

	if (!bShow || !bDressed)
		return;
	S = 240.0;
	C.Style = 1;
	C.SetDrawColor(255, 255, 255, 255);
	if (ShowPick > 0)
	{
		S = C.ClipY;
		C.SetPos(0, 0);
		if (ShowPick == 1)
			C.DrawTile(EyeA.View, S, S, 0, 0, EyeA.Size, EyeA.Size);
		else if (ShowPick == 2)
			C.DrawTile(EyeW.View, S, S, 0, 0, EyeW.Size, EyeW.Size);
		else if (ShowPick == 3)
			C.DrawTile(EyeB.View, S, S, 0, 0, EyeB.Size, EyeB.Size);
		else if (ShowPick == 4)
			C.DrawTile(Depth, S, S, 0, 0, EyeW.Size, EyeW.Size);
		else if (ShowPick == 5)
			C.DrawTile(FluxFull, S, S, 0, 0, EyeA.Size, EyeA.Size);
		else if (ShowPick == 6)
			C.DrawTile(Pattern, S, S, 0, 0, 512, 512);
		else if (ShowPick == 7 && Pen != None)
			C.DrawTile(Pen, S, S, 0, 0, EyeW.Size, EyeW.Size);
		return;
	}
	C.SetPos(8, 8);
	C.DrawTile(EyeA.View, S, S, 0, 0, EyeA.Size, EyeA.Size);
	C.SetPos(16 + S, 8);
	C.DrawTile(Depth, S, S, 0, 0, EyeW.Size, EyeW.Size);
	C.SetPos(24 + 2 * S, 8);
	C.DrawTile(FluxFull, S, S, 0, 0, EyeA.Size, EyeA.Size);
	C.SetPos(32 + 3 * S, 8);
	C.DrawTile(Pattern, S, S, 0, 0, 512, 512);
	if (Pen != None && bSoftNow)
	{
		C.SetPos(40 + 4 * S, 8);
		C.DrawTile(Pen, S, S, 0, 0, EyeW.Size, EyeW.Size);
	}
}

// A tool: what the light is doing, in a line
simulated function string Says()
{
	return "lit" @ bLit @ "pictures" @ EyeA.Size @ "and" @ EyeW.Size @ "cone" @ FOV @ "fog from" @ int(FogStart) @ "to" @ int(Range) @ "of" @ int(MaxRange) @ "cones reach" @ int(FarLit) @ "of" @ int(FarMost)
		@ "bodies in the beam" @ Bodies.Length @ "left out of its pictures" @ Glows.Length @ "seen through" @ Sheer.Length @ "of" @ AllSheer.Length @ "lean" @ Soft @ "bounce" @ bThrowBack
		@ "on the weapon" @ bRel @ "bright" @ Bright @ "soft edges" @ int(Edge * 100.0)
		@ "thrift" @ Thrift @ "sparing now" @ bSparing @ "a frame takes" @ int(Pace * 10000.0) * 0.1 @ "ms";
}

defaultproperties
{
     Reach=22.000000
     PictureSize=2048
     DepthSize=1024
     NearShare=0.700000
     NearLess=20.000000
     FloorSteps=6
     Cone=70
     Soft=1
     bThrowBack=False
     BounceGain=1.000000
     Thrift=2
     bAlwaysTick=True
     Throw=2600.000000
     MaxRange=1600.000000
     MinRange=320.000000
     Range=1600.000000
     Slack=3
     Edge=1.000000
     Spread=1.600000
     SheerGain=0.600000
     Gain=1.000000
     EdgeDark=0.250000
     FadeBy=3000.000000
     DimSoft=1.000000
     RingTaps(0)=4
     RingTaps(1)=4
     RingTaps(2)=6
     RingTaps(3)=6
     RingTurn(0)=0.500000
     RingTurn(1)=0.000000
     RingTurn(2)=0.250000
     RingTurn(3)=0.750000
     Bright=1.000000
     FarSpare=1.150000
     FarMore=120.000000
     FarLeast=400.000000
     FarHold=0.750000
     FarFrames=90
     PoolWide=0.520000
     SpillWide=1.100000
     MaterialBlendingOp=PB_None
     FrameBufferBlendingOp=PB_Add
     ProjTexture=Texture'KFTorchTex.KFTCookie'
     Cookie=Texture'KFTorchTex.KFTCookie'
     FOV=100
     MaxTraceDistance=2600
     bDynamicAttach=True
     bProjectActor=False
     bClipBSP=False
     bProjectOnUnlit=True
     bGradient=False
     bProjectOnAlpha=True
     bProjectOnParallelBSP=True
     bNoProjectOnOwner=True
     bStatic=False
     bHidden=False
     DrawType=DT_None
     bLightChanged=True
     RemoteRole=ROLE_None
     bGameRelevant=True
     LifeSpan=0.000000
}
