// He wears a suit. Walks aboot . Duh dum te tah Doot
// By : Alex

class HazMatWorker extends Mover;
#exec OBJ LOAD FILE=KFCharactersB.ukx

var () name WalkAnim;
var () name IdleAnim;
var () name DeathAnim;
var () float WalkRate; // Adjust anim play speeds based on Mover times. OR DEFRPOPS CUZ I CAN'T HACK TEH MATHS FOR THE OTHER. :-/
var () name SpecialAnim; // Unique Actions for our Hazmat .  // 1. DrugPound
var Actor NeedleProp,BoardProp;
var Actor OptionalProp;
var () class<actor>  OptionalPropType;
var bool bPendingDeath;
var ()class<emitter> BloodEffect; //When he dies, he GOES OUT GOREY. AND WE WANT MORE-Y SO IT AINT BORIN'    don't rap in comments. PLEASE.


// shadow variables
var Projector Shadow;
var ShadowProjector PlayerShadow;
var globalconfig bool bBlobShadow;


 function PostBeginPlay()
 {
   LinkSkelAnim(MeshAnimation'HazmatMan');
   LoopAnim(IdleAnim);

   PlayerShadow = Spawn(class'ShadowProjector',Self,'',Location);
   PlayerShadow.ShadowActor = self;
   PlayerShadow.bBlobShadow = bBlobShadow;
   PlayerShadow.LightDirection = Normal(vect(1,1,3));
   PlayerShadow.LightDistance = 320;
   PlayerShadow.MaxTraceDistance = 350;
   PlayerShadow.InitShadow();
   PlayerShadow.bShadowActive = true;
   
   if (OptionalPropType != none)
    { 
      OptionalProp = Spawn( OptionalPropType,,, Location, Rotation );
      AttachToBone( OptionalProp, 'AttachPoint' );
      
      if (!AttachToBone( OptionalProp, 'AttachPoint' ))
       NeedleProp.destroy();
    }


}


//  Add a needle to his hand

function AddNeedle()
{
    NeedleProp = Spawn( class 'KFMod.NeedleAttachment',,, Location, Rotation );
    AttachToBone( NeedleProp, 'AttachPoint' );
     if (!AttachToBone( NeedleProp, 'AttachPoint' ))
       NeedleProp.destroy();
}


function RemoveNeedle()
{
  NeedleProp.destroy();
}


//  Add a ClipBoard to his hand

function AddClipBoard()
{
    BoardProp = Spawn( class 'KFMod.BoardAttachment',,, Location, Rotation );
    AttachToBone( BoardProp, 'AttachPoint' );
     if (!AttachToBone( BoardProp, 'AttachPoint' ))
       BoardProp.destroy();
}

function RemoveClipBoard()
{
  BoardProp.destroy();
}


function DoOpen()
{

    LoopAnim(WalkAnim,WalkRate,0.1);
    bOpening = true;
    bDelaying = false;
    InterpolateTo( 1, MoveTime );
    MakeNoise(1.0);
    PlaySound( OpeningSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
    AmbientSound = MoveAmbientSound;
    TriggerEvent(OpeningEvent, Self, Instigator);
    if ( Follower != None )
        Follower.DoOpen();
}

// Close the mover.
function DoClose()
{
    LoopAnim(WalkAnim,WalkRate,0.1);
    bOpening = false;
    bDelaying = false;
    InterpolateTo( Max(0,KeyNum-1), MoveTime );
    MakeNoise(1.0);
    PlaySound( ClosingSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);
    UntriggerEvent(Event, self, Instigator);
    AmbientSound = MoveAmbientSound;
    TriggerEvent(ClosingEvent,Self,Instigator);
    if ( Follower != None )
        Follower.DoClose();
}

// Handle when the mover finishes opening.
function FinishedOpening()
{
    // Update sound effects.
    PlaySound( OpenedSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0);

    // Trigger any chained movers / Events
    TriggerEvent(Event, Self, Instigator);
    TriggerEvent(OpenedEvent, Self, Instigator);
    
   if (SpecialAnim == '')
     LoopAnim(IdleAnim,,0.1);
   else
     PlayAnim(SpecialAnim,,0.1);

    If ( MyMarker != None )
        MyMarker.MoverOpened();
    FinishNotify();
}

// Handle when the mover finishes closing.
function FinishedClosing()
{
    local Mover M;
    
    // Update sound effects.
    PlaySound( ClosedSound, SLOT_None, SoundVolume / 255.0, false, SoundRadius, SoundPitch / 64.0); 

    // Handle Events
    
    TriggerEvent( ClosedEvent, Self, Instigator );
    
    
    LoopAnim(IdleAnim,,0.1);
    
    // Notify our triggering actor that we have completed.
    if( SavedTrigger != None )
        SavedTrigger.EndEvent();

    SavedTrigger = None;
    Instigator = None;
    If ( MyMarker != None )
        MyMarker.MoverClosed();
    bClosed = true;
    FinishNotify(); 
    for ( M=Leader; M!=None; M=M.Follower )
        if ( !M.bClosed )
            return;
    UnTriggerEvent(OpeningEvent, Self, Instigator);
}



// Called by notify when we want to set this guy up to die soon (next time he's triggered by an event)
function PendingDeath()
{
 GotoState( 'DeathState','Die');
}



state() DeathState
{

    function Trigger( actor Other, pawn EventInstigator )
    {

        if (bPendingDeath)
        {
         //Log("I AM PENDING DEATH");
         PlayAnim(DeathAnim,,0.1);
        }

    }
    
    Die:
     bPendingDeath = true;
    // PlayAnim(DeathAnim,,0.1);
}


// Since direct effect notifies are out, call this from a script.

simulated function BloodSpray()
{
 local BloodExplosion HazMatBloodExplosion;
 //local Vector NewLocation;

// NewLocation = Location;
// NewLocation.Z += 70;

  HazMatBloodExplosion = spawn(class 'KFMod.HazMatBLoodSplash' ,,,Location,Rotation);
  HazMatBloodExplosion.SetRelativeLocation(vect(0,0,70));
  //AttachToBone(HazMatBloodExplosion, 'Bip01 Head');
}

defaultproperties
{
     WalkAnim="WalkCycle"
     IdleAnim="IdleCycle"
     DeathAnim="Die1"
     WalkRate=1.000000
     MoverEncroachType=ME_IgnoreWhenEncroach
     bDynamicLightMover=True
     DrawType=DT_Mesh
     bReplicateAnimations=True
     RemoteRole=ROLE_None
     Mesh=SkeletalMesh'KFCharactersB.HazmatMan'
     bShadowCast=False
     bBlockKarma=True
}
