// A green bolt from the BFG's ball to a specimen near its path (BFGBall), a copy of KFZapBeam's in its colour. BFGBall
// spans it each tick.
class KFBFGBeam extends Emitter;

simulated function Span( vector Start, vector End )
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
}

defaultproperties
{
     Begin Object Class=BeamEmitter Name=ZapCore
         BeamDistanceRange=(Min=500.000000,Max=500.000000)
         BeamEndPoints(0)=(offset=(Z=(Min=-20.000000,Max=20.000000)),Weight=1.000000)
         DetermineEndPointBy=PTEP_Offset
         BeamTextureUScale=6.000000
         LowFrequencyNoiseRange=(X=(Min=-30.000000,Max=30.000000),Y=(Min=-30.000000,Max=30.000000),Z=(Min=-30.000000,Max=30.000000))
         LowFrequencyPoints=5
         HighFrequencyNoiseRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=-10.000000,Max=10.000000))
         UseBranching=True
         BranchProbability=(Min=0.200000,Max=0.200000)
         BranchEmitter=1
         BranchSpawnAmountRange=(Min=1.000000,Max=1.000000)
         LinkupLifetime=True
         UseColorScale=True
         FadeOut=True
         UseSizeScale=True
         UseRegularSizeScale=False
         ColorScale(0)=(Color=(B=224,G=255,R=192,A=255))
         ColorScale(1)=(RelativeTime=0.428571,Color=(B=192,G=255,R=128,A=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=128,G=255,A=255))
         FadeOutStartTime=0.032000
         CoordinateSystem=PTCS_Relative
         MaxParticles=8
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=0.170000,RelativeSize=0.500000)
         SizeScale(2)=(RelativeTime=1.000000,RelativeSize=0.500000)
         StartSizeRange=(X=(Min=8.000000,Max=13.000000),Y=(Min=8.000000,Max=13.000000),Z=(Min=8.000000,Max=13.000000))
         Texture=Texture'EpicParticles.Beams.HotBolt03aw'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.200000,Max=0.200000)
     End Object
     Emitters(0)=BeamEmitter'KFMod.KFBFGBeam.ZapCore'

     Begin Object Class=BeamEmitter Name=ZapWild
         BeamDistanceRange=(Min=1000.000000,Max=1000.000000)
         BeamEndPoints(0)=(offset=(Z=(Min=-50.000000,Max=50.000000)),Weight=1.000000)
         DetermineEndPointBy=PTEP_Offset
         LowFrequencyNoiseRange=(X=(Min=150.000000,Max=150.000000),Y=(Min=-150.000000,Max=150.000000),Z=(Min=-150.000000,Max=150.000000))
         HighFrequencyNoiseRange=(X=(Min=-30.000000,Max=30.000000),Y=(Min=-30.000000,Max=30.000000),Z=(Min=-30.000000,Max=30.000000))
         NoiseDeterminesEndPoint=True
         FadeOut=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
         ColorMultiplierRange=(X=(Min=0.450000,Max=0.450000),Y=(Min=0.850000,Max=0.850000),Z=(Min=0.450000,Max=0.450000))
         CoordinateSystem=PTCS_Relative
         MaxParticles=8
         StartSizeRange=(X=(Min=6.000000,Max=10.000000),Y=(Min=6.000000,Max=10.000000),Z=(Min=6.000000,Max=10.000000))
         Texture=Texture'EpicParticles.Beams.HotBolt04aw'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.200000,Max=0.200000)
     End Object
     Emitters(1)=BeamEmitter'KFMod.KFBFGBeam.ZapWild'

     Begin Object Class=BeamEmitter Name=ZapGlow
         BeamEndPoints(0)=(Weight=1.000000)
         DetermineEndPointBy=PTEP_Offset
         FadeOut=True
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
         ColorMultiplierRange=(X=(Min=0.100000,Max=0.100000),Y=(Min=0.550000,Max=0.550000),Z=(Min=0.250000,Max=0.250000))
         FadeOutStartTime=0.036000
         CoordinateSystem=PTCS_Relative
         MaxParticles=1
         StartSizeRange=(X=(Min=26.000000,Max=26.000000),Y=(Min=26.000000,Max=26.000000),Z=(Min=26.000000,Max=26.000000))
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.200000,Max=0.200000)
     End Object
     Emitters(2)=BeamEmitter'KFMod.KFBFGBeam.ZapGlow'

     AutoDestroy=True
     bNoDelete=False
     bNotOnDedServer=False
}
