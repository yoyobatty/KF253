//=============================================================================
// KFImpactMetal
// A bullet on metal: a hot star of a flash with a short light, sparks that bounce and cool from white to red, a
// glowing spot where it struck and a wisp of smoke.
//=============================================================================
class KFImpactMetal extends KFImpactEmitter;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	// (the light only for the shooter's own strikes, as MetalHitEmitter)
	if ( !Level.bDropDetail && Instigator != None && PlayerController(Instigator.Controller) != None )
	{
		bDynamicLight = true;
		SetTimer(0.15, false);
	}
}

simulated function Timer()
{
	bDynamicLight = false;
}

defaultproperties
{
	Counts(0)=1
	Counts(1)=12
	Counts(2)=1
	Counts(3)=2
	ImpactSounds(0)=Sound'KFWeaponSound.bullethitmetal2'
	ImpactSounds(1)=Sound'KFWeaponSound.bullethitmetal3'
	ImpactSounds(2)=Sound'KFWeaponSound.bullethitmetal4'
	LightType=LT_Steady
	LightHue=30
	LightSaturation=150
	LightBrightness=110.000000
	LightRadius=4.000000

	Begin Object Class=SpriteEmitter Name=MetalFlash
		UseRotationFrom=PTRS_Actor
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		ColorScale(0)=(Color=(B=210,G=240,R=255,A=255))
		ColorScale(1)=(RelativeTime=1.000000)
		MaxParticles=2
		StartLocationOffset=(X=2.000000)
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.600000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.200000)
		StartSizeRange=(X=(Min=7.000000,Max=10.000000))
		Texture=Texture'KFX.MetalHitKF2'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.060000,Max=0.080000)
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFImpactMetal.MetalFlash'

	Begin Object Class=SpriteEmitter Name=MetalSparks
		UseDirectionAs=PTDU_Up
		UseRotationFrom=PTRS_Actor
		UseCollision=True
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		ScaleSizeYByVelocity=True
		Acceleration=(Z=-900.000000)
		DampingFactorRange=(X=(Min=0.250000,Max=0.450000),Y=(Min=0.250000,Max=0.450000),Z=(Min=0.250000,Max=0.450000))
		ColorScale(0)=(Color=(B=230,G=250,R=255,A=255))
		ColorScale(1)=(RelativeTime=0.250000,Color=(B=90,G=210,R=255,A=255))
		ColorScale(2)=(RelativeTime=0.700000,Color=(B=20,G=100,R=230,A=255))
		ColorScale(3)=(RelativeTime=1.000000,Color=(R=90,A=255))
		MaxParticles=24
		StartSizeRange=(X=(Min=1.200000,Max=2.000000),Y=(Min=1.200000,Max=2.000000))
		ScaleSizeByVelocityMultiplier=(Y=0.010000)
		DrawStyle=PTDS_Brighten
		Texture=Texture'KFX.KFSparkHead'
		TextureUSubdivisions=1
		TextureVSubdivisions=2
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.250000,Max=0.600000)
		StartVelocityRange=(X=(Min=150.000000,Max=600.000000),Y=(Min=-450.000000,Max=450.000000),Z=(Min=-450.000000,Max=450.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFImpactMetal.MetalSparks'

	Begin Object Class=SpriteEmitter Name=MetalHotSpot
		UseRotationFrom=PTRS_Actor
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		ColorScale(0)=(Color=(B=60,G=170,R=255,A=255))
		ColorScale(1)=(RelativeTime=0.500000,Color=(B=10,G=60,R=170,A=255))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=2
		StartLocationOffset=(X=1.000000)
		SizeScale(0)=(RelativeSize=0.600000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.200000)
		StartSizeRange=(X=(Min=2.500000,Max=3.500000))
		Texture=Texture'KFX.MetalHitKF'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.250000,Max=0.350000)
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFImpactMetal.MetalHotSpot'

	Begin Object Class=SpriteEmitter Name=MetalSmoke
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
		Acceleration=(Z=12.000000)
		ColorScale(0)=(Color=(B=90,G=90,R=90,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=70,G=70,R=70,A=255))
		Opacity=0.500000
		FadeOutStartTime=0.300000
		FadeInEndTime=0.100000
		MaxParticles=4
		StartLocationOffset=(X=3.000000)
		SpinsPerSecondRange=(X=(Min=-0.150000,Max=0.150000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=4.000000)
		StartSizeRange=(X=(Min=3.000000,Max=5.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.900000,Max=1.300000)
		StartVelocityRange=(X=(Min=20.000000,Max=60.000000),Y=(Min=-15.000000,Max=15.000000),Z=(Min=-15.000000,Max=15.000000))
		VelocityLossRange=(X=(Min=1.500000,Max=2.000000),Y=(Min=1.500000,Max=2.000000),Z=(Min=1.500000,Max=2.000000))
	End Object
	Emitters(3)=SpriteEmitter'KFMod.KFImpactMetal.MetalSmoke'
}
