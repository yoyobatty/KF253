class KFRemoveBotButton extends moButton;



function bool InternalOnClick(GUIComponent Sender)
{
    local int PendingBots;
    local KFGameReplicationInfo  KFGRI;
    local String BotName;

    KFGRI = KFGameReplicationInfo(PlayerOwner().GameReplicationInfo);

   if (KFGRI == none)
    return false;


    PendingBots = KFGRI.PendingBots;

   if (PendingBots > 0)
   {
    KFPlayerController(PlayerOwner()).GRIKillBotCall(1);
    PendingBots --;
    PlayerOwner().ClientMessage("A bot was removed from pending BotList");
    PlayerOwner().ClientMessage("Number of bots left: "$PendingBots );
    BotName = "";
   }

    KFPlayerController(PlayerOwner()).ServerSetGRIPendingBots(PendingBots,BotName);


}

defaultproperties
{
     ButtonCaption="Remove Bot"
}
