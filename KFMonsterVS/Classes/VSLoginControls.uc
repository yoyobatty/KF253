class VSLoginControls extends KFLoginControls;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	local string s;
	local int i;
	local eFontScale FS;

	Super(MidGamePanel).InitComponent(MyController, MyOwner);

	li_Red  = lb_Red.List;
	li_FFA  = lb_FFA.List;

	s = GetSizingCaption();
	for ( i = 0; i < Controls.Length; i++ )
	{
		if ( GUIButton(Controls[i]) != None )
		{
			GUIButton(Controls[i]).bAutoSize = True;
			GUIButton(Controls[i]).SizingCaption = s;
			GUIButton(Controls[i]).AutoSizePadding.HorzPerc = 0.04;
			GUIButton(Controls[i]).AutoSizePadding.VertPerc = 0.5;
		}
	}
	PlayerStyle = MyController.GetStyle(PlayerStyleName, fs);
}
function string GetSizingCaption()
{
	local int i;
	local string s;

	for ( i = 0; i < Controls.Length; i++ )
	{
		if ( GUIButton(Controls[i]) != none )
		{
			if ( Len(s)==0 || Len(GUIButton(Controls[i]).Caption) > Len(s) )
				s = GUIButton(Controls[i]).Caption;
		}
	}
	return s;
}
function SetupGroups()
{
	local PlayerController PC;

	PC = PlayerOwner();

	RemoveComponent(i_JoinRed, true);
	RemoveComponent(lb_Red, true);
	RemoveComponent(sb_Red, true);

	if( PC.GameReplicationInfo != None && PC.GameReplicationInfo.bNoTeamChanges )
		RemoveComponent(b_Team);

	if ( PC.Level.NetMode != NM_Client )
	{
		RemoveComponent(b_Favs);
		RemoveComponent(b_Browser);
	}
	else if ( CurrentServerIsInFavorites() )
		DisableComponent(b_Favs);

	if ( PC.Level.NetMode == NM_StandAlone )
	{
		RemoveComponent(b_MapVote, True);
		RemoveComponent(b_MatchSetup, True);
		RemoveComponent(b_KickVote, True);
	}
	else if ( PC.VoteReplicationInfo != None )
	{
		if ( !PC.VoteReplicationInfo.MapVoteEnabled() )
			RemoveComponent(b_MapVote,True);
		if ( !PC.VoteReplicationInfo.KickVoteEnabled() )
			RemoveComponent(b_KickVote);
		if ( !PC.VoteReplicationInfo.MatchSetupEnabled() )
			RemoveComponent(b_MatchSetup);
	}
	else
	{
		RemoveComponent(b_MapVote);
		RemoveComponent(b_KickVote);
		RemoveComponent(b_MatchSetup);
	}
	RemapComponents();
}
function SetButtonPositions(Canvas C)
{
	local int i, j, ButtonsPerRow, ButtonsLeftInRow, NumButtons;
	local float Width, Height, Center, X, Y, YL, ButtonSpacing;

	Width = b_Settings.ActualWidth();
	Height = b_Settings.ActualHeight();
	Center = ActualLeft() + (ActualWidth() / 2.0);

	ButtonSpacing = Width * 0.05;
	YL = Height * 1.2;
	Y = b_Settings.ActualTop();

	ButtonsPerRow = ActualWidth() / (Width + ButtonSpacing);
	ButtonsLeftInRow = ButtonsPerRow;

	for ( i = 0; i < Components.Length; i++)
	{
		if ( Components[i].bVisible && GUIButton(Components[i]) != none )
			NumButtons++;
	}
	if ( NumButtons < ButtonsPerRow )
		X = Center - (((Width * float(NumButtons)) + (ButtonSpacing * float(NumButtons - 1))) * 0.5);
	else if ( ButtonsPerRow > 1 )
		X = Center - (((Width * float(ButtonsPerRow)) + (ButtonSpacing * float(ButtonsPerRow - 1))) * 0.5);
	else X = Center - Width / 2.0;

	for ( i = 0; i < Components.Length; i++)
	{
		if ( !Components[i].bVisible || GUIButton(Components[i]) == none )
			continue;
		Components[i].SetPosition( X, Y, Width, Height, true );
		if ( --ButtonsLeftInRow > 0 )
			X += Width + ButtonSpacing;
		else
		{
			Y += YL;
			for ( j = i + 1; j < Components.Length && ButtonsLeftInRow < ButtonsPerRow; j++)
			{
				if ( Components[i].bVisible && GUIButton(Components[i]) != none )
					ButtonsLeftInRow++;
			}
			if ( ButtonsLeftInRow > 1 )
				X = Center - (((Width * float(ButtonsLeftInRow)) + (ButtonSpacing * float(ButtonsLeftInRow - 1))) * 0.5);
			else X = Center - Width / 2.0;
		}
	}
}

function bool TeamChange(GUIComponent Sender)
{
	PlayerOwner().SwitchTeam();
	Controller.CloseMenu(false);
	return true;
}

defaultproperties
{
     Begin Object Class=GUIButton Name=TeamSwitchButton
         Caption="Switch Team"
         bAutoSize=True
         Hint="Switch to enemy team"
         WinTop=0.750000
         WinLeft=0.025000
         WinWidth=0.200000
         WinHeight=0.050000
         TabOrder=3
         bBoundToParent=True
         bScaleToParent=True
         OnClick=VSLoginControls.TeamChange
         OnKeyEvent=TeamSwitchButton.InternalOnKeyEvent
     End Object
     b_Team=GUIButton'KFMonsterVS.VSLoginControls.TeamSwitchButton'

}
