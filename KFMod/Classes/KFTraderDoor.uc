// This door opens and closes ONLY by way of a specific call in the gametype.

class KFTraderDoor extends Mover;

defaultproperties
{
     MoverEncroachType=ME_IgnoreWhenEncroach
     InitialState="TriggerToggle"
}
