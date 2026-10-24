class KFIncendiaryExplosion extends KFNadeExplosion;

// An incendiary grenade going off: a flash, a rolling fireball, tongues of flame, burning fuel flung out to where the
// ground fires start, embers drifting down, and a dark plume of smoke rising after

simulated function NadeLight()
{
    if ( !bFlashed && !Level.bDropDetail && (Instigator != None)
        && ((Level.TimeSeconds - LastRenderTime < 0.2) || (PlayerController(Instigator.Controller) != None)) )
    {
        bDynamicLight = true;
        SetTimer(0.6, false);
    }
    else
        Timer();
}

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=IncFlash
         RespawnDeadParticles=False
         UseColorScale=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=90,G=170,R=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=0,G=40,R=140))
         MaxParticles=1
         StartLocationOffset=(Z=30.000000)
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.400000)
         StartSizeRange=(X=(Min=140.000000,Max=170.000000))
         InitialParticlesPerSecond=1000.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'AW-2004Particles.Weapons.HardSpot'
         LifetimeRange=(Min=0.120000,Max=0.140000)
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFIncendiaryExplosion.IncFlash'

     Begin Object Class=SpriteEmitter Name=IncFireball
         FadeOut=True
         RespawnDeadParticles=False
         SpinParticles=True
         UseColorScale=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         BlendBetweenSubdivisions=True
         Acceleration=(Z=120.000000)
         ColorScale(0)=(Color=(B=150,G=200,R=255))
         ColorScale(1)=(RelativeTime=0.500000,Color=(B=50,G=120,R=230))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=10,G=35,R=110))
         FadeOutStartTime=0.300000
         MaxParticles=5
         StartLocationOffset=(Z=35.000000)
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=30.000000)
         SpinsPerSecondRange=(X=(Min=-0.150000,Max=0.150000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.600000)
         SizeScale(1)=(RelativeTime=0.400000,RelativeSize=1.500000)
         SizeScale(2)=(RelativeTime=1.000000,RelativeSize=1.800000)
         StartSizeRange=(X=(Min=45.000000,Max=70.000000))
         InitialParticlesPerSecond=1000.000000
         Texture=Texture'ExplosionTex.Framed.exp1_frames'
         TextureUSubdivisions=2
         TextureVSubdivisions=4
         LifetimeRange=(Min=0.550000,Max=0.750000)
         StartVelocityRange=(X=(Min=-60.000000,Max=60.000000),Y=(Min=-60.000000,Max=60.000000),Z=(Min=40.000000,Max=140.000000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFIncendiaryExplosion.IncFireball'

     Begin Object Class=SpriteEmitter Name=IncTongues
         FadeOut=True
         RespawnDeadParticles=False
         SpinParticles=True
         UseColorScale=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         BlendBetweenSubdivisions=True
         Acceleration=(Z=80.000000)
         ColorScale(0)=(Color=(B=140,G=200,R=255))
         ColorScale(1)=(RelativeTime=0.450000,Color=(B=30,G=100,R=210))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=10,G=30,R=90))
         FadeOutStartTime=0.350000
         MaxParticles=24
         StartLocationOffset=(Z=15.000000)
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=20.000000)
         SpinsPerSecondRange=(X=(Max=0.600000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.600000)
         SizeScale(1)=(RelativeTime=0.300000,RelativeSize=1.200000)
         SizeScale(2)=(RelativeTime=1.000000,RelativeSize=0.400000)
         StartSizeRange=(X=(Min=20.000000,Max=45.000000))
         InitialParticlesPerSecond=1000.000000
         Texture=Texture'KillingFloorTextures.LondonCommon.fire3'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         LifetimeRange=(Min=0.600000,Max=0.950000)
         StartVelocityRange=(X=(Min=-380.000000,Max=380.000000),Y=(Min=-380.000000,Max=380.000000),Z=(Min=40.000000,Max=260.000000))
         VelocityLossRange=(X=(Min=2.000000,Max=2.500000),Y=(Min=2.000000,Max=2.500000),Z=(Min=1.000000,Max=1.500000))
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFIncendiaryExplosion.IncTongues'

     Begin Object Class=SpriteEmitter Name=IncFuel
         FadeOut=True
         RespawnDeadParticles=False
         SpinParticles=True
         UseColorScale=True
         UniformSize=True
         AutomaticInitialSpawning=False
         UseRandomSubdivision=True
         Acceleration=(Z=-900.000000)
         ColorScale(0)=(Color=(B=140,G=210,R=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=20,G=90,R=230))
         FadeOutStartTime=0.600000
         MaxParticles=18
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=15.000000)
         SpinsPerSecondRange=(X=(Max=1.000000))
         StartSpinRange=(X=(Max=1.000000))
         StartSizeRange=(X=(Min=10.000000,Max=18.000000))
         InitialParticlesPerSecond=1000.000000
         Texture=Texture'KillingFloorTextures.LondonCommon.fire3'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         LifetimeRange=(Min=0.700000,Max=0.950000)
         StartVelocityRange=(X=(Min=-240.000000,Max=240.000000),Y=(Min=-240.000000,Max=240.000000),Z=(Min=220.000000,Max=420.000000))
     End Object
     Emitters(3)=SpriteEmitter'KFMod.KFIncendiaryExplosion.IncFuel'

     Begin Object Class=SpriteEmitter Name=IncEmbers
         FadeOut=True
         RespawnDeadParticles=False
         UseColorScale=True
         UniformSize=True
         AutomaticInitialSpawning=False
         UseRandomSubdivision=True
         Acceleration=(Z=-220.000000)
         ColorScale(0)=(Color=(B=120,G=220,R=255))
         ColorScale(1)=(RelativeTime=0.500000,Color=(B=40,G=140,R=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=10,G=40,R=150))
         FadeOutStartTime=1.000000
         MaxParticles=40
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=25.000000)
         StartSizeRange=(X=(Min=2.500000,Max=4.500000))
         InitialParticlesPerSecond=1000.000000
         Texture=Texture'KillingFloorTextures.LondonCommon.fire3'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         LifetimeRange=(Min=1.300000,Max=2.300000)
         StartVelocityRange=(X=(Min=-230.000000,Max=230.000000),Y=(Min=-230.000000,Max=230.000000),Z=(Min=150.000000,Max=520.000000))
         VelocityLossRange=(X=(Min=0.800000,Max=1.200000),Y=(Min=0.800000,Max=1.200000))
     End Object
     Emitters(4)=SpriteEmitter'KFMod.KFIncendiaryExplosion.IncEmbers'

     Begin Object Class=SpriteEmitter Name=IncSmoke
         FadeOut=True
         FadeIn=True
         RespawnDeadParticles=False
         SpinParticles=True
         UseColorScale=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         UseRandomSubdivision=True
         Acceleration=(Z=35.000000)
         ColorScale(0)=(Color=(B=30,G=32,R=36,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=60,G=60,R=62,A=255))
         FadeOutStartTime=1.400000
         FadeInEndTime=0.400000
         MaxParticles=9
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=45.000000)
         SpinsPerSecondRange=(X=(Min=-0.080000,Max=0.080000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.800000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=3.000000)
         StartSizeRange=(X=(Min=60.000000,Max=95.000000))
         InitialParticlesPerSecond=1000.000000
         InitialDelayRange=(Min=0.200000,Max=0.300000)
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'EmitterTextures.MultiFrame.smoke_a2'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         LifetimeRange=(Min=2.600000,Max=3.400000)
         StartVelocityRange=(X=(Min=-40.000000,Max=40.000000),Y=(Min=-40.000000,Max=40.000000),Z=(Min=50.000000,Max=110.000000))
     End Object
     Emitters(5)=SpriteEmitter'KFMod.KFIncendiaryExplosion.IncSmoke'

     LightType=LT_Flicker
     LightHue=22
     LightSaturation=40
     LightBrightness=1000.000000
     LightRadius=15.000000
}
