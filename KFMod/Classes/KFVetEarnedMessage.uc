class KFVetEarnedMessage extends CriticalEventPlus
	abstract;
	
var(Message) localized string EarnedString;

//
// Messages common to GameInfo derivatives.
//
static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1, 
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
	local string S;

	if( Class<KFVeterancyTypes>(OptionalObject)==None )
		return "";
	S = Default.EarnedString;
	ReplaceText(S,"%v",Class<KFVeterancyTypes>(OptionalObject).Default.VeterancyName);
	Return S;
}

defaultproperties
{
<<<<<<< HEAD
	EarnedString="You have qualified for %v !"
	DrawColor=(B=50,G=50,R=255)
	PosY=0.200000
	FontSize=3
=======
     EarnedString="You have qualified for %v !"
     DrawColor=(B=50,G=50,R=255)
     PosY=0.200000
     FontSize=3
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
