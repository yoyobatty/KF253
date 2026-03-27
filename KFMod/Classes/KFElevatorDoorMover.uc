class KFElevatorDoorMover extends KFDoorMover;

var vector InitialOffset;
var bool bAttached, bDoorIsClosed;
var Vector AdjustedOffset;



simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if(Owner!=none)
      InitialOffset = Location - Owner.Location;

}


function FollowElevator()  // Called from the elevator to attach the door to it while moving.
{
    Enable('Tick');
    bAttached = true;
}
    
function DetachFromElevator()  // Called from the elevator to detach the door so it can open.
{
    Disable('Tick');
    bAttached =false;
}

function Tick(float DeltaTime)
{

  if (!KFElevator(Owner).bElevatorMoving && bAttached)
   DetachFromElevator();
  else
  {
    if (KeyNum == 0 && !bDoorIsClosed )
    {
     SetLocation(Owner.Location + InitialOffset);  // Follow the elevator.
     BasePos = Location;  // Adjust the base position so the doors don't return to the ground floor while opening.
    }
    if (KeyNum == 1 && bDoorIsClosed)
    {
     //AdjustedLocation.X = 10;
     // InterpolateTo(1,0.1);
      //Log("Initial Offset: "$InitialOffset);
     // Log("Adjusted Offset: "$AdjustedOffset);

      SetLocation(Owner.Location + InitialOffset);  // Follow the elevator.
      BasePos = Location;  // Adjust the base position so the doors don't return to the ground floor while opening.
    }

  }
}

// Handle when the mover finishes opening.
function FinishedOpening()
{
    Super.FinishedOpening();
    bDoorIsClosed = false;
    //AdjustedOffset = Location - Owner.Location;
}

// Handle when the mover finishes closing.
function FinishedClosing()
{
   Super.FinishedClosing();
   AdjustedOffset = Location - Owner.Location;
   bDoorIsClosed = true;
}

defaultproperties
{
}
