//-----------------------------------------------------------
//
//-----------------------------------------------------------
class KFVoicePack extends VoicePack;

// Need Support
const MAXSUPP = 5;
var() sound SuppSound[MAXSUPP];
var() localized string SuppString[MAXSUPP];
//var() localized string SuppAbbrev[MAXACK];
//var() name AckAnim[MAXACK];
var() int numSupp;

// Form Up
const MAXFORM = 5;
var() sound FormSound[MAXFORM];
var() localized string FormString[MAXFORM];
var() int numForm;

// Take This
const MAXTAKE = 5;
var() sound TakeSound[MAXTAKE];
var() localized string TakeString[MAXTAKE];
var() int numTake;

// Going Trading
const MAXTRAD = 5;
var() sound TradSound[MAXTRAD];
var() localized string TradString[MAXTRAD];
var() int numTrad;

// MEDIC!
const MAXMEDIC = 5;
var() sound MedicSound[MAXMEDIC];
var() localized string MedicString[MAXMEDIC];
var() int numMedic;

// I'm Welding
const MAXWELD = 5;
var() sound WELDSound[MAXWELD];
var() localized string WeldString[MAXWELD];
var() int numWeld;

// I'm Covering you
const MAXCOVER = 5;
var() sound CoverSound[MAXCOVER];
var() localized string CoverString[MAXCOVER];
var() int numCover;

var float Pitch;
var string MessageString;


var bool bForceMessageSound;
var bool bDisplayPortrait;
var PlayerReplicationInfo PortraitPRI;

//const MAXPHRASE = 8;
var Sound Phrase; //[MAXPHRASE];
var string PhraseString; //[MAXPHRASE];
//var int PhraseNum;
//var() byte DisplayMessage[MAXPHRASE];
var PlayerReplicationInfo DelayedSender;

//TODO: Make sound play

static function PlayerSpeech( name Type, int Index, string Callsign, Actor PackOwner )
{
	/*
    local name SendMode;
	local PlayerReplicationInfo Recipient;
	local int i;
	local GameReplicationInfo GRI;

	switch (Type)
	{
		case 'ACK':					// Acknowledgements
		case 'FRIENDLYFIRE':		// Friendly Fire
		case 'OTHER':				// Other
			SendMode = 'TEAM';		// Only send to team.
			Recipient = None;		// Send to everyone.
			break;
		case 'ORDER':				// Orders
			SendMode = 'TEAM';		// Only send to team.

			Index = OrderToIndex(Index, PackOwner.Level.Game.Class);

			GRI = PlayerController(PackOwner).GameReplicationInfo;
			if ( GRI.bTeamGame )
			{
				if ( Callsign == "" )
					Recipient = None;
				else
				{
					for ( i=0; i<GRI.PRIArray.Length; i++ )
						if ( (GRI.PRIArray[i] != None) && (GRI.PRIArray[i].PlayerName == Callsign)
							&& (GRI.PRIArray[i].Team == PlayerController(PackOwner).PlayerReplicationInfo.Team) )
						{
							Recipient = GRI.PRIArray[i];
							break;
						}
				}
			}
			break;
		case 'TAUNT':				// Taunts
		case 'HIDDEN':				// Hidden Taunts
			SendMode = 'GLOBAL';	// Send to all teams.
			Recipient = None;		// Send to everyone.
			break;
		default:
			SendMode = 'GLOBAL';
			Recipient = None;
	}
	if (!PlayerController(PackOwner).GameReplicationInfo.bTeamGame)
		SendMode = 'GLOBAL';  // Not a team game? Send to everyone.
    */
	//Log("PlayerSpeech: "$Type$" Ix:"$Index$" Callsign:"$Callsign$" Recip:"$Recipient);
	Controller(PackOwner).SendVoiceMessage( Controller(PackOwner).PlayerReplicationInfo, none, Type, GetRandIndex(Type), 'TEAM' );
}

static function byte GetRandIndex(name Type)
{
  local byte RetRand;

  log("GetRandIndex Type = "$Type);

  switch(Type)
  {
	  case'SUPP'  : RetRand=rand(default.numSupp); break;
	  case'FORM'  : RetRand=rand(default.numForm); break;
	  case'TAKE'  : RetRand=rand(default.numTake); break;
	  case'TRAD'  : RetRand=rand(default.numTrad); break;
	  case'MEDIC' : RetRand=rand(default.numMedic); break;
	  case'WELD'  : RetRand=rand(default.numWeld); break;
	  case'COVER' : RetRand=rand(default.numCover); break;

  }
  log("GetRandIndex RetRand="$RetRand);
  return RetRand;
}

function ClientInitialize(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageIndex)
{
	local Sound MessageSound;

	DelayedSender = Sender;

// TODO - What is DisplayString?
//	DisplayString = 0;
	/*
    bDisplayPortrait = false;
	bDisplayNextMessage = bShowMessageText && (MessageType != 'TAUNT') && (MessageType != 'AUTOTAUNT');
	if ( (PlayerController(Owner).PlayerReplicationInfo == Recipient) || (messagetype == 'OTHER') )
	{
		PortraitPRI = Sender;
		bDisplayPortrait = true;
	}
	else if ( (Recipient == None) && (messagetype == 'ORDER') )
	{
		PortraitPRI = Sender;
		bDisplayPortrait = true;
	}
	else if ( (PlayerController(Owner).PlayerReplicationInfo != Sender) && ((messagetype == 'ORDER') || (messagetype == 'ACK'))
			&& (Recipient != None) )
	{
		Destroy();
		return;
	}
    */
	if(PlayerController(Owner).bNoVoiceMessages
	//	|| (PlayerController(Owner).bNoVoiceTaunts && (MessageType == 'TAUNT' || MessageType == 'AUTOTAUNT'))
	//	|| (PlayerController(Owner).bNoAutoTaunts && MessageType == 'AUTOTAUNT')
		)
	{
		Destroy();
		return;
	}

    /*
	if ( Sender.bBot )
	{
		BotInitialize(Sender, Recipient, messagetype, messageIndex);
		return;
	}
    */

	messagesound = none;

    //SetSuppMessage(messageIndex, Recipient, MessageSound);

	switch(messagetype)
	{
	  case'SUPP'  : SetSuppMessage(messageIndex, Recipient, MessageSound); break;
	  case'FORM'  : SetFormMessage(messageIndex, Recipient, MessageSound); break;
	  case'TAKE'  : SetTakeMessage(messageIndex, Recipient, MessageSound); break;
	  case'TRAD'  : SetTradMessage(messageIndex, Recipient, MessageSound); break;
	  case'MEDIC' : SetMedicMessage(messageIndex, Recipient, MessageSound); break;
	  case'WELD'  : SetWeldMessage(messageIndex, Recipient, MessageSound); break;
	  case'COVER' : SetCoverMessage(messageIndex, Recipient, MessageSound); break;

	}
    /*
    if ( messagetype == 'ACK' )
		SetClientAckMessage(messageIndex, Recipient, MessageSound);
	else
	{
		if ( messagetype == 'FRIENDLYFIRE' )
			SetClientFFireMessage(messageIndex, Recipient, MessageSound);
		else if ( messagetype == 'TAUNT' )
			SetClientTauntMessage(messageIndex, Recipient, MessageSound);
		else if ( messagetype == 'AUTOTAUNT' )
		{
			SetClientTauntMessage(messageIndex, Recipient, MessageSound);
			SetTimer(1, false);
		}
		else if ( messagetype == 'ORDER' )
			SetClientOrderMessage(messageIndex, Recipient, MessageSound);
		else if ( messagetype == 'HIDDEN' )
			SetClientHiddenMessage(messageIndex, Recipient, MessageSound);
		else // messagetype == Other
			SetClientOtherMessage(messageIndex, Recipient, MessageSound);
	}
	*/

    if(messagesound==none)
      return;

    PortraitPRI = Sender;
	bDisplayPortrait = true;

    SetTimer(0.6, false);

    Phrase = MessageSound;
	PhraseString = MessageString;
	//DisplayMessage[0] = DisplayString;

    if ( PlayerController(Owner).PlayerReplicationInfo == Sender )
		bForceMessageSound = true;
	//else if ( (PlayerController(Owner).PlayerReplicationInfo == Recipient)
	//		&& (MessageType != 'TAUNT') && (MessageType != 'AUTOTAUNT') )
	//	bForceMessageSound = true;

}

function SetSuppMessage(int messageIndex, PlayerReplicationInfo Recipient, out Sound MessageSound)
{

    if(messageIndex >= numSupp)
      messageIndex=0;

    //if ( OtherDelayed[messageIndex] != 0 )
	//	SetTimer(2.5 + 0.5*FRand(), false); // wait for initial request to be spoken
	MessageSound = SuppSound[messageIndex];
	MessageString = SuppString[messageIndex];
	//DisplayString = DisplayOtherMessage[messageIndex];
    //MessageAnim = OtherAnim[messageIndex];
}

function SetFormMessage(int messageIndex, PlayerReplicationInfo Recipient, out Sound MessageSound)
{
    if(messageIndex >= numForm)
      messageIndex=0;

    MessageSound = FormSound[messageIndex];
	MessageString = FormString[messageIndex];
}

function SetTakeMessage(int messageIndex, PlayerReplicationInfo Recipient, out Sound MessageSound)
{

    if(messageIndex >= numTake)
      messageIndex=0;

    MessageSound = TakeSound[messageIndex];
	MessageString = TakeString[messageIndex];
}

function SetTradMessage(int messageIndex, PlayerReplicationInfo Recipient, out Sound MessageSound)
{
    if(messageIndex >= numTrad)
      messageIndex=0;

    MessageSound = TradSound[messageIndex];
	MessageString = TradString[messageIndex];
}

function SetMedicMessage(int messageIndex, PlayerReplicationInfo Recipient, out Sound MessageSound)
{
    if(messageIndex >= numMedic)
      messageIndex=0;

    MessageSound = MedicSound[messageIndex];
	MessageString = MedicString[messageIndex];
}

function SetWeldMessage(int messageIndex, PlayerReplicationInfo Recipient, out Sound MessageSound)
{
    if(messageIndex >= numWeld)
      messageIndex=0;

    MessageSound = WeldSound[messageIndex];
	MessageString = WeldString[messageIndex];
}

function SetCoverMessage(int messageIndex, PlayerReplicationInfo Recipient, out Sound MessageSound)
{
    if(messageIndex >= numCover)
      messageIndex=0;

    MessageSound = CoverSound[messageIndex];
	MessageString = CoverString[messageIndex];
}

// We can't use the normal ParseMessageString, because thats only really valid on the server.
// So we use a special one just for the %l (location) token.
static function string ClientParseChatPercVar(PlayerReplicationInfo PRI, String Cmd)
{
	if (cmd~="%L")
		return "("$PRI.GetLocationName()$")";
}

static function string ClientParseMessageString(PlayerReplicationInfo PRI, String Message)
{
	local string OutMsg;
	local string cmd;
	local int pos,i;

	OutMsg = "";
	pos = InStr(Message,"%");
	while (pos>-1)
	{
		if (pos>0)
		{
		  OutMsg = OutMsg$Left(Message,pos);
		  Message = Mid(Message,pos);
		  pos = 0;
	    }

		i = len(Message);
		cmd = mid(Message,pos,2);
		if (i-2 > 0)
			Message = right(Message,i-2);
		else
			Message = "";

		OutMsg = OutMsg$ClientParseChatPercVar(PRI, Cmd);
		pos = InStr(Message,"%");
	}

	if (Message!="")
		OutMsg=OutMsg$Message;

	return OutMsg;
}

function Timer()
{
	local PlayerController PlayerOwner;
	local string Mesg;

	PlayerOwner = PlayerController(Owner);
	if ( bDisplayPortrait) // && (PhraseNum == 0) && (PortraitPRI != None))
		PlayerController(Owner).myHUD.DisplayPortrait(PortraitPRI);
	//if ( (Phrase[PhraseNum] != None) && (bDisplayNextMessage || (DisplayMessage[PhraseNum] != 0)) )
	//{
		Mesg = ClientParseMessageString(DelayedSender, PhraseString);
		if ( Mesg != "" )
			PlayerOwner.TeamMessage(DelayedSender,Mesg,'TEAMSAYQUIET');
	//}

	if ( (Phrase != None) && ((Level.TimeSeconds - PlayerOwner.LastPlaySpeech > 2) || bForceMessageSound)  )
	{
		PlayerOwner.LastPlaySpeech = Level.TimeSeconds;
		if ( (PlayerOwner.ViewTarget != None) )
		{
			PlayerOwner.ViewTarget.PlaySound(Phrase, SLOT_Interface,1.5*TransientSoundVolume,,,Pitch,false);
		}
		else
		{
			PlayerOwner.PlaySound(Phrase, SLOT_Interface,1.5*TransientSoundVolume,,,Pitch,false);
		}

        //if (MessageAnim != '')
        //{
        //    UnrealPlayer(PlayerOwner).Taunt(MessageAnim);
        //}

		//if ( Phrase[PhraseNum+1] == None )
			Destroy();
		/*
        else
		{
			SetTimer(GetSoundDuration(Phrase[PhraseNum]), false);
			PhraseNum++;
		}
		*/
	}
	else
		Destroy();
}

defaultproperties
{
	Pitch=1.000000
	TransientSoundVolume=0.900000
}
