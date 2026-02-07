class KFInvasionMessage extends InvasionMessage
	abstract;

var localized string SameTeamKill,KilledByMonster;

static function string GetString(
    optional int Switch,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
	if( RelatedPRI_1==None )
		Return "";
	else if( RelatedPRI_2!=None && RelatedPRI_2!=RelatedPRI_1 )
		Return RelatedPRI_1.PlayerName@Default.SameTeamKill@RelatedPRI_2.PlayerName;
	else if( Class<Monster>(OptionalObject)!=None )
		Return RelatedPRI_1.PlayerName@Default.KilledByMonster@GetNameOf(Class<Monster>(OptionalObject));
	Return RelatedPRI_1.PlayerName@Default.OutMessage;
}

static function string GetNameOf( Class<Monster> OClass )
{
	local string S;

	S = OClass.Default.MenuName;
	if( S=="" )
		S = string(OClass.Name);
	if( OClass.Default.bBoss )
		Return "the"@S;
	else if( ShouldUseAn(S) )
		Return "an"@S;
	else Return "a"@S;
}
static function bool ShouldUseAn( string S )
{
	S = Left(S,1);
	Return (S~="a" || S~="e" || S~="i" || S~="o" || S~="u");
}

defaultproperties
{
<<<<<<< HEAD
	SameTeamKill="was team-killed by"
	KilledByMonster="was killed by"
	OutMessage="has died."
	DrawColor=(B=75,G=75,R=255,A=230)
	FontSize=0
=======
     SameTeamKill="was team-killed by"
     KilledByMonster="was killed by"
     OutMessage="has died."
     DrawColor=(B=75,G=75,R=255,A=230)
     FontSize=0
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
