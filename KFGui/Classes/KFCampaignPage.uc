// The Campaign choice from the main menu: KFMod 1.0's story from the start, on from the last checkpoint, or the
// shooting range. (The game itself is KFCampaign.KFCampaignGame, named only in the URLs here.)
class KFCampaignPage extends UT2K4QuitPage;

var GUILabel l_Saved;
var localized string ContinueFrom, NoSave;

function InitComponent( GUIController MyController, GUIComponent MyOwner )
{
	local string S;

	Super.InitComponent(MyController, MyOwner);
	l_Saved = GUILabel(Controls[6]);
	DynamicLoadObject("KFCampaign.KFCampaignSave", class'Class', true);
	S = PlayerOwner().ConsoleCommand("get KFCampaign.KFCampaignSave MapName");
	if( S=="" || InStr(S, "Unrecognized")>=0 )
	{
		l_Saved.Caption = NoSave;
		GUIButton(Controls[2]).DisableMe();
	}
	else l_Saved.Caption = ContinueFrom@S;
}

function bool InternalOnClick( GUIComponent Sender )
{
	local string URL;

	if( Sender==Controls[1] )
		URL = "KFS-Intro";
	else if( Sender==Controls[2] )
		URL = "KFS-RESUMEGAME";
	else if( Sender==Controls[3] )
		URL = "KFS-Training";
	else
	{
		Controller.CloseMenu(false);
		return true;
	}
	PlayerOwner().ClientTravel(URL$"?Game=KFCampaign.KFCampaignGame", TRAVEL_Absolute, false);
	Controller.CloseAll(false, true);
	return true;
}

defaultproperties
{
	ContinueFrom="Last checkpoint:"
	NoSave="No checkpoint saved yet."

	Begin Object Class=GUIButton Name=QuitBackground
		StyleName="SquareBar"
		WinHeight=1.000000
		bBoundToParent=True
		bScaleToParent=True
		bAcceptsInput=False
		bNeverFocus=True
		OnKeyEvent=QuitBackground.InternalOnKeyEvent
	End Object
	Controls(0)=GUIButton'KFGui.KFCampaignPage.QuitBackground'

	Begin Object Class=GUIButton Name=NewButton
		Caption="NEW CAMPAIGN"
		WinTop=0.750000
		WinLeft=0.060000
		WinWidth=0.200000
		bBoundToParent=True
		OnClick=KFCampaignPage.InternalOnClick
		OnKeyEvent=NewButton.InternalOnKeyEvent
	End Object
	Controls(1)=GUIButton'KFGui.KFCampaignPage.NewButton'

	Begin Object Class=GUIButton Name=ContinueButton
		Caption="CONTINUE"
		WinTop=0.750000
		WinLeft=0.290000
		WinWidth=0.200000
		bBoundToParent=True
		OnClick=KFCampaignPage.InternalOnClick
		OnKeyEvent=ContinueButton.InternalOnKeyEvent
	End Object
	Controls(2)=GUIButton'KFGui.KFCampaignPage.ContinueButton'

	Begin Object Class=GUIButton Name=TrainingButton
		Caption="TRAINING"
		WinTop=0.750000
		WinLeft=0.520000
		WinWidth=0.200000
		bBoundToParent=True
		OnClick=KFCampaignPage.InternalOnClick
		OnKeyEvent=TrainingButton.InternalOnKeyEvent
	End Object
	Controls(3)=GUIButton'KFGui.KFCampaignPage.TrainingButton'

	Begin Object Class=GUIButton Name=BackButton
		Caption="BACK"
		WinTop=0.750000
		WinLeft=0.750000
		WinWidth=0.200000
		bBoundToParent=True
		OnClick=KFCampaignPage.InternalOnClick
		OnKeyEvent=BackButton.InternalOnKeyEvent
	End Object
	Controls(4)=GUIButton'KFGui.KFCampaignPage.BackButton'

	Begin Object Class=GUILabel Name=QuitDesc
		Caption="Killing Floor 1.0: the campaign"
		TextAlign=TXTA_Center
		TextColor=(B=0,R=187)
		TextFont="UT2HeaderFont"
		WinTop=0.395000
		WinHeight=32.000000
	End Object
	Controls(5)=GUILabel'KFGui.KFCampaignPage.QuitDesc'

	Begin Object Class=GUILabel Name=SavedLabel
		TextAlign=TXTA_Center
		TextColor=(B=170,G=170,R=170,A=255)
		TextFont="UT2SmallFont"
		WinTop=0.465000
		WinHeight=24.000000
	End Object
	Controls(6)=GUILabel'KFGui.KFCampaignPage.SavedLabel'

	WinTop=0.375000
	WinHeight=0.250000
}
