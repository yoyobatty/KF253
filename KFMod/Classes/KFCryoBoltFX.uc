//=============================================================================
// KFCryoBoltFX
// The cryo bolt in flight (CryoBolt): a white-blue core with a halo, frost streaming off behind it, ice glints.
//=============================================================================
class KFCryoBoltFX extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=BoltCore
         UseColorScale=True
         UniformSize=True
         ColorScale(0)=(Color=(B=255,G=250,R=235,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=210,R=150,A=255))
         CoordinateSystem=PTCS_Relative
         MaxParticles=3
         StartSizeRange=(X=(Min=18.000000,Max=24.000000))
         ParticlesPerSecond=40.000000
         InitialParticlesPerSecond=40.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.060000,Max=0.080000)
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFCryoBoltFX.BoltCore'

     Begin Object Class=SpriteEmitter Name=BoltFrost
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ColorScale(0)=(Color=(B=255,G=245,R=225,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=230,R=200,A=255))
         Opacity=0.500000
         FadeOutStartTime=0.200000
         FadeInEndTime=0.050000
         MaxParticles=60
         StartLocationRange=(X=(Min=-3.000000,Max=3.000000),Y=(Min=-3.000000,Max=3.000000),Z=(Min=-3.000000,Max=3.000000))
         SpinsPerSecondRange=(X=(Min=-0.300000,Max=0.300000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.500000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.200000)
         StartSizeRange=(X=(Min=10.000000,Max=16.000000))
         ParticlesPerSecond=80.000000
         InitialParticlesPerSecond=80.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         UseRandomSubdivision=True
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.500000,Max=0.700000)
         StartVelocityRange=(X=(Min=-15.000000,Max=15.000000),Y=(Min=-15.000000,Max=15.000000),Z=(Min=-25.000000,Max=5.000000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFCryoBoltFX.BoltFrost'

     Begin Object Class=SpriteEmitter Name=BoltGlints
         UseColorScale=True
         FadeOut=True
         UniformSize=True
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=200,R=140,A=255))
         MaxParticles=30
         StartSizeRange=(X=(Min=1.500000,Max=2.500000))
         ParticlesPerSecond=40.000000
         InitialParticlesPerSecond=40.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.400000,Max=0.700000)
         StartVelocityRange=(X=(Min=-40.000000,Max=40.000000),Y=(Min=-40.000000,Max=40.000000),Z=(Min=-60.000000,Max=10.000000))
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFCryoBoltFX.BoltGlints'

     bNoDelete=False
     bNotOnDedServer=False
     RemoteRole=ROLE_None
}
