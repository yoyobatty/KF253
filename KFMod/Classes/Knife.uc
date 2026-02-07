//=============================================================================
// Knife Inventory class
//=============================================================================
class Knife extends KFMeleeGun;

defaultproperties
{
<<<<<<< HEAD
	weaponRange=65.000000
	MeleeHitSounds(0)=Sound'KFWeaponSound.knife_hit2'
	MeleeHitSounds(1)=Sound'KFWeaponSound.knife_hit3'
	MeleeHitSounds(2)=Sound'KFWeaponSound.knife_hit4'
	BloodyMaterial=Shader'KillingFloorWeapons.Knife.KnifeShaderBloody'
	bSpeedMeUp=True
	HudImage=Texture'KFKillMeNow.KnifeHUD'
	Weight=0.000000
	bKFNeverThrow=True
	FireModeClass(0)=Class'KFMod.KnifeFire'
	FireModeClass(1)=Class'KFMod.KnifeFireB'
	SelectAnimRate=0.800000
	BringUpTime=0.660000
	SelectSound=Sound'KFWeaponSound.knife_deploy1'
	AIRating=0.200000
	CurrentRating=0.200000
	Description="Military Combat Knife"
	DisplayFOV=75.000000
	Priority=10
	SmallViewOffset=(X=13.000000,Y=18.000000,Z=-10.000000)
	GroupOffset=1
	PickupClass=Class'KFMod.KnifePickup'
	PlayerViewOffset=(X=4.000000,Y=5.500000,Z=-6.000000)
	PlayerViewPivot=(Pitch=400)
	BobDamping=8.000000
	AttachmentClass=Class'KFMod.KnifeAttachment'
	IconCoords=(X1=246,Y1=80,X2=332,Y2=106)
	ItemName="Knife"
	Mesh=SkeletalMesh'KFWeaponModels.Knife'
	Skins(0)=Texture'KillingFloorWeapons.Deagle.HandSkinNew'
	Skins(1)=Texture'KillingFloorWeapons.Deagle.ArmSkinNew'
	Skins(2)=Shader'KillingFloorWeapons.Knife.KnifeShineShader'
=======
     MeleeHitSounds(0)=Sound'KFWeaponSound.knife_hit2'
     MeleeHitSounds(1)=Sound'KFWeaponSound.knife_hit3'
     MeleeHitSounds(2)=Sound'KFWeaponSound.knife_hit4'
     BloodyMaterial=Shader'KillingFloorWeapons.Knife.KnifeShaderBloody'
     bSpeedMeUp=True
     HudImage=Texture'KFKillMeNow.KnifeHUD'
     Weight=0.000000
     bKFNeverThrow=True
     FireModeClass(0)=Class'KFMod.KnifeFire'
     FireModeClass(1)=Class'KFMod.KnifeFireB'
     SelectAnimRate=0.800000
     BringUpTime=0.660000
     SelectSound=Sound'KFWeaponSound.knife_deploy1'
     AIRating=0.200000
     CurrentRating=0.200000
     Description="Military Combat Knife"
     DisplayFOV=75.000000
     Priority=2
     SmallViewOffset=(X=13.000000,Y=18.000000,Z=-10.000000)
     GroupOffset=1
     PickupClass=Class'KFMod.KnifePickup'
     PlayerViewOffset=(X=4.000000,Y=5.500000,Z=-6.000000)
     PlayerViewPivot=(Pitch=400)
     BobDamping=4.000000
     AttachmentClass=Class'KFMod.KnifeAttachment'
     IconCoords=(X1=246,Y1=80,X2=332,Y2=106)
     ItemName="Knife"
     Mesh=SkeletalMesh'KFWeaponModels.Knife'
     Skins(0)=Texture'KillingFloorWeapons.Deagle.HandSkinNew'
     Skins(1)=Texture'KillingFloorWeapons.Deagle.ArmSkinNew'
     Skins(2)=Shader'KillingFloorWeapons.Knife.KnifeShineShader'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
