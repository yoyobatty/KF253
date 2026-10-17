//=============================================================================
// KFTBullpup - the Bullpup, whose muzzle flash lights what is ahead of it as
// the tactical light does (KFTFlash): a demonstration. "mutate torch bullpup"
// hands one to whoever asks. It is the mod's Bullpup in every other way; the
// trader knows it only as what it is dropped as.
//
// The weapon in hand gives no light of its own: the mod lights it (a small
// point light, on for 0.15 s) with each shot seen in first person, and here
// the flash's own light does that. Its look from outside (the weapon in the
// holder's hand, lit as ever) is for everybody else.
//=============================================================================
class KFTBullpup extends Bullpup;

var KFTFlash	Flash;		// the flash's light, on the machine of whoever fires this

// A shot (from the fire mode, on the machine of whoever fires): the light, for a player looking through their own
// eyes here (not a bot, not anybody else's weapon)
simulated function MuzzleLight()
{
	local PlayerController PC;

	if (Level.NetMode == NM_DedicatedServer || Instigator == None)
		return;
	PC = PlayerController(Instigator.Controller);
	if (PC == None || Viewport(PC.Player) == None || !class'KFTBeam'.static.DeviceFits(self))
		return;
	if (Flash == None || Flash.bDeleteMe)
	{
		Flash = Spawn(class'KFTFlash');
		if (Flash == None)
			return;
		Flash.Holder = Instigator;
	}
	Flash.Shot();
}

simulated event Destroyed()
{
	if (Flash != None)
		Flash.Destroy();
	Flash = None;
	Super.Destroyed();
}

defaultproperties
{
     FireModeClass(0)=Class'KFTorch.KFTBullpupFire'
     ItemName="Bullpup (flash light)"
     LightType=LT_None
}
