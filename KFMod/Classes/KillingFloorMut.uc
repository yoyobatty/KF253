class KillingFloorMut extends Mutator;

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if( Controller(Other)!=None )
		Controller(Other).PlayerReplicationInfoClass = Class'KFPlayerReplicationInfo';
	return true;
}

defaultproperties
{
<<<<<<< HEAD
	GroupName="KF"
=======
     GroupName="KF"
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
