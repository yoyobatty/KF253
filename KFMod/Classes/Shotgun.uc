//=============================================================================
// Shotgun Inventory class
//=============================================================================
class Shotgun extends KFWeaponShotgun;

function bool RecommendLongRangedAttack() //Makes them stay still when shooting
{
     return true;
}

defaultproperties
{
     ClipCount=8
     ReloadRate=0.750000
     ReloadAnim="Reload"
     ReloadAnimRate=1.450000
     Weight=8.000000
     UpKick=700
     FireModeClass(0)=Class'KFMod.ShotgunFire'
     FireModeClass(1)=Class'KFMod.NoFire'
     PutDownAnim="PutDown"
     SelectSound=Sound'KFPlayerSound.getweaponout'
     AIRating=0.600000
     CurrentRating=0.600000
     bShowChargingBar=True
     OldCenteredOffsetY=0.000000
     OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
     OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
     OldPlayerViewPivot=(Pitch=400)
     Description="A rugged tactical pump action shotgun common to police divisions the world over. It accepts a maximum of 8 shells and can fire in rapid succession. "
     DisplayFOV=75.000000
     Priority=15
     SmallViewOffset=(X=-35.000000,Y=20.000000,Z=-10.000000)
     InventoryGroup=3
     GroupOffset=3
     PickupClass=Class'KFMod.ShotgunPickup'
     PlayerViewOffset=(X=4.000000,Y=5.500000,Z=-6.000000)
     PlayerViewPivot=(Pitch=400)
     BobDamping=4.000000
     AttachmentClass=Class'KFMod.ShotgunAttachment'
     IconCoords=(X1=169,Y1=172,X2=245,Y2=208)
     ItemName="Shotgun"
     Mesh=SkeletalMesh'KFWeaponModels.Shotgun'
     TransientSoundVolume=1.000000
     WallPivotRot=(Pitch=0,Yaw=0,Roll=0)
	WallPivotOffset=(x=-50,y=0,z=-10)
}
