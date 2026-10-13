class VSInfoMessage extends CriticalEventPlus
	abstract;
	
var(Message) localized string InfoText[2];

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
	Return Default.InfoText[Switch];
}

defaultproperties
{
     InfoText(0)="Tip: Press [Fire] to possess this monster!"
     InfoText(1)="Tip: On escape menu you can switch teams!"
     bIsUnique=False
     Lifetime=5
     DrawColor=(B=50,G=255,R=50)
     DrawPivot=DP_UpperLeft
     StackMode=SM_Down
     PosX=0.020000
     PosY=0.200000
     FontSize=3
}
