//=============================================================================
// KFBackblast
// The LAW's backblast: a jet of flame and grit out of the back of the tube, and a cloud of dust and smoke that hangs
// behind the one who fired (LAWAttachment). X points out of the back of the tube.
//=============================================================================
class KFBackblast extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EmitterTextures.utx

simulated function PostBeginPlay()
{
	local int i;

	Super.PostBeginPlay();
	for ( i = 0; i < Emitters.Length; i++ )
		Emitters[i].SpawnParticle(Emitters[i].MaxParticles);
}

defaultproperties
{
	// flame out of the back
	Begin Object Class=SpriteEmitter Name=BlastFlame
		UseColorScale=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseRotationFrom=PTRS_Actor
		ColorScale(0)=(Color=(B=150,G=225,R=255))
		ColorScale(1)=(RelativeTime=0.350000,Color=(B=40,G=120,R=240))
		ColorScale(2)=(RelativeTime=0.800000,Color=(B=6,G=20,R=80))
		ColorScale(3)=(RelativeTime=1.000000)
		MaxParticles=8
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.500000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.000000)
		StartSizeRange=(X=(Min=12.000000,Max=20.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=0.120000,Max=0.220000)
		StartVelocityRange=(X=(Min=500.000000,Max=900.000000),Y=(Min=-90.000000,Max=90.000000),Z=(Min=-90.000000,Max=90.000000))
		VelocityLossRange=(X=(Min=6.000000,Max=8.000000),Y=(Min=6.000000,Max=8.000000),Z=(Min=6.000000,Max=8.000000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFBackblast.BlastFlame'

	// grit thrown back
	Begin Object Class=SpriteEmitter Name=BlastGrit
		UseDirectionAs=PTDU_Up
		UseColorScale=True
		ScaleSizeYByVelocity=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseRotationFrom=PTRS_Actor
		Acceleration=(Z=-600.000000)
		ColorScale(0)=(Color=(B=180,G=230,R=255))
		ColorScale(1)=(RelativeTime=0.500000,Color=(B=30,G=110,R=230))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=12
		StartSizeRange=(X=(Min=0.600000,Max=1.000000),Y=(Min=0.600000,Max=1.000000))
		ScaleSizeByVelocityMultiplier=(Y=0.003000)
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Energy.SparkHead'
		LifetimeRange=(Min=0.200000,Max=0.450000)
		StartVelocityRange=(X=(Min=600.000000,Max=1200.000000),Y=(Min=-250.000000,Max=250.000000),Z=(Min=-150.000000,Max=250.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFBackblast.BlastGrit'

	// the cloud that hangs behind
	Begin Object Class=SpriteEmitter Name=BlastCloud
		FadeOut=True
		FadeIn=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseRotationFrom=PTRS_Actor
		Acceleration=(Z=12.000000)
		ColorScale(0)=(Color=(B=150,G=160,R=170,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=150,G=160,R=170,A=255))
		Opacity=0.550000
		FadeOutStartTime=0.600000
		FadeInEndTime=0.080000
		MaxParticles=10
		StartSpinRange=(X=(Max=1.000000))
		SpinsPerSecondRange=(X=(Min=-0.060000,Max=0.060000))
		SizeScale(0)=(RelativeSize=0.400000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.600000)
		StartSizeRange=(X=(Min=30.000000,Max=48.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Fire.MuchSmoke1'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=1.600000,Max=2.400000)
		StartVelocityRange=(X=(Min=150.000000,Max=420.000000),Y=(Min=-90.000000,Max=90.000000),Z=(Min=-40.000000,Max=80.000000))
		VelocityLossRange=(X=(Min=2.500000,Max=3.500000),Y=(Min=2.500000,Max=3.500000),Z=(Min=2.500000,Max=3.500000))
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFBackblast.BlastCloud'

	AutoDestroy=True
	bNoDelete=False
	RemoteRole=ROLE_None
	LifeSpan=4.000000
}
