//=============================================================================
// Winchester Inventory class
//=============================================================================
<<<<<<< HEAD
class Winchester extends KFWeaponShotgun;      // Bullpup
=======
class Winchester extends KFWeaponShotgun;  
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

exec function ReloadMeNow()
{
	if(!AllowReload())
		return;

	if ( bAimingRifle )
	{
		FireMode[1].bIsFiring = False;
		ServerSetAiming(False);
		PlayAnimZoom(False);
	}
	Super.ReloadMeNow();
}

<<<<<<< HEAD

//I'll just copy and paste the damn things if you want them
//so badly.
// AI Interface
function float GetAIRating()
{
	local Bot B;
	local float EnemyDist;
	local vector EnemyDir;

	B = Bot(Instigator.Controller);
	if ( B == None )
		return AIRating;

	if ( (B.Target != None) && (Pawn(B.Target) == None) && (VSize(B.Target.Location - Instigator.Location) < 1250) )
		return 0.9;

	if ( B.Enemy == None )
	{
		if ( (B.Target != None) && VSize(B.Target.Location - B.Pawn.Location) > 3500 )
			return 0.2;
		return AIRating;
	}

	EnemyDir = B.Enemy.Location - Instigator.Location;
	EnemyDist = VSize(EnemyDir);
	if ( EnemyDist > 750 )
	{
		if ( EnemyDist > 2000 )
		{
			if ( EnemyDist > 3500 )
				return 0.2;
			return (AIRating - 0.3);
		}
		if ( EnemyDir.Z < -0.5 * EnemyDist )
			return (AIRating - 0.3);
	}
	else if ( (B.Enemy.Weapon != None) && B.Enemy.Weapon.bMeleeWeapon )
		return (AIRating + 0.35);
	else if ( EnemyDist < 400 )
		return (AIRating + 0.2);
	return FMax(AIRating + 0.2 - (EnemyDist - 400) * 0.0008, 0.2);
}

function float SuggestAttackStyle()
{
	if ( (AIController(Instigator.Controller) != None)
		&& (AIController(Instigator.Controller).Skill < 3) )
		return 0.4;
    return 0.8;
}

=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated function BringUp(optional Weapon PrevWeapon)
{
	if ( PlayerController(Instigator.Controller) != None )
		LastFOV = PlayerController(Instigator.Controller).DesiredFOV;
	FireMode[0].FireAnim = 'Fire';
	FireMode[0].FireLoopAnim = 'Fire';
	IdleAnim = Default.IdleAnim;
	if( WinchesterFire(FireMode[0])!=none ) 
		WinchesterFire(FireMode[0]).NormalSpeed();
	Super.BringUp(PrevWeapon);
}

simulated function WeaponTick(float deltaTime)
{
	Super.WeaponTick(deltaTime);
	if( Level.NetMode==NM_DedicatedServer )
		Return;
	if ( bAimingRifle && Instigator!=None && Instigator.Physics==PHYS_Falling )
	{
		FireMode[1].bIsFiring = False;
		ServerSetAiming(False);
		PlayAnimZoom(False);
	}
	if( bZooming && ZoomingInTimer<Level.TimeSeconds )
	{
		ZoomLevel = 0.150;
		if(PlayerController(Instigator.Controller)!=none)
			PlayerController(Instigator.Controller).DesiredFOV = FClamp(90.0 - (ZoomLevel * 88.0), 1, 170);
	}
}

simulated function bool CanZoomNow()
{
	Return (!FireMode[0].bIsFiring && Instigator!=None && Instigator.Physics!=PHYS_Falling);
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
<<<<<<< HEAD
=======
		Upkick = default.UpKick * 0.5;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		BobDamping=1.0;
		bZooming = True;
		ZoomingInTimer = Level.TimeSeconds+0.3;
		if( WinchesterFire(FireMode[0])!=none ) 	
			WinchesterFire(FireMode[0]).AimingSpeed();
	}
	else if( IdleAnim!=Default.IdleAnim )
	{
		FireMode[0].FireAnim = 'Fire';
		FireMode[0].FireLoopAnim = 'Fire';
		IdleAnim = Default.IdleAnim;
		TweenAnim(IdleAnim,0.5);
		bZooming = False;
		ZoomLevel=0.0;
<<<<<<< HEAD
=======
		Upkick = default.UpKick;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		BobDamping=default.BobDamping;
		if (WinchesterFire(FireMode[0]) != none) 
			WinchesterFire(FireMode[0]).NormalSpeed();
		if(PlayerController(Instigator.Controller)!=none)
			PlayerController(Instigator.Controller).DesiredFOV = PlayerController(Instigator.Controller).DefaultFOV;
	}
}
function ServerSetAiming(bool IsAiming)
{
	Super.ServerSetAiming(IsAiming);
	if( WinchesterFire(FireMode[0])==none )
		Return;
	if( IsAiming )
		WinchesterFire(FireMode[0]).AimingSpeed();
	else WinchesterFire(FireMode[0]).NormalSpeed();
}

<<<<<<< HEAD
defaultproperties
{
	ClipCount=10
	ReloadRate=0.900000
	ReloadAnim="Reload"
	ReloadAnimRate=1.000000
	IdleAimAnim="'"
	Weight=6.000000
	FireModeClass(0)=Class'KFMod.WinchesterFire'
	FireModeClass(1)=Class'KFMod.WinchesterAltFire'
	PutDownAnim="PutDown"
	BringUpTime=1.000000
	SelectSound=Sound'KFPlayerSound.getweaponout'
	AIRating=0.560000
	CurrentRating=0.560000
	bSniping=True
	bShowChargingBar=True
	OldCenteredOffsetY=0.000000
	OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
	OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
	OldPlayerViewPivot=(Pitch=800)
	OldCenteredRoll=3000
	Description="A rugged and reliable single-shot rifle.  "
	EffectOffset=(X=100.000000,Y=25.000000,Z=-10.000000)
	DisplayFOV=70.000000
	Priority=20
	SmallViewOffset=(X=8.000000,Y=18.000000,Z=-4.000000)
	CenteredOffsetY=-5.000000
	CenteredRoll=3000
	CenteredYaw=-1500
	CustomCrosshair=-1
	CustomCrossHairColor=(B=0,G=0,R=0,A=0)
	CustomCrossHairTextureName=
	InventoryGroup=3
	GroupOffset=2
	PickupClass=Class'KFMod.WinchesterPickup'
	BobDamping=6.000000
	AttachmentClass=Class'KFMod.WinchesterAttachment'
	ItemName="Winchester"
	bUseDynamicLights=True
	Mesh=SkeletalMesh'KFWeaponModels.Winchester'
	DrawScale=0.900000
	TransientSoundVolume=50.000000
=======
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

defaultproperties
{
     ClipCount=10
     ReloadRate=0.900000
     ReloadAnim="Reload"
     ReloadAnimRate=1.000000
     IdleAimAnim="'"
     Weight=6.000000
	 UpKick=800.000000
     FireModeClass(0)=Class'KFMod.WinchesterFire'
     FireModeClass(1)=Class'KFMod.WinchesterAltFire'
     PutDownAnim="PutDown"
     BringUpTime=1.000000
     SelectSound=Sound'KFPlayerSound.getweaponout'
     AIRating=0.600000
     CurrentRating=0.600000
     bShowChargingBar=True
     OldCenteredOffsetY=0.000000
     OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
     OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
     OldPlayerViewPivot=(Pitch=800)
     OldCenteredRoll=3000
     Description="A rugged and reliable single-shot rifle.  "
     EffectOffset=(X=100.000000,Y=25.000000,Z=-10.000000)
     DisplayFOV=65.000000
     Priority=9
     SmallViewOffset=(X=8.000000,Y=20.100000,Z=-4.000000)
     CenteredOffsetY=-5.000000
     CenteredRoll=3000
     CenteredYaw=-1500
     InventoryGroup=3
     GroupOffset=2
     PickupClass=Class'KFMod.WinchesterPickup'
     PlayerViewOffset=(X=15.000000,Y=20.100000,Z=-3.500000)
     BobDamping=4.000000
     AttachmentClass=Class'KFMod.WinchesterAttachment'
     ItemName="Winchester"
     bUseDynamicLights=True
     Mesh=SkeletalMesh'KFWeaponModels.Winchester'
     DrawScale=0.900000
     TransientSoundVolume=50.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
