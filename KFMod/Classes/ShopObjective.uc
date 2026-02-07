class ShopObjective extends GameObjective;

function bool TellBotHowToDisable(Bot B)
{
	if ( (VSize(B.Pawn.Location - Location) > 200.f) )
		return B.Squad.FindPathToObjective(B,self);
	if ( B.Enemy != None )
		return false;
    KFInvasionBot(B).GotoState('Shopping');
	return true;
}

defaultproperties
{
    NetUpdateFrequency=40.000000
    ObjectiveStringSuffix="Shop"
    BaseRadius=1000.000000
    bStatic=False
    bNoDelete=False
    Score=0
}