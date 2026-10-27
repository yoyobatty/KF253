//=============================================================================
// KFElementHit
// Where an upgraded gun's round strikes: a spit of sparks and a flash in its element's colour (KFElement), beside the
// round's own hit (KFWeaponAttachment.ThirdPersonEffects). X is out of the surface.
//=============================================================================
class KFElementHit extends KFBlastEmitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx

defaultproperties
{
	Counts(0)=1
	Counts(1)=7
	LifeSpan=1.500000

	Begin Object Class=SpriteEmitter Name=HitFlash
		UseColorScale=True
		UniformSize=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseRotationFrom=PTRS_Actor
		ColorScale(0)=(Color=(B=255,G=255,R=255))
		ColorScale(1)=(RelativeTime=1.000000)
		MaxParticles=3
		StartLocationOffset=(X=4.000000)
		StartSizeRange=(X=(Min=20.000000,Max=28.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'EpicParticles.Flares.FlashFlare1'
		LifetimeRange=(Min=0.080000,Max=0.100000)
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFElementHit.HitFlash'

	Begin Object Class=SpriteEmitter Name=HitSparks
		UseDirectionAs=PTDU_Up
		UseColorScale=True
		ScaleSizeYByVelocity=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseRotationFrom=PTRS_Actor
		Acceleration=(Z=-500.000000)
		ColorScale(0)=(Color=(B=255,G=255,R=255))
		ColorScale(1)=(RelativeTime=0.500000,Color=(B=200,G=200,R=200))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=20
		StartLocationOffset=(X=2.000000)
		StartSizeRange=(X=(Min=0.500000,Max=0.800000),Y=(Min=0.500000,Max=0.800000))
		ScaleSizeByVelocityMultiplier=(Y=0.003500)
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Energy.SparkHead'
		LifetimeRange=(Min=0.150000,Max=0.350000)
		StartVelocityRange=(X=(Min=200.000000,Max=600.000000),Y=(Min=-300.000000,Max=300.000000),Z=(Min=-300.000000,Max=300.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFElementHit.HitSparks'
}
