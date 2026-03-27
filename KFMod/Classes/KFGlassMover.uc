// Custom Bits of Glass for KF!
// By: Alex
// These will respond both to gunfire AND pawn / karma actor encroachment.
// If the encroaching pawn is a KFMonster, the monster will play an attack animation.
// They do not block paths.

class KFGlassMover extends Actor;

var () class <Emitter> GlassBits,BreakGlassBits;  // Stuff to spawn when the Window bit breaks.
var () Material ShatteredTexture; // What to change the skin of the glass to when any part of the pane breaks.
var () int Health;  // How strong is this bit of glass?
var bool bCracked;
var KFGlassMover GM;


replication
{
    reliable if(Role == ROLE_Authority)
        ClientGlassBits,ClientBreakGlassBits,Health;
    reliable if (Role < ROLE_Authority)
     bCracked;
}


simulated function PostNetBeginPlay()
{
  // Hack for glass that starts out broken, so you can jump through it.
  if(Health == 1)
   bCracked = true;
}

// When bumped by player (OR ZOMBIES!!!!). evil things happen ....

simulated function Bump( actor Other )
{
 local KFMonster GlassCrasher;
 local class <DamageType> DummyDam;

 // if our window crasher is a Zombie, he must use his arms to break the glass,
 // and pause for a moment while doing this!


 if (Other.IsA('KFHumanPawn') && !bCracked)
  return;

 // Log("Touching actor was moving at:");
 // Log(Other.Velocity);

  // If the incoming object is moving at a speed above our set threshold ..
  if (vSize(Other.Velocity) >= 10)
  {
    TakeDamage(VSize(Other.Velocity),pawn(Other),location,Other.Velocity,DummyDam);
    
  if ( EffectIsRelevant(Location,false))
     {
      ClientGlassBits();
     }

  }

 if (Other.IsA('KFMonster'))
 {
  GlassCrasher = KFMonster(Other);
  
  GlassCrasher.Acceleration = vect(0,0,0);
  GlassCrasher.Velocity = vect(0,0,0);
  
  GlassCrasher.SetAnimAction(GlassCrasher.MeleeAnims[0]);
  KFMonsterController(GlassCrasher.controller).GotoState('Kicking');
  GlassCrasher.bShotAnim = true;

  TakeDamage(GlassCrasher.damageConst,pawn(Other),location,Other.Velocity,DummyDam);
 }




}

simulated function ClientGlassBits()
{
  local Emitter GlassShards;

  GlassShards = Spawn(GlassBits,,,Location,Rotation);
}

simulated function ClientBreakGlassBits()
{
  local Emitter BreakGlassShards;

  BreakGlassShards = Spawn(BreakGlassBits,,,Location,Rotation);
 // BreakWindowGlassEmitter(BreakGlassShards).GlassExplosionEmitter.MaxParticles = (DrawScale * 20);
}


// Added bHidden for small bit of optimization
simulated function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
                        Vector momentum, class<DamageType> damageType)
{
    //local KFGlassMover GM;
    

    Health -= Damage;

    // glass shatters
    if (Health <= 0 )
    {
        if(bHidden)
         return;

        if ( (AIController(instigatedBy.Controller) != None)
            && (instigatedBy.Controller.Focus == self) )
            instigatedBy.Controller.StopFiring();

         //Trigger(self, instigatedBy);
         //GotoState( , 'Open' );
         SetCollision(false,false,false);
         bHidden = true;
         ClientBreakGlassBits();
         PostNetReceive();

         //Destroy();



        if ( (AIController(instigatedBy.Controller) != None) && (instigatedBy.Controller.Target == self) )
            instigatedBy.Controller.StopFiring();



    }

     if ( EffectIsRelevant(Location,false) )
     {
      ClientGlassBits();
     }
     


}

simulated function PostNetReceive()
{
  //local KFGlassMover GM;

        foreach DynamicActors(class'KFGlassMover',GM)
          {
           if (GM.Tag == tag && tag != 'KFGlassMover')
           {
            GM.Health = 1;
            GM.bCracked = true;
            GM.Skins[0] = ShatteredTexture;
           }
          }

}

defaultproperties
{
     GlassBits=Class'KFMod.WindowGlassEmitter'
     BreakGlassBits=Class'KFMod.BreakWindowGlassEmitter'
     ShatteredTexture=Shader'KillingFloorLabTextures.Statics.ShaderCrackedGlass'
     Health=50
     bNoDelete=True
     bStasis=True
     bAlwaysRelevant=True
     bOnlyDirtyReplication=True
     RemoteRole=ROLE_SimulatedProxy
     NetUpdateFrequency=1.000000
     NetPriority=2.700000
     bCollideActors=True
     bBlockActors=True
     bBlockKarma=True
}
