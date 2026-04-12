//-----------------------------------------------------------
//
//-----------------------------------------------------------
class LobbyMenu extends UT2k4MainPage;

var automated moCheckBox ReadyBox[6];
var automated KFPlayerReadyBar PlayerBox[6];
var automated KFLobbyChat t_ChatBox;
var automated KFLobbyTitleLabel l_TitleBar;
var automated KFMapStoryLabel l_StoryBox;
var automated GUISectionBackground StoryBoxBG;
var automated KFBotComboBox BotSlot1;
var automated KFAddBotButton AddBotButton;
var automated KFRemoveBotButton RemoveBotButton;
var automated KFRemoveAllBotButton TotallyRemoveBotsButton;
var automated GUISectionBackground BotsBG ;

var automated GUIlabel label_TimeOutCounter;  

var bool bStoryBoxFilled;
var bool bAllowClose;

//var bool bAdminUse;  // If you're not an admin, gtfo!

var int ActivateTimeoutTime; // When was the lobby timeout turned on?
var bool bTimeoutTimeLogged;  // Was it already logged once?
var bool bTimedOut; // Have we timed out out successfully?

function CheckBotButtonAccess()
{
	if(KFGameReplicationInfo(PlayerOwner().GameReplicationInfo) == none)
		return;

      // log(PlayerOwner().GameReplicationInfo.GameClass);

      // Dont show Invasion bots, on Story mode.
      // Check the GRI, on dedicated servers
      // Level.Game seems to work on listens.

        if (PlayerOwner().GameReplicationInfo.GameClass == "KFMod.KFSPGameType" ||
         PlayerOwner().Level.NetMode == NM_ListenServer && KFSPGameType(PlayerOwner().Level.Game) != none)
	{
		BotSlot1.Hide();
		AddBotButton.Hide();
		RemoveBotButton.Hide();
		TotallyRemoveBotsButton.Hide();
		BotsBG.Hide();
	}
	else
	{
		BotSlot1.Show();
		AddBotButton.Show();
		RemoveBotButton.Show();
		TotallyRemoveBotsButton.Show();
		BotsBG.Show();
	}

	if (!PlayerOwner().PlayerReplicationInfo.bAdmin && PlayerOwner().Level.NetMode != NM_StandAlone)
	{
		BotSlot1.DisableMe();
		AddBotButton.DisableMe();
		RemoveBotButton.DisableMe();
		TotallyRemoveBotsButton.DisableMe();
		BotsBG.DisableMe();
	}
	if (PlayerOwner().PlayerReplicationInfo.bAdmin  || PlayerOwner().Level.NetMode == NM_ListenServer )
	{
		if (KFGameReplicationInfo(PlayerOwner().GameReplicationInfo).bNoBots )
		{
			BotSlot1.DisableMe();
			AddBotButton.DisableMe();
			RemoveBotButton.DisableMe();
			TotallyRemoveBotsButton.DisableMe();
			BotsBG.DisableMe();
		}
		else
		{
			BotSlot1.EnableMe();
			AddBotButton.EnableMe();
			RemoveBotButton.EnableMe();
			BotsBG.EnableMe();
			TotallyRemoveBotsButton.EnableMe();
		}

		if (PlayerOwner().GameReplicationInfo.PRIArray.length + KFGameReplicationInfo(PlayerOwner().GameReplicationInfo).PendingBots < 6)
			AddBotButton.EnableMe();
		else AddBotButton.DisableMe();

		if (KFGameReplicationInfo(PlayerOwner().GameReplicationInfo).PendingBots > 0)
		{
			RemoveBotButton.EnableMe();
			TotallyRemoveBotsButton.EnableMe();
		}
		else
		{
			RemoveBotButton.DisableMe();
			TotallyRemoveBotsButton.DisableMe();
		}
	}
}

function UpdateBotSlots();

function ClearChatBox()
{
	t_ChatBox.lb_Chat.SetContent("");
}

function TimedOut()
{
	bTimedOut = true;
	PlayerOwner().ServerRestartPlayer();
	bAllowClose = true;
}

function bool InternalOnPreDraw(Canvas C)
{
	local int i,j,z;
	local string StoryString;
	local String SkillString;
	local KFGameReplicationInfo KFGRI;
	local PlayerController PC;
	local PlayerReplicationInfo InList[6];
	local bool bWasThere;

	PC = PlayerOwner();
	if( PC==None || PC.Level==None ) // Error?
		Return False;
	if( PC.PlayerReplicationInfo!=None && (!PC.PlayerReplicationInfo.bWaitingPlayer || PC.PlayerReplicationInfo.bOnlySpectator) )
	{
		PC.ClientCloseMenu(True,False);
		Return False;
	}
	KFGRI = KFGameReplicationInfo(PC.GameReplicationInfo);
	if( KFGRI==None ) // May not have been received yet on client.
	{
		l_TitleBar.Caption = "Awaiting for server status...";
		Return False;
	}

	// First fill in non-ready players.
	for ( i=0; i<KFGRI.PRIArray.Length; i++ )
	{
		if( KFGRI.PRIArray[i]==None || KFGRI.PRIArray[i].bOnlySpectator || KFGRI.PRIArray[i].bReadyToPlay )
			continue;
		ReadyBox[j].Checked(False);
		if( KFGRI.PRIArray[i].bWaitingPlayer )
			ReadyBox[j].SetCaption(KFGRI.PRIArray[i].PlayerName@"<Pending Player>");
		else ReadyBox[j].SetCaption(KFGRI.PRIArray[i].PlayerName@"<Active>");
		PlayerBox[j].ImageColor = PlayerBox[j].Default.ImageColor;
		InList[j] = KFGRI.PRIArray[i];
		j++;
		if( j>=6 )
			GoTo'DoneIt';
	}

	// Then comes rest.
	for ( i=0; i<KFGRI.PRIArray.Length; i++ )
	{
		if( KFGRI.PRIArray[i]==None || KFGRI.PRIArray[i].bOnlySpectator )
			Continue;
		bWasThere = False;
		for( z=0; z<j; z++ )
		{
			if( InList[z]==KFGRI.PRIArray[i] )
			{
				bWasThere = True;
				Break;
			}
		}
		if( bWasThere )
			Continue;
		ReadyBox[j].Checked(KFGRI.PRIArray[i].bReadyToPlay);
		if( KFGRI.PRIArray[i].bWaitingPlayer )
			ReadyBox[j].SetCaption(KFGRI.PRIArray[i].PlayerName@"<Pending Player>");
		else ReadyBox[j].SetCaption(KFGRI.PRIArray[i].PlayerName@"<Active>");
		if( KFGRI.PRIArray[i].bReadyToPlay )
		{
			PlayerBox[j].ImageColor.R = 200 ;
			PlayerBox[j].ImageColor.G = 75;
			PlayerBox[j].ImageColor.B = 75 ;
			PlayerBox[j].ImageColor.A = 200 ;
        
			if (!bTimeoutTimeLogged)
			{
				ActivateTimeoutTime = PC.Level.TimeSeconds;
				bTimeoutTimeLogged = true;
			}
		}
		else PlayerBox[j].ImageColor = PlayerBox[j].Default.ImageColor;
		j++;
		if( j>=6 )
			Break;
	}
	While( j<6 )
	{
		ReadyBox[j].Checked(False);
		ReadyBox[j].SetCaption("");
		PlayerBox[j].ImageColor = PlayerBox[j].Default.ImageColor;
		j++;
	}
DoneIt:
	StoryString = PC.Level.Description;

	if (!bStoryBoxFilled)
	{
		l_StoryBox.LoadStoryText();
		bStoryBoxFilled = true;
	}

	CheckBotButtonAccess();

	// Hate to do it like this, but there's no real easy way to get the SkillLevel strings from the Scoreboard, since it's only ever
	// called as a class. Spawning a fresh one /w DynamicLoadObject doesn't work too great (online).
	if( KFGRI.BaseDifficulty <3)
		SkillString ="Beginner";
	else if( KFGRI.BaseDifficulty==3 )
		SkillString ="Normal";
	else if( KFGRI.BaseDifficulty==4 )
		SkillString ="Skilled";
	else if( KFGRI.BaseDifficulty==5 )
		SkillString ="Elite";
	else if( KFGRI.BaseDifficulty==7 )
		SkillString ="Suicidal";
	l_TitleBar.Caption = (SkillString@KFGRI.GameName$" on "$PC.Level.Title);
	return false;
}

function bool StopClose(optional bool bCancelled)
{
	bStoryBoxFilled = false;
     
	CheckBotButtonAccess();
	UpdateBotSlots();
	ClearChatBox();

	// this is for the OnCanClose delegate
	// can't close now unless done by call to CloseAll,
	// or the bool has been set to true by LobbyFooter
	return false;
}

event Opened(GUIComponent Sender)                   // Called when the Menu Owner is opened
{
	SetTimer(1,true);
}

event Timer()
{
	local KFGameReplicationInfo KF;

	if( PlayerOwner().PlayerReplicationInfo.bOnlySpectator )
	{
		label_TimeOutCounter.caption = "You are a spectator.";
		Return;
	}
	KF = KFGameReplicationInfo(PlayerOwner().GameReplicationInfo);
	if( KF==None )
		label_TimeOutCounter.caption = "Awaiting server status...";
	else if( KF.LobbyTimeout<=0 )
		label_TimeOutCounter.caption = "Waiting for players to be ready...";
	else label_TimeOutCounter.caption = "Game will auto-commence in:"@KF.LobbyTimeout;
}

defaultproperties
{
     Begin Object Class=moCheckBox Name=ReadyBox0
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.900000
         Caption="NAME1"
         OnCreateComponent=ReadyBox0.InternalOnCreateComponent
         WinTop=0.100000
         WinLeft=0.050000
         WinWidth=0.400000
         WinHeight=0.040000
     End Object
     ReadyBox(0)=moCheckBox'KFGui.LobbyMenu.ReadyBox0'

     Begin Object Class=moCheckBox Name=ReadyBox1
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.900000
         Caption="NAME2"
         OnCreateComponent=ReadyBox1.InternalOnCreateComponent
         WinTop=0.150000
         WinLeft=0.050000
         WinWidth=0.400000
         WinHeight=0.040000
     End Object
     ReadyBox(1)=moCheckBox'KFGui.LobbyMenu.ReadyBox1'

     Begin Object Class=moCheckBox Name=ReadyBox2
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.900000
         Caption="NAME3"
         OnCreateComponent=ReadyBox2.InternalOnCreateComponent
         WinTop=0.200000
         WinLeft=0.050000
         WinWidth=0.400000
         WinHeight=0.040000
     End Object
     ReadyBox(2)=moCheckBox'KFGui.LobbyMenu.ReadyBox2'

     Begin Object Class=moCheckBox Name=ReadyBox3
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.900000
         Caption="NAME4"
         OnCreateComponent=ReadyBox3.InternalOnCreateComponent
         WinTop=0.250000
         WinLeft=0.050000
         WinWidth=0.400000
         WinHeight=0.040000
     End Object
     ReadyBox(3)=moCheckBox'KFGui.LobbyMenu.ReadyBox3'

     Begin Object Class=moCheckBox Name=ReadyBox4
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.900000
         Caption="NAME5"
         OnCreateComponent=ReadyBox4.InternalOnCreateComponent
         WinTop=0.300000
         WinLeft=0.050000
         WinWidth=0.400000
         WinHeight=0.040000
     End Object
     ReadyBox(4)=moCheckBox'KFGui.LobbyMenu.ReadyBox4'

     Begin Object Class=moCheckBox Name=ReadyBox5
         bValueReadOnly=True
         ComponentJustification=TXTA_Left
         CaptionWidth=0.900000
         Caption="NAME6"
         OnCreateComponent=ReadyBox5.InternalOnCreateComponent
         WinTop=0.350000
         WinLeft=0.050000
         WinWidth=0.400000
         WinHeight=0.040000
     End Object
     ReadyBox(5)=moCheckBox'KFGui.LobbyMenu.ReadyBox5'

     Begin Object Class=KFPlayerReadyBar Name=Player1BackDrop
         Image=Texture'KFKillMeNow.LobbyPlayerListBG'
         ImageColor=(B=25,G=25,R=100,A=100)
         ImageStyle=ISTY_Scaled
         ImageRenderStyle=MSTY_Normal
         WinTop=0.095000
         WinLeft=0.040000
         WinWidth=0.350000
         WinHeight=0.035000
     End Object
     PlayerBox(0)=KFPlayerReadyBar'KFGui.LobbyMenu.Player1BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player2BackDrop
         Image=Texture'KFKillMeNow.LobbyPlayerListBG'
         ImageColor=(B=25,G=25,R=100,A=100)
         ImageStyle=ISTY_Scaled
         ImageRenderStyle=MSTY_Normal
         WinTop=0.145000
         WinLeft=0.040000
         WinWidth=0.350000
         WinHeight=0.035000
     End Object
     PlayerBox(1)=KFPlayerReadyBar'KFGui.LobbyMenu.Player2BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player3BackDrop
         Image=Texture'KFKillMeNow.LobbyPlayerListBG'
         ImageColor=(B=25,G=25,R=100,A=100)
         ImageStyle=ISTY_Scaled
         ImageRenderStyle=MSTY_Normal
         WinTop=0.195000
         WinLeft=0.040000
         WinWidth=0.350000
         WinHeight=0.035000
     End Object
     PlayerBox(2)=KFPlayerReadyBar'KFGui.LobbyMenu.Player3BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player4BackDrop
         Image=Texture'KFKillMeNow.LobbyPlayerListBG'
         ImageColor=(B=25,G=25,R=100,A=100)
         ImageStyle=ISTY_Scaled
         ImageRenderStyle=MSTY_Normal
         WinTop=0.245000
         WinLeft=0.040000
         WinWidth=0.350000
         WinHeight=0.035000
     End Object
     PlayerBox(3)=KFPlayerReadyBar'KFGui.LobbyMenu.Player4BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player5BackDrop
         Image=Texture'KFKillMeNow.LobbyPlayerListBG'
         ImageColor=(B=25,G=25,R=100,A=100)
         ImageStyle=ISTY_Scaled
         ImageRenderStyle=MSTY_Normal
         WinTop=0.295000
         WinLeft=0.040000
         WinWidth=0.350000
         WinHeight=0.035000
     End Object
     PlayerBox(4)=KFPlayerReadyBar'KFGui.LobbyMenu.Player5BackDrop'

     Begin Object Class=KFPlayerReadyBar Name=Player6BackDrop
         Image=Texture'KFKillMeNow.LobbyPlayerListBG'
         ImageColor=(B=25,G=25,R=100,A=100)
         ImageStyle=ISTY_Scaled
         ImageRenderStyle=MSTY_Normal
         WinTop=0.345000
         WinLeft=0.040000
         WinWidth=0.350000
         WinHeight=0.035000
     End Object
     PlayerBox(5)=KFPlayerReadyBar'KFGui.LobbyMenu.Player6BackDrop'

     Begin Object Class=KFLobbyChat Name=ChatBox
         OnCreateComponent=ChatBox.InternalOnCreateComponent
         WinWidth=0.943879
         TabOrder=1
         OnPreDraw=ChatBox.FloatingPreDraw
         OnRendered=ChatBox.FloatingRendered
         OnHover=ChatBox.FloatingHover
         OnMousePressed=ChatBox.FloatingMousePressed
         OnMouseRelease=ChatBox.FloatingMouseRelease
     End Object
     t_ChatBox=KFLobbyChat'KFGui.LobbyMenu.ChatBox'

     Begin Object Class=KFLobbyTitleLabel Name=LobbyTitle
         TextColor=(B=255,G=255,R=255)
         WinTop=0.025000
         WinLeft=0.050000
         WinWidth=0.915313
         WinHeight=0.049359
         RenderWeight=0.300000
         bScaleToParent=True
     End Object
     l_TitleBar=KFLobbyTitleLabel'KFGui.LobbyMenu.LobbyTitle'

     Begin Object Class=KFMapStoryLabel Name=LobbyMapStoryBox
         OnCreateComponent=LobbyMapStoryBox.InternalOnCreateComponent
     End Object
     l_StoryBox=KFMapStoryLabel'KFGui.LobbyMenu.LobbyMapStoryBox'

     Begin Object Class=AltSectionBackground Name=StoryBoxBackground
         WinTop=0.048000
         WinLeft=0.450000
         WinWidth=0.520000
         WinHeight=0.380000
         OnPreDraw=StoryBoxBackground.InternalPreDraw
     End Object
     StoryBoxBG=AltSectionBackground'KFGui.LobbyMenu.StoryBoxBackground'

     Begin Object Class=KFBotComboBox Name=BotComboBox1
         ComponentJustification=TXTA_Left
         CaptionWidth=0.650000
         Caption="                                   Bot Control"
         OnCreateComponent=BotComboBox1.InternalOnCreateComponent
         Hint="Select Bot to Add"
         WinTop=0.550000
         WinLeft=0.400000
         WinWidth=0.550000
         TabOrder=10
         OnChange=LobbyMenu.InternalOnChange
     End Object
     BotSlot1=KFBotComboBox'KFGui.LobbyMenu.BotComboBox1'

     Begin Object Class=KFAddBotButton Name=AddBotGUIButton
         OnCreateComponent=AddBotGUIButton.InternalOnCreateComponent
         WinTop=0.650000
         WinLeft=0.450000
         WinWidth=0.450000
         OnChange=LobbyMenu.InternalOnChange
     End Object
     AddBotButton=KFAddBotButton'KFGui.LobbyMenu.AddBotGUIButton'

     Begin Object Class=KFRemoveBotButton Name=RemoveBotGUIButton
         OnCreateComponent=RemoveBotGUIButton.InternalOnCreateComponent
         WinTop=0.700000
         WinLeft=0.320000
         WinWidth=0.590000
         OnChange=LobbyMenu.InternalOnChange
     End Object
     RemoveBotButton=KFRemoveBotButton'KFGui.LobbyMenu.RemoveBotGUIButton'

     Begin Object Class=KFRemoveAllBotButton Name=RemoveAllBotsGUIButton
         OnCreateComponent=RemoveAllBotsGUIButton.InternalOnCreateComponent
         WinTop=0.750000
         WinLeft=0.320000
         WinWidth=0.590000
         OnChange=LobbyMenu.InternalOnChange
     End Object
     TotallyRemoveBotsButton=KFRemoveAllBotButton'KFGui.LobbyMenu.RemoveAllBotsGUIButton'

     Begin Object Class=AltSectionBackground Name=BotAreaBackground
         WinTop=0.500000
         WinLeft=0.450000
         WinWidth=0.520000
         WinHeight=0.380000
         OnPreDraw=BotAreaBackground.InternalPreDraw
     End Object
     BotsBG=AltSectionBackground'KFGui.LobbyMenu.BotAreaBackground'

     Begin Object Class=GUILabel Name=TimeOutCounter
         Caption="Game will auto-commence in: "
         TextColor=(B=150,G=150,R=255)
         WinTop=0.395609
         WinLeft=0.011213
         WinWidth=0.460000
         WinHeight=0.200000
         TabOrder=6
     End Object
     label_TimeOutCounter=GUILabel'KFGui.LobbyMenu.TimeOutCounter'

     c_Tabs=None

     Begin Object Class=LobbyFooter Name=BuyFooter
         RenderWeight=0.300000
         TabOrder=8
         bBoundToParent=False
         bScaleToParent=False
         OnPreDraw=BuyFooter.InternalOnPreDraw
     End Object
     t_Footer=LobbyFooter'KFGui.LobbyMenu.BuyFooter'

     i_Background=None

     i_bkChar=None

     i_bkScan=None

     bRenderWorld=True
     bAllowedAsLast=True
     BackgroundColor=(B=0,G=20,R=0,A=20)
     InactiveFadeColor=(G=0,R=0,A=64)
     BackgroundRStyle=MSTY_Alpha
     OnCanClose=LobbyMenu.StopClose
     WinHeight=0.500000
     OnPreDraw=LobbyMenu.InternalOnPreDraw
}
