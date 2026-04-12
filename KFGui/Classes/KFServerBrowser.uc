class KFServerBrowser extends UT2K4ServerBrowser;

function PopulateGameTypes()
{
    local array<CacheManager.GameRecord> Games;
    local int i, j;

    if (Records.Length > 0)
        Records.Remove(0, Records.Length);

    class'CacheManager'.static.GetGameTypeList(Games);
    for (i = 0; i < Games.Length; i++)
    {
        for (j = 0; j < Records.Length; j++)
        {
            if ((Games[i].GameName <= Records[j].GameName) || (Games[i].GameTypeGroup <= Records[j].GameTypeGroup))
            {
                if (Games[i].GameTypeGroup <= Records[j].GameTypeGroup)
                    continue;
                else break;
            }
        }
        
       // Hacked. Display only the two KF specific gametypes in the filter

       if (Games[i].GameName == "Survival" || Games[i].GameName == "Story")
       {
        Records.Insert(j, 1);
        Records[j] = Games[i];
       }
    }
}

defaultproperties
{
     bPlayerVerified=True
     Begin Object Class=moComboBox Name=GameTypeCombo
         bReadOnly=True
         CaptionWidth=0.100000
         Caption="Game Type"
         OnCreateComponent=GameTypeCombo.InternalOnCreateComponent
         IniOption="@INTERNAL"
         Hint="Choose the gametype to query"
         WinTop=0.050160
         WinLeft=0.638878
         WinWidth=0.358680
         WinHeight=0.035000
         RenderWeight=1.000000
         TabOrder=0
         OnPreDraw=KFServerBrowser.ComboOnPreDraw
         OnLoadINI=KFServerBrowser.InternalOnLoadINI
     End Object
     co_GameType=moComboBox'KFGui.KFServerBrowser.GameTypeCombo'

     Begin Object Class=GUIHeader Name=ServerBrowserHeader
         bUseTextHeight=True
         Caption="Server Browser"
     End Object
     t_Header=GUIHeader'KFGui.KFServerBrowser.ServerBrowserHeader'

     Begin Object Class=UT2k4Browser_Footer Name=FooterPanel
         WinTop=0.917943
         TabOrder=4
         OnPreDraw=FooterPanel.InternalOnPreDraw
     End Object
     t_Footer=UT2k4Browser_Footer'KFGui.KFServerBrowser.FooterPanel'

     Begin Object Class=BackgroundImage Name=PageBackground
         Image=Texture'2K4Menus.Controls.menuBackground'
         ImageStyle=ISTY_Scaled
         RenderWeight=0.010000
     End Object
     i_Background=BackgroundImage'KFGui.KFServerBrowser.PageBackground'

     PanelClass(0)="KFGUI.KFServerListPageInternet"
     PanelClass(1)="GUI2K4.UT2K4Browser_ServerListPageLAN"
     PanelClass(2)="none"
     PanelClass(3)="none"
     PanelClass(4)="none"
     PanelClass(5)="none"
     PanelCaption(0)="Internet Games"
     PanelCaption(1)="LAN"
     PanelCaption(3)="Chat"
     PanelHint(0)="Choose from hundreds of Killing FLoor servers across the world"
     PanelHint(1)="View all Killing Floor servers currently running on your LAN"
     PanelHint(3)="KF integrated IRC client"
     PanelHint(5)="The latest on KF"
     bRenderWorld=True
     OnOpen=KFServerBrowser.BrowserOpened
}
