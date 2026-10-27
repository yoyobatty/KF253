//=============================================================================
// KFAxeSlashWarp
// The air bent along the flying cut (KFAxeSlash), the way a hot blade of air would bend the light through it: the view
// behind the cut is stretched across a band that follows the blade's curve, and shimmers. Drawn as the BFG's lens is
// (KFBFGLens): a disc facing the eye at the cut, sized to it, whose texture coordinates are where the light seen
// through it came from (Models/make_axeslash.py), laid on a picture of the scene without the cut's own glow in it.
//=============================================================================
class KFAxeSlashWarp extends KFBFGLens;

#exec NEW StaticMesh File="..\KFMod254\KFMod\Models\KFAxeSlashWarp.ase" Name="KFAxeSlashWarp"

var KFAxeSlash	Slash;
var vector		LastSpot, LastRight;
var float		HalfWidth;
var float		FadeAge;
var() float		FadeTime;
var() float		NearFade, NearFadeOver;		// it comes up from this far from the eye, over this much more

const WarpOut = 1.45;						// the disc's widest reach, in half the cut's widths

static function KFAxeSlashWarp MakeFor( KFAxeSlash S )
{
	local PlayerController P;
	local KFScreenFX F;
	local KFAxeSlashWarp W;

	if ( S == None || S.Level.NetMode == NM_DedicatedServer )
		return None;
	P = S.Level.GetLocalPlayerController();
	if ( P == None )
		return None;
	F = class'KFFrameTap'.static.GetFX(P);
	if ( F == None || !F.bShockWaves || F.Waves.Length >= F.MaxWaves )
		return None;
	W = F.Spawn(class'KFAxeSlashWarp',,, S.Location);
	if ( W == None )
		return None;
	W.FX = F;
	W.Slash = S;
	F.Waves[F.Waves.Length] = W;
	return W;
}

simulated function Tick( float DT )
{
	bHidden = true;
	Age += DT;
	if ( Slash == None || Slash.bDeleteMe || Slash.bDone )
	{
		FadeAge += DT;
		if ( FadeAge >= FadeTime )
			Destroy();
	}
}

simulated function bool FrameSetup( Canvas C, Actor CamActor, vector CamLocation, rotator CamRotation, float CamFOV )
{
	local vector A, Y, Z, S3;
	local float D, E, S, HalfTan, Pixels, Angle, HalfView, Fade;
	local rotator Rot;
	local int FOV;

	if ( Slash != None && !Slash.bDeleteMe && !Slash.bDone )
	{
		LastSpot = Slash.Location;
		LastRight = Slash.Across;
		HalfWidth = 0.5 * Slash.WidthNow();
	}
	if ( HalfWidth <= 0.0 )
		return false;
	A = LastSpot - CamLocation;
	D = VSize(A);
	if ( D < 30.0 )
		return false;
	A = A / D;
	Fade = FClamp((D - NearFade) / NearFadeOver, 0.0, 1.0) * FClamp(1.0 - FadeAge / FadeTime, 0.0, 1.0);
	if ( Fade < 0.02 || !FastTrace(LastSpot, CamLocation) )
		return false;

	// a unit of the disc is half the cut's width, as a slope from the eye
	E = HalfWidth / D;
	Ring = E;
	Angle = Acos(FClamp(A dot vector(CamRotation), -1.0, 1.0));
	HalfView = Atan(Tan(CamFOV * Pi / 360.0) * Sqrt(1.0 + Square(float(C.SizeY) / float(C.SizeX))), 1.0);
	if ( Angle - Atan(WarpOut * E, 1.0) > HalfView )
		return false;
	FOV = Clamp(int(Atan(1.1 * WarpOut * E, 1.0) * 360.0 / Pi) + 2, 4, 150);
	HalfTan = Tan(FOV * Pi / 360.0);
	Pixels = HalfTan * C.SizeX / Tan(CamFOV * Pi / 360.0);
	if ( Pixels < 24.0 )
		return false;

	// the disc square to the line to the cut, its across along the cut's own across
	Y = LastRight - A * (LastRight dot A);
	if ( VSize(Y) < 0.01 )
		return false;
	Y = Normal(Y);
	Z = A cross Y;
	Rot = OrthoRotation(A, Y, Z);
	S = Near * E / RingUnit;
	SetLocation(CamLocation + A * Near);
	SetRotation(Rot);
	SetDrawScale(S);
	S3.X = 2.0 * FMax(1.0, D + 8.0 - Near) / (FarX * S);
	S3.Y = 1.0;
	S3.Z = 1.0;
	SetDrawScale3D(S3);

	Tint.Color.A = byte(255.0 * Fade);
	TakeView(CamActor, CamLocation, Rot, FOV, Min(int(Pixels) + 1, TextureSize));
	Lay(A, Y, Z, E);
	return true;
}

// The view drawn again for the warp, without the cut's own glow and trails
simulated event RenderTexture( ScriptedTexture Tex )
{
	local int i;
	local bool bBlade;
	local byte Was[3];

	if ( ViewActor == None )
		return;
	if ( Slash != None && Slash.Blade != None )
	{
		bBlade = Slash.Blade.bHidden;
		Slash.Blade.bHidden = true;
	}
	if ( Slash != None )
		for ( i = 0; i < ArrayCount(Slash.Trails); i++ )
			if ( Slash.Trails[i] != None )
			{
				Was[i] = byte(Slash.Trails[i].bHidden);
				Slash.Trails[i].bHidden = true;
			}
	Tex.DrawPortal(0, 0, ViewSize, ViewSize, ViewActor, ViewLocation, ViewRotation, ViewFOV, true);
	if ( Slash != None && Slash.Blade != None )
		Slash.Blade.bHidden = bBlade;
	if ( Slash != None )
		for ( i = 0; i < ArrayCount(Slash.Trails); i++ )
			if ( Slash.Trails[i] != None )
				Slash.Trails[i].bHidden = (Was[i] != 0);
}

defaultproperties
{
	FadeTime=0.250000
	NearFade=60.000000
	NearFadeOver=140.000000
	StaticMesh=StaticMesh'KFAxeSlashWarp'
	LifeSpan=6.000000
}
