//=============================================================================
// KFTBullpupFire - the Bullpup's fire, which also lights the muzzle flash's
// light (KFTBullpup, KFTFlash) with each shot.
//=============================================================================
class KFTBullpupFire extends BullpupFire;

// (on the machine of whoever fires, as the flash is shown)
function FlashMuzzleFlash()
{
	Super.FlashMuzzleFlash();
	if (KFTBullpup(Weapon) != None)
		KFTBullpup(Weapon).MuzzleLight();
}

defaultproperties
{
}
