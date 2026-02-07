class NoTraderMut extends Mutator;

function bool CheckReplacement( Actor Other, out byte bSuperRelevant )
{
	if ( Other.IsA('WeaponLocker') )
		return false;
	return true;
}

defaultproperties
{
	GroupName="KF-NoTraderz"
	FriendlyName="No Trader"
	Description="Trader doors stay shut the entire game."
}
