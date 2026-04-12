class KFInvasionLoginMenu extends UT2K4InvasionLoginMenu;

function AddPanels()
{
    local int i;
    local MidGamePanel Panel;

    for ( i = 0; i < Panels.Length; i++ )
    {
        Panel = MidGamePanel(c_Main.AddTabItem(Panels[i]));
        if ( Panel != None )
            Panel.ModifiedChatRestriction = UpdateChatRestriction;
    }
}

defaultproperties
{
     Panels(0)=(ClassName="KFGUI.KFLoginControls")
     Panels(1)=(ClassName="GUI2K4.UT2K4Tab_MidGameRulesCombo",Caption="Server Info",Hint="Current map rotation and game settings")
     Panels(2)=(ClassName="GUI2K4.UT2K4Tab_MidGameVoiceChat",Caption="Communication",Hint="Manage communication with other players")
     Panels(3)=(ClassName="KFGUI.KFTab_MidGameHelp",Caption="Help",Hint="How to survive in Killing Floor")
     Begin Object Class=GUITabControl Name=LoginMenuTC
         bFillSpace=True
         bDockPanels=True
         TabHeight=0.037500
         BackgroundStyleName="TabBackground"
         WinTop=0.060215
         WinLeft=0.012500
         WinWidth=0.974999
         WinHeight=0.044644
         bScaleToParent=True
         bAcceptsInput=True
         OnActivate=LoginMenuTC.InternalOnActivate
     End Object
     c_Main=GUITabControl'KFGui.KFInvasionLoginMenu.LoginMenuTC'

     OnClose=KFInvasionLoginMenu.InternalOnClose
}
