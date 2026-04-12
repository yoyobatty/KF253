class KFModelSelect extends UT2k4ModelSelect;

function RefreshCharacterList(string ExcludedChars, optional string Race)
{
    local int i; //, j;
    local array<string> Excluded;
    local bool blocked;

    // Prevent list from calling OnChange events
    CharList.List.bNotify = False;
    CharList.Clear();


    Split(ExcludedChars, ";", Excluded);
    for(i=0; i<PlayerList.Length; i++)
    {

        //if ( Race == "" || Race ~= Playerlist[i].Race )
        //{
            /*
            // Check that this character is selectable
            if ( PlayerList[i].Menu != "" )
            {
                for (j = 0; j < Excluded.Length; j++)
                    if ( InStr(";" $ Playerlist[i].Menu $ ";", ";" $ Excluded[j] $ ";") != -1 )
                        break;

                if ( j < Excluded.Length )
                    continue;
            }
            */

            bLocked = !IsUnLocked(PlayerList[i]);
            // Modded to HARDCODE the possible characters you can pick (seeing as players were picking UT models at whim)
            if (Playerlist[i].DefaultName == "Soldier_Black"  ||
                Playerlist[i].DefaultName == "Soldier_Urban"  ||
                Playerlist[i].DefaultName ~= "Soldier"        ||
                Playerlist[i].DefaultName == "Soldier_Lewis"  ||
                Playerlist[i].DefaultName == "Soldier_Davin"  ||
                Playerlist[i].DefaultName == "Hazmat"  ||
                Playerlist[i].DefaultName == "Soldier_Kara"   ||
                Playerlist[i].DefaultName == "Soldier_Powers" ||
                Playerlist[i].DefaultName == "Stalker" ||
                Playerlist[i].DefaultName == "Soldier_Masterson")
            {
              CharList.List.Add( Playerlist[i].Portrait, i, int(bLocked) );
            }
        //}
    }

    CharList.List.LockedMat = LockedImage;
    CharList.List.bNotify = True;
}

function PopulateRaces()
{
   /*
    local int i;
    local string specName;

    for(i=0; i<PlayerList.Length; i++)
    {
        specName=Caps(PlayerList[i].Race);
        if (specName!="" && co_Race.MyComboBox.List.FindIndex(specName,True) == -1)
            co_Race.AddItem(specName);
    }
    */
}

defaultproperties
{
     co_Race=None

     SpinnyDudeOffset=(X=0.000000,Y=0.000000,Z=0.000000)
}
