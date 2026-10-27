//=============================================================================
// KFZapCrawl
// One stretch of current crawling over a floor (KFZapConduct): a thin bolt hugging the floor from here to an end,
// flickering out at once, sparks spitting where it ends.
//=============================================================================
class KFZapCrawl extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx

simulated function Span( vector Start, vector End, bool bSparks )
{
	local int i;
	local rangevector R;

	SetLocation(Start);
	SetRotation(rot(0,0,0));
	R.X.Min = End.X - Start.X;
	R.X.Max = R.X.Min;
	R.Y.Min = End.Y - Start.Y;
	R.Y.Max = R.Y.Min;
	R.Z.Min = End.Z - Start.Z;
	R.Z.Max = R.Z.Min;
	for ( i=0; i<Emitters.Length; i++ )
		if ( BeamEmitter(Emitters[i]) != None )
			BeamEmitter(Emitters[i]).BeamEndPoints[0].Offset = R;
	Emitters[2].StartLocationOffset = End - Start;
	if ( !bSparks )
		Emitters[2].Disabled = true;
}

defaultproperties
{
     Begin Object Class=BeamEmitter Name=CrawlCore
         BeamEndPoints(0)=(Weight=1.000000)
         DetermineEndPointBy=PTEP_Offset
         BeamTextureUScale=3.000000
         LowFrequencyNoiseRange=(X=(Min=-14.000000,Max=14.000000),Y=(Min=-14.000000,Max=14.000000),Z=(Min=0.000000,Max=7.000000))
         LowFrequencyPoints=4
         HighFrequencyNoiseRange=(X=(Min=-5.000000,Max=5.000000),Y=(Min=-5.000000,Max=5.000000),Z=(Min=0.000000,Max=4.000000))
         HighFrequencyPoints=8
         UseColorScale=True
         FadeOut=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=255,G=230,R=200,A=255))
         ColorScale(1)=(RelativeTime=0.500000,Color=(B=255,G=190,R=120,A=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=255,G=120,R=40,A=255))
         FadeOutStartTime=0.040000
         CoordinateSystem=PTCS_Relative
         MaxParticles=4
         StartSizeRange=(X=(Min=6.000000,Max=10.000000),Y=(Min=6.000000,Max=10.000000),Z=(Min=6.000000,Max=10.000000))
         InitialParticlesPerSecond=40.000000
         Texture=Texture'EpicParticles.Beams.HotBolt03aw'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.150000,Max=0.300000)
     End Object
     Emitters(0)=BeamEmitter'KFMod.KFZapCrawl.CrawlCore'

     Begin Object Class=BeamEmitter Name=CrawlGlow
         BeamEndPoints(0)=(Weight=1.000000)
         DetermineEndPointBy=PTEP_Offset
         FadeOut=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
         ColorMultiplierRange=(X=(Min=0.080000,Max=0.080000),Y=(Min=0.200000,Max=0.200000),Z=(Min=0.450000,Max=0.450000))
         FadeOutStartTime=0.040000
         CoordinateSystem=PTCS_Relative
         MaxParticles=1
         StartSizeRange=(X=(Min=26.000000,Max=26.000000),Y=(Min=26.000000,Max=26.000000),Z=(Min=26.000000,Max=26.000000))
         InitialParticlesPerSecond=40.000000
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.180000,Max=0.180000)
     End Object
     Emitters(1)=BeamEmitter'KFMod.KFZapCrawl.CrawlGlow'

     Begin Object Class=SpriteEmitter Name=CrawlSparks
         UseDirectionAs=PTDU_Up
         UseColorScale=True
         ScaleSizeYByVelocity=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         Acceleration=(Z=-900.000000)
         ColorScale(0)=(Color=(B=255,G=245,R=230))
         ColorScale(1)=(RelativeTime=0.400000,Color=(B=255,G=200,R=140))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=120,G=40,R=10))
         MaxParticles=10
         StartSizeRange=(X=(Min=0.600000,Max=1.100000),Y=(Min=0.600000,Max=1.100000))
         ScaleSizeByVelocityMultiplier=(Y=0.004000)
         InitialParticlesPerSecond=300.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'AW-2004Particles.Energy.SparkHead'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.250000,Max=0.600000)
         StartVelocityRange=(X=(Min=-280.000000,Max=280.000000),Y=(Min=-280.000000,Max=280.000000),Z=(Min=80.000000,Max=420.000000))
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFZapCrawl.CrawlSparks'

     AutoDestroy=True
     bNoDelete=False
     bNotOnDedServer=False
     RemoteRole=ROLE_None
     LifeSpan=1.500000
}
