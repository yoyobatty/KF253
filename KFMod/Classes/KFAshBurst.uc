//=============================================================================
// KFAshBurst
// A burnt-through body crumbling under a blow (KFMonster.AshCrumble): a dark cloud of ash, embers swirling up out of it,
// flakes of ash drifting down, a puff of fine dust along the floor.
//=============================================================================
class KFAshBurst extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx

defaultproperties
{
	Begin Object Class=SpriteEmitter Name=AshCloud
		FadeOut=True
		FadeIn=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		Acceleration=(Z=12.000000)
		ColorScale(0)=(Color=(B=52,G=54,R=58,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=62,G=63,R=66,A=255))
		Opacity=0.800000
		FadeOutStartTime=1.200000
		FadeInEndTime=0.100000
		MaxParticles=10
		StartLocationRange=(X=(Min=-30.000000,Max=30.000000),Y=(Min=-30.000000,Max=30.000000),Z=(Min=0.000000,Max=40.000000))
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-0.060000,Max=0.060000))
		SizeScale(0)=(RelativeSize=0.500000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.300000)
		StartSizeRange=(X=(Min=40.000000,Max=70.000000))
		InitialParticlesPerSecond=1000.000000
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		UseRandomSubdivision=True
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=2.400000,Max=3.400000)
		StartVelocityRange=(X=(Min=-70.000000,Max=70.000000),Y=(Min=-70.000000,Max=70.000000),Z=(Min=10.000000,Max=70.000000))
		VelocityLossRange=(X=(Min=0.800000,Max=1.200000),Y=(Min=0.800000,Max=1.200000),Z=(Min=0.800000,Max=1.200000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFAshBurst.AshCloud'

	Begin Object Class=SpriteEmitter Name=AshEmbers
		UseColorScale=True
		FadeOut=True
		UniformSize=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		Acceleration=(Z=30.000000)
		ColorScale(0)=(Color=(B=110,G=210,R=255,A=255))
		ColorScale(1)=(RelativeTime=0.500000,Color=(B=20,G=110,R=255,A=255))
		ColorScale(2)=(RelativeTime=1.000000,Color=(R=60,A=255))
		FadeOutStartTime=1.000000
		MaxParticles=55
		StartLocationRange=(X=(Min=-25.000000,Max=25.000000),Y=(Min=-25.000000,Max=25.000000),Z=(Min=0.000000,Max=30.000000))
		StartSizeRange=(X=(Min=1.800000,Max=3.200000))
		InitialParticlesPerSecond=1000.000000
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Energy.SparkHead'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=1.200000,Max=2.600000)
		StartVelocityRange=(X=(Min=-140.000000,Max=140.000000),Y=(Min=-140.000000,Max=140.000000),Z=(Min=40.000000,Max=220.000000))
		VelocityLossRange=(X=(Min=0.600000,Max=1.000000),Y=(Min=0.600000,Max=1.000000),Z=(Min=0.600000,Max=1.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFAshBurst.AshEmbers'

	Begin Object Class=SpriteEmitter Name=AshFlakes
		UseColorScale=True
		FadeOut=True
		SpinParticles=True
		UniformSize=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		Acceleration=(Z=-110.000000)
		ColorScale(0)=(Color=(B=24,G=25,R=27,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=34,G=35,R=36,A=255))
		FadeOutStartTime=2.200000
		MaxParticles=40
		StartLocationRange=(X=(Min=-25.000000,Max=25.000000),Y=(Min=-25.000000,Max=25.000000),Z=(Min=0.000000,Max=40.000000))
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-1.000000,Max=1.000000))
		StartSizeRange=(X=(Min=2.500000,Max=5.000000))
		InitialParticlesPerSecond=1000.000000
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		UseRandomSubdivision=True
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=2.400000,Max=3.600000)
		StartVelocityRange=(X=(Min=-110.000000,Max=110.000000),Y=(Min=-110.000000,Max=110.000000),Z=(Min=60.000000,Max=200.000000))
		VelocityLossRange=(X=(Min=0.800000,Max=1.200000),Y=(Min=0.800000,Max=1.200000),Z=(Min=0.400000,Max=0.600000))
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFAshBurst.AshFlakes'

	Begin Object Class=SpriteEmitter Name=AshFloor
		FadeOut=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		ColorScale(0)=(Color=(B=40,G=42,R=46,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=40,G=42,R=46,A=255))
		Opacity=0.500000
		FadeOutStartTime=0.400000
		MaxParticles=8
		StartLocationOffset=(Z=-20.000000)
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.600000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.000000)
		StartSizeRange=(X=(Min=40.000000,Max=60.000000))
		InitialParticlesPerSecond=1000.000000
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		UseRandomSubdivision=True
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=1.000000,Max=1.400000)
		StartVelocityRange=(X=(Min=-220.000000,Max=220.000000),Y=(Min=-220.000000,Max=220.000000),Z=(Min=0.000000,Max=20.000000))
		VelocityLossRange=(X=(Min=2.000000,Max=2.500000),Y=(Min=2.000000,Max=2.500000))
	End Object
	Emitters(3)=SpriteEmitter'KFMod.KFAshBurst.AshFloor'

	AutoDestroy=True
	bNoDelete=False
	bNotOnDedServer=False
	RemoteRole=ROLE_None
	LifeSpan=6.000000
}
