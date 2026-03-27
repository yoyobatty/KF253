// Ok this will be effin' gruesome.
// Full Animated arm mesh with convulsive looping anim.
// FURTHER, i'm including some custom projector based shadow code so we can get that high detail goodness for the menu.
// (since the arm is gonna be twitching, having a static shadow wouldnt do it justice :) )

class DetachedArm extends DECO_SpaceFighter;    // Decoration
#exec OBJ LOAD FILE=KFMapObjects.ukx

// shadow variables
var Projector Shadow;
var ShadowProjector PlayerShadow;
var globalconfig bool bBlobShadow;
var () bool bKActorShadows;


 function PostBeginPlay()
 {
   LinkSkelAnim(MeshAnimation'NastyArm');
   LoopAnim('Twitch');

    PlayerShadow = Spawn(class'ShadowProjector',Self,'',Location);
    PlayerShadow.ShadowActor = self;
    PlayerShadow.bBlobShadow = bBlobShadow;
    PlayerShadow.LightDirection = Normal(vect(1,1,3));
    PlayerShadow.LightDistance = 320;
    PlayerShadow.MaxTraceDistance = 350;
    PlayerShadow.InitShadow();
    PlayerShadow.bShadowActive = true;
}

simulated function Destroyed()
{
    if( PlayerShadow != None )
        PlayerShadow.Destroy();

    Super.Destroyed();
}

defaultproperties
{
     bStatic=False
     bStasis=False
     bReplicateAnimations=True
     Mesh=SkeletalMesh'KFMapObjects.NastyArm'
}
