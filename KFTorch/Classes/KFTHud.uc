//=============================================================================
// KFTHud - the tactical light's hook into the drawing of each frame, on the
// machine of whoever holds it.
//
// Before a frame is drawn: every lit light (KFTLight) is put where it is this
// frame and has its pictures taken, with its own projectors off the level,
// and the pictures made from those are made. A picture made by script is
// drawn when something is drawn with it, so each is drawn here on one pixel,
// in a way that changes nothing on the screen.
//
// After the frame is drawn, and the weapon in hand with it: each light notes
// where the weapon's light bone was, for the next frame.
//
// There is one for the game's whole run; it lets go of a level's lights when
// the level ends.
//=============================================================================
class KFTHud extends Interaction;

var array<KFTLight>	Lights;
var int				Turn;				// (whose turn it is to take pictures, when more than one light is lit)

static final function KFTHud Of(PlayerController PC, optional bool bMake)
{
	local int i;

	if (PC == None || PC.Player == None)
		return None;
	for (i = 0; i < PC.Player.LocalInteractions.Length; i++)
		if (KFTHud(PC.Player.LocalInteractions[i]) != None)
			return KFTHud(PC.Player.LocalInteractions[i]);
	if (!bMake || PC.Player.InteractionMaster == None)
		return None;
	return KFTHud(PC.Player.InteractionMaster.AddInteraction("KFTorch.KFTHud", PC.Player));
}

event NotifyLevelChange()
{
	Lights.Length = 0;
}

function Add(KFTLight L)
{
	local int i;

	for (i = 0; i < Lights.Length; i++)
		if (Lights[i] == L)
			return;
	Lights[Lights.Length] = L;
}

function Remove(KFTLight L)
{
	local int i;

	for (i = 0; i < Lights.Length; i++)
		if (Lights[i] == L)
		{
			Lights.Remove(i, 1);
			return;
		}
}

function PreRender(Canvas C)
{
	local int i, n;
	local KFTLight Taker;

	for (i = Lights.Length - 1; i >= 0; i--)
		if (Lights[i] == None || Lights[i].bDeleteMe)
			Lights.Remove(i, 1);
	// One light's pictures a frame. The torch and the muzzle light both taking theirs in the same frame left the sky
	// drawn as black fog for the rest of the map (inside the renderer: nothing a script can see changes). A light with
	// no pictures yet goes first; otherwise the lights take turns, and the others keep the pictures they have.
	Taker = None;
	for (i = 0; i < Lights.Length; i++)
		if (Lights[i].bDressed && Lights[i].bLit && !Lights[i].bHavePictures)
		{
			Taker = Lights[i];
			break;
		}
	if (Taker == None && Lights.Length > 0)
	{
		Turn++;
		for (n = 0; n < Lights.Length; n++)
		{
			Taker = Lights[(Turn + n) % Lights.Length];
			if (Taker.bDressed && Taker.bLit)
				break;
		}
	}
	n = 0;
	for (i = 0; i < Lights.Length; i++)
		Lights[i].bYield = (Lights[i] != Taker);
	for (i = 0; i < Lights.Length; i++)
	{
		Lights[i].Shun(true);
		if (Lights[i].Frame(C))
			n++;
	}
	if (n == 0)
		return;
	// have the lights' pictures drawn now, while their projectors are off the level
	C.DrawActor(None, false, false);
	for (i = 0; i < Lights.Length; i++)
		Lights[i].Prep(C);
}

function PostRender(Canvas C)
{
	local int i;

	for (i = 0; i < Lights.Length; i++)
		if (Lights[i] != None && !Lights[i].bDeleteMe)
		{
			Lights[i].Shun(false);
			Lights[i].Aimed();
			Lights[i].Show(C);
		}
}

defaultproperties
{
     bVisible=True
     bActive=False
}
