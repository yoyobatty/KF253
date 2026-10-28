//=============================================================================
// The part of a cut body left lying (KFTrauma.CutWaist): the body itself, its skins swapped for ones that do not draw
// what lies across the cut (within an oval round the spine, so that nothing outside the trunk is lost), and the cut's
// face laid on it. The cut rides one of its bones: each tick it is drawn the cut and face are laid on again where that
// bone is. Each machine that draws the body has its own. The swapped skins are this actor's, so it lasts as long as
// the body does.
//=============================================================================
class KFCutBody extends Actor;

var KFMonster Body;
var name Bone;
var vector CutSpot, CutNormal, CutAlong, RingA, RingB, FaceZ;	// against the bone's axes
var float CutWidth, RingRA, RingRB;
var TexMatrix CutCoords, RingCoords;
var KFCutCap Face;
var array<Object> Made;

// Cuts M along the plane through Spot (world) square to CutN (what is on CutN's side goes) within the oval round
// Spot, half widths RA along A and RB along B; the face, Pic FaceY by FaceZ with its top toward Up, faces CutN's way
simulated function Take( KFMonster M, name OnBone, vector Spot, vector CutN, vector Along, vector A, vector B, float RA, float RB, float Width, Material Pic, float FaceYSize, float FaceZSize, vector Up )
{
	local coords C;
	local vector BX, BY, BZ, D;
	local Material Either;
	local Texture T;
	local int i;

	Body = M;
	Bone = OnBone;
	C = M.GetBoneCoords(OnBone);
	BX = Normal(C.XAxis);
	BY = Normal(C.YAxis);
	BZ = Normal(C.ZAxis);
	CutSpot = class'KFCutPiece'.static.InBone(Spot - C.Origin, BX, BY, BZ);
	CutNormal = class'KFCutPiece'.static.InBone(CutN, BX, BY, BZ);
	CutAlong = class'KFCutPiece'.static.InBone(Along, BX, BY, BZ);
	RingA = class'KFCutPiece'.static.InBone(A, BX, BY, BZ);
	RingB = class'KFCutPiece'.static.InBone(B, BX, BY, BZ);
	FaceZ = class'KFCutPiece'.static.InBone(Up, BX, BY, BZ);
	CutWidth = Width;
	RingRA = RA;
	RingRB = RB;

	CutCoords = class'KFTrauma'.static.CutCoords(Made, Level, Texture'KFCutEdge');
	RingCoords = class'KFTrauma'.static.CutCoords(Made, Level, Texture'KFCutRing');
	Either = class'KFTrauma'.static.EitherMask(Made, Level, CutCoords, RingCoords);
	for ( i=0; i<M.Skins.Length; i++ )
	{
		T = class'KFTrauma'.static.CutSource(M.Skins[i]);
		if ( T == None )
			T = Texture'KFCutMeat';
		M.Skins[i] = class'KFTrauma'.static.CutSkin(Made, Level, T, Either);
	}
	M.bCutBody = true;

	if ( Pic != None && FaceYSize > 0.0 )
	{
		Face = Spawn(class'KFCutCap', self,, Spot);
		if ( Face != None )
		{
			D.X = 1.0;
			D.Y = FaceYSize;
			D.Z = FaceZSize;
			Face.SetDrawScale3D(D);
			Face.Skins[0] = class'KFTrauma'.static.FaceSkin(Made, Level, Pic);
			Face.bHardAttach = false;
		}
	}
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

// The cut and its face laid on where the bone is now
simulated function Lay()
{
	local coords C;
	local vector BX, BY, BZ, S, N, X, Y, Z;

	C = Body.GetBoneCoords(Bone);
	BX = Normal(C.XAxis);
	BY = Normal(C.YAxis);
	BZ = Normal(C.ZAxis);
	S = C.Origin + class'KFCutPiece'.static.OutOfBone(CutSpot, BX, BY, BZ);
	N = class'KFCutPiece'.static.OutOfBone(CutNormal, BX, BY, BZ);
	class'KFTrauma'.static.SetPlane(CutCoords, S, N, class'KFCutPiece'.static.OutOfBone(CutAlong, BX, BY, BZ), CutWidth, 30.0);
	class'KFTrauma'.static.SetRing(RingCoords, S, class'KFCutPiece'.static.OutOfBone(RingA, BX, BY, BZ), class'KFCutPiece'.static.OutOfBone(RingB, BX, BY, BZ), RingRA, RingRB);
	if ( Face != None )
	{
		X = N;
		Z = class'KFCutPiece'.static.OutOfBone(FaceZ, BX, BY, BZ);
		Z = Z - X * (Z dot X);
		if ( VSize(Z) < 0.1 )
			Z = BY - X * (BY dot X);
		Z = Normal(Z);
		Y = Z cross X;
		Face.SetLocation(S);
		Face.SetRotation(OrthoRotation(X, Y, Z));
	}
	SetLocation(S);
}

simulated function Destroyed()
{
	if ( Face != None )
		Face.Destroy();
	Face = None;
	CutCoords = None;
	RingCoords = None;
	if ( Made.Length > 0 )
		class'KFFXMat'.static.FreeAll(Made, Level);
	Super.Destroyed();
}

defaultproperties
{
     DrawType=DT_None
     bHidden=True
     RemoteRole=ROLE_None
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
}
