//=============================================================================
// KFDragonTrail
// The flame a burning pellet of an upgraded pump shotgun (ShotgunBulletDragon) trails as it flies
//=============================================================================
class KFDragonTrail extends Emitter;

defaultproperties
{
	Begin Object Class=SpriteEmitter Name=DragonFlames
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		ColorScale(0)=(Color=(B=120,G=210,R=255,A=255))
		ColorScale(1)=(RelativeTime=0.400000,Color=(B=30,G=120,R=240,A=255))
		ColorScale(2)=(RelativeTime=1.000000,Color=(A=255))
		MaxParticles=24
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.200000)
		StartSizeRange=(X=(Min=2.500000,Max=4.000000))
		ParticlesPerSecond=80.000000
		InitialParticlesPerSecond=80.000000
		Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.120000,Max=0.200000)
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFDragonTrail.DragonFlames'

	Begin Object Class=SpriteEmitter Name=DragonCore
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UniformSize=True
		ColorScale(0)=(Color=(B=180,G=235,R=255,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=40,G=120,R=255,A=255))
		MaxParticles=12
		StartSizeRange=(X=(Min=1.500000,Max=2.000000))
		ParticlesPerSecond=80.000000
		InitialParticlesPerSecond=80.000000
		Texture=Texture'EmitterTextures.Flares.EFlareOY'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.050000,Max=0.070000)
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFDragonTrail.DragonCore'

	bNoDelete=False
}
