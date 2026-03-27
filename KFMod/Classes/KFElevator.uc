// By: Alex
class KFElevator extends Mover;

var bool bDoorsClosed;
var bool bElevatorMoving;
var () edfindable array <KFElevatorDoorMover> EDoors;
var sound DummySound;


// Let's mod this to detach any attached Movers.
simulated function Timer()
{


   //Log("Time until next possible use: "$KFElevatorTrigger(SavedTrigger).RefireDelay - (Level.TimeSeconds - (KFElevatorTrigger(SavedTrigger).LastAttempt + MoveTime)));




    if ( Velocity != vect(0,0,0) )
    {
        if ( bClientPause )
            bClientPause = false;
        return;     
    }
    if ( Level.NetMode == NM_Client && !bClientAuthoritative )
    {
        if ( ClientUpdate == 0 ) // not doing a move
        {
           // bElevatorMoving = false;

            if ( bClientPause )
            {
                if ( VSize(RealPosition - Location) > 3 )
                    SetLocation(RealPosition);
                else
                    RealPosition = Location;
                SetRotation(RealRotation);
                bClientPause = false;
            }
            else if ( RealPosition != Location )
                bClientPause = true;
        }
        else
            bClientPause = false;
    }
    else 
    {
        if ( bCollideActors )
        {
            if ( RealRotation != Rotation )
                RealRotation = Rotation;
            if ( RealPosition != Location )
                RealPosition = Location;
        }
    }
    


}


// Open the mover.
function DoOpen()
{
  bElevatorMoving = true;
  

  //for( i=0; i<EDoors.length; i++ )
   // EDoors[i].FollowElevator();
   
  // UpdateAttemptTimes();

   //if (SavedTrigger!= none && KFElevatorTrigger(SavedTrigger).bUsed)
    //ToggleDoors();

   //Super.DoOpen();
   
    bOpening = true;
    bDelaying = false;
    InterpolateTo( 1, MoveTime );
    MakeNoise(1.0);
    PlaySound( OpeningSound, SLOT_None, SoundVolume*TransientSoundVolume, false, SoundRadius, SoundPitch / 64.0);
    UntriggerEvent(Event, self, Instigator);
    AmbientSound = MoveAmbientSound;
 //   TriggerEvent(OpeningEvent, Self, Instigator);
    if ( Follower != None )
        Follower.DoOpen();
   

}

// Close the mover.
function DoClose()
{
  bElevatorMoving = true;

  //for( i=0; i<EDoors.length; i++ )
   // EDoors[i].FollowElevator();

 // UpdateAttemptTimes();
 //  Super.DoClose();
   
   //ToggleDoors();
   
    bOpening = false;
    bDelaying = false;
    InterpolateTo( Max(0,KeyNum-1), MoveTime );
    MakeNoise(1.0);
    PlaySound( ClosingSound, SLOT_None, SoundVolume * TransientSoundVolume, false, SoundRadius, SoundPitch / 64.0);
    UntriggerEvent(Event, self, Instigator);
    AmbientSound = MoveAmbientSound;
   // TriggerEvent(ClosingEvent,Self,Instigator);
    if ( Follower != None )
        Follower.DoClose();
}
/*

function UpdateAttemptTimes()
{
   local KFElevatorTrigger KFeT;

   //if (SavedTrigger != none && SavedTrigger.IsA('KFElevatorTrigger'))
   foreach DynamicActors(class 'KFElevatorTrigger',KFeT)
   if (KFeT != none)
   {
    //Log(KFeT);
    KFeT.LastAttempt = Level.TimeSeconds;
   }

}
*/


//
/*
function ToggleDoors()
{
   // local KFElevatorDoorMover AttachedMover;
   // local name LastAttachTag;
    local int i;
    
    //bElevatorMoving = true;

     for( i=0; i<EDoors.length; i++ )
      {
       if(!bDoorsClosed)
       {
       // Mover(EDoors[i]).Detach(self);
        EDoors[i].TriggerEvent(EDoors[i].Tag, self, Instigator);
        bDoorsClosed = true;
       }
       else
       if(bDoorsClosed)
       {
        EDoors[i].TriggerEvent(EDoors[i].Tag, self, Instigator);
       // Mover(EDoors[i]).Attach(self);
        bDoorsClosed = false;
       }
      }



}
*/


/*   OLD AND BUSTED CODE

foreach DynamicActors(class'KFElevatorDoorMover', AttachedMover)
    {
     if(AttachedMover.AttachTag == Tag && bOpening && !bClosed )
     {
      if (LastAttachTag == '' && LastAttachTag != AttachedMover.AttachTag)
      {
      // Log("CHILD'S BASE IS : "$AttachedMover.Base );
       LastAttachTag = AttachedMover.AttachTag;
       AttachedMover.AttachTag = '';
       AttachedMover.SetBase(none);
       AttachedMover.SetOwner(none);
      //Log("detaching a mover from the elevator!");

      }
      else
      {
       AttachedMover.AttachTag = LastAttachTag;
       LastAttachTag = '';
       AttachedMover.SetBase(self);
       AttachedMover.SetOwner(self);

      }
     }
    }


*/

function PostBeginPlay()
{
 local KFElevatorTrigger T;

 Super.PostBeginPlay();

 ForEach DynamicActors( class 'KFElevatorTrigger', T)
 {
  if (T!=none)
   T.ElevatorMoveTime = MoveTime;
 }

/*
 for( d=0; d<EDoors.length; d++ )
 EDoors[d].SetOwner(self);
  */
}


// Handle when the mover finishes closing.
function FinishedClosing()
{
Super.FinishedClosing();
bElevatorMoving = false;
AmbientSound = DummySound;

}

// Handle when the mover finishes opening.
function FinishedOpening()
{
Super.FinishedOpening();
bElevatorMoving = false;
AmbientSound = DummySound;
}


//=================================================================
// Other Mover States

// Toggle when triggered.
state() Elevator
{
    function bool SelfTriggered()
    {
        return false;
    }
    function Reset()
    {
        super.Reset();

        if ( bOpening )
        {
            // Reset instantly
            SetResetStatus( true );
            GotoState( 'Elevator', 'Close' );
        }
    }
        
    function Trigger( actor Other, pawn EventInstigator )
    {
        SavedTrigger = Other;
        Instigator = EventInstigator;
        if ( SavedTrigger != None )
            SavedTrigger.BeginEvent();
        if( KeyNum==0 || KeyNum<PrevKeyNum )
            GotoState( 'Elevator', 'Open' );
        else
            GotoState( 'Elevator', 'Close' );
    }
Open:
    bClosed = false;
    TriggerEvent(OpeningEvent, Self, Instigator);
    if ( DelayTime > 0 )
    {
        bDelaying = true;
        Sleep(DelayTime);
    }
    DoOpen();
    FinishInterpolation();
    FinishedOpening();
    if ( SavedTrigger != None )
        SavedTrigger.EndEvent();
    Stop;
Close:      
    TriggerEvent(ClosingEvent, Self, Instigator);
    if ( DelayTime > 0 )
    {
        bDelaying = true;
        Sleep(DelayTime);
    }
    DoClose();
    FinishInterpolation();
    FinishedClosing();
    SetResetStatus( false );
}

defaultproperties
{
     TransientSoundVolume=100.000000
}
