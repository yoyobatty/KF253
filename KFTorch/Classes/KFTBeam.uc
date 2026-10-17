//=============================================================================
// KFTBeam - what a weapon's tactical light is to the rest of the mod, with
// the light itself changed for KFTLight.
//
// The mod's light is an actor (Effect_TacLightProjector) that the weapon
// makes on the server and that every machine is sent. On each machine it puts
// a projector on the level, and a glow where the beam lands. The weapon, the
// pawn's battery and the weapon as others see it all speak to that actor, so
// this is still one. But on the machine of whoever holds the light it puts
// neither the projector nor the glow on the level: it keeps a KFTLight lit
// and tells it how the battery is.
//
// Everybody else's light is drawn the mod's own way on this machine: a
// KFTLight has the scene drawn three more times each frame, which is too much
// to pay once for every light in sight. So is the player's own, if they have
// turned "Shadowed Flashlight" off in the settings (KFScreenFX.bTorch).
//=============================================================================
class KFTBeam extends Effect_TacLightProjector;

var KFTLight	Lamp;				// the light itself, here, if it is this machine's player's
var bool		bGlowOut;			// (the mod's glow has been put out)
var bool		bDeviceRead, bDeviceFits;	// (whether this machine draws with Direct3D 9 or 8, read once)

// The light draws alike on Direct3D 9 and on 3369's Direct3D 8 (tested 2026-10-16); the Direct3D 11 renderer crashes
// drawing it. Also asked by the muzzle flash's light (KFTBullpup). (A change of renderer needs a restart.)
static function bool DeviceFits(Actor A)
{
	local string Device;

	if (!default.bDeviceRead)
	{
		Device = Caps(A.ConsoleCommand("get ini:Engine.Engine.RenderDevice Class"));
		default.bDeviceFits = InStr(Device, "D3D9DRV") >= 0 || InStr(Device, "D3DDRV") >= 0;
		default.bDeviceRead = true;
	}
	return default.bDeviceFits;
}

simulated function bool Mine()
{
	local PlayerController PC;

	if (Level.NetMode == NM_DedicatedServer || LightPawn == None || !class'KFScreenFX'.default.bTorch || !DeviceFits(self))
		return false;
	PC = Level.GetLocalPlayerController();
	return PC != None && PC.Pawn == LightPawn;
}

simulated function Destroyed()
{
	if (Lamp != None)
		Lamp.Destroy();
	Lamp = None;
	Super.Destroyed();
}

simulated function Tick(float DeltaTime)
{
	local vector HL, HN;
	local float BeamLength, G, W;
	local int Battery;
	local rotator R;

	// anybody else's light, a server with nobody at it, and this player's own with the light turned off in the
	// settings: the mod's own way (and then the lamp's pictures are given back)
	if (!Mine())
	{
		if (Lamp != None && !class'KFScreenFX'.default.bTorch)
		{
			Lamp.Destroy();
			Lamp = None;
		}
		if (Lamp != None)
			Lamp.SetLit(false);
		if (bGlowOut && TacLightGlow != None)
		{
			TacLightGlow.LightType = TacLightGlow.default.LightType;
			bGlowOut = false;
		}
		Super.Tick(DeltaTime);
		return;
	}

	if (Level.NetMode != NM_Client && (LightPawn.Weapon == None || LightPawn.Weapon != ValidWeapon))
	{
		DetachProjector();
		Destroy();
		return;
	}

	// the mod's projector is not put on the level, and its glow gives no light (the weapon goes on setting the
	// glow's brightness and colour by the battery; it is left there to be set)
	DetachProjector();
	if (TacLightGlow != None)
	{
		TacLightGlow.bDynamicLight = false;
		TacLightGlow.LightType = LT_None;
		bGlowOut = true;
	}

	if (!bHasLight)
	{
		if (Lamp != None)
			Lamp.SetLit(false);
		if (AssignedAttach != None)
		{
			if (KFWeaponAttachment(AssignedAttach) != None)
				KFWeaponAttachment(AssignedAttach).TacBeamGone();
			AssignedAttach = None;
		}
		if (bIsAssigned)
			RemoveProjecting();
		return;
	}

	if (Lamp == None)
	{
		Lamp = Spawn(class'KFTLight');
		if (Lamp == None)
			return;
		Lamp.Holder = LightPawn;
	}
	Lamp.SetLit(true);

	// The battery, as the mod has it: under a fifth of a charge the bulb dims and goes toward amber, and in its
	// last moments it sputters
	G = 1.0;
	if (KFHumanPawn(LightPawn) != None)
	{
		Battery = KFHumanPawn(LightPawn).TorchBatteryLife;
		if (Battery <= 100)
		{
			W = 1.0 - float(Battery) / 100.0;
			G = FClamp(float(Battery) / 100.0, 0.0, 1.0);
			if (Battery <= 30)
				G *= 0.3 + 0.7 * FRand();
		}
	}
	Lamp.Glowing(G, W);

	// What the rest of the mod asks of a light: which way it points, for the other machines; how far it reaches,
	// for the shine on the weapon as others see it
	BeamLength = 1800.0;
	if (Lamp.Aim != vect(0,0,0))
	{
		R = rotator(Lamp.Aim);
		if (Level.NetMode != NM_Client)
		{
			LightRot[0] = R.Yaw / 256;
			LightRot[1] = R.Pitch / 256;
		}
		if (Trace(HL, HN, Lamp.Apex + Lamp.Aim * 1800.0, Lamp.Apex, false) == None)
			HL = Lamp.Apex + Lamp.Aim * 1800.0;
		WallHitLocation = HL;
		BeamLength = VSize(HL - Lamp.Apex);
	}
	SetLocation(LightPawn.Location);

	if (XPawn(LightPawn) != None && XPawn(LightPawn).WeaponAttachment != AssignedAttach)
	{
		if (KFWeaponAttachment(AssignedAttach) != None)
			KFWeaponAttachment(AssignedAttach).TacBeamGone();
		AssignedAttach = XPawn(LightPawn).WeaponAttachment;
	}
	if (KFWeaponAttachment(AssignedAttach) != None)
		KFWeaponAttachment(AssignedAttach).UpdateTacBeam(BeamLength);
	if (!bIsAssigned && AssignedPC != None)
		AddProjecting();
}

defaultproperties
{
     bAlwaysTick=True
}
