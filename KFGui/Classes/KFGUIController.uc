Class KFGUIController extends UT2K4GUIController;

#exec OBJ LOAD FILE=..\KFMod254\Textures\KFInterfaceContent.utx
#exec OBJ LOAD FILE=..\KFMod254\Textures\2K4MenuSounds.uax
#exec OBJ LOAD FILE=..\KFMod254\Textures\2K4Menus.utx

function PurgeComponentClasses()
{
	if ( RegisteredClasses.Length > 0 )
		RegisteredClasses.Remove(0, RegisteredClasses.Length);

	Super.PurgeComponentClasses();
}


function ReturnToMainMenu()
{
    CloseAll(true);

    if ( MenuStack.Length == 0 )
        OpenMenu(GetMainMenuClass());
}
static simulated function string GetServerBrowserPage()
{
	return "KFGUI.KFServerBrowser";
}

defaultproperties
{
     STYLE_NUM=62
     DefaultStyleNames(0)="KFGUI.KF_RoundButton"
     DefaultStyleNames(2)="KFGUI.KF_SquareButton"
     DefaultStyleNames(3)="KFGUI.KF_ListBox"
     DefaultStyleNames(5)="KFGUI.KF_TextButton"
     DefaultStyleNames(7)="KFGUI.KF_Header"
     DefaultStyleNames(9)="KFGUI.KF_TabButton"
     DefaultStyleNames(13)="KFGUI.KF_ServerBrowserGrid"
     DefaultStyleNames(14)="KFGUI.KF_NoBackground"
     DefaultStyleNames(23)="KFGUI.KF_TextLabel"
     DefaultStyleNames(29)="KFGUI.KF_ContextMenu"
     DefaultStyleNames(30)="KFGUI.KF_ServerListContextMenu"
     DefaultStyleNames(31)="KFGUI.KF_ListSelection"
     DefaultStyleNames(32)="GUI2K4.STY2TabBackGround"
     DefaultStyleNames(33)="KFGUI.KF_BrowserListSel"
     DefaultStyleNames(34)="KFGUI.KF_EditBox"
     DefaultStyleNames(39)="KFGUI.KF_ListSectionHeader"
     DefaultStyleNames(41)="KFGUI.KF_ListHighlight"
     DefaultStyleNames(48)="KFGUI.KF_FooterButton"
     DefaultStyleNames(59)="GUI2K4.STY2AltComboButton"
     DefaultStyleNames(60)="KFGUI.KF_ItemBoxInfo"
     DefaultStyleNames(61)="KFGUI.GUIVetToolTipMOStyle"
     MainMenuOptions(2)="KFGUI.KFGamePageSP"
     MainMenuOptions(3)="KFGUI.KFGamePageMP"
     MainMenuOptions(5)="KFGUI.KFSettingsPage"
     MainMenuOptions(6)="KFGUI.KFQuitPage"
}
