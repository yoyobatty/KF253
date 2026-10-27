//=============================================================================
// KFRailSpiral
// The railgun's line (KFRailBeam.Lay): the core and glow drawn as beams from one end to the other, and the rings of
// the spiral laid one by one along it, each drifting out from the line and fading.
//=============================================================================
class KFRailSpiral extends Emitter;

#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx

var() float	RingEvery, SpiralRadius, TurnPerRing, DriftSpeed;

var vector	StartP, EndP;
var int		Stage;		// 1: to be thrown (its first update); 2: the rings to be laid on the spiral (its second)
var int		RingCount;

// Where it runs; thrown in its first update (what an emitter throws before then is lost)
simulated function Lay( vector Start, vector End )
{
	StartP = Start;
	EndP = End;
	Stage = 1;
	SetLocation(Start);
	SetRotation(rot(0,0,0));
}

simulated function Tick( float DT )
{
	if ( Stage == 1 )
	{
		Stage = 2;
		Throw(StartP, EndP);
	}
	else if ( Stage == 2 )
	{
		Stage = 0;
		Coil(StartP, EndP);
	}
}

// The core and glow beams, and the rings (all at the muzzle for now: one spawn call takes one start for all)
simulated function Throw( vector Start, vector End )
{
	local rangevector R;

	R.X.Min = End.X - Start.X;
	R.X.Max = R.X.Min;
	R.Y.Min = End.Y - Start.Y;
	R.Y.Max = R.Y.Min;
	R.Z.Min = End.Z - Start.Z;
	R.Z.Max = R.Z.Min;
	BeamEmitter(Emitters[0]).BeamEndPoints[0].Offset = R;
	BeamEmitter(Emitters[1]).BeamEndPoints[0].Offset = R;
	Emitters[0].SpawnParticle(1);
	Emitters[1].SpawnParticle(1);
	RingCount = Min(int(VSize(End - Start) / RingEvery), Emitters[2].MaxParticles);
	Emitters[2].SpawnParticle(RingCount);
}

// Each ring put in its place on the spiral round the line, drifting out from it
simulated function Coil( vector Start, vector End )
{
	local vector X, Y, Z, Out, P;
	local float L, A, D;
	local int i, k;

	L = VSize(End - Start);
	X = (End - Start) / FMax(L, 1.0);
	Y = Normal(X cross vect(0,0,1));
	if ( VSize(Y) < 0.1 )
		Y = Normal(X cross vect(0,1,0));
	Z = Y cross X;
	for ( i = 0; i < Emitters[2].Particles.Length; i++ )
	{
		if ( (Emitters[2].Particles[i].Flags & 1) == 0 )
			continue;
		D = 8.0 + float(k) * RingEvery;
		A = float(k) * TurnPerRing;
		Out = Y * Cos(A) + Z * Sin(A);
		P = Start + X * D + Out * SpiralRadius;
		Emitters[2].Particles[i].Location = P;
		Emitters[2].Particles[i].OldLocation = P;
		Emitters[2].Particles[i].Velocity = Out * DriftSpeed;
		k++;
	}
}

defaultproperties
{
     RingEvery=7.000000
     SpiralRadius=6.500000
     TurnPerRing=0.550000
     DriftSpeed=7.000000

     Begin Object Class=BeamEmitter Name=RailCore
         BeamEndPoints(0)=(Weight=1.000000)
         DetermineEndPointBy=PTEP_Offset
         UseColorScale=True
         FadeOut=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=255,G=250,R=245,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=170,R=110,A=255))
         FadeOutStartTime=0.150000
         MaxParticles=1
         StartSizeRange=(X=(Min=3.500000,Max=3.500000),Y=(Min=3.500000,Max=3.500000),Z=(Min=3.500000,Max=3.500000))
         Texture=Texture'EpicParticles.Beams.BeamFalloff'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.700000,Max=0.700000)
     End Object
     Emitters(0)=BeamEmitter'KFMod.KFRailSpiral.RailCore'

     Begin Object Class=BeamEmitter Name=RailGlow
         BeamEndPoints(0)=(Weight=1.000000)
         DetermineEndPointBy=PTEP_Offset
         FadeOut=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
         ColorMultiplierRange=(X=(Min=0.150000,Max=0.150000),Y=(Min=0.400000,Max=0.400000),Z=(Min=0.850000,Max=0.850000))
         FadeOutStartTime=0.100000
         MaxParticles=1
         StartSizeRange=(X=(Min=14.000000,Max=14.000000),Y=(Min=14.000000,Max=14.000000),Z=(Min=14.000000,Max=14.000000))
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.900000,Max=0.900000)
     End Object
     Emitters(1)=BeamEmitter'KFMod.KFRailSpiral.RailGlow'

     Begin Object Class=SpriteEmitter Name=RailRings
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ColorScale(0)=(Color=(B=255,G=235,R=200,A=255))
         ColorScale(1)=(RelativeTime=0.400000,Color=(B=255,G=150,R=60,A=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=120,G=40,R=10,A=255))
         FadeOutStartTime=0.400000
         FadeInEndTime=0.060000
         MaxParticles=900
         SizeScale(0)=(RelativeSize=0.700000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.600000)
         StartSizeRange=(X=(Min=4.500000,Max=5.500000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=1.600000,Max=2.000000)
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFRailSpiral.RailRings'

     AutoDestroy=True
     bNoDelete=False
     bNotOnDedServer=False
     RemoteRole=ROLE_None
     LifeSpan=3.000000
}
