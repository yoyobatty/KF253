//=============================================================================
// Tac 9mm SP only  (Dual Possible)
//=============================================================================
class Single extends KFWeapon;

var bool bDualMode;
var bool bWasDualMode;
var bool bFireLeft;
var float DualPickupTime;

function bool HandlePickupQuery( pickup Item )
{
	if ( Item.InventoryType == Class )
	{
		if( KFHumanPawn(Owner)!=None && !KFHumanPawn(Owner).CanCarry(Class'Dualies'.Default.Weight) )
		{
			Pawn(Owner).ClientMessage("You are carrying too much.", 'CriticalEvent');
			Return True;
		}
		return false; // Allow to "pickup" so this weapon can be replaced with dualies.
	}
	Return Super.HandlePickupQuery(Item);
}

function byte BestMode()
{
	return 0;
}

function bool RecommendRangedAttack()
{
	return true;
}

simulated function bool PutDown()
{
	if (  Instigator.PendingWeapon != none && Instigator.PendingWeapon.class == class'Dualies' )
	{
		bIsReloading = false;
	}

	return super.PutDown();
}

defaultproperties
{
	MeshMats(1)=Texture'KillingFloorWeapons.Deagle.HandSkinNew'
	MeshMats(2)=Texture'KillingFloorWeapons.Deagle.ArmSkinNew'
	BrassClass=Class'KFMod.KFBrass'
	BrassBone=CasingBone
     Element=3
	FarKind(0)=FAR_Pistol
     ClipCount=15
     ReloadRate=2.000000
     ReloadAnim="Reload"
     ReloadAnimRate=1.000000
     WeaponReloadAnim="ReloadPistol"
     ModeSwitchAnim="LightOn"
     //FlashBoneName="Flash"
     HudImage=Texture'KFKillMeNow.SingleHUD'
     Weight=0.000000
     bKFNeverThrow=True
     bTorchEnabled=True
     UpKick=300
     FireModeClass(0)=Class'KFMod.SingleFire'
     FireModeClass(1)=Class'KFMod.SingleALTFire'
     PutDownAnim="PutDown"
     SelectSound=Sound'KFPlayerSound.getweaponout'
     AIRating=0.300000
     CurrentRating=0.300000
     bShowChargingBar=True
     Description="A 9mm Pistol"
     DisplayFOV=90.000000
     Priority=3
     SmallViewOffset=(X=13.000000,Y=18.000000,Z=-10.000000)
     InventoryGroup=2
     GroupOffset=1
     PickupClass=Class'KFMod.SinglePickup'
     PlayerViewOffset=(X=4.000000,Y=11.500000,Z=-6.000000)
     PlayerViewPivot=(Yaw=-500,Pitch=400)
     BobDamping=4.000000
     AttachmentClass=Class'KFMod.SingleAttachment'
     IconCoords=(X1=434,Y1=253,X2=506,Y2=292)
     ItemName="9mm Tactical"
     Mesh=SkeletalMesh'KFWeaponModels.9MM'
     UpgradeName="Wasp"
     UpgradeMagScale=2.000000
     UpgradeBurst=3
     UpgradePenetrations=1
     UpgradeFireRateScale=0.800000
     SheenSlots(0)=0
     SheenMats(0)=Shader'KillingFloorWeapons.Dualies.DualiesShineShader'
     SheenSlots(1)=3
     SheenMats(1)=Shader'KillingFloorWeapons.Dualies.DualiesShineShader'
}
