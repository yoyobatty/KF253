class KnifeWoodHitEmitter extends KFHitEmitter;

defaultproperties
{
	ImpactSounds(0)=Sound'KFWeaponSound.knife_hit2'
	ImpactSounds(1)=Sound'KFWeaponSound.knife_hit3'
	ImpactSounds(2)=Sound'KFWeaponSound.knife_hit4'
	Begin Object Class=SpriteEmitter Name=SpriteEmitter0
		UseCollision=True
		FadeOut=True
		RespawnDeadParticles=False
		SpinParticles=True
		UniformSize=True
		AutomaticInitialSpawning=False
		UseRandomSubdivision=True
		Acceleration=(Z=-400.000000)
		DampingFactorRange=(X=(Min=0.000000,Max=0.800000),Y=(Min=0.000000,Max=0.800000),Z=(Min=0.000000,Max=0.400000))
		FadeOutStartTime=1.000000
		MaxParticles=5
		DetailMode=DM_High
		StartSpinRange=(X=(Min=1.000000))
		StartSizeRange=(X=(Min=3.000000,Max=1.000000))
		InitialParticlesPerSecond=200.000000
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'KFMaterials.WoodChips'
		TextureUSubdivisions=3
		TextureVSubdivisions=3
		LifetimeRange=(Min=2.000000)
		StartVelocityRange=(X=(Min=100.000000,Max=300.000000),Y=(Min=-50.000000,Max=50.000000),Z=(Min=-50.000000,Max=50.000000))
		MaxAbsVelocity=(Z=400.000000)
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KnifeWoodHitEmitter.SpriteEmitter0'

	Begin Object Class=SpriteEmitter Name=SpriteEmitter1
		FadeOut=True
		FadeIn=True
		RespawnDeadParticles=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		AutomaticInitialSpawning=False
		Acceleration=(Z=10.000000)
		ColorMultiplierRange=(X=(Min=0.800000,Max=0.900000),Y=(Min=0.700000,Max=0.700000),Z=(Min=0.400000,Max=0.500000))
		FadeOutStartTime=0.500000
		FadeInEndTime=0.100000
		MaxParticles=3
		SpinsPerSecondRange=(X=(Min=-0.200000,Max=0.200000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.300000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.000000)
		StartSizeRange=(X=(Min=6.000000,Max=12.000000))
		InitialParticlesPerSecond=5.000000
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'VehicleFX.Particles.DustyCloud2'
		LifetimeRange=(Min=1.000000,Max=1.500000)
		StartVelocityRange=(X=(Min=-8.000000,Max=8.000000),Y=(Min=-8.000000,Max=8.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KnifeWoodHitEmitter.SpriteEmitter1'

}
