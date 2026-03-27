//=============================================================================
// Axe Inventory class
//=============================================================================
class Axe extends KFMeleeGun;

defaultproperties
{
     MeleeHitSounds(0)=Sound'KFPawnDamageSound.MeleeDamageSounds.axehitflesh'
     ChopSlowRate=0.200000
     BloodyMaterial=Shader'KillingFloorWeapons.Axe.AxeShaderBloody'
     BloodSkinSwitchArray=0
     bSpeedMeUp=True
     Weight=5.000000
     FireModeClass(0)=Class'KFMod.AxeFire'
     FireModeClass(1)=Class'KFMod.NoFire'
     SelectAnimRate=1.000000
     BringUpTime=0.800000
     SelectSound=Sound'PatchSounds.pickupm2-3'
     AIRating=0.510000
     CurrentRating=0.510000
     Description="A common two-handed fireman's axe."
     DisplayFOV=90.000000
     Priority=4
     SmallViewOffset=(X=10.000000,Y=3.000000,Z=-18.000000)
     GroupOffset=3
     PickupClass=Class'KFMod.AxePickup'
     BobDamping=4.000000
     AttachmentClass=Class'KFMod.AxeAttachment'
     IconCoords=(X1=169,Y1=39,X2=241,Y2=77)
     ItemName="Axe"
     Mesh=SkeletalMesh'KFWeaponModels.Axe'
     Skins(0)=Shader'KillingFloorWeapons.Axe.AxeShineShader'
     Skins(1)=Texture'KillingFloorWeapons.Deagle.HandSkinNew'
     Skins(2)=Texture'KillingFloorWeapons.Deagle.ArmSkinNew'
}
