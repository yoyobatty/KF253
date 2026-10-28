// The moment a specimen arrives in a lockdown (KFTeleportFX): a flash, a ring of fire running out over the floor, sparks
class KFTeleportFlash extends Emitter;

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=ArriveFlash
         UseColorScale=True
         FadeOut=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ColorScale(0)=(Color=(B=120,G=200,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=10,G=50,R=220,A=255))
         FadeOutStartTime=0.050000
         MaxParticles=3
         RespawnDeadParticles=False
         SizeScale(0)=(RelativeSize=0.400000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.500000)
         StartSizeRange=(X=(Min=110.000000,Max=140.000000))
         InitialParticlesPerSecond=1000.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.250000,Max=0.300000)
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFTeleportFlash.ArriveFlash'

     Begin Object Class=SpriteEmitter Name=ArriveRing
         UseDirectionAs=PTDU_Normal
         UseColorScale=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ColorScale(0)=(Color=(B=255,G=230,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=10,G=30,R=120,A=255))
         ColorMultiplierRange=(X=(Min=1.000000,Max=1.000000),Y=(Min=0.450000,Max=0.450000),Z=(Min=0.150000,Max=0.150000))
         MaxParticles=1
         SizeScale(0)=(RelativeSize=0.100000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.000000)
         StartSizeRange=(X=(Min=260.000000,Max=260.000000))
         InitialParticlesPerSecond=100.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'XEffectMat.Shock.shock_ring_b'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.400000,Max=0.400000)
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFTeleportFlash.ArriveRing'

     Begin Object Class=SpriteEmitter Name=ArriveSparks
         UseColorScale=True
         FadeOut=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         Acceleration=(Z=-500.000000)
         ColorScale(0)=(Color=(B=80,G=200,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=10,G=60,R=255,A=255))
         FadeOutStartTime=0.300000
         MaxParticles=40
         RespawnDeadParticles=False
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=0.200000)
         StartSizeRange=(X=(Min=4.000000,Max=7.000000))
         InitialParticlesPerSecond=2000.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'KFX.KFSparkHead'
         TextureUSubdivisions=1
         TextureVSubdivisions=2
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.500000,Max=0.900000)
         StartVelocityRange=(X=(Min=-350.000000,Max=350.000000),Y=(Min=-350.000000,Max=350.000000),Z=(Min=50.000000,Max=380.000000))
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFTeleportFlash.ArriveSparks'

     AutoDestroy=True
     LightType=LT_Steady
     LightHue=12
     LightSaturation=40
     LightBrightness=255.000000
     LightRadius=14.000000
     bDynamicLight=True
     bNoDelete=False
     RemoteRole=ROLE_None
     LifeSpan=1.500000
}
