//=============================================================================
// BoomStick Inventory class
//=============================================================================
class BoomStick extends KFWeaponShotgun;

#EXEC OBJ LOAD FILE=KillingFloorHUD.utx

simulated event WeaponTick(float dt)
{
	if(AmmoAmount(0) == 0)
		Clipleft = 0;
	if(Clipleft == 1)
		Clipleft = 2;
	super.Weapontick(dt);
}

defaultproperties
{
	ClipCount=1
	ReloadRate=0.010000
	ReloadAnim="Reload"
	ReloadAnimRate=0.900000
	UpKick=2500
	FireModeClass(0)=Class'KFMod.BoomStickFire'
	FireModeClass(1)=Class'KFMod.NoFire'
	PutDownAnim="PutDown"
	SelectSound=Sound'KFPlayerSound.getweaponout'
	AIRating=0.900000
	CurrentRating=0.900000
	OldCenteredOffsetY=0.000000
	OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
	OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
	OldPlayerViewPivot=(Pitch=400)
	OldCenteredRoll=3000
	Description="A double barreled shotgun used by big game hunters. It fires two slugs simultaneously and can bring down even the largest targets, quickly."
	DisplayFOV=55.000000
	Priority=30
	SmallViewOffset=(X=8.000000,Y=18.000000,Z=-4.000000)
	CenteredOffsetY=-5.000000
	CenteredRoll=3000
	CenteredYaw=-1500
	CustomCrosshair=-1
	CustomCrossHairColor=(B=0,G=0,R=0,A=0)
	CustomCrossHairTextureName=
	InventoryGroup=4
	GroupOffset=3
	PickupClass=Class'KFMod.BoomStickPickup'
	BobDamping=6.000000
	AttachmentClass=Class'KFMod.BoomStickAttachment'
	ItemName="Hunting Shotgun"
	bUseDynamicLights=True
	Mesh=SkeletalMesh'KFWeaponModels.BoomStick'
	TransientSoundVolume=1.000000
}
