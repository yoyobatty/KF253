class WaitingMessage extends TimerMessage;

var name WarningMessage[2];

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
        return "Next Wave Inbound!";
}

static function ClientReceive(
    PlayerController P,
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
    super(CriticalEventPlus).ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

    if(Switch == 1)
       	P.QueueAnnouncement( default.WarningMessage[Rand(2)], 1, AP_InstantOrQueueSwitch, 1 );
}

defaultproperties
{
<<<<<<< HEAD
	WarningMessage(0)="HereTheyCome5"
	WarningMessage(1)="HereTheyCome2"
	DrawColor=(G=0)
=======
     WarningMessage(0)="HereTheyCome5"
     WarningMessage(1)="HereTheyCome2"
     DrawColor=(G=0)
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
