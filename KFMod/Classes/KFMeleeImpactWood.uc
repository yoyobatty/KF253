//=============================================================================
// KFMeleeImpactWood
// A melee blow on wood: the bullet impact's dust, bigger (KFMeleeHitEffect sizes it), and a woody thunk or chop.
//=============================================================================
class KFMeleeImpactWood extends KFImpactWood;

#exec OBJ LOAD FILE=PatchSounds.uax

defaultproperties
{
	ImpactSounds(0)=Sound'PatchSounds.WoodImpact1'
	ImpactSounds(1)=Sound'PatchSounds.WoodImpact2'
	ImpactSounds(2)=Sound'PatchSounds.WoodImpact3'
	ImpactSounds(3)=Sound'PatchSounds.WoodImpact4'
	ImpactSounds(4)=Sound'KFWeaponSound.WoodImpact'
}
