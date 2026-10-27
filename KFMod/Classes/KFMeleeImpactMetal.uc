//=============================================================================
// KFMeleeImpactMetal
// A melee blow on metal: the bullet impact's flash, sparks and hot spot, bigger (KFMeleeHitEffect sizes it), a clang,
// and a spray of sparks scraped off along the swing.
//=============================================================================
class KFMeleeImpactMetal extends KFImpactMetal;

#exec OBJ LOAD FILE=PatchSounds.uax

var() array<Sound> BluntSounds;

simulated function PostBeginPlay()
{
	if ( KFMeleeHitEffect(Owner) != None && KFMeleeHitEffect(Owner).Kind == 2 )
		ImpactSounds = BluntSounds;
	Super.PostBeginPlay();
	class'KFMeleeHitEffect'.static.Scrape(self, 4, 26, 10);
}

defaultproperties
{
	Counts(1)=16
	ImpactSounds(0)=Sound'KFWeaponSound.MetalHitMelee1'
	ImpactSounds(1)=Sound'KFWeaponSound.MetalHitMelee2'
	ImpactSounds(2)=Sound'KFWeaponSound.MetalHitMelee3'
	ImpactSounds(3)=Sound'KFWeaponSound.KnifeHitMetal'
	BluntSounds(0)=Sound'PatchSounds.MetalImpact3'
	BluntSounds(1)=Sound'PatchSounds.MetalImpact4'
	BluntSounds(2)=Sound'PatchSounds.MetalImpact5'
	LightBrightness=150.000000
	LightRadius=5.000000

	Begin Object Class=SpriteEmitter Name=MeleeScrape
		UseDirectionAs=PTDU_Up
		UseRotationFrom=PTRS_Actor
		UseCollision=True
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		ScaleSizeYByVelocity=True
		Acceleration=(Z=-950.000000)
		DampingFactorRange=(X=(Min=0.300000,Max=0.500000),Y=(Min=0.300000,Max=0.500000),Z=(Min=0.300000,Max=0.500000))
		ColorScale(0)=(Color=(B=235,G=252,R=255,A=255))
		ColorScale(1)=(RelativeTime=0.300000,Color=(B=100,G=215,R=255,A=255))
		ColorScale(2)=(RelativeTime=0.750000,Color=(B=20,G=100,R=230,A=255))
		ColorScale(3)=(RelativeTime=1.000000,Color=(R=90,A=255))
		MaxParticles=40
		StartSizeRange=(X=(Min=1.200000,Max=2.200000),Y=(Min=1.200000,Max=2.200000))
		ScaleSizeByVelocityMultiplier=(Y=0.012000)
		DrawStyle=PTDS_Brighten
		Texture=Texture'KFX.KFSparkHead'
		TextureUSubdivisions=1
		TextureVSubdivisions=2
		SecondsBeforeInactive=0.000000
		LifetimeRange=(Min=0.350000,Max=0.900000)
	End Object
	Emitters(4)=SpriteEmitter'KFMod.KFMeleeImpactMetal.MeleeScrape'
}
