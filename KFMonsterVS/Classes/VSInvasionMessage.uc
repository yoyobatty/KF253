class VSInvasionMessage extends KFInvasionMessage
	abstract;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
	if( RelatedPRI_1 == none )
		return "";
	else if( RelatedPRI_2 != none && RelatedPRI_2 != RelatedPRI_1 )
	{
		if ( RelatedPRI_2.Team != RelatedPRI_1.Team )
		{
			if( Class<Monster>(OptionalObject) != none )
				return RelatedPRI_1.PlayerName@default.KilledByMonster@RelatedPRI_2.PlayerName@"("$Class<Monster>(OptionalObject).Default.MenuName$")";
			return RelatedPRI_1.PlayerName@default.KilledByMonster@RelatedPRI_2.PlayerName;
		}
		return RelatedPRI_1.PlayerName@Default.SameTeamKill@RelatedPRI_2.PlayerName;
	}
	else if( Class<Monster>(OptionalObject) != none )
		return RelatedPRI_1.PlayerName@Default.KilledByMonster@GetNameOf(Class<Monster>(OptionalObject));
	Return RelatedPRI_1.PlayerName@Default.OutMessage;
}

defaultproperties
{
}
