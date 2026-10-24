//=============================================================================
// A limb or head off a specimen, its own and not a clot's giblet: a copy of the specimen's mesh with all but
// the part shrunk away (KFLimbMesh), carried by this giblet from the part's middle. Each machine drawing the
// specimen makes its own (KFMonster.ThrowLimb).
//=============================================================================
class KFLimbGib extends KFGib;

var KFLimbMesh Piece;
var KFGib Cap;				// raw meat on the end it came off at
var vector LimbAxis;		// the way the part runs from its joint, against this giblet's own axes

// Takes the part of M that hangs from Joint, as it is now. Tip is the far end of it (None for the head, whose
// far end is worked out from M's head size); Below is a part further down it that came off before it.
simulated function bool TakeLimb( KFMonster M, name Joint, name Tip, name Below, float CapSize )
{
	local coords PJ, BJ;
	local vector PX, PY, PZ, BX, BY, BZ, X, Y, Z, T, R;
	local name Seq;
	local float Frame, Rate;
	local int i;

	Piece = Spawn(class'KFLimbMesh', self,, M.Location, M.Rotation);
	if ( Piece == None )
		return false;
	Piece.LinkMesh(M.Mesh);
	Piece.SetDrawScale(M.DrawScale);
	Piece.SetDrawScale3D(M.DrawScale3D);
	Piece.PrePivot = M.PrePivot;
	Piece.AmbientGlow = M.AmbientGlow;
	Piece.Skins.Length = M.Skins.Length;
	for ( i=0; i<M.Skins.Length; i++ )
	{
		// a skin on its way to burnt is a blend the body has from the level's pool: the part has the plain skin under it
		if ( i < ArrayCount(M.CharSkins) && M.CharSkins[i] != None && M.Skins[i] == M.CharSkins[i] )
			Piece.Skins[i] = M.CharSkins[i].Material2;
		else
			Piece.Skins[i] = M.Skins[i];
	}
	CharPiece(M);

	// (posed and shrunk before its bones are first asked for: they are worked out once a tick)
	M.GetAnimParams(0, Seq, Frame, Rate);
	if ( Seq != '' )
	{
		Piece.PlayAnim(Seq, 0.0, 0.0);
		Piece.SetAnimFrame(Frame);
	}
	// everything shrunk into the hips, and the part grown back to its size
	Piece.SetBoneScale(0, 0.01, 'Bip01 Pelvis');
	Piece.SetBoneScale(1, 100.0, Joint);
	if ( Below != 'None' )
		Piece.SetBoneScale(2, 0.0, Below);

	PJ = Piece.GetBoneCoords(Joint);
	if ( Tip != 'None' )
		T = Piece.GetBoneCoords(Tip).Origin;
	else
		T = PJ.Origin + 2.0 * M.HeadHeight * M.HeadScale * PJ.XAxis;

	// laid on the body's joint, and turned as the body's joint is turned (the body may be a ragdoll by now)
	BJ = M.GetBoneCoords(Joint);
	PX = Normal(PJ.XAxis);
	PY = Normal(PJ.YAxis);
	PZ = Normal(PJ.ZAxis);
	BX = Normal(BJ.XAxis);
	BY = Normal(BJ.YAxis);
	BZ = Normal(BJ.ZAxis);
	GetAxes(Piece.Rotation, X, Y, Z);
	Piece.SetRotation(OrthoRotation(TurnBy(X, PX, PY, PZ, BX, BY, BZ), TurnBy(Y, PX, PY, PZ, BX, BY, BZ), TurnBy(Z, PX, PY, PZ, BX, BY, BZ)));
	// (PrePivot is not turned with the mesh)
	R = BJ.Origin + TurnBy(Piece.Location + Piece.PrePivot - PJ.Origin, PX, PY, PZ, BX, BY, BZ);
	T = BJ.Origin + TurnBy(T - PJ.Origin, PX, PY, PZ, BX, BY, BZ);

	// carried from its middle, so it turns over about that
	SetRotation(Piece.Rotation);
	SetLocation(0.5 * (BJ.Origin + T));
	LimbAxis = Normal(T - BJ.Origin) << Rotation;
	// (the mesh's own middle, the body's hips, can come to lie under the floor, where nothing lights it)
	Piece.Offset = (R - Location) << Rotation;
	Piece.SetLocation(Location);
	Piece.PrePivot = R - Location;
	Piece.SetBase(self);

	if ( M.HeadStubClass != None )
	{
		// facing back the way the part came off
		Cap = Spawn(M.HeadStubClass, self,, BJ.Origin, OrthoRotation(-BX, -BY, BZ));
		if ( Cap != None )
		{
			Cap.RemoteRole = ROLE_None;
			Cap.SetPhysics(PHYS_None);
			Cap.bCollideWorld = false;
			Cap.SetCollision(false, false, false);
			Cap.LifeSpan = 0;
			Cap.SetDrawScale(Cap.DrawScale * CapSize);
			Cap.bHardAttach = true;
			Cap.SetBase(self);
			Cap.CharTo(M.CharLevel * M.GibCharShare);
		}
	}
	return true;
}

// V turned as the axes PX, PY, PZ would have to be turned to lie on BX, BY, BZ
static function vector TurnBy( vector V, vector PX, vector PY, vector PZ, vector BX, vector BY, vector BZ )
{
	return BX * (V dot PX) + BY * (V dot PY) + BZ * (V dot PZ);
}

// V turned about the axis K by the angle with sine S and cosine C
static function vector TurnAbout( vector V, vector K, float S, float C )
{
	return V * C + (K cross V) * S + K * (K dot V) * (1.0 - C);
}

// A part off a body that was burning is as burnt as the body
simulated function CharPiece( KFMonster M )
{
	local Texture T;
	local int i;

	if ( M.CharLevel <= 0.0 || M.bCharDone || Level.NetMode == NM_DedicatedServer )
		return;
	CharMask = class'KFFXMat'.static.Tone(CharMade, Level, 255, 255);
	CharMask.Color.A = Clamp(int(255.0 * (1.0 - M.CharLevel)), 0, 255);
	for ( i=0; i<Piece.Skins.Length && i<ArrayCount(M.CharSkins); i++ )
	{
		T = M.PlainSkin(Piece.Skins[i]);
		if ( T != None )
			Piece.Skins[i] = class'KFFXMat'.static.Fade(CharMade, Level, Texture'PatchTex.Common.ZedBurnSkin', T, CharMask);
	}
}

simulated function HitWall( vector HitNormal, Actor Wall )
{
	Super.HitWall(HitNormal, Wall);
	if ( Physics == PHYS_None )
		LayFlat(HitNormal);
}

// At rest it lies along the floor, not stood up out of it or sunk into it
simulated function LayFlat( vector Floor )
{
	local vector W, F, K, X, Y, Z;
	local float S;

	W = LimbAxis >> Rotation;
	F = W - Floor * (W dot Floor);
	if ( VSize(F) < 0.05 )
		return;
	F = Normal(F);
	K = W cross F;
	S = VSize(K);
	if ( S < 0.01 )
		return;
	K = K / S;
	GetAxes(Rotation, X, Y, Z);
	SetRotation(OrthoRotation(TurnAbout(X, K, S, W dot F), TurnAbout(Y, K, S, W dot F), TurnAbout(Z, K, S, W dot F)));
}

simulated function Destroyed()
{
	if ( Piece != None )
		Piece.Destroy();
	if ( Cap != None )
		Cap.Destroy();
	Super.Destroyed();
}

defaultproperties
{
     GibGroupClass=Class'KFMod.KFHumanGibGroup'
     DampenFactor=0.250000
     DrawType=DT_None
     LifeSpan=20.000000
     TransientSoundVolume=25.000000
     CollisionRadius=6.000000
     CollisionHeight=4.000000
}
