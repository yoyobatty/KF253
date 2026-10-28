// What a player is told about rising as a specimen and changing teams (a specimen class goes in as OptionalObject)
class VSInfoMessage extends CriticalEventPlus
	abstract;

var(Message) localized string InfoText[12];

static function string GetString(
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	if( class<Monster>(OptionalObject)!=None )
		return Default.InfoText[Switch]@class<Monster>(OptionalObject).Default.MenuName$"!";
	return Default.InfoText[Switch];
}

defaultproperties
{
     InfoText(0)="You are a specimen: find a spot the survivors cannot see and press Fire to rise."
     InfoText(1)="Tip: on the escape menu you can switch teams."
     InfoText(2)="Can't rise here: no floor below."
     InfoText(3)="Can't rise here: a survivor can see this spot."
     InfoText(4)="Can't rise here: too close to a survivor."
     InfoText(5)="Can't rise here: no room."
     InfoText(6)="Can't rise until the wave begins."
     InfoText(7)="This wave's heavy is yours: you rise as the"
     InfoText(8)="Too long without hurting a survivor: the heavy goes to the AI."
     InfoText(9)="The other team has more players already."
     InfoText(10)="Switched to the other team."
     bIsUnique=False
     Lifetime=5
     DrawColor=(B=50,G=255,R=50)
     DrawPivot=DP_UpperLeft
     StackMode=SM_Down
     PosX=0.020000
     PosY=0.200000
     FontSize=3
}
