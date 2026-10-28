// The flash where a glory kill tears a specimen apart (KFGloryBurst)
class KFGloryFlash extends Emitter;

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=GloryFlashGlow
         UseColorScale=True
         FadeOut=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ColorScale(0)=(Color=(B=30,G=80,R=230,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=10,G=40,R=180,A=255))
         FadeOutStartTime=0.050000
         MaxParticles=3
         RespawnDeadParticles=False
         SizeScale(0)=(RelativeSize=0.500000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.600000)
         StartSizeRange=(X=(Min=34.000000,Max=48.000000))
         InitialParticlesPerSecond=1000.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.250000,Max=0.350000)
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFGloryFlash.GloryFlashGlow'

     AutoDestroy=True
     LightType=LT_Steady
     LightHue=10
     LightSaturation=60
     LightBrightness=150.000000
     LightRadius=10.000000
     bDynamicLight=True
     bNoDelete=False
     RemoteRole=ROLE_None
     LifeSpan=1.500000
}
