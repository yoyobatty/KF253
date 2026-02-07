class MutMachinePistols extends Mutator;

function bool CheckReplacement( Actor Other, out byte bSuperRelevant )
{
	// here, in mutator subclass, change InventoryClassName if desired.  For example:
	if ( WeaponPickup(Other) != None )
	{
		if ( string(Other.Class) ~= "KFMod.SinglePickup" )
		{
			ReplaceWith( Other, "MachinePistolPickup" );
			return false;
		}
	}
	return true;
}

defaultproperties
{
<<<<<<< HEAD
	FriendlyName="Machine Pistols"
	Description="All the semi-auto 9mms in Killing Floor are replaced with fully automatic counterparts. "
=======
     FriendlyName="Machine Pistols"
     Description="All the semi-auto 9mms in Killing Floor are replaced with fully automatic counterparts. "
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
