class KFMapPage extends UT2K4Tab_MainSP;

// Query the CacheManager for the maps that correspond to this gametype, then fill the main list
function InitMaps( optional string MapPrefix )
{
    local int i, j, BV;
    local bool bTemp;
    local string Package, Item, CurrentItem, Desc;
    local GUITreeNode StoredItem;
    local DecoText DT;
    local array<string> CustomLinkSetups;

    // Make sure we have a map prefix
    if ( MapPrefix == "" )
        MapPrefix = GetMapPrefix();

    // Temporarily disable notification in all components
    bTemp = Controller.bCurMenuInitialized;
    Controller.bCurMenuInitialized = False;

    if ( li_Maps.IsValid() )
        li_Maps.GetElementAtIndex(li_Maps.Index, StoredItem);

    // Get the list of maps for the current gametype
    class'CacheManager'.static.GetMapList( CacheMaps, MapPrefix );
    if ( MapHandler.GetAvailableMaps(MapHandler.GetGameIndex(CurrentGameType.ClassName), Maps) )
    {
        li_Maps.bNotify = False;
        li_Maps.Clear();

        for ( i = 0; i < Maps.Length; i++ )
        {
            DT = None;
            if ( class'CacheManager'.static.IsDefaultContent(Maps[i].MapName) )
            {
                if ( bOnlyShowCustom )
                    continue;
            }
            else if ( bOnlyShowOfficial )
                continue;

            j = FindCacheRecordIndex(Maps[i].MapName);
            if ( class'CacheManager'.static.Is2003Content(Maps[i].MapName) )
            {
                if ( CacheMaps[j].TextName != "" )
                {
                    if ( !Divide(CacheMaps[j].TextName, ".", Package, Item) )
                {
                        Package = "XMaps";
                        Item = CacheMaps[j].TextName;
                    }
                }

                DT = class'xUtil'.static.LoadDecoText(Package, Item);
            }

            if ( DT != None )
                Desc = JoinArray(DT.Rows, "|");
            else
                Desc =CacheMaps[j].Description;


            // KF Map Hack
            if ( CurrentGameType.MapPrefix ~= "KF" )
            {
             if (Maps[i].MapName != "KF-Intro" && Maps[i].MapName != "KF-Menu")
              li_Maps.AddItem( Maps[i].MapName, Maps[i].MapName, ,,Desc);
            }
            else
             li_Maps.AddItem( Maps[i].MapName, Maps[i].MapName, ,,Desc);


            // for now, limit this to power link setups only
            if ( CurrentGameType.MapPrefix ~= "ONS" )
            {

                // Big Hack Time for the bonus pack

                CurrentItem = Maps[i].MapName;
                for (BV=0;BV<2;BV++)
                {
                    if ( Maps[i].Options.Length > 0 )
                    {
                        Package = CacheMaps[j].Description;

                        // Add the "auto link setup" item
                        li_Maps.AddItem( AutoSelectText @ LinkText, Maps[i].MapName $ "?LinkSetup=Random", CurrentItem,,Package );

                        // Now add all official link setups
                        for ( j = 0; j < Maps[i].Options.Length; j++ )
                            li_Maps.AddItem(Maps[i].Options[j].Value @ LinkText, Maps[i].MapName $ "?LinkSetup=" $ Maps[i].Options[j].Value, CurrentItem,,Package );
                    }

                    // Now to add the custom setups
                    CustomLinkSetups = GetPerObjectNames(Maps[i].MapName, "ONSPowerLinkCustomSetup");
                    for ( j = 0; j < CustomLinkSetups.Length; j++ )
                        li_Maps.AddItem(CustomLinkSetups[j] @ LinkText, Maps[i].MapName $ "?" $ "LinkSetup=" $ CustomLinkSetups[j], CurrentItem,,Package);

                    if ( !OrigONSMap(Maps[i].MapName) )
                        break;

                    else if (BV<1 && Controller.bECEEdition)
                    {

                        li_Maps.AddItem( Maps[i].MapName$BonusVehicles, Maps[i].MapName, ,,BonusVehiclesMsg$Desc);
                        CurrentItem=CurrentItem$BonusVehicles;
                    }

                    if ( !Controller.bECEEdition )  // Don't do the second loop if not the ECE
                        break;

                }

            }
            
            




        }
    }

    if ( li_Maps.bSorted )
        li_Maps.SortList();

    if ( StoredItem.Caption != "" )
    {
        i = li_Maps.FindFullIndex(StoredItem.Caption, StoredItem.Value, StoredItem.ParentCaption);
        if ( i != -1 )
            li_Maps.SilentSetIndex(i);
    }

    li_Maps.bNotify = True;

    Controller.bCurMenuInitialized = bTemp;
}

function MaplistConfigClick( GUIComponent Sender )
{
    local MaplistEditor MaplistPage;

    // open maplist config page
    if ( Controller.OpenMenu(MaplistEditorMenu) )
    {
        MaplistPage = MaplistEditor(Controller.ActivePage);
        if ( MaplistPage != None )
        {
            MaplistPage.MainPanel = self;
            MaplistPage.bOnlyShowOfficial = bOnlyShowOfficial;
            MaplistPage.bOnlyShowCustom = bOnlyShowCustom;
            MaplistPage.Initialize(MapHandler);
        }
    }
}

defaultproperties
{
     LastSelectedMap="KF-Manor"
     Begin Object Class=moCheckBox Name=FilterCheck
         CaptionWidth=0.100000
         ComponentWidth=0.900000
         Caption="Only Official KF Maps"
         OnCreateComponent=FilterCheck.InternalOnCreateComponent
         Hint="Hides all those that are not official Killing Floor maps"
         WinTop=0.772865
         WinLeft=0.051758
         WinWidth=0.341797
         WinHeight=0.030035
         TabOrder=1
         OnChange=KFMapPage.ChangeMapFilter
     End Object
     ch_OfficialMapsOnly=moCheckBox'KFGui.KFMapPage.FilterCheck'

}
