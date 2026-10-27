//=============================================================================
// KFAxeSlashTrail
// What the flying cut leaves in the air behind it (KFAxeSlash keeps three: its middle and its two tips): a red-white
// afterglow and embers that fall away.
//=============================================================================
class KFAxeSlashTrail extends Emitter;

defaultproperties
{
	Begin Object Class=SpriteEmitter Name=TrailGlow
		FadeOut=True
		FadeOutStartTime=0.040000
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		ColorMultiplierRange=(X=(Min=1.000000,Max=1.000000),Y=(Min=0.380000,Max=0.560000),Z=(Min=0.320000,Max=0.480000))
		MaxParticles=40
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=0.400000)
		StartSizeRange=(X=(Min=7.000000,Max=12.000000))
		ParticlesPerSecond=140.000000
		InitialParticlesPerSecond=110.000000
		DrawStyle=PTDS_Brighten
		Texture=Texture'EpicParticles.Flares.SoftFlare'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.140000,Max=0.240000)
		StartVelocityRange=(X=(Min=-40.000000,Max=40.000000),Y=(Min=-40.000000,Max=40.000000),Z=(Min=-40.000000,Max=40.000000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFAxeSlashTrail.TrailGlow'

	Begin Object Class=SpriteEmitter Name=TrailEmbers
		UseDirectionAs=PTDU_Up
		FadeOut=True
		FadeOutStartTime=0.200000
		ScaleSizeYByVelocity=True
		Acceleration=(Z=-700.000000)
		ColorMultiplierRange=(X=(Min=1.000000,Max=1.000000),Y=(Min=0.450000,Max=0.700000),Z=(Min=0.250000,Max=0.400000))
		MaxParticles=30
		StartSizeRange=(X=(Min=1.500000,Max=3.000000),Y=(Min=1.500000,Max=3.000000))
		ScaleSizeByVelocityMultiplier=(Y=0.010000)
		ParticlesPerSecond=40.000000
		InitialParticlesPerSecond=40.000000
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Energy.SparkHead'
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.300000,Max=0.500000)
		StartVelocityRange=(X=(Min=-160.000000,Max=160.000000),Y=(Min=-160.000000,Max=160.000000),Z=(Min=-60.000000,Max=200.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFAxeSlashTrail.TrailEmbers'

	bNoDelete=False
	RemoteRole=ROLE_None
	LifeSpan=4.000000
}
