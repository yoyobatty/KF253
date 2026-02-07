//=============================================================================
// L85 Inventory class
//=============================================================================
class Bullpup extends KFWeapon
	config(user);

#exec OBJ LOAD FILE=KillingFloorWeapons.utx
#exec OBJ LOAD FILE=KillingFloorHUD.utx



simulated function DoToggle ()
{
	local PlayerController Player;

	Player = Level.GetLocalPlayerController();
	if ( Player!=None )
	{
		FireMode[0].bWaitForRelease = !FireMode[0].bWaitForRelease;
		if ( FireMode[0].bWaitForRelease )
			Player.ReceiveLocalizedMessage(class'KFmod.BullpupSwitchMessage');
		else Player.ReceiveLocalizedMessage(class'KFmod.BullpupSwitchMessage');
	}
	Super.DoToggle();
}

function bool RecommendRangedAttack()
{
	return true;
}

//TODO: LONG ranged?
function bool RecommendLongRangedAttack()
{
	return true;
}

function float SuggestAttackStyle()
{
	return -1.0;
}

exec function SwitchModes()
{
	DoToggle();
}

function float GetAIRating()
{
	local Bot B;

	B = Bot(Instigator.Controller);
	if ( (B == None) || (B.Enemy == None) )
		return AIRating;

	return AIRating;
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
	DisplayFOV=75.000000
	Priority=40
	SmallViewOffset=(X=5.000000,Y=18.000000,Z=-20.000000)
	CenteredOffsetY=-5.000000
	CenteredRoll=3000
	CenteredYaw=-1500
	CustomCrosshair=-1
	CustomCrossHairColor=(B=0,G=0,R=0,A=0)
	CustomCrossHairTextureName=
	InventoryGroup=3
	GroupOffset=1
	PickupClass=Class'KFMod.BullpupPickup'
	PlayerViewOffset=(X=4.000000,Y=5.500000,Z=-6.000000)
	PlayerViewPivot=(Pitch=400)
	BobDamping=6.000000
	AttachmentClass=Class'KFMod.BullpupAttachment'
	IconCoords=(X1=245,Y1=39,X2=329,Y2=79)
	ItemName="Bullpup"
	Mesh=SkeletalMesh'KFWeaponModels.L85'
	DrawScale=0.850000
	TransientSoundVolume=1.250000
}
