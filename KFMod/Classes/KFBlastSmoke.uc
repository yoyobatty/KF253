//=============================================================================
// KFBlastSmoke
// What a blast leaves hanging: a column of dark smoke climbing and spreading, and embers drifting up out of it and
// going out (KFBlast). Up is the world's.
//=============================================================================
class KFBlastSmoke extends KFBlastEmitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx

defaultproperties
{
	Counts(0)=7
	Counts(1)=16
	LifeSpan=8.000000

	Begin Object Class=SpriteEmitter Name=SmokeColumn
		FadeOut=True
		FadeIn=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		Acceleration=(Z=18.000000)
		ColorScale(0)=(Color=(B=52,G=54,R=58,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=70,G=72,R=76,A=255))
		Opacity=0.650000
		FadeOutStartTime=2.500000
		FadeInEndTime=0.300000
		MaxParticles=14
		StartLocationRange=(X=(Min=-30.000000,Max=30.000000),Y=(Min=-30.000000,Max=30.000000),Z=(Min=10.000000,Max=60.000000))
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-0.040000,Max=0.040000))
		SizeScale(0)=(RelativeSize=0.500000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.000000)
		StartSizeRange=(X=(Min=45.000000,Max=65.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Fire.MuchSmoke1'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=4.000000,Max=6.000000)
		StartVelocityRange=(X=(Min=-30.000000,Max=30.000000),Y=(Min=-30.000000,Max=30.000000),Z=(Min=40.000000,Max=90.000000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFBlastSmoke.SmokeColumn'

	Begin Object Class=SpriteEmitter Name=SmokeEmbers
		UseColorScale=True
		UniformSize=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		Acceleration=(Z=-30.000000)
		ColorScale(0)=(Color=(B=120,G=215,R=255))
		ColorScale(1)=(RelativeTime=0.500000,Color=(B=20,G=100,R=235))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=30
		StartLocationRange=(X=(Min=-40.000000,Max=40.000000),Y=(Min=-40.000000,Max=40.000000),Z=(Min=0.000000,Max=50.000000))
		StartSizeRange=(X=(Min=1.000000,Max=2.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'EpicParticles.Flares.HotSpot'
		LifetimeRange=(Min=1.400000,Max=3.000000)
		StartVelocityRange=(X=(Min=-90.000000,Max=90.000000),Y=(Min=-90.000000,Max=90.000000),Z=(Min=60.000000,Max=200.000000))
		VelocityLossRange=(X=(Min=0.400000,Max=0.800000),Y=(Min=0.400000,Max=0.800000),Z=(Min=0.400000,Max=0.800000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFBlastSmoke.SmokeEmbers'
}
