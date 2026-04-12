class KFHudSettings extends UT2K4Tab_HudSettings;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super(Settings_Tabs).InitComponent(MyController, MyOwner);

	i_BG1.ManageComponent(ch_Visible);
	i_BG1.ManageComponent(ch_Weapons);
	i_BG1.ManageComponent(ch_Personal);
	i_BG1.ManageComponent(ch_Score);
	i_BG1.ManageComponent(ch_Portraits);
	i_BG1.ManageComponent(ch_VCPortraits);
	i_BG1.ManageComponent(ch_DeathMsgs);
	i_BG1.ManageComponent(nu_MsgCount);
	i_BG1.ManageComponent(nu_MsgScale);
	i_BG1.ManageComponent(nu_MsgOffset);

	sl_Opacity.MySlider.bDrawPercentSign = True;
	sl_Scale.MySlider.bDrawPercentSign = True;
}

function InternalOnLoadINI(GUIComponent Sender, string s)
{
	local HUD H;

	H = PlayerOwner().myHUD;
	switch (Sender)
	{
		case ch_DeathMsgs:
			bNoMsgs = class'XGame.xDeathMessage'.default.bNoConsoleDeathMessages;
			ch_DeathMsgs.SetComponentValue(bNoMsgs,true);
			break;

		case ch_Visible:
			bVis = H.bHideHUD;
			ch_Visible.SetComponentValue(bVis,true);
			InitializeHUDColor();
			break;

		case ch_Weapons:
			bWeapons = H.bShowWeaponInfo;
			ch_Weapons.SetComponentValue(bWeapons,true);
			break;

		case ch_Personal:
			bPersonal = H.bShowPersonalInfo;
			ch_Personal.SetComponentValue(bPersonal,true);
			break;

		case ch_Score:
			bScore = H.bShowPoints;
			ch_Score.SetComponentValue(bScore,true);
			break;

		case ch_WeaponBar:
			bWeaponBar = H.bShowWeaponBar;
			ch_WeaponBar.SetComponentValue(bWeaponBar,true);
			break;

		case ch_Portraits:
			bPortraits = H.bShowPortrait;
			ch_Portraits.SetComponentValue(bPortraits,true);
			break;

		case nu_MsgCount:
			iCount = H.ConsoleMessageCount;
			nu_MsgCount.SetComponentValue(iCount,true);
			break;

		case nu_MsgScale:
			iScale = 8 - H.ConsoleFontSize;
			nu_MsgScale.SetComponentValue(iScale,true);
			break;

		case nu_MsgOffset:
			iOffset = H.MessageFontOffset+4;
			nu_MsgOffset.SetComponentValue(iOffset,true);
			break;

		case ch_VCPortraits:
			bVCPortraits = H.bShowPortraitVC;
			ch_VCPortraits.SetComponentValue(bVCPortraits,true);
			break;

		default:
			GUIMenuOption(Sender).SetComponentValue(s,true);
	}
}

function InitializeHUDColor()
{
	fScale = PlayerOwner().myHUD.HudScale * 100;
	fOpacity = (PlayerOwner().myHUD.HudOpacity / 255) * 100;

	sl_Scale.SetValue(fScale);
	sl_Opacity.SetValue(fOpacity);

	UpdatePreviewColor();
}

defaultproperties
{
     Begin Object Class=GUIImage Name=PreviewBackground
         Image=Texture'KillingFloorHUD.Generic.HUD'
         ImageStyle=ISTY_Scaled
         ImageAlign=IMGA_Center
         X1=0
         Y1=110
         X2=166
         Y2=163
         WinTop=0.211713
         WinLeft=0.749335
         WinWidth=0.163437
         WinHeight=0.121797
         RenderWeight=1.002000
     End Object
     i_PreviewBG=GUIImage'KFGui.KFHudSettings.PreviewBackground'

     Begin Object Class=GUIImage Name=Preview
         Image=Texture'KillingFloorHUD.Generic.HUD'
         ImageStyle=ISTY_Scaled
         ImageAlign=IMGA_Center
         X1=74
         Y1=165
         X2=123
         Y2=216
         WinTop=0.211559
         WinLeft=0.749828
         WinWidth=0.063241
         WinHeight=0.099531
         RenderWeight=1.003000
     End Object
     i_Preview=GUIImage'KFGui.KFHudSettings.Preview'

     sl_Red=None

     sl_Green=None

     sl_Blue=None

     ch_WeaponBar=None

     ch_EnemyNames=None

     ch_CustomColor=None

     co_CustomHUD=None

     b_CustomHUD=None

}
