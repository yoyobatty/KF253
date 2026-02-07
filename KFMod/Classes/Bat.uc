//=============================================================================
// Bat Inventory class
//=============================================================================
class Bat extends KFMeleeGun;

defaultproperties
{
	weaponRange=80.000000
	MeleeHitSounds(0)=Sound'KFPawnDamageSound.MeleeDamageSounds.bathitflesh'
	MeleeHitSounds(1)=Sound'KFPawnDamageSound.MeleeDamageSounds.bathitflesh2'
	MeleeHitSounds(2)=Sound'KFPawnDamageSound.MeleeDamageSounds.bathitflesh3'
	ChopSlowRate=0.350000
	BloodyMaterial=Shader'KillingFloorWeapons.Bat.BatBloodyShader'
	bSpeedMeUp=True
	Weight=3.000000
	FireModeClass(0)=Class'KFMod.BatFire'
	FireModeClass(1)=Class'KFMod.NoFire'
	AIRating=0.400000
	CurrentRating=0.400000
	Description="This bit of broken pipe looks like it was pried from a gas-line."
	DisplayFOV=70.000000
	Priority=20
	SmallViewOffset=(X=13.000000,Y=18.000000,Z=-10.000000)
	GroupOffset=2
	PickupClass=Class'KFMod.BatPickup'
	PlayerViewOffset=(X=4.000000,Y=5.500000,Z=-6.000000)
	PlayerViewPivot=(Pitch=400)
	BobDamping=8.000000
	AttachmentClass=Class'KFMod.BatAttachment'
	IconCoords=(Y1=407,X2=118,Y2=442)
	ItemName="Broken Pipe"
	Mesh=SkeletalMesh'KFWeaponModels.Bat'
	Skins(0)=Texture'KillingFloorWeapons.Deagle.HandSkinNew'
	Skins(1)=Texture'KillingFloorWeapons.Deagle.ArmSkinNew'
	Skins(2)=Shader'KillingFloorWeapons.Bat.BatShineShader'
}
