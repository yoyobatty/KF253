class KFMutatorPage extends UT2K4Tab_MutatorBase;

var automated moCheckBox b_Allow2004Muts;

// Called when a new gametype has been selected - remove any mutators which affect physics if
// this gametype doesn't allow them
function SetCurrentGame( CacheManager.GameRecord CurrentGame )
{
    local int i;
    local string m, t;
    local class<GameInfo> GameClass;

    if ( MutatorList.Length > 0 )
        m = BuildActiveMutatorString();
    else m = LastActiveMutators;

    class'CacheManager'.static.GetMutatorList(MutatorList);
    GameClass = class<GameInfo>(DynamicLoadObject(CurrentGame.ClassName, class'Class'));
    if ( GameClass != None )
    {
        for ( i = MutatorList.Length - 1; i >= 0; i-- )
            if ( !GameClass.static.AllowMutator(MutatorList[i].ClassName) )
                MutatorList.Remove(i,1);
    }

    // Disable the list's OnChange() delegate
    lb_Active.List.bNotify = False;
    lb_Avail.List.bNotify = False;

    lb_Active.List.Clear();
    lb_Avail.List.Clear();

	for (i=0;i<MutatorList.Length;i++)
	{
		if ( Left(MutatorList[i].GroupName,2)== "KF" )
			lb_Avail.List.Add(MutatorList[i].FriendlyName,,MutatorList[i].Description);
        else if ( b_Allow2004Muts.IsChecked() )
			lb_Avail.List.Add(MutatorList[i].FriendlyName,,MutatorList[i].Description);
	}

    t = NextMutatorInString(m);
    while (t!="")
    {
        SelectMutator(t);
        t = NextMutatorInString(m);
    }

    lb_Active.List.bNotify = True;
    lb_Avail.List.bNotify = True;

    lb_Active.List.CheckLinkedObjects(lb_Active.List);
    lb_Avail.List.CheckLinkedObjects(lb_Avail.List);
}

function ListChange(GUIComponent Sender)
{
    local int i;
    local string m, t;
    local class<GameInfo> GameClass;

    Super.ListChange(Sender);
	if (Sender == b_Allow2004Muts)
	{

        if ( MutatorList.Length > 0 )
            m = BuildActiveMutatorString();
        else m = LastActiveMutators;

        class'CacheManager'.static.GetMutatorList(MutatorList);
        GameClass = class<GameInfo>(DynamicLoadObject(CurrentGame.ClassName, class'Class'));
        if ( GameClass != None )
        {
            for ( i = MutatorList.Length - 1; i >= 0; i-- )
                if ( !GameClass.static.AllowMutator(MutatorList[i].ClassName) )
                    MutatorList.Remove(i,1);
        }

        // Disable the list's OnChange() delegate
        lb_Active.List.bNotify = False;
        lb_Avail.List.bNotify = False;

        lb_Active.List.Clear();
        lb_Avail.List.Clear();

        for (i=0;i<MutatorList.Length;i++)
        {
            if ( Left(MutatorList[i].GroupName,2)== "KF" )
                lb_Avail.List.Add(MutatorList[i].FriendlyName,,MutatorList[i].Description);
            else if ( b_Allow2004Muts.IsChecked() )
                lb_Avail.List.Add(MutatorList[i].FriendlyName,,MutatorList[i].Description);
        }

        t = NextMutatorInString(m);
        while (t!="")
        {
            SelectMutator(t);
            t = NextMutatorInString(m);
        }

        lb_Active.List.bNotify = True;
        lb_Avail.List.bNotify = True;

        lb_Active.List.CheckLinkedObjects(lb_Active.List);
        lb_Avail.List.CheckLinkedObjects(lb_Avail.List);
    }
}

defaultproperties
{
    Begin Object Class=moCheckBox Name=AllowUT2k4Muts
        Caption="Allow UT2004 mutators"
        Hint="Allows mutators from UT2004, be careful."
        WinTop=0.00259
        WinLeft=0.42000
        WinWidth=0.145000
        WinHeight=0.050000
        OnClickSound=CS_Down
        OnChange=KFMutatorPage.ListChange
    End Object
    b_Allow2004Muts=AllowUT2k4Muts
}
