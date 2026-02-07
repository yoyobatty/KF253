// By: Alex
<<<<<<< HEAD
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
=======
// Major fixes by Marco.
class KFElevator extends Mover;

var() float ElevatorMoveSpeed;
var() name ElevatorFloorTags[8]; // The tag of the desired doors/triggers.
var() name ElevatorCenterTriggerTag; // The tag of the trigger inside elevator.
var sound DummySound;
struct DoorMType
{
	var array<KFDoorMover> Doors;
};
var DoorMType FloorMovers[ArrayCount(ElevatorFloorTags)];
var KFElevatorTrigger FloorTriggers[ArrayCount(ElevatorFloorTags)],ElevCenterTrigger;
var LiftExit MyExits[ArrayCount(ElevatorFloorTags)]; // Our desired lift exits for AI hint.
var byte GoalKeyFrame,NumberOfFloors;
var bool bElevatorActive;
var bool bUseElevator;

function PostBeginPlay()
{
	local KFDoorMover K;
	local KFElevatorTrigger T;
	local byte i;
	local NavigationPoint N;
	local bool bFoundFloor;

	Super.PostBeginPlay();
	DummySound = AmbientSound;

	ForEach DynamicActors(class'KFElevatorTrigger',T)
	{
		for( i=0; i<ArrayCount(ElevatorFloorTags); i++ )
		{
			if( ElevatorFloorTags[i]!='' && ElevatorFloorTags[i]==T.Tag )
			{
				FloorTriggers[i] = T;
				T.MyElevator = Self;
				T.MyFloorNum = i;
                if ( i > NumberOfFloors )
                    NumberOfFloors = i;
				bFoundFloor = true;
				break;
			}
		}
		if( ElevatorCenterTriggerTag!='' && T.Tag==ElevatorCenterTriggerTag )
		{
			ElevCenterTrigger = T;
			T.MyElevator = Self;
			T.SetBase(Self);
			T.MyFloorNum = 255;
		}
	}
	ForEach DynamicActors(class'KFDoorMover',K)
	{
		for( i=0; i<ArrayCount(ElevatorFloorTags); i++ )
		{
			if( ElevatorFloorTags[i]!='' && ElevatorFloorTags[i]==K.Tag )
			{
				if ( i > NumberOfFloors )
                    NumberOfFloors = i;
				FloorMovers[i].Doors[FloorMovers[i].Doors.Length] = K;
				bFoundFloor = true;
				if( FloorTriggers[i]!=None )
				{
					FloorTriggers[i].AddDoor(K);
					K.MyTrigger = FloorTriggers[i];
				}
				break;
			}
		}
	}

	// If we didn't find any valid elevator floors, fall back to stock mover behavior
	if( !bFoundFloor )
	{
		bUseElevator = false;
		// If mapper left InitialState as Elevator, switch to a normal mover state
		if( InitialState=='Elevator' )
			InitialState='TriggerToggle';
		GotoState(InitialState);
		return;
	}
	for( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
	{
		if( LiftExit(N)!=None && LiftExit(N).MyLift==Self && LiftExit(N).KeyFrame<ArrayCount(ElevatorFloorTags) )
			MyExits[LiftExit(N).KeyFrame] = LiftExit(N);
	}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}


// Handle when the mover finishes closing.
function FinishedClosing()
{
<<<<<<< HEAD
Super.FinishedClosing();
bElevatorMoving = false;
AmbientSound = DummySound;

=======
	Super.FinishedClosing();
	AmbientSound = DummySound;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

// Handle when the mover finishes opening.
function FinishedOpening()
{
<<<<<<< HEAD
Super.FinishedOpening();
bElevatorMoving = false;
AmbientSound = DummySound;
}

=======
	Super.FinishedOpening();
	AmbientSound = DummySound;
}

// Notify AI that mover finished movement
function FinishNotify()
{
	Super.FinishNotify();
	bClosed = True;
}


// Interpolation ended.
simulated event KeyFrameReached()
{
	local Mover M;

	PrevKeyNum = KeyNum;
	PhysAlpha  = 0;
	ClientUpdate--;

	// Finished interpolating.
	NetUpdateTime = Level.TimeSeconds - 1;
	FinishNotify();
	if ( (ClientUpdate == 0) && ((Level.NetMode != NM_Client) || bClientAuthoritative) )
	{
		RealPosition = Location;
		RealRotation = Rotation;
		ForEach BasedActors(class'Mover', M)
			M.BaseFinished(); 
	}
}

function DoOpen()
{
	local byte i;
	local float MT;

	bOpening = true;
	bDelaying = false;
	MT = FMax(VSize(KeyPos[GoalKeyFrame]-Location)/ElevatorMoveSpeed,0.1f);
	InterpolateTo( GoalKeyFrame, MT );
	for( i=0; i<=NumberOfFloors; i++ )
		if( FloorTriggers[i]!=None )
			FloorTriggers[i].NotifyElevatorStarted(MT);
	if( ElevCenterTrigger!=None )
		ElevCenterTrigger.NotifyElevatorStarted(MT);
	MakeNoise(1.0);
	PlaySound( OpeningSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
	AmbientSound = MoveAmbientSound;
	TriggerEvent(OpeningEvent, Self, Instigator);
}

/* Attempt to figure out the AI players desired floor, if fails then do like with players */
function byte GetAIDesiredFloor( Pawn Other )
{
	local int i;
	local byte j;

	for( i=0; i<5; i++ )
		if( LiftExit(Other.Controller.RouteCache[i])!=None )
		{
			for( j=0; j<=NumberOfFloors; j++ )
				if( MyExits[j]==Other.Controller.RouteCache[i] )
				{
					if( j==KeyNum )
						break;
					return j;
				}
		}
	return 255;
}

function GoToFloor( byte FloorNum, Actor Other, Pawn EventInstigator )
{
	Trigger(Other,EventInstigator);
}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

//=================================================================
// Other Mover States

// Toggle when triggered.
state() Elevator
{
<<<<<<< HEAD
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
=======
Ignores Trigger;

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
			GotoState(,'Close');
		}
	}
	function GoToFloor( byte FloorNum, Actor Other, Pawn EventInstigator )
	{
		if( KeyNum==FloorNum || bElevatorActive )
			return; // nocando.
		GoalKeyFrame = FloorNum;
		SavedTrigger = Other;
		Instigator = EventInstigator;
		if ( SavedTrigger != None )
			SavedTrigger.BeginEvent();
		bElevatorActive = true;
		GotoState(,'Open');
	}
	function ToggleDoors( byte KeyNums, bool bOpened )
	{
		local int l,i;

		l = FloorMovers[KeyNums].Doors.Length;
		for( i=0; i<l; i++ )
		{
			FloorMovers[KeyNums].Doors[i].Instigator = Instigator;
			if( bOpened )
				FloorMovers[KeyNums].Doors[i].GoToState(,'Open');
			else FloorMovers[KeyNums].Doors[i].GoToState(,'Close');
		}
	}
Begin:
	Sleep(0.01);
	ToggleDoors(KeyNum,True);
	Stop;
Open:
	ToggleDoors(KeyNum,False);
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
	bElevatorActive = false;
	if ( SavedTrigger != None )
		SavedTrigger.EndEvent();
	ToggleDoors(GoalKeyFrame,True);
	Stop;
Close:
	DoClose();
	FinishInterpolation();
	FinishedClosing();
	SetResetStatus( false );
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

defaultproperties
{
<<<<<<< HEAD
	TransientSoundVolume=100.000000
=======
    ElevatorMoveSpeed=350.000000
    MoverEncroachType=ME_IgnoreWhenEncroach
    InitialState="Elevator"
    TransientSoundVolume=100.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
