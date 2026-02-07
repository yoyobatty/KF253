class MetalImpactEmitterLight extends KFHitEmitter;
         #exec OBJ LOAD FILE=PatchSounds.uax

defaultproperties
{
	ImpactSounds(0)=Sound'PatchSounds.MetalImpact4'
	ImpactSounds(1)=Sound'PatchSounds.MetalImpact5'
	ImpactSounds(2)=Sound'PatchSounds.MetalImpact6'
	Begin Object Class=SpriteEmitter Name=SpriteEmitter0
		UseDirectionAs=PTDU_Up
		UseCollision=True
		UseColorScale=True
		RespawnDeadParticles=False
		UseSizeScale=True
		UseRegularSizeScale=False
		ScaleSizeYByVelocity=True
		AutomaticInitialSpawning=False
		BlendBetweenSubdivisions=True
		UseRandomSubdivision=True
		Acceleration=(Z=-700.000000)
		DampingFactorRange=(X=(Min=0.200000),Y=(Min=0.200000),Z=(Min=0.200000,Max=0.500000))
		ColorScale(0)=(Color=(B=200,G=255,R=255))
		ColorScale(1)=(RelativeTime=0.200000,Color=(B=190,G=220,R=242))
		ColorScale(2)=(RelativeTime=0.400000,Color=(B=90,G=91,R=90))
		ColorScale(3)=(RelativeTime=1.000000,Color=(G=40,R=102))
		DetailMode=DM_High
		SizeScale(2)=(RelativeTime=0.070000,RelativeSize=1.000000)
		SizeScale(3)=(RelativeTime=1.000000,RelativeSize=1.000000)
		StartSizeRange=(X=(Min=3.000000,Max=5.000000),Y=(Min=2.000000,Max=4.000000),Z=(Min=2.000000,Max=2.000000))
		ScaleSizeByVelocityMultiplier=(Y=0.020000)
		InitialParticlesPerSecond=100.000000
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Energy.SparkHead'
		TextureUSubdivisions=2
		TextureVSubdivisions=2
		LifetimeRange=(Min=0.600000,Max=0.900000)
		StartVelocityRange=(X=(Min=200.000000,Max=300.000000),Y=(Min=-70.000000,Max=70.000000),Z=(Min=-70.000000,Max=70.000000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.MetalImpactEmitterLight.SpriteEmitter0'

	Begin Object Class=SpriteEmitter Name=SpriteEmitter1
		FadeOut=True
		FadeIn=True
		RespawnDeadParticles=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		AutomaticInitialSpawning=False
		UseRandomSubdivision=True
		Acceleration=(Z=10.000000)
		ColorMultiplierRange=(X=(Min=0.250000,Max=0.350000),Y=(Min=0.250000,Max=0.300000),Z=(Min=0.200000,Max=0.250000))
		FadeOutStartTime=0.500000
		FadeInEndTime=0.100000
		MaxParticles=0
		SpinsPerSecondRange=(X=(Min=-0.200000,Max=0.200000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.300000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.000000)
		StartSizeRange=(X=(Min=5.000000,Max=10.000000))
		InitialParticlesPerSecond=5.000000
		DrawStyle=PTDS_Brighten
		Texture=Texture'XEffects.EmitSmoke_t'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=1.000000,Max=1.500000)
		StartVelocityRange=(X=(Min=-8.000000,Max=8.000000),Y=(Min=-8.000000,Max=8.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.MetalImpactEmitterLight.SpriteEmitter1'

	Begin Object Class=SpriteEmitter Name=SpriteEmitter2
		RespawnDeadParticles=False
		UniformSize=True
		AutomaticInitialSpawning=False
		ColorMultiplierRange=(X=(Min=0.700000,Max=0.900000),Y=(Min=0.700000,Max=0.800000),Z=(Min=0.500000,Max=0.600000))
		MaxParticles=0
		SpinsPerSecondRange=(X=(Min=-0.200000,Max=0.200000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeTime=1.000000,RelativeSize=1.000000)
		StartSizeRange=(X=(Min=6.000000,Max=6.000000))
		InitialParticlesPerSecond=5.000000
		DrawStyle=PTDS_Brighten
		Texture=Texture'KFX.MetalHitKF'
		LifetimeRange=(Min=0.100000,Max=0.100000)
	End Object
	Emitters(2)=SpriteEmitter'KFMod.MetalImpactEmitterLight.SpriteEmitter2'

}
