//=============================================================================
// KFGoreSuckFX
// The Gore Cannon's vacuum as seen and heard: streaks of air and a faint haze rushing into the barrel's mouth from in
// front of it, and a rushing roar. Fed every tick while it runs (Feed); it stops by itself when it is not.
//=============================================================================
class KFGoreSuckFX extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx
#exec OBJ LOAD FILE=..\Sounds\IndoorAmbience.uax

var bool	bOn;
var float	LastFeed;
var() float	StreakRate, HazeRate;

simulated function Feed( vector At, rotator Aim )
{
	SetLocation(At);
	SetRotation(Aim);
	LastFeed = Level.TimeSeconds;
	if ( !bOn )
	{
		bOn = true;
		Rates(StreakRate, HazeRate);
		AmbientSound = default.AmbientSound;
	}
}

simulated function Rates( float Streaks, float Haze )
{
	Emitters[0].ParticlesPerSecond = Streaks;
	Emitters[0].InitialParticlesPerSecond = Streaks;
	Emitters[1].ParticlesPerSecond = Haze;
	Emitters[1].InitialParticlesPerSecond = Haze;
	if ( Streaks > 0 )
	{
		Emitters[0].AllParticlesDead = false;
		Emitters[1].AllParticlesDead = false;
	}
}

simulated function Tick( float DT )
{
	if ( bOn && Level.TimeSeconds - LastFeed > 0.15 )
	{
		bOn = false;
		Rates(0, 0);
		AmbientSound = None;
	}
}

defaultproperties
{
     StreakRate=130.000000
     HazeRate=16.000000

     Begin Object Class=SpriteEmitter Name=SuckStreaks
         UseDirectionAs=PTDU_Up
         FadeOut=True
         FadeIn=True
         FadeOutStartTime=0.200000
         FadeInEndTime=0.080000
         RespawnDeadParticles=False
         ScaleSizeYByVelocity=True
         CoordinateSystem=PTCS_Relative
         ColorMultiplierRange=(X=(Min=0.800000,Max=0.950000),Y=(Min=0.750000,Max=0.900000),Z=(Min=0.720000,Max=0.880000))
         MaxParticles=70
         StartLocationRange=(X=(Min=180.000000,Max=520.000000),Y=(Min=-220.000000,Max=220.000000),Z=(Min=-160.000000,Max=160.000000))
         StartSizeRange=(X=(Min=2.000000,Max=3.400000),Y=(Min=2.000000,Max=3.400000))
         ScaleSizeByVelocityMultiplier=(Y=0.020000)
         ParticlesPerSecond=0.000000
         InitialParticlesPerSecond=0.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.280000,Max=0.380000)
         StartVelocityRadialRange=(Min=-1400.000000,Max=-1000.000000)
         GetVelocityDirectionFrom=PTVD_AddRadial
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFGoreSuckFX.SuckStreaks'

     Begin Object Class=SpriteEmitter Name=SuckHaze
         FadeOut=True
         FadeIn=True
         FadeOutStartTime=0.300000
         FadeInEndTime=0.150000
         RespawnDeadParticles=False
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         UseRandomSubdivision=True
         CoordinateSystem=PTCS_Relative
         ColorMultiplierRange=(X=(Min=0.500000,Max=0.600000),Y=(Min=0.450000,Max=0.550000),Z=(Min=0.420000,Max=0.520000))
         Opacity=0.280000
         MaxParticles=10
         StartLocationRange=(X=(Min=200.000000,Max=480.000000),Y=(Min=-160.000000,Max=160.000000),Z=(Min=-110.000000,Max=110.000000))
         StartSpinRange=(X=(Max=1.000000))
         SpinsPerSecondRange=(X=(Min=-0.300000,Max=0.300000))
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=0.300000)
         StartSizeRange=(X=(Min=40.000000,Max=70.000000))
         ParticlesPerSecond=0.000000
         InitialParticlesPerSecond=0.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.450000,Max=0.600000)
         StartVelocityRadialRange=(Min=-750.000000,Max=-550.000000)
         GetVelocityDirectionFrom=PTVD_AddRadial
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFGoreSuckFX.SuckHaze'

     AmbientSound=Sound'IndoorAmbience.hiss1'
     SoundPitch=40
     SoundVolume=220
     SoundRadius=300.000000
     bNoDelete=False
     RemoteRole=ROLE_None
}
