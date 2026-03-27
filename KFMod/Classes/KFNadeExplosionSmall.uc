class KFNadeExplosionSmall extends NewExplosionC;

var     bool    bFlashed;

replication
{
    // Things the server should send to the client.
    reliable if( bNetDirty && (!bNetOwner || bDemoRecording || bRepClientDemo) && (Role==ROLE_Authority) )
        bFlashed;

}

simulated function PostBeginPlay()
{
   Super.Postbeginplay();
   NadeLight();
}



simulated function NadeLight()
{
    if ( !bFlashed && !Level.bDropDetail && (Instigator != None)
        && ((Level.TimeSeconds - LastRenderTime < 0.2) || (PlayerController(Instigator.Controller) != None)) )
    {
        bDynamicLight = true;
        SetTimer(0.25, false);
    }
    else 
        Timer();
}


simulated function Timer()
{
    bDynamicLight = false;
}

defaultproperties
{
     Emitters(0)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter0'

     Emitters(1)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter1'

     Emitters(2)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter2'

     Emitters(3)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter3'

     Emitters(4)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter4'

     Emitters(5)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter5'

     LightType=LT_Steady
     LightHue=30
     LightSaturation=100
     LightBrightness=500.000000
     LightRadius=6.000000
     RemoteRole=ROLE_SimulatedProxy
     bNotOnDedServer=False
}
