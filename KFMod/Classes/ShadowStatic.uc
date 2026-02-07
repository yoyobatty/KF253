// A simple static mesh modded to cast dynamic shadows.

class ShadowStatic extends StaticMeshActor;

// shadow variables
var Projector Shadow;
var ShadowProjector PlayerShadow;
var globalconfig bool bBlobShadow;


 function PostBeginPlay()
 {
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
<<<<<<< HEAD
=======
    bActorShadows=True
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
