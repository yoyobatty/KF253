// The upgraded flamethrower's loose lightning while it fires: bolts crackling off the nozzle ahead, whether or not there is
// anything to strike (the Ballistic Weapons HVC Mk9's free zaps), and the lightning's sound. KFFlameStream keeps it at the
// nozzle, aimed along the stream.
class KFZapFree extends Emitter;

#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\ZapLoop.wav NAME=ZapLoop GROUP=Zap
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\ZapStart.wav NAME=ZapStart GROUP=Zap
#exec AUDIO IMPORT FILE=..\KFMod254\KFMod\Sounds\ZapFlesh.wav NAME=ZapFlesh GROUP=Zap

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	PlaySound(Sound'KFMod.Zap.ZapStart', SLOT_None, 1.0,, 400);
	Point();
}

// The bolts go off along the nozzle's line, spread round it
simulated function Point()
{
	local vector X, Y, Z;
	local rangevector R;

	GetAxes(Rotation, X, Y, Z);
	R.X.Min = X.X - 0.5;
	R.X.Max = X.X + 0.5;
	R.Y.Min = X.Y - 0.5;
	R.Y.Max = X.Y + 0.5;
	R.Z.Min = X.Z - 0.4;
	R.Z.Max = X.Z + 0.4;
	Emitters[0].StartVelocityRange = R;
}

// Its sound stops, and its bolts are left to fade
simulated function Stop()
{
	AmbientSound = None;
	Kill();
}

defaultproperties
{
     Begin Object Class=BeamEmitter Name=FreeBolt
         BeamDistanceRange=(Min=220.000000,Max=480.000000)
         DetermineEndPointBy=PTEP_Distance
         BeamTextureUScale=4.000000
         RotatingSheets=2
         LowFrequencyNoiseRange=(X=(Min=-60.000000,Max=60.000000),Y=(Min=-60.000000,Max=60.000000),Z=(Min=-60.000000,Max=60.000000))
         HighFrequencyNoiseRange=(X=(Min=-15.000000,Max=15.000000),Y=(Min=-15.000000,Max=15.000000),Z=(Min=-15.000000,Max=15.000000))
         NoiseDeterminesEndPoint=True
         UseColorScale=True
         FadeOut=True
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=0.685714,Color=(B=255,G=128,R=32,A=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=255,G=128,A=255))
         ColorMultiplierRange=(X=(Min=0.800000),Y=(Min=0.900000))
         FadeOutStartTime=0.088000
         MaxParticles=3
         StartSizeRange=(X=(Min=5.000000,Max=7.000000),Y=(Min=5.000000,Max=7.000000),Z=(Min=5.000000,Max=7.000000))
         Texture=Texture'EpicParticles.Beams.HotBolt03aw'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.150000,Max=0.250000)
         StartVelocityRange=(X=(Min=0.500000,Max=1.500000),Y=(Min=-0.500000,Max=0.500000),Z=(Min=-0.400000,Max=0.400000))
     End Object
     Emitters(0)=BeamEmitter'KFMod.KFZapFree.FreeBolt'

     AutoDestroy=True
     bNoDelete=False
     bNotOnDedServer=False
     AmbientSound=Sound'KFMod.Zap.ZapLoop'
     SoundVolume=200
     SoundRadius=300.000000
}
