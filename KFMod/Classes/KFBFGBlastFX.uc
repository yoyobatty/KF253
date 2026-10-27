//=============================================================================
// KFBFGBlastFX
// The BFG's ball bursting (BFGBall.Blast): KFArcBlast's flash, plasma, sparks, shock ring, arcs and smoke in green and
// bigger, a green light flooding the room, and the bang.
//=============================================================================
class KFBFGBlastFX extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx
#exec OBJ LOAD FILE=..\Textures\XEffectMat.utx
#exec OBJ LOAD FILE=..\Sounds\WeaponSounds.uax
#exec OBJ LOAD FILE=..\Sounds\ONSBPSounds.uax

var float Age;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetPower(1.0);
	PlaySound(Sound'WeaponSounds.Misc.redeemer_explosionsound', SLOT_None, 2.5,, 6000, 1.15);
	PlaySound(Sound'ONSBPSounds.ShockTank.ShockBallExplosion', SLOT_None, 2.5,, 5000, 0.8);
	PlaySound(Sound'KFMod.Zap.ZapStart', SLOT_None, 2.0,, 3000, 0.5);
}

simulated function Tick( float DT )
{
	Age += DT;
	if ( LightType == LT_None )
		return;
	LightBrightness = default.LightBrightness * FClamp(1.0 - Age / 0.9, 0.0, 1.0);
	if ( Age > 0.9 )
		LightType = LT_None;
}

simulated function SetPower( float C )
{
	local int i;
	local float S;

	S = 1.35 * (0.55 + 0.45 * C);
	for ( i=0; i<Emitters.Length; i++ )
	{
		Emitters[i].StartSizeRange.X.Min *= S;
		Emitters[i].StartSizeRange.X.Max *= S;
		Emitters[i].StartSizeRange.Y.Min *= S;
		Emitters[i].StartSizeRange.Y.Max *= S;
		Emitters[i].StartVelocityRange.X.Min *= S;
		Emitters[i].StartVelocityRange.X.Max *= S;
		Emitters[i].StartVelocityRange.Y.Min *= S;
		Emitters[i].StartVelocityRange.Y.Max *= S;
		Emitters[i].StartVelocityRange.Z.Min *= S;
		Emitters[i].StartVelocityRange.Z.Max *= S;
	}
	Emitters[2].InitialParticlesPerSecond *= C;
}

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=BlastFlash
         UseColorScale=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         UniformSize=True
         ColorScale(0)=(Color=(B=250,G=255,R=245,A=255))
         ColorScale(1)=(RelativeTime=0.400000,Color=(B=200,G=255,R=170,A=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=40,G=120,R=20,A=255))
         MaxParticles=2
         StartSizeRange=(X=(Min=340.000000,Max=420.000000))
         InitialParticlesPerSecond=400.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.FlashFlare1'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.120000,Max=0.160000)
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFBFGBlastFX.BlastFlash'

     Begin Object Class=SpriteEmitter Name=BlastPlasma
         UseColorScale=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         FadeOut=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         UseRandomSubdivision=True
         Acceleration=(Z=120.000000)
         ColorScale(0)=(Color=(B=235,G=255,R=215,A=255))
         ColorScale(1)=(RelativeTime=0.200000,Color=(B=150,G=255,R=110,A=255))
         ColorScale(2)=(RelativeTime=0.550000,Color=(B=110,G=90,R=230,A=255))
         ColorScale(3)=(RelativeTime=1.000000,Color=(B=20,G=10,R=60,A=255))
         FadeOutStartTime=0.300000
         MaxParticles=22
         StartLocationRange=(X=(Min=-20.000000,Max=20.000000),Y=(Min=-20.000000,Max=20.000000),Z=(Min=-20.000000,Max=20.000000))
         SpinsPerSecondRange=(X=(Min=-0.400000,Max=0.400000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.400000)
         SizeScale(1)=(RelativeTime=0.300000,RelativeSize=1.000000)
         SizeScale(2)=(RelativeTime=1.000000,RelativeSize=1.500000)
         StartSizeRange=(X=(Min=90.000000,Max=160.000000))
         InitialParticlesPerSecond=600.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.500000,Max=0.850000)
         StartVelocityRange=(X=(Min=-420.000000,Max=420.000000),Y=(Min=-420.000000,Max=420.000000),Z=(Min=-200.000000,Max=420.000000))
         VelocityLossRange=(X=(Min=3.000000,Max=3.000000),Y=(Min=3.000000,Max=3.000000),Z=(Min=3.000000,Max=3.000000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFBFGBlastFX.BlastPlasma'

     Begin Object Class=SpriteEmitter Name=BlastMolten
         UseDirectionAs=PTDU_Up
         UseCollision=True
         UseColorScale=True
         ScaleSizeYByVelocity=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         Acceleration=(Z=-1100.000000)
         DampingFactorRange=(X=(Min=0.400000,Max=0.500000),Y=(Min=0.400000,Max=0.500000),Z=(Min=0.250000,Max=0.350000))
         ColorScale(0)=(Color=(B=250,G=230,R=255))
         ColorScale(1)=(RelativeTime=0.250000,Color=(B=200,G=90,R=255))
         ColorScale(2)=(RelativeTime=0.700000,Color=(B=90,G=10,R=230))
         ColorScale(3)=(RelativeTime=1.000000,Color=(B=10,R=60))
         MaxParticles=90
         StartSizeRange=(X=(Min=1.200000,Max=2.400000),Y=(Min=1.200000,Max=2.400000))
         ScaleSizeByVelocityMultiplier=(Y=0.004000)
         InitialParticlesPerSecond=3000.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'AW-2004Particles.Energy.SparkHead'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.900000,Max=2.200000)
         StartVelocityRange=(X=(Min=-1100.000000,Max=1100.000000),Y=(Min=-1100.000000,Max=1100.000000),Z=(Min=-300.000000,Max=1200.000000))
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFBFGBlastFX.BlastMolten'

     Begin Object Class=SpriteEmitter Name=BlastRing
         UseDirectionAs=PTDU_Normal
         UseColorScale=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ColorScale(0)=(Color=(B=230,G=255,R=200,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=20,G=60,R=10,A=255))
         MaxParticles=1
         StartLocationOffset=(Z=4.000000)
         SizeScale(0)=(RelativeSize=0.150000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.000000)
         StartSizeRange=(X=(Min=700.000000,Max=700.000000))
         InitialParticlesPerSecond=100.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'XEffectMat.Shock.shock_ring_b'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.400000,Max=0.400000)
     End Object
     Emitters(3)=SpriteEmitter'KFMod.KFBFGBlastFX.BlastRing'

     Begin Object Class=BeamEmitter Name=BlastArcs
         BeamDistanceRange=(Min=120.000000,Max=380.000000)
         DetermineEndPointBy=PTEP_Distance
         LowFrequencyNoiseRange=(X=(Min=-40.000000,Max=40.000000),Y=(Min=-40.000000,Max=40.000000),Z=(Min=-40.000000,Max=40.000000))
         HighFrequencyNoiseRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=-10.000000,Max=10.000000))
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         FadeOut=True
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
         ColorMultiplierRange=(X=(Min=0.600000,Max=0.750000),Y=(Min=1.000000,Max=1.000000),Z=(Min=0.700000,Max=0.850000))
         FadeOutStartTime=0.100000
         MaxParticles=14
         StartSizeRange=(X=(Min=10.000000,Max=18.000000),Y=(Min=10.000000,Max=18.000000),Z=(Min=10.000000,Max=18.000000))
         InitialParticlesPerSecond=40.000000
         Texture=Texture'EpicParticles.Beams.HotBolt04aw'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.150000,Max=0.300000)
         StartVelocityRange=(X=(Min=-1.000000,Max=1.000000),Y=(Min=-1.000000,Max=1.000000),Z=(Min=-0.300000,Max=1.000000))
     End Object
     Emitters(4)=BeamEmitter'KFMod.KFBFGBlastFX.BlastArcs'

     Begin Object Class=SpriteEmitter Name=BlastSmoke
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         Acceleration=(Z=40.000000)
         ColorScale(0)=(Color=(B=38,G=40,R=36,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=48,G=50,R=46,A=255))
         UseColorScale=True
         Opacity=0.650000
         FadeOutStartTime=1.200000
         FadeInEndTime=0.300000
         MaxParticles=10
         StartLocationRange=(X=(Min=-40.000000,Max=40.000000),Y=(Min=-40.000000,Max=40.000000),Z=(Min=0.000000,Max=60.000000))
         SpinsPerSecondRange=(X=(Min=-0.080000,Max=0.080000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.600000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.000000)
         StartSizeRange=(X=(Min=90.000000,Max=140.000000))
         InitialParticlesPerSecond=12.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         UseRandomSubdivision=True
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=2.400000,Max=3.400000)
         InitialDelayRange=(Min=0.150000,Max=0.300000)
         StartVelocityRange=(X=(Min=-60.000000,Max=60.000000),Y=(Min=-60.000000,Max=60.000000),Z=(Min=20.000000,Max=90.000000))
     End Object
     Emitters(5)=SpriteEmitter'KFMod.KFBFGBlastFX.BlastSmoke'

     LightType=LT_Steady
     LightHue=85
     LightSaturation=60
     LightBrightness=255.000000
     LightRadius=36.000000
     bDynamicLight=True
     AutoDestroy=True
     bNoDelete=False
     bNotOnDedServer=False
     RemoteRole=ROLE_None
     LifeSpan=6.000000
}
