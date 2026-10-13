class KFAddBotButton extends moButton;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	local KFGameReplicationInfo KFGRI;

	Super.InitComponent(MyController, MyOwner);
	KFGRI = KFGameReplicationInfo(PlayerOwner().GameReplicationInfo);
	if( KFGRI==none )
		DisableMe();
}
function bool InternalOnClick(GUIComponent Sender)
{
	local int PendingBots;
	local KFGameReplicationInfo  KFGRI;
	local String BotName;

	KFGRI = KFGameReplicationInfo(PlayerOwner().GameReplicationInfo);

	if (KFGRI == none)
		return false;

	PendingBots = KFGRI.PendingBots;
	if (KFGRI.TempBotName != "")
		BotName = KFGRI.TempBotName;
	// (the server is only told of a name when the list is changed: otherwise, the one the list shows)
	else if (LobbyMenu(PageOwner) != None)
		BotName = LobbyMenu(PageOwner).BotSlot1.GetText();

	if(BotName != "")
	{
		if ((PlayerOwner().GameReplicationInfo.PRIArray.length  + PendingBots) < 6)
		{
			PendingBots ++;
			KFPlayerController(PlayerOwner()).ServerSetGRIPendingBots(PendingBots,BotName);
			PlayerOwner().ClientMessage("Bot "$KFGameReplicationInfo(PlayerOwner().GameReplicationInfo).LastBotName[PendingBots]$" added to BotList");
			PlayerOwner().ClientMessage("Number of Bots to spawn: "$KFGameReplicationInfo(PlayerOwner().GameReplicationInfo).PendingBots);
		}
		else Warn("No Valid KF Bot selected");
	}
}

defaultproperties
{
     ButtonCaption="Add Bot"
}
