//=============================================================================
// MessageTrigger
//=============================================================================
// Broadcasts a message to all players
//=============================================================================
class KFMessageTrigger extends Triggers;

var()   enum EMT_MessageType
{
	EMT_Default,
	EMT_CriticalEvent,
	EMT_DeathMessage,
	EMT_Say,
	EMT_TeamSay,
	EMT_KFObjective,
} MessageType;

var() localized string  Message;

event Trigger( Actor Other, Pawn EventInstigator )
{
	local name              MSGType;
	local Controller        C;
	local PlayerController  P;

	switch ( MessageType )
	{
		case EMT_CriticalEvent	: MSGType = 'CriticalEvent';		break;
		case EMT_DeathMessage	: MSGType = 'DeathMessage';		break;
		case EMT_Say		: MSGType = 'Say';			break;
		case EMT_TeamSay		: MSGType = 'TeamSay';			break;
		default			: MSGType = 'KFCriticalEventPlus';	break;
	}

	for ( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		P = PlayerController(C);
		if( P != None )
			P.TeamMessage(C.PlayerReplicationInfo, Message, MSGType);
	}
}

defaultproperties
{
<<<<<<< HEAD
	messagetype=EMT_CriticalEvent
	Message="My Message"
=======
     messagetype=EMT_CriticalEvent
     Message="My Message"
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
