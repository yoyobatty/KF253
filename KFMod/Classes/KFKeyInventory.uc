class KFKeyInventory extends Inventory;
  
var KFKeyPickup MyPickup;

function UnLock(LockedObjective O)
{
    if ( !UnrealMPGameInfo(Level.Game).CanDisableObjective( O ) )
        O.DisableObjective(Pawn(Owner));
}

function Destroyed()
{
	if( MyPickup!=None )
		MyPickup.GotoState('Pickup');
	Super.Destroyed();
}

defaultproperties
{
}
