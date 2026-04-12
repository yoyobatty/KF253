Class KFSettingsPage extends  UT2K4SettingsPage;

#exec OBJ LOAD FILE=..\KFMod254\Textures\KFInterfaceContent.utx


//==============================================================================
//  Description
//
//  Written by Ron Prestenback (based on XInterface.SettingsPage)
//  � 2003, Epic Games, Inc.  All Rights Reserved
//==============================================================================


function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	local rotator PlayerRot;
	local int i;

	Super.InitComponent(MyController, MyOwner);
	PageCaption = t_Header.Caption;

	GetSizingButton();


	// Set camera's pitch to zero when menu initialised (otherwise spinny weap goes kooky)
	PlayerRot = PlayerOwner().Rotation;
	SavedPitch = PlayerRot.Pitch;
	PlayerRot.Pitch = 0;
	PlayerRot.Roll = 0;
	PlayerOwner().SetRotation(PlayerRot);

	for ( i = 0; i < PanelCaption.Length && i < PanelClass.Length && i < PanelHint.Length; i++ )
	{
		Profile("Settings_" $ PanelCaption[i]);
		c_Tabs.AddTab(PanelCaption[i], PanelClass[i],, PanelHint[i]);
		Profile("Settings_" $ PanelCaption[i]);
	}

	tp_Game = UT2K4Tab_GameSettings(c_Tabs.BorrowPanel(PanelCaption[3]));
}

function GetSizingButton()
{
	local int i;

	SizingButton = None;
	for (i = 0; i < Components.Length; i++)
	{
		if (GUIButton(Components[i]) == None)
			continue;

		if ( SizingButton == None || Len(GUIButton(Components[i]).Caption) > Len(SizingButton.Caption))
			SizingButton = GUIButton(Components[i]);
	}
}

function bool InternalOnPreDraw(Canvas Canvas)
{
	local int X, i;
	local float XL,YL;

	if (SizingButton == None)
		return false;

	SizingButton.Style.TextSize(Canvas, SizingButton.MenuState, SizingButton.Caption, XL, YL, SizingButton.FontScale);

	XL += 32;
	X = Canvas.ClipX - XL;
	for (i = Components.Length - 1; i >= 0; i--)
	{
		if (GUIButton(Components[i]) == None)
			continue;

		Components[i].WinWidth = XL;
		Components[i].WinLeft = X;
		X -= XL;
	}

	return false;
}

function bool InternalOnCanClose(optional bool bCanceled)
{
	if(Controller.ActivePage == Self && !tp_Game.ValidStatConfig())
	{
		c_Tabs.ActivateTabByPanel(tp_Game, True);

		Controller.OpenMenu("GUI2K4.UT2K4GenericMessageBox",InvalidStats,tp_Game.l_Warning.Caption);
		return false;
	}

	return true;
}

function InternalOnClose(optional Bool bCanceled)
{
	local rotator NewRot;

	// Reset player
	NewRot = PlayerOwner().Rotation;
	NewRot.Pitch = SavedPitch;
	PlayerOwner().SetRotation(NewRot);

	Super.OnClose(bCanceled);
}

function InternalOnChange(GUIComponent Sender)
{
	Super.InternalOnChange(Sender);

	if ( c_Tabs.ActiveTab == None )
		ActivePanel = None;
	else ActivePanel = Settings_Tabs(c_Tabs.ActiveTab.MyPanel);
}

function BackButtonClicked()
{
	if ( InternalOnCanClose(False) )
	{
		c_Tabs.ActiveTab.OnDeActivate();
		Controller.CloseMenu(False);
	}
}


function DefaultsButtonClicked()
{
	ActivePanel.ResetClicked();
}

function bool ButtonClicked(GUIComponent Sender)
{
	ActivePanel.AcceptClicked();
	return true;
}

event bool NotifyLevelChange()
{
	bPersistent = false;
	LevelChanged();
	return true;
}

defaultproperties
{
     Begin Object Class=GUIHeader Name=SettingHeader
         Caption="Settings"
         RenderWeight=0.300000
     End Object
     t_Header=GUIHeader'KFGui.KFSettingsPage.SettingHeader'

     Begin Object Class=UT2K4Settings_Footer Name=SettingFooter
         RenderWeight=0.300000
         TabOrder=4
         OnPreDraw=SettingFooter.InternalOnPreDraw
     End Object
     t_Footer=UT2K4Settings_Footer'KFGui.KFSettingsPage.SettingFooter'

     Begin Object Class=BackgroundImage Name=PageBackgroundKF
         Image=Texture'2K4Menus.Controls.menuBackground'
         ImageStyle=ISTY_Tiled
         X1=0
         Y1=0
         X2=4
         Y2=768
         RenderWeight=0.010000
     End Object
     i_Background=BackgroundImage'KFGui.KFSettingsPage.PageBackgroundKF'

     i_bkScan=None

     PanelClass(0)="KFGUI.KFTab_DetailSettings"
     PanelClass(1)="KFGUI.KFAudioSettingsTab"
     PanelClass(2)="KFGUI.KFPlayerSettings"
     PanelClass(3)="KFGUI.KFGameSettings"
     PanelClass(4)="KFGUI.KFInputSettings"
     PanelClass(5)="KFGUI.KFHUDSettings"
     PanelClass(6)=
     PanelCaption(5)="HUD"
     PanelCaption(6)=
     PanelHint(2)="Configure your Killing Floor Avatar..."
     PanelHint(5)="Customize your HUD..."
     PanelHint(6)=
     bRenderWorld=True
     OnClose=KFSettingsPage.InternalOnClose
     OnCanClose=KFSettingsPage.InternalOnCanClose
     OnPreDraw=KFSettingsPage.InternalOnPreDraw
}
