class KFObjectiveMsg extends CriticalEventPlus
	abstract;

static function string GetString(
	 optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	if( KFSPLevelinfo(OptionalObject)==None || Switch<0 || KFSPLevelinfo(OptionalObject).MissionObjectives.Length<=Switch )
		Return "";
	Return KFSPLevelinfo(OptionalObject).MissionObjectives[Switch];
}

defaultproperties
{
<<<<<<< HEAD
	DrawColor=(G=100,R=255)
	StackMode=SM_Down
	PosY=0.800000
	FontSize=2
=======
     DrawColor=(G=100,R=255)
     StackMode=SM_Down
     PosY=0.800000
     FontSize=2
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
