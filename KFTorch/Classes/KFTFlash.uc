//=============================================================================
// KFTFlash - the light of a muzzle flash, worked out as the tactical light
// (KFTLight) is: from the muzzle, a wide warm flash for a few hundredths of a
// second after each shot, with shadows behind whatever stands in it. Its
// pattern (KFTFlashCookie) is turned at random for each shot and its strength
// varies a little, so that a burst flickers as a real one does.
//
// Made by the weapon in hand (KFTBullpup) on the machine of whoever fires it,
// for that player alone: everybody else sees the mod's own flash.
//=============================================================================
class KFTFlash extends KFTLight;

#exec TEXTURE IMPORT NAME=KFTFlashCookie FILE=..\KFMod254\KFTorch\Textures\KFTFlashCookie.tga MIPS=Off UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP

var() float			FlashTime;		// how long a shot's light lasts, seconds (it falls to nothing over that)
var() float			FlashWarm;		// how far toward amber it is
var() float			PeakLeast;		// the least a shot's light is, as a share of the most
var() float			MuzzleMost;		// how far from the eye the light may be put (or it would look through the wall leant on)
var float			ShotAt, Peak;
var TexRotator		Turn;			// the pattern, turned for this shot
var ScriptedTexture	TurnedPic;		// ...drawn so: what the light's materials take as its pattern
var FinalBlend		TurnedOver, TurnedSeen;

// (the pattern the light is made with is a picture of the turned one, made before the light is dressed)
simulated event PreBeginPlay()
{
	Super.PreBeginPlay();
	if (Level.NetMode == NM_DedicatedServer)
		return;
	Turn = TexRotator(Level.ObjectPool.AllocateObject(class'TexRotator'));
	Turn.Material = Texture'KFTorch.KFTFlashCookie';
	Turn.TexRotationType = TR_FixedRotation;
	Turn.UOffset = 128.0;
	Turn.VOffset = 128.0;
	TurnedPic = ScriptedTexture(Level.ObjectPool.AllocateObject(class'ScriptedTexture'));
	TurnedPic.SetSize(256, 256);
	TurnedPic.Client = self;
	TurnedPic.UClampMode = TC_Clamp;
	TurnedPic.VClampMode = TC_Clamp;
	TurnedOver = FinalBlend(Level.ObjectPool.AllocateObject(class'FinalBlend'));
	TurnedOver.Material = Turn;
	TurnedOver.FrameBufferBlending = FB_Overwrite;
	TurnedOver.ZWrite = false;
	TurnedOver.ZTest = false;
	TurnedSeen = FinalBlend(Level.ObjectPool.AllocateObject(class'FinalBlend'));
	TurnedSeen.Material = TurnedPic;
	TurnedSeen.FrameBufferBlending = FB_Invisible;
	TurnedSeen.ZWrite = false;
	TurnedSeen.ZTest = false;
	Cookie = TurnedPic;
}

simulated event Destroyed()
{
	Super.Destroyed();
	if (TurnedPic != None)
	{
		TurnedPic.Client = None;
		TurnedPic.UClampMode = TC_Wrap;
		TurnedPic.VClampMode = TC_Wrap;
		Level.ObjectPool.FreeObject(TurnedPic);
		TurnedPic = None;
	}
	if (TurnedOver != None)
	{
		TurnedOver.Material = None;
		TurnedOver.FrameBufferBlending = FB_Overwrite;
		TurnedOver.ZWrite = true;
		TurnedOver.ZTest = true;
		Level.ObjectPool.FreeObject(TurnedOver);
		TurnedOver = None;
	}
	if (TurnedSeen != None)
	{
		TurnedSeen.Material = None;
		TurnedSeen.FrameBufferBlending = FB_Overwrite;
		TurnedSeen.ZWrite = true;
		TurnedSeen.ZTest = true;
		Level.ObjectPool.FreeObject(TurnedSeen);
		TurnedSeen = None;
	}
	if (Turn != None)
	{
		Turn.Material = None;
		Level.ObjectPool.FreeObject(Turn);
		Turn = None;
	}
}

// A shot: the light comes up at once, turned and as strong as it happens to be this time
simulated function Shot()
{
	ShotAt = Level.TimeSeconds;
	Peak = PeakLeast + (1.0 - PeakLeast) * FRand();
	if (Turn != None)
		Turn.Rotation.Yaw = Rand(65536);
}

simulated function Tick(float DT)
{
	local float T;

	Super.Tick(DT);
	if (bDeleteMe)
		return;
	T = Level.TimeSeconds - ShotAt;
	if (ShotAt > 0.0 && T >= 0.0 && T < FlashTime)
	{
		Glowing(Peak * (1.0 - T / FlashTime), FlashWarm);
		SetLit(true);
	}
	else
		SetLit(false);
}

// Where the muzzle was from the eye, as the eye saw it, when the weapon was last drawn; the light goes the way the
// eye looks (a flash lights all that is ahead)
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
	B = W.GetBoneCoords(W.FlashBoneName);
	if (B.XAxis == vect(0,0,0))
		return;
	PC.PlayerCalcView(Cam, Eye, Rot);
	// (as the light on the weapon is found: the weapon in hand is drawn at a fifth of its size about its own place)
	At = W.Location + (B.Origin - W.Location) * 0.2;
	Rel = (At - Eye) << Rot;
	if (VSize(Rel) > MuzzleMost)
		Rel = Normal(Rel) * MuzzleMost;
	RelAim = vect(1,0,0);
	bRel = true;
}

// Before the frame, after the light's pictures are taken: the turned pattern first, which the rest is made with
simulated function Prep(Canvas C)
{
	if (bDressed && bLit && TurnedPic != None)
		Make(C, TurnedPic, TurnedSeen);
	Super.Prep(C);
}

simulated event RenderTexture(ScriptedTexture Tex)
{
	if (Tex == TurnedPic && TurnedPic != None)
	{
		Tex.DrawTile(0, 0, 256, 256, 0, 0, 256, 256, TurnedOver, class'Canvas'.static.MakeColor(255, 255, 255, 255));
		return;
	}
	Super.RenderTexture(Tex);
}

defaultproperties
{
     FlashTime=0.050000
     FlashWarm=0.800000
     PeakLeast=0.750000
     MuzzleMost=14.000000
     Gain=4.000000
     Cookie=Texture'KFTorch.KFTFlashCookie'
     Cone=120
     Thrift=0
     PictureSize=1024
     DepthSize=1024
     Reach=8.000000
     Throw=1600.000000
     MaxRange=1200.000000
     bThrowBack=False
}
