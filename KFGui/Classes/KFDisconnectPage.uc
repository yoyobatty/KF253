// Fancy new in-game disconnect page

class KFDisconnectPage extends UT2K4DisconnectOptionPage;

function bool InternalOnClick(GUIComponent Sender)
{
    local GUIController C;


    if ( GUIButton(Sender) == None )
        return false;

    C = Controller;
    switch (GUIButton(Sender).Caption)
    {
        case b_MainMenu.Caption:
                 C.ViewportOwner.Console.ConsoleCommand( "DISCONNECT" );
                 C.ViewportOwner.Console.ConsoleCommand("OPEN Menu?Game=unrealgame.cinematicgame");
                 return true;
            //UT2K4GUIController(C).ReturnToMainMenu();


        case b_ServerBrowser.Caption:
            C.OpenMenu("KFGUI.KFSettingsPage");
            return true;

        case b_Quit.Caption:
            C.OpenMenu(C.GetQuitPage());
            return true;

        case b_Reconnect.Caption:
            C.ViewportOwner.Console.DelayedConsoleCommand("Reconnect");
            C.CloseMenu(false);
            return True;
//			Controller.CloseAll(false,true);
    }

    return false;
}

defaultproperties
{
     Begin Object Class=GUIButton Name=MainMenuButton
         Caption="MAIN MENU"
         bAutoSize=True
         WinTop=0.548235
         WinLeft=0.157811
         WinWidth=0.132806
         TabOrder=1
         OnClick=KFDisconnectPage.InternalOnClick
         OnKeyEvent=MainMenuButton.InternalOnKeyEvent
     End Object
     b_MainMenu=GUIButton'KFGui.KFDisconnectPage.MainMenuButton'

     Begin Object Class=GUIButton Name=SettingsButton
         Caption="SETTINGS"
         bAutoSize=True
         WinTop=0.548235
         WinLeft=0.345702
         WinWidth=0.132806
         TabOrder=0
         OnClick=KFDisconnectPage.InternalOnClick
         OnKeyEvent=SettingsButton.InternalOnKeyEvent
     End Object
     b_ServerBrowser=GUIButton'KFGui.KFDisconnectPage.SettingsButton'

     Begin Object Class=GUIButton Name=ReconnectButton
         Caption="RETRY"
         bAutoSize=True
         WinTop=0.548235
         WinLeft=0.345702
         WinWidth=0.132806
         TabOrder=0
         OnClick=KFDisconnectPage.InternalOnClick
         OnKeyEvent=ReconnectButton.InternalOnKeyEvent
     End Object
     b_Reconnect=GUIButton'KFGui.KFDisconnectPage.ReconnectButton'

     Begin Object Class=GUIButton Name=QuitButton
         Caption="QUIT"
         bAutoSize=True
         WinTop=0.548235
         WinLeft=0.627929
         WinWidth=0.223632
         TabOrder=2
         OnClick=KFDisconnectPage.InternalOnClick
         OnKeyEvent=QuitButton.InternalOnKeyEvent
     End Object
     b_Quit=GUIButton'KFGui.KFDisconnectPage.QuitButton'

     Begin Object Class=GUILabel Name=cNetStatLabel
         Caption="Select an option"
         TextAlign=TXTA_Center
         bMultiLine=True
         FontScale=FNS_Large
         StyleName="TextLabel"
         WinTop=0.314687
         WinHeight=0.099922
         bBoundToParent=True
     End Object
     l_Status=GUILabel'KFGui.KFDisconnectPage.cNetStatLabel'

     OnCanClose=KFDisconnectPage.CanClose
     OnPreDraw=KFDisconnectPage.InternalOnPreDraw
     OnKeyEvent=KFDisconnectPage.InternalOnKeyEvent
}
