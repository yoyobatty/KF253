//=============================================================================
// L85 Inventory class
//=============================================================================
class Bullpup extends KFWeapon;

//var BullpupReflectManager ReflectManager;
//var BullpupReflectCam ReflectCam;

#exec OBJ LOAD FILE=KillingFloorWeapons.utx
#exec OBJ LOAD FILE=KillingFloorHUD.utx

var() bool bAltFire;

replication
{
	reliable if(Role < ROLE_Authority)
		ServerChangeFireMode;

    reliable if (Role == ROLE_Authority)
        bAltFire;
}

/* 
simulated function PostBeginPlay()
{
	local vector TempLoc;

	Super.PostBeginPlay();
	TempLoc = Location;
	TempLoc.Y -= 50000;
	ReflectCam = Spawn(class'BullpupReflectCam', self);

	if (Level.NetMode != NM_DedicatedServer)
	{
		ReflectManager = Spawn(class'BullpupReflectManager', self, , TempLoc);
		ReflectManager.CamActor = ReflectCam;
	}

}
*/


simulated function DoToggle ()
{
	local PlayerController Player;

	if( IsFiring() )
	   return;

	Player = Level.GetLocalPlayerController();
	if ( Player!=None )
	{
		//PlayOwnedSound(sound'Inf_Weapons_Foley.stg44_firemodeswitch01',SLOT_None,2.0,,,,false);
		bAltFire = !bAltFire;
		if ( bAltFire )
		{
			Player.ReceiveLocalizedMessage(class'KFmod.BullpupSwitchMessage',0);
			BullpupFire(FireMode[0]).MaxFireBurst = 3;
			FireMode[0].FireRate*=0.85;
			FireMode[0].Spread*=0.8;
		}
		else 
		{
			Player.ReceiveLocalizedMessage(class'KFmod.BullpupSwitchMessage',1);
			BullpupFire(FireMode[0]).MaxFireBurst = 0; 
			FireMode[0].FireRate=FireMode[0].default.FireRate;
			FireMode[0].Spread=FireMode[0].default.Spread;
		}
	}
	//log(Owner.GetHumanReadableName()$" changed firemode on " $GetHumanReadableName());
	Super.DoToggle();
	ServerChangeFireMode(bAltFire);
}

// Set the new fire mode on the server
function ServerChangeFireMode(bool bNewAltFire)
{
    bAltFire = bNewAltFire;
    if ( BullpupFire(FireMode[0]) != None )
    {
        if ( bAltFire )
            BullpupFire(FireMode[0]).MaxFireBurst = 3;
        else
            BullpupFire(FireMode[0]).MaxFireBurst = 0;
    }
}

function bool RecommendRangedAttack()
{
	return true;
}

function float SuggestAttackStyle()
{
	return -1.0;
}

exec simulated function SwitchModes()
{
    DoToggle();
}

function byte BestMode()
{
	return 0;
}

simulated function bool PutDown()
{
	if ( Super.PutDown() )
	{
		GotoState('');
		return true;
	}
	return false;
}

defaultproperties
{
	ClipCount=40
	ReloadRate=2.000000
	ReloadBeginSound=Sound'KFWeaponSound.L85Clipchange'
	ReloadSound=Sound'KFWeaponSound.L85Cock'
	ReloadAnim="Reload"
	ReloadAnimRate=0.900000
	WeaponReloadAnim="ReloadBullpup"
	Weight=6.000000
	UpKick=200
	FireModeClass(0)=Class'KFMod.BullpupFire'
	FireModeClass(1)=Class'KFMod.KFZoom'
	PutDownAnim="PutDown"
	SelectAnimRate=0.800000
	BringUpTime=0.660000
	SelectSound=Sound'KFPlayerSound.getweaponout'
	SelectForce="SwitchToAssaultRifle"
	AIRating=0.550000
	CurrentRating=0.550000
	bShowChargingBar=True
	OldCenteredOffsetY=0.000000
	OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
	OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
	OldPlayerViewPivot=(Pitch=400)
	OldCenteredRoll=3000
	Description="A military grade automatic rifle. Can be fired in semi-auto or full auto firemodes and comes equipped with a scope for increased accuracy."
	EffectOffset=(X=100.000000,Y=25.000000,Z=-10.000000)
	DisplayFOV=86.000000
	AimZoom=4.600000
	AimInTime=0.400000
	AimViewOffset=(X=10.000000,Y=20.830000,Z=-23.763000)
	Priority=4
	SmallViewOffset=(X=10.000000,Y=20.800000,Z=-23.800000)
	CenteredOffsetY=-5.000000
	CenteredRoll=3000
	CenteredYaw=-1500
	CustomCrosshair=11
	CustomCrossHairTextureName="Crosshairs.HUD.Crosshair_Cross5"
	InventoryGroup=3
	GroupOffset=1
	PickupClass=Class'KFMod.BullpupPickup'
	PlayerViewOffset=(X=6.000000,Y=6.500000,Z=-6.000000)
	PlayerViewPivot=(Pitch=400)
	BobDamping=4.000000
	AttachmentClass=Class'KFMod.BullpupAttachment'
	IconCoords=(X1=245,Y1=39,X2=329,Y2=79)
	ItemName="Bullpup"
	Mesh=SkeletalMesh'KFWeaponModels.L85'
	Skins(0)=Texture'KillingFloorWeapons.Deagle.HandSkinNew'
	DrawScale=0.850000
	TransientSoundVolume=1.250000
}
