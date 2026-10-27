//=============================================================================
// KFBFGBallFX
// The BFG's ball in flight (BFGBall): a blinding green core, plasma boiling off it and trailing behind, sparks, a halo
// and arcs crackling off it.
//=============================================================================
class KFBFGBallFX extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=BallCore
         UseColorScale=True
         UniformSize=True
         ColorScale(0)=(Color=(B=210,G=255,R=220,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=60,G=255,R=90,A=255))
         CoordinateSystem=PTCS_Relative
         MaxParticles=4
         StartSizeRange=(X=(Min=70.000000,Max=90.000000))
         ParticlesPerSecond=40.000000
         InitialParticlesPerSecond=40.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.080000,Max=0.100000)
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFBFGBallFX.BallCore'

     Begin Object Class=SpriteEmitter Name=BallPlasma
         UseColorScale=True
         FadeOut=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         UseRandomSubdivision=True
         ColorScale(0)=(Color=(B=160,G=255,R=180,A=255))
         ColorScale(1)=(RelativeTime=0.400000,Color=(B=40,G=230,R=70,A=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=5,G=60,R=10,A=255))
         FadeOutStartTime=0.150000
         MaxParticles=40
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Min=10.000000,Max=30.000000)
         SpinsPerSecondRange=(X=(Min=-1.000000,Max=1.000000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=0.300000)
         StartSizeRange=(X=(Min=40.000000,Max=70.000000))
         ParticlesPerSecond=90.000000
         InitialParticlesPerSecond=90.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.300000,Max=0.450000)
         StartVelocityRange=(X=(Min=-60.000000,Max=60.000000),Y=(Min=-60.000000,Max=60.000000),Z=(Min=-60.000000,Max=60.000000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFBFGBallFX.BallPlasma'

     Begin Object Class=SpriteEmitter Name=BallSparks
         UseDirectionAs=PTDU_Up
         UseColorScale=True
         ScaleSizeYByVelocity=True
         ColorScale(0)=(Color=(B=200,G=255,R=210))
         ColorScale(1)=(RelativeTime=1.000000,Color=(G=120,R=20))
         MaxParticles=40
         StartSizeRange=(X=(Min=1.200000,Max=2.200000),Y=(Min=1.200000,Max=2.200000))
         ScaleSizeByVelocityMultiplier=(Y=0.006000)
         ParticlesPerSecond=70.000000
         InitialParticlesPerSecond=70.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'AW-2004Particles.Energy.SparkHead'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.200000,Max=0.400000)
         StartVelocityRange=(X=(Min=-450.000000,Max=450.000000),Y=(Min=-450.000000,Max=450.000000),Z=(Min=-450.000000,Max=450.000000))
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFBFGBallFX.BallSparks'

     Begin Object Class=SpriteEmitter Name=BallHalo
         UseColorScale=True
         UniformSize=True
         ColorScale(0)=(Color=(B=30,G=160,R=40,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=30,G=160,R=40,A=255))
         CoordinateSystem=PTCS_Relative
         MaxParticles=2
         StartSizeRange=(X=(Min=170.000000,Max=200.000000))
         ParticlesPerSecond=20.000000
         InitialParticlesPerSecond=20.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.100000,Max=0.100000)
     End Object
     Emitters(3)=SpriteEmitter'KFMod.KFBFGBallFX.BallHalo'

     Begin Object Class=BeamEmitter Name=BallArcs
         BeamDistanceRange=(Min=50.000000,Max=140.000000)
         DetermineEndPointBy=PTEP_Distance
         LowFrequencyNoiseRange=(X=(Min=-20.000000,Max=20.000000),Y=(Min=-20.000000,Max=20.000000),Z=(Min=-20.000000,Max=20.000000))
         HighFrequencyNoiseRange=(X=(Min=-6.000000,Max=6.000000),Y=(Min=-6.000000,Max=6.000000),Z=(Min=-6.000000,Max=6.000000))
         FadeOut=True
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
         ColorMultiplierRange=(X=(Min=0.450000,Max=0.600000),Y=(Min=1.000000,Max=1.000000),Z=(Min=0.450000,Max=0.600000))
         FadeOutStartTime=0.030000
         CoordinateSystem=PTCS_Relative
         MaxParticles=10
         StartSizeRange=(X=(Min=5.000000,Max=9.000000),Y=(Min=5.000000,Max=9.000000),Z=(Min=5.000000,Max=9.000000))
         ParticlesPerSecond=45.000000
         InitialParticlesPerSecond=45.000000
         Texture=Texture'EpicParticles.Beams.HotBolt04aw'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.060000,Max=0.120000)
         StartVelocityRange=(X=(Min=-1.000000,Max=1.000000),Y=(Min=-1.000000,Max=1.000000),Z=(Min=-1.000000,Max=1.000000))
     End Object
     Emitters(4)=BeamEmitter'KFMod.KFBFGBallFX.BallArcs'

     bNoDelete=False
     bNotOnDedServer=False
     RemoteRole=ROLE_None
}
