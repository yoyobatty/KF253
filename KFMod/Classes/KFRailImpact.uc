//=============================================================================
// KFRailImpact
// Where the railgun's slug stopped in a wall (KFRailBeam): a blue-white flash and a spray of hot sparks off it.
//=============================================================================
class KFRailImpact extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=RailFlash
         UseColorScale=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         UniformSize=True
         ColorScale(0)=(Color=(B=255,G=240,R=220,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=120,G=40,R=10,A=255))
         MaxParticles=2
         StartSizeRange=(X=(Min=70.000000,Max=90.000000))
         InitialParticlesPerSecond=200.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.FlashFlare1'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.150000,Max=0.200000)
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFRailImpact.RailFlash'

     Begin Object Class=SpriteEmitter Name=RailSparks
         UseDirectionAs=PTDU_Up
         UseRotationFrom=PTRS_Actor
         UseCollision=True
         UseColorScale=True
         ScaleSizeYByVelocity=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         Acceleration=(Z=-900.000000)
         DampingFactorRange=(X=(Min=0.300000,Max=0.500000),Y=(Min=0.300000,Max=0.500000),Z=(Min=0.300000,Max=0.500000))
         ColorScale(0)=(Color=(B=255,G=245,R=230))
         ColorScale(1)=(RelativeTime=0.400000,Color=(B=255,G=180,R=110))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=90,G=30,R=10))
         MaxParticles=30
         StartSizeRange=(X=(Min=1.000000,Max=1.800000),Y=(Min=1.000000,Max=1.800000))
         ScaleSizeByVelocityMultiplier=(Y=0.006000)
         InitialParticlesPerSecond=2000.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'AW-2004Particles.Energy.SparkHead'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.400000,Max=0.900000)
         StartVelocityRange=(X=(Min=150.000000,Max=600.000000),Y=(Min=-400.000000,Max=400.000000),Z=(Min=-400.000000,Max=400.000000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFRailImpact.RailSparks'

     AutoDestroy=True
     bNoDelete=False
     bNotOnDedServer=False
     RemoteRole=ROLE_None
     LifeSpan=2.000000
}
