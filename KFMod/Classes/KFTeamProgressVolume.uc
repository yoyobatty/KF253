// Ok, what this does is it basically checks to see if
// every player on the server is in a certain area, and if 
// that is satisfied, it calls the volume's event.
// This is useful for story based missions where you need to 
// gather your whole team before you can progress.

// Alex

class KFTeamProgressVolume extends PhysicsVolume ;

var int NumPlayers;
var int NumTouching; 
var KFHumanPawn LastTouching;
var GameReplicationInfo GRI;
var bool bOff;

// Configurable Variables

var () bool bDisableAfterTriggered;   // default true.  Changes this if you'd like to the volume to continue checking player counts.
var () bool bTimeOut;   // default false.  If true, the volume's event will fire even if not all players are inside.
var () int TimeOutSeconds;  // Number of seconds before timeout is called
var () float PlayerThreshold;  // Min percent of total players who HAVE to be in the volume before the timeout can go through.

event PostNetBeginPlay()
{
  SetTimer(1.0,true);
}


simulated function Timer()
{
   local int i;

   // Why check, if the volume is disabled?
   if (bOFF)
    return;

    foreach TouchingActors( class 'KFHumanPawn', LastTouching )
     if(LastTouching!= none && LastTouching.health > 0)
      NumTouching ++;


  for ( i=0; i<GRI.PRIArray.Length; i++ )
   if (Pawn(GRI.PRIArray[i].Owner) != none &&
   Pawn(GRI.PRIArray[i].Owner).health > 0)
    NumPlayers ++;


  if (NumTouching / NumPlayers >= PlayerThreshold )
  {
   TriggerEvent(Event,self,LastTouching);
   self.SetCollision(false,false,false);
  }

}


/*

simulated event PawnEnteredVolume(Pawn P)
{
  local KFHumanPawn A;



  A = KFHumanPawn(P);
  LastTouching = A;
  //log("Touched");
  NumTouching ++;

  GRI = PlayerController(A.Controller).GameReplicationInfo;

    if((NumTouching +1) >= GRI.PRIArray.Length)
    {
     TriggerEvent(Event,self,A);

     if(bDisableAfterTriggered)
     {
      self.SetCollision(false,false,false);
     }
    }

   // So we dont have enough players, but we've set timeout
   // check to see if the percentage of total players in our volume
   // makes the threshold requirement

   if (bTimeOut && TimeOutSeconds >0 && (NumTouching +1 / GRI.PRIArray.Length) >= PlayerThreshold)
   {
     SetTimer(1.0,false);
   }

   
   // Log(A);
   // Log(GRI.PRIArray.Length);
   // Log("Num Touching :"$NumTouching);



}


simulated event PawnLeavingVolume(Pawn P)
{

      //  Super.PawnLeavingVolume(P);
       // log("UN-Touched");
        NumTouching --;
}
*/



function TriggerEvent( Name EventName, Actor Other, Pawn EventInstigator )
{
   if(bDisableAfterTriggered)
   {
     bOFF = true;
     SetTimer(0.1,false);
   }

  Super.TriggerEvent(EventName,Other,EventInstigator);
  
}  



function Trigger( actor Other, pawn EventInstigator )
{
    local KFHumanPawn P;

    if (bOff) 
     return;

    SetCollision(!bCollideActors);
    Log("Progress volume collision set to "$bCollideActors);

    foreach TouchingActors( class 'KFHumanPawn', P )
     if(P != none && P.health > 0)
      P.UnTouch(self);
      
    if(bCollideActors)
     SetTimer(1.0,true);

}

defaultproperties
{
     bDisableAfterTriggered=True
     TimeOutSeconds=60
     PlayerThreshold=0.750000
}
