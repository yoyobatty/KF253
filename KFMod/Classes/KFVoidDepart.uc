//=============================================================================
// KFVoidDepart
// Where the Void Executioner's wielder blinked away from (KFVoidArrival): a violet wisp folding in on itself and a puff
// of violet sparks.
//=============================================================================
class KFVoidDepart extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=DepartFold
         FadeOut=True
         FadeIn=True
         FadeInEndTime=0.050000
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         UniformSize=True
         ColorMultiplierRange=(X=(Min=0.700000,Max=0.900000),Y=(Min=0.300000,Max=0.500000),Z=(Min=1.000000,Max=1.000000))
         MaxParticles=30
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Min=40.000000,Max=60.000000)
         StartSizeRange=(X=(Min=8.000000,Max=16.000000))
         InitialParticlesPerSecond=1000.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.250000,Max=0.350000)
         StartVelocityRadialRange=(Min=-220.000000,Max=-160.000000)
         GetVelocityDirectionFrom=PTVD_AddRadial
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFVoidDepart.DepartFold'

     Begin Object Class=SpriteEmitter Name=DepartFlash
         FadeOut=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         UniformSize=True
         ColorMultiplierRange=(X=(Min=0.850000,Max=0.850000),Y=(Min=0.500000,Max=0.500000),Z=(Min=1.000000,Max=1.000000))
         MaxParticles=1
         StartSizeRange=(X=(Min=140.000000,Max=160.000000))
         InitialParticlesPerSecond=100.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.FlashFlare1'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.180000,Max=0.180000)
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFVoidDepart.DepartFlash'

     bNoDelete=False
     RemoteRole=ROLE_None
     LifeSpan=2.000000
}
