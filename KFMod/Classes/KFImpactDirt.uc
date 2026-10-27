//=============================================================================
// KFImpactDirt
// A bullet on earth or grass: a fan of dirt out of the ground, a brown kick of dust that falls back, and a haze.
//=============================================================================
class KFImpactDirt extends KFImpactEmitter;

defaultproperties
{
	Counts(0)=1
	Counts(1)=6
	Counts(2)=2
	ImpactSounds(0)=Sound'KFWeaponSound.bullethitdirt'
	ImpactSounds(1)=Sound'KFWeaponSound.bullethitdirt2'
	ImpactSounds(2)=Sound'KFWeaponSound.bullethitdirt3'
	ImpactSounds(3)=Sound'KFWeaponSound.bullethitdirt4'

	Begin Object Class=SpriteEmitter Name=DirtSpray
		UseDirectionAs=PTDU_Up
		UseRotationFrom=PTRS_Actor
		UseColorScale=True
		FadeOut=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseSizeScale=True
		UseRegularSizeScale=False
		ColorScale(0)=(Color=(B=76,G=102,R=125,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=60,G=80,R=98,A=255))
		Opacity=1.000000
		FadeOutStartTime=0.100000
		MaxParticles=2
		StartLocationOffset=(X=12.000000)
		SizeScale(0)=(RelativeSize=0.500000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.000000)
		StartSizeRange=(X=(Min=12.000000,Max=16.000000),Y=(Min=24.000000,Max=32.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'KFMaterials.NewDustSpray'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.400000,Max=0.550000)
		StartVelocityRange=(X=(Min=30.000000,Max=38.000000),Y=(Min=-4.000000,Max=4.000000),Z=(Min=-4.000000,Max=4.000000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFImpactDirt.DirtSpray'

	Begin Object Class=SpriteEmitter Name=DirtKick
		UseRotationFrom=PTRS_Actor
		UseColorScale=True
		FadeOut=True
		FadeIn=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		Acceleration=(Z=-140.000000)
		ColorScale(0)=(Color=(B=112,G=142,R=165,A=255))
		ColorScale(1)=(RelativeTime=0.350000,Color=(B=84,G=104,R=120,A=255))
		ColorScale(2)=(RelativeTime=1.000000,Color=(B=72,G=88,R=100,A=255))
		Opacity=0.850000
		FadeOutStartTime=0.300000
		FadeInEndTime=0.040000
		MaxParticles=12
		SpinsPerSecondRange=(X=(Min=-0.150000,Max=0.150000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=0.250000,RelativeSize=2.800000)
		SizeScale(2)=(RelativeTime=1.000000,RelativeSize=3.600000)
		StartSizeRange=(X=(Min=5.000000,Max=8.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'VMParticleTextures.VehicleExplosions.smoke1tex'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=1.000000,Max=1.600000)
		StartVelocityRange=(X=(Min=120.000000,Max=320.000000),Y=(Min=-90.000000,Max=90.000000),Z=(Min=-90.000000,Max=90.000000))
		VelocityLossRange=(X=(Min=2.000000,Max=3.000000),Y=(Min=2.000000,Max=3.000000),Z=(Min=2.000000,Max=3.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFImpactDirt.DirtKick'

	Begin Object Class=SpriteEmitter Name=DirtHaze
		UseRotationFrom=PTRS_Actor
		UseColorScale=True
		FadeOut=True
		FadeIn=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		Acceleration=(Z=-5.000000)
		ColorScale(0)=(Color=(B=120,G=150,R=170,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=110,G=134,R=150,A=255))
		Opacity=0.350000
		FadeOutStartTime=1.000000
		FadeInEndTime=0.400000
		MaxParticles=4
		StartLocationOffset=(X=8.000000)
		SpinsPerSecondRange=(X=(Min=-0.050000,Max=0.050000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.400000)
		StartSizeRange=(X=(Min=11.000000,Max=15.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'VMParticleTextures.TankFiringP.TankDustKick'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=2.200000,Max=3.000000)
		StartVelocityRange=(X=(Min=15.000000,Max=35.000000),Y=(Min=-12.000000,Max=12.000000),Z=(Min=-12.000000,Max=12.000000))
		VelocityLossRange=(X=(Min=1.000000,Max=1.500000),Y=(Min=1.000000,Max=1.500000),Z=(Min=1.000000,Max=1.500000))
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFImpactDirt.DirtHaze'
}
