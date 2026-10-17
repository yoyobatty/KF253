//=============================================================================
// KFTMat - the handful of materials the tactical light (KFTLight) is made of,
// from the level's pool, each noted in a list so that all can be given back
// at once. Nothing here is drawn: these are the parts.
//=============================================================================
class KFTMat extends Object;

static function ConstantColor Hue(out array<Object> Made, LevelInfo L, int R, int G, int B)
{
	local ConstantColor K;

	K = ConstantColor(L.ObjectPool.AllocateObject(class'ConstantColor'));
	K.Color.R = Clamp(R, 0, 255);
	K.Color.G = Clamp(G, 0, 255);
	K.Color.B = Clamp(B, 0, 255);
	K.Color.A = 255;
	Made[Made.Length] = K;
	return K;
}

static function ConstantColor Grey(out array<Object> Made, LevelInfo L, int V)
{
	return Hue(Made, L, V, V, V);
}

// Two things put together. What: 0 one times the other, 1 the second less the first, 2 one plus the other.
// Gain (when it is times): 2 or 4 for that many times over. A plain colour has to be the first thing in the whole
// row of them, and there may be one.
static function Combiner Mix(out array<Object> Made, LevelInfo L, Material A, Material B, int What, optional int Gain)
{
	local Combiner M;

	M = Combiner(L.ObjectPool.AllocateObject(class'Combiner'));
	M.Material1 = A;
	M.Material2 = B;
	M.Mask = None;
	M.InvertMask = false;
	M.Modulate2X = (Gain == 2);
	M.Modulate4X = (Gain == 4);
	if (What == 1)
		M.CombineOperation = CO_Subtract;
	else if (What == 2)
		M.CombineOperation = CO_Add;
	else
		M.CombineOperation = CO_Multiply;
	M.AlphaOperation = AO_Use_Mask;
	Made[Made.Length] = M;
	return M;
}

// A thing times four, as often as asked
static function Material Gained(out array<Object> Made, LevelInfo L, Material M, int Times)
{
	local int i;

	for (i = 0; i < Times; i++)
		M = Mix(Made, L, M, Texture'Engine.WhiteTexture', 0, 4);
	return M;
}

// A thing as it is drawn. How: 0 over what is there, 1 added to it, 2 not at all (it is only made ready), 3 what is
// there times it and doubled, 4 what is there less this share of it, 5 added to it but never past white (what is
// there loses this share of itself first).
// (Added, 1, goes by how solid the thing drawn is: behind a plain colour it is solid, a picture made here may not
// be. The others take no notice of that.)
static function FinalBlend Paint(out array<Object> Made, LevelInfo L, Material M, int How)
{
	local FinalBlend B;

	B = FinalBlend(L.ObjectPool.AllocateObject(class'FinalBlend'));
	B.Material = M;
	if (How == 1)
		B.FrameBufferBlending = FB_Brighten;
	else if (How == 2)
		B.FrameBufferBlending = FB_Invisible;
	else if (How == 3)
		B.FrameBufferBlending = FB_Modulate;
	else if (How == 4)
		B.FrameBufferBlending = FB_Darken;
	else if (How == 5)
		B.FrameBufferBlending = FB_Translucent;
	else
		B.FrameBufferBlending = FB_Overwrite;
	B.ZWrite = false;
	B.ZTest = false;
	B.AlphaTest = false;
	B.TwoSided = true;
	Made[Made.Length] = B;
	return B;
}

// A picture drawn over what is there, as solid as Alpha (of 255) says: what is there becomes that share the picture
// and the rest itself. Drawn one after another at a half, a third, a quarter, pictures come out averaged exactly.
static function FinalBlend Ghost(out array<Object> Made, LevelInfo L, Material Pic, int Alpha)
{
	local ConstantColor K;
	local Combiner M;
	local FinalBlend B;

	K = Hue(Made, L, 255, 255, 255);
	K.Color.A = Clamp(Alpha, 0, 255);
	M = Mix(Made, L, K, Pic, 0);
	M.CombineOperation = CO_Use_Color_From_Material2;
	M.AlphaOperation = AO_Use_Alpha_From_Material1;
	B = Paint(Made, L, M, 0);
	B.FrameBufferBlending = FB_AlphaBlend;
	return B;
}

// A picture to draw into, which asks Client for its drawing (RenderTexture)
static function ScriptedTexture Sheet(out array<Object> Made, LevelInfo L, Actor Client, int Size)
{
	local ScriptedTexture T;

	T = ScriptedTexture(L.ObjectPool.AllocateObject(class'ScriptedTexture'));
	T.SetSize(Size, Size);
	T.Client = Client;
	Made[Made.Length] = T;
	return T;
}

// A ramp laid by how far along a projector's cone a point is, over Far. A projector hands its material three numbers
// for each point: how far across the cone it is and how far down, each times its distance along the cone from the
// cone's tip, and that distance; the renderer divides the first two by the third. Here the first is made the
// distance over Far and the third is made one, so that nothing is divided. The cone's tip has to be where the light
// is (the light sizes its projector so). Less moves the ramp's start nearer the light by that share of Far.
// (This is here and not in the light: in a projector's own code "Matrix" is the projector's, not the kind of thing.)
static function Ramp(TexMatrix T, float Far, float Less)
{
	local Matrix M;

	M.ZPlane.X = 1.0 / Far;
	M.WPlane.X = Less;
	M.WPlane.Y = 0.5;
	M.WPlane.Z = 1.0;
	M.WPlane.W = 1.0;
	T.Matrix = M;
}

// The ramp again, for pictures whose fog begins Near from the light and ends Far from it, and whose first steps of
// distance (Floor, a share of all of them) stand for "nearer than where the fog begins".
static function RampFrom(TexMatrix T, float Near, float Far, float Floor, float Less)
{
	local Matrix M;

	M.ZPlane.X = (1.0 - Floor) / (Far - Near);
	M.WPlane.X = Less + Floor - (1.0 - Floor) * Near / (Far - Near);
	M.WPlane.Y = 0.5;
	M.WPlane.Z = 1.0;
	M.WPlane.W = 1.0;
	T.Matrix = M;
}

// The light's fall with distance (KFTFall's rows, top to bottom) laid along a projector's cone as the renderer would
// lay it over a cone Far long, from a projector that stands Near in front of its cone's tip: the first row behind
// the projector, the last past the cone's end, the sixty-two between spread evenly from the one to the other.
static function Fall(TexMatrix T, float Far, float Near)
{
	local Matrix M;

	M.ZPlane.Y = 62.0 / (64.0 * Far);
	M.WPlane.X = 0.5;
	M.WPlane.Y = (0.969 - 62.0 * Near / Far) / 64.0;
	M.WPlane.Z = 1.0;
	M.WPlane.W = 1.0;
	T.Matrix = M;
}

// A picture that can be moved across a flat drawing it is part of, apart from the rest of the drawing
static function TexMatrix Shift(out array<Object> Made, LevelInfo L, Material M)
{
	local TexMatrix T;

	T = TexMatrix(L.ObjectPool.AllocateObject(class'TexMatrix'));
	T.Material = M;
	T.TexCoordSource = TCS_Stream0;
	T.TexCoordCount = TCN_2DCoords;
	T.TexCoordProjected = false;
	Made[Made.Length] = T;
	Moved(T, 0.0, 0.0);
	return T;
}

// ...by so much of its width across and down. (In a flat drawing a texture's coordinates are two numbers from the
// drawing itself; what moves them is the third row of a matrix.)
static function Moved(TexMatrix T, float DU, float DV)
{
	local Matrix M;

	M.XPlane.X = 1.0;
	M.YPlane.Y = 1.0;
	M.ZPlane.X = DU;
	M.ZPlane.Y = DV;
	M.ZPlane.Z = 1.0;
	M.WPlane.W = 1.0;
	T.Matrix = M;
}

// All of them given back, as they were found
static function FreeAll(out array<Object> Made, LevelInfo L)
{
	local Matrix Unit;
	local int i;

	Unit.XPlane.X = 1.0;
	Unit.YPlane.Y = 1.0;
	Unit.ZPlane.Z = 1.0;
	Unit.WPlane.W = 1.0;
	for (i = 0; i < Made.Length; i++)
	{
		if (Made[i] == None)
			continue;
		if (Combiner(Made[i]) != None)
		{
			Combiner(Made[i]).Material1 = None;
			Combiner(Made[i]).Material2 = None;
			Combiner(Made[i]).Modulate2X = false;
			Combiner(Made[i]).Modulate4X = false;
			Combiner(Made[i]).CombineOperation = CO_Multiply;
			Combiner(Made[i]).AlphaOperation = AO_Use_Mask;
		}
		else if (FinalBlend(Made[i]) != None)
		{
			FinalBlend(Made[i]).Material = None;
			FinalBlend(Made[i]).FrameBufferBlending = FB_Overwrite;
			FinalBlend(Made[i]).ZTest = true;
			FinalBlend(Made[i]).ZWrite = true;
			FinalBlend(Made[i]).TwoSided = false;
		}
		else if (TexMatrix(Made[i]) != None)
		{
			TexMatrix(Made[i]).Material = None;
			TexMatrix(Made[i]).TexCoordProjected = false;
			TexMatrix(Made[i]).TexCoordSource = TCS_NoChange;
			TexMatrix(Made[i]).Matrix = Unit;
		}
		else if (ScriptedTexture(Made[i]) != None)
		{
			ScriptedTexture(Made[i]).Client = None;
			ScriptedTexture(Made[i]).UClampMode = TC_Wrap;
			ScriptedTexture(Made[i]).VClampMode = TC_Wrap;
		}
		L.ObjectPool.FreeObject(Made[i]);
	}
	Made.Length = 0;
}
