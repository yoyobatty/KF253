class VSTimeMessage extends CriticalEventPlus
	abstract;
	
var(Message) localized string InfoText;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
	Return Default.InfoText@GetTimeStr(Switch);
}

static final function string GetTimeStr( int Seconds )
{
	local int Minutes;

	Minutes = Seconds / 60;
	Seconds = Seconds - (Minutes * 60);

	return Minutes$":"$Eval(Seconds<10,"0"$Seconds,string(Seconds));
}

defaultproperties
{
     InfoText="Time until forcing suicide:"
     bIsConsoleMessage=False
     Lifetime=1
     DrawColor=(B=50,G=255,R=255)
     PosY=0.100000
     FontSize=4
}
