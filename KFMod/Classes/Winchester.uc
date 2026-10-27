//=============================================================================
// Winchester Inventory class
//=============================================================================
class Winchester extends KFWeaponShotgun;  

simulated function BringUp(optional Weapon PrevWeapon)
{
	if( WinchesterFire(FireMode[0])!=none ) 
		WinchesterFire(FireMode[0]).NormalSpeed();
	Super.BringUp(PrevWeapon);
}

simulated function PlayAnimZoom( bool bZoomNow )
{
	Super.PlayAnimZoom(bZoomNow);
	if( bZoomNow )
		UpKick = default.UpKick * 0.5;
	else UpKick = default.UpKick;
	if( WinchesterFire(FireMode[0])==none )
		return;
	if( bZoomNow )
		WinchesterFire(FireMode[0]).AimingSpeed();
	else WinchesterFire(FireMode[0]).NormalSpeed();
}

function ServerSetAiming(bool IsAiming)
{
	Super.ServerSetAiming(IsAiming);
	if( WinchesterFire(FireMode[0])==none )
		Return;
	if( IsAiming )
		WinchesterFire(FireMode[0]).AimingSpeed();
	else WinchesterFire(FireMode[0]).NormalSpeed();
}

function bool RecommendRangedAttack()
{
	return true;
}

defaultproperties
{
	MeshMats(0)=Texture'KillingFloorWeapons.Deagle.HandSkinNew'
	MeshMats(1)=Texture'KillingFloorWeapons.Deagle.ArmSkinNew'
	BrassClass=Class'KFMod.KFBrass'
	BrassBone=CasingBone
	BrassSize=1.500000
	BrassDelay=0.420000
     Element=5
	FarKind(0)=FAR_Rifle
     ClipCount=10
     ReloadRate=0.900000
     ReloadAnim="Reload"
     ReloadAnimRate=1.000000
     Weight=6.000000
	 UpKick=900.000000
     FireModeClass(0)=Class'KFMod.WinchesterFire'
     FireModeClass(1)=Class'KFMod.WinchesterAltFire'
     PutDownAnim="PutDown"
     BringUpTime=1.000000
     SelectSound=Sound'KFPlayerSound.getweaponout'
     AIRating=0.600000
     CurrentRating=0.600000
     bShowChargingBar=True
     OldCenteredOffsetY=0.000000
     OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
     OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
     OldPlayerViewPivot=(Pitch=800)
     OldCenteredRoll=3000
     Description="A rugged and reliable single-shot rifle.  "
     EffectOffset=(X=100.000000,Y=25.000000,Z=-10.000000)
     DisplayFOV=80.000000
     AimZoom=1.700000
     AimViewOffset=(X=8.000000,Y=19.970000,Z=-3.540000)
     Priority=9
     SmallViewOffset=(X=8.000000,Y=20.100000,Z=-4.000000)
     CenteredOffsetY=-5.000000
     CenteredRoll=3000
     CenteredYaw=-1500
     InventoryGroup=3
     GroupOffset=2
     PickupClass=Class'KFMod.WinchesterPickup'
     PlayerViewOffset=(X=15.000000,Y=20.100000,Z=-3.500000)
     BobDamping=4.000000
     AttachmentClass=Class'KFMod.WinchesterAttachment'
     ItemName="Winchester"
     bUseDynamicLights=True
     Mesh=SkeletalMesh'KFWeaponModels.Winchester'
     DrawScale=0.900000
     TransientSoundVolume=50.000000
     UpgradeName="Deadeye"
     UpgradeMagScale=2.000000
     UpgradePenetrations=95
     UpgradePenDamageScale=0.850000
     bUpgradeHeadShock=True
     SheenSlots(0)=2
     SheenMats(0)=Shader'KillingFloorWeapons.Winchester.LawShineShader'
     SheenSlots(1)=3
     SheenMats(1)=Shader'KillingFloorWeapons.Winchester.LawShineShader'
}
