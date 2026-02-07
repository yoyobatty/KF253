class MetalHitEmitter extends KFHitEmitter;

var     bool    bFlashed;
         #exec OBJ LOAD FILE=KFWeaponSound.uax replication
replication
{
    // Things the server should send to the client.
    reliable if( bNetDirty && (!bNetOwner || bDemoRecording || bRepClientDemo) && (Role==ROLE_Authority) )
        bFlashed;

}

simulated function PostBeginPlay()
{
   Super.Postbeginplay();
   SparkLight();
}

simulated function SparkLight()
{
    if ( !bFlashed && !Level.bDropDetail && (Instigator != None)
        && ((Level.TimeSeconds - LastRenderTime < 0.2) || (PlayerController(Instigator.Controller) != None)) )
    {
        bDynamicLight = true;
        SetTimer(0.15, false);
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
     ImpactSounds(0)=Sound'KFWeaponSound.bullethitmetal2'
     ImpactSounds(1)=Sound'KFWeaponSound.bullethitmetal3'
     ImpactSounds(2)=Sound'KFWeaponSound.bullethitmetal4'
     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
         UseDirectionAs=PTDU_Up
         UseCollision=True
         UseColorScale=True
         RespawnDeadParticles=False
         UseSizeScale=True
         UseRegularSizeScale=False
         ScaleSizeYByVelocity=True
         AutomaticInitialSpawning=False
         BlendBetweenSubdivisions=True
         UseRandomSubdivision=True
         Acceleration=(Z=-900.000000)
         DampingFactorRange=(X=(Min=0.200000),Y=(Min=0.200000),Z=(Min=0.200000,Max=0.500000))
         ColorScale(0)=(Color=(B=200,G=255,R=255))
         ColorScale(1)=(RelativeTime=0.200000,Color=(B=190,G=220,R=242))
         ColorScale(2)=(RelativeTime=0.400000,Color=(B=200,G=255,R=255))
         ColorScale(3)=(RelativeTime=1.000000,Color=(B=200,G=255,R=255))
         MaxParticles=15
         DetailMode=DM_High
         SizeScale(2)=(RelativeTime=0.070000,RelativeSize=1.000000)
         SizeScale(3)=(RelativeTime=1.000000,RelativeSize=1.000000)
         StartSizeRange=(X=(Min=3.000000,Max=5.000000),Y=(Min=2.000000,Max=4.000000),Z=(Min=2.000000,Max=2.000000))
         ScaleSizeByVelocityMultiplier=(Y=0.020000)
         InitialParticlesPerSecond=100.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'KFX.KFSparkHead'
         TextureUSubdivisions=1
         TextureVSubdivisions=2
         LifetimeRange=(Min=0.010000,Max=0.150000)
         StartVelocityRange=(Y=(Min=-600.000000,Max=600.000000),Z=(Min=-600.000000,Max=600.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.MetalHitEmitter.SpriteEmitter0'

     LightType=LT_Steady
     LightHue=40
     LightSaturation=150
     LightBrightness=100.000000
     LightRadius=3.000000
}
