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
			Pawn(Owner).ClientMessage("You are carrying too much.", 'KFCriticalEvent');
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

defaultproperties
{
	ClipCount=15
	ReloadRate=2.000000
	ReloadAnim="Reload"
	ReloadAnimRate=1.000000
	WeaponReloadAnim="ReloadPistol"
	ModeSwitchAnim="LightOn"
	HudImage=Texture'KFKillMeNow.SingleHUD'
	Weight=0.000000
	bKFNeverThrow=True
	bTorchEnabled=True
	UpKick=300
	FireModeClass(0)=Class'KFMod.SingleFire'
	FireModeClass(1)=Class'KFMod.SingleALTFire'
	PutDownAnim="PutDown"
	SelectSound=Sound'KFPlayerSound.getweaponout'
	AIRating=0.250000
	CurrentRating=0.250000
	bShowChargingBar=True
	Description="A 9mm Pistol"
	DisplayFOV=70.000000
	Priority=10
	SmallViewOffset=(X=13.000000,Y=18.000000,Z=-10.000000)
	CustomCrosshair=-1
	CustomCrossHairColor=(B=0,G=0,R=0,A=0)
	CustomCrossHairTextureName=
	InventoryGroup=2
	GroupOffset=1
	PickupClass=Class'KFMod.SinglePickup'
	PlayerViewOffset=(X=4.000000,Y=5.500000,Z=-6.000000)
	BobDamping=6.000000
	AttachmentClass=Class'KFMod.SingleAttachment'
	IconCoords=(X1=434,Y1=253,X2=506,Y2=292)
	ItemName="9mm Tactical"
	Mesh=SkeletalMesh'KFWeaponModels.9MM'
}
