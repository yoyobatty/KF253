//=============================================================================
// KFMeleeImpactDirt
// A melee blow on earth or grass: the bullet impact's dirt thrown up, bigger (KFMeleeHitEffect sizes it), and a thud.
//=============================================================================
class KFMeleeImpactDirt extends KFImpactDirt;

defaultproperties
{
	ImpactSounds(0)=Sound'KFWeaponSound.MeleeHitGround'
	ImpactSounds(1)=Sound'KFWeaponSound.MeleeHitGround2'
	ImpactSounds(2)=Sound'KFWeaponSound.MeleeHitGround3'
}
