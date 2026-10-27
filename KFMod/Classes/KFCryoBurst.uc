//=============================================================================
// KFCryoBurst
// Where a cryo bolt bursts (CryoBolt): a white-blue flash, a cloud of freezing vapour rolling out and sinking, shards
// of ice flung off, glints, a frost ring, a hiss and a crack.
//=============================================================================
class KFCryoBurst extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx
#exec OBJ LOAD FILE=..\Textures\XEffectMat.utx
#exec OBJ LOAD FILE=KFMaterials.utx
#exec OBJ LOAD FILE=PatchSounds.uax
#exec OBJ LOAD FILE=..\Sounds\GeneralAmbience.uax

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	PlaySound(Sound'GeneralAmbience.steamfx2', SLOT_None, 2.0,, 1200, 0.8);
	PlaySound(Sound'PatchSounds.GlassImpact2', SLOT_None, 1.6,, 900, 0.75);
}

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=BurstFlash
         UseColorScale=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         UniformSize=True
         ColorScale(0)=(Color=(B=255,G=250,R=240,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=150,G=90,R=40,A=255))
         MaxParticles=1
         StartSizeRange=(X=(Min=180.000000,Max=200.000000))
         InitialParticlesPerSecond=100.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.200000,Max=0.250000)
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFCryoBurst.BurstFlash'

     Begin Object Class=SpriteEmitter Name=BurstCloud
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         Acceleration=(Z=-25.000000)
         ColorScale(0)=(Color=(B=255,G=248,R=232,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=236,R=214,A=255))
         Opacity=0.750000
         FadeOutStartTime=1.000000
         FadeInEndTime=0.080000
         MaxParticles=22
         StartLocationRange=(X=(Min=-20.000000,Max=20.000000),Y=(Min=-20.000000,Max=20.000000),Z=(Min=-10.000000,Max=30.000000))
         SpinsPerSecondRange=(X=(Min=-0.100000,Max=0.100000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.500000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.000000)
         StartSizeRange=(X=(Min=60.000000,Max=95.000000))
         InitialParticlesPerSecond=1000.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         UseRandomSubdivision=True
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=1.800000,Max=2.600000)
         StartVelocityRange=(X=(Min=-280.000000,Max=280.000000),Y=(Min=-280.000000,Max=280.000000),Z=(Min=-40.000000,Max=120.000000))
         VelocityLossRange=(X=(Min=1.800000,Max=2.400000),Y=(Min=1.800000,Max=2.400000),Z=(Min=1.800000,Max=2.400000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFCryoBurst.BurstCloud'

     Begin Object Class=SpriteEmitter Name=BurstShards
         UseCollision=True
         UseColorScale=True
         FadeOut=True
         RespawnDeadParticles=False
         SpinParticles=True
         UniformSize=True
         AutomaticInitialSpawning=False
         UseRandomSubdivision=True
         Acceleration=(Z=-700.000000)
         DampingFactorRange=(X=(Min=0.200000,Max=0.600000),Y=(Min=0.200000,Max=0.600000),Z=(Min=0.200000,Max=0.400000))
         ColorScale(0)=(Color=(B=255,G=245,R=225,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=225,R=190,A=255))
         FadeOutStartTime=1.200000
         MaxParticles=30
         SpinsPerSecondRange=(X=(Min=-2.000000,Max=2.000000))
         StartSpinRange=(X=(Max=1.000000))
         StartSizeRange=(X=(Min=2.500000,Max=5.000000))
         InitialParticlesPerSecond=1000.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'KFMaterials.GlassChips'
         TextureUSubdivisions=3
         TextureVSubdivisions=3
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=1.400000,Max=2.000000)
         StartVelocityRange=(X=(Min=-350.000000,Max=350.000000),Y=(Min=-350.000000,Max=350.000000),Z=(Min=50.000000,Max=400.000000))
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFCryoBurst.BurstShards'

     Begin Object Class=SpriteEmitter Name=BurstGlints
         UseColorScale=True
         FadeOut=True
         UniformSize=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         Acceleration=(Z=-60.000000)
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=210,R=150,A=255))
         FadeOutStartTime=0.600000
         MaxParticles=40
         StartLocationRange=(X=(Min=-60.000000,Max=60.000000),Y=(Min=-60.000000,Max=60.000000),Z=(Min=-10.000000,Max=70.000000))
         StartSizeRange=(X=(Min=1.500000,Max=3.000000))
         InitialParticlesPerSecond=1000.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.900000,Max=1.600000)
         StartVelocityRange=(X=(Min=-60.000000,Max=60.000000),Y=(Min=-60.000000,Max=60.000000),Z=(Min=-20.000000,Max=40.000000))
     End Object
     Emitters(3)=SpriteEmitter'KFMod.KFCryoBurst.BurstGlints'

     Begin Object Class=SpriteEmitter Name=BurstRing
         UseDirectionAs=PTDU_Normal
         UseColorScale=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ColorScale(0)=(Color=(B=255,G=240,R=220,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=90,G=60,R=30,A=255))
         ColorMultiplierRange=(X=(Min=0.250000,Max=0.250000),Y=(Min=0.750000,Max=0.750000),Z=(Min=1.000000,Max=1.000000))
         MaxParticles=1
         SizeScale(0)=(RelativeSize=0.200000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.000000)
         StartSizeRange=(X=(Min=420.000000,Max=420.000000))
         InitialParticlesPerSecond=100.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'XEffectMat.Shock.shock_ring_b'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.450000,Max=0.450000)
     End Object
     Emitters(4)=SpriteEmitter'KFMod.KFCryoBurst.BurstRing'

     LightType=LT_Steady
     LightHue=150
     LightSaturation=100
     LightBrightness=180.000000
     LightRadius=14.000000
     bDynamicLight=True
     AutoDestroy=True
     bNoDelete=False
     bNotOnDedServer=False
     RemoteRole=ROLE_None
     LifeSpan=4.000000
}
