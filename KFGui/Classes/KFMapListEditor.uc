class KFMaplistEditor extends MaplistEditor;

// Fill the custom maplist selection combo with the custom maplists for this gametype
function RefreshMaplistNames(optional string CurrentMaplist)
{
    local int i, Index, Current;
    local array<string> Ar;

    Index = MapHandler.GetGameIndex(CurrentGameType.ClassName);
    Ar = MapHandler.GetMapListNames(Index);

    Current = MapHandler.GetRecordIndex(Index, CurrentMaplist);
    if ( Current == -1 )
        Current = MapHandler.GetActiveList(Index);

    // Disable OnChange() calls
    co_Maplist.List.bNotify = False;
    co_Maplist.List.Clear();

    for ( i = 0; i < Ar.Length; i++ )
        co_Maplist.AddItem(Ar[i]);

    co_Maplist.List.bNotify = True;
    CurrentMaplist = MapHandler.GetMaplistTitle(Index, Current);

    co_Maplist.SetText(CurrentMaplist, True);
}


// Query the CacheManager for the maps that correspond to this gametype, then fill the 'available' list
function ReloadAvailable()
{
    local int i, j;
    local array<string> CustomLinkSetups;

    if ( MapHandler.GetAvailableMaps(GameIndex, Maps) )
    {
        li_Avail.bNotify = False;
        li_Avail.Clear();

        for ( i = 0; i < Maps.Length; i++ )
        {
            if ( class'CacheManager'.static.IsDefaultContent(Maps[i].MapName) )
            {
                if ( bOnlyShowCustom )
                    continue;
            }
            else if ( bOnlyShowOfficial )
                continue;

            // KF Hack . OMG HiJacked!
            if ( Maps[i].Options.Length > 0 && Maps[i].MapName != "KF-Intro" && Maps[i].MapName != "KF-Menu"  )
            {
                // Add the "auto link setup" item
                li_Avail.AddItem( AutoSelectText @ LinkText, Maps[i].MapName $ "?LinkSetup=Random", Maps[i].MapName );

                // Now add all custom link setups
                for ( j = 0; j < Maps[i].Options.Length; j++ )
                    li_Avail.AddItem(Maps[i].Options[j].Value @ LinkText, Maps[i].MapName $ "?LinkSetup=" $ Maps[i].Options[j].Value, Maps[i].MapName );
            }
            //else li_Avail.AddItem( Maps[i].MapName, Maps[i].MapName );

            if ( CurrentGameType.MapPrefix == "ONS" )
            {
                CustomLinkSetups = GetPerObjectNames( Maps[i].MapName, "ONSPowerLinkCustomSetup" );
                for ( j = 0; j < CustomLinkSetups.Length; j++ )
                    li_Avail.AddItem( CustomLinkSetups[j] @ LinkText, Maps[i].MapName $ "?LinkSetup=" $ CustomLinkSetups[j], Maps[i].MapName );

                if ( OrigONSMap(Maps[i].MapName) && Controller.bECEEdition )
                {
                    li_Avail.AddItem( Maps[i].MapName$BonusVehicles, Maps[i].MapName$"?BonusVehicles=true" );

                    // Now add all custom link setups
                    for ( j = 0; j < Maps[i].Options.Length; j++ )
                        li_Avail.AddItem(Maps[i].Options[j].Value @ LinkText, Maps[i].MapName $ "?LinkSetup=" $ Maps[i].Options[j].Value$"?BonusVehicles=true" , Maps[i].MapName$BonusVehicles );

                    CustomLinkSetups = GetPerObjectNames( Maps[i].MapName, "ONSPowerLinkCustomSetup" );
                    for ( j = 0; j < CustomLinkSetups.Length; j++ )
                        li_Avail.AddItem( CustomLinkSetups[j] @ LinkText, Maps[i].MapName $ "?LinkSetup=" $ CustomLinkSetups[j]$"?BonusVehicles=true", Maps[i].MapName$BonusVehicles );
                }
            }
        }
    }

    if ( li_Avail.bSorted )
        li_Avail.Sort();

    li_Avail.bNotify = True;
}

defaultproperties
{
}
