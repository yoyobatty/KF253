class Crossbow extends KFWeapon;

var color ChargeColor;

var float Range;
var float LastRangingTime;

var() Material ZoomMat;
var() float ScopeCrossX, ScopeCrossY;	// where the reticle crosses in ZoomMat's 512 square; that point goes on the aim
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

simulated function bool PutDown()
{
	if ( Super.PutDown() )
	{
		GotoState('');
		return true;
	}
	return false;
}

// The bow drawn up to the eye, and the view through its scope once it is there
simulated event RenderOverlays(Canvas Canvas)
{
	if( Instigator==None || PlayerController(Instigator.Controller)==None )
		return;

	if( AimBlend() < 1.0 )
	{
		Super.RenderOverlays(Canvas);
		zoomed=false;
		return;
	}

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
	Canvas.DrawTile(ZoomMat, Canvas.SizeY, Canvas.SizeY, ScopeCrossX - 256, ScopeCrossY - 256, 512, 512);

	DrawRangeFinder(Canvas);
	zoomed = true;
}

// What the scope is on and how far off it is, worked out only while looking through it. A look at nothing within
// the finder's reach (open sky) shows no range: a missed trace has no place to measure to.
simulated function DrawRangeFinder(Canvas Canvas)
{
	local int HitCount;
	local vector Start, End, HitLoc, HitNorm;
	local actor T;
	local string RangeText, TargetName;

	Start = Instigator.Location + Instigator.EyePosition();
	End = Start + vector(Instigator.GetViewRotation()) * 15000;
	RangeText = "--";
	TargetName = "None";
	While( (HitCount++)<50 )
	{
		T = Instigator.Trace(HitLoc, HitNorm, End, Start, true);
		if( T==None )
			break;
		// (past the holder and what rides on them)
		if( T==Instigator || T.Base==Instigator )
		{
			Start = HitLoc;
			continue;
		}
		RangeText = int(VSize(HitLoc - (Instigator.Location + Instigator.EyePosition())) / 52.5 + 0.5) $ "m";
		if( T.IsA('Pawn') )
			TargetName = T.GetHumanReadableName();
		else if( T.IsA('ExtendedZCollision') && T.Owner!=None )
			TargetName = T.Owner.GetHumanReadableName();
		break;
	}

	Canvas.Font = Canvas.MedFont;
	Canvas.SetDrawColor(200,150,0);
	Canvas.SetPos(Canvas.SizeX * 0.16, Canvas.SizeY * 0.43);
	Canvas.DrawText("Range Finder: " $ RangeText);
	Canvas.SetPos(Canvas.SizeX * 0.16, Canvas.SizeY * 0.47);
	Canvas.DrawText("Target: " $ TargetName);
}

defaultproperties
{
     ZoomMat=FinalBlend'KillingFloorWeapons.Xbow.CommandoCrossFinalBlend'
     ScopeCrossX=260.000000
     ScopeCrossY=279.600000
     ClipCount=1
     ReloadRate=0.010000
     bLoadsWithFire=True
     Weight=9.000000
     UpKick=400
	 SideKick=0
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
     AimZoom=4.600000
     AimViewOffset=(X=-5.000000,Y=18.000000,Z=-15.000000)
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
