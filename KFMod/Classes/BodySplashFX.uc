class BodySplashFX extends FleshHitEmitter;

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=SpriteEmitterSp
         FadeOut=True
         RespawnDeadParticles=False
         SpawnOnlyInDirectionOfNormal=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ScaleSizeYByVelocity=True
         ScaleSizeZByVelocity=True
         AutomaticInitialSpawning=False
         BlendBetweenSubdivisions=True
         UseRandomSubdivision=True
         Acceleration=(Z=-600.000000)
         ColorScale(0)=(Color=(G=255))
         ColorScale(1)=(RelativeTime=0.300000,Color=(B=255,G=255,R=255))
         ColorScale(2)=(RelativeTime=0.750000,Color=(B=96,G=255,R=255))
         ColorScale(3)=(RelativeTime=1.000000)
         ColorMultiplierRange=(Z=(Min=0.670000))
         FadeOutStartTime=0.255000
         MaxParticles=80
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=5.000000)
         StartMassRange=(Min=11.000000,Max=11.000000)
         UseRotationFrom=PTRS_Normal
         SpinsPerSecondRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeTime=1.000000,RelativeSize=3.500000)
         StartSizeRange=(X=(Min=14.000000,Max=17.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
         ScaleSizeByVelocityMultiplier=(X=0.000000,Y=0.000000,Z=0.000000)
         ScaleSizeByVelocityMax=3.000000
         InitialParticlesPerSecond=504.949005
         DrawStyle=PTDS_Modulated
         Texture=Texture'KFX.BloodySpray'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         LifetimeRange=(Min=0.500000,Max=0.750000)
         StartVelocityRange=(X=(Min=-150.000000,Max=150.000000),Y=(Min=-150.000000,Max=150.000000),Z=(Min=100.000000,Max=300.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.BodySplashFX.SpriteEmitterSp'

     LifeSpan=1.500000
}
