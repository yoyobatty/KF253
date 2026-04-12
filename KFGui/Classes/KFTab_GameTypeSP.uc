class KFTab_GametypeSP extends UT2k4Tab_gametypeMP;
          

function PopulateGameTypes()
{
    local int i,cnt;

    class'CacheManager'.static.GetGameTypeList(GameTypes);

	// Get the list of valid gametypes, and separate them into the appropriate lists
	// All official gametypes go into the large listbox
	// All custom gametypes go into the combo box (sorry guys!)
    for (i = 0; i < GameTypes.Length; i++)
    {
		if ( HasMaps(GameTypes[i]))
		{
			//if (GameTypes[i].GameTypeGroup < 3 || GameTypes[i].GameAcronym == "KF" || GameTypes[i].GameAcronym == "KFDM" )
	        if (GameTypes[i].GameAcronym == "KF" || GameTypes[i].GameName == "Story")
	            AddEpicGameType( GameTypes[i].GameName, GameTypes[i].MapListClassName);
			else
				cnt++;    //UNCOMMENT THIS TO MOD!!!
		}
		else if (GameTypes[i].GameTypeGroup >= 3)
		{
			Log("Gametype"@GameTypes[i].ClassName@"found but it has no maps", 'Warning');
		}
    }
 }

//	li_Games.SortList();
 /*
	if (cnt>0)
	{
	    li_Games.Add(CustomGameCaption,None,"",true);

	    for (i = 0; i < GameTypes.Length; i++)
	    {
			if ( HasMaps(GameTypes[i]) && GameTypes[i].GameAcronym != "KF"  && GameTypes[i].GameAcronym != "KFDM" )
			{
				if (GameTypes[i].GameTypeGroup >= 3)
		            AddEpicGameType( GameTypes[i].GameName, GameTypes[i].MapListClassName);
		    }
	    }
		li_Games.Insert(0,EpicGameCaption,None,"",true,true);
		li_Games.SetIndex(1);

    }

}                    // GameTypes[i].GameAcronym == "KF" ||
 */

defaultproperties
{
     EpicGameCaption=""
     CustomGameCaption=""
}
