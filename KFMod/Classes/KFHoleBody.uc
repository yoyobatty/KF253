//=============================================================================
// Holes right through a body (KFTrauma.NoteWound, a big round's killing shot): along each round's line the body is not
// drawn within its radius (the round mask, KFCutRing, laid on along the line and alpha tested), so the scene behind
// shows through it; the wounds at either end (KFWound) are the hole's raw edges. Up to MaxHoles a body. Each hole
// rides the bone it went through and is laid on again each tick the body is drawn. Each machine that draws the body
// has its own; the swapped skins are this actor's, so it lasts as long as the body does.
//=============================================================================
class KFHoleBody extends Actor;

var() int MaxHoles;

struct HoleLine
{
	var name Bone;
	var vector Spot, Dir;		// against the bone's axes
	var float R;
	var TexMatrix Coords;
};

var KFMonster Body;
var array<HoleLine> Holes;
var array<Texture> Plain;		// the body's own pictures, under what the holes are laid over
var Material Mask;				// every hole's mask at once (solid where none of them is)
var array<Object> Made;
var bool bLogged;

// A hole through M along the line through Spot along Dir (against Bone's axes), R units round
static function Make( KFMonster M, name Bone, vector Spot, vector Dir, float R )
{
	if ( !class'KFTrauma'.static.Allowed(M) || M.bGibbed || M.bFrozen )
		return;
	if ( M.HoleBody == None )
	{
		// (a body already cut in two keeps its cut)
		if ( M.bCutBody )
			return;
		M.HoleBody = M.Spawn(class'KFHoleBody', M,, M.Location);
		if ( M.HoleBody == None )
			return;
		M.HoleBody.Take(M);
	}
	M.HoleBody.Add(Bone, Spot, Dir, R);
}

simulated function Take( KFMonster M )
{
	local int i;

	Body = M;
	M.bCutBody = true;
	Plain.Length = M.Skins.Length;
	for ( i=0; i<M.Skins.Length; i++ )
	{
		Plain[i] = class'KFTrauma'.static.CutSource(M.Skins[i]);
		if ( Plain[i] == None )
			Plain[i] = Texture'KFCutMeat';
	}
}

simulated function Add( name Bone, vector Spot, vector Dir, float R )
{
	local HoleLine H;
	local Combiner Both;
	local int i;

	if ( Holes.Length >= MaxHoles || Body == None )
		return;
	H.Bone = Bone;
	H.Spot = Spot;
	H.Dir = Normal(Dir);
	H.R = R;
	H.Coords = class'KFTrauma'.static.CutCoords(Made, Level, Texture'KFCutRing');
	Holes[Holes.Length] = H;
	if ( Mask == None )
		Mask = H.Coords;
	else
	{
		Both = Combiner(Level.ObjectPool.AllocateObject(class'Combiner'));
		Both.Material1 = Mask;
		Both.Material2 = H.Coords;
		Both.Mask = None;
		Both.InvertMask = false;
		Both.Modulate2X = false;
		Both.Modulate4X = false;
		Both.CombineOperation = CO_Use_Color_From_Material1;
		Both.AlphaOperation = AO_Multiply;
		Made[Made.Length] = Both;
		Mask = Both;
	}
	for ( i=0; i<Body.Skins.Length && i<Plain.Length; i++ )
		Body.Skins[i] = class'KFTrauma'.static.CutSkin(Made, Level, Plain[i], Mask);
	Lay();
}

simulated function Tick( float DeltaTime )
{
	if ( Body == None || Body.bDeleteMe || Body.bHidden )
	{
		Destroy();
		return;
	}
	if ( Level.TimeSeconds - Body.LastRenderTime < 1.0 )
		Lay();
}

simulated function Lay()
{
	local coords C;
	local vector BX, BY, BZ, S, D, A, B;
	local int i;

	for ( i=0; i<Holes.Length; i++ )
	{
		C = Body.GetBoneCoords(Holes[i].Bone);
		BX = Normal(C.XAxis);
		BY = Normal(C.YAxis);
		BZ = Normal(C.ZAxis);
		S = C.Origin + class'KFCutPiece'.static.OutOfBone(Holes[i].Spot, BX, BY, BZ);
		D = class'KFCutPiece'.static.OutOfBone(Holes[i].Dir, BX, BY, BZ);
		A = D cross vect(0,0,1);
		if ( VSize(A) < 0.1 )
			A = D cross vect(1,0,0);
		A = Normal(A);
		B = Normal(D cross A);
		class'KFTrauma'.static.SetRing(Holes[i].Coords, S, A, B, Holes[i].R, Holes[i].R);
		if ( class'KFTrauma'.default.bTraumaDebug && !bLogged )
			log("HOLE" @ i @ "bone" @ Holes[i].Bone @ "S" @ S @ "D" @ D @ "A" @ A @ "B" @ B @ "R" @ Holes[i].R @ "body" @ Body.Location @ "local dir" @ Holes[i].Dir);
	}
	bLogged = true;
}

simulated function Destroyed()
{
	if ( Body != None && Body.HoleBody == self )
		Body.HoleBody = None;
	if ( Made.Length > 0 )
		class'KFFXMat'.static.FreeAll(Made, Level);
	Super.Destroyed();
}

defaultproperties
{
     MaxHoles=3
     DrawType=DT_None
     bHidden=True
     RemoteRole=ROLE_None
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
}
