//=========================================================
//  BETimedTrigger - Slinky - 4/28/05
//=========================================================
//  Triggers the associated event after the listed delay.
// Only one delayed event per trigger may be processed
// simultaneously.
//=========================================================
//  Black Ether Studios, 2005.
//=========================================================
class BETimedTrigger extends Triggers;

var(Events) float eventDelay;
var bool processingTrigger;

function Trigger( actor Other, pawn EventInstigator )
{
	if( processingTrigger )
		return;
	Instigator = EventInstigator;
	processingTrigger = true;
	SetTimer(eventDelay,false);
}

event Timer()
{
	TriggerEvent(Event,Self,Instigator);
	processingTrigger = false;
}

defaultproperties
{
<<<<<<< HEAD
	eventDelay=1.000000
=======
     eventDelay=1.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
