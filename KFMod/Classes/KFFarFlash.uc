//=============================================================================
// KFFarFlash
// A blast too far off for its own effects, seen anyway: a burst of light and a glow that dies away (KFBlast.Far)
//=============================================================================
class KFFarFlash extends KFBlastEmitter;

#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx

defaultproperties
{
	Counts(0)=1
	Counts(1)=1
	LifeSpan=2.000000

	Begin Object Class=SpriteEmitter Name=FarBurst
		UseColorScale=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		ColorScale(0)=(Color=(B=210,G=245,R=255))
		ColorScale(1)=(RelativeTime=1.000000)
		MaxParticles=2
		SizeScale(0)=(RelativeSize=0.700000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.300000)
		StartSizeRange=(X=(Min=260.000000,Max=300.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'EpicParticles.Flares.FlashFlare1'
		LifetimeRange=(Min=0.250000,Max=0.250000)
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFFarFlash.FarBurst'

	Begin Object Class=SpriteEmitter Name=FarGlow
		UseColorScale=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		ColorScale(0)=(Color=(B=40,G=110,R=200))
		ColorScale(1)=(RelativeTime=0.300000,Color=(B=15,G=55,R=140))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=2
		SizeScale(0)=(RelativeSize=0.800000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.400000)
		StartSizeRange=(X=(Min=420.000000,Max=480.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'EpicParticles.Flares.SoftFlare'
		LifetimeRange=(Min=1.400000,Max=1.400000)
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFFarFlash.FarGlow'
}
