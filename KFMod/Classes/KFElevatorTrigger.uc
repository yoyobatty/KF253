//=============================================================================
// KF Use Trigger. Now with bigger messages, and Refire delays for human users.
//
// By: Alex
<<<<<<< HEAD
//=============================================================================
class KFElevatorTrigger extends UseTrigger;

var () int ReFireDelay;
var float LastAttempt;
var () Sound ActivateSound; // Beep Beep TOOT TOOT! wizzzzPOW!
var int ElevatorMoveTime;
var bool bUsed; //
var KFElevator MyElevator;
var KFDoorMover MyTopDoors[2],MyBottomDoors[2];
//var () bool bTopTrigger;  // Is this trigger @ the top of the shaft?
var bool bCarTrigger; // Is this trigger used from inside the car?.

replication
{
  reliable if (Role==ROLE_Authority )
    LastAttempt,bUsed;
}

function PostBeginPlay()
{
     local KFElevator A;
     local KFDoorMover D,C;
     local int TopDoorArray,BottomDoorArray;
     
     TopDoorArray = 0 ;
     BottomDoorArray = 0;

      ForEach DynamicActors( class 'KFElevator', A)
      {
        if (A!=none)
        {
          MyElevator = A;
          ElevatorMoveTime = A.MoveTime;
        }
      }

      ForEach DynamicActors( class 'KFDoorMover',D)
      {
        if (D!=none && D.bElevOuterDoorTop)
        {
          MyTopDoors[TopDoorArray] = D;
          TopDoorArray ++;
         // if (D.tag == event)
         //  bTopTrigger = true;
        }
      }
      
      ForEach DynamicActors( class 'KFDoorMover',C)
      {
        if (C!=none && C.bElevOuterDoorBottom)
        {
          MyBottomDoors[BottomDoorArray] = C;
          BottomDoorArray ++;
       //   if (C.tag == event)
        //   bTopTrigger = false;
        }
      }
      
      SetTimer(1.0, true);
}


=======
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

function bool SelfTriggered()
{
    return true;
}

<<<<<<< HEAD
function UsedBy( Pawn user )
{
    // Why send back an elevator you just called...
  //   if(bTopTrigger && MyElevator.bClosed || !bTopTrigger && !MyElevator.bClosed)
  //    return;

    
     if (Level.TimeSeconds - LastAttempt >= RefireDelay )
    {
     MyElevator.TriggerEvent(MyElevator.tag, self, user);
     PlaySound(ActivateSound,SLOT_None, 255, false,200,,true);
     UpdateAttempts();
    }
}

function UpdateAttempts()
{
 local KFElevatorTrigger KET;

 ForEach DynamicActors( class 'KFElevatorTrigger',KET)
     KET.LastAttempt = Level.TimeSeconds;

}


/*
function Timer()
{
 local KFMonster Zom;

 //Log("Is teh elevator moving?"$MyElevator.bElevatorMoving);


 ForEach TouchingActors(class'KFMonster',Zom)
 {
 // Log(Zom);
  UsedBy(Zom);
 }


}

*/

defaultproperties
{
	ReFireDelay=10
=======
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
		log("Elevator used by "@user.PlayerReplicationInfo.PlayerName@" to floor "@k);
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
		Touch(P);
}

function Touch( Actor Other )
{
	if ( Pawn(Other) != None )
	{
	    // Send a string message to the toucher.
		if( !MyElevator.bInterpolating )
	    	if( Message != "" )
		    	Pawn(Other).ClientMessage( Message );
		else
			if (MessageMoving != "")
				Pawn(Other).ClientMessage( MessageMoving );

		if ( AIController(Pawn(Other).Controller) != None )
			UsedBy(Pawn(Other));
	}
}

defaultproperties
{
    ReUseDelay=3.000000
    MessageMoving="The elevator is moving. Please wait."
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
