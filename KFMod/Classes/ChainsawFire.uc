// Chainsaw Fire //
class ChainsawFire extends KnifeFire;

function PlayFiring()
{
	if ( Weapon.Mesh != None )
	{
		if ( FireCount > 0 )
		{
			if ( Weapon.HasAnim(FireLoopAnim) )
				Weapon.PlayAnim(FireLoopAnim, FireLoopAnimRate, 0.0);
			else Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
		}
	}
	else Weapon.PlayAnim(FireAnim, FireAnimRate, TweenTime);
	Weapon.PlayOwnedSound(FireSound,SLOT_Interact,TransientSoundVolume,,TransientSoundRadius,Default.FireAnimRate/FireAnimRate,false);
	ClientPlayForceFeedback(FireForce);  // jdf
	FireCount++;
}

defaultproperties
{
     maxAdditionalDamage=50
     hitDamageClass=Class'KFMod.DamTypeChainsaw'
     TransientSoundVolume=100.000000
     FireSound=Sound'KFWeaponSound.SawLoop'
     FireRate=0.200000
}
