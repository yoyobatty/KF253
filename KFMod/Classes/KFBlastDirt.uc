//=============================================================================
// KFBlastDirt
// A blast's answer from the ground it went off on: a jet of earth, a ring of it rolling out along the surface, grit flung out (KFBlast)
//=============================================================================
class KFBlastDirt extends KFBlastEmitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EmitterTextures.utx

defaultproperties
{
	Counts(0)=10
	Counts(1)=10
	Counts(2)=20

	// a jet of earth thrown off the surface
	Begin Object Class=SpriteEmitter Name=GroundJet
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
		Acceleration=(Z=-60.000000)
		ColorScale(0)=(Color=(B=62,G=78,R=92,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=62,G=78,R=92,A=255))
		Opacity=0.750000
		FadeOutStartTime=0.400000
		FadeInEndTime=0.050000
		MaxParticles=20
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-0.080000,Max=0.080000))
		SizeScale(0)=(RelativeSize=0.400000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.200000)
		StartSizeRange=(X=(Min=34.000000,Max=58.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Fire.MuchSmoke1'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=1.400000,Max=2.400000)
		StartVelocityRange=(X=(Min=300.000000,Max=800.000000),Y=(Min=-260.000000,Max=260.000000),Z=(Min=-260.000000,Max=260.000000))
		VelocityLossRange=(X=(Min=2.500000,Max=3.500000),Y=(Min=2.500000,Max=3.500000),Z=(Min=2.500000,Max=3.500000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFBlastDirt.GroundJet'

	// the ring that rolls out along the surface
	Begin Object Class=SpriteEmitter Name=GroundRing
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
		ColorScale(0)=(Color=(B=62,G=78,R=92,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=62,G=78,R=92,A=255))
		Opacity=0.600000
		FadeOutStartTime=0.350000
		FadeInEndTime=0.050000
		MaxParticles=20
		StartLocationOffset=(X=10.000000)
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-0.050000,Max=0.050000))
		SizeScale(0)=(RelativeSize=0.500000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.600000)
		StartSizeRange=(X=(Min=26.000000,Max=40.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Fire.MuchSmoke1'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=1.200000,Max=2.000000)
		StartVelocityRange=(X=(Min=10.000000,Max=60.000000),Y=(Min=-750.000000,Max=750.000000),Z=(Min=-750.000000,Max=750.000000))
		VelocityLossRange=(X=(Min=3.000000,Max=3.500000),Y=(Min=3.000000,Max=3.500000),Z=(Min=3.000000,Max=3.500000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFBlastDirt.GroundRing'

	// grit and bits flung out
	Begin Object Class=SpriteEmitter Name=GroundGrit
		UseColorScale=True
		SpinParticles=True
		UniformSize=True
		UseRandomSubdivision=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseRotationFrom=PTRS_Actor
		Acceleration=(Z=-900.000000)
		ColorScale(0)=(Color=(B=40,G=52,R=64,A=255))
		ColorScale(1)=(RelativeTime=0.800000,Color=(B=40,G=52,R=64,A=255))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=30
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-2.000000,Max=2.000000))
		StartSizeRange=(X=(Min=1.500000,Max=3.500000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'EmitterTextures.MultiFrame.rockchunks02'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=0.600000,Max=1.200000)
		StartVelocityRange=(X=(Min=350.000000,Max=900.000000),Y=(Min=-420.000000,Max=420.000000),Z=(Min=-420.000000,Max=420.000000))
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFBlastDirt.GroundGrit'

}
