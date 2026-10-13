class VSBaseMut extends Mutator
	CacheExempt;

function bool CheckReplacement(Actor Other, out byte bSuperRelevant)
{
	if( Controller(Other)!=None )
		Controller(Other).PlayerReplicationInfoClass = Class'VSPRI';
	return true;
}

defaultproperties
{
}
