//=============================================================================
// Welder Inventory class
//=============================================================================
class Welder extends KFMeleeGun;

var () float AmmoRegenRate;

var float AmmoRegenCount;

// Scripted Nametag vars

var ScriptedTexture  ScriptedScreen;
var Shader ShadedScreen;
var Material   ScriptedScreenBack;

//Font/Color/stuff
var Font NameFont;
var font SmallNameFont;                           // Used when the name is to big too fit
var color NameColor;                                // Colors
var Color BackColor;

var float ScreenWeldPercent;
var bool bNoTarget;  // Not close enough to door to get reading
var int FireModeArray;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	bNoTarget =  true;
	if( Level.NetMode==NM_DedicatedServer )
		Return;
	skins[0] = Texture'KillingFloorWeapons.Deagle.HandSkinNew';
	skins[1] = Texture'KillingFloorWeapons.Deagle.ArmSkinNew';
	skins[2] = Shader'KillingFloorWeapons.Welder.WelderShader';
	skins[4] = Shader'KillingFloorWeapons.Welder.FlameShader';
}

function byte BestMode()
{
	Return 1;
}

simulated function float RateSelf()
{
	return -100;
}

simulated function Destroyed()
{
	Super.Destroyed();
	if( ScriptedScreen!=None )
	{
		ScriptedScreen.SetSize(256,256);
		ScriptedScreen.FallBackMaterial = None;
		ScriptedScreen.Client = None;
		Level.ObjectPool.FreeObject(ScriptedScreen);
		ScriptedScreen = None;
	}
	if( ShadedScreen!=None )
	{
		ShadedScreen.Diffuse = None;
		ShadedScreen.Opacity = None;
		ShadedScreen.SelfIllumination = None;
		ShadedScreen.SelfIlluminationMask = None;
		Level.ObjectPool.FreeObject(ShadedScreen);
		ShadedScreen = None;
		skins[3] = None;
	}
}

// Destroy this stuff when the level changes
simulated function PreTravelCleanUp()
{
	if( ScriptedScreen!=None )
	{
		ScriptedScreen.SetSize(256,256);
		ScriptedScreen.FallBackMaterial = None;
		ScriptedScreen.Client = None;
		Level.ObjectPool.FreeObject(ScriptedScreen);
		ScriptedScreen = None;
	}

	if( ShadedScreen!=None )
	{
		ShadedScreen.Diffuse = None;
		ShadedScreen.Opacity = None;
		ShadedScreen.SelfIllumination = None;
		ShadedScreen.SelfIlluminationMask = None;
		Level.ObjectPool.FreeObject(ShadedScreen);
		ShadedScreen = None;
		skins[3] = None;
	}
}

simulated function InitMaterials()
{
	if( ScriptedScreen==None )
	{
		ScriptedScreen = ScriptedTexture(Level.ObjectPool.AllocateObject(class'ScriptedTexture'));
		ScriptedScreen.SetSize(256,256);
		ScriptedScreen.FallBackMaterial = ScriptedScreenBack;
		ScriptedScreen.Client = Self;
	}
	if( ShadedScreen==None )
	{
		ShadedScreen = Shader(Level.ObjectPool.AllocateObject(class'Shader'));
		ShadedScreen.Diffuse = ScriptedScreen;
		ShadedScreen.Opacity = ScriptedScreen;
		ShadedScreen.SelfIllumination = ScriptedScreen;
		ShadedScreen.SelfIlluminationMask = ScriptedScreen;
		skins[3] = ShadedScreen;
	}
}
simulated function Tick(float dt)
{
    local KFDoorMover LastDoorHitActor;

	Super.Tick(dt);
	if (FireMode[0].bIsFiring)
		FireModeArray = 0;
	else if (FireMode[1].bIsFiring)
		FireModeArray = 1;

	if (WeldFire(FireMode[FireModeArray]).LastHitActor != none && VSize(WeldFire(FireMode[FireModeArray]).LastHitActor.Location - Owner.Location) <= (MeleeWeaponRange * 1.5) )
	{
		bNoTarget = false;
		LastDoorHitActor = KFDoorMover(WeldFire(FireMode[FireModeArray]).LastHitActor);
        if(LastDoorHitActor != none)
        {
            ScreenWeldPercent = (LastDoorHitActor.WeldStrength / LastDoorHitActor.MaxWeld) * 100;
        }
		if( ScriptedScreen==None )
			InitMaterials();
		ScriptedScreen.Revision++;
		if( ScriptedScreen.Revision>10 )
			ScriptedScreen.Revision = 1;
	}
	else if (WeldFire(FireMode[FireModeArray]).LastHitActor == none || WeldFire(FireMode[FireModeArray]).LastHitActor != none && VSize(WeldFire(FireMode[FireModeArray]).LastHitActor.Location - Owner.Location) > (MeleeWeaponRange * 1.5) && !bNoTarget  )
	{
		if( ScriptedScreen==None )
			InitMaterials();
		ScriptedScreen.Revision++;
		if( ScriptedScreen.Revision>10 )
			ScriptedScreen.Revision = 1;
		bNoTarget = true;
		if( ClientState != WS_Hidden && Level.NetMode != NM_DedicatedServer && Instigator != none && Instigator.IsLocallyControlled() )
		{
		  PlayIdle();
		}
	}
	if ( AmmoAmount(0) < FireMode[0].AmmoClass.Default.MaxAmmo)
	{
		AmmoRegenCount += (dT * AmmoRegenRate );
		ConsumeAmmo(0, -1*(int(AmmoRegenCount)));
		AmmoRegenCount -= int(AmmoRegenCount);
	}
}

simulated function float ChargeBar()
{
	return FMin(1, (AmmoAmount(0))/(FireMode[0].AmmoClass.Default.MaxAmmo));
}


simulated event RenderTexture(ScriptedTexture Tex)
{
	local int SizeX,  SizeY;

	Tex.DrawTile(0,0,Tex.USize,Tex.VSize,0,0,512,128,Texture'ItemListButtonUnselected',BackColor);   // Draws the tile background
	if(!bNoTarget && ScreenWeldPercent > 0 )
	{
		// Err for now go with a name in black letters
		NameColor.R=(255 - (ScreenWeldPercent * 2));
		NameColor.G=(0 + (ScreenWeldPercent * 2.55));
		NameColor.B=(20 + ScreenWeldPercent);
		NameColor.A=255;
		Tex.TextSize(ScreenWeldPercent@"%",NameFont,SizeX,SizeY); // get the size of the players name
		Tex.DrawText( (Tex.USize - SizeX) * 0.5, 85,ScreenWeldPercent@"%", NameFont, NameColor);
		Tex.TextSize("Integrity:",NameFont,SizeX,SizeY);
		Tex.DrawText( (Tex.USize - SizeX) * 0.5, 50,"Integrity:", NameFont, NameColor);
	}
	else
	{
		NameColor.R=255;
		NameColor.G=255;
		NameColor.B=255;
		NameColor.A=255;
		Tex.TextSize("-",NameFont,SizeX,SizeY); // get the size of the players name
		Tex.DrawText( (Tex.USize - SizeX) * 0.5, 85,"-", NameFont, NameColor);
		Tex.TextSize("Integrity:",NameFont,SizeX,SizeY);
		Tex.DrawText( (Tex.USize - SizeX) * 0.5, 50,"Integrity:", NameFont, NameColor);
	}

}

defaultproperties
{
     AmmoRegenRate=40.000000
     ScriptedScreenBack=FinalBlend'KillingFloorWeapons.Welder.WelderWindowFinal'
     NameFont=Font'UT2003Fonts.FontLarge'
     SmallNameFont=Font'UT2003Fonts.FontSmall'
     BackColor=(B=128,G=128,R=128,A=255)
     MeleeHitSounds(0)=Sound'PatchSounds.WelderFire'
     Weight=0.000000
     bKFNeverThrow=True
     bAmmoHUDAsBar=True
     FireModeClass(0)=Class'KFMod.WeldFire'
     FireModeClass(1)=Class'KFMod.UnWeldFire'
     AIRating=-2.000000
     bMeleeWeapon=False
     bShowChargingBar=True
     OldCenteredOffsetY=0.000000
     OldPlayerViewOffset=(X=-8.000000,Y=5.000000,Z=-6.000000)
     OldSmallViewOffset=(X=4.000000,Y=11.000000,Z=-12.000000)
     OldPlayerViewPivot=(Pitch=400)
     OldCenteredRoll=3000
     EffectOffset=(X=100.000000,Y=25.000000,Z=-10.000000)
     DisplayFOV=75.000000
     Priority=5
     SmallViewOffset=(X=13.000000,Y=30.000000,Z=-10.000000)
	 PrePivot=(X=0,Y=0,Z=0)
     CenteredOffsetY=-5.000000
     CenteredRoll=3000
     CenteredYaw=-1500
     InventoryGroup=6
     GroupOffset=1
     PickupClass=Class'KFMod.WelderPickup'
     PlayerViewOffset=(X=4.000000,Y=5.500000,Z=-6.000000)
     PlayerViewPivot=(Pitch=400)
     BobDamping=4.000000
     AttachmentClass=Class'KFMod.WelderAttachment'
     IconCoords=(X1=169,Y1=39,X2=241,Y2=77)
     ItemName="Welder"
     Mesh=SkeletalMesh'KFWeaponModels.Welder'
     AmbientGlow=2
	 GunLengthDist=0.000000
	 WallPivotRot=(Pitch=0,Yaw=0,Roll=0)
	 WallPivotOffset=(x=0,y=0,z=0)
	 MeleeWeaponRange=90.000000
}
