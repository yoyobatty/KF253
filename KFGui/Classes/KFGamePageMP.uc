class KFGamePageMP extends UT2K4GamePageMP;

function StartGame(string GameURL, bool bAlt)
{
    local GUIController C;

    C = Controller;

    if (bAlt)
    {
        if ( mcServerRules != None )
            GameURL $= mcServerRules.Play();

        // Append optional server flags
        PlayerOwner().ConsoleCommand("relaunch"@GameURL@"-server  -log=server.log  -mod=KFMod254");
    }
    else
        PlayerOwner().ClientTravel(GameURL $ "?Listen",TRAVEL_Absolute,False);

    C.CloseAll(false,True);
}

function UpdateBotSetting( string NewValue, moNumericEdit BotControl )
{
    local GUITabButton BotTab;
   // local byte Value;

    if ( BotControl == None || NewValue == "" )
        return;

        BotTab = GetBotTab();

        EnableComponent(BotControl);
        EnableComponent(BotTab);

}

defaultproperties
{
     PageCaption="Killing Floor"
     Begin Object Class=UT2K4GameFooter Name=SPFooter
         PrimaryCaption="Listen"
         PrimaryHint="Start a listen server..."
         SecondaryCaption="Dedicated"
         SecondaryHint="Start a dedicated server..."
         Justification=TXTA_Left
         TextIndent=5
         FontScale=FNS_Small
         WinTop=0.957943
         RenderWeight=0.300000
         TabOrder=8
         OnPreDraw=SPFooter.InternalOnPreDraw
     End Object
     t_Footer=UT2K4GameFooter'KFGui.KFGamePageMP.SPFooter'

     Begin Object Class=BackgroundImage Name=PageBackgroundKF
         Image=Texture'2K4Menus.Controls.menuBackground'
         ImageStyle=ISTY_Tiled
         X1=0
         Y1=0
         X2=4
         Y2=768
         RenderWeight=0.010000
     End Object
     i_Background=BackgroundImage'KFGui.KFGamePageMP.PageBackgroundKF'

     i_bkScan=None

     PanelClass(0)="KFGUI.KFTab_GameTypeSP"
     PanelClass(1)="KFGUI.KFMapPage"
     PanelClass(2)="KFGUI.KFRules"
     PanelClass(3)="KFGUI.KFMutatorPage"
     PanelClass(4)=
     bRenderWorld=True
}
