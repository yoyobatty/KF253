//=============================================================================
// L85 Inventory class
//=============================================================================
class Bullpup extends KFWeapon;

//var BullpupReflectManager ReflectManager;
//var BullpupReflectCam ReflectCam;

#exec OBJ LOAD FILE=KillingFloorWeapons.utx
#exec OBJ LOAD FILE=KillingFloorHUD.utx

var() bool bAltFire;

var ()      int         HealBoostAmount;// How much we heal a player by default with the heal dart

var localized   string  SuccessfulHealMessage;

var         int         HealAmmoCharge; // Current healing charger
var         float       RegenTimer;     // Tracks regeneration
Const MaxAmmoCount=500;                 // Maximum healing charge count
var ()      float       AmmoRegenRate;  // How quickly the healing charge regenerates

replication
{
	reliable if(Role < ROLE_Authority)
		ServerChangeFireMode;

    reliable if (Role == ROLE_Authority)
        bAltFire, HealAmmoCharge, ClientSuccessfulHeal;
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
// The server lets the client know they successfully healed someone
simulated function ClientSuccessfulHeal(String HealedName)
{
    if( PlayerController(Instigator.Controller) != none )
    {
        PlayerController(Instigator.controller).ClientMessage(SuccessfulHealMessage$HealedName, 'CriticalEvent');
    }
}

// Return a float value representing the current healing charge amount
simulated function float ChargeBar()
{
	return FClamp(float(HealAmmoCharge)/float(MaxAmmoCount),0,1);
}

simulated function Tick(float dt)
{
	Super.Tick(dt);
	if ( Level.NetMode!=NM_Client && HealAmmoCharge < MaxAmmoCount && RegenTimer<Level.TimeSeconds )
	{
		RegenTimer = Level.TimeSeconds + AmmoRegenRate;

		if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none )
		{
			HealAmmoCharge += 10 * KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill.Static.GetSyringeChargeRate();
		}
		else
		{
			HealAmmoCharge += 10;
		}
		if ( HealAmmoCharge > MaxAmmoCount )
		{
			HealAmmoCharge = MaxAmmoCount;
		}
	}
}

simulated function ChangedPerk(string NewPerk)
{
	if ( NewPerk == "Field Medic" )
	{
		log("Bullpup changed to healing mode for " $Instigator.GetHumanReadableName());
		//FireMode[1] = BullpupHealFire(Level.ObjectPool.AllocateObject(class'BullpupHealFire'));
		FireModeClass[1] = class'BullpupHealFire';
		FireMode[1] = new(class'BullpupHealFire') FireModeClass[1];
	}
	else
	{
		log("Bullpup changed to zoom mode for " $Instigator.GetHumanReadableName());
		//FireMode[1] = KFZoom(Level.ObjectPool.AllocateObject(default.FireModeClass[1]));
		FireModeClass[1] = default.FireModeClass[1];
		FireMode[1] = new(default.FireModeClass[1]) default.FireModeClass[1];
	}
	InitWeaponFires();
	if (FireMode[1] != None)
	{
		FireMode[1].ThisModeNum = 1;
		FireMode[1].Weapon = self;
		FireMode[1].Instigator = Instigator;
		FireMode[1].Level = Level;
		FireMode[1].Owner = self;
		FireMode[1].PreBeginPlay();
		FireMode[1].BeginPlay();
		FireMode[1].PostBeginPlay();
		FireMode[1].SetInitialState();
		FireMode[1].PostNetBeginPlay();
	}
}


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

simulated function SetZoomBlendColor(Canvas c)
{
	local Byte    val;
	local Color   clr;
	local Color   fog;

	clr.R = 255;
	clr.G = 255;
	clr.B = 255;
	clr.A = 255;

	if( Instigator.Region.Zone.bDistanceFog )
	{
		fog = Instigator.Region.Zone.DistanceFogColor;
		val = 0;
		val = Max( val, fog.R);
		val = Max( val, fog.G);
		val = Max( val, fog.B);
		if( val > 128 )
		{
			val -= 128;
			clr.R -= val;
			clr.G -= val;
			clr.B -= val;
		}
	}
	c.DrawColor = clr;
}

simulated function BringUp(optional Weapon PrevWeapon)
{
	if ( PlayerController(Instigator.Controller) != None )
		LastFOV = PlayerController(Instigator.Controller).DesiredFOV;
	FireMode[0].FireAnim = 'Fire';
	FireMode[0].FireLoopAnim = 'Fire';
	IdleAnim = Default.IdleAnim;
	Super.BringUp(PrevWeapon);
}

simulated function bool PutDown()
{
	if( Instigator.Controller.IsA( 'PlayerController' ) )
		PlayerController(Instigator.Controller).EndZoom();
	if ( Super.PutDown() )
	{
		GotoState('');
		return true;
	}
	return false;
}

simulated function WeaponTick(float deltaTime)
{
	super.WeaponTick(deltaTime);

	if( Level.NetMode==NM_DedicatedServer )
		Return;

	if ( bAimingRifle && Instigator!=None && Instigator.Physics==PHYS_Falling )
	{
		FireMode[1].bIsFiring = False;
		ServerSetAiming(False);
		PlayAnimZoom(False);
	}
	else if( bZooming && ZoomingInTimer<Level.TimeSeconds )
	{
		bZooming = False;
		ZoomLevel = 0.20;
		if( PlayerController(Instigator.Controller)!=None )
			PlayerController(Instigator.Controller).DesiredFOV = FClamp(50.0 - (ZoomLevel * 88.0), 1, 170);
	}
}
simulated function bool CanZoomNow()
{
	Return (!FireMode[0].bIsFiring && Instigator!=None && Instigator.Physics!=PHYS_Falling);
}

// Draw the Winchester, but zoom in the FOV so you can see down the barrel, too.
simulated event RenderOverlays(Canvas Canvas)
{
	local PlayerController PC;

	PC = PlayerController(KFPawn(Owner).Controller);

	if(PC == None)
		return;

	LastFOV = PC.DesiredFOV;

	if (PC.DesiredFOV == PC.DefaultFOV || (Level.bClassicView && PC.DesiredFOV == 90))
	{
		Super.RenderOverlays(Canvas);
		zoomed=false;
		//bAimingRifle = false;
	}
	else
	{
		SetZoomBlendColor(Canvas);
		SetLocation( Instigator.Location + Instigator.CalcDrawOffset(self) );
		SetRotation( Instigator.GetViewRotation() );
		Canvas.DrawActor(self, false);
		zoomed = true;
	}
}

simulated function PlayAnimZoom( bool bZoomNow )
{
	if( bZoomNow )
	{
		IdleAnim = 'AimIdle';
		PlayAnim('Raise');
		FireMode[0].FireAnim = 'AimFire';
		FireMode[0].FireLoopAnim = 'AimFire';
		PrePivot=vect(0,0,0);
		BobDamping=1.0;
		bZooming = True;
		ZoomingInTimer = Level.TimeSeconds+0.3;
	}
	else if( IdleAnim!=Default.IdleAnim )
	{
		FireMode[0].FireAnim = 'Fire';
		FireMode[0].FireLoopAnim = 'Fire';
		IdleAnim = Default.IdleAnim;
		TweenAnim(IdleAnim,0.5);
		bZooming = False;
		ZoomLevel=0.0; 
		BobDamping=default.BobDamping;
		if(PlayerController(Instigator.Controller)!=none)
			PlayerController(Instigator.Controller).DesiredFOV = PlayerController(Instigator.Controller).DefaultFOV;
	}
}

defaultproperties
{
	HealBoostAmount=20
	SuccessfulHealMessage="You healed "
	HealAmmoCharge=500
	AmmoRegenRate=0.300000
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
