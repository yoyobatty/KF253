class VSKilledMessage extends CriticalEventPlus
	abstract;
	
var(Message) localized string InfoText;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
	if( Class<Monster>(OptionalObject)!=None )
		Return Default.InfoText@Class'KFInvasionMessage'.Static.GetNameOf(Class<Monster>(OptionalObject));
	Return Default.InfoText@Eval(RelatedPRI_1!=None,RelatedPRI_1.PlayerName,"somebody");
}

defaultproperties
{
     InfoText="You were killed by"
     Lifetime=4
     DrawColor=(B=0,G=0,R=255)
     StackMode=SM_Up
     PosY=0.200000
     FontSize=3
}
