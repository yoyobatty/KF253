//=============================================================================
// KFVoidBurst
// The Void Executioner's shock wave as seen (KFVoidArrival): a violet-white flash and a core of light, a flat ring
// racing out over the floor and a round one, violet sparks flung out, dark violet smoke rolling, the room lit violet
// and fading.
//=============================================================================
class KFVoidBurst extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx
#exec OBJ LOAD FILE=..\Textures\XEffectMat.utx

var float Age;

// Seen from inside by the one who arrived in it: the flash and the smoke kept out of their eyes
simulated function Inside()
{
	Emitters[0].StartSizeRange.X.Min *= 0.35;
	Emitters[0].StartSizeRange.X.Max *= 0.35;
	Emitters[2].Disabled = true;
	Emitters[4].Opacity *= 0.3;
	Emitters[4].StartSizeRange.X.Min *= 0.6;
	Emitters[4].StartSizeRange.X.Max *= 0.6;
	LightBrightness *= 0.7;
}

simulated function Tick( float DT )
{
	Age += DT;
	if ( LightType != LT_None )
	{
		LightBrightness = default.LightBrightness * FMax(0.0, 1.0 - Age / 0.7);
		if ( Age > 0.7 )
		{
			LightType = LT_None;
			bDynamicLight = false;
		}
	}
}

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=VoidFlash
         FadeOut=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ColorMultiplierRange=(X=(Min=0.850000,Max=0.850000),Y=(Min=0.550000,Max=0.550000),Z=(Min=1.000000,Max=1.000000))
         MaxParticles=2
         SizeScale(0)=(RelativeSize=0.600000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.300000)
         StartSizeRange=(X=(Min=420.000000,Max=520.000000))
         InitialParticlesPerSecond=100.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.FlashFlare1'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.220000,Max=0.300000)
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFVoidBurst.VoidFlash'

     Begin Object Class=SpriteEmitter Name=VoidRingFlat
         UseDirectionAs=PTDU_Normal
         UseColorScale=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ColorScale(0)=(Color=(B=255,G=230,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=90,G=10,R=50,A=255))
         ColorMultiplierRange=(X=(Min=0.900000,Max=0.900000),Y=(Min=0.400000,Max=0.400000),Z=(Min=1.000000,Max=1.000000))
         MaxParticles=1
         SizeScale(0)=(RelativeSize=0.100000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.000000)
         StartSizeRange=(X=(Min=1150.000000,Max=1150.000000))
         InitialParticlesPerSecond=100.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'XEffectMat.Shock.shock_ring_b'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.450000,Max=0.450000)
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFVoidBurst.VoidRingFlat'

     Begin Object Class=SpriteEmitter Name=VoidRingRound
         UseColorScale=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ColorScale(0)=(Color=(B=255,G=230,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=60,G=0,R=30,A=255))
         ColorMultiplierRange=(X=(Min=0.850000,Max=0.850000),Y=(Min=0.350000,Max=0.350000),Z=(Min=1.000000,Max=1.000000))
         MaxParticles=1
         SizeScale(0)=(RelativeSize=0.150000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.000000)
         StartSizeRange=(X=(Min=900.000000,Max=900.000000))
         InitialParticlesPerSecond=100.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'XEffectMat.Shock.shock_ring_b'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.320000,Max=0.320000)
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFVoidBurst.VoidRingRound'

     Begin Object Class=SpriteEmitter Name=VoidSparks
         UseDirectionAs=PTDU_Up
         FadeOut=True
         FadeOutStartTime=0.300000
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         ScaleSizeYByVelocity=True
         Acceleration=(Z=-600.000000)
         ColorMultiplierRange=(X=(Min=0.750000,Max=0.950000),Y=(Min=0.400000,Max=0.650000),Z=(Min=1.000000,Max=1.000000))
         MaxParticles=70
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Min=8.000000,Max=24.000000)
         StartSizeRange=(X=(Min=2.500000,Max=4.500000),Y=(Min=2.500000,Max=4.500000))
         ScaleSizeByVelocityMultiplier=(Y=0.008000)
         InitialParticlesPerSecond=1000.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'AW-2004Particles.Energy.SparkHead'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.500000,Max=0.900000)
         StartVelocityRadialRange=(Min=900.000000,Max=1800.000000)
         GetVelocityDirectionFrom=PTVD_AddRadial
     End Object
     Emitters(3)=SpriteEmitter'KFMod.KFVoidBurst.VoidSparks'

     Begin Object Class=SpriteEmitter Name=VoidSmoke
         FadeOut=True
         FadeIn=True
         FadeOutStartTime=0.600000
         FadeInEndTime=0.080000
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         UseRandomSubdivision=True
         Acceleration=(Z=30.000000)
         ColorMultiplierRange=(X=(Min=0.180000,Max=0.240000),Y=(Min=0.060000,Max=0.090000),Z=(Min=0.260000,Max=0.340000))
         Opacity=0.700000
         MaxParticles=16
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Min=10.000000,Max=40.000000)
         SpinsPerSecondRange=(X=(Min=-0.100000,Max=0.100000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.600000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.400000)
         StartSizeRange=(X=(Min=90.000000,Max=140.000000))
         InitialParticlesPerSecond=1000.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=1.500000,Max=2.200000)
         VelocityLossRange=(X=(Min=2.000000,Max=2.500000),Y=(Min=2.000000,Max=2.500000),Z=(Min=2.000000,Max=2.500000))
         StartVelocityRadialRange=(Min=300.000000,Max=600.000000)
         GetVelocityDirectionFrom=PTVD_AddRadial
     End Object
     Emitters(4)=SpriteEmitter'KFMod.KFVoidBurst.VoidSmoke'

     LightType=LT_Steady
     LightEffect=LE_NonIncidence
     LightHue=200
     LightSaturation=60
     LightBrightness=255.000000
     LightRadius=24.000000
     bDynamicLight=True
     bNoDelete=False
     RemoteRole=ROLE_None
     LifeSpan=3.000000
}
