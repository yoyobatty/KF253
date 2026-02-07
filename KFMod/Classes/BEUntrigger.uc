//======================================
// BEUntrigger - Slinky - 4/28/05
//======================================
//  Used as a trigger inverter, for when
// you need to pick up untrigger messages
// coming from a trigger.  Allows filters.
//======================================
// Black Ether Studios, 2005.
//======================================
class BEUntrigger extends Triggers;

var(Events) bool bSendUntrigger,bSendTrigger;

event Trigger( Actor Other, Pawn EventInstigator )
{
	if(bSendUntrigger)
		UntriggerEvent(Event,Other,EventInstigator);
}
event Untrigger( Actor Other, Pawn EventInstigator )
{
	if(bSendTrigger)
		TriggerEvent(Event,Other,EventInstigator);
}

defaultproperties
{
<<<<<<< HEAD
	bSendUntrigger=True
	bSendTrigger=True
=======
     bSendUntrigger=True
     bSendTrigger=True
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
