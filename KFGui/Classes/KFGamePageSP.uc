class KFGamePageSP extends UT2K4GamePageSP;

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
         PrimaryCaption="Play"
         PrimaryHint="Face the hoards..."
         SecondaryCaption="Spectate"
         SecondaryHint="Spectate a match with these settings"
         Justification=TXTA_Left
         TextIndent=5
         FontScale=FNS_Small
         WinTop=0.957943
         RenderWeight=0.300000
         TabOrder=8
         OnPreDraw=SPFooter.InternalOnPreDraw
     End Object
     t_Footer=UT2K4GameFooter'KFGui.KFGamePageSP.SPFooter'

     Begin Object Class=BackgroundImage Name=PageBackgroundKF
         Image=Texture'2K4Menus.Controls.menuBackground'
         ImageStyle=ISTY_Tiled
         X1=0
         Y1=0
         X2=4
         Y2=768
         RenderWeight=0.010000
     End Object
     i_Background=BackgroundImage'KFGui.KFGamePageSP.PageBackgroundKF'

     i_bkScan=None

     PanelClass(0)="KFGUI.KFTab_GameTypeSP"
     PanelClass(1)="KFGUI.KFMapPage"
     PanelClass(2)="KFGUI.KFRules"
     PanelClass(3)="KFGUI.KFMutatorPage"
     PanelClass(4)=
     bRenderWorld=True
}
