//=============================================================================
// KFFrameTap - the frame as a picture, for the screen effects (KFScreenFX).
//
// The engine's motion blur has the level drawn into a picture the size of the
// screen, then copies that to the screen; the weapon and the HUD are drawn
// after. With the blur at 255 it blurs nothing, and the picture is simply the
// frame: bloom and the hit blur are made from it.
//
// The engine ties that picture to the first MotionBlur that ever draws, for
// as long as the game runs. So this keeps one blur through every level, puts
// it on the view once at the start even if no effect is on, and nothing else
// in the mod may use a MotionBlur of its own.
//=============================================================================
class KFFrameTap extends Interaction;

var MotionBlur		Blur;
var BitmapMaterial	Frame;
var KFScreenFX		FX;				// this level's
var int				Seeks, SeekWait, SpawnWait;

static function KFFrameTap Of(PlayerController PC)
{
	local int i;

	if (PC == None || Viewport(PC.Player) == None || PC.Player.InteractionMaster == None)
		return None;
	// (the engine's blur does not work there)
	if (PC.PlatformIsMacOS() || PC.PlatformIsUnix())
		return None;
	for (i = 0; i < PC.Player.LocalInteractions.Length; i++)
		if (KFFrameTap(PC.Player.LocalInteractions[i]) != None)
			return KFFrameTap(PC.Player.LocalInteractions[i]);
	// (once a game run: the settings go into the user's ini, to be found there and changed by hand)
	class'KFScreenFX'.static.StaticSaveConfig();
	return KFFrameTap(PC.Player.InteractionMaster.AddInteraction("KFMod.KFFrameTap", PC.Player));
}

// This level's effects, for the player at this machine
static function KFScreenFX GetFX(PlayerController PC)
{
	local KFFrameTap T;

	T = Of(PC);
	if (T == None)
		return None;
	T.Attend(PC);
	return T.FX;
}

event NotifyLevelChange()
{
	FX = None;
	SpawnWait = 0;
}

function Attend(PlayerController PC)
{
	if (FX != None && !FX.bDeleteMe && FX.Level == PC.Level)
		return;
	FX = None;
	// only in a game: this lives on into the main menu's level after a round, and that is not to glow
	if (HUDKillingFloor(PC.myHUD) == None)
		return;
	if (SpawnWait > 0)
	{
		SpawnWait--;
		return;
	}
	FX = PC.Spawn(class'KFScreenFX', PC);
	SpawnWait = 60;
}

function PreRender(Canvas C)
{
	local PlayerController PC;

	PC = ViewportOwner.Actor;
	if (PC == None || PC.Level == None)
		return;
	Attend(PC);
	if (FX != None)
		FX.Prep(self, PC, C);
}

// The blur on this player's view, first of its effects: whatever else is laid over the screen comes after its copy
function Fit(PlayerController PC)
{
	if (Blur == None)
	{
		Blur = new(None) class'MotionBlur';
		Blur.BlurAlpha = 255;
	}
	Blur.Alpha = 1.0;
	Blur.FinalEffect = false;
	if (PC.CameraEffects.Length > 0 && PC.CameraEffects[0] == Blur)
		return;
	PC.RemoveCameraEffect(Blur);
	PC.CameraEffects.Insert(0, 1);
	PC.CameraEffects[0] = Blur;
}

function Unfit(PlayerController PC)
{
	if (Blur != None)
		PC.RemoveCameraEffect(Blur);
}

// Looks for the frame's picture until it is found. It has no name to ask for: it is the one picture of the engine's
// own kind that is the size of the screen, made the first time the blur draws.
function bool Find(Canvas C)
{
	local BitmapMaterial M;

	if (Frame != None)
		return true;
	if (Blur == None)
		return false;
	if (SeekWait > 0)
	{
		SeekWait--;
		return false;
	}
	Seeks++;
	if (Seeks < 30)
		SeekWait = 10;
	else
		SeekWait = 600;
	foreach AllObjects(class'BitmapMaterial', M)
		if (M.IsA('ProxyBitmapMaterial') && M.USize == C.SizeX && M.VSize == C.SizeY)
		{
			Frame = M;
			break;
		}
	return Frame != None;
}

defaultproperties
{
     bVisible=True
     bActive=False
}
