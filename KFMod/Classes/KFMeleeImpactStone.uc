//=============================================================================
// KFMeleeImpactStone
// A melee blow on stone or plaster: the bullet impact's dust and grit, bigger (KFMeleeHitEffect sizes it), a crack of
// steel on stone, and for a blade a few sparks struck off along the swing.
//=============================================================================
class KFMeleeImpactStone extends KFImpactStone;

#exec OBJ LOAD FILE=PatchSounds.uax

var() array<Sound> BluntSounds;

simulated function PostBeginPlay()
{
	if ( KFMeleeHitEffect(Owner) != None && KFMeleeHitEffect(Owner).Kind == 2 )
		ImpactSounds = BluntSounds;
	Super.PostBeginPlay();
	class'KFMeleeHitEffect'.static.Scrape(self, Emitters.Length - 1, 9, 0);
}

defaultproperties
{
	ImpactSounds(0)=Sound'KFWeaponSound.MetalHitMelee1'
	ImpactSounds(1)=Sound'KFWeaponSound.MetalHitMelee2'
	ImpactSounds(2)=Sound'KFWeaponSound.MeleeHitGround3'
	BluntSounds(0)=Sound'PatchSounds.MiscImpact1'
	BluntSounds(1)=Sound'PatchSounds.MiscImpact2'
	BluntSounds(2)=Sound'KFWeaponSound.MeleeHitGround3'

	Begin Object Class=SpriteEmitter Name=StoneSparks
		UseDirectionAs=PTDU_Up
		UseRotationFrom=PTRS_Actor
		UseCollision=True
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		ScaleSizeYByVelocity=True
		Acceleration=(Z=-950.000000)
		DampingFactorRange=(X=(Min=0.250000,Max=0.400000),Y=(Min=0.250000,Max=0.400000),Z=(Min=0.250000,Max=0.400000))
		ColorScale(0)=(Color=(B=200,G=245,R=255,A=255))
		ColorScale(1)=(RelativeTime=0.300000,Color=(B=60,G=190,R=255,A=255))
		ColorScale(2)=(RelativeTime=1.000000,Color=(R=90,A=255))
		MaxParticles=16
		StartSizeRange=(X=(Min=0.900000,Max=1.600000),Y=(Min=0.900000,Max=1.600000))
		ScaleSizeByVelocityMultiplier=(Y=0.010000)
		DrawStyle=PTDS_Brighten
		Texture=Texture'KFX.KFSparkHead'
		TextureUSubdivisions=1
		TextureVSubdivisions=2
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.200000,Max=0.500000)
	End Object
	Emitters(5)=SpriteEmitter'KFMod.KFMeleeImpactStone.StoneSparks'
}
