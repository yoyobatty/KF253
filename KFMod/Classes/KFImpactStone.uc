//=============================================================================
// KFImpactStone
// A bullet on concrete, stone, tile, or a surface that says nothing: a fan of dust straight out of it, a burst of
// dust that slows and spreads, a haze that hangs and settles, a few short sparks and a small flash.
//=============================================================================
class KFImpactStone extends KFImpactEmitter;

defaultproperties
{
	Counts(0)=1
	Counts(1)=7
	Counts(2)=2
	Counts(3)=3
	Counts(4)=1
	ImpactSounds(0)=Sound'KFWeaponSound.bullethitroad'
	ImpactSounds(1)=Sound'KFWeaponSound.bullethitroad2'
	ImpactSounds(2)=Sound'KFWeaponSound.bullethitroad3'
	TransientSoundVolume=50.000000

	Begin Object Class=SpriteEmitter Name=StoneSpray
		UseDirectionAs=PTDU_Up
		UseRotationFrom=PTRS_Actor
		UseColorScale=True
		FadeOut=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseSizeScale=True
		UseRegularSizeScale=False
		ColorScale(0)=(Color=(B=130,G=142,R=150,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=96,G=104,R=110,A=255))
		Opacity=1.000000
		FadeOutStartTime=0.100000
		MaxParticles=2
		StartLocationOffset=(X=10.000000)
		SizeScale(0)=(RelativeSize=0.500000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.000000)
		StartSizeRange=(X=(Min=10.000000,Max=14.000000),Y=(Min=20.000000,Max=26.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'KFMaterials.NewDustSpray'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.350000,Max=0.500000)
		StartVelocityRange=(X=(Min=24.000000,Max=30.000000),Y=(Min=-4.000000,Max=4.000000),Z=(Min=-4.000000,Max=4.000000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFImpactStone.StoneSpray'

	Begin Object Class=SpriteEmitter Name=StoneBurst
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
		Acceleration=(Z=-15.000000)
		ColorScale(0)=(Color=(B=132,G=142,R=150,A=255))
		ColorScale(1)=(RelativeTime=0.350000,Color=(B=88,G=95,R=100,A=255))
		ColorScale(2)=(RelativeTime=1.000000,Color=(B=71,G=76,R=80,A=255))
		Opacity=0.850000
		FadeOutStartTime=0.300000
		FadeInEndTime=0.040000
		MaxParticles=12
		SpinsPerSecondRange=(X=(Min=-0.150000,Max=0.150000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=0.250000,RelativeSize=3.000000)
		SizeScale(2)=(RelativeTime=1.000000,RelativeSize=4.000000)
		StartSizeRange=(X=(Min=4.000000,Max=7.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=1.200000,Max=1.800000)
		StartVelocityRange=(X=(Min=90.000000,Max=300.000000),Y=(Min=-90.000000,Max=90.000000),Z=(Min=-90.000000,Max=90.000000))
		VelocityLossRange=(X=(Min=3.500000,Max=5.000000),Y=(Min=3.500000,Max=5.000000),Z=(Min=3.500000,Max=5.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFImpactStone.StoneBurst'

	Begin Object Class=SpriteEmitter Name=StoneHaze
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
		ColorScale(0)=(Color=(B=69,G=74,R=78,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=61,G=65,R=68,A=255))
		Opacity=0.400000
		FadeOutStartTime=1.000000
		FadeInEndTime=0.400000
		MaxParticles=4
		StartLocationOffset=(X=8.000000)
		SpinsPerSecondRange=(X=(Min=-0.050000,Max=0.050000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.500000)
		StartSizeRange=(X=(Min=10.000000,Max=14.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Fire.MuchSmoke1'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=2.400000,Max=3.200000)
		StartVelocityRange=(X=(Min=15.000000,Max=35.000000),Y=(Min=-12.000000,Max=12.000000),Z=(Min=-12.000000,Max=12.000000))
		VelocityLossRange=(X=(Min=1.000000,Max=1.500000),Y=(Min=1.000000,Max=1.500000),Z=(Min=1.000000,Max=1.500000))
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFImpactStone.StoneHaze'

	Begin Object Class=SpriteEmitter Name=StoneSparks
		UseDirectionAs=PTDU_Up
		UseRotationFrom=PTRS_Actor
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		ScaleSizeYByVelocity=True
		Acceleration=(Z=-600.000000)
		ColorScale(0)=(Color=(B=200,G=240,R=255,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=40,G=120,R=255,A=255))
		MaxParticles=6
		StartSizeRange=(X=(Min=1.000000,Max=1.500000),Y=(Min=1.000000,Max=1.500000))
		ScaleSizeByVelocityMultiplier=(Y=0.012000)
		DrawStyle=PTDS_Brighten
		Texture=Texture'KFX.KFSparkHead'
		TextureUSubdivisions=1
		TextureVSubdivisions=2
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.060000,Max=0.140000)
		StartVelocityRange=(X=(Min=300.000000,Max=750.000000),Y=(Min=-350.000000,Max=350.000000),Z=(Min=-350.000000,Max=350.000000))
		DetailMode=DM_High
	End Object
	Emitters(3)=SpriteEmitter'KFMod.KFImpactStone.StoneSparks'

	Begin Object Class=SpriteEmitter Name=StoneFlash
		UseRotationFrom=PTRS_Actor
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		ColorScale(0)=(Color=(B=150,G=190,R=220,A=255))
		ColorScale(1)=(RelativeTime=1.000000)
		MaxParticles=2
		StartLocationOffset=(X=2.000000)
		SizeScale(0)=(RelativeSize=0.600000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.200000)
		StartSizeRange=(X=(Min=5.000000,Max=7.000000))
		Texture=Texture'KFX.MetalHitKF'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.050000,Max=0.070000)
	End Object
	Emitters(4)=SpriteEmitter'KFMod.KFImpactStone.StoneFlash'
}
