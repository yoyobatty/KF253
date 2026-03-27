class Crossbow extends KFWeapon;

var color ChargeColor;

var float Range;
var float LastRangingTime;

var() Material ZoomMat;
var() Sound ZoomSound;
var bool bArrowRemoved;

function byte BestMode()
{
	return 0;
}

function float GetAIRating()
{
	local Bot B;
	local float ZDiff, dist, Result;

	B = Bot(Instigator.Controller);
	if ( B == None )
		return AIRating;
	if ( B.IsShootingObjective() )
		return AIRating - 0.15;
	if ( B.Enemy == None )
	{
		if ( (B.Target != None) && VSize(B.Target.Location - B.Pawn.Location) > 8000 )
			return 0.95;
		return AIRating;
	}

	if ( B.Stopped() )
		result = AIRating + 0.1;
	else
		result = AIRating - 0.1;
	if ( Vehicle(B.Enemy) != None )
		result -= 0.2;
	ZDiff = Instigator.Location.Z - B.Enemy.Location.Z;
	if ( ZDiff < -200 )
		result += 0.1;
	dist = VSize(B.Enemy.Location - Instigator.Location);
	if ( dist > 2000 )
	{
		if ( !B.EnemyVisible() )
			result = result - 0.15;
		return ( FMin(2.0,result + (dist - 2000) * 0.0002) );
	}
	if ( !B.EnemyVisible() )
		return AIRating - 0.1;

	return result;
}

function bool RecommendRangedAttack()
{
	return true;
}

function float SuggestAttackStyle()
{
	return -1.0;
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
	local float Dist;
	local int HitCount;
	local vector Start, StartDist, HitLoc, HitNorm;
	local actor T;
	local string TargetName;

	Start = Instigator.Location + Instigator.EyePosition();
	StartDist=Start;
	While( (HitCount++)<50 )
	{
		T = Instigator.Trace(HitLoc, HitNorm, Start + vector(Instigator.GetViewRotation()) * 15000, Start, true);
		if (T == None)
		{
			Dist = -1;
			TargetName = "Null"; //For fun
			Break;
		}
		else if( T==Instigator || T.Base == Instigator )
		{
			Start = HitLoc;
			Continue;
		}

	}
	Dist = VSize(HitLoc-StartDist);
	if(T.IsA('Pawn'))
		TargetName = T.GetHumanReadableName();
	else if (T.IsA('ExtendedZCollision'))
		TargetName = T.Owner.GetHumanReadableName();
	else
		TargetName = "None";

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
		/*

                SetZoomBlendColor(Canvas);
		SetLocation( Instigator.Location + Instigator.CalcDrawOffset(self) );
		SetRotation( Instigator.GetViewRotation() );
		Canvas.DrawActor(self, false);
		zoomed = true;
		*/
		
		SetZoomBlendColor(Canvas);

		//Black-out either side of the main zoom circle.
		Canvas.Style = ERenderStyle.STY_Normal;
		Canvas.SetPos(0, 0);
		Canvas.DrawTile(ZoomMat, (Canvas.SizeX - Canvas.SizeY) / 2, Canvas.SizeY, 0.0, 0.0, 8, 8);
		Canvas.SetPos(Canvas.SizeX, 0);
		Canvas.DrawTile(ZoomMat, -(Canvas.SizeX - Canvas.SizeY) / 2, Canvas.SizeY, 0.0, 0.0, 8, 8);

		//The view through the scope itself.
		Canvas.Style = 255;
		Canvas.SetPos((Canvas.SizeX - Canvas.SizeY) / 2,0);
		Canvas.DrawTile(ZoomMat, Canvas.SizeY, Canvas.SizeY, 0.0, 0.0, 512, 512);

		//Draw some useful text.
		Canvas.Font = Canvas.MedFont;
		Canvas.SetDrawColor(200,150,0);

		Canvas.SetPos(Canvas.SizeX * 0.16, Canvas.SizeY * 0.43);
		Canvas.DrawText("Range Finder: " $(Dist/52.5)$ "m");
		Canvas.SetPos(Canvas.SizeX * 0.16, Canvas.SizeY * 0.47);
		Canvas.DrawText("Target: " $TargetName);

		zoomed = true;
	}
}

simulated function PlayAnimZoom( bool bZoomNow )
{
	if( bZoomNow )
	{
		IdleAnim = 'AimIdle';
		PlayAnim('Raise');
		//FireMode[0].FireAnim = 'AimFire';
		//FireMode[0].FireLoopAnim = 'AimFire';
		PrePivot=vect(0,0,0);
		BobDamping=1.0;
		bZooming = True;
		ZoomingInTimer = Level.TimeSeconds+0.3;
	}
	else if( IdleAnim!=Default.IdleAnim )
	{
		//FireMode[0].FireAnim = 'Fire';
		//FireMode[0].FireLoopAnim = 'Fire';
		IdleAnim = Default.IdleAnim;
		TweenAnim(IdleAnim,0.5);
		bZooming = False;
		ZoomLevel=0.0;
		if(PlayerController(Instigator.Controller)!=none)
			PlayerController(Instigator.Controller).DesiredFOV = PlayerController(Instigator.Controller).DefaultFOV;
	}
}

defaultproperties
{
     ZoomMat=FinalBlend'KillingFloorWeapons.Xbow.CommandoCrossFinalBlend'
     ClipCount=1
     ReloadRate=0.010000
     Weight=9.000000
     UpKick=150
     FireModeClass(0)=Class'KFMod.CrossbowFire'
     FireModeClass(1)=Class'KFMod.KFZoom'
     PutDownAnim="PutDown"
     SelectSound=Sound'KFPlayerSound.getweaponout'
     SelectForce="SwitchToAssaultRifle"
     AIRating=0.650000
     CurrentRating=0.650000
     OldCenteredOffsetY=0.000000
     OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
     OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
     OldPlayerViewPivot=(Pitch=400)
     OldCenteredRoll=3000
     Description="A recreational hunting weapon, featuring a firing trigger and an a powerful integrated scope. "
     DisplayFOV=80.000000
     Priority=10
     SmallViewOffset=(X=-5.000000,Y=18.000000,Z=-15.000000)
     CenteredOffsetY=-5.000000
     CenteredRoll=3000
     CenteredYaw=-1500
     CustomCrosshair=11
     CustomCrossHairTextureName="Crosshairs.HUD.Crosshair_Cross5"
     InventoryGroup=4
     GroupOffset=2
     PickupClass=Class'KFMod.CrossbowPickup'
     PlayerViewOffset=(X=4.000000,Y=5.500000,Z=-6.000000)
     PlayerViewPivot=(Pitch=400)
     BobDamping=4.000000
     AttachmentClass=Class'KFMod.CrossbowAttachment'
     IconCoords=(X1=253,Y1=146,X2=333,Y2=181)
     ItemName="Compound Crossbow"
     LightType=LT_None
     LightBrightness=0.000000
     LightRadius=0.000000
     Mesh=SkeletalMesh'KFWeaponModels.Xbow'
     DrawScale=0.900000
}
