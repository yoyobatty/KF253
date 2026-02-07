<<<<<<< HEAD
#exec OBJ LOAD FILE=KillingFloorHUD.utx
#exec OBJ LOAD FILE=PatchTex.utx
#exec OBJ LOAD FILE=KFInterfaceContent.utx
#exec OBJ LOAD FILE=KFKillMeNow.utx
#exec OBJ LOAD FILE=KFMapEndTextures.utx
=======
#exec OBJ LOAD FILE=..\KFMod20\Textures\KillingFloorHUD.utx
#exec OBJ LOAD FILE=..\KFMod20\Textures\PatchTex.utx
#exec OBJ LOAD FILE=..\KFMod20\Textures\KFInterfaceContent.utx
#exec OBJ LOAD FILE=..\KFMod20\Textures\KFKillMeNow.utx
#exec OBJ LOAD FILE=..\KFMod20\Textures\KFMapEndTextures.utx
#exec OBJ LOAD FILE=Crosshairs.utx
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

class HUDKillingFloor extends HudBase
	config(User);

var int KFHUDAlpha;
var int GrainAlpha;

var float HealthBarFullVisDist, HealthBarCutoffDist;

var float DoorHealthViewDist;

var float BarLength, BarHeight;
var()   float			   HealthBarWidth,HealthBarHeight;

var() DigitSet DigitsBig;

var transient float MaxAmmoPrimary, CurAmmoPrimary, CurClipsPrimary;

var() SpriteWidget AmmoIcon;
var() SpriteWidget BulletIcon;
var() SpriteWidget DividerIcon;
var() SpriteWidget TorchBatteryIcon;
var() NumericWidget DigitsClipsLeft;
var() NumericWidget DigitsNumLeftInClip;

var()   Material			HealthBarBackMat;
var()   Material			HealthBarMat;

var() SpriteWidget GrenadeIcon;
//var () Material SpecRemIcon;
var() NumericWidget DigitsGrenade;

var transient Frag PlayerGrenade;

var() SpriteWidget HealthArmourBorderLeft;

var() SpriteWidget HealthMeter;
var() SpriteWidget ArmourMeter;
var() SpriteWidget BatteryMeter;

var() SpriteWidget CashIcon;
var() NumericWidget DigitsCash;

var() SpriteWidget ToolChargeMeter;

<<<<<<< HEAD
const MAXWEIGHT = 20;

var() SpriteWidget CarryMeter[MAXWEIGHT];
=======
//const MAXWEIGHT = 50; //why hardcap this in the first place though?

var() Material CarryIcon;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

const WEIGHTON_R=190;
const WEIGHTON_G=60;
const WEIGHTON_B=60;

const WEIGHTOFF_R=60;
const WEIGHTOFF_G=60;
const WEIGHTOFF_B=60;

var Material Portrait;
var float PortraitTime;
var float PortraitX;

var()Material VisionOverlay,GhostMat,NearDeathOverlay,FireOverlay;

var() Font LevelActionFontFont;
var() color LevelActionFontColor;

var bool bTorching; // is our light on?
var int AlphaAmount;

var() float LevelActionPositionX, LevelActionPositionY;

var class<DamageType> HUDHitDamage;
var bool DamageIsUber;

var ZoneInfo CurrentZone,LastZone;
var PhysicsVolume CurrentVolume,LastVolume;

var bool bZoneChanged;
var bool bTicksTurn;
var int ValueCheckOut;

var material LastWeaponMat;

var float NextModLogTime;

var bool bInitialDark;  // a variable that initializes the overlay as black so theres' no pop-in when it adjusts to the zone color
<<<<<<< HEAD
=======
var bool bHasFogTint; 
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

var () float VeterancyMatScaleFactor;   // Amount to scale all Veterancy indicators on the HUD by


var float CurrentR,CurrentG,CurrentB;
var float LastR,LastG,LastB;
var () float OverlayFadeSpeed;  // How quickly the HUD color overlay blends between zones.  default = 0.025
//var color FogColor;
var int NumCalls;

// KF Cinematic Subtitles

var string Subtitle;
var int SubIndex;
var float LastSubChangeTime;
var bool bGetNewSub,bDisplayDeathScreen;
var Actor GoalTarget;

var KFSPLevelInfo KFLevelRule;

// intro cinematic
var float   IntroTitleFade,DamageStartTime;
var float   Global_Delta;

var KFPlayerReplicationInfo KFPRI;
var KFGameReplicationInfo KFGRI;

var float NextStatsUdpTime,EndGameHUDTime,VomitHudTimer,DamageHUDTimer;
var ColorModifier MyColorMod;

<<<<<<< HEAD
=======
// Player Info List(Used to draw Name, Health, Armor, and Veterancy over players)
struct PlayerInfoPawnType
{
	var KFPawn	Pawn;
	var	float	PlayerInfoScreenPosX;
	var	float	PlayerInfoScreenPosY;
	var float	RendTime;
};
var	array<PlayerInfoPawnType>				PlayerInfoPawns;

var float DesaturationFactor, DarknessFactor;

var		float					LastDoorBarHealthUpdate;
var 	array<KFDoorMover>		DoorCache;

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated function PostBeginPlay()
{
	if( MyColorMod==None )
	{
		MyColorMod = ColorModifier(Level.ObjectPool.AllocateObject(class'ColorModifier'));
		MyColorMod.AlphaBlend = True;
		MyColorMod.Color.R = 255;
		MyColorMod.Color.B = 255;
		MyColorMod.Color.G = 255;
	}
	Super.PostBeginPlay();
	SetHUDAlpha();
	foreach DynamicActors(class'KFSPLevelInfo', KFLevelRule)
		Break;
<<<<<<< HEAD
}
=======
	if ( CustomCrosshairsAllowed() )
		SetCustomCrosshairs();
}

function bool CustomCrosshairsAllowed()
{
	return true;
}

function bool CustomCrosshairColorAllowed()
{
	return true;
}


// TODO Add support for custom crosshair scale to menus
function SetCustomCrosshairs()
{
	local int i;
	local array<CacheManager.CrosshairRecord> CustomCrosshairs;

	class'CacheManager'.static.GetCrosshairList(CustomCrosshairs);
	Crosshairs.Length = CustomCrosshairs.Length;
	for (i = 0; i < CustomCrosshairs.Length; i++)
	{
		Crosshairs[i].WidgetTexture = CustomCrosshairs[i].CrosshairTexture;

		Crosshairs[i].TextureCoords.X1 = 0;
		Crosshairs[i].TextureCoords.X2 = 64;
		Crosshairs[i].TextureCoords.Y1 = 0;
		Crosshairs[i].TextureCoords.Y2 = 64;

		Crosshairs[i].TextureScale = 0.75;
		Crosshairs[i].DrawPivot = DP_MiddleMiddle;
		Crosshairs[i].PosX = 0.5;
		Crosshairs[i].PosY = 0.5;
		Crosshairs[i].OffsetX = 0;
		Crosshairs[i].OffsetY = 0;
		Crosshairs[i].ScaleMode = SM_None;
		Crosshairs[i].Scale = 1.0;
		Crosshairs[i].RenderStyle = STY_Alpha;
	}

	if ( CustomCrosshairColorAllowed() )
		SetCustomCrosshairColors();
}

function SetCustomCrosshairColors()
{
	local int i, j;

	for (i = 0; i < Crosshairs.Length; i++)
		for (j = 0; j < 2; j++)
			Crosshairs[i].Tints[j] = CrosshairColor;
}


simulated function DrawCrosshair (Canvas C)
{
    local float NormalScale;
    local int i, CurrentCrosshair;
    local float OldScale,OldW, CurrentCrosshairScale;
    local color CurrentCrosshairColor;
	local SpriteWidget CHtexture;

    if (!bCrosshairShow)
        return;

	if ( bUseCustomWeaponCrosshairs && (PawnOwner != None) && (PawnOwner.Weapon != None) )
	{
		CurrentCrosshair = PawnOwner.Weapon.CustomCrosshair;
		if (CurrentCrosshair == -1 || CurrentCrosshair == Crosshairs.Length)
		{
//			log("Not drawing crosshair because it's -1 or "$Crosshairs.Length);
			return;
		}

		CurrentCrosshairColor = PawnOwner.Weapon.CustomCrosshairColor;
		CurrentCrosshairScale = PawnOwner.Weapon.CustomCrosshairScale;
		if ( PawnOwner.Weapon.CustomCrosshairTextureName != "" )
		{
			if ( PawnOwner.Weapon.CustomCrosshairTexture == None )
			{
				PawnOwner.Weapon.CustomCrosshairTexture = Texture(DynamicLoadObject(PawnOwner.Weapon.CustomCrosshairTextureName,class'Texture'));
				if ( PawnOwner.Weapon.CustomCrosshairTexture == None )
				{
					log(PawnOwner.Weapon$" custom crosshair texture not found!");
					PawnOwner.Weapon.CustomCrosshairTextureName = "";
				}
			}
			CHTexture = Crosshairs[0];
			CHTexture.WidgetTexture = PawnOwner.Weapon.CustomCrosshairTexture;
		}
	}
	else
	{
		CurrentCrosshair = CrosshairStyle;
		CurrentCrosshairColor = CrosshairColor;
		CurrentCrosshairScale = CrosshairScale;
	}

	CurrentCrosshair = Clamp(CurrentCrosshair, 0, Crosshairs.Length - 1);

    NormalScale = Crosshairs[CurrentCrosshair].TextureScale;
	if ( CHTexture.WidgetTexture == None )
		CHTexture = Crosshairs[CurrentCrosshair];
    CHTexture.TextureScale *= CurrentCrosshairScale;

    for( i = 0; i < ArrayCount(CHTexture.Tints); i++ )
        CHTexture.Tints[i] = CurrentCrossHairColor;

	if ( LastPickupTime > Level.TimeSeconds - 0.4 )
	{
		if ( LastPickupTime > Level.TimeSeconds - 0.2 )
			CHTexture.TextureScale *= (1 + 5 * (Level.TimeSeconds - LastPickupTime));
		else
			CHTexture.TextureScale *= (1 + 5 * (LastPickupTime + 0.4 - Level.TimeSeconds));
	}
    OldScale = HudScale;
    HudScale=1;
    OldW = C.ColorModulate.W;
    C.ColorModulate.W = 1;
    DrawSpriteWidget (C, CHTexture);
    C.ColorModulate.W = OldW;
	HudScale=OldScale;
    CHTexture.TextureScale = NormalScale;
}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated function Destroyed()
{
	if( MyColorMod!=None )
	{
		MyColorMod.AlphaBlend = MyColorMod.Default.AlphaBlend;
		MyColorMod.Material = None;
		MyColorMod.Color = MyColorMod.Default.Color;
		Level.ObjectPool.FreeObject(MyColorMod);
		MyColorMod = None;
	}
	Super.Destroyed();
}

// Take it out.
exec function ShowHud();

simulated function SetHUDAlpha()
{
<<<<<<< HEAD
	local byte i;

=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	AmmoIcon.Tints[0].A=KFHUDAlpha;
	AmmoIcon.Tints[1].A=KFHUDAlpha;
	BulletIcon.Tints[0].A=KFHUDAlpha;
	BulletIcon.Tints[1].A=KFHUDAlpha;
	BatteryMeter.Tints[0].A=KFHUDAlpha;
	BatteryMeter.Tints[1].A=KFHUDAlpha;
	DividerIcon.Tints[0].A=KFHUDAlpha;
	DividerIcon.Tints[1].A=KFHUDAlpha;
	DigitsClipsLeft.Tints[0].A=KFHUDAlpha;
	DigitsClipsLeft.Tints[1].A=KFHUDAlpha;
	DigitsNumLeftInClip.Tints[0].A=KFHUDAlpha;
	DigitsNumLeftInClip.Tints[1].A=KFHUDAlpha;
	GrenadeIcon.Tints[0].A=KFHUDAlpha;
	GrenadeIcon.Tints[1].A=KFHUDAlpha;
	TorchBatteryIcon.Tints[0].A=KFHUDAlpha;
	TorchBatteryIcon.Tints[0].A=KFHUDAlpha;
	DigitsGrenade.Tints[0].A=KFHUDAlpha;
	DigitsGrenade.Tints[1].A=KFHUDAlpha;
	HealthArmourBorderLeft.Tints[0].A=KFHUDAlpha;
	HealthArmourBorderLeft.Tints[1].A=KFHUDAlpha;
	HealthMeter.Tints[0].A=KFHUDAlpha;
	HealthMeter.Tints[1].A=KFHUDAlpha;
	ArmourMeter.Tints[0].A=KFHUDAlpha;
	ArmourMeter.Tints[1].A=KFHUDAlpha;
	CashIcon.Tints[0].A=KFHUDAlpha;
	CashIcon.Tints[1].A=KFHUDAlpha;
	DigitsCash.Tints[0].A=KFHUDAlpha;
	DigitsCash.Tints[1].A=KFHUDAlpha;
	ToolChargeMeter.Tints[0].A=KFHUDAlpha;
	ToolChargeMeter.Tints[1].A=KFHUDAlpha;
<<<<<<< HEAD

	for(i=0; i<KFHumanPawn(PawnOwner).MaxCarryWeight; ++i)
	{
		CarryMeter[i].Tints[0].A=KFHUDAlpha;
		CarryMeter[i].Tints[1].A=KFHUDAlpha;
	}
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

simulated function Tick(float deltaTime)
{
	local Material NewPortrait;

	if( KFGameReplicationInfo(Level.GRI)!=None && KFGameReplicationInfo(Level.GRI).EndGameType>0 && EndGameHUDTime<1 )
		EndGameHUDTime+=(deltaTime/3.f);
	Super.Tick(deltaTime);

	Global_Delta = DeltaTime;

   	if ( (Level.TimeSeconds - LastPlayerIDTalkingTime < 0.1) && (PlayerOwner.GameReplicationInfo != None) )
	{
		if ( (PortraitPRI == None) || (PortraitPRI.PlayerID != LastPlayerIDTalking) )
		{
			PortraitPRI = PlayerOwner.GameReplicationInfo.FindPlayerByID(LastPlayerIDTalking);
			if ( PortraitPRI != None )
			{
				NewPortrait = PortraitPRI.GetPortrait();
				if ( NewPortrait != None )
				{
					if ( Portrait == None )
						PortraitX = 1;
					Portrait = NewPortrait;
					PortraitTime = Level.TimeSeconds + 3;
				}
			}
		}
		else
			PortraitTime = Level.TimeSeconds + 0.2;
	}
	else
		LastPlayerIDTalking = 0;

	if ( PortraitTime - Level.TimeSeconds > 0 )
		PortraitX = FMax(0,PortraitX-3*deltaTime);
	else if ( Portrait != None )
	{
		PortraitX = FMin(1,PortraitX+3*deltaTime);
		if ( PortraitX == 1 )
		{
			Portrait = None;
			PortraitPRI = None;
		}
	}
	
	
	// update flashlight info
<<<<<<< HEAD

	 if (PlayerOwner != none && PlayerOwner.Pawn != none)
	{
	  if (PlayerOwner.pawn.Weapon != none && KFWeapon(PlayerOwner.pawn.Weapon).FlashLight != none)
	  bTorching = KFWeapon(PlayerOwner.pawn.Weapon).FlashLight.bHasLight ;
	}
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	
	if ( PawnOwner != None && PawnOwner.PlayerReplicationInfo != None )
		KFPRI = KFPlayerReplicationInfo(PawnOwner.PlayerReplicationInfo);
		
	if ( KFGRI == None && PlayerOwner.GameReplicationInfo != None )
		KFGRI = KFGameReplicationInfo(PlayerOwner.GameReplicationInfo);
}

function DrawCustomBeacon(Canvas C, Pawn P, float ScreenLocX, float ScreenLocY)
{
<<<<<<< HEAD
=======
	local int i;
	local KFPawn KFP;

	KFP = KFPawn(P);

	if ( KFP == none || PawnOwner == none ||
		 KFP.PlayerReplicationInfo == none || PawnOwner.PlayerReplicationInfo == none ||
		 KFP.PlayerReplicationInfo.Team != PawnOwner.PlayerReplicationInfo.Team )
	{
		return;
	}

	for ( i = 0; i < PlayerInfoPawns.Length; i++ )
	{
		if ( PlayerInfoPawns[i].Pawn == P )
		{
			PlayerInfoPawns[i].PlayerInfoScreenPosX = ScreenLocX;
			PlayerInfoPawns[i].PlayerInfoScreenPosY = ScreenLocY;
			PlayerInfoPawns[i].RendTime = Level.TimeSeconds + 0.1;
			return;
		}
	}

	i = PlayerInfoPawns.Length;
	PlayerInfoPawns.Length = i + 1;
	PlayerInfoPawns[i].Pawn = KFP;
	PlayerInfoPawns[i].PlayerInfoScreenPosX = ScreenLocX;
	PlayerInfoPawns[i].PlayerInfoScreenPosY = ScreenLocY;
	PlayerInfoPawns[i].RendTime = Level.TimeSeconds + 0.1;
}

function DrawPlayerInfo(Canvas C, Pawn P, float ScreenLocX, float ScreenLocY)
{
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	local float XL,YL;
	local float Dist;
	local byte BeaconAlpha;
	local float OldZ;
	local Class<KFVeterancyTypes> VE;
	local Material M;
	local int MW;

	if( P.PlayerReplicationInfo==none || KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).bViewingMatineeCinematic )
		return;

	Dist = vsize(P.Location - PlayerOwner.CalcViewLocation);
	Dist -= HealthBarFullVisDist;
	Dist = FClamp(Dist, 0, HealthBarCutoffDist-HealthBarFullVisDist);
	Dist = Dist/(HealthBarCutoffDist-HealthBarFullVisDist);
	BeaconAlpha = byte((1.f-Dist)*255.f);

	if(BeaconAlpha == 0)
		return;

	OldZ = C.Z;
<<<<<<< HEAD
	C.Z = 2;
=======
	C.Z = 1.0;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	C.Style = ERenderStyle.STY_Alpha;
	C.SetDrawColor(255,255,255,BeaconAlpha);

	C.Font = GetConsoleFont(C); //GetFontSizeIndex(C, 1);

	C.StrLen(P.PlayerReplicationInfo.PlayerName, XL, YL);
	C.SetPos(ScreenLocX - 0.5*XL , ScreenLocY -YL);//- 0.125 * BeaconTex.VSize - YL);
	C.DrawTextClipped(P.PlayerReplicationInfo.PlayerName,true);

	if( KFPlayerReplicationInfo(P.PlayerReplicationInfo)!=None )
	{
		VE = KFPlayerReplicationInfo(P.PlayerReplicationInfo).ClientVeteranSkill;
		if( VE!=None )
		{
			M = VE.Default.OnHUDIcon;
			MW = 36.f*VeterancyMatScaleFactor;
			if( M!=None )
			{
				C.SetPos(ScreenLocX - FClamp(XL/2,BarLength/2,500.f)-50,ScreenLocY-YL-18);    // -31
				C.DrawTile(M,MW,MW,0,0,M.MaterialUSize(),M.MaterialVSize());
			}
			M = VE.Default.SubHUDIcon;
			if( M!=None )
			{
				C.SetPos(ScreenLocX - FClamp(XL/2,BarLength/2,500.f)-50,ScreenLocY-YL-8);
				C.DrawTile(M,MW,MW,0,0,M.MaterialUSize(),M.MaterialVSize());
			}
		}
	}

	// Health
	if (P.Health > 0)
		DrawKFBar(C, ScreenLocX, (ScreenLocY - YL)-0.5*BarHeight, FClamp(P.Health/P.HealthMax,0,1), BeaconAlpha);
	// Armor
	if (P.ShieldStrength > 0)
		DrawKFBar(C, ScreenLocX, (ScreenLocY - YL)-1.5*BarHeight, FClamp(P.ShieldStrength/100.f,0,1), BeaconAlpha, true);
	C.Z = OldZ;
}

simulated function DrawKFBar(Canvas C, float XCentre, float YCentre, float BarPercentage, byte BarAlpha, optional bool bArmor)
{
	local float BorderWidth;
	local int InnerBarLength, TexLength;

	C.SetDrawColor(255,255,255,BarAlpha);
	C.SetPos(XCentre - 0.5*BarLength , YCentre-0.5*BarHeight );
	C.DrawTileClipped(Texture'KFKillMeNow.KFHUDIcons', BarLength, BarHeight, 37,204, 217,21);
	BorderWidth = (BarLength/217.0)*4;

	if (bArmor)
		C.SetDrawColor(25,200,230,BarAlpha);
	else C.SetDrawColor(255,0,0,BarAlpha);
	C.SetPos( (XCentre - 0.5*BarLength)+BorderWidth , YCentre-0.5*BarHeight );
	InnerBarLength = (BarLength-BorderWidth) * BarPercentage;
	TexLength = 209* BarPercentage;
	C.DrawTileClipped(Texture'KFKillMeNow.KFHUDIcons', InnerBarLength, BarHeight, 41,146, TexLength,17);
}

simulated function DrawHud( Canvas C )
{
	local KFGameReplicationInfo CurrentGame;
<<<<<<< HEAD
=======
	local rotator CamRot;
	local vector CamPos, ViewDir;
	local int i;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
  
	if (KFGameType(PlayerOwner.Level.Game) != none)
		CurrentGame = KFGameReplicationInfo(PlayerOwner.Level.GRI);

	if ( FontsPrecached < 2 )
		PrecacheFonts(C);
	Super(HUD).DrawHud(C);

	UpdateHud();

<<<<<<< HEAD
=======
	PassStyle = STY_Modulated;
	DrawModOverlay(C);

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	if (!KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).bViewingMatineeCinematic)
	{
		if( bShowTargeting )
			DrawTargeting(C);

<<<<<<< HEAD
		PassStyle = STY_Alpha;
		DrawDamageIndicators(C);
		DrawHudPassA(C);
		PassStyle = STY_Additive;
		DrawHudPassB(C);
		PassStyle = STY_Alpha;
=======
		// Grab our View Direction
		C.GetCameraLocation(CamPos,CamRot);
		ViewDir = vector(CamRot);

		// Draw the Name, Health, Armor, and Veterancy above other players
		for ( i = 0; i < PlayerInfoPawns.Length; i++ )
		{
			if ( PlayerInfoPawns[i].Pawn != none && PlayerInfoPawns[i].Pawn.Health > 0 && (PlayerInfoPawns[i].Pawn.Location - PawnOwner.Location) dot ViewDir > 0.8 &&
				 PlayerInfoPawns[i].RendTime > Level.TimeSeconds )
			{
				DrawPlayerInfo(C, PlayerInfoPawns[i].Pawn, PlayerInfoPawns[i].PlayerInfoScreenPosX, PlayerInfoPawns[i].PlayerInfoScreenPosY);
			}
			else
			{
				PlayerInfoPawns.Remove(i--, 1);
			}
		}

		PassStyle = STY_Alpha;
		DrawDamageIndicators(C);
		DrawHudPassA(C);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		DrawHudPassC(C);
		if( KFPlayerController(PlayerOwner)!=None && KFPlayerController(PlayerOwner).ActiveNote!=None )
		{
			if( PlayerOwner.Pawn==None )
				KFPlayerController(PlayerOwner).ActiveNote = None;
			else KFPlayerController(PlayerOwner).ActiveNote.RenderNote(C);
		}
		PassStyle = STY_None;
<<<<<<< HEAD
		DrawHudPassD(C);
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		DisplayLocalMessages(C);
		DrawWeaponName(C);
		DrawVehicleName(C);
	
		PassStyle = STY_Modulated;
		if( KFGameReplicationInfo(Level.GRI)!=None && KFGameReplicationInfo(Level.GRI).EndGameType>0 )
		{
			if( KFGameReplicationInfo(Level.GRI).EndGameType==2 )
			{
				DrawEndGameHUD(C,True);
				Return;
			}
			else DrawEndGameHUD(C,False);
		}
		DrawKFHUDTextElements(C);
	}
<<<<<<< HEAD
	PassStyle = STY_Modulated;
	DrawModOverlay(C);
=======

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	if (KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).bViewingMatineeCinematic)
	{
		PassStyle = STY_Alpha;
		DrawCinematicHUD(C);
	}  
}

simulated function DrawHealthBar(Canvas C, Actor A, int Health, int MaxHealth, float Height)
{
	local vector		CameraLocation, CamDir, TargetLocation, HBScreenPos;
	local rotator	   CameraRotation;
	local float		 Dist, HealthPct;
	local color		 OldDrawColor;

	// rjp --  don't draw the health bar if menus are open
	// exception being, the Veterancy menu

	if ( PlayerOwner.Player.GUIController.bActive && GUIController(PlayerOwner.Player.GUIController).ActivePage.Name !=
        'GUIVeterancyBinder')
		return;

	OldDrawColor = C.DrawColor;

	C.GetCameraLocation( CameraLocation, CameraRotation );
	TargetLocation = A.Location + vect(0,0,1) * Height;
	Dist = VSize(TargetLocation - CameraLocation);

	// Check Distance Threshold
	if (Dist > HealthBarCutoffDist)
		return;

	CamDir  = vector(CameraRotation);

	// Target is located behind camera
	HBScreenPos = C.WorldToScreen(TargetLocation);
	if ((TargetLocation - CameraLocation) dot CamDir < 0 || HBScreenPos.X <= 0 || HBScreenPos.X >= C.SizeX || HBScreenPos.Y <= 0 || HBScreenPos.Y >= C.SizeY)
	{
		TargetLocation = A.Location + vect(0,0,1) * (A.CollisionHeight * 2);
		if ((TargetLocation - CameraLocation) dot CamDir < 0)
			return;
		HBScreenPos = C.WorldToScreen(TargetLocation);
		if (HBScreenPos.X <= 0 || HBScreenPos.X >= C.ClipX || HBScreenPos.Y <= 0 || HBScreenPos.Y >= C.ClipY)
			return;
	}

	if (FastTrace(TargetLocation, CameraLocation))
	{
		C.DrawColor = WhiteColor;
		C.SetPos(HBScreenPos.X - HealthBarWidth * 0.5, HBScreenPos.Y );
		C.DrawTileStretched(HealthBarBackMat, HealthBarWidth, HealthBarHeight);

		HealthPct = 1.0f * Health / MaxHealth;

	        C.DrawColor = RedColor;
        /*
        	if (HealthPct < 0.35)
			C.DrawColor = RedColor;
		else if (HealthPct < 0.70)
			C.DrawColor = GoldColor;
		else
			C.DrawColor = GreenColor;
        */

		C.SetPos(HBScreenPos.X - HealthBarWidth * 0.5, HBScreenPos.Y );
		C.DrawTileStretched(HealthBarMat, (HealthBarWidth * HealthPct) + 15, HealthBarHeight);
	}
	C.DrawColor = OldDrawColor;
}


simulated function FindPlayerGrenade()
{
	local inventory inv;
	local class<Ammunition> AmmoClass;

	for(inv=PawnOwner.inventory; inv!=none; inv=inv.Inventory)
	{
		if(Frag(inv)!=none)
		{
			PlayerGrenade = Frag(inv);
			AmmoClass = PlayerGrenade.GetAmmoClass(0);
		}
	}
}

simulated function UpdateHud()
{
	local float MaxGren, CurGren;
<<<<<<< HEAD
	local int i;
	local float BatLife;
=======

	if( PawnOwner == none )
	{
		super.UpdateHud();
		return;
	}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	CalculateAmmo();
	DigitsClipsLeft.Value=CurClipsPrimary;

<<<<<<< HEAD
	if( KFHumanPawn(pawnowner)!=none )
		BatLife = KFHumanPawn(pawnowner).TorchBatteryLife;
	
	if (PawnOwner.Weapon != none) 
		DigitsNumLeftInClip.Value=kfWeapon(PawnOwner.Weapon).ClipLeft;
=======
	if (PawnOwner.Weapon!=None) 
		if (KFWeapon(PawnOwner.Weapon)!=None)
			DigitsNumLeftInClip.Value=kfWeapon(PawnOwner.Weapon).ClipLeft;
		else DigitsNumLeftInClip.Value = CurAmmoPrimary;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	if (DigitsNumLeftInClip.Value < 0)
		DigitsNumLeftInClip.Value = 0;

	if(PlayerGrenade==none)
		FindPlayerGrenade();

	if(PlayerGrenade!=none)
	{
		PlayerGrenade.GetAmmoCount(MaxGren,CurGren);
		DigitsGrenade.Value=CurGren;
	}

	HealthMeter.Scale = pawnowner.Health / pawnowner.HealthMax;
	ArmourMeter.Scale = xPawn(pawnowner).ShieldStrength / 100;
<<<<<<< HEAD
	BatteryMeter.Scale = BatLife / KFHumanPawn(pawnowner).default.TorchBatteryLife;

	for(i=0; i<KFHumanPawn(PawnOwner).MaxCarryWeight; ++i)
	{
		if(i< KFHumanPawn(PawnOwner).CurrentWeight )
		{
			CarryMeter[i].Tints[0].R = WEIGHTON_R;
			CarryMeter[i].Tints[1].R = WEIGHTON_R;
			CarryMeter[i].Tints[0].G = WEIGHTON_G;
			CarryMeter[i].Tints[1].G = WEIGHTON_G;
			CarryMeter[i].Tints[0].B = WEIGHTON_B;
			CarryMeter[i].Tints[1].B = WEIGHTON_B;
		}
		else
		{
			CarryMeter[i].Tints[0].R = WEIGHTOFF_R;
			CarryMeter[i].Tints[1].R = WEIGHTOFF_R;
			CarryMeter[i].Tints[0].G = WEIGHTOFF_G;
			CarryMeter[i].Tints[1].G = WEIGHTOFF_G;
			CarryMeter[i].Tints[0].B = WEIGHTOFF_B;
			CarryMeter[i].Tints[1].B = WEIGHTOFF_B;
		}

	}
=======
	if(KFHumanPawn(PawnOwner)!=None)
		BatteryMeter.Scale = float(KFHumanPawn(PawnOwner).TorchBatteryLife) / float(KFHumanPawn(pawnowner).default.TorchBatteryLife);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	// "Poison" the health meter
	if ( VomitHudTimer>Level.TimeSeconds )
	{
		HealthMeter.Tints[0].R = 25;
		HealthMeter.Tints[0].G = 255;
		HealthMeter.Tints[0].B = 25;
	
		HealthMeter.Tints[1].R = 25;
		HealthMeter.Tints[1].G = 255;
		HealthMeter.Tints[1].B = 25;
	}
	else
	{
		HealthMeter.Tints[0].R = 255;
		HealthMeter.Tints[0].G = 255;
		HealthMeter.Tints[0].B = 255;
	
		HealthMeter.Tints[1].R = 255;
		HealthMeter.Tints[1].G = 255;
		HealthMeter.Tints[1].B = 255;
	}

	DigitsCash.Value=PawnOwnerPRI.Score;
	ToolChargeMeter.Scale=CurAmmoPrimary/MaxAmmoPrimary;
	Super.UpdateHud();
}

<<<<<<< HEAD
simulated function CalculateAmmo()
=======
simulated function CalculateAmmo() //Revised to work with UT2004 weapons as well as KF ones.
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
{
	MaxAmmoPrimary = 1;
	CurAmmoPrimary = 1;

<<<<<<< HEAD
	if(PawnOwner.Weapon == none)
		return;

	if ( (PawnOwner != none) && (PawnOwner.Weapon != none) )
		PawnOwner.Weapon.GetAmmoCount(MaxAmmoPrimary,CurAmmoPrimary);
		
	CurClipsPrimary = (CurAmmoPrimary - kfWeapon(PawnOwner.Weapon).ClipLeft) / kfWeapon(PawnOwner.Weapon).ClipCount;

	// count the partial clip if there is one
	if((CurAmmoPrimary - kfWeapon(PawnOwner.Weapon).ClipLeft) % kfWeapon(PawnOwner.Weapon).ClipCount > 0 )
		CurClipsPrimary+=1;
	if (CurClipsPrimary < 0)   
		CurClipsPrimary = 0;
}

=======
	if ( PawnOwner == None || KFWeapon(PawnOwner.Weapon) == none )
		return;

	PawnOwner.Weapon.GetAmmoCount(MaxAmmoPrimary,CurAmmoPrimary);

	if(KFWeapon(PawnOwner.Weapon) != None )
	{
		if( KFWeapon(PawnOwner.Weapon).bHoldToReload )
		{
			CurClipsPrimary = Max(CurAmmoPrimary-KFWeapon(PawnOwner.Weapon).ClipLeft,0); // Single rounds reload, just show the true ammo count.
			return;
		}
			
		CurClipsPrimary = (CurAmmoPrimary - kfWeapon(PawnOwner.Weapon).ClipLeft) / kfWeapon(PawnOwner.Weapon).ClipCount;

		// count the partial clip if there is one
		if((CurAmmoPrimary - kfWeapon(PawnOwner.Weapon).ClipLeft) % kfWeapon(PawnOwner.Weapon).ClipCount > 0 )
			CurClipsPrimary+=1;
		if (CurClipsPrimary < 0)   
			CurClipsPrimary = 0;
	}
}


>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated function DrawHudPassA (Canvas C)
{
	local class<Ammunition> AmmoClass;
	local int i;
	local Material Ma;
	local class<KFVeterancyTypes> VE;
	local int MW,MH;

<<<<<<< HEAD
	//  if( bShowWeaponInfo && (PawnOwner.Weapon != None) )
	if((PawnOwner.Weapon != None) )
=======
	DrawDoorHealthBars(C);

	//  if( bShowWeaponInfo && (PawnOwner.Weapon != None) )
	if((PawnOwner != none && PawnOwner.Weapon != None) )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	{
		AmmoClass = PawnOwner.Weapon.GetAmmoClass(0);
		if( (AmmoClass != None) || Syringe(PawnOwner.Weapon)!=None )
		{
			if( KFWeapon(PawnOwner.Weapon)!=none && KFWeapon(PawnOwner.Weapon).bAmmoHUDAsBar )
				DrawSpriteWidget(C, ToolChargeMeter);
			else
			{
				DrawSpriteWidget (C, AmmoIcon);
				DrawSpriteWidget (C, BulletIcon);
<<<<<<< HEAD
				DrawSpriteWidget (C, DividerIcon);
				DrawNumericWidget (C, DigitsClipsLeft, DigitsBig);
=======
				if(KFWeapon(PawnOwner.Weapon)!=none)
				{
					DrawSpriteWidget (C, DividerIcon);
					DrawNumericWidget (C, DigitsClipsLeft, DigitsBig);
				}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
				DrawNumericWidget (C, DigitsNumLeftInClip, DigitsBig);
			}
		}
	}
<<<<<<< HEAD
	if( KFPawn(PawnOwner)!=None )
		KFPawn(PawnOwner).GetVeteran().Static.SpecialHUDInfo(C);
  
	// Torch
	if (bTorching)
=======
	if( KFPawn(PawnOwner)!=None && KFPawn(PawnOwner).GetVeteran() != None )
		KFPawn(PawnOwner).GetVeteran().Static.SpecialHUDInfo(C);
  
	// Torch

	if ( KFWeapon(PawnOwner.Weapon) != none && KFWeapon(PawnOwner.Weapon).bTorchEnabled )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	{
		DrawSpriteWidget (C, BatteryMeter);
		DrawSpriteWidget (C, TorchBatteryIcon);
	}
<<<<<<< HEAD
=======

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	// Grenade counter
	if(PlayerGrenade!=none)
	{
		DrawSpriteWidget (C, GrenadeIcon);
		DrawNumericWidget (C, DigitsGrenade, DigitsBig);
	}

	DrawSpriteWidget(C, HealthArmourBorderLeft);
	DrawSpriteWidget (C, HealthMeter);
	DrawSpriteWidget (C, ArmourMeter);

        if (KFSGameReplicationInfo(PlayerOwner.GameReplicationInfo) != none &&
        !KFSGameReplicationInfo(PlayerOwner.GameReplicationInfo).bHUDShowCash)
        {
        }
        else
        {
	 DrawSpriteWidget(C, CashIcon);
	 DrawNumericWidget(C, DigitsCash, DigitsBig);
        }

<<<<<<< HEAD
	for( i=0; i<KFHumanPawn(PawnOwner).MaxCarryWeight; i++ )
		DrawSpriteWidget( C, CarryMeter[i] );
=======
	//10x easier and faster than using spritewidgets, also allows for more weight than the stock capped 20 - by YoYoBatty
	if(KFHumanPawn(PawnOwner)!=None)
	{
		for( i=0; i<KFHumanPawn(PawnOwner).MaxCarryWeight; i++ )
		{
			if(i < KFHumanPawn(PawnOwner).CurrentWeight )
			{
				C.DrawColor.R = WEIGHTON_R;
				C.DrawColor.G = WEIGHTON_G;
				C.DrawColor.B = WEIGHTON_B;
			}
			else
			{
				C.DrawColor.R = WEIGHTOFF_R;
				C.DrawColor.G = WEIGHTOFF_G;
				C.DrawColor.B = WEIGHTOFF_B;
			}
			//C.DrawColor.R = WEIGHTOFF_R;
			//C.DrawColor.G = WEIGHTOFF_G;
			//C.DrawColor.B = WEIGHTOFF_B;

			C.SetPos(C.ClipX*0.97,C.ClipY*0.87 - (i*34)); //draws it right above the nade left icon, just like original
			C.DrawTile(CarryIcon,27,35,210,65,35,63); //nice and clean, gets the full icon size too
		}
	}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	if( KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo)!=None )
	{
		VE = KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).ClientVeteranSkill;
		if( VE!=None )
		{
			C.DrawColor.R = 255;
<<<<<<< HEAD
			C.DrawColor.B = 255;
			C.DrawColor.G = 255;
=======
			C.DrawColor.G = 255;
			C.DrawColor.B = 255;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
			C.DrawColor.A = 255;

			Ma = VE.Default.OnHUDIcon;
			
			MW = 36;

			MW *= VeterancyMatScaleFactor * 1.4;   // Should always be larger on the HUD
			MH = MW;

			if( Ma!=None )
			{
				C.SetPos(C.ClipX/56,C.ClipY*0.95-85);
				C.DrawTile(Ma,MW,MH,0,0,Ma.MaterialUSize(),Ma.MaterialVSize());  // 36
			}
			Ma = VE.Default.SubHUDIcon;
			if( Ma!=None )
			{
				C.SetPos(C.ClipX/56,C.ClipY*0.95-85);
				C.DrawTile(Ma,MW,MH,0,0,Ma.MaterialUSize(),Ma.MaterialVSize());
			}
		}
	}
}

simulated event PostRender( canvas Canvas )
{
	local float XPos, YPos;
	local plane OldModulate;
	local color OldColor;
	local int i;

	BuildMOTD();

	OldModulate = Canvas.ColorModulate;
	OldColor = Canvas.DrawColor;

	Canvas.ColorModulate.X = 1;
	Canvas.ColorModulate.Y = 1;
	Canvas.ColorModulate.Z = 1;
	Canvas.ColorModulate.W = HudOpacity/255;

	LinkActors();

	ResScaleX = Canvas.SizeX / 640.0;
	ResScaleY = Canvas.SizeY / 480.0;

	CheckCountDown(PlayerOwner.GameReplicationInfo);

	if ( PawnOwner != None )
	{
		if ( !PlayerOwner.bBehindView )
		{
			if ( PlayerOwner.bDemoOwner || ((Level.NetMode == NM_Client) && (PlayerOwner.Pawn != PawnOwner)) )
				PawnOwner.GetDemoRecordingWeapon();
			else
				CanvasDrawActors( Canvas, false );
		}
		else
			CanvasDrawActors( Canvas, false );
	}

	if ( PawnOwner != None && PawnOwner.bSpecialHUD )
		PawnOwner.DrawHud(Canvas);
	if ( bShowDebugInfo )
	{
		Canvas.Font = GetConsoleFont(Canvas);
		Canvas.Style = ERenderStyle.STY_Alpha;
		Canvas.DrawColor = ConsoleColor;

		PlayerOwner.ViewTarget.DisplayDebug(Canvas, XPos, YPos);
<<<<<<< HEAD
=======
		DrawHeadShotSphere();
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		if (PlayerOwner.ViewTarget != PlayerOwner && (Pawn(PlayerOwner.ViewTarget) == None || Pawn(PlayerOwner.ViewTarget).Controller == None))
		{
			YPos += XPos * 2;
			Canvas.SetPos(4, YPos);
			Canvas.DrawText("----- VIEWER INFO -----");
			YPos += XPos;
			Canvas.SetPos(4, YPos);
			PlayerOwner.DisplayDebug(Canvas, XPos, YPos);
		}
	}
	else
	{
		if ( bShowLocalStats )
		{
			if( NextStatsUdpTime<Level.TimeSeconds )
			{
				NextStatsUdpTime = Level.TimeSeconds+30; // Update stats once a 30 seconds while being watched.
				KFPlayerController(PlayerOwner).UpdateStatsScreen();
			}
			DrawClientStats(Canvas);
		}
		if ( (PlayerOwner == None) || (PawnOwner == None) || (PawnOwnerPRI == None) || (PlayerOwner.IsSpectating() && PlayerOwner.bBehindView) )
			DrawSpectatingHud(Canvas);
		else if( !PawnOwner.bHideRegularHUD )
			DrawHud(Canvas);

		for (i = 0; i < Overlays.length; i++)
			Overlays[i].Render(Canvas);

		if( !DrawLevelAction(Canvas) )
		{
			if (PlayerOwner!=None)
			{
				if (PlayerOwner.ProgressTimeOut > Level.TimeSeconds)
					DisplayProgressMessages (Canvas);
				else if (MOTDState==1)
					MOTDState=2;
			}
		}

		if (bShowBadConnectionAlert)
			DisplayBadConnectionAlert(Canvas);
		DisplayMessages(Canvas);
		if( bShowVoteMenu && VoteMenu!=None )
			VoteMenu.RenderOverlays(Canvas);
	}

	PlayerOwner.RenderOverlays(Canvas);

	if ((PlayerConsole != None) && PlayerConsole.bTyping)
		DrawTypingPrompt(Canvas, PlayerConsole.TypedStr, PlayerConsole.TypedStrPos);

	Canvas.ColorModulate=OldModulate;
	Canvas.DrawColor = OldColor;
	OnPostRender(Self, Canvas);
}

function CanvasDrawActors( Canvas C, bool bClearedZBuffer )
{
	if ( !PlayerOwner.bBehindView && PawnOwner.Weapon != None )
	{
		if ( !bClearedZBuffer)
			C.DrawActor(None, false, true); // Clear the z-buffer here

		//TODO: only draw one when suitably prepared
		if( KFPawn(PawnOwner).SecondaryItem!=none)
			KFPawn(PawnOwner).SecondaryItem.RenderOverlays( C );
		else PawnOwner.Weapon.RenderOverlays( C );
	}
}

simulated function DrawKFHUDTextElements(Canvas C)
{
	local float XL,YL;
	local int NumZombies,Min;
	local string S;

	// Countdown Text
	if(!PlayerOwner.GameReplicationInfo.bMatchHasBegun || PlayerOwner.GameReplicationInfo == none)
		return;

	if (KFHumanPawn(PlayerOwner.Pawn) != none)
		AlphaAmount = KFHumanPawn(PlayerOwner.Pawn).AlphaAmount;

	if(!KFGameReplicationInfo(PlayerOwner.GameReplicationInfo).bWaveInProgress)
	{
		C.SetDrawColor(255,255,255,KFHUDAlpha);
		C.Font = LoadFont(7);

		if (KFGameReplicationInfo(PlayerOwner.GameReplicationInfo).TimeToNextWave > 5)
			C.SetDrawColor(255,255,255,KFHUDAlpha);
		else C.SetDrawColor(255,50,50,KFHUDAlpha);

		NumZombies = KFGameReplicationInfo(PlayerOwner.GameReplicationInfo).TimeToNextWave;
		Min = NumZombies/60;
		NumZombies-=Min*60;
		S = Eval((Min>=10),string(Min),"0"$Min)$":"$Eval((NumZombies>=10),string(NumZombies),"0"$NumZombies);
		C.SetPos(C.ClipX-128,2);
		C.DrawTile(Material'KFKillMeNow.TimeRemainingIcon',128,128,0,0,256,256);
		C.Strlen(S,XL,YL);
		C.SetPos(C.ClipX-64-(XL/2),66-YL/2);
		C.DrawText(S,False);
	}
	else
	{
		C.Font = LoadFont(1);

		S = string(KFGameReplicationInfo(PlayerOwner.GameReplicationInfo).MaxMonsters);
		C.SetPos(C.ClipX-128,2);
		C.SetDrawColor(255,255,255,KFHUDAlpha);
		C.DrawTile(Material'KFKillMeNow.SpecRemainingIcon',128,128,0,0,256,256);

		if( KFGameReplicationInfo(PlayerOwner.GameReplicationInfo).MaxMonsters>5 )
			C.SetDrawColor(255,255,80,KFHUDAlpha);
		else C.SetDrawColor(255,50,50,KFHUDAlpha);

		C.Strlen(S,XL,YL);
		C.SetPos(C.ClipX-64-(XL/2),66-YL/2);
		C.DrawText(S);
	}
}

simulated function Timer()
{
	if (KFLevelRule != none && !KFLevelRule.bUseVisionOverlay)
		return;

	if (bZoneChanged)
	{
		// Lets get the facts straight, first.
		if (CurrentZone != none)
		{
			CurrentR = CurrentZone.DistanceFogColor.R ;
			CurrentG = CurrentZone.DistanceFogColor.G ;
			CurrentB = CurrentZone.DistanceFogColor.B ;
		}
		else if (CurrentVolume != none)
		{
			CurrentR = CurrentVolume.DistanceFogColor.R ;
			CurrentG = CurrentVolume.DistanceFogColor.G ;
			CurrentB = CurrentVolume.DistanceFogColor.B ;
		}
		else return;

		// Do we even need to tally up, or we sorted?
		if( LastR==CurrentR && LastG==CurrentG && LastB==CurrentB )
		{
			bZoneChanged = false;
			bTicksTurn = false;
			return;
		}
		// Now to even them out.
		if (ValueCheckOut < 3)
		{
			if (LastR < CurrentR)
				LastR += (Round(Abs(LastR-CurrentR) * 0.1) + 0.0625);
			else if (LastR > CurrentR)
				LastR -= (Round(Abs(LastR-CurrentR) * 0.1) + 0.0625);

			if (LastG < CurrentG)
				LastG += (Round(Abs(LastG-CurrentG) * 0.1) + 0.0625);
			else if (LastG > CurrentG)
				LastG -= (Round(Abs(LastG-CurrentG) * 0.1) + 0.0625);

			if (LastB < CurrentB)
				LastB += (Round(Abs(LastB-CurrentB) * 0.1) + 0.0625);
			else if (LastB > CurrentB)
				LastB -= (Round(Abs(LastB-CurrentB) * 0.1) + 0.0625);
			ValueCheckOut = 3;
		}
		// Bounce back 'atcha to display the result of my maths!
		if (ValueCheckOut == 3)
			bTicksTurn = false;
		// Joy , we're all sorted. Time to alert The Canvas.
	}
}

// "Mood" overlay. 
// : By Alex
// Simulates post process 
// This is my finest achievement! It basically Blends between
// ZoneInfo DistanceFog R G B   colorvalues  and applies that
// information to the DrawColor of the Screen overlay

simulated function DrawModOverlay( Canvas C )
{
<<<<<<< HEAD
	local float MaxRBrighten,MaxGBrighten,MaxBBrighten;
=======
	local int FinalR, FinalG, FinalB, FinalAlpha;
	local int MaxRBrighten, MaxGBrighten, MaxBBrighten;
	local int BaseR, BaseG, BaseB;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	C.SetPos(0,0);

	// We want the overlay to start black, and fade in, almost like the player opened their eyes
	// BrightFactor = 1.5;   // Not too bright.  Not too dark.  Livens things up just abit
	// Hook for Optional Vision overlay.  - Alex
	if (VisionOverlay != none )
	{
		if( PlayerOwner == none || PlayerOwner.PlayerReplicationInfo == none || PlayerOwner.PlayerReplicationInfo.bOnlySpectator )
			return;

		// If critical, pulsate.  otherwise, dont.
<<<<<<< HEAD
=======
		/* 
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		if( PlayerOwner.Pawn!=none && PlayerOwner.Pawn.Health>0 )
		{
			if (PlayerOwner.pawn.Health < PlayerOwner.pawn.HealthMax * 0.25)
				VisionOverlay = NearDeathOverlay;
			else if (KFPawn(PlayerOwner.pawn).BurnDown > 0)
				VisionOverlay = FireOverlay;
			else VisionOverlay = default.VisionOverlay; 
		}
<<<<<<< HEAD


		// Dead Players see Red
		if( PlayerOwner.PlayerReplicationInfo.bOutOfLives || PlayerOwner.PlayerReplicationInfo.bIsSpectator )
		{
			if( !bDisplayDeathScreen )
				Return;
			if( PlayerOwner.ViewTarget!=GoalTarget || GoalTarget==None )
				bDisplayDeathScreen = False;
=======
		*/
		//Desaturate from 100 to 0 health, darken at 50 health and lower
		if (PlayerOwner.Pawn != None && PlayerOwner.Pawn.Health > 0)
			DesaturationFactor = 0.5 + 0.5 * (float(PlayerOwner.Pawn.Health) / PlayerOwner.Pawn.HealthMax);
		// Dead Players see Red
		if( PlayerOwner.PlayerReplicationInfo.bOutOfLives || PlayerOwner.PlayerReplicationInfo.bIsSpectator )
		{
			//if( !bDisplayDeathScreen )
			//	Return;
			//if( PlayerOwner.ViewTarget!=GoalTarget || GoalTarget==None )
			//	bDisplayDeathScreen = False;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
			C.SetDrawColor(255,255,255,GrainAlpha);
			C.DrawTile(GhostMat,C.SizeX,C.SizeY,0,0,1024,1024);
			return;
		} // So Do Lobby players
		else if (CurrentZone == none && PlayerOwner.PlayerReplicationInfo.bWaitingPlayer)
		{
			C.SetDrawColor(255,255,255,GrainAlpha);
			C.DrawTile(GhostMat,C.SizeX,C.SizeY,0,0,1024,1024);
		}
		// Hook for fade in from black at the start.
		if(!bInitialDark && PlayerOwner.PlayerReplicationInfo.bReadyToPlay)
		{
			C.SetDrawColor(0,0,0,255);
			C.DrawTile(VisionOverlay,C.SizeX,C.SizeY,0,0,1024,1024);
<<<<<<< HEAD
			bInitialDark = true;
=======
			bInitialDark = true;	
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
			return;
		}

		// Players can choose to turn this feature off completely.
		// conversely, setting bDistanceFog = false in a Zone 
		//will cause the code to ignore that zone for a shift in RGB tint
<<<<<<< HEAD
		if (KFLevelRule != none && !KFLevelRule.bUseVisionOverlay)
			return;
	  
		// here we determine the maximum "brighten" amounts for each value.  CANNOT exceed 255
		MaxRBrighten = Round(LastR* (1.0 - (LastR / 255)) - 2) ;
		MaxGBrighten = Round(LastG* (1.0 - (LastG / 255)) - 2) ;
		MaxBBrighten = Round(LastB* (1.0 - (LastB / 255)) - 2) ;



		C.SetDrawColor(LastR+MaxRBrighten,LastG+MaxGBrighten,LastB+MaxBBrighten,GrainAlpha);
		C.DrawTileScaled(VisionOverlay,C.SizeX,C.SizeY);  //,0,0,1024,1024);
=======
		// Players can choose to turn this feature off completely.
		if (KFLevelRule != None && !KFLevelRule.bUseVisionOverlay)
			return;

        // Choose base color: if we never picked up a fog tint, use neutral white so screen isn't black.
        if( LastR==0 && LastG==0 && LastB==0 )
        {
            BaseR = 255;
            BaseG = 255;
            BaseB = 255;
        }
        else
        {
            BaseR = LastR;
            BaseG = LastG;
            BaseB = LastB;
        }

        // Original zone-based tinting logic (now using Base* instead of Last*)
        MaxRBrighten = Round(BaseR * (1.0 - (BaseR / 255)) - 2);
        MaxGBrighten = Round(BaseG * (1.0 - (BaseG / 255)) - 2);
        MaxBBrighten = Round(BaseB * (1.0 - (BaseB / 255)) - 2);

        // Blend the mod overlay color with grayscale based on DesaturationFactor
        FinalR = Round((BaseR + MaxRBrighten) * (DesaturationFactor));
        FinalG = Round((BaseG + MaxGBrighten) * (DesaturationFactor));
        FinalB = Round((BaseB + MaxBBrighten) * (DesaturationFactor));

		// Ensure values are clamped between 0 and 255
		FinalR = Clamp(FinalR, 0, 255);
		FinalG = Clamp(FinalG, 0, 255);
		FinalB = Clamp(FinalB, 0, 255);

		// Set the draw color with the final calculated values
		C.SetDrawColor(FinalR, FinalG, FinalB, GrainAlpha);
		C.DrawTile(VisionOverlay,C.SizeX,C.SizeY,0,0,1024,1024);
		//C.DrawTileScaled(VisionOverlay, C.SizeX, C.SizeY);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		
		/*
                // Added Canvas Modulation
                C.ColorModulate.X = LastR;  //R
                C.ColorModulate.Y = LastG;  //G
                C.ColorModulate.Z = LastB;  //B
                */

		// Here we change over the Zone.
		// What happens of importance is
		// A.  Set Old Zone to current
		// B.  Set New Zone
		// C.  Set Color info up for use by Tick()

		// if we're in a new zone or volume without distance fog...just , dont touch anything.
		// the physicsvolume check is abit screwy because the player is always in a volume called "DefaultPhyicsVolume"
		// so we've gotta make sure that the return checks take this into consideration.

		if (PlayerOwner != none && PlayerOwner.Pawn != none)
		{
			// This block of code here just makes sure that if we've already got a tint, and we step into a zone/volume without
			// bDistanceFog, our current tint is not affected.
			// a.  If I'm in a zone and its not bDistanceFog. AND IM NOT IN A PHYSICSVOLUME. Just a zone.
			// b.  If I'm in a Volume
			if( PlayerOwner.PlayerReplicationInfo.PlayerZone != none && !PlayerOwner.PlayerReplicationInfo.PlayerZone.bDistanceFog
			 && PlayerOwner.PlayerReplicationInfo.PlayerVolume == none || DefaultPhysicsVolume(PlayerOwner.pawn.PhysicsVolume)==None
			 && !PlayerOwner.pawn.PhysicsVolume.bDistanceFog )
				return;
		}
		if (PlayerOwner != none && !bZoneChanged && PlayerOwner.Pawn != none)
		{
			// Grab the most recent zone info from our PRI
			// Only update if it's different
			// EDIT:  AND HAS bDISTANCEFOG true
			if( CurrentZone!=PlayerOwner.PlayerReplicationInfo.PlayerZone || DefaultPhysicsVolume(PlayerOwner.pawn.PhysicsVolume)==None
			 && CurrentVolume!=PlayerOwner.pawn.PhysicsVolume )
			{
				if(CurrentZone != none)
					LastZone = CurrentZone;
				else if(CurrentVolume != none)
					LastVolume = CurrentVolume;

				// This is for all occasions where we're either in a Levelinfo handled zone
				// Or a zoneinfo.
				// If we're in a LevelInfo / ZoneInfo  and NOT touching a Volume.  Set current Zone
				if( PlayerOwner.PlayerReplicationInfo.PlayerZone != none && PlayerOwner.PlayerReplicationInfo.PlayerZone.bDistanceFog
				 && DefaultPhysicsVolume(PlayerOwner.pawn.PhysicsVolume)!=None )
				{
					CurrentVolume = none;
					CurrentZone = PlayerOwner.PlayerReplicationInfo.PlayerZone;
				}
				else if( DefaultPhysicsVolume(PlayerOwner.pawn.PhysicsVolume)==None && PlayerOwner.pawn.PhysicsVolume.bDistanceFog )
				{
					CurrentZone = none;
					CurrentVolume = PlayerOwner.pawn.PhysicsVolume;
				}
				if (CurrentVolume != none)
					LastZone = none;
				else if (CurrentZone != none)
					LastVolume = none;

<<<<<<< HEAD
				if (LastZone != none)
				{
					LastR = LastZone.DistanceFogColor.R;
					LastG = LastZone.DistanceFogColor.G;
					LastB = LastZone.DistanceFogColor.B;
				}
				else if (LastVolume != none)
				{
					LastR = LastVolume.DistanceFogColor.R;
					LastG = LastVolume.DistanceFogColor.G;
					LastB = LastVolume.DistanceFogColor.B;
				}
=======
                if (LastZone != none)
                {
                    LastR = LastZone.DistanceFogColor.R;
                    LastG = LastZone.DistanceFogColor.G;
                    LastB = LastZone.DistanceFogColor.B;
                    bHasFogTint = true;  // captured a fog tint
                }
                else if (LastVolume != none)
                {
                    LastR = LastVolume.DistanceFogColor.R;
                    LastG = LastVolume.DistanceFogColor.G;
                    LastB = LastVolume.DistanceFogColor.B;
                    bHasFogTint = true;  // captured a fog tint
                }
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
				else if (LastZone != none && LastVolume != none)
					return;

				if( LastZone!=CurrentZone || LastVolume!=CurrentVolume )
				{
					bZoneChanged = true;
					SetTimer(OverlayFadeSpeed,false);
				}
			}
		}
		if (!bTicksTurn && bZoneChanged)
		{
			// Pass it off to the tick now
			// valueCheckout signifies that none of the three values have been
			// altered by Tick() yet.

			// BOUNCE IT BACK! :D
			ValueCheckOut = 0;
			bTicksTurn = true;
			SetTimer(OverlayFadeSpeed,false);
		}
	}
}

simulated function DrawHudPassC(Canvas C)
{
	local float PortraitWidth,PortraitHeight, XL, YL, Abbrev; //, SmallH, NameWidth;
	local string PortraitString;

	if( bShowScoreBoard && ScoreBoard!=None )
		ScoreBoard.DrawScoreboard(C);

	// portrait
	if ( bShowPortrait && (Portrait != None) )
	{
		PortraitWidth = 0.125 * C.ClipY;
		PortraitHeight = 1.5 * PortraitWidth;
		C.DrawColor = WhiteColor;

		C.SetPos(-PortraitWidth*PortraitX + 0.025*PortraitWidth,0.5*(C.ClipY-PortraitHeight) + 0.025*PortraitHeight);
		C.DrawTile( Portrait, PortraitWidth, PortraitHeight, 0, 0, 256, 384);

		C.SetPos(-PortraitWidth*PortraitX,0.5*(C.ClipY-PortraitHeight));
		C.Font = GetFontSizeIndex(C,-2);
		PortraitString = PortraitPRI.PlayerName;
		C.StrLen(PortraitString,XL,YL);
		if ( XL > PortraitWidth )
		{
			C.Font = GetFontSizeIndex(C,-4);
			C.StrLen(PortraitString,XL,YL);
			if ( XL > PortraitWidth )
			{
				Abbrev = float(len(PortraitString)) * PortraitWidth/XL;
				PortraitString = left(PortraitString,Abbrev);
				C.StrLen(PortraitString,XL,YL);
			}
		}

		C.DrawColor = C.static.MakeColor(160,160,160);
		C.SetPos(-PortraitWidth*PortraitX + 0.025*PortraitWidth,0.5*(C.ClipY-PortraitHeight) + 0.025*PortraitHeight);
		C.DrawTile( Material'XGameShaders.ModuNoise', PortraitWidth, PortraitHeight, 0.0, 0.0, 512, 512 );

		C.DrawColor = WhiteColor;
		C.SetPos(-PortraitWidth*PortraitX,0.5*(C.ClipY-PortraitHeight));
		C.DrawTileStretched(texture 'InterfaceContent.Menu.BorderBoxA1', 1.05 * PortraitWidth, 1.05*PortraitHeight);

		C.DrawColor = WhiteColor;
		C.SetPos(C.ClipY/256-PortraitWidth*PortraitX + 0.5 * (PortraitWidth - XL),0.5*(C.ClipY+PortraitHeight) + 0.06*PortraitHeight);
		if ( PortraitPRI != None )
		{
			if ( PortraitPRI.Team != None )
			{
				if ( PortraitPRI.Team.TeamIndex == 0 )
					C.DrawColor = RedColor;
				else
					C.DrawColor = TurqColor;
			}
			C.DrawText(PortraitString,true);
		}
	}
<<<<<<< HEAD
=======

	DrawCrosshair(C);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

function bool DrawLevelAction (Canvas C)
{
	local String LevelActionText;
	local Plane OldModulate;

	if ((Level.LevelAction == LEVACT_None) && (Level.Pauser != none))
	{
		LevelActionText = LevelActionPaused;
	}
	else if ((Level.LevelAction == LEVACT_Loading) || (Level.LevelAction == LEVACT_Precaching))
		LevelActionText = LevelActionLoading;
	else
		LevelActionText = "";

	if (LevelActionText == "")
		return false;

	C.Font = LoadLevelActionFont();
	C.DrawColor = LevelActionFontColor;
	C.Style = ERenderStyle.STY_Alpha;

	OldModulate = C.ColorModulate;
	C.ColorModulate = C.default.ColorModulate;

	C.DrawScreenText (LevelActionText, LevelActionPositionX, LevelActionPositionY, DP_MiddleMiddle);

	C.ColorModulate = OldModulate;

	return true;
}

function DisplayPortrait(PlayerReplicationInfo PRI)
{
	local Material NewPortrait;

	if ( LastPlayerIDTalking > 0 )
		return;

	NewPortrait = PRI.GetPortrait();
	if ( NewPortrait == None )
		return;
	if ( Portrait == None )
		PortraitX = 1;
	Portrait = NewPortrait;
	PortraitTime = Level.TimeSeconds + 3;
	PortraitPRI = PRI;
}


simulated function Message( PlayerReplicationInfo PRI, coerce string Msg, name MsgType )
{
	local Class<LocalMessage> LocalMessageClass;

	if ( PRI != None && (MsgType == 'Say') || (MsgType == 'TeamSay') )
		DisplayPortrait(PRI);

	switch( MsgType )
	{
		case 'Say':
			if ( PRI == None )
				return;
			Msg = PRI.PlayerName$": "$Msg;
			LocalMessageClass = class'SayMessagePlus';
			break;
		case 'TeamSay':
			if ( PRI == None )
				return;
			Msg = PRI.PlayerName$"("$PRI.GetLocationName()$"): "$Msg;
			LocalMessageClass = class'TeamSayMessagePlus';
			break;
		case 'CriticalEvent':
			LocalMessageClass = class'KFCriticalEventPlus';
			LocalizedMessage( LocalMessageClass, 0, None, None, None, Msg );
			return;
		case 'DeathMessage':
			LocalMessageClass = class'xDeathMessage';
			break;
		default:
			LocalMessageClass = class'StringMessagePlus';
			break;
	}
	AddTextMessage(Msg,LocalMessageClass,PRI);
}

simulated function font LoadLevelActionFont()
{
	if( LevelActionFontFont == none )
	{
		LevelActionFontFont = Font(DynamicLoadObject(LevelActionFontName, class'Font'));
		if( LevelActionFontFont == None )
			Log("Warning: "$Self$" Couldn't dynamically load font "$LevelActionFontName);
	}
	return LevelActionFontFont;
}

// Draw Health Bars for damage opened doors.
<<<<<<< HEAD
simulated function DrawDoorHealthBars(Canvas C)
{
	local KFDoorMover DamageDoor;

	foreach AllActors(class'KFDoorMover',DamageDoor)
	{
		if (DamageDoor.WeldStrength > 0)
			DrawDoorHealthBar(C, DamageDoor, DamageDoor.WeldStrength, DamageDoor.MaxWeld, 100.0);
	}
}

simulated function DrawDoorHealthBar(Canvas C, Actor A, int Health, int MaxHealth, float Height)
{
	local vector		CameraLocation, CamDir, TargetLocation, HBScreenPos;
	local rotator		CameraRotation;
	local float			Dist; //, HealthPct;
	//local color		 OldDrawColor;

	local vector HitLoc;
	local vector HitNorm;

	// rjp --  don't draw the health bar if menus are open
	if ( PlayerOwner.Player.GUIController.bActive )
		return;

	C.GetCameraLocation( CameraLocation, CameraRotation );
	TargetLocation = A.Location + vect(0,0,1) * Height;
	Dist = VSize(TargetLocation - CameraLocation);

	// Check Distance Threshold
	if (Dist > DoorHealthViewDist)
		return;

	CamDir	= vector(CameraRotation);

	// Target is located behind camera
	HBScreenPos = C.WorldToScreen(TargetLocation);
	if ((TargetLocation - CameraLocation) dot CamDir < 0 || HBScreenPos.X <= 0 || HBScreenPos.X >= C.SizeX || HBScreenPos.Y <= 0
		   || HBScreenPos.Y >= C.SizeY)
	{
		TargetLocation = A.Location + vect(0,0,1) * A.CollisionHeight;
		if ((TargetLocation - CameraLocation) dot CamDir < 0)
			return;
		HBScreenPos = C.WorldToScreen(TargetLocation);
		if (HBScreenPos.X <= 0 || HBScreenPos.X >= C.ClipX || HBScreenPos.Y <= 0 || HBScreenPos.Y >= C.ClipY)
			return;
	}
	if(A == Trace(HitLoc,HitNorm,TargetLocation, CameraLocation ) )
		DrawKFBar(C, HBScreenPos.X, HBScreenPos.Y, 1.0f * Health / MaxHealth, 255);
}

=======
function DrawDoorHealthBars(Canvas C)
{
	local KFDoorMover DamageDoor;
	local vector CameraLocation, CamDir, TargetLocation, HBScreenPos;
	local rotator CameraRotation;
	local name DoorTag;
	local int i;


	if ( Level.TimeSeconds > LastDoorBarHealthUpdate + 0.2 ||
        (PlayerOwner.Pawn != None && PlayerOwner.Pawn.Weapon != none && PlayerOwner.Pawn.Weapon.class == class'Welder' && PlayerOwner.bFire == 1 ))
	{
		if(PlayerOwner.Pawn == None)
			return;
		DoorCache.Remove(0, DoorCache.Length);

		foreach CollidingActors(class'KFDoorMover', DamageDoor, 300.00, PlayerOwner.Pawn.Location)
		{
			if ( DamageDoor.WeldStrength > 0 && !DamageDoor.bHidden)
			{
				DoorCache.Insert(0, 1);
				DoorCache[0] = DamageDoor;

				C.GetCameraLocation(CameraLocation, CameraRotation);
				TargetLocation = DamageDoor.WeldIconLocation /*+ vect(0, 0, 1) * Height*/;
				TargetLocation.Z = CameraLocation.Z;
				CamDir	= vector(CameraRotation);

				if ( Normal(TargetLocation - CameraLocation) dot Normal(CamDir) >= 0.1 && DamageDoor.Tag != DoorTag && FastTrace(DamageDoor.WeldIconLocation - ((DoorCache[i].WeldIconLocation - CameraLocation) * 0.25), CameraLocation) )
				{
					HBScreenPos = C.WorldToScreen(TargetLocation);
					DrawKFBar(C, HBScreenPos.X, HBScreenPos.Y, DamageDoor.WeldStrength / DamageDoor.MaxWeld, 255);
					DoorTag = DamageDoor.Tag;
				}
			}
		}

		LastDoorBarHealthUpdate = Level.TimeSeconds;
	}
	else
	{
		for ( i = 0; i < DoorCache.Length; i++ )
		{
	 		C.GetCameraLocation(CameraLocation, CameraRotation);
			TargetLocation = DoorCache[i].WeldIconLocation /*+ vect(0, 0, 1) * Height*/;
			TargetLocation.Z = CameraLocation.Z;
			CamDir	= vector(CameraRotation);

			if ( Normal(TargetLocation - CameraLocation) dot Normal(CamDir) >= 0.1 && DoorCache[i].Tag != DoorTag && FastTrace(DoorCache[i].WeldIconLocation - ((DoorCache[i].WeldIconLocation - CameraLocation) * 0.25), CameraLocation) )
			{
				HBScreenPos = C.WorldToScreen(TargetLocation);
				DrawKFBar(C, HBScreenPos.X, HBScreenPos.Y, DoorCache[i].WeldStrength / DoorCache[i].MaxWeld, 255);
				DoorTag = DoorCache[i].Tag;
			}
		}
	}
}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated function DisplayHit(vector HitDir, int Damage, class<DamageType> damageType)
{
	// What type of damage are we sustaining?
	HUDHitDamage = damageType;

	if( DamageTime[0]>0 )
		DamageIsUber = true;
	else DamageIsUber = false;

	if(class<DamTypeZombieAttack>(HUDHitDamage)!=none)
	{
		DamageStartTime = class<DamTypeZombieAttack>(HUDHitDamage).default.HUDTime;
		if( HUDHitDamage==Class'DamTypeVomit' )
			VomitHudTimer = Level.TimeSeconds+0.8;
	}
	else DamageStartTime = Clamp(float(Damage)/5.f,0.2,1.5);
	DamageHUDTimer = Level.TimeSeconds+DamageStartTime;
}

simulated function DrawDamageIndicators(Canvas C)
{
	local class<DamTypeZombieAttack> ZHUDDam;
	local float DltA;

	// let's mod this to account for other types of damage effects.
	// - ALEX
	if ( DamageHUDTimer>Level.TimeSeconds )
	{
		C.SetPos(0,0);
		DltA = DamageHUDTimer-Level.TimeSeconds;
		C.SetDrawColor(255,255,255,clamp((DltA/DamageStartTime*200.f), 0, 200));

		ZHUDDam = class<DamTypeZombieAttack>(HUDHitDamage);
		if ( ZHUDDam==none )
			C.DrawTile( FinalBlend'KillingfloorHUD.GoreSplashFB', C.SizeX, C.SizeY, 0.0, 0.0, 512, 512);
		else
		{
			if(DamageIsUber)
				C.DrawTile( ZHUDDam.default.HUDUberDamageTex, C.SizeX, C.SizeY, 0.0, 0.0, ZHUDDam.default.HUDUberDamageTex.MaterialUSize(), ZHUDDam.default.HUDUberDamageTex.MaterialVSize());
			else C.DrawTile( ZHUDDam.default.HUDDamageTex, C.SizeX, C.SizeY, 0.0, 0.0, ZHUDDam.default.HUDDamageTex.MaterialUSize(), ZHUDDam.default.HUDDamageTex.MaterialVSize());
		}
	}
}

simulated function DrawSpectatingHud( Canvas C )
{
<<<<<<< HEAD
	DrawModOverlay(C);
=======
	local rotator CamRot;
	local vector CamPos, ViewDir;
	local int i;

	DrawModOverlay(C);

	if( bHideHud )
	{
		return;
	}

	// Grab our View Direction
	C.GetCameraLocation(CamPos, CamRot);
	ViewDir = vector(CamRot);

	// Draw the Name, Health, Armor, and Veterancy above other players
	for ( i = 0; i < PlayerInfoPawns.Length; i++ )
	{
		if ( PlayerInfoPawns[i].Pawn != None && PlayerInfoPawns[i].Pawn.Health > 0 && (PlayerInfoPawns[i].Pawn.Location - CamPos) dot ViewDir > 0.6 &&
			 PlayerInfoPawns[i].RendTime > Level.TimeSeconds )
		{
			DrawPlayerInfo(C, PlayerInfoPawns[i].Pawn, PlayerInfoPawns[i].PlayerInfoScreenPosX, PlayerInfoPawns[i].PlayerInfoScreenPosY);
		}
		else
		{
			PlayerInfoPawns.Remove(i--, 1);
		}
	}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	super.DrawSpectatingHud(C);
	if( KFPlayerController(PlayerOwner)!=None && KFPlayerController(PlayerOwner).ActiveNote!=None )
		KFPlayerController(PlayerOwner).ActiveNote = None;
	if( KFGameReplicationInfo(Level.GRI)!=None && KFGameReplicationInfo(Level.GRI).EndGameType>0 )
	{
		if( KFGameReplicationInfo(Level.GRI).EndGameType==2 )
		{
			DrawEndGameHUD(C,True);
			Return;
		}
		else DrawEndGameHUD(C,False);
	}
	DrawKFHUDTextElements(C);
	DisplayLocalMessages(C);
	if( bShowScoreBoard && ScoreBoard!=None )
		ScoreBoard.DrawScoreboard(C);
}

simulated function DrawWeaponName(Canvas C)
{
	local string CurWeaponName;
	local float XL,YL;
	
	if (  PawnOwner==None || PawnOwner.Weapon==None )
	return;
	
	CurWeaponName = PawnOwner.Weapon.GetHumanReadableName();

	C.Font  = GetFontSizeIndex( C, -1 );
	C.SetDrawColor(255,50,50,KFHUDAlpha);
	C.Strlen(CurWeaponName,XL,YL);
<<<<<<< HEAD
	C.SetPos( (C.ClipX/2) - (XL/2) + C.ClipX / 3 , C.ClipY*0.8-YL + C.ClipY / 8);
=======
	//C.SetPos( (C.ClipX/2) - (XL/2) + C.ClipX / 3 , C.ClipY*0.8-YL + C.ClipY / 8 + 10);
	C.SetPos(C.ClipX * 0.79, C.ClipY * 0.91);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	C.DrawText(CurWeaponName);
}

/* Called when viewing a Matinee cinematic */
simulated function DrawCinematicHUD( Canvas C )
{
	IntroTitleFade += Global_Delta * 2;

	if ( IntroTitleFade<10 && KFPRI!=None )
	{
		Subtitle =  KFPRI.Subtitle[SubIndex];
		DrawSubtitle( C,Subtitle );

		// The Subtitle List has been played through
		// Reset for next cam.
		if (SubIndex > 4)
		{
			Subtitle = "";
			SubIndex = 0;
		}
	}

	super.DrawCinematicHUD( C );

	// Film Grain Overlay
	if ( !Level.IsSoftwareRendering() && Level.DetailMode>DM_LOW && KFPRI!=None && KFPRI.bWideScreenOverlay)
	{
		C.SetPos(0,0);
		C.Style = ERenderStyle.STY_Modulated;
		C.DrawColor.A = 255;
		C.DrawTileScaled( Material 'KillingFloorHUD.ClassMenu.CinematicOverlay', C.ClipX/1024, C.ClipY/1024);
	}
}

simulated function DrawSubtitle( Canvas C , string Text )
{
	local int	   FontIndex;
	local String	LevelTitle;
	local float	 XL, YL;
	local float  SubYLoc;

	C.DrawColor = WhiteColor;
	C.Style	 = ERenderStyle.STY_Alpha;
	FontIndex   = 8;
	LevelTitle  = Text;

	do  // make sure name is not too big
	{
		C.Font = GetFontSizeIndex( C, FontIndex-- );
		C.TextSize( LevelTitle, XL, YL );
	} until ( (XL < C.ClipX*0.67) && (YL < C.ClipY*0.67) )

	if ( IntroTitleFade < 1 )								   // Hidden
		C.DrawColor.A = 0;
	else if ( IntroTitleFade < 3 )							  // fade in
		C.DrawColor.A = 255 * ((IntroTitleFade-1)*0.5);
	else if ( IntroTitleFade > 6 )							  // fade out
		C.DrawColor.A = 255 * (1.f - ((IntroTitleFade-6)/4));
	else C.DrawColor.A = 255;									// normal
	
	// Adjust the Y Location of the Subtitle based on whether the Widescreen is on, or not.

	if( KFPRI!=None && KFPRI.bWideScreenOverlay )
		SubYLoc = 0.75;
	else SubYLoc = 1.0;

	C.SetPos( (C.ClipX-XL)*0.5, (C.ClipY-YL)*SubYLoc );
	C.DrawText( LevelTitle, false );

	if (IntroTitleFade >= 9.9)
	{
		if(SubIndex < 5 &&
		Level.TimeSeconds - LastSubChangeTime > 1.0)
		{
			SubIndex ++;
			bGetNewSub = false;
			LastSubChangeTime = Level.TimeSeconds;
		}
		IntroTitleFade = 0;
	}
}

simulated function DrawClientStats( Canvas C )
{
	local KFPlayerController PC;
	local float XL,YL,Y;

	PC = KFPlayerController(PlayerOwner);
	if( PC==None )
		Return;
	C.Font = LoadFont(6);
	C.TextSize("TEST",XL,YL);
	C.DrawColor.R = 255;
	C.DrawColor.B = 255;
	C.DrawColor.G = 255;
	C.DrawColor.A = 255;
	Y = 45;
	C.SetPos(30,Y);
	C.DrawText("Your personal stats:",False);
	Y+=YL*1.5;
	C.DrawColor.R = 255;
	C.DrawColor.B = 255;
	C.DrawColor.G = 50;
	C.SetPos(20,Y);
	Y+=YL;
	if( KFPlayerReplicationInfo(PC.PlayerReplicationInfo)!=None && KFPlayerReplicationInfo(PC.PlayerReplicationInfo).ClientVeteranSkill!=None )
		C.DrawText("Current special skill:"@KFPlayerReplicationInfo(PC.PlayerReplicationInfo).ClientVeteranSkill.Default.VeterancyName,False);
	else C.DrawText("Current special skill: None",False);
	C.DrawColor.R = 200;
	C.DrawColor.B = 50;
	C.DrawColor.G = 50;
	C.SetPos(20,Y);
	Y+=YL;
	C.DrawText("Total kills:"@PC.CLStats[0],False);
	C.SetPos(20,Y);
	Y+=YL;
	C.DrawText("Headshot kills:"@PC.CLStats[2],False);
	C.SetPos(20,Y);
	Y+=YL;
	C.DrawText("Power weapons kills:"@PC.CLStats[3],False);
	C.SetPos(20,Y);
	Y+=YL;
	C.DrawText("Total hitpoints healed:"@PC.CLStats[4]@"%",False);
	C.SetPos(20,Y);
	Y+=YL;
	C.DrawText("Total door hitpoints welded:"@PC.CLStats[5]@"%",False);
	C.SetPos(20,Y);
	Y+=YL;
	C.DrawText("Stalker kills:"@PC.CLStats[6],False);
	C.SetPos(20,Y);
	Y+=YL;
	C.DrawText("Total Bullpup damage:"@PC.CLStats[7],False);
	C.SetPos(20,Y);
	Y+=YL;
	C.DrawText("Total Melee damage:"@PC.CLStats[1],False);
	C.SetPos(20,Y);
	Y+=YL;
	C.DrawText("Total Playtime:"@Strl(PC.CLStats[8]),False);
	C.SetPos(20,Y);
	Y+=YL;
	C.DrawText("Games Won/Lost:"@PC.CLStats[9]$"/"$PC.CLStats[10],False);

	C.Font = LoadFont(7);
	C.SetPos(24,Y);
	C.DrawColor.R = 50;
	C.DrawColor.B = 50;
	C.DrawColor.G = 200;
	C.DrawText("Time until next stats update:"@int(NextStatsUdpTime-Level.TimeSeconds)@"seconds",False);
}
simulated function string Strl( int Value )
{
	local int Hours, Minutes, Seconds;

	Seconds = Abs(Value);
	Minutes = Seconds / 60;
	Hours   = Minutes / 60;
	Seconds = Seconds - (Minutes * 60);
	Minutes = Minutes - (Hours * 60);
	Return Hours$":"$Eval(Minutes<10,"0"$Minutes,string(Minutes))$":"$Eval(Seconds<10,"0"$Seconds,string(Seconds));
}

simulated function DrawEndGameHUD( Canvas C, bool bVictory )
{
	local float Scalar;

	C.DrawColor.A = 255;
	C.DrawColor.R = 255;
	C.DrawColor.G = 255;
	C.DrawColor.B = 255;
	Scalar = FClamp(C.ClipY,320,1024);
	C.CurX = C.ClipX/2-Scalar/2;
	C.CurY = C.ClipY/2-Scalar/2;
	C.Style = ERenderStyle.STY_Alpha;
	if( bVictory )
		MyColorMod.Material = Combiner'VictoryCombiner';
	else MyColorMod.Material = Combiner'DefeatCombiner';
	if( EndGameHUDTime>=1 )
		MyColorMod.Color.A = 255;
	else MyColorMod.Color.A = (EndGameHUDTime*255.f);
	C.DrawTile( MyColorMod, Scalar, Scalar, 0, 0, 1024, 1024);
}

defaultproperties
{
<<<<<<< HEAD
	KFHUDAlpha=200
	GrainAlpha=200
	HealthBarFullVisDist=700.000000
	HealthBarCutoffDist=2000.000000
	DoorHealthViewDist=4000.000000
	BarLength=54.250000
	BarHeight=10.000000
	HealthBarWidth=50.000000
	HealthBarHeight=10.000000
	DigitsBig=(DigitTexture=Texture'KillingFloorHUD.Generic.HUD',TextureCoords[0]=(X2=38,Y2=38),TextureCoords[1]=(X1=39,X2=77,Y2=38),TextureCoords[2]=(X1=78,X2=116,Y2=38),TextureCoords[3]=(X1=117,X2=155,Y2=38),TextureCoords[4]=(X1=156,X2=194,Y2=38),TextureCoords[5]=(X1=195,X2=233,Y2=38),TextureCoords[6]=(X1=234,X2=272,Y2=38),TextureCoords[7]=(X1=273,X2=311,Y2=38),TextureCoords[8]=(X1=312,X2=350,Y2=38),TextureCoords[9]=(X1=351,X2=389,Y2=38),TextureCoords[10]=(X1=390,X2=428,Y2=38))
	AmmoIcon=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=128,X2=191,Y2=63),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-16,OffsetY=-16,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
	BulletIcon=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=64,X2=127,Y2=63),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-294,OffsetY=-16,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
	DividerIcon=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(Y1=64,X2=31,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-219,OffsetY=-16,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
	TorchBatteryIcon=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=14,Y1=180,X2=30,Y2=192),TextureScale=0.500000,DrawPivot=DP_LowerRight,PosY=1.000000,OffsetX=-16,OffsetY=-100,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
	DigitsClipsLeft=(RenderStyle=STY_Alpha,TextureScale=0.500000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-74,OffsetY=-10,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
	DigitsNumLeftInClip=(RenderStyle=STY_Alpha,TextureScale=0.500000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-223,OffsetY=-10,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
	HealthBarBackMat=Texture'InterfaceContent.Menu.BorderBoxD'
	HealthBarMat=Texture'KFInterfaceContent.Menu.StatusBarInner'
	GrenadeIcon=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X2=63,Y2=63),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-16,OffsetY=-100,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
	DigitsGrenade=(RenderStyle=STY_Alpha,TextureScale=0.500000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-74,OffsetY=-60,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
	HealthArmourBorderLeft=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=14,Y1=204,X2=254,Y2=249),TextureScale=0.500000,DrawPivot=DP_LowerLeft,PosY=1.000000,OffsetX=10,OffsetY=-10,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
	HealthMeter=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=41,Y1=186,X2=250,Y2=199),TextureScale=0.500000,DrawPivot=DP_LowerLeft,PosY=1.000000,OffsetX=37,OffsetY=-15,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
	ArmourMeter=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=41,Y1=168,X2=250,Y2=181),TextureScale=0.500000,DrawPivot=DP_LowerLeft,PosY=1.000000,OffsetX=37,OffsetY=-38,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
	BatteryMeter=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=41,Y1=150,X2=250,Y2=163),TextureScale=0.500000,DrawPivot=DP_LowerRight,PosY=1.000000,OffsetX=1200,OffsetY=-100,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
	CashIcon=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=193,X2=255,Y2=63),TextureScale=0.300000,DrawPivot=DP_LowerLeft,PosY=1.000000,OffsetX=476,OffsetY=-15,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
	DigitsCash=(RenderStyle=STY_Alpha,TextureScale=0.500000,DrawPivot=DP_LowerLeft,PosY=1.000000,OffsetX=324,OffsetY=-10,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
	ToolChargeMeter=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=41,Y1=186,X2=250,Y2=199),TextureScale=0.750000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-6,OffsetY=-6,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(0)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-170,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(1)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-210,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(2)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-250,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(3)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-290,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(4)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-330,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(5)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-370,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(6)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-410,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(7)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-450,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(8)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-490,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(9)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-530,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(10)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-570,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(11)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-610,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(12)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-650,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(13)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-690,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(14)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-730,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(15)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-770,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(16)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-810,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(17)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-850,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(18)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-890,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	CarryMeter(19)=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=218,Y1=90,X2=245,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-35,OffsetY=-930,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=150),Tints[1]=(B=255,G=255,R=255,A=255))
	VisionOverlay=Shader'KFX.SepiaShader'
	GhostMat=Shader'KFX.LightBloom'
	NearDeathOverlay=Shader'KFX.NearDeathShader'
	FireOverlay=Shader'KFX.BlazingShader'
	LevelActionFontColor=(B=255,G=255,R=255,A=255)
	LevelActionPositionX=0.500000
	LevelActionPositionY=0.250000
	VeterancyMatScaleFactor=1.500000
	OverlayFadeSpeed=0.024250
	YouveWonTheMatch="Your squad survived! "
	YouveLostTheMatch="Squad eliminated."
	ConsoleMessagePosX=0.005000
	ConsoleMessagePosY=0.920000
=======
     KFHUDAlpha=200
     GrainAlpha=200
     HealthBarFullVisDist=700.000000
     HealthBarCutoffDist=2000.000000
     DoorHealthViewDist=4000.000000
     BarLength=54.250000
     BarHeight=10.000000
     HealthBarWidth=50.000000
     HealthBarHeight=10.000000
     DigitsBig=(DigitTexture=Texture'KillingFloorHUD.Generic.HUD',TextureCoords[0]=(X2=38,Y2=38),TextureCoords[1]=(X1=39,X2=77,Y2=38),TextureCoords[2]=(X1=78,X2=116,Y2=38),TextureCoords[3]=(X1=117,X2=155,Y2=38),TextureCoords[4]=(X1=156,X2=194,Y2=38),TextureCoords[5]=(X1=195,X2=233,Y2=38),TextureCoords[6]=(X1=234,X2=272,Y2=38),TextureCoords[7]=(X1=273,X2=311,Y2=38),TextureCoords[8]=(X1=312,X2=350,Y2=38),TextureCoords[9]=(X1=351,X2=389,Y2=38),TextureCoords[10]=(X1=390,X2=428,Y2=38))
     AmmoIcon=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=128,X2=191,Y2=63),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-16,OffsetY=-16,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     BulletIcon=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=64,X2=127,Y2=63),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-394,OffsetY=-16,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     DividerIcon=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(Y1=64,X2=31,Y2=127),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-219,OffsetY=-16,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     TorchBatteryIcon=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=14,Y1=180,X2=30,Y2=192),TextureScale=0.500000,DrawPivot=DP_LowerRight,PosY=1.000000,OffsetX=-16,OffsetY=-100,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     DigitsClipsLeft=(RenderStyle=STY_Alpha,TextureScale=0.400000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-74,OffsetY=-15,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     DigitsNumLeftInClip=(RenderStyle=STY_Alpha,TextureScale=0.400000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-190,OffsetY=-15,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     HealthBarBackMat=Texture'InterfaceContent.Menu.BorderBoxD'
     HealthBarMat=Texture'KFInterfaceContent.Menu.StatusBarInner'
     GrenadeIcon=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X2=63,Y2=63),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-16,OffsetY=-100,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     DigitsGrenade=(RenderStyle=STY_Alpha,TextureScale=0.400000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-74,OffsetY=-80,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     HealthArmourBorderLeft=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=14,Y1=204,X2=254,Y2=249),TextureScale=0.500000,DrawPivot=DP_LowerLeft,PosY=1.000000,OffsetX=10,OffsetY=-10,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     HealthMeter=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=41,Y1=186,X2=250,Y2=199),TextureScale=0.500000,DrawPivot=DP_LowerLeft,PosY=1.000000,OffsetX=37,OffsetY=-15,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     ArmourMeter=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=41,Y1=168,X2=250,Y2=181),TextureScale=0.500000,DrawPivot=DP_LowerLeft,PosY=1.000000,OffsetX=37,OffsetY=-38,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     BatteryMeter=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=41,Y1=150,X2=250,Y2=163),TextureScale=0.500000,DrawPivot=DP_LowerRight,PosY=1.000000,OffsetX=1220,OffsetY=-100,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     CashIcon=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=193,X2=255,Y2=63),TextureScale=0.295000,DrawPivot=DP_LowerLeft,PosY=1.000000,OffsetX=446,OffsetY=-15,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     DigitsCash=(RenderStyle=STY_Alpha,TextureScale=0.400000,DrawPivot=DP_LowerLeft,PosY=1.000000,OffsetX=374,OffsetY=-15,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     ToolChargeMeter=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=41,Y1=186,X2=250,Y2=199),TextureScale=0.750000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-6,OffsetY=-6,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     CarryIcon=Texture'KFKillMeNow.KFHUDIcons'
     VisionOverlay=Shader'KFX.SepiaShader'
     GhostMat=Shader'KFX.LightBloom'
     NearDeathOverlay=Shader'KFX.NearDeathShader'
     FireOverlay=Shader'KFX.BlazingShader'
     LevelActionFontColor=(B=255,G=255,R=255,A=255)
     LevelActionPositionX=0.500000
     LevelActionPositionY=0.250000
     VeterancyMatScaleFactor=1.500000
     OverlayFadeSpeed=0.024250
     YouveWonTheMatch="Your squad survived! "
     YouveLostTheMatch="Squad eliminated."
     ConsoleMessagePosX=0.005000
     ConsoleMessagePosY=0.920000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
