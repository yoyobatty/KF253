//=============================================================================
// KFBFGBolt
// One of the BFG's tracers as seen (KFBFGSpray): a green bolt from the blast to a specimen the tracers struck, a
// copy of KFArcBolt's in its colour.
//=============================================================================
class KFBFGBolt extends Emitter;

#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx

simulated function Span( vector Start, vector End, float Thick )
{
	local int i;
	local rangevector R;
	local float L;

	SetLocation(Start);
	SetRotation(rot(0,0,0));
	R.X.Min = End.X - Start.X;
	R.X.Max = R.X.Min;
	R.Y.Min = End.Y - Start.Y;
	R.Y.Max = R.Y.Min;
	R.Z.Min = End.Z - Start.Z;
	R.Z.Max = R.Z.Min;
	L = FClamp(VSize(End - Start) / 600.0, 0.3, 2.5);
	for ( i=0; i<Emitters.Length; i++ )
	{
		if ( BeamEmitter(Emitters[i]) != None )
		{
			if ( BeamEmitter(Emitters[i]).BeamEndPoints.Length > 0 )
				BeamEmitter(Emitters[i]).BeamEndPoints[0].Offset = R;
			BeamEmitter(Emitters[i]).LowFrequencyNoiseRange.X.Min *= L;
			BeamEmitter(Emitters[i]).LowFrequencyNoiseRange.X.Max *= L;
			BeamEmitter(Emitters[i]).LowFrequencyNoiseRange.Y.Min *= L;
			BeamEmitter(Emitters[i]).LowFrequencyNoiseRange.Y.Max *= L;
			BeamEmitter(Emitters[i]).LowFrequencyNoiseRange.Z.Min *= L;
			BeamEmitter(Emitters[i]).LowFrequencyNoiseRange.Z.Max *= L;
		}
		Emitters[i].StartSizeRange.X.Min *= Thick;
		Emitters[i].StartSizeRange.X.Max *= Thick;
		Emitters[i].StartSizeRange.Y.Min *= Thick;
		Emitters[i].StartSizeRange.Y.Max *= Thick;
		Emitters[i].StartSizeRange.Z.Min *= Thick;
		Emitters[i].StartSizeRange.Z.Max *= Thick;
	}
}

defaultproperties
{
     Begin Object Class=BeamEmitter Name=BoltCore
         BeamEndPoints(0)=(Weight=1.000000)
         DetermineEndPointBy=PTEP_Offset
         BeamTextureUScale=4.000000
         LowFrequencyNoiseRange=(X=(Min=-45.000000,Max=45.000000),Y=(Min=-45.000000,Max=45.000000),Z=(Min=-45.000000,Max=45.000000))
         LowFrequencyPoints=7
         HighFrequencyNoiseRange=(X=(Min=-12.000000,Max=12.000000),Y=(Min=-12.000000,Max=12.000000),Z=(Min=-12.000000,Max=12.000000))
         HighFrequencyPoints=14
         UseBranching=True
         BranchProbability=(Min=0.400000,Max=0.400000)
         BranchEmitter=1
         BranchSpawnAmountRange=(Min=1.000000,Max=2.000000)
         LinkupLifetime=True
         UseColorScale=True
         FadeOut=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=250,G=255,R=245,A=255))
         ColorScale(1)=(RelativeTime=0.300000,Color=(B=215,G=255,R=190,A=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=140,G=255,R=90,A=255))
         FadeOutStartTime=0.080000
         CoordinateSystem=PTCS_Relative
         MaxParticles=3
         StartSizeRange=(X=(Min=26.000000,Max=34.000000),Y=(Min=26.000000,Max=34.000000),Z=(Min=26.000000,Max=34.000000))
         InitialParticlesPerSecond=200.000000
         Texture=Texture'EpicParticles.Beams.HotBolt03aw'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.220000,Max=0.320000)
     End Object
     Emitters(0)=BeamEmitter'KFMod.KFBFGBolt.BoltCore'

     Begin Object Class=BeamEmitter Name=BoltFork
         BeamDistanceRange=(Min=60.000000,Max=220.000000)
         DetermineEndPointBy=PTEP_Distance
         LowFrequencyNoiseRange=(X=(Min=-30.000000,Max=30.000000),Y=(Min=-30.000000,Max=30.000000),Z=(Min=-30.000000,Max=30.000000))
         HighFrequencyNoiseRange=(X=(Min=-8.000000,Max=8.000000),Y=(Min=-8.000000,Max=8.000000),Z=(Min=-8.000000,Max=8.000000))
         FadeOut=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
         ColorMultiplierRange=(X=(Min=0.550000,Max=0.550000),Y=(Min=1.000000,Max=1.000000),Z=(Min=0.650000,Max=0.650000))
         FadeOutStartTime=0.050000
         CoordinateSystem=PTCS_Relative
         MaxParticles=12
         StartSizeRange=(X=(Min=8.000000,Max=14.000000),Y=(Min=8.000000,Max=14.000000),Z=(Min=8.000000,Max=14.000000))
         Texture=Texture'EpicParticles.Beams.HotBolt04aw'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.150000,Max=0.250000)
         StartVelocityRange=(X=(Min=-1.000000,Max=1.000000),Y=(Min=-1.000000,Max=1.000000),Z=(Min=-1.000000,Max=1.000000))
     End Object
     Emitters(1)=BeamEmitter'KFMod.KFBFGBolt.BoltFork'

     Begin Object Class=BeamEmitter Name=BoltGlow
         BeamEndPoints(0)=(Weight=1.000000)
         DetermineEndPointBy=PTEP_Offset
         FadeOut=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
         ColorMultiplierRange=(X=(Min=0.200000,Max=0.200000),Y=(Min=0.750000,Max=0.750000),Z=(Min=0.350000,Max=0.350000))
         FadeOutStartTime=0.100000
         CoordinateSystem=PTCS_Relative
         MaxParticles=1
         StartSizeRange=(X=(Min=90.000000,Max=90.000000),Y=(Min=90.000000,Max=90.000000),Z=(Min=90.000000,Max=90.000000))
         InitialParticlesPerSecond=200.000000
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.450000,Max=0.450000)
     End Object
     Emitters(2)=BeamEmitter'KFMod.KFBFGBolt.BoltGlow'

     AutoDestroy=True
     bNoDelete=False
     bNotOnDedServer=False
     RemoteRole=ROLE_None
     LifeSpan=2.000000
}
