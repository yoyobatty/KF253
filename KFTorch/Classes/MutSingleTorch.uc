//=============================================================================
// MutSingleTorch - everybody's tactical light, on the 9mm and the dual 9mms,
// is the one worked out at every pixel (KFTBeam, KFTLight): each weapon with
// a torch is handed that light as the weapon is made. Every weapon is handed
// the muzzle flash's light too (KFTFlash), which its shots throw ahead on the
// shooter's machine. The weapons stay the mod's own, so the trader knows them
// as ever.
//
// In the console, on a game of one's own:
//   mutate torch              what the light is doing
//   mutate torch lean 0|1|2   how the light is weighed by the way a surface faces it (1)
//   mutate torch bounce 0|1   the light a lit surface throws back (1); or a number over 1: how much, in hundredths
//   mutate torch size N       the light's picture of what it falls on, pixels across: 512, 1024, 2048 (2048)
//   mutate torch thrift 0|1|2 the light's pictures taken every other frame: never, always, when frames are slow (2)
//   mutate torch soft N       how soft a shadow's edge is, in hundredths: 0 hard, 100 the usual, up to 400
// Each is kept in the mod's user ini, under [KFTorch.KFTLight].
//=============================================================================
class MutSingleTorch extends Mutator;

// Every weapon passes by here as it is made (on the server, where the light is made too)
function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if (KFWeapon(Other) != None && KFWeapon(Other).bTorchEnabled)
		KFWeapon(Other).FlashLightClass = class'KFTBeam';
	// (only shots with a muzzle flash ask for it: KFWeapon.ShotLight)
	if (KFWeapon(Other) != None)
		KFWeapon(Other).MuzzleLightClass = class'KFTFlash';
	return true;
}

function Mutate(string MutateString, PlayerController Sender)
{
	local array<string> Words;
	local KFTLight L;
	local string Verb, Said, Name;
	local int N, i;
	local bool bRemake, bRelook;

	Split(MutateString, " ", Words);
	if (Words.Length > 0 && Words[0] ~= "torch")
	{
		if (Words.Length > 1)
			Verb = Words[1];
		if (Words.Length > 2)
			N = int(Words[2]);
		if (Verb ~= "lean")
			class'KFTLight'.default.Soft = Clamp(N, 0, 2);
		else if (Verb ~= "bounce")
		{
			class'KFTLight'.default.bThrowBack = (N != 0);
			if (N > 1)
				class'KFTLight'.default.BounceGain = FClamp(float(N) / 100.0, 0.05, 4.0);
		}
		else if (Verb ~= "thrift")
			class'KFTLight'.default.Thrift = Clamp(N, 0, 2);
		else if (Verb ~= "soft")
			class'KFTLight'.default.Edge = FClamp(float(N) / 100.0, 0.0, 4.0);
		else if (Verb ~= "show")
		{
			// (a tool: the light's own pictures, along the top of the screen)
			foreach DynamicActors(class'KFTLight', L)
				L.bShow = !L.bShow;
			Verb = "";
		}
		else if (Verb ~= "size")
		{
			class'KFTLight'.default.PictureSize = Clamp(N, 256, 2048);
			bRemake = true;
		}
		else if (Verb ~= "cone")
		{
			class'KFTLight'.default.Cone = Clamp(N, 60, 100);
			bRemake = true;
		}
		else if (Verb ~= "depth")
		{
			class'KFTLight'.default.DepthSize = Clamp(N, 256, 2048);
			bRemake = true;
		}
		else if (Verb ~= "omit")
		{
			// A see-through model the light is to leave alone: by a part of its name; or, with no name, the one the
			// lit torch points at. "omit clear" empties the list.
			if (Words.Length > 2)
				Name = Words[2];
			else
				foreach DynamicActors(class'KFTLight', L)
					Name = L.OmitAhead();
			if (Name ~= "clear")
				class'KFTLight'.default.Omit.Length = 0;
			else if (Name != "")
			{
				for (i = 0; i < class'KFTLight'.default.Omit.Length; i++)
					if (class'KFTLight'.default.Omit[i] ~= Name)
						break;
				class'KFTLight'.default.Omit[i] = Name;
			}
			bRelook = true;
		}
		if (Verb != "")
			class'KFTLight'.static.StaticSaveConfig();
		foreach DynamicActors(class'KFTLight', L)
		{
			// (a muzzle flash's light keeps its own settings)
			if (KFTFlash(L) != None)
				continue;
			if (bRemake)
			{
				// (whoever keeps it makes another, of the new size)
				L.Destroy();
				continue;
			}
			L.Lean(class'KFTLight'.default.Soft);
			L.bThrowBack = class'KFTLight'.default.bThrowBack;
			L.BounceGain = class'KFTLight'.default.BounceGain;
			L.Thrift = class'KFTLight'.default.Thrift;
			L.Edge = class'KFTLight'.default.Edge;
			if (L.Bounce != None)
				L.Bounce.Gain = L.BounceGain;
			if (bRelook)
			{
				L.Omit = class'KFTLight'.default.Omit;
				L.Relook();
			}
			Said = L.Says();
		}
		if (bRelook)
		{
			if (Name == "")
				Said = "nothing see-through in the middle of the beam: light the torch and point it at the thing, or give a part of its name";
			else
			{
				Said = "the light leaves alone:";
				for (i = 0; i < class'KFTLight'.default.Omit.Length; i++)
					Said = Said @ class'KFTLight'.default.Omit[i];
				if (class'KFTLight'.default.Omit.Length == 0)
					Said = "the light leaves nothing alone that it would light by itself";
			}
		}
		if (Said == "")
			Said = "no light is lit; pictures" @ class'KFTLight'.default.PictureSize @ "lean" @ class'KFTLight'.default.Soft @ "bounce" @ class'KFTLight'.default.bThrowBack;
		Log("KFTorch:" @ Said);
		if (Sender != None)
			Sender.ClientMessage("Torch:" @ Said);
	}
	Super.Mutate(MutateString, Sender);
}

defaultproperties
{
     bAddToServerPackages=True
     GroupName="KFTorch"
     FriendlyName="9mm with a real light"
     Description="Everybody's 9mm and dual 9mms have a tactical light that is worked out at every pixel: a hot middle, a pool and a dim wide spill, shadows behind whatever stands in the beam, and the light a lit wall throws back."
}
