#exec OBJ LOAD FILE=..\KFMod254\Textures\KillingFloorHUD.utx
#exec OBJ LOAD FILE=..\KFMod254\Textures\PatchTex.utx
#exec OBJ LOAD FILE=..\KFMod254\Textures\KFInterfaceContent.utx
#exec OBJ LOAD FILE=..\KFMod254\Textures\KFKillMeNow.utx
#exec OBJ LOAD FILE=..\KFMod254\Textures\KFMapEndTextures.utx
#exec OBJ LOAD FILE=Crosshairs.utx

class HUDKillingFloor extends HudBase
	config(User);

#exec TEXTURE IMPORT NAME=KFWarpLines FILE=..\KFMod254\KFMod\Textures\KFWarpLines.tga MIPS=ON ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP
#exec TEXTURE IMPORT NAME=KFWarpVignette FILE=..\KFMod254\KFMod\Textures\KFWarpVignette.tga MIPS=ON ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP

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
var transient Pawn LastGrenadePawn; // Track which pawn PlayerGrenade belongs to

var() SpriteWidget HealthArmourBorderLeft;

var() SpriteWidget HealthMeter;
var() SpriteWidget ArmourMeter;
var() SpriteWidget BatteryMeter;

var() SpriteWidget CashIcon;
var() NumericWidget DigitsCash;

var transient bool bScoreInited;
var transient float LastDisplayedScore;
var transient int ScorePopupAmount;
var transient float ScorePopupStartTime;
var transient float ScorePopupEndTime;
var transient float ScorePopupRiseOffset;
var float ScorePopupDuration;
var float ScorePopupRiseDistance;
var float ScorePopupRiseTime;
var transient int PopAmount[10];		// Zombies: each award of points its own "+10" flying off the score (DrawPointsPops)
var transient float PopStart[10], PopSide[10];
var transient int PopNext;
var float PopLife;

var() SpriteWidget ToolChargeMeter;

//const MAXWEIGHT = 50; //why hardcap this in the first place though?

var() Material CarryIcon;

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
var bool bScreenFXStarted;  // the frame tap that bloom, vivid and the hit blur are made from is there
var KFTraderDread Dread;     // the far-off specimen sounds between waves
var bool bHasFogTint; 
var float MoodStart;  // when this HUD first drew for a player with a pawn

var () float VeterancyMatScaleFactor;   // Amount to scale all Veterancy indicators on the HUD by
var int FontPixels[9];   // how tall each of the HUD's fonts is, biggest first
var float CornerUnits;   // the round icons in the top right corner, in the HUD's units (51.2 was 128 pixels on 1200 lines)
var float ClockDigits;   // the countdown's digits, as a share of the size that fills the clock's window
var float NameUnits;     // how tall the weapon's name is, in the HUD's units
var float NameRoom;      // how wide it may be, in the HUD's units, before it is set smaller
var float NameHold, NameFade;   // the name is shown this long after a change of weapon, then fades out over this long
var transient Weapon NameWeapon;
var transient float NameShownAt;
var float Edge8X[8], Edge8Y[8];  // the eight ways round a letter, for a dark edge


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

// blood on the screen (AddScreenBlood): where each splat is, as a share of the screen, how big, when it came and for
// how long, how fast it runs down, which picture (0-15 KFX.BloodSplash's sixteen, 16-31 KFX.BloodySpray's), how solid
struct ScreenBlot
{
	var float X, Y, Size, Born, Life, Run;
	var int Sub;
	var byte Alpha;
};
var array<ScreenBlot> Blots;
var() int MaxBlots;
var() int ScreenBlotsAtOnce;	// no more splats are laid while this many are on the screen
var float VoidWarpTime;			// the Void Executioner's blink (AddVoidWarp)
var() float WarpLinesTime, WarpEdgeTime;
var ColorModifier MyColorMod;

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

var string CriticalPrompt;      // (Zombies) a use prompt kept up as a critical message, while it lasts
var float CriticalPromptFade;   // that message fades out over this long once the prompt goes

var KFNightVision NightVision;  // the Commando's night vision, drawn over the view and the weapon (KFPlayerController.bNightVision)

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
	// bloom, vivid and the hit blur start with the HUD
	StartScreenFX();
	if( Dread==None )
		Dread = Spawn(class'KFTraderDread', self);
	foreach DynamicActors(class'KFSPLevelInfo', KFLevelRule)
		Break;
	if ( CustomCrosshairsAllowed() )
		SetCustomCrosshairs();
}

// On a network client the player's screen is not always there yet when the HUD begins: asked again from each
// frame's drawing until the tap is made.
simulated function StartScreenFX()
{
	if ( !bScreenFXStarted )
		bScreenFXStarted = (class'KFFrameTap'.static.Of(PlayerOwner) != None);
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

    // (no crosshair records found: nothing to draw, and no error line every frame)
    if (!bCrosshairShow || Crosshairs.Length == 0)
        return;

	// (the sights take over once a weapon is halfway up to the eye)
	if ( !PlayerOwner.bBehindView && PawnOwner != None && KFWeapon(PawnOwner.Weapon) != None
		&& KFWeapon(PawnOwner.Weapon).AimBlend() > 0.5 )
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
	if( Dread!=None )
		Dread.Destroy();
	if( NightVision!=None )
		NightVision.Destroy();
	Super.Destroyed();
}

// Night vision over the view and the weapon, under the HUD: while the player's own controller has it on and may
simulated function DrawNightVision( Canvas C )
{
	local KFPlayerController KPC;

	KPC = KFPlayerController(PlayerOwner);
	if( KPC!=None && KPC.bNightVision && PawnOwner!=None && PawnOwner==KPC.Pawn && KPC.NightVisionAllowed() )
	{
		if( NightVision==None )
			NightVision = Spawn(class'KFNightVision', self);
		if( NightVision!=None )
			NightVision.Draw(C, KPC);
	}
	else if( NightVision!=None && NightVision.bActive )
		NightVision.Off();
}

// Take it out.
exec function ShowHud();

simulated function SetHUDAlpha()
{
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
	TorchBatteryIcon.Tints[1].A=KFHUDAlpha;
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
}

simulated function Tick(float deltaTime)
{
	local Material NewPortrait;

	if( KFGameReplicationInfo(Level.GRI)!=None && KFGameReplicationInfo(Level.GRI).EndGameType>0 && EndGameHUDTime<1 )
		EndGameHUDTime+=(deltaTime/3.f);

	if ( ScorePopupEndTime > Level.TimeSeconds && ScorePopupRiseOffset < ScorePopupRiseDistance )
		ScorePopupRiseOffset = FMin(ScorePopupRiseDistance, ScorePopupRiseOffset + deltaTime*(ScorePopupRiseDistance/ScorePopupRiseTime));

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
	
	if ( PawnOwner != None && PawnOwner.PlayerReplicationInfo != None )
		KFPRI = KFPlayerReplicationInfo(PawnOwner.PlayerReplicationInfo);
		
	if ( KFGRI == None && PlayerOwner.GameReplicationInfo != None )
		KFGRI = KFGameReplicationInfo(PlayerOwner.GameReplicationInfo);
}

function DrawCustomBeacon(Canvas C, Pawn P, float ScreenLocX, float ScreenLocY)
{
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
	local float XL,YL;
	local float Dist;
	local byte BeaconAlpha;
	local float OldZ;
	local Class<KFVeterancyTypes> VE;
	local Material M;
	local float MW, BS;

	if( P.PlayerReplicationInfo==none || KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).bViewingMatineeCinematic )
		return;
	BS = BigScreenScale(C);

	Dist = vsize(P.Location - PlayerOwner.CalcViewLocation);
	Dist -= HealthBarFullVisDist;
	Dist = FClamp(Dist, 0, HealthBarCutoffDist-HealthBarFullVisDist);
	Dist = Dist/(HealthBarCutoffDist-HealthBarFullVisDist);
	BeaconAlpha = byte((1.f-Dist)*255.f);

	if(BeaconAlpha == 0)
		return;

	OldZ = C.Z;
	C.Z = 1.0;

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
			MW = 36.f*VeterancyMatScaleFactor*BS;
			if( M!=None )
			{
				C.SetPos(ScreenLocX - FClamp(XL/2,BS*BarLength/2,500.f)-50*BS,ScreenLocY-YL-18*BS);    // -31
				C.DrawTile(M,MW,MW,0,0,M.MaterialUSize(),M.MaterialVSize());
			}
			M = VE.Default.SubHUDIcon;
			if( M!=None )
			{
				C.SetPos(ScreenLocX - FClamp(XL/2,BS*BarLength/2,500.f)-50*BS,ScreenLocY-YL-8*BS);
				C.DrawTile(M,MW,MW,0,0,M.MaterialUSize(),M.MaterialVSize());
			}
		}
	}

	// Health
	if (P.Health > 0)
		DrawKFBar(C, ScreenLocX, (ScreenLocY - YL)-0.5*BarHeight*BS, FClamp(P.Health/P.HealthMax,0,1), BeaconAlpha);
	// Armor
	if (P.ShieldStrength > 0)
		DrawKFBar(C, ScreenLocX, (ScreenLocY - YL)-1.5*BarHeight*BS, FClamp(P.ShieldStrength/100.f,0,1), BeaconAlpha, true);
	C.Z = OldZ;
}

// The bars and icons over players and doors are sized in pixels for a screen up to 1200 lines: bigger on a bigger one
simulated function float BigScreenScale(Canvas C)
{
	return FMax(1.0, C.ClipY/1200.f);
}

// A length of the native widgets' own measure (640 by 480) on this screen, by its height
simulated function float HudUnits(float Units)
{
	return Units * HudCanvasScale * ResScaleY * HudScale;
}

// Where the native code draws a widget: its left and top edge on the screen, and its size
simulated function WidgetBox(Canvas C, SpriteWidget W, out float X, out float Y, out float XL, out float YL)
{
	local float SX, SY;

	SX = W.TextureScale * HudCanvasScale * ResScaleX * HudScale;
	SY = W.TextureScale * HudCanvasScale * ResScaleY * HudScale;
	XL = (Abs(W.TextureCoords.X2 - W.TextureCoords.X1) + 1.0) * SX;
	YL = (Abs(W.TextureCoords.Y2 - W.TextureCoords.Y1) + 1.0) * SY;
	X = (W.PosX * HudCanvasScale + (1.0 - HudCanvasScale) * 0.5) * C.SizeX + W.OffsetX * SX;
	Y = (W.PosY * HudCanvasScale + (1.0 - HudCanvasScale) * 0.5) * C.SizeY + W.OffsetY * SY;
	if( W.DrawPivot==DP_UpperMiddle || W.DrawPivot==DP_MiddleMiddle || W.DrawPivot==DP_LowerMiddle )
		X -= 0.5*XL;
	else if( W.DrawPivot==DP_UpperRight || W.DrawPivot==DP_MiddleRight || W.DrawPivot==DP_LowerRight )
		X -= XL;
	if( W.DrawPivot==DP_MiddleLeft || W.DrawPivot==DP_MiddleMiddle || W.DrawPivot==DP_MiddleRight )
		Y -= 0.5*YL;
	else if( W.DrawPivot==DP_LowerLeft || W.DrawPivot==DP_LowerMiddle || W.DrawPivot==DP_LowerRight )
		Y -= YL;
}

// (the prompt to open the trader is not drawn while its menu is open: it showed through the menu's panels)
simulated function DisplayLocalMessages( Canvas C )
{
	local int i;

	if( TraderOpen() )
	{
		for( i=0; i<ArrayCount(LocalMessages); i++ )
		{
			if( LocalMessages[i].Message==class'KFMainMessages' && LocalMessages[i].Switch==3 )
				LocalMessages[i].EndOfLife = Level.TimeSeconds;
		}
	}
	Super.DisplayLocalMessages(C);
}

// Whether the trader's menu is open
simulated function bool TraderOpen()
{
	local GUIController G;

	if( PlayerOwner==None || PlayerOwner.Player==None )
		return false;
	G = GUIController(PlayerOwner.Player.GUIController);
	return G!=None && G.bActive && G.ActivePage!=None && G.ActivePage.IsA('GUIBuyMenu');
}

// Which of the HUD's fonts is nearest in size to so many pixels tall
simulated function int NearestFont(float Want)
{
	local int i, Best;

	Best = ArrayCount(FontPixels)-1;
	for( i=0; i<ArrayCount(FontPixels); i++ )
		if( Abs(FontPixels[i]-Want) < Abs(FontPixels[Best]-Want) )
			Best = i;
	return Best;
}

// The biggest of the HUD's fonts no taller than H in which S is no wider than W, narrowed down to Narrowest (a fifth
// off if not said) if that keeps it a size bigger (FontScaleX is left set: put it back after drawing); the width S
// takes is returned
simulated function float FitFont(Canvas C, string S, float W, float H, optional float Narrowest)
{
	local int i;
	local float XL, YL;

	if( Narrowest<=0.0 )
		Narrowest = 0.8;
	for( i=0; i<ArrayCount(FontPixels)-1; i++ )
		if( FontPixels[i]<=H )
			break;
	for( i=i; i<ArrayCount(FontPixels); i++ )
	{
		C.Font = LoadFont(i);
		C.FontScaleX = 1.0;
		C.StrLen(S, XL, YL);
		if( XL*Narrowest<=W || i==ArrayCount(FontPixels)-1 )
			break;
	}
	if( XL>W )
	{
		C.FontScaleX = W/XL;
		XL = W;
	}
	return XL;
}

// The font nearest in size to what font Index is on a screen of 1200 lines
simulated function Font HeightFont(Canvas C, int Index)
{
	local float Want;
	local int i, Best;

	Want = FontPixels[Index] * C.ClipY/1200.f;
	Best = ArrayCount(FontPixels)-1;
	for( i=0; i<ArrayCount(FontPixels); i++ )
		if( Abs(FontPixels[i]-Want) < Abs(FontPixels[Best]-Want) )
			Best = i;
	return LoadFont(Best);
}

simulated function DrawKFBar(Canvas C, float XCentre, float YCentre, float BarPercentage, byte BarAlpha, optional bool bArmor)
{
	local float BorderWidth, BL, BH;
	local int InnerBarLength, TexLength;

	BL = BarLength*BigScreenScale(C);
	BH = BarHeight*BigScreenScale(C);

	C.SetDrawColor(255,255,255,BarAlpha);
	C.SetPos(XCentre - 0.5*BL , YCentre-0.5*BH );
	C.DrawTileClipped(Texture'KFKillMeNow.KFHUDIcons', BL, BH, 37,204, 217,21);
	BorderWidth = (BL/217.0)*4;

	if (bArmor)
		C.SetDrawColor(25,200,230,BarAlpha);
	else C.SetDrawColor(255,0,0,BarAlpha);
	C.SetPos( (XCentre - 0.5*BL)+BorderWidth , YCentre-0.5*BH );
	InnerBarLength = (BL-BorderWidth) * BarPercentage;
	TexLength = 209* BarPercentage;
	C.DrawTileClipped(Texture'KFKillMeNow.KFHUDIcons', InnerBarLength, BH, 41,146, TexLength,17);
}

simulated function DrawHud( Canvas C )
{
	local KFGameReplicationInfo CurrentGame;
	local rotator CamRot;
	local vector CamPos, ViewDir;
	local int i;
  
	if (KFGameType(PlayerOwner.Level.Game) != none)
		CurrentGame = KFGameReplicationInfo(PlayerOwner.Level.GRI);

	if ( FontsPrecached < 2 )
		PrecacheFonts(C);
	Super(HUD).DrawHud(C);

	UpdateHud();
	DrawUpgradeCard(C);

	StartScreenFX();
	PassStyle = STY_Modulated;
	DrawModOverlay(C);
	if ( Blots.Length > 0 )
		DrawScreenBlood(C);
	if ( VoidWarpTime > 0 )
		DrawVoidWarp(C);

	if (!KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).bViewingMatineeCinematic)
	{
		if( bShowTargeting )
			DrawTargeting(C);

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
		DrawHudPassC(C);
		if( KFPlayerController(PlayerOwner)!=None && KFPlayerController(PlayerOwner).ActiveNote!=None )
		{
			if( PlayerOwner.Pawn==None )
				KFPlayerController(PlayerOwner).ActiveNote = None;
			else KFPlayerController(PlayerOwner).ActiveNote.RenderNote(C);
		}
		PassStyle = STY_None;
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
		DrawZombiesHUD(C);
	}

	if (KFPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo).bViewingMatineeCinematic)
	{
		PassStyle = STY_Alpha;
		DrawCinematicHUD(C);
	}  
}

simulated function DrawZombiesBar(Canvas C, float X, float Y, float W, float H, float Pct, byte R, byte G, byte B)
{
	C.SetDrawColor(0,0,0,160);
	C.SetPos(X, Y);
	C.DrawTile(Texture'Engine.WhiteSquareTexture', W, H, 0, 0, 2, 2);

	C.SetDrawColor(R,G,B,220);
	C.SetPos(X+2, Y+2);
	C.DrawTile(Texture'Engine.WhiteSquareTexture', (W-4)*FClamp(Pct,0.0,1.0), H-4, 0, 0, 2, 2);
}

// An upgraded or re-packed weapon's name across the screen as it comes back from the machine (KFWeapon.ShowCard)
simulated function DrawUpgradeCard( Canvas C )
{
	local KFWeapon W;
	local float Left, A, XL, YL;
	local Font OldFont;

	if ( PawnOwner == None )
		return;
	W = KFWeapon(PawnOwner.Weapon);
	if ( W == None || W.CardText == "" )
		return;
	Left = W.CardUntil - Level.TimeSeconds;
	if ( Left <= 0.0 )
		return;
	// (not over the trader's menu: an upgrade bought there is shown when it closes)
	if ( TraderOpen() )
	{
		W.CardUntil = Level.TimeSeconds + 3.0;
		return;
	}
	// (it comes up quickly and fades in its last second)
	A = FMin(1.0, Left) * FMin(1.0, (3.0 - Left) * 5.0);
	OldFont = C.Font;
	C.Font = GetFontSizeIndex(C, 1);
	C.Style = ERenderStyle.STY_Alpha;
	C.TextSize(Caps(W.CardText), XL, YL);
	C.SetDrawColor(0, 0, 0, int(160.0 * A));
	C.SetPos(C.ClipX * 0.5 - XL * 0.5 + 2, C.ClipY * 0.30 + 2);
	C.DrawText(Caps(W.CardText), false);
	C.DrawColor = W.CardColor;
	C.DrawColor.A = int(255.0 * A);
	C.SetPos(C.ClipX * 0.5 - XL * 0.5, C.ClipY * 0.30);
	C.DrawText(Caps(W.CardText), false);
	C.Font = OldFont;
}

simulated function DrawZombiesText(Canvas C, string S, float CentreX, float Y)
{
	local float XL, YL;

	C.TextSize(S, XL, YL);
	C.SetPos(CentreX - XL*0.5, Y);
	C.DrawText(S, false);
}

simulated function DrawZombiesPerk(Canvas C, bool bHasPerk, string Label, byte R, byte G, byte B, out float X, float Y, float Size)
{
	local float XL, YL;

	if( !bHasPerk )
		Return;

	C.SetDrawColor(R,G,B,200);
	C.SetPos(X, Y);
	C.DrawTile(Texture'Engine.WhiteSquareTexture', Size, Size, 0, 0, 2, 2);

	C.SetDrawColor(255,255,255,255);
	C.TextSize(Label, XL, YL);
	C.SetPos(X + (Size-XL)*0.5, Y + (Size-YL)*0.5);
	C.DrawText(Label, false);

	X += Size + 4;
}

// A use prompt shown as KF's critical messages are, kept at full strength while it lasts and faded out over
// CriticalPromptFade once it goes. A critical message of the game's own keeps the place until it has faded.
simulated function ShowCriticalPrompt( string S )
{
	local int i;
	local bool bOldBeep;

	For( i=0; i<ArrayCount(LocalMessages); i++ )
	{
		if( LocalMessages[i].Message!=class'KFCriticalEventPlus' )
			Continue;
		if( LocalMessages[i].StringMessage==S )
		{
			LocalMessages[i].LifeTime = CriticalPromptFade;
			LocalMessages[i].EndOfLife = Level.TimeSeconds + CriticalPromptFade;
			Return;
		}
		if( LocalMessages[i].StringMessage!=CriticalPrompt )
			Return;
		Break;
	}

	// (no beep: it is put up again after every message of the game's own)
	CriticalPrompt = S;
	bOldBeep = bMessageBeep;
	bMessageBeep = false;
	LocalizedMessage(class'KFCriticalEventPlus', 0, None, None, None, S);
	bMessageBeep = bOldBeep;
}

// The time left of the power-ups that are running, outside Zombies (Zombies draws them with the rest of its HUD)
simulated function DrawPowerUpTimes(Canvas C, KFGameReplicationInfo G)
{
	local float XL, YL, Y;
	local byte OldStyle;

	if( G.InstaKillTime==0 && G.DoublePointsTime==0 )
		Return;
	OldStyle = C.Style;
	C.Style = ERenderStyle.STY_Alpha;
	C.Font = GetFontSizeIndex(C, -1);
	C.TextSize("A", XL, YL);
	C.SetDrawColor(255,255,255,255);
	Y = C.ClipY*0.12;
	if( G.InstaKillTime>0 )
	{
		DrawZombiesText(C, "ONE-HIT KILLS" @ G.InstaKillTime, C.ClipX*0.5, Y);
		Y += YL;
	}
	if( G.DoublePointsTime>0 )
		DrawZombiesText(C, "DOUBLE DOSH" @ G.DoublePointsTime, C.ClipX*0.5, Y);
	C.Style = OldStyle;
}

simulated function DrawZombiesHUD(Canvas C)
{
	local KFGameReplicationInfo ZGRI;
	local KFHumanPawnZombies ZP, Other;
	local KFPlayerReplicationInfo ZPRI;
	local float CentreX, X, Y, BarW, BarH, XL, YL, Size;
	local vector CamLoc, WorldPos, ScreenPos;
	local rotator CamRot;
	local string S;
	local int i;
	local bool bAnyDowned;
	local byte OldStyle;

	ZGRI = KFGameReplicationInfo(PlayerOwner.GameReplicationInfo);
	if( ZGRI==None )
		Return;
	// (Endless has the power-ups too: only their time left)
	if( !ZGRI.bZombiesMode )
	{
		DrawPowerUpTimes(C, ZGRI);
		Return;
	}

	OldStyle = C.Style;
	C.Style = ERenderStyle.STY_Alpha;

	CentreX = C.ClipX*0.5;
	BarW = C.ClipX*0.18;
	BarH = FMax(10, C.ClipY*0.014);

	C.Font = GetFontSizeIndex(C, -1);
	C.TextSize("A", XL, YL);

	C.SetDrawColor(200,20,20,255);
	DrawZombiesText(C, "ROUND" @ (ZGRI.WaveNumber+1), C.ClipX-HudUnits(CornerUnits*0.5), HudUnits(CornerUnits*1.03));

	Y = C.ClipY*0.12;
	C.SetDrawColor(255,255,255,255);
	if( ZGRI.InstaKillTime>0 )
	{
		DrawZombiesText(C, "ONE-HIT KILLS" @ ZGRI.InstaKillTime, CentreX, Y);
		Y += YL;
	}
	if( ZGRI.DoublePointsTime>0 )
		DrawZombiesText(C, "DOUBLE DOSH" @ ZGRI.DoublePointsTime, CentreX, Y);

	ZP = KFHumanPawnZombies(PawnOwner);
	if( ZP==None )
	{
		C.Style = OldStyle;
		Return;
	}

	if( KFWeapon(ZP.Weapon)!=None && KFWeapon(ZP.Weapon).bUpgraded )
	{
		C.SetDrawColor(255,215,0,255);
		DrawZombiesText(C, ZP.Weapon.GetHumanReadableName(), C.ClipX*0.90, C.ClipY*0.80);
		if( KFWeapon(ZP.Weapon).AmmoMod>0 )
		{
			C.DrawColor = class'KFAmmoMod'.static.ColourOf(KFWeapon(ZP.Weapon).AmmoMod);
			DrawZombiesText(C, class'KFAmmoMod'.static.NameOf(KFWeapon(ZP.Weapon).AmmoMod), C.ClipX*0.90, C.ClipY*0.835);
		}
	}

	if( ZP.UsePrompt!="" && !ZP.bIsDowned )
	{
		if( ZP.bUsePromptCritical )
			ShowCriticalPrompt(ZP.UsePrompt);
		else
		{
			C.SetDrawColor(255,255,255,255);
			DrawZombiesText(C, ZP.UsePrompt, CentreX, C.ClipY*0.62);
		}
	}

	if( ZP.bIsDowned )
	{
		C.SetDrawColor(255,60,60,255);
		if( ZP.bSelfReviving )
			S = "SECOND WIND";
		else if( ZP.bBeingRevived )
			S = "BEING REVIVED";
		else
			S = "YOU ARE DOWN";
		DrawZombiesText(C, S, CentreX, C.ClipY*0.40);

		if( ZP.bSelfReviving || ZP.bBeingRevived )
			DrawZombiesBar(C, CentreX-BarW*0.5, C.ClipY*0.40+YL+4, BarW, BarH, float(ZP.ReviveByte)/255.0, 60,220,60);
		else
			DrawZombiesBar(C, CentreX-BarW*0.5, C.ClipY*0.40+YL+4, BarW, BarH, float(ZP.BleedoutByte)/255.0, 220,40,40);
	}

	For( i=0; i<ZGRI.PRIArray.Length; i++ )
	{
		if( KFPlayerReplicationInfo(ZGRI.PRIArray[i])!=None && KFPlayerReplicationInfo(ZGRI.PRIArray[i]).bIsDowned )
		{
			bAnyDowned = true;
			Break;
		}
	}

	if( bAnyDowned )
	{
		C.GetCameraLocation(CamLoc, CamRot);

		ForEach DynamicActors(class'KFHumanPawnZombies', Other)
		{
			if( Other==ZP || !Other.bIsDowned || Other.Health<=0 )
				Continue;

			S = "REVIVE";
			if( Other.PlayerReplicationInfo!=None )
				S = S @ Other.PlayerReplicationInfo.PlayerName;

			if( Other.bBeingRevived && Other.Reviver==ZP )
			{
				C.SetDrawColor(60,220,60,255);
				DrawZombiesText(C, "REVIVING" @ Mid(S, 7), CentreX, C.ClipY*0.52);
				DrawZombiesBar(C, CentreX-BarW*0.5, C.ClipY*0.52+YL+4, BarW, BarH, float(Other.ReviveByte)/255.0, 60,220,60);
				Continue;
			}

			WorldPos = Other.Location + vect(0,0,1)*Other.CollisionHeight;
			if( (WorldPos-CamLoc) Dot vector(CamRot) <= 0 )
				Continue;

			ScreenPos = C.WorldToScreen(WorldPos);
			if( ScreenPos.X<0 || ScreenPos.X>C.ClipX || ScreenPos.Y<0 || ScreenPos.Y>C.ClipY )
				Continue;

			C.SetDrawColor(255,Other.BleedoutByte,Other.BleedoutByte,255);
			DrawZombiesText(C, S, ScreenPos.X, ScreenPos.Y-YL-BarH-2);
			if( Other.bBeingRevived )
				DrawZombiesBar(C, ScreenPos.X-BarW*0.25, ScreenPos.Y-BarH, BarW*0.5, BarH, float(Other.ReviveByte)/255.0, 60,220,60);
			else
				DrawZombiesBar(C, ScreenPos.X-BarW*0.25, ScreenPos.Y-BarH, BarW*0.5, BarH, float(Other.BleedoutByte)/255.0, 220,40,40);
		}
	}

	ZPRI = KFPlayerReplicationInfo(PawnOwnerPRI);
	if( ZPRI!=None )
	{
		C.Font = GetFontSizeIndex(C, -3);
		Size = FMax(32, C.ClipY*0.045);
		X = C.ClipX*0.02;
		Y = C.ClipY*0.78;
		DrawZombiesPerk(C, ZPRI.bHasJuggernog, "IRN", 190,30,30, X, Y, Size);
		DrawZombiesPerk(C, ZPRI.bHasQuickRevive, "WND", 40,120,220, X, Y, Size);
		DrawZombiesPerk(C, ZPRI.bHasSpeedCola, "HND", 30,150,60, X, Y, Size);
		DrawZombiesPerk(C, ZPRI.bHasDoubleTap, "TRG", 210,120,20, X, Y, Size);
		DrawZombiesPerk(C, ZPRI.bHasStaminUp, "FLT", 190,170,20, X, Y, Size);
	}

	C.Style = OldStyle;
}

simulated function DrawHealthBar(Canvas C, Actor A, int Health, int MaxHealth, float Height)
{
	local vector		CameraLocation, CamDir, TargetLocation, HBScreenPos;
	local rotator	   CameraRotation;
	local float		 Dist, HealthPct;
	local color		 OldDrawColor;

	// rjp --  don't draw the health bar if menus are open
	// exception being, the Veterancy menu

	if ( PlayerOwner.Player.GUIController.bActive && (GUIController(PlayerOwner.Player.GUIController).ActivePage==None
		|| !GUIController(PlayerOwner.Player.GUIController).ActivePage.IsA('GUIVeterancyBinder')) )
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

	if( PawnOwner == none )
	{
		super.UpdateHud();
		return;
	}

	CalculateAmmo();
	DigitsClipsLeft.Value=CurClipsPrimary;

	if (PawnOwner.Weapon!=None) 
		if (KFWeapon(PawnOwner.Weapon)!=None)
			DigitsNumLeftInClip.Value=kfWeapon(PawnOwner.Weapon).ClipLeft;
		else DigitsNumLeftInClip.Value = CurAmmoPrimary;

	if (DigitsNumLeftInClip.Value < 0)
		DigitsNumLeftInClip.Value = 0;
	TintClipDigits();

	if(PlayerGrenade==none || LastGrenadePawn != PawnOwner)
	{
		PlayerGrenade = None;
		FindPlayerGrenade();
		LastGrenadePawn = PawnOwner;
	}

	if(PlayerGrenade!=none)
	{
		PlayerGrenade.GetAmmoCount(MaxGren,CurGren);
		DigitsGrenade.Value=CurGren;
	}

	HealthMeter.Scale = pawnowner.Health / pawnowner.HealthMax;
	ArmourMeter.Scale = xPawn(pawnowner).ShieldStrength / 100;
	if(KFHumanPawn(PawnOwner)!=None)
		BatteryMeter.Scale = float(KFHumanPawn(PawnOwner).TorchBatteryLife) / float(KFHumanPawn(pawnowner).default.TorchBatteryLife);

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

	if ( !bScoreInited )
	{
		LastDisplayedScore = PawnOwnerPRI.Score;
		bScoreInited = true;
	}
	else if ( PawnOwnerPRI.Score > LastDisplayedScore && KFHumanPawnZombies(PawnOwner) != None )
	{
		AddPointsPop(int(PawnOwnerPRI.Score - LastDisplayedScore));
		LastDisplayedScore = PawnOwnerPRI.Score;
	}
	else if ( PawnOwnerPRI.Score > LastDisplayedScore )
	{
		if ( ScorePopupEndTime > Level.TimeSeconds )
			ScorePopupAmount += int(PawnOwnerPRI.Score - LastDisplayedScore);
		else
		{
			// Only reset the rise-animation clock when the previous popup has fully expired -
			// otherwise sustained fire keeps restarting the rise and it never gets to play out.
			ScorePopupAmount = int(PawnOwnerPRI.Score - LastDisplayedScore);
			ScorePopupStartTime = Level.TimeSeconds;
			ScorePopupRiseOffset = 0;
		}
		ScorePopupEndTime = Level.TimeSeconds + ScorePopupDuration;
		LastDisplayedScore = PawnOwnerPRI.Score;
	}
	else LastDisplayedScore = PawnOwnerPRI.Score;

	ToolChargeMeter.Scale=CurAmmoPrimary/MaxAmmoPrimary;
	Super.UpdateHud();
}

simulated function CalculateAmmo() //Revised to work with UT2004 weapons as well as KF ones.
{
	MaxAmmoPrimary = 1;
	CurAmmoPrimary = 1;

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


simulated function DrawHudPassA (Canvas C)
{
	local class<Ammunition> AmmoClass;
	local int i;
	local Material Ma;
	local class<KFVeterancyTypes> VE;
	local float MW, BX, BY, BXL, BYL;

	DrawDoorHealthBars(C);
	// (with the trader open, its menu says what is carried, the cash and the weight; these lay under it)
	if( TraderOpen() )
		return;

	//  if( bShowWeaponInfo && (PawnOwner.Weapon != None) )
	if((PawnOwner != none && PawnOwner.Weapon != None) )
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
				if(KFWeapon(PawnOwner.Weapon)!=none)
				{
					DrawSpriteWidget (C, DividerIcon);
					DrawNumericWidget (C, DigitsClipsLeft, DigitsBig);
				}
				DrawNumericWidget (C, DigitsNumLeftInClip, DigitsBig);
			}
		}
	}
	if( KFPawn(PawnOwner)!=None && KFPawn(PawnOwner).GetVeteran() != None )
		KFPawn(PawnOwner).GetVeteran().Static.SpecialHUDInfo(C);
  
	// Torch: while it is lit, and after until the battery is full again

	if ( KFWeapon(PawnOwner.Weapon) != none && KFWeapon(PawnOwner.Weapon).bTorchEnabled
		&& ((KFWeapon(PawnOwner.Weapon).FlashLight != none && KFWeapon(PawnOwner.Weapon).FlashLight.bHasLight)
		|| (KFHumanPawn(PawnOwner) != none && KFHumanPawn(PawnOwner).TorchBatteryLife < KFHumanPawn(PawnOwner).default.TorchBatteryLife)) )
	{
		DrawSpriteWidget (C, BatteryMeter);
		DrawSpriteWidget (C, TorchBatteryIcon);
	}

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
	 DrawScorePopup(C);
	 DrawPointsPops(C);
        }

	//10x easier and faster than using spritewidgets, also allows for more weight than the stock capped 20 - by YoYoBatty
	if(KFHumanPawn(PawnOwner)!=None && KFHumanPawnZombies(PawnOwner)==None)
	{
		// stacked right above the nade icon wherever that is drawn, just like original, and sized by the screen as it is
		WidgetBox(C, GrenadeIcon, BX, BY, BXL, BYL);
		MW = HudUnits(8.8);
		BX += 0.5*(BXL-MW);
		BY -= HudUnits(13.2);
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

			C.SetPos(BX,BY - i*HudUnits(11.6));
			C.DrawTile(CarryIcon,MW,HudUnits(12.0),210,65,35,63); //nice and clean, gets the full icon size too
		}
	}

	if( KFPlayerReplicationInfo(PawnOwnerPRI)!=None )
	{
		VE = KFPlayerReplicationInfo(PawnOwnerPRI).ClientVeteranSkill;
		if( VE!=None )
		{
			C.DrawColor.R = 255;
			C.DrawColor.G = 255;
			C.DrawColor.B = 255;
			C.DrawColor.A = 255;

			Ma = VE.Default.OnHUDIcon;

			// Should always be larger on the HUD. (36 pixels on a screen of 1200 lines, 2.5 of them to a unit.)
			MW = HudUnits(36 * VeterancyMatScaleFactor * 1.4 / 2.5);
			// it stands on the health and armour box
			WidgetBox(C, HealthArmourBorderLeft, BX, BY, BXL, BYL);

			if( Ma!=None )
			{
				C.SetPos(HudUnits(11.43),BY-MW);
				C.DrawTile(Ma,MW,MW,0,0,Ma.MaterialUSize(),Ma.MaterialVSize());  // 36
			}
			Ma = VE.Default.SubHUDIcon;
			if( Ma!=None )
			{
				C.SetPos(HudUnits(11.43),BY-MW);
				C.DrawTile(Ma,MW,MW,0,0,Ma.MaterialUSize(),Ma.MaterialVSize());
			}
		}
	}
}

simulated function bool LobbyOpen()
{
	local GUIController G;

	if ( PlayerOwner == None || PlayerOwner.Player == None )
		return false;
	G = GUIController(PlayerOwner.Player.GUIController);
	return G != None && G.bActive && G.ActivePage != None && G.ActivePage.IsA('LobbyMenu');
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
	if ( KFPlayerController(PlayerOwner) != None )
		KFPlayerController(PlayerOwner).CheckAspect(Canvas.SizeX, Canvas.SizeY);

	// One scale both ways, so that nothing is drawn wider than it is tall on a wide screen (it used to be
	// SizeX/640 across and SizeY/480 down). On a 4:3 screen the two are the same number.
	ResScaleX = FMin(Canvas.SizeX / 640.0, Canvas.SizeY / 480.0);
	ResScaleY = ResScaleX;

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
	DrawNightVision(Canvas);

	if ( PawnOwner != None && PawnOwner.bSpecialHUD )
		PawnOwner.DrawHud(Canvas);
	if ( bShowDebugInfo )
	{
		Canvas.Font = GetConsoleFont(Canvas);
		Canvas.Style = ERenderStyle.STY_Alpha;
		Canvas.DrawColor = ConsoleColor;

		PlayerOwner.ViewTarget.DisplayDebug(Canvas, XPos, YPos);
		DrawHeadShotSphere();
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
		// the lobby has its own chat box
		if ( !LobbyOpen() )
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

// An upgraded gun's rounds in its element's colour, leaning red with a slow pulse when a quarter of the magazine or less
// is left
simulated function TintClipDigits()
{
	local KFWeapon W;
	local color C, E;
	local float K;

	C = class'Canvas'.static.MakeColor(255, 255, 255);
	if ( PawnOwner != None )
		W = KFWeapon(PawnOwner.Weapon);
	if ( W != None )
	{
		if ( W.bUpgraded && class'KFElement'.static.Has(W.Element) )
		{
			E = class'KFElement'.static.Glow(W.Element);
			C.R = 255 - int(0.85 * (255 - E.R));
			C.G = 255 - int(0.85 * (255 - E.G));
			C.B = 255 - int(0.85 * (255 - E.B));
		}
		if ( W.ClipCount > 3 && !W.bHoldToReload && W.ClipLeft * 4 <= W.ClipCount )
		{
			K = 0.55 + 0.25 * Sin(Level.TimeSeconds * 6.0);
			C.R = C.R + int(K * (255 - C.R));
			C.G = int(C.G * (1.0 - K) + 50 * K);
			C.B = int(C.B * (1.0 - K) + 40 * K);
		}
	}
	DigitsNumLeftInClip.Tints[0].R = C.R;
	DigitsNumLeftInClip.Tints[0].G = C.G;
	DigitsNumLeftInClip.Tints[0].B = C.B;
	DigitsNumLeftInClip.Tints[1].R = C.R;
	DigitsNumLeftInClip.Tints[1].G = C.G;
	DigitsNumLeftInClip.Tints[1].B = C.B;
}

simulated function AddPointsPop( int Amount )
{
	PopAmount[PopNext] = Amount;
	PopStart[PopNext] = Level.TimeSeconds;
	PopSide[PopNext] = FRand();
	PopNext = (PopNext + 1) % ArrayCount(PopAmount);
}

// Zombies: each award of points flies off the score on its own, up and out to the right, fading (a kill's bigger award
// in a bigger hand)
simulated function DrawPointsPops( Canvas C )
{
	local int i;
	local float T, A, XL, YL, S, X, Y;
	local string Txt;

	S = DigitsCash.TextureScale*HudCanvasScale*ResScaleX*HudScale;
	for ( i = 0; i < ArrayCount(PopAmount); i++ )
	{
		if ( PopAmount[i] <= 0 )
			continue;
		T = (Level.TimeSeconds - PopStart[i]) / PopLife;
		if ( T >= 1.0 || T < 0.0 )
		{
			PopAmount[i] = 0;
			continue;
		}
		A = FMin(1.0, (1.0 - T) / 0.45);
		Txt = "+" $ PopAmount[i];
		if ( PopAmount[i] >= 50 )
			C.Font = GetFontSizeIndex(C, -1);
		else
			C.Font = GetFontSizeIndex(C, -2);
		C.TextSize(Txt, XL, YL);
		X = DigitsCash.OffsetX*S + (110.0 + 160.0 * T + 40.0 * PopSide[i]) * S;
		Y = C.ClipY - (70.0 + 30.0 * PopSide[i] + 70.0 * T) * S;
		C.SetDrawColor(0, 0, 0, int(150 * A));
		C.SetPos(X - XL*0.5 + 1, Y + 1);
		C.DrawText(Txt, false);
		C.SetDrawColor(255, 215, 0, int(255 * A));
		C.SetPos(X - XL*0.5, Y);
		C.DrawText(Txt, false);
	}
}

simulated function DrawScorePopup(Canvas C)
{
	local float DltA, TimeLeft, XL, YL, HUDWidgetScale;
	local string PopupText;

	if ( ScorePopupEndTime <= Level.TimeSeconds )
		return;

	TimeLeft = ScorePopupEndTime - Level.TimeSeconds;

	// Hold full opacity for the first 60% of the popup's life, then fade out.
	if ( TimeLeft > ScorePopupDuration*0.4 )
		DltA = 1;
	else DltA = Clamp(TimeLeft/(ScorePopupDuration*0.4), 0, 1);

	PopupText = "+"$ScorePopupAmount;

	// Native widgets (DigitsCash, CashIcon) scale their pixel offsets by this - match it so the
	// popup lines up at any resolution.
	HUDWidgetScale = DigitsCash.TextureScale*HudCanvasScale*ResScaleX*HudScale;

	C.Font = GetFontSizeIndex(C, -1);
	C.TextSize(PopupText, XL, YL);
	C.SetDrawColor(255,215,0,DltA*255);
	C.SetPos(DigitsCash.OffsetX*HUDWidgetScale - XL*0.5, C.ClipY - 55*HUDWidgetScale - ScorePopupRiseOffset*HUDWidgetScale);
	C.DrawText(PopupText, false);
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
	local float XL,YL,IS,S2,Grow,O;
	local int NumZombies,Min,i;
	local color Col;
	local string S;

	// the round icon in the corner: 160 pixels on a screen of 1200 lines
	IS = HudUnits(CornerUnits);

	// Countdown Text
	if( PlayerOwner.GameReplicationInfo == none || !PlayerOwner.GameReplicationInfo.bMatchHasBegun )
		return;

	if (KFHumanPawn(PlayerOwner.Pawn) != none)
		AlphaAmount = KFHumanPawn(PlayerOwner.Pawn).AlphaAmount;

	if(!KFGameReplicationInfo(PlayerOwner.GameReplicationInfo).bWaveInProgress)
	{
		C.SetDrawColor(255,255,255,KFHUDAlpha);

		if (KFGameReplicationInfo(PlayerOwner.GameReplicationInfo).TimeToNextWave > 5)
			C.SetDrawColor(255,255,255,KFHUDAlpha);
		else C.SetDrawColor(255,50,50,KFHUDAlpha);

		NumZombies = KFGameReplicationInfo(PlayerOwner.GameReplicationInfo).TimeToNextWave;
		Min = NumZombies/60;
		NumZombies-=Min*60;
		S = Eval((Min>=10),string(Min),"0"$Min)$":"$Eval((NumZombies>=10),string(NumZombies),"0"$NumZombies);
		C.SetPos(C.ClipX-IS,IS/64);
		C.DrawTile(Material'KFKillMeNow.TimeRemainingIcon',IS,IS,0,0,256,256);
		// (sized by the clock's little window, a little short of filling it; the digits' middle is four tenths of the
		// way down their line, and is set on the window's middle)
		XL = FitFont(C,"00:00",IS*0.35,IS*0.12,0.7);
		C.StrLen("0",S2,YL);
		C.FontScaleX *= ClockDigits;
		C.FontScaleY = ClockDigits;
		XL *= ClockDigits;
		YL *= ClockDigits;
		C.SetPos(C.ClipX-IS/2-(XL/2),IS*(1.0/64.0+0.497)-YL*0.4);
		C.DrawTextClipped(S);
		C.FontScaleX = 1.0;
		C.FontScaleY = 1.0;
	}
	else
	{
		S = string(KFGameReplicationInfo(PlayerOwner.GameReplicationInfo).MaxMonsters);
		C.SetPos(C.ClipX-IS,IS/64);
		C.SetDrawColor(255,255,255,KFHUDAlpha);
		C.DrawTile(Material'KFKillMeNow.SpecRemainingIcon',IS,IS,0,0,256,256);

		if( KFGameReplicationInfo(PlayerOwner.GameReplicationInfo).MaxMonsters>5 )
			C.SetDrawColor(255,255,80,KFHUDAlpha);
		else C.SetDrawColor(255,50,50,KFHUDAlpha);

		// (about a quarter of the icon tall: past the biggest font, the biggest drawn larger)
		C.Font = LoadFont(NearestFont(IS*0.24));
		Grow = FMax(1.0, IS*0.24/FontPixels[0]);
		C.StrLen(S,XL,YL);
		C.FontScaleX = Grow;
		C.FontScaleY = Grow;
		// (with a dark edge round it, against the white figure behind it)
		Col = C.DrawColor;
		O = FMax(1.0, float(int(IS/160.0)));
		C.SetDrawColor(0,0,0,Col.A);
		for( i=0; i<8; i++ )
		{
			C.SetPos(C.ClipX-IS/2-(XL*Grow/2)+O*Edge8X[i],IS*0.516-YL*Grow/2+O*Edge8Y[i]);
			C.DrawTextClipped(S);
		}
		C.DrawColor = Col;
		C.SetPos(C.ClipX-IS/2-(XL*Grow/2),IS*0.516-YL*Grow/2);
		C.DrawTextClipped(S);
		C.FontScaleX = 1.0;
		C.FontScaleY = 1.0;
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
			MoodTint(CurrentZone.DistanceFogColor, CurrentR, CurrentG, CurrentB);
		else if (CurrentVolume != none)
			MoodTint(CurrentVolume.DistanceFogColor, CurrentR, CurrentG, CurrentB);
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
	local int FinalR, FinalG, FinalB;
	local float MaxRBrighten, MaxGBrighten, MaxBBrighten;
	local float BaseR, BaseG, BaseB;

	C.SetPos(0,0);

	// We want the overlay to start black, and fade in, almost like the player opened their eyes
	// BrightFactor = 1.5;   // Not too bright.  Not too dark.  Livens things up just abit
	// Hook for Optional Vision overlay.  - Alex
	if (VisionOverlay != none )
	{
		if( PlayerOwner == none || PlayerOwner.PlayerReplicationInfo == none || PlayerOwner.PlayerReplicationInfo.bOnlySpectator )
			return;

		// If critical, pulsate.  otherwise, dont.
		/* 
		if( PlayerOwner.Pawn!=none && PlayerOwner.Pawn.Health>0 )
		{
			if (PlayerOwner.pawn.Health < PlayerOwner.pawn.HealthMax * 0.25)
				VisionOverlay = NearDeathOverlay;
			else if (KFPawn(PlayerOwner.pawn).BurnDown > 0)
				VisionOverlay = FireOverlay;
			else VisionOverlay = default.VisionOverlay; 
		}
		*/
		//Desaturate from 100 to 0 health, darken at 50 health and lower
		if (PlayerOwner.Pawn != None && PlayerOwner.Pawn.Health > 0)
			DesaturationFactor = 0.75 + 0.25 * (float(PlayerOwner.Pawn.Health) / PlayerOwner.Pawn.HealthMax);
		// Dead Players see Red
		if( PlayerOwner.PlayerReplicationInfo.bOutOfLives || PlayerOwner.PlayerReplicationInfo.bIsSpectator )
		{
			//if( !bDisplayDeathScreen )
			//	Return;
			//if( PlayerOwner.ViewTarget!=GoalTarget || GoalTarget==None )
			//	bDisplayDeathScreen = False;
			C.SetDrawColor(255,255,255,GrainAlpha);
			C.DrawTile(GhostMat,C.SizeX,C.SizeY,0,0,1024,1024);
			return;
		} // So Do Lobby players
		else if (CurrentZone == none && PlayerOwner.PlayerReplicationInfo.bWaitingPlayer)
		{
			C.SetDrawColor(255,255,255,GrainAlpha);
			C.DrawTile(GhostMat,C.SizeX,C.SizeY,0,0,1024,1024);
			return;
		}
		// Hook for fade in from black at the start.
		if(!bInitialDark && PlayerOwner.PlayerReplicationInfo.bReadyToPlay)
		{
			C.SetDrawColor(0,0,0,255);
			C.DrawTile(VisionOverlay,C.SizeX,C.SizeY,0,0,1024,1024);
			bInitialDark = true;	
			return;
		}

		// Players can choose to turn this feature off completely.
		// conversely, setting bDistanceFog = false in a Zone 
		//will cause the code to ignore that zone for a shift in RGB tint
		// Players can choose to turn this feature off completely.
		if (KFLevelRule != None && !KFLevelRule.bUseVisionOverlay)
			return;

        // The fog he stands in is taken up before this frame is drawn with it.
        TrackMoodZone();

        // Choose base color: until a fog tint has been picked up (or if the one in force is plain black), white, so the screen isn't black.
        if( !bHasFogTint || (LastR==0 && LastG==0 && LastB==0 && !bZoneChanged) )
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
        MaxRBrighten = Round(BaseR * (1.0 - (BaseR / 255.0)) - 2);
        MaxGBrighten = Round(BaseG * (1.0 - (BaseG / 255.0)) - 2);
        MaxBBrighten = Round(BaseB * (1.0 - (BaseB / 255.0)) - 2);

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
		
		/*
                // Added Canvas Modulation
                C.ColorModulate.X = LastR;  //R
                C.ColorModulate.Y = LastG;  //G
                C.ColorModulate.Z = LastB;  //B
                */

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

// A fog colour as a mood tint. Black fog, or next to it, is a map's darkness, not a mood: it gives no tint, as a map
// with no fog does. (Taken as a colour it tinted the view black, for good in a near-black zone, and for the length
// of a change between black zones, so a doorway between them blinked the view black.)
simulated function MoodTint(color Fog, out float R, out float G, out float B)
{
	if ( Fog.R <= 2 && Fog.G <= 2 && Fog.B <= 2 )
	{
		R = 255;
		G = 255;
		B = 255;
		return;
	}
	R = Fog.R;
	G = Fog.G;
	B = Fog.B;
}

// The fog the mood overlay takes its colour from: the zone the player's pawn is in, or a fog volume he stands in.
simulated function TrackMoodZone()
{
	local ZoneInfo Z;

	if ( PlayerOwner == None || PlayerOwner.Pawn == None || PlayerOwner.PlayerReplicationInfo == None )
		return;
	if ( MoodStart == 0 )
		MoodStart = Level.TimeSeconds;
	// (the pawn's own zone: the one in the player's replicated record is a second or two behind)
	Z = PlayerOwner.Pawn.Region.Zone;

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
		if( Z != none && !Z.bDistanceFog
		 && PlayerOwner.PlayerReplicationInfo.PlayerVolume == none || DefaultPhysicsVolume(PlayerOwner.pawn.PhysicsVolume)==None
		 && !PlayerOwner.pawn.PhysicsVolume.bDistanceFog )
			return;
	}
	if (PlayerOwner != none && !bZoneChanged && PlayerOwner.Pawn != none)
	{
		// Grab the zone the pawn is in
		// Only update if it's different
		// EDIT:  AND HAS bDISTANCEFOG true
		if( CurrentZone!=Z || DefaultPhysicsVolume(PlayerOwner.pawn.PhysicsVolume)==None
		 && CurrentVolume!=PlayerOwner.pawn.PhysicsVolume )
		{
			if(CurrentZone != none)
				LastZone = CurrentZone;
			else if(CurrentVolume != none)
				LastVolume = CurrentVolume;

			// This is for all occasions where we're either in a Levelinfo handled zone
			// Or a zoneinfo.
			// If we're in a LevelInfo / ZoneInfo  and NOT touching a Volume.  Set current Zone
			if( Z != none && Z.bDistanceFog
			 && DefaultPhysicsVolume(PlayerOwner.pawn.PhysicsVolume)!=None )
			{
				CurrentVolume = none;
				CurrentZone = Z;
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

                if (LastZone != none)
                {
                    MoodTint(LastZone.DistanceFogColor, LastR, LastG, LastB);
                    bHasFogTint = true;  // captured a fog tint
                }
                else if (LastVolume != none)
                {
                    MoodTint(LastVolume.DistanceFogColor, LastR, LastG, LastB);
                    bHasFogTint = true;  // captured a fog tint
                }
			else if (LastZone != none && LastVolume != none)
				return;

			if( LastZone!=CurrentZone || LastVolume!=CurrentVolume )
			{
				bZoneChanged = true;
				SetTimer(OverlayFadeSpeed,false);
			}
		}
	}
	// The first fog taken up. At the start the view fades in from black (the colour starts at nothing); met later,
	// after playing with no tint, it eases from that plain view instead.
	if ( !bHasFogTint && (CurrentZone != None || CurrentVolume != None) )
	{
		bHasFogTint = true;
		if ( Level.TimeSeconds - MoodStart > 1.0 )
		{
			LastR = 255;
			LastG = 255;
			LastB = 255;
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
		// (the talker's record can be gone while the picture is still up)
		if ( PortraitPRI != None )
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

	DrawCrosshair(C);
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

// Blood on the screen from a body blown apart close in front (KFBloodBlast), as much as Amount (1 is a clot's at arm's
// length): splats that run slowly down and fade
simulated function AddScreenBlood( float Amount )
{
	local int i, n;
	local ScreenBlot B;

	n = Clamp(int(3.0 + Amount * 8.0 + FRand()), 3, 10);
	// (many bodies bursting round the player at once still leave the screen mostly clear)
	n = Min(n, ScreenBlotsAtOnce - Blots.Length);
	for ( i = 0; i < n && Blots.Length < MaxBlots; i++ )
	{
		B.X = 0.05 + 0.9 * FRand();
		B.Y = 0.08 + 0.8 * FRand();
		B.Size = (0.10 + 0.22 * FRand()) * FClamp(Amount + 0.3, 0.7, 1.6);
		B.Born = Level.TimeSeconds;
		B.Life = 1.8 + 1.8 * FRand();
		B.Run = 0.015 + 0.045 * FRand();
		// (sixteen drops, or now and then one of sixteen sprays, bigger)
		B.Sub = Rand(16);
		if ( FRand() < 0.4 )
		{
			B.Sub += 16;
			B.Size *= 1.4;
		}
		B.Alpha = 150 + Rand(90);
		Blots[Blots.Length] = B;
	}
}

// The Void Executioner's blink, on its wielder's view: violet streaks rushing out from the middle, and a violet edge
simulated function AddVoidWarp()
{
	VoidWarpTime = Level.TimeSeconds;
}

simulated function DrawVoidWarp( Canvas C )
{
	local float T, A, S, W;

	T = Level.TimeSeconds - VoidWarpTime;
	if ( T < 0.0 || T > FMax(WarpLinesTime, WarpEdgeTime) )
	{
		VoidWarpTime = 0;
		return;
	}
	if ( T < WarpLinesTime )
	{
		A = 1.0 - T / WarpLinesTime;
		S = 0.9 + 1.1 * (T / WarpLinesTime);
		W = FMax(C.SizeX, C.SizeY) * 1.15 * S;
		C.Style = ERenderStyle.STY_Additive;
		C.SetDrawColor(byte(210.0 * A), byte(120.0 * A), byte(255.0 * A), 255);
		C.SetPos(0.5 * (C.SizeX - W), 0.5 * (C.SizeY - W));
		C.DrawTile(Texture'KFWarpLines', W, W, 0, 0, 512, 512);
	}
	if ( T < WarpEdgeTime )
	{
		A = 1.0 - T / WarpEdgeTime;
		C.Style = ERenderStyle.STY_Alpha;
		C.SetDrawColor(255, 255, 255, byte(255.0 * A));
		C.SetPos(0, 0);
		C.DrawTile(Texture'KFWarpVignette', C.SizeX, C.SizeY, 0, 0, 256, 256);
	}
	C.Style = ERenderStyle.STY_Normal;
	C.SetDrawColor(255, 255, 255, 255);
}

simulated function DrawScreenBlood( Canvas C )
{
	local int i;
	local float Age, A, W, Y;

	C.Style = ERenderStyle.STY_Alpha;
	for ( i = Blots.Length - 1; i >= 0; i-- )
	{
		Age = Level.TimeSeconds - Blots[i].Born;
		if ( Age > Blots[i].Life || Age < 0.0 )
		{
			Blots.Remove(i, 1);
			continue;
		}
		// (full for the first two thirds of its time, then gone)
		A = Blots[i].Alpha * FMin(1.0, 3.0 * (1.0 - Age / Blots[i].Life));
		W = Blots[i].Size * C.SizeX;
		Y = (Blots[i].Y + Blots[i].Run * Age) * C.SizeY;
		C.SetDrawColor(255, 255, 255, byte(A));
		C.SetPos(Blots[i].X * C.SizeX - 0.5 * W, Y - 0.5 * W);
		if ( Blots[i].Sub >= 16 )
			C.DrawTile(Texture'KFX.BloodySpray', W, W, (Blots[i].Sub & 3) * 128, ((Blots[i].Sub - 16) >> 2) * 128, 128, 128);
		else
			C.DrawTile(Texture'KFX.BloodSplash', W, W, (Blots[i].Sub & 3) * 64, (Blots[i].Sub >> 2) * 64, 64, 64);
	}
	C.Style = ERenderStyle.STY_Normal;
	C.SetDrawColor(255, 255, 255, 255);
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
	local rotator CamRot;
	local vector CamPos, ViewDir;
	local int i;

	StartScreenFX();
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
	local float XL,YL,X,Right,SX,BX,BY,BXL,BYL,Fade;
	local int i,Best;
	local byte OldStyle;

	if (  PawnOwner==None || PawnOwner.Weapon==None || TraderOpen() )
	return;

	CurWeaponName = PawnOwner.Weapon.GetHumanReadableName();
	// (shown for a few seconds after the weapon changes, then faded out)
	if( PawnOwner.Weapon!=NameWeapon )
	{
		NameWeapon = PawnOwner.Weapon;
		NameShownAt = Level.TimeSeconds;
	}
	Fade = 1.0 - FClamp((Level.TimeSeconds-NameShownAt-NameHold)/NameFade,0.0,1.0);
	if( Fade<=0.0 )
		return;

	// Sized by the HUD's scale as the rest of the corner is (the font went by the screen's width alone, and at 1280x720
	// stood out over the grenade count), on the grenade's row and clear of its count. A name that does not fit where it
	// begins moves left; one too long for that is set a size or two smaller, then narrowed. (A name that ran past the
	// screen's edge was wrapped, and its last word lost.)
	WidgetBox(C, GrenadeIcon, BX, BY, BXL, BYL);
	SX = DigitsGrenade.TextureScale * HudCanvasScale * ResScaleX * HudScale;
	Right = (DigitsGrenade.PosX * HudCanvasScale + (1.0 - HudCanvasScale) * 0.5) * C.SizeX + DigitsGrenade.OffsetX * SX
		- Max(Len(string(DigitsGrenade.Value)),1) * 39.0 * SX - HudUnits(4.0);
	Best = NearestFont(HudUnits(NameUnits));
	C.Font = LoadFont(Best);
	C.StrLen(CurWeaponName,XL,YL);
	for( i=Best+1; i<ArrayCount(FontPixels) && XL>HudUnits(NameRoom) && FontPixels[i]>=0.75*FontPixels[Best]; i++ )
	{
		C.Font = LoadFont(i);
		C.StrLen(CurWeaponName,XL,YL);
	}
	if( XL>HudUnits(NameRoom) )
	{
		C.FontScaleX = HudUnits(NameRoom)/XL;
		XL = HudUnits(NameRoom);
	}
	X = FMin(C.ClipX - HudUnits(134.4), Right - XL);
	OldStyle = C.Style;
	C.Style = ERenderStyle.STY_Alpha;
	C.SetDrawColor(255,50,50,byte(float(KFHUDAlpha)*Fade));
	C.SetPos(X, BY + 0.5*BYL - 0.5*YL);
	C.DrawTextClipped(CurWeaponName);
	C.FontScaleX = 1.0;
	C.Style = OldStyle;
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
     MaxBlots=14
     ScreenBlotsAtOnce=8
     WarpLinesTime=0.350000
     WarpEdgeTime=0.650000
     ScorePopupDuration=2.5
     PopLife=0.900000
     ScorePopupRiseDistance=45.000000
     ScorePopupRiseTime=0.800000
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
     TorchBatteryIcon=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=14,Y1=180,X2=30,Y2=192),TextureScale=0.500000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-276,OffsetY=-100,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     DigitsClipsLeft=(RenderStyle=STY_Alpha,TextureScale=0.400000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-74,OffsetY=-15,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     DigitsNumLeftInClip=(RenderStyle=STY_Alpha,TextureScale=0.400000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-190,OffsetY=-15,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     HealthBarBackMat=Texture'InterfaceContent.Menu.BorderBoxD'
     HealthBarMat=Texture'KFInterfaceContent.Menu.StatusBarInner'
     GrenadeIcon=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X2=63,Y2=63),TextureScale=0.300000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-16,OffsetY=-100,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     DigitsGrenade=(RenderStyle=STY_Alpha,TextureScale=0.400000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-74,OffsetY=-80,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     HealthArmourBorderLeft=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=14,Y1=204,X2=254,Y2=249),TextureScale=0.500000,DrawPivot=DP_LowerLeft,PosY=1.000000,OffsetX=10,OffsetY=-10,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     HealthMeter=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=41,Y1=186,X2=250,Y2=199),TextureScale=0.500000,DrawPivot=DP_LowerLeft,PosY=1.000000,OffsetX=37,OffsetY=-15,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     ArmourMeter=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=41,Y1=168,X2=250,Y2=181),TextureScale=0.500000,DrawPivot=DP_LowerLeft,PosY=1.000000,OffsetX=37,OffsetY=-38,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
     BatteryMeter=(WidgetTexture=Texture'KFKillMeNow.KFHUDIcons',RenderStyle=STY_Alpha,TextureCoords=(X1=41,Y1=150,X2=250,Y2=163),TextureScale=0.500000,DrawPivot=DP_LowerRight,PosX=1.000000,PosY=1.000000,OffsetX=-60,OffsetY=-100,ScaleMode=SM_Right,Scale=1.000000,Tints[0]=(B=255,G=255,R=255,A=255),Tints[1]=(B=255,G=255,R=255,A=255))
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
     CornerUnits=64.000000
     ClockDigits=0.850000
     NameHold=3.000000
     NameFade=1.000000
     CriticalPromptFade=1.000000
     Edge8X(0)=1.000000
     Edge8X(1)=1.000000
     Edge8X(3)=-1.000000
     Edge8X(4)=-1.000000
     Edge8X(5)=-1.000000
     Edge8X(7)=1.000000
     Edge8Y(1)=1.000000
     Edge8Y(2)=1.000000
     Edge8Y(3)=1.000000
     Edge8Y(5)=-1.000000
     Edge8Y(6)=-1.000000
     Edge8Y(7)=-1.000000
     NameUnits=9.600000
     NameRoom=200.000000
     FontPixels(0)=37
     FontPixels(1)=29
     FontPixels(2)=24
     FontPixels(3)=21
     FontPixels(4)=17
     FontPixels(5)=14
     FontPixels(6)=12
     FontPixels(7)=9
     FontPixels(8)=8
     OverlayFadeSpeed=0.024250
     YouveWonTheMatch="Your squad survived! "
     YouveLostTheMatch="Squad eliminated."
     ConsoleMessagePosX=0.005000
     ConsoleMessagePosY=0.920000
}
