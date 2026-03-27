class NoTraderMut extends Mutator;

function bool CheckReplacement( Actor Other, out byte bSuperRelevant )
{
	if ( Other.IsA('WeaponLocker') )
		return false;
	return true;
}

defaultproperties
{
<<<<<<< HEAD
	GroupName="KF-NoTraderz"
	FriendlyName="No Trader"
	Description="Trader doors stay shut the entire game."
=======
     GroupName="KF-NoTraderz"
     FriendlyName="No Trader"
     Description="Trader doors stay shut the entire game."
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
