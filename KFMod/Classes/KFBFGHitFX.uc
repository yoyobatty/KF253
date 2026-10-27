//=============================================================================
// KFBFGHitFX
// Where one of the BFG's tracers strikes a specimen (KFBFGSpray): a green flash and a spit of green sparks and plasma.
//=============================================================================
class KFBFGHitFX extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=HitFlash
         UseColorScale=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         UniformSize=True
         ColorScale(0)=(Color=(B=200,G=255,R=210,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(G=90,R=10,A=255))
         MaxParticles=1
         StartSizeRange=(X=(Min=90.000000,Max=120.000000))
         InitialParticlesPerSecond=100.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.FlashFlare1'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.180000,Max=0.220000)
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFBFGHitFX.HitFlash'

     Begin Object Class=SpriteEmitter Name=HitSparks
         UseDirectionAs=PTDU_Up
         UseColorScale=True
         ScaleSizeYByVelocity=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         Acceleration=(Z=-700.000000)
         ColorScale(0)=(Color=(B=210,G=255,R=220))
         ColorScale(1)=(RelativeTime=1.000000,Color=(G=100,R=10))
         MaxParticles=18
         StartSizeRange=(X=(Min=1.000000,Max=1.800000),Y=(Min=1.000000,Max=1.800000))
         ScaleSizeByVelocityMultiplier=(Y=0.005000)
         InitialParticlesPerSecond=1000.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'AW-2004Particles.Energy.SparkHead'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.300000,Max=0.600000)
         StartVelocityRange=(X=(Min=-420.000000,Max=420.000000),Y=(Min=-420.000000,Max=420.000000),Z=(Min=-150.000000,Max=500.000000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFBFGHitFX.HitSparks'

     Begin Object Class=SpriteEmitter Name=HitPlasma
         UseColorScale=True
         FadeOut=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         SpinParticles=True
         UniformSize=True
         UseRandomSubdivision=True
         ColorScale(0)=(Color=(B=150,G=255,R=170,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(G=50,R=5,A=255))
         FadeOutStartTime=0.150000
         MaxParticles=5
         StartSpinRange=(X=(Max=1.000000))
         StartSizeRange=(X=(Min=30.000000,Max=50.000000))
         InitialParticlesPerSecond=500.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.300000,Max=0.450000)
         StartVelocityRange=(X=(Min=-80.000000,Max=80.000000),Y=(Min=-80.000000,Max=80.000000),Z=(Min=0.000000,Max=120.000000))
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFBFGHitFX.HitPlasma'

     AutoDestroy=True
     bNoDelete=False
     bNotOnDedServer=False
     RemoteRole=ROLE_None
     LifeSpan=2.000000
}
