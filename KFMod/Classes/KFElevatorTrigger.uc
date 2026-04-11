//=============================================================================
// KF Use Trigger. Now with bigger messages, and Refire delays for human users.
//
// By: Alex
// Major fixes by Marco (16.1.2009).
// Minor fix by YoYoBatty (2025) - Fixes NumberOfFloors being 0, adding moving message
//=============================================================================
class KFElevatorTrigger extends KFUseTrigger;

var() float ReUseDelay;
var transient float NextAttemptTime;
var() Sound ActivateSound; // Beep Beep TOOT TOOT! wizzzzPOW!
var KFElevator MyElevator;
var byte MyFloorNum; // 255 - Elevator itself.
var() string MessageMoving;
var float NextMessageTimer;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();
    SetTimer(2.0, true);
}

function bool SelfTriggered()
{
    return true;
}
function NotifyElevatorStarted( float MoveTimer )
{
	NextAttemptTime = Level.TimeSeconds+MoveTimer+ReUseDelay;
	SetTimer(MoveTimer+ReUseDelay+1,false);
}
function UsedBy( Pawn user )
{
    local byte k;

    if( Level.TimeSeconds>NextAttemptTime )
    {
        // If no elevator was linked, fall back to standard trigger behavior (Event -> Tag)
        if( MyElevator == None )
        {
            TriggerEvent(Event, self, user);
            NextAttemptTime = Level.TimeSeconds + 0.5;
            PlaySound(ActivateSound,SLOT_None, 255, false,200,,true);
            return;
        }
        if( MyFloorNum==255 )
        {
            if( AIController(user.Controller)!=None )
                k = MyElevator.GetAIDesiredFloor(user);
            else k = 255;
            if( k==255 )
            {
                if( MyElevator.KeyNum>=MyElevator.NumberOfFloors )
                    k = 0;
                else k = MyElevator.KeyNum+1;
            }
        }
        else k = MyFloorNum;
        NextAttemptTime = Level.TimeSeconds+0.5+MyElevator.DelayTime;
        MyElevator.GoToFloor(k,Self,user);
        //log("Elevator used by "@user.PlayerReplicationInfo.PlayerName@" to floor "@k);
        PlaySound(ActivateSound,SLOT_None, 255, false,200,,true);
    }
}
function Reset()
{
	NextAttemptTime = -1;
}

function Timer()
{
	local Pawn P;

	foreach TouchingActors(Class'Pawn',P)
	{
        if (AIController(P.Controller) != None )
		    Touch(P);
	}
}

function Touch( Actor Other )
{
    if ( Pawn(Other) != None )
    {
        // Send a string message to the toucher.
        if( MyElevator != None && MyElevator.bInterpolating )
        {
            if (MessageMoving != "")
                Pawn(Other).ClientMessage( MessageMoving , 'CriticalEvent');
        }
        else if( Message != "" )
            Pawn(Other).ClientMessage( Message , 'CriticalEvent');

        if ( AIController(Pawn(Other).Controller) != None )
            UsedBy(Pawn(Other));
    }
}

defaultproperties
{
    ReUseDelay=3.000000
    MessageMoving="The elevator is moving. Please wait."
}
