// A specimen teleporting into a lockdown (KFTeleportIn), Doom style, as each machine sees it: dark smoke boiling up,
// embers drawn in to a burning core, a red glow growing; then (Arrive) a flash, a ring of fire on the floor, and it is
// there.
class KFTeleportFX extends Emitter;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(class'KFTeleportIn'.default.Charge - 0.04, false);
	PlaySound(Sound'WeaponSounds.BaseFiringSounds.BTranslocatorFire', SLOT_None, 2.0,, 1500.0, 0.45);
}

simulated function Timer()
{
	Spawn(class'KFTeleportFlash',,, Location);
	PlaySound(Sound'ONSBPSounds.ShockTank.ShockBallExplosion', SLOT_None, 1.8,, 2000.0, 0.9);
	Kill();
}

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=PortalSmoke
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         Acceleration=(Z=40.000000)
         ColorScale(0)=(Color=(B=20,G=20,R=40,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=5,G=5,R=15,A=255))
         FadeOutStartTime=0.500000
         FadeInEndTime=0.200000
         MaxParticles=14
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=24.000000)
         SizeScale(0)=(RelativeSize=0.600000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.600000)
         StartSizeRange=(X=(Min=36.000000,Max=56.000000))
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         UseRandomSubdivision=True
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.700000,Max=1.100000)
         StartVelocityRange=(X=(Min=-30.000000,Max=30.000000),Y=(Min=-30.000000,Max=30.000000),Z=(Min=20.000000,Max=70.000000))
         InitialParticlesPerSecond=40.000000
         ParticlesPerSecond=20.000000
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFTeleportFX.PortalSmoke'

     Begin Object Class=SpriteEmitter Name=PortalEmbers
         UseColorScale=True
         FadeIn=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ColorScale(0)=(Color=(B=60,G=170,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=20,G=80,R=255,A=255))
         FadeInEndTime=0.100000
         MaxParticles=50
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Min=50.000000,Max=70.000000)
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=0.300000)
         StartSizeRange=(X=(Min=5.000000,Max=9.000000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'KFX.KFSparkHead'
         TextureUSubdivisions=1
         TextureVSubdivisions=2
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.400000,Max=0.500000)
         StartVelocityRadialRange=(Min=-150.000000,Max=-120.000000)
         GetVelocityDirectionFrom=PTVD_AddRadial
         InitialParticlesPerSecond=80.000000
         ParticlesPerSecond=80.000000
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFTeleportFX.PortalEmbers'

     Begin Object Class=SpriteEmitter Name=PortalCore
         UseColorScale=True
         FadeIn=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ColorScale(0)=(Color=(B=30,G=90,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=60,G=180,R=255,A=255))
         FadeInEndTime=0.300000
         MaxParticles=3
         SizeScale(0)=(RelativeSize=0.200000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.400000)
         StartSizeRange=(X=(Min=60.000000,Max=70.000000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.600000,Max=0.600000)
         InitialParticlesPerSecond=6.000000
         ParticlesPerSecond=4.000000
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFTeleportFX.PortalCore'

     LightType=LT_Pulse
     LightHue=8
     LightSaturation=40
     LightBrightness=200.000000
     LightRadius=8.000000
     LightPeriod=10
     bDynamicLight=True
     bNoDelete=False
     RemoteRole=ROLE_None
     LifeSpan=2.500000
}
