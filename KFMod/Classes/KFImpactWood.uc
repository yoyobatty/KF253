//=============================================================================
// KFImpactWood
// A bullet on wood: a fan and a burst of sawdust that falls away, and a little haze.
//=============================================================================
class KFImpactWood extends KFImpactEmitter;

defaultproperties
{
	Counts(0)=1
	Counts(1)=5
	Counts(2)=1
	ImpactSounds(0)=Sound'KFWeaponSound.bullethitwood'
	ImpactSounds(1)=Sound'KFWeaponSound.bullethitwood2'
	ImpactSounds(2)=Sound'KFWeaponSound.WoodImpact'

	Begin Object Class=SpriteEmitter Name=WoodSpray
		UseDirectionAs=PTDU_Up
		UseRotationFrom=PTRS_Actor
		UseColorScale=True
		FadeOut=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseSizeScale=True
		UseRegularSizeScale=False
		ColorScale(0)=(Color=(B=98,G=128,R=150,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=76,G=98,R=115,A=255))
		Opacity=1.000000
		FadeOutStartTime=0.100000
		MaxParticles=2
		StartLocationOffset=(X=9.000000)
		SizeScale(0)=(RelativeSize=0.500000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.000000)
		StartSizeRange=(X=(Min=9.000000,Max=13.000000),Y=(Min=18.000000,Max=24.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'KFMaterials.NewDustSpray'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.350000,Max=0.500000)
		StartVelocityRange=(X=(Min=22.000000,Max=28.000000),Y=(Min=-4.000000,Max=4.000000),Z=(Min=-4.000000,Max=4.000000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFImpactWood.WoodSpray'

	Begin Object Class=SpriteEmitter Name=WoodBurst
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
		Acceleration=(Z=-20.000000)
		ColorScale(0)=(Color=(B=135,G=155,R=170,A=255))
		ColorScale(1)=(RelativeTime=0.350000,Color=(B=96,G=110,R=120,A=255))
		ColorScale(2)=(RelativeTime=1.000000,Color=(B=82,G=92,R=100,A=255))
		Opacity=0.850000
		FadeOutStartTime=0.250000
		FadeInEndTime=0.040000
		MaxParticles=10
		SpinsPerSecondRange=(X=(Min=-0.150000,Max=0.150000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=0.250000,RelativeSize=2.800000)
		SizeScale(2)=(RelativeTime=1.000000,RelativeSize=3.600000)
		StartSizeRange=(X=(Min=4.000000,Max=6.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'VMParticleTextures.VehicleExplosions.smoke1tex'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=1.000000,Max=1.500000)
		StartVelocityRange=(X=(Min=80.000000,Max=240.000000),Y=(Min=-80.000000,Max=80.000000),Z=(Min=-80.000000,Max=80.000000))
		VelocityLossRange=(X=(Min=3.500000,Max=5.000000),Y=(Min=3.500000,Max=5.000000),Z=(Min=3.500000,Max=5.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFImpactWood.WoodBurst'

	Begin Object Class=SpriteEmitter Name=WoodHaze
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
		Acceleration=(Z=-6.000000)
		ColorScale(0)=(Color=(B=95,G=106,R=115,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=86,G=94,R=100,A=255))
		Opacity=0.350000
		FadeOutStartTime=0.800000
		FadeInEndTime=0.300000
		MaxParticles=2
		StartLocationOffset=(X=6.000000)
		SpinsPerSecondRange=(X=(Min=-0.050000,Max=0.050000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.300000)
		StartSizeRange=(X=(Min=9.000000,Max=12.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'VMParticleTextures.VehicleExplosions.smoke1tex'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=2.000000,Max=2.600000)
		StartVelocityRange=(X=(Min=12.000000,Max=28.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=-10.000000,Max=10.000000))
		VelocityLossRange=(X=(Min=1.000000,Max=1.500000),Y=(Min=1.000000,Max=1.500000),Z=(Min=1.000000,Max=1.500000))
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFImpactWood.WoodHaze'
}
