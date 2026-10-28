// The King Fleshpound's chest beam (ZombieKingFleshpound): a red-hot line from its chest to what it burns, spanned each tick
class KFKingBeamFX extends Emitter;

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
     Begin Object Class=BeamEmitter Name=KingBeamCore
         BeamDistanceRange=(Min=500.000000,Max=500.000000)
         BeamEndPoints(0)=(Weight=1.000000)
         DetermineEndPointBy=PTEP_Offset
         BeamTextureUScale=4.000000
         HighFrequencyNoiseRange=(X=(Min=-1.500000,Max=1.500000),Y=(Min=-1.500000,Max=1.500000),Z=(Min=-1.500000,Max=1.500000))
         HighFrequencyPoints=10
         UseColorScale=True
         ColorScale(0)=(Color=(B=200,G=230,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=150,G=200,R=255,A=255))
         CoordinateSystem=PTCS_Relative
         MaxParticles=3
         StartSizeRange=(X=(Min=9.000000,Max=12.000000),Y=(Min=9.000000,Max=12.000000),Z=(Min=9.000000,Max=12.000000))
         Texture=Texture'EpicParticles.Beams.BeamFalloff'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.050000,Max=0.050000)
     End Object
     Emitters(0)=BeamEmitter'KFMod.KFKingBeamFX.KingBeamCore'

     Begin Object Class=BeamEmitter Name=KingBeamGlow
         BeamDistanceRange=(Min=500.000000,Max=500.000000)
         BeamEndPoints(0)=(Weight=1.000000)
         DetermineEndPointBy=PTEP_Offset
         BeamTextureUScale=2.000000
         LowFrequencyNoiseRange=(X=(Min=-4.000000,Max=4.000000),Y=(Min=-4.000000,Max=4.000000),Z=(Min=-4.000000,Max=4.000000))
         LowFrequencyPoints=4
         UseColorScale=True
         ColorScale(0)=(Color=(B=30,G=50,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=10,G=20,R=220,A=255))
         CoordinateSystem=PTCS_Relative
         MaxParticles=3
         StartSizeRange=(X=(Min=34.000000,Max=46.000000),Y=(Min=34.000000,Max=46.000000),Z=(Min=34.000000,Max=46.000000))
         Texture=Texture'EpicParticles.Beams.BeamFalloff'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.060000,Max=0.060000)
     End Object
     Emitters(1)=BeamEmitter'KFMod.KFKingBeamFX.KingBeamGlow'

     LightType=LT_Steady
     LightHue=0
     LightSaturation=40
     LightBrightness=180.000000
     LightRadius=12.000000
     bDynamicLight=True
     bNoDelete=False
     RemoteRole=ROLE_None
}
