//=============================================================================
// KF Use Trigger. Now with bigger messages, and Refire delays for human users.
//
// By: Alex
//=============================================================================
class KFElevatorTrigger extends UseTrigger;

var () int ReFireDelay;
var float LastAttempt;
var () Sound ActivateSound; // Beep Beep TOOT TOOT! wizzzzPOW!
var int ElevatorMoveTime;
var bool bUsed; //
var KFElevator MyElevator;
var KFDoorMover MyTopDoors[2],MyBottomDoors[2];
var bool bTopTrigger;
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
          if (D.tag == event)
           bTopTrigger = true;
        }
      }
      
      ForEach DynamicActors( class 'KFDoorMover',C)
      {
        if (C!=none && C.bElevOuterDoorBottom)
        {
          MyBottomDoors[BottomDoorArray] = C;
          BottomDoorArray ++;
          if (C.tag == event)
           bTopTrigger = false;
        }
      }
      
      SetTimer(1.0, true);
}



function bool SelfTriggered()
{
    return true;
}

function UsedBy( Pawn user )
{
     if (bUsed && Level.TimeSeconds - (LastAttempt + ElevatorMoveTime + RefireDelay) >= RefireDelay )
    {
     MyElevator.TriggerEvent(MyElevator.tag, self, user);
     PlaySound(ActivateSound,SLOT_None, 255, false,200,,true);
     UpdateAttempts();
    }  
    
    else
    if (!bUsed)
    {
      MyElevator.TriggerEvent(MyElevator.tag, self, user);
     PlaySound(ActivateSound,SLOT_None, 255, false,200,,true);
     UpdateAttempts();
     bUsed=true;
    }
}

function UpdateAttempts()
{
 local KFElevatorTrigger KET;

 ForEach DynamicActors( class 'KFElevatorTrigger',KET)
     KET.LastAttempt = Level.TimeSeconds;

}


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

defaultproperties
{
     ReFireDelay=10
}
