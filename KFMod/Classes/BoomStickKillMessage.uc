class BoomStickKillMessage extends LocalMessage;

var	localized string 	KillString;
var name KillSoundName;

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1, 
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject 
	)
{
	return Default.KillString; 
}

static simulated function ClientReceive( 
	PlayerController P,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1, 
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	Super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
	P.ClientPlaySound(Sound'AnnouncerMale2k4.HolyShit_F',true,,SLOT_Talk);
}

static function int GetFontSize( int Switch, PlayerReplicationInfo RelatedPRI1, PlayerReplicationInfo RelatedPRI2, PlayerReplicationInfo LocalPlayer )
{
	if ( Switch < 4 )
		return 0;
	if ( Switch == 4 )
		return 1;
	if ( Switch == 7 )
		return 3;
	return 2;
}

defaultproperties
{
	KillString="H O L Y  F U C K I N G  S H I T !!!!!"
	bIsUnique=True
	bFadeMessage=True
	DrawColor=(B=60,G=60)
	StackMode=SM_Down
	PosY=0.242000
	FontSize=1
}
