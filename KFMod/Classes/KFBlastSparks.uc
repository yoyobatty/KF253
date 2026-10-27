//=============================================================================
// KFBlastSparks
// A blast's answer from metal: a shower of sparks that fall and cool, a hot flash, a little smoke (KFBlast)
//=============================================================================
class KFBlastSparks extends KFBlastEmitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx

defaultproperties
{
	Counts(0)=36
	Counts(1)=1
	Counts(2)=5

	Begin Object Class=SpriteEmitter Name=MetalSparks
		UseDirectionAs=PTDU_Up
		UseColorScale=True
		ScaleSizeYByVelocity=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseRotationFrom=PTRS_Actor
		Acceleration=(Z=-950.000000)
		ColorScale(0)=(Color=(B=220,G=250,R=255))
		ColorScale(1)=(RelativeTime=0.350000,Color=(B=60,G=190,R=255))
		ColorScale(2)=(RelativeTime=0.800000,Color=(B=10,G=60,R=200))
		ColorScale(3)=(RelativeTime=1.000000)
		MaxParticles=60
		StartSizeRange=(X=(Min=0.800000,Max=1.400000),Y=(Min=0.800000,Max=1.400000))
		ScaleSizeByVelocityMultiplier=(Y=0.004000)
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Energy.SparkHead'
		LifetimeRange=(Min=0.500000,Max=1.300000)
		StartVelocityRange=(X=(Min=400.000000,Max=1300.000000),Y=(Min=-700.000000,Max=700.000000),Z=(Min=-700.000000,Max=700.000000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFBlastSparks.MetalSparks'

	Begin Object Class=SpriteEmitter Name=MetalFlash
		UseColorScale=True
		UniformSize=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseRotationFrom=PTRS_Actor
		ColorScale(0)=(Color=(B=200,G=240,R=255))
		ColorScale(1)=(RelativeTime=1.000000)
		MaxParticles=2
		StartLocationOffset=(X=8.000000)
		StartSizeRange=(X=(Min=90.000000,Max=110.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'EpicParticles.Flares.FlashFlare1'
		LifetimeRange=(Min=0.150000,Max=0.150000)
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFBlastSparks.MetalFlash'

	Begin Object Class=SpriteEmitter Name=MetalSmoke
		FadeOut=True
		FadeIn=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseRotationFrom=PTRS_Actor
		ColorScale(0)=(Color=(B=95,G=98,R=100,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=95,G=98,R=100,A=255))
		Opacity=0.500000
		FadeOutStartTime=0.400000
		FadeInEndTime=0.050000
		MaxParticles=8
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.500000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.000000)
		StartSizeRange=(X=(Min=26.000000,Max=40.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Fire.MuchSmoke1'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=1.200000,Max=1.800000)
		StartVelocityRange=(X=(Min=150.000000,Max=400.000000),Y=(Min=-150.000000,Max=150.000000),Z=(Min=-150.000000,Max=150.000000))
		VelocityLossRange=(X=(Min=2.500000,Max=3.000000),Y=(Min=2.500000,Max=3.000000),Z=(Min=2.500000,Max=3.000000))
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFBlastSparks.MetalSmoke'
}
