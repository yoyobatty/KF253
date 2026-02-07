class KFLastManStandingMsg extends CriticalEventPlus
	abstract;

var localized string LastManStandStr;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
	Return Default.LastManStandStr;
}

defaultproperties
{
<<<<<<< HEAD
	LastManStandStr="You are the only one left..."
	bIsConsoleMessage=False
	DrawColor=(B=25,G=25,R=255,A=230)
	PosY=0.200000
=======
     LastManStandStr="You are the only one left..."
     bIsConsoleMessage=False
     DrawColor=(B=25,G=25,R=255,A=230)
     PosY=0.200000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
