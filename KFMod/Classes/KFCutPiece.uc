//=============================================================================
// A part of a specimen cut through (KFTrauma): its own mesh as KFLimbGib carries it, but what lies across the cut is
// see-through (a mask laid on by world position, alpha tested: KFTrauma.CutSkin), a copy a little smaller wearing raw
// meat fills it from inside (Shell), and the cut's face lies on the plane (Face). The plane is kept in this giblet's
// own axes and laid on again each tick as it flies. A half of a split head first hangs open on the neck it came off
// (HingeOn), then drops.
//=============================================================================
class KFCutPiece extends KFLimbGib;

var vector CutSpot, CutNormal, CutAlong;	// the cut, against this giblet's axes
var float CutWidth;
var TexMatrix CutCoords;					// world position to the cut's mask
var array<Object> Made;						// pooled materials, given back when it goes
var KFLimbMesh Shell;						// the meat inside
var KFCutCap Face, Face2;					// the cut's face (a cleaved half has two: the trunk's and the head's)
var bool bNoShell;							// a whole body: a copy shrunk about one point would stick out of thin parts
var vector RingSpot, RingA, RingB;			// (Ring) the oval the cut reaches within, against this giblet's axes
var float RingRA, RingRB;
var TexMatrix RingCoords;
var array<name> ScaledBones;				// the bones shrunk or grown on the piece, done again on the shell
var array<float> ScaledBy;

// hung on a body's bone: its place and axes against the bone's, the hinge it turns open on
var KFMonster Hung;
var name HungBone;
var vector HungSpot, HungX, HungY, HungZ, HingeSpot, HingeAxis;
var float HingeAngle, HingeAge, HingeDrop;

simulated function bool TakeLimb( KFMonster M, name Joint, name Tip, name Below, float CapSize )
{
	if ( !Super.TakeLimb(M, Joint, Tip, Below, CapSize) )
		return false;
	ScaledBones[0] = 'Bip01 Pelvis';
	ScaledBy[0] = 0.01;
	ScaledBones[1] = Joint;
	ScaledBy[1] = 100.0;
	if ( Below != 'None' )
	{
		ScaledBones[2] = Below;
		ScaledBy[2] = 0.0;
	}
	// (a cap of zero size: none wanted)
	if ( CapSize <= 0.0 && Cap != None )
	{
		Cap.Destroy();
		Cap = None;
	}
	return true;
}

// The whole of M as it is now, less its legs (but with them, bLegs) and what it had lost already: laid over M, turned so
// that its Anchor bone lies on M's, and carried from there. Cut it afterwards.
simulated function bool TakeUpper( KFMonster M, name Anchor, optional bool bLegs )
{
	local coords PJ, BJ;
	local vector PX, PY, PZ, BX, BY, BZ, X, Y, Z, R;
	local name Seq;
	local float Frame, Rate;
	local int i;

	Piece = Spawn(class'KFLimbMesh', self,, M.Location, M.Rotation);
	if ( Piece == None )
		return false;
	bNoShell = true;
	Piece.LinkMesh(M.Mesh);
	Piece.SetDrawScale(M.DrawScale);
	Piece.SetDrawScale3D(M.DrawScale3D);
	Piece.PrePivot = M.PrePivot;
	Piece.AmbientGlow = M.AmbientGlow;
	Piece.Skins.Length = M.Skins.Length;
	for ( i=0; i<M.Skins.Length; i++ )
	{
		if ( i < ArrayCount(M.CharSkins) && M.CharSkins[i] != None && M.Skins[i] == M.CharSkins[i] )
			Piece.Skins[i] = M.CharSkins[i].Material2;
		else
			Piece.Skins[i] = M.LimbSkin(i);
	}
	M.GetAnimParams(0, Seq, Frame, Rate);
	if ( Seq != '' )
	{
		Piece.PlayAnim(Seq, 0.0, 0.0);
		Piece.SetAnimFrame(Frame);
	}
	// (parts thrown about, not things to stand on or be pushed by)
	SetCollision(false, false, false);
	if ( !bLegs )
	{
		ScaleBone('Bip01 L Thigh', 0.0);
		ScaleBone('Bip01 R Thigh', 0.0);
	}
	else
	{
		if ( M.Severed[0] != 0 )
			ScaleBone('Bip01 L Thigh', 0.0);
		if ( M.Severed[1] != 0 )
			ScaleBone('Bip01 R Thigh', 0.0);
		if ( M.Severed[6] != 0 )
			ScaleBone('Bip01 L Calf', 0.0);
		if ( M.Severed[7] != 0 )
			ScaleBone('Bip01 R Calf', 0.0);
	}
	if ( M.Severed[4] != 0 )
		ScaleBone(M.HeadBone, 0.0);
	if ( M.Severed[2] != 0 )
		ScaleBone('Bip01 R Forearm', 0.0);
	if ( M.Severed[3] != 0 )
		ScaleBone('Bip01 L Forearm', 0.0);
	if ( M.Severed[8] != 0 )
		ScaleBone('Bip01 L UpperArm', 0.0);
	if ( M.Severed[9] != 0 )
		ScaleBone('Bip01 R UpperArm', 0.0);

	PJ = Piece.GetBoneCoords(Anchor);
	BJ = M.GetBoneCoords(Anchor);
	PX = Normal(PJ.XAxis);
	PY = Normal(PJ.YAxis);
	PZ = Normal(PJ.ZAxis);
	BX = Normal(BJ.XAxis);
	BY = Normal(BJ.YAxis);
	BZ = Normal(BJ.ZAxis);
	GetAxes(Piece.Rotation, X, Y, Z);
	Piece.SetRotation(OrthoRotation(TurnBy(X, PX, PY, PZ, BX, BY, BZ), TurnBy(Y, PX, PY, PZ, BX, BY, BZ), TurnBy(Z, PX, PY, PZ, BX, BY, BZ)));
	R = BJ.Origin + TurnBy(Piece.Location + Piece.PrePivot - PJ.Origin, PX, PY, PZ, BX, BY, BZ);
	SetRotation(Piece.Rotation);
	SetLocation(BJ.Origin);
	LimbAxis = Normal(M.GetBoneCoords('Bip01 Neck').Origin - M.GetBoneCoords('Bip01 Spine1').Origin) << Rotation;
	Piece.Offset = (R - Location) << Rotation;
	Piece.SetLocation(Location);
	Piece.PrePivot = R - Location;
	Piece.SetBase(self);
	return true;
}

simulated function ScaleBone( name Bone, float By )
{
	Piece.SetBoneScale(ScaledBones.Length, By, Bone);
	ScaledBy[ScaledBones.Length] = By;
	ScaledBones[ScaledBones.Length] = Bone;
}

// A second mask: the cut reaches only within the oval round the line through Spot along Axis (world), half widths RA
// along A and RB along the other way across; what lies outside it is kept whichever side of the plane it is on
simulated function Ring( vector Spot, vector A, vector B, float RA, float RB )
{
	local Material Either;
	local int i;

	RingSpot = (Spot - Location) << Rotation;
	RingA = A << Rotation;
	RingB = B << Rotation;
	RingRA = RA;
	RingRB = RB;
	RingCoords = class'KFTrauma'.static.CutCoords(Made, Level, Texture'KFCutRing');
	LayCut();
	Either = class'KFTrauma'.static.EitherMask(Made, Level, CutCoords, RingCoords);
	for ( i=0; i<Piece.Skins.Length; i++ )
		if ( FinalBlend(Piece.Skins[i]) != None && Combiner(FinalBlend(Piece.Skins[i]).Material) != None )
			Combiner(FinalBlend(Piece.Skins[i]).Material).Material2 = Either;
	if ( Shell != None )
		for ( i=0; i<Shell.Skins.Length; i++ )
			if ( FinalBlend(Shell.Skins[i]) != None && Combiner(FinalBlend(Shell.Skins[i]).Material) != None )
				Combiner(FinalBlend(Shell.Skins[i]).Material).Material2 = Either;
}

// Cut through by the plane through Spot (world) square to Normal: what lies on Normal's side goes, what is on the other
// side stays; the face, Pic, an oval FaceY by FaceZ with its top toward FaceUp, lies on the plane facing Normal's way
simulated function Cut( vector Spot, vector Normal, vector Along, float Width, Material Pic, float FaceY, float FaceZ, vector FaceUp )
{
	local Texture T;
	local int i;

	if ( Piece == None )
		return;
	CutSpot = (Spot - Location) << Rotation;
	CutNormal = Normal << Rotation;
	CutAlong = Along << Rotation;
	CutWidth = Width;
	CutCoords = class'KFTrauma'.static.CutCoords(Made, Level, Texture'KFCutEdge');
	LayCut();
	for ( i=0; i<Piece.Skins.Length; i++ )
	{
		T = class'KFTrauma'.static.CutSource(Piece.Skins[i]);
		if ( T == None )
			T = Texture'KFCutMeat';
		Piece.Skins[i] = class'KFTrauma'.static.CutSkin(Made, Level, T, CutCoords);
	}
	if ( !bNoShell )
		MakeShell();
	if ( Pic != None && FaceY > 0.0 )
		Face = MakeFace(Pic, FaceY, FaceZ, FaceUp, Location + (CutSpot >> Rotation));
}

// The meat inside: the same pose a little smaller about this giblet's middle, cut the same
simulated function MakeShell()
{
	local name Seq;
	local float Frame, Rate, S;
	local FinalBlend Meat;
	local int i;

	S = class'KFTrauma'.default.ShellShrink;
	Shell = Spawn(class'KFLimbMesh', self,, Location, Piece.Rotation);
	if ( Shell == None )
		return;
	Shell.LinkMesh(Piece.Mesh);
	Shell.SetDrawScale(Piece.DrawScale * S);
	Shell.SetDrawScale3D(Piece.DrawScale3D);
	Shell.AmbientGlow = Piece.AmbientGlow;
	Piece.GetAnimParams(0, Seq, Frame, Rate);
	if ( Seq != '' )
	{
		Shell.PlayAnim(Seq, 0.0, 0.0);
		Shell.SetAnimFrame(Frame);
	}
	for ( i=0; i<ScaledBones.Length; i++ )
		Shell.SetBoneScale(i, ScaledBy[i], ScaledBones[i]);
	Meat = class'KFTrauma'.static.CutSkin(Made, Level, Texture'KFCutMeat', CutCoords);
	Shell.Skins.Length = Piece.Skins.Length;
	for ( i=0; i<Shell.Skins.Length; i++ )
		Shell.Skins[i] = Meat;
	Shell.Offset = Piece.Offset * S;
	Shell.PrePivot = Shell.Offset >> Rotation;
	Shell.SetBase(self);
}

// A cut face, Pic, an oval FaceY by FaceZ round At (world, on the cut) with its top toward FaceUp
simulated function KFCutCap MakeFace( Material Pic, float FaceY, float FaceZ, vector FaceUp, vector At )
{
	local vector X, Y, Z, D;
	local KFCutCap F;

	X = CutNormal >> Rotation;
	Z = FaceUp - X * (FaceUp dot X);
	if ( VSize(Z) < 0.1 )
		Z = (CutAlong >> Rotation) cross X;
	Z = Normal(Z);
	Y = Z cross X;
	F = Spawn(class'KFCutCap', self,, At - X * (((At - Location) dot X) - (CutSpot dot CutNormal)), OrthoRotation(X, Y, Z));
	if ( F == None )
		return None;
	D.X = 1.0;
	D.Y = FaceY;
	D.Z = FaceZ;
	F.SetDrawScale3D(D);
	F.Skins[0] = class'KFTrauma'.static.FaceSkin(Made, Level, Pic);
	F.SetBase(self);
	return F;
}

// The cut laid on where this giblet is now
simulated function LayCut()
{
	if ( CutCoords != None )
		class'KFTrauma'.static.SetPlane(CutCoords, Location + (CutSpot >> Rotation), CutNormal >> Rotation, CutAlong >> Rotation, CutWidth, 30.0);
	if ( RingCoords != None )
		class'KFTrauma'.static.SetRing(RingCoords, Location + (RingSpot >> Rotation), RingA >> Rotation, RingB >> Rotation, RingRA, RingRB);
}

// Hung on M's bone Bone as it is now, to turn open about the line through Pivot along Axis (world) by Angle degrees,
// and drop off after Seconds
simulated function HingeOn( KFMonster M, name Bone, vector Pivot, vector Axis, float Angle, float Seconds )
{
	local coords C;
	local vector BX, BY, BZ, X, Y, Z;

	C = M.GetBoneCoords(Bone);
	BX = Normal(C.XAxis);
	BY = Normal(C.YAxis);
	BZ = Normal(C.ZAxis);
	GetAxes(Rotation, X, Y, Z);
	HungSpot = InBone(Location - C.Origin, BX, BY, BZ);
	HungX = InBone(X, BX, BY, BZ);
	HungY = InBone(Y, BX, BY, BZ);
	HungZ = InBone(Z, BX, BY, BZ);
	HingeSpot = InBone(Pivot - C.Origin, BX, BY, BZ);
	HingeAxis = InBone(Normal(Axis), BX, BY, BZ);
	HingeAngle = Angle * Pi / 180.0;
	HingeAge = 0.0;
	HingeDrop = Seconds;
	Hung = M;
	HungBone = Bone;
	SetPhysics(PHYS_None);
	bCollideWorld = false;
}

static function vector InBone( vector V, vector BX, vector BY, vector BZ )
{
	local vector R;

	R.X = V dot BX;
	R.Y = V dot BY;
	R.Z = V dot BZ;
	return R;
}

static function vector OutOfBone( vector V, vector BX, vector BY, vector BZ )
{
	return BX * V.X + BY * V.Y + BZ * V.Z;
}

simulated function Tick( float DeltaTime )
{
	if ( Hung != None )
		HangOn(DeltaTime);
	LayCut();
}

simulated function HangOn( float DeltaTime )
{
	local coords C;
	local vector BX, BY, BZ, K, P, X, Y, Z, L;
	local float T, A, S, Co;

	if ( Hung == None || Hung.bDeleteMe || Hung.bHidden )
	{
		Drop();
		return;
	}
	HingeAge += DeltaTime;
	C = Hung.GetBoneCoords(HungBone);
	BX = Normal(C.XAxis);
	BY = Normal(C.YAxis);
	BZ = Normal(C.ZAxis);
	// opening quickly, with a little swing back
	T = FMin(HingeAge / 0.16, 1.0);
	A = HingeAngle * (1.0 - Square(1.0 - T)) * (1.0 + 0.12 * Sin(FMin(HingeAge, 0.6) * 18.0) * (1.0 - FMin(HingeAge / 0.6, 1.0)));
	S = Sin(A);
	Co = Cos(A);
	K = OutOfBone(HingeAxis, BX, BY, BZ);
	P = C.Origin + OutOfBone(HingeSpot, BX, BY, BZ);
	L = C.Origin + OutOfBone(HungSpot, BX, BY, BZ);
	X = TurnAbout(OutOfBone(HungX, BX, BY, BZ), K, S, Co);
	Y = TurnAbout(OutOfBone(HungY, BX, BY, BZ), K, S, Co);
	Z = TurnAbout(OutOfBone(HungZ, BX, BY, BZ), K, S, Co);
	SetLocation(P + TurnAbout(L - P, K, S, Co));
	SetRotation(OrthoRotation(X, Y, Z));
	if ( HingeAge >= HingeDrop )
		Drop();
}

// Off the body, falling
simulated function Drop()
{
	local vector V;

	if ( Hung != None && !Hung.bDeleteMe )
		V = Hung.Velocity;
	Hung = None;
	bCollideWorld = true;
	SetPhysics(PHYS_Falling);
	bBounce = true;
	Velocity = V + VRand() * 40.0 + vect(0,0,60);
	RandSpin(60000);
}

simulated function Destroyed()
{
	if ( Shell != None )
		Shell.Destroy();
	if ( Face != None )
		Face.Destroy();
	if ( Face2 != None )
		Face2.Destroy();
	Shell = None;
	Face = None;
	Face2 = None;
	CutCoords = None;
	RingCoords = None;
	if ( Piece != None )
		Piece.Skins.Length = 0;
	Super.Destroyed();
	if ( Made.Length > 0 )
		class'KFFXMat'.static.FreeAll(Made, Level);
}

defaultproperties
{
     LifeSpan=24.000000
}
