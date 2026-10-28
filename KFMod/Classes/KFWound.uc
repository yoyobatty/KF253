//=============================================================================
// A wound in a specimen (KFTrauma.NoteWound): a hole where a round went in, a ragged tear where a heavy one came out,
// a cavity a shotgun opened at close range, a blade's gash. A small projector cast onto that body alone, riding the
// bone it is on, laid on again whenever the bone has moved. Projectors are drawn unlit, so it is kept dark, never
// glowing: black in the middle, dark raw meat round it, a faint bruise, a run of blood down from a hole. Each machine that draws
// the body has its own; a wound goes with the part it is on.
//=============================================================================
class KFWound extends Projector;

#exec TEXTURE IMPORT NAME=KFWoundHole FILE=..\KFMod254\KFMod\Textures\KFWoundHole.tga ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP
#exec TEXTURE IMPORT NAME=KFWoundExit FILE=..\KFMod254\KFMod\Textures\KFWoundExit.tga ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP
#exec TEXTURE IMPORT NAME=KFWoundCavity FILE=..\KFMod254\KFMod\Textures\KFWoundCavity.tga ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP
#exec TEXTURE IMPORT NAME=KFWoundGash FILE=..\KFMod254\KFMod\Textures\KFWoundGash.tga ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP
#exec TEXTURE IMPORT NAME=KFWoundRim FILE=..\KFMod254\KFMod\Textures\KFWoundRim.tga ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP
#exec TEXTURE IMPORT NAME=KFWoundFade FILE=..\KFMod254\KFMod\Textures\KFWoundFade.tga MIPS=OFF ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP

var KFMonster Zed;
var name Bone;
var vector Spot, Dir, Up;			// against the bone's axes: where it is cast from, which way, its picture's top
var int Joint;						// the sever slot whose loss takes it with the part (-1: the trunk's)
var vector LastOrigin, LastX, LastY;	// the bone as it was when last laid on
var() int MaxLive;					// no new wounds while this many are about
var int Live;						// (default: how many there are)

static function KFWound Make( KFMonster M, name OnBone, int OnJoint, vector LSpot, vector LDir, vector LUp, byte Kind, float Size, float Depth )
{
	local KFWound W;

	if ( M == None || M.Level.NetMode == NM_DedicatedServer || class'GameInfo'.static.UseLowGore() || default.Live >= default.MaxLive
		|| !M.bAcceptsProjectors || M.bGibbed )
		return None;
	W = M.Spawn(class'KFWound', M,, M.Location);
	if ( W == None )
		return None;
	W.Zed = M;
	W.Bone = OnBone;
	W.Joint = OnJoint;
	W.Spot = LSpot;
	W.Dir = LDir;
	W.Up = LUp;
	switch ( Kind )
	{
		case 1:		W.ProjTexture = Texture'KFWoundExit';	break;
		case 2:		W.ProjTexture = Texture'KFWoundCavity';	break;
		case 3:		W.ProjTexture = Texture'KFWoundGash';	break;
		case 5:		W.ProjTexture = Texture'KFWoundRim';	break;
		case 5:		W.ProjTexture = Texture'KFWoundRim';	break;
		default:	W.ProjTexture = Texture'KFWoundHole';
	}
	W.SetDrawScale(Size / W.ProjTexture.MaterialUSize());
	W.MaxTraceDistance = Depth;
	W.Lay(true);
	return W;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	default.Live++;
}

simulated function Destroyed()
{
	default.Live--;
	DetachProjector(true);
	Super.Destroyed();
}

simulated function Tick( float DeltaTime )
{
	if ( Zed == None || Zed.bDeleteMe || Zed.bHidden || Zed.bGibbed || !Zed.bAcceptsProjectors
		|| (Joint >= 0 && Zed.Severed[Joint] != 0) )
	{
		Destroy();
		return;
	}
	if ( Level.TimeSeconds - Zed.LastRenderTime < 0.25 )
		Lay(false);
}

// Cast again from where the bone now puts it, if the bone has moved since
simulated function Lay( bool bForce )
{
	local coords C;
	local vector BX, BY, BZ, X, Y, Z;

	C = Zed.GetBoneCoords(Bone);
	BX = Normal(C.XAxis);
	BY = Normal(C.YAxis);
	if ( !bForce && VSize(C.Origin - LastOrigin) < 0.25 && (BX dot LastX) > 0.9998 && (BY dot LastY) > 0.9998 )
		return;
	LastOrigin = C.Origin;
	LastX = BX;
	LastY = BY;
	BZ = Normal(C.ZAxis);
	X = class'KFCutPiece'.static.OutOfBone(Dir, BX, BY, BZ);
	Z = class'KFCutPiece'.static.OutOfBone(Up, BX, BY, BZ);
	Z = Z - X * (Z dot X);
	if ( VSize(Z) < 0.05 )
		Z = BZ - X * (BZ dot X);
	Z = Normal(Z);
	Y = Z cross X;
	SetLocation(C.Origin + class'KFCutPiece'.static.OutOfBone(Spot, BX, BY, BZ));
	SetRotation(OrthoRotation(X, Y, Z));
	DetachProjector(true);
	AttachProjector();
	AttachActor(Zed);
}

defaultproperties
{
     MaxLive=180
     FrameBufferBlendingOp=PB_AlphaBlend
     MaterialBlendingOp=PB_None
     FOV=0
     MaxTraceDistance=24
     bProjectBSP=False
     bProjectTerrain=False
     bProjectStaticMesh=False
     bProjectParticles=False
     bProjectActor=False
     bProjectOnBackfaces=False
     bProjectOnUnlit=False
     bClipBSP=False
     bGradient=True
     GradientTexture=Texture'KFWoundFade'
     bStatic=False
     bNoDelete=False
     bHidden=True
     RemoteRole=ROLE_None
     bDirectional=False
}
