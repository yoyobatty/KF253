//=============================================================================
// KFFXMat - the materials KFScreenFX is made of, from the level's pool, each
// noted in a list so that all can be given back at once.
//=============================================================================
class KFFXMat extends Object;

// A plain grey, as solid as A says (both of 255). It has to be the first thing in a row of materials.
static function ConstantColor Tone(out array<Object> Made, LevelInfo L, int V, int A)
{
	local ConstantColor K;

	K = ConstantColor(L.ObjectPool.AllocateObject(class'ConstantColor'));
	K.Color.R = Clamp(V, 0, 255);
	K.Color.G = K.Color.R;
	K.Color.B = K.Color.R;
	K.Color.A = Clamp(A, 0, 255);
	Made[Made.Length] = K;
	return K;
}

// Two things put together. What: 0 one times the other, 1 the second less the first, 2 the second as it is,
// 3 one plus the other. For 1 and 2 the result is as solid as the first.
static function Combiner Mix(out array<Object> Made, LevelInfo L, Material A, Material B, int What)
{
	local Combiner M;

	M = Combiner(L.ObjectPool.AllocateObject(class'Combiner'));
	M.Material1 = A;
	M.Material2 = B;
	M.Mask = None;
	M.InvertMask = false;
	M.Modulate2X = false;
	M.Modulate4X = false;
	M.CombineOperation = CO_Multiply;
	M.AlphaOperation = AO_Use_Mask;
	if (What == 1)
	{
		M.CombineOperation = CO_Subtract;
		M.AlphaOperation = AO_Use_Alpha_From_Material1;
	}
	else if (What == 2)
	{
		M.CombineOperation = CO_Use_Color_From_Material2;
		M.AlphaOperation = AO_Use_Alpha_From_Material1;
	}
	else if (What == 3)
		M.CombineOperation = CO_Add;
	Made[Made.Length] = M;
	return M;
}

// Two pictures, B showing over A by how solid Mask is (the A of a Tone). Both must be plain pictures.
static function Combiner Fade(out array<Object> Made, LevelInfo L, Material A, Material B, Material Mask)
{
	local Combiner M;

	M = Combiner(L.ObjectPool.AllocateObject(class'Combiner'));
	M.Material1 = A;
	M.Material2 = B;
	M.Mask = Mask;
	M.InvertMask = false;
	M.Modulate2X = false;
	M.Modulate4X = false;
	M.CombineOperation = CO_AlphaBlend_With_Mask;
	M.AlphaOperation = AO_Use_Mask;
	Made[Made.Length] = M;
	return M;
}

// A thing times four, as often as asked (as solid as white is)
static function Material Gained(out array<Object> Made, LevelInfo L, Material M, int Times)
{
	local Combiner C;
	local int i;

	for (i = 0; i < Times; i++)
	{
		C = Mix(Made, L, M, Texture'Engine.WhiteTexture', 0);
		C.Modulate4X = true;
		C.AlphaOperation = AO_Use_Alpha_From_Material2;
		M = C;
	}
	return M;
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

// ...by so much of its width across and of its height down. (In a flat drawing a texture's coordinates are two
// numbers from the drawing itself; what moves them is the third row of a matrix.)
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

// A material as it is drawn. How: 0 over what is there by how solid it is, 1 added to what is there by how solid
// it is, 2 not at all (a picture drawn so is only made ready), 3 what is there times it and doubled, 4 in place
// of what is there, 5 what is there less that share of itself.
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
		B.FrameBufferBlending = FB_Overwrite;
	else if (How == 5)
		B.FrameBufferBlending = FB_Darken;
	else
		B.FrameBufferBlending = FB_AlphaBlend;
	B.ZWrite = false;
	B.ZTest = false;
	B.AlphaTest = false;
	B.TwoSided = true;
	Made[Made.Length] = B;
	return B;
}

// A picture to draw into, which asks Client for its drawing (RenderTexture)
static function ScriptedTexture Sheet(out array<Object> Made, LevelInfo L, Actor Client, int Width, int Height)
{
	local ScriptedTexture T;

	T = ScriptedTexture(L.ObjectPool.AllocateObject(class'ScriptedTexture'));
	T.SetSize(Width, Height);
	T.Client = Client;
	T.UClampMode = TC_Clamp;
	T.VClampMode = TC_Clamp;
	Made[Made.Length] = T;
	return T;
}

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
			Combiner(Made[i]).Mask = None;
			Combiner(Made[i]).CombineOperation = CO_Multiply;
			Combiner(Made[i]).AlphaOperation = AO_Use_Mask;
			Combiner(Made[i]).Modulate2X = false;
			Combiner(Made[i]).Modulate4X = false;
		}
		else if (TexMatrix(Made[i]) != None)
		{
			TexMatrix(Made[i]).Material = None;
			TexMatrix(Made[i]).TexCoordProjected = false;
			TexMatrix(Made[i]).TexCoordSource = TCS_NoChange;
			TexMatrix(Made[i]).Matrix = Unit;
		}
		else if (FinalBlend(Made[i]) != None)
		{
			FinalBlend(Made[i]).Material = None;
			FinalBlend(Made[i]).FrameBufferBlending = FB_Overwrite;
			FinalBlend(Made[i]).ZTest = true;
			FinalBlend(Made[i]).ZWrite = true;
			FinalBlend(Made[i]).TwoSided = false;
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
