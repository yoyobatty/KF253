//=============================================================================
// Deagle Inventory class
//=============================================================================
class Deagle extends KFWeapon;

function bool RecommendRangedAttack()
{
	return true;
}

function byte BestMode()
{
    return 0;
}

defaultproperties
{
     ClipCount=8
     ReloadRate=2.100000
     ReloadAnim="Reload"
     ReloadAnimRate=1.000000
     WeaponReloadAnim="ReloadPistol"
     Weight=4.000000
     UpKick=1500
     FireModeClass(0)=Class'KFMod.DeagleFire'
     FireModeClass(1)=Class'KFMod.NoFire'
     PutDownAnim="PutDown"
     SelectAnimRate=0.800000
     BringUpTime=0.730000
     SelectSound=Sound'KFPlayerSound.getweaponout'
     AIRating=0.550000
     CurrentRating=0.550000
     bShowChargingBar=True
     OldCenteredOffsetY=0.000000
     OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
     OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
     OldPlayerViewPivot=(Pitch=400)
     OldCenteredRoll=3000
     Description=".50 calibre action express handgun. This is about as big and nasty as personal weapons are going to get. But with a 7 round magazine, it should be used conservatively.  "
     EffectOffset=(X=100.000000,Y=25.000000,Z=-10.000000)
     DisplayFOV=85.000000
     Priority=5
     SmallViewOffset=(X=13.000000,Y=15.000000,Z=-8.000000)
     CenteredOffsetY=-5.000000
     CenteredYaw=-1500
     InventoryGroup=2
     GroupOffset=3
     PickupClass=Class'KFMod.DeaglePickup'
     PlayerViewOffset=(X=4.000000,Y=5.500000,Z=-6.000000)
     BobDamping=4.000000
     AttachmentClass=Class'KFMod.DeagleAttachment'
     IconCoords=(X1=250,Y1=110,X2=330,Y2=145)
     ItemName="Handcannon"
     bUseDynamicLights=True
     Mesh=SkeletalMesh'KFWeaponModels.Deagle'
     DrawScale=0.900000
     TransientSoundVolume=1.000000
}
