//=============================================================================
// KFIceShatter
// A frozen specimen breaking like glass when it is killed (KFMonster.GibBody while frozen): a burst of ice shards
// that bounce and skitter, a puff of frost, glints, and the crash of breaking ice.
//=============================================================================
class KFIceShatter extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx
#exec OBJ LOAD FILE=KFMaterials.utx
#exec OBJ LOAD FILE=PatchSounds.uax

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	PlaySound(Sound'PatchSounds.GlassImpact1', SLOT_None, 2.5,, 1200, 0.8 + 0.2 * FRand());
	PlaySound(Sound'PatchSounds.GlassImpact3', SLOT_None, 2.0,, 1000, 0.6 + 0.2 * FRand());
}

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=IceShards
         UseCollision=True
         UseColorScale=True
         FadeOut=True
         RespawnDeadParticles=False
         SpinParticles=True
         UniformSize=True
         AutomaticInitialSpawning=False
         UseRandomSubdivision=True
         Acceleration=(Z=-800.000000)
         DampingFactorRange=(X=(Min=0.200000,Max=0.600000),Y=(Min=0.200000,Max=0.600000),Z=(Min=0.150000,Max=0.350000))
         ColorScale(0)=(Color=(B=255,G=240,R=215,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=220,R=180,A=255))
         FadeOutStartTime=2.000000
         MaxParticles=70
         StartLocationRange=(X=(Min=-15.000000,Max=15.000000),Y=(Min=-15.000000,Max=15.000000),Z=(Min=-35.000000,Max=35.000000))
         SpinsPerSecondRange=(X=(Min=-2.500000,Max=2.500000))
         StartSpinRange=(X=(Max=1.000000))
         StartSizeRange=(X=(Min=3.000000,Max=8.000000))
         InitialParticlesPerSecond=3000.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'KFMaterials.GlassChips'
         TextureUSubdivisions=3
         TextureVSubdivisions=3
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=2.500000,Max=3.200000)
         StartVelocityRange=(X=(Min=-380.000000,Max=380.000000),Y=(Min=-380.000000,Max=380.000000),Z=(Min=40.000000,Max=420.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFIceShatter.IceShards'

     Begin Object Class=SpriteEmitter Name=IcePuff
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         Acceleration=(Z=-15.000000)
         ColorScale(0)=(Color=(B=255,G=248,R=235,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=240,R=220,A=255))
         Opacity=0.650000
         FadeOutStartTime=0.700000
         FadeInEndTime=0.060000
         MaxParticles=10
         StartLocationRange=(X=(Min=-20.000000,Max=20.000000),Y=(Min=-20.000000,Max=20.000000),Z=(Min=-30.000000,Max=30.000000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.500000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.800000)
         StartSizeRange=(X=(Min=40.000000,Max=70.000000))
         InitialParticlesPerSecond=1000.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         UseRandomSubdivision=True
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=1.400000,Max=2.000000)
         StartVelocityRange=(X=(Min=-120.000000,Max=120.000000),Y=(Min=-120.000000,Max=120.000000),Z=(Min=-20.000000,Max=80.000000))
         VelocityLossRange=(X=(Min=1.500000,Max=2.000000),Y=(Min=1.500000,Max=2.000000),Z=(Min=1.500000,Max=2.000000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFIceShatter.IcePuff'

     Begin Object Class=SpriteEmitter Name=IceGlints
         UseColorScale=True
         FadeOut=True
         UniformSize=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         Acceleration=(Z=-200.000000)
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=200,R=150,A=255))
         FadeOutStartTime=0.400000
         MaxParticles=30
         StartLocationRange=(X=(Min=-25.000000,Max=25.000000),Y=(Min=-25.000000,Max=25.000000),Z=(Min=-40.000000,Max=40.000000))
         StartSizeRange=(X=(Min=1.500000,Max=3.000000))
         InitialParticlesPerSecond=2000.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.600000,Max=1.200000)
         StartVelocityRange=(X=(Min=-200.000000,Max=200.000000),Y=(Min=-200.000000,Max=200.000000),Z=(Min=0.000000,Max=250.000000))
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFIceShatter.IceGlints'

     AutoDestroy=True
     bNoDelete=False
     bNotOnDedServer=False
     RemoteRole=ROLE_None
     LifeSpan=5.000000
}
