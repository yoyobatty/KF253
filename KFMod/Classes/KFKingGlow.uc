// A red glow: the King Fleshpound's chest charging its beam, and where the beam burns (ZombieKingFleshpound)
class KFKingGlow extends Emitter;

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=KingGlowCore
         UseColorScale=True
         FadeOut=True
         UniformSize=True
         ColorScale(0)=(Color=(B=60,G=110,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=10,G=30,R=230,A=255))
         FadeOutStartTime=0.050000
         MaxParticles=4
         StartSizeRange=(X=(Min=40.000000,Max=56.000000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.100000,Max=0.150000)
         ParticlesPerSecond=30.000000
         InitialParticlesPerSecond=30.000000
         AutomaticInitialSpawning=False
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFKingGlow.KingGlowCore'

     Begin Object Class=SpriteEmitter Name=KingGlowSparks
         UseColorScale=True
         FadeOut=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         Acceleration=(Z=-400.000000)
         ColorScale(0)=(Color=(B=80,G=180,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=10,G=50,R=255,A=255))
         FadeOutStartTime=0.200000
         MaxParticles=40
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=0.200000)
         StartSizeRange=(X=(Min=3.000000,Max=6.000000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'KFX.KFSparkHead'
         TextureUSubdivisions=1
         TextureVSubdivisions=2
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.300000,Max=0.600000)
         StartVelocityRange=(X=(Min=-200.000000,Max=200.000000),Y=(Min=-200.000000,Max=200.000000),Z=(Min=-50.000000,Max=250.000000))
         ParticlesPerSecond=50.000000
         InitialParticlesPerSecond=50.000000
         AutomaticInitialSpawning=False
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFKingGlow.KingGlowSparks'

     LightType=LT_Steady
     LightHue=0
     LightSaturation=30
     LightBrightness=220.000000
     LightRadius=8.000000
     bDynamicLight=True
     bNoDelete=False
     RemoteRole=ROLE_None
}
