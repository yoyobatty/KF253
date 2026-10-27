//=============================================================================
// KFBlastCeiling
// The ceiling over a blast shaken: a curtain of fine dust sifting down, and grit and flakes of plaster that fall, hit
// the floor and bounce (KFBlast.Ceiling).
//=============================================================================
class KFBlastCeiling extends KFBlastEmitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx

defaultproperties
{
	Counts(0)=18
	Counts(1)=22
	Counts(2)=6

	// fine dust sifting down
	Begin Object Class=SpriteEmitter Name=CeilingDust
		FadeOut=True
		FadeIn=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		Acceleration=(Z=-70.000000)
		ColorScale(0)=(Color=(B=150,G=160,R=170,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=135,G=143,R=150,A=255))
		UseColorScale=True
		Opacity=0.650000
		FadeOutStartTime=1.200000
		FadeInEndTime=0.250000
		MaxParticles=24
		StartLocationRange=(X=(Min=-70.000000,Max=70.000000),Y=(Min=-70.000000,Max=70.000000),Z=(Min=-10.000000,Max=0.000000))
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-0.050000,Max=0.050000))
		SizeScale(0)=(RelativeSize=0.500000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.000000)
		StartSizeRange=(X=(Min=40.000000,Max=75.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		UseRandomSubdivision=True
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=2.400000,Max=3.800000)
		StartVelocityRange=(X=(Min=-14.000000,Max=14.000000),Y=(Min=-14.000000,Max=14.000000),Z=(Min=-90.000000,Max=-20.000000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFBlastCeiling.CeilingDust'

	// grit that falls and bounces
	Begin Object Class=SpriteEmitter Name=CeilingGrit
		UseCollision=True
		UseColorScale=True
		SpinParticles=True
		UniformSize=True
		FadeOut=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		Acceleration=(Z=-950.000000)
		DampingFactorRange=(X=(Min=0.300000,Max=0.500000),Y=(Min=0.300000,Max=0.500000),Z=(Min=0.250000,Max=0.400000))
		ColorScale(0)=(Color=(B=70,G=74,R=78,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=60,G=63,R=66,A=255))
		FadeOutStartTime=1.600000
		MaxParticles=30
		StartLocationRange=(X=(Min=-60.000000,Max=60.000000),Y=(Min=-60.000000,Max=60.000000),Z=(Min=-6.000000,Max=0.000000))
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-1.500000,Max=1.500000))
		StartSizeRange=(X=(Min=1.800000,Max=4.200000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		UseRandomSubdivision=True
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=1.800000,Max=2.400000)
		StartVelocityRange=(X=(Min=-50.000000,Max=50.000000),Y=(Min=-50.000000,Max=50.000000),Z=(Min=-80.000000,Max=0.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFBlastCeiling.CeilingGrit'

	// a few bigger flakes
	Begin Object Class=SpriteEmitter Name=CeilingFlakes
		UseCollision=True
		UseColorScale=True
		SpinParticles=True
		UniformSize=True
		FadeOut=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		Acceleration=(Z=-800.000000)
		DampingFactorRange=(X=(Min=0.250000,Max=0.400000),Y=(Min=0.250000,Max=0.400000),Z=(Min=0.200000,Max=0.300000))
		ColorScale(0)=(Color=(B=96,G=101,R=106,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=86,G=90,R=94,A=255))
		FadeOutStartTime=2.000000
		MaxParticles=8
		StartLocationRange=(X=(Min=-50.000000,Max=50.000000),Y=(Min=-50.000000,Max=50.000000))
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-0.800000,Max=0.800000))
		StartSizeRange=(X=(Min=4.000000,Max=7.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		UseRandomSubdivision=True
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=2.200000,Max=2.800000)
		StartVelocityRange=(X=(Min=-40.000000,Max=40.000000),Y=(Min=-40.000000,Max=40.000000),Z=(Min=-40.000000,Max=0.000000))
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFBlastCeiling.CeilingFlakes'

	// a thin stream of sand that keeps running down a moment after
	Begin Object Class=SpriteEmitter Name=CeilingTrickle
		FadeOut=True
		UniformSize=True
		UseColorScale=True
		RespawnDeadParticles=False
		Acceleration=(Z=-500.000000)
		ColorScale(0)=(Color=(B=140,G=150,R=160,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=120,G=128,R=136,A=255))
		Opacity=0.700000
		FadeOutStartTime=0.600000
		MaxParticles=26
		StartLocationRange=(X=(Min=-6.000000,Max=6.000000),Y=(Min=-6.000000,Max=6.000000))
		StartSizeRange=(X=(Min=6.000000,Max=10.000000))
		ParticlesPerSecond=16.000000
		InitialParticlesPerSecond=16.000000
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		UseRandomSubdivision=True
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.800000,Max=1.000000)
		InitialDelayRange=(Min=0.200000,Max=0.500000)
		StartVelocityRange=(Z=(Min=-60.000000,Max=-20.000000))
	End Object
	Emitters(3)=SpriteEmitter'KFMod.KFBlastCeiling.CeilingTrickle'

	LifeSpan=5.000000
}
