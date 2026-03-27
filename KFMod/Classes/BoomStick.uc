//=============================================================================
// BoomStick Inventory class
//=============================================================================
class BoomStick extends KFWeaponShotgun;

<<<<<<< HEAD
#EXEC OBJ LOAD FILE=KillingFloorHUD.utx

simulated event WeaponTick(float dt)
{
	if(AmmoAmount(0) == 0)
=======
var() bool bAltFire;
var() int SlugsPerFire;

#EXEC OBJ LOAD FILE=KillingFloorHUD.utx

replication
{
	reliable if(Role < ROLE_Authority)
		ServerChangeFireMode;

    reliable if (Role == ROLE_Authority)
        bAltFire;
}

function byte BestMode()
{
	local Bot B;
	local float Dist;
	local Vector Dir;

	B = Bot(Instigator.Controller);
	if ( (B == None) || (B.Enemy == None) )
		return 0;

	Dir = Instigator.Location - B.Enemy.Location;
	Dist = VSize(Dir);

	if (Dist > 600.f)
		return 1;
	else return 0;
}

// Toggle semi/auto fire
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
			Player.ReceiveLocalizedMessage(class'KFmod.BoomStickSwitchMessage',0);
			//FireMode[0].ProjectileClass = class'KFMod.BoomStickSlug';
			FireMode[0].ProjectileClass = FireMode[1].ProjectileClass;
			BoomStickFire(FireMode[0]).ProjPerFire = SlugsPerFire;
     		FireMode[0].Spread = 0.010000;
			FireMode[0].SpreadStyle = SS_Line;
		}
		else 
		{
			Player.ReceiveLocalizedMessage(class'KFmod.BoomStickSwitchMessage',1);
			FireMode[0].ProjectileClass = FireMode[0].default.ProjectileClass;
			BoomStickFire(FireMode[0]).ProjPerFire = BoomStickFire(FireMode[0]).default.ProjPerFire;
			FireMode[0].Spread = FireMode[0].default.Spread;
			FireMode[0].SpreadStyle = FireMode[0].default.SpreadStyle;
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
}

exec simulated function SwitchModes()
{
    DoToggle();
}

simulated event WeaponTick(float dt)
{
	if(AmmoAmount(0) <= 1)
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		Clipleft = 0;
	if(Clipleft == 1)
		Clipleft = 2;
	super.Weapontick(dt);
}

defaultproperties
{
<<<<<<< HEAD
=======
	SlugsPerFire=1
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	ClipCount=1
	ReloadRate=0.010000
	ReloadAnim="Reload"
	ReloadAnimRate=0.900000
	UpKick=2500
	FireModeClass(0)=Class'KFMod.BoomStickFire'
<<<<<<< HEAD
	FireModeClass(1)=Class'KFMod.NoFire'
=======
	FireModeClass(1)=Class'KFMod.BoomStickAltFire'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	PutDownAnim="PutDown"
	SelectSound=Sound'KFPlayerSound.getweaponout'
	AIRating=0.900000
	CurrentRating=0.900000
<<<<<<< HEAD
=======
	bSniping=False
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	OldCenteredOffsetY=0.000000
	OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
	OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
	OldPlayerViewPivot=(Pitch=400)
	OldCenteredRoll=3000
	Description="A double barreled shotgun used by big game hunters. It fires two slugs simultaneously and can bring down even the largest targets, quickly."
	DisplayFOV=55.000000
<<<<<<< HEAD
	Priority=30
=======
	Priority=20
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	SmallViewOffset=(X=8.000000,Y=18.000000,Z=-4.000000)
	CenteredOffsetY=-5.000000
	CenteredRoll=3000
	CenteredYaw=-1500
<<<<<<< HEAD
	CustomCrosshair=-1
	CustomCrossHairColor=(B=0,G=0,R=0,A=0)
	CustomCrossHairTextureName=
	InventoryGroup=4
	GroupOffset=3
	PickupClass=Class'KFMod.BoomStickPickup'
	BobDamping=6.000000
=======
	InventoryGroup=4
	GroupOffset=3
	PickupClass=Class'KFMod.BoomStickPickup'
	BobDamping=4.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	AttachmentClass=Class'KFMod.BoomStickAttachment'
	ItemName="Hunting Shotgun"
	bUseDynamicLights=True
	Mesh=SkeletalMesh'KFWeaponModels.BoomStick'
	TransientSoundVolume=1.000000
<<<<<<< HEAD
=======
	bModeZeroCanDryFire=false
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
