//=============================================================================
// KFImpactSnow
// A bullet on snow or ice: a fan and a burst of white powder, and a haze.
//=============================================================================
class KFImpactSnow extends KFImpactEmitter;

defaultproperties
{
	Counts(0)=1
	Counts(1)=6
	Counts(2)=2
	ImpactSounds(0)=Sound'KFWeaponSound.bullethitdirt'
	ImpactSounds(1)=Sound'KFWeaponSound.bullethitdirt2'
	ImpactSounds(2)=Sound'KFWeaponSound.bullethitdirt3'
	ImpactSounds(3)=Sound'KFWeaponSound.bullethitdirt4'

	Begin Object Class=SpriteEmitter Name=SnowSpray
		UseDirectionAs=PTDU_Up
		UseRotationFrom=PTRS_Actor
		UseColorScale=True
		FadeOut=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseSizeScale=True
		UseRegularSizeScale=False
		ColorScale(0)=(Color=(B=212,G=205,R=200,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=182,G=175,R=170,A=255))
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
	Emitters(0)=SpriteEmitter'KFMod.KFImpactSnow.SnowSpray'

	Begin Object Class=SpriteEmitter Name=SnowBurst
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
		Acceleration=(Z=-60.000000)
		ColorScale(0)=(Color=(B=228,G=220,R=215,A=255))
		ColorScale(1)=(RelativeTime=0.350000,Color=(B=188,G=180,R=175,A=255))
		ColorScale(2)=(RelativeTime=1.000000,Color=(B=168,G=160,R=155,A=255))
		Opacity=0.850000
		FadeOutStartTime=0.300000
		FadeInEndTime=0.040000
		MaxParticles=12
		SpinsPerSecondRange=(X=(Min=-0.150000,Max=0.150000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=0.250000,RelativeSize=2.900000)
		SizeScale(2)=(RelativeTime=1.000000,RelativeSize=3.800000)
		StartSizeRange=(X=(Min=4.000000,Max=7.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Fire.MuchSmoke1'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=1.000000,Max=1.600000)
		StartVelocityRange=(X=(Min=90.000000,Max=280.000000),Y=(Min=-90.000000,Max=90.000000),Z=(Min=-90.000000,Max=90.000000))
		VelocityLossRange=(X=(Min=3.000000,Max=4.500000),Y=(Min=3.000000,Max=4.500000),Z=(Min=3.000000,Max=4.500000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFImpactSnow.SnowBurst'

	Begin Object Class=SpriteEmitter Name=SnowHaze
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
		Acceleration=(Z=-8.000000)
		ColorScale(0)=(Color=(B=163,G=155,R=150,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=150,G=142,R=138,A=255))
		Opacity=0.400000
		FadeOutStartTime=1.000000
		FadeInEndTime=0.400000
		MaxParticles=4
		StartLocationOffset=(X=8.000000)
		SpinsPerSecondRange=(X=(Min=-0.050000,Max=0.050000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.400000)
		StartSizeRange=(X=(Min=10.000000,Max=14.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Fire.MuchSmoke1'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=2.200000,Max=3.000000)
		StartVelocityRange=(X=(Min=15.000000,Max=35.000000),Y=(Min=-12.000000,Max=12.000000),Z=(Min=-12.000000,Max=12.000000))
		VelocityLossRange=(X=(Min=1.000000,Max=1.500000),Y=(Min=1.000000,Max=1.500000),Z=(Min=1.000000,Max=1.500000))
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFImpactSnow.SnowHaze'
}
