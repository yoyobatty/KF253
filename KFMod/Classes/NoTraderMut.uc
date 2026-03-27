class NoTraderMut extends Mutator;

function bool CheckReplacement( Actor Other, out byte bSuperRelevant ) {

if ( Other.IsA('WeaponLocker') ) {
ReplaceWith(Other, "None");  //KFChar.ZombieClot
return false;
}
return true;
}

defaultproperties
{
     GroupName="KF"
     FriendlyName="No Trader"
     Description="Trader doors stay shut the entire game."
}
