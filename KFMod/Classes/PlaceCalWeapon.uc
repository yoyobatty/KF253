//=============================================================================
// 50 Placeable Inventory class
//=============================================================================
class PlaceCalWeapon extends KFWeapon;

function float GetAIRating()
{
	local Bot B;


	B = Bot(Instigator.Controller);
	if ( (B == None) || (B.Enemy == None) )
		return AIRating;

	return (AIRating + 0.0003 * FClamp(1500 - VSize(B.Enemy.Location - Instigator.Location),0,1000));
}

function byte BestMode()
{
    return 0;
}

defaultproperties
{
     ClipCount=1
     ReloadAnimRate=1.000000
     FireModeClass(0)=Class'KFMod.PlaceCalFire'
     FireModeClass(1)=Class'KFMod.PlaceCalFire'
     PutDownAnim="PutDown"
     SelectSound=Sound'KFPlayerSound.getweaponout'
     AIRating=0.400000
     CurrentRating=0.400000
     bCanThrow=False
     OldCenteredOffsetY=0.000000
     OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
     OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
     OldPlayerViewPivot=(Pitch=400)
     OldCenteredRoll=3000
     Description=".50 calibre action express handgun. This is about as big and nasty as personal weapons are going to get. But with a 7 round magazine, it should be used conservatively.  "
     EffectOffset=(X=100.000000,Y=25.000000,Z=-10.000000)
     DisplayFOV=70.000000
     Priority=39
     SmallViewOffset=(X=15.000000,Y=-50.000000,Z=-10.000000)
     CenteredOffsetY=-5.000000
     CenteredRoll=3000
     CenteredYaw=-1500
     CustomCrosshair=-1
     CustomCrossHairColor=(B=0,G=0,R=0,A=0)
     CustomCrossHairTextureName=""
     GroupOffset=1
     PickupClass=Class'KFMod.PlaceCalPickup'
     PlayerViewOffset=(X=10.000000,Y=3.000000,Z=-5.000000)
     PlayerViewPivot=(Yaw=17884,Roll=2000)
     BobDamping=8.000000
     AttachmentClass=Class'KFMod.DeagleAttachment'
     IconCoords=(X1=250,Y1=110,X2=330,Y2=145)
     ItemName="Press [FIRE] to deploy "
     bUseDynamicLights=True
     Mesh=SkeletalMesh'KFWeaponModels.50CalWeapon'
     DrawScale=0.900000
     TransientSoundVolume=1.000000
}
