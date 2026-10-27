//=============================================================================
// KFArcCharge
// (Blue Inferno) The charge building at the nozzle while its alternate fire is held (FlameAltFire): sparks drawn in to
// the nozzle, arcs crackling off it, a ball of blue light growing, a rising whine. FlameThrowerAttachment feeds it the
// charge (SetCharge) on each machine that draws it.
//=============================================================================
class KFArcCharge extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx
#exec OBJ LOAD FILE=..\Sounds\WeaponSounds.uax

var float	Charge;
var bool	bStarted;
var float	ViewScale;		// smaller at the nozzle of its holder's own first-person view, right before the eyes

simulated function SetCharge( float C )
{
	Charge = FClamp(C, 0.0, 1.0);
	if ( !bStarted )
	{
		bStarted = true;
		PlaySound(Sound'WeaponSounds.LightningGun.LightningGunChargeUp', SLOT_None, 1.4,, 900, 1.0);
	}
	Emitters[0].ParticlesPerSecond = 20 + 70 * Charge;
	Emitters[0].InitialParticlesPerSecond = Emitters[0].ParticlesPerSecond;
	Emitters[1].ParticlesPerSecond = 6 + 26 * Charge;
	Emitters[1].InitialParticlesPerSecond = Emitters[1].ParticlesPerSecond;
	Emitters[1].StartSizeRange.X.Min = (3 + 5 * Charge) * ViewScale;
	Emitters[1].StartSizeRange.X.Max = (5 + 7 * Charge) * ViewScale;
	BeamEmitter(Emitters[1]).BeamDistanceRange.Min = 25 * ViewScale;
	BeamEmitter(Emitters[1]).BeamDistanceRange.Max = (40 + 40 * Charge) * ViewScale;
	Emitters[2].StartSizeRange.X.Min = (10 + 50 * Charge) * ViewScale;
	Emitters[2].StartSizeRange.X.Max = (14 + 60 * Charge) * ViewScale;
	Emitters[0].SphereRadiusRange.Min = 40 * ViewScale;
	Emitters[0].SphereRadiusRange.Max = 70 * ViewScale;
	Emitters[0].StartVelocityRadialRange.Min = -260 * ViewScale;
	Emitters[0].StartVelocityRadialRange.Max = -200 * ViewScale;
	Emitters[0].StartSizeRange.X.Min = 1.5 * ViewScale;
	Emitters[0].StartSizeRange.X.Max = 3.0 * ViewScale;
	SoundPitch = byte(40 + 60 * Charge);
	SoundVolume = byte(120 + 135 * Charge);
	LightBrightness = 40 + 160 * Charge;
	LightRadius = 3 + 5 * Charge;
}

simulated function Fade()
{
	local int i;

	AmbientSound = None;
	LightType = LT_None;
	for ( i=0; i<Emitters.Length; i++ )
	{
		Emitters[i].ParticlesPerSecond = 0;
		Emitters[i].InitialParticlesPerSecond = 0;
		Emitters[i].RespawnDeadParticles = false;
	}
	LifeSpan = 1.0;
}

simulated function Tick( float DT )
{
	if ( Instigator == None || Instigator.Health <= 0 )
	{
		if ( AmbientSound != None )
			Fade();
		return;
	}
	SetLocation(class'KFArcFlash'.static.NozzleOf(Instigator));
	ViewScale = 1.0;
	if ( FlameThrower(Instigator.Weapon) != None && Level.TimeSeconds - FlameThrower(Instigator.Weapon).DrawnNozzleTime < 0.1 )
		ViewScale = 0.18;
}

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=ChargeGather
         UseColorScale=True
         FadeIn=True
         UniformSize=True
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=255,G=200,R=150,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=250,R=240,A=255))
         FadeInEndTime=0.100000
         CoordinateSystem=PTCS_Relative
         MaxParticles=40
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Min=40.000000,Max=70.000000)
         StartSizeRange=(X=(Min=1.500000,Max=3.000000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.220000,Max=0.300000)
         StartVelocityRadialRange=(Min=-260.000000,Max=-200.000000)
         GetVelocityDirectionFrom=PTVD_AddRadial
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFArcCharge.ChargeGather'

     Begin Object Class=BeamEmitter Name=ChargeArcs
         BeamDistanceRange=(Min=25.000000,Max=70.000000)
         DetermineEndPointBy=PTEP_Distance
         LowFrequencyNoiseRange=(X=(Min=-14.000000,Max=14.000000),Y=(Min=-14.000000,Max=14.000000),Z=(Min=-14.000000,Max=14.000000))
         HighFrequencyNoiseRange=(X=(Min=-4.000000,Max=4.000000),Y=(Min=-4.000000,Max=4.000000),Z=(Min=-4.000000,Max=4.000000))
         FadeOut=True
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
         ColorMultiplierRange=(X=(Min=0.550000,Max=0.750000),Y=(Min=0.700000,Max=0.850000),Z=(Min=1.000000,Max=1.000000))
         FadeOutStartTime=0.030000
         CoordinateSystem=PTCS_Relative
         MaxParticles=12
         StartSizeRange=(X=(Min=3.000000,Max=5.000000),Y=(Min=3.000000,Max=5.000000),Z=(Min=3.000000,Max=5.000000))
         Texture=Texture'EpicParticles.Beams.HotBolt04aw'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.060000,Max=0.120000)
         StartVelocityRange=(X=(Min=-1.000000,Max=1.000000),Y=(Min=-1.000000,Max=1.000000),Z=(Min=-1.000000,Max=1.000000))
     End Object
     Emitters(1)=BeamEmitter'KFMod.KFArcCharge.ChargeArcs'

     Begin Object Class=SpriteEmitter Name=ChargeCore
         UseColorScale=True
         UniformSize=True
         ColorScale(0)=(Color=(B=255,G=230,R=200,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=150,R=80,A=255))
         CoordinateSystem=PTCS_Relative
         MaxParticles=3
         StartSizeRange=(X=(Min=10.000000,Max=14.000000))
         ParticlesPerSecond=30.000000
         InitialParticlesPerSecond=30.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.080000,Max=0.100000)
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFArcCharge.ChargeCore'

     ViewScale=1.000000
     AmbientSound=Sound'KFMod.Zap.ZapLoop'
     SoundRadius=500.000000
     SoundVolume=120
     SoundPitch=40
     LightType=LT_Steady
     LightHue=165
     LightSaturation=80
     LightBrightness=40.000000
     LightRadius=3.000000
     bDynamicLight=True
     bNoDelete=False
     bNotOnDedServer=False
     RemoteRole=ROLE_None
}
