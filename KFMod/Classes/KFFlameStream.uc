//=============================================================================
// KFFlameStream
// The flamethrower's stream as it is seen and heard, one at each flamethrower, on each machine that draws it. The
// tendrils that do the harm (FlameTendril) carry no picture of their own. FlameThrowerAttachment feeds it at each
// shot; it stops when the shots stop. In its holder's own first-person view the weapon puts it at the drawn nozzle
// (FlameThrower.RenderOverlays), otherwise it is at the third-person model's nozzle.
//=============================================================================
class KFFlameStream extends Emitter;

// Its parts (Emitters)
const E_CORE	= 0;	// white-hot fuel just out of the nozzle
const E_BODY	= 1;	// the stream, yellow to orange to deep red as it goes and swells
const E_LICK	= 2;	// licks of flame that drag behind it and billow
const E_SOOT	= 3;
const E_DRIP	= 4;	// burning drops falling off the arc
const E_FLARE	= 5;	// where a drop lands
const E_SPARK	= 6;	// the igniter
const E_PUFF	= 7;	// the last of the fuel at release
const E_SMOKE	= 8;

// Feeding
var bool	bOn, bReleasing;
var float	LastFeed, OnSince, OffSince, ReleaseAt;
var float	FeedTimeout;	// no shot for this long and it stops (a remote one's last shot can be lost)
var float	DribbleLeft;	// after release: drops still falling from the nozzle

// Where it starts and how the fuel flies (as a tendril does, FlameTendril)
var vector	Nozzle;
var rotator	Aim;
var float	Speed, Toss, Gravity, Flight;
var float	BodyDrag, LickDrag, SootDrag;	// speed lost a second, as a share
var float	BodySpeed, LickSpeed;
var float	CoreRate, BodyRate, LickRate, SootRate, DripRate;	// a second, while it burns

// Seen from the shooter's own eyes the whole stream lies over the aim: less of the outer fire and smoke there, dimmer
var bool	bFromEyes;
var float	EyesLickShare, EyesSootShare, EyesLickGlow, EyesBodyGlow;

// Where the stream fired at each moment stops: the splash follows a sweep as the fuel gets there
struct StreamSample
{
	var float	Time;
	var vector	Start, End, Normal;
	var float	Dist;		// along the stream to End
	var bool	bHit;		// stops at something there, else it burns out there
	var bool	bPawn;
};
var StreamSample	Samples[24];
var int		SampleHead, SampleCount;
var float	NextSample;

var KFFlameStreamEnd	EndFX;
var KFFlameStreamLight	Glow;
var float	LightUp, Flicker, FlickerTo, NextFlicker;

// Sound: the fire sound again before its tail, in the other slot, so it runs on; a crackle under it fades at release
var Sound	IgniteSound, RoarSound, StopSound, LoopSound;
var float	RoarAgain, NextRoar, RoarVolume, RoarRadius;
var bool	bRoarSlot;
var float	LoopLevel;
var byte	LoopVolume;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetFlight();
	PlaceAtNozzle();
}

simulated function Destroyed()
{
	if ( EndFX != None )
		EndFX.Destroy();
	if ( Glow != None )
		Glow.Destroy();
	Super.Destroyed();
}

// A shot: on, or kept on
simulated function Feed()
{
	LastFeed = Level.TimeSeconds;
	bReleasing = false;
	if ( !bOn )
		TurnOn();
}

// The trigger let go. Not at once: the shot count wraps through 0 while held.
simulated function Release()
{
	if ( bOn && !bReleasing )
	{
		bReleasing = true;
		ReleaseAt = Level.TimeSeconds + 0.1;
	}
}

// P, drawn with the first-person weapon at DrawFOV, as a place in the scene seen at SceneFOV that is in the same place on
// the screen, Depth ahead of the camera
static function vector OnSceneView( vector P, vector ViewLoc, rotator ViewRot, float DrawFOV, float SceneFOV, float Depth )
{
	local vector X, Y, Z, D;
	local float Ahead, K;

	GetAxes(ViewRot, X, Y, Z);
	D = P - ViewLoc;
	Ahead = FMax(D dot X, 1.0);
	K = Depth * Tan(SceneFOV * Pi / 360.0) / (Ahead * Tan(DrawFOV * Pi / 360.0));
	return ViewLoc + Depth * X + (D dot Y) * K * Y + (D dot Z) * K * Z;
}

static function float LaunchSpeed( float Dist, float Drag, float T )
{
	return Dist * Drag / (1.0 - Exp(-Drag * T));
}

// How long fuel set off at V, slowing by Drag a second, takes to go Dist; 0 if it never gets there
static function float TimeTo( float Dist, float V, float Drag )
{
	if ( Drag * Dist >= V * 0.999 )
		return 0;
	return -Loge(1.0 - Drag * Dist / V) / Drag;
}

// The holder's aim. A remote pawn has no controller here: its yaw, and the pitch sent for it.
static function rotator AimOf( Pawn P )
{
	local rotator R;

	if ( P.Controller != None )
		return P.GetViewRotation();
	R = P.Rotation;
	R.Pitch = int(P.ViewPitch) * 256;
	return R;
}

simulated function SetFlight()
{
	local float V;

	Speed = class'FlameTendril'.default.Speed;
	Toss = class'FlameTendril'.default.TossZ;
	Flight = class'FlameTendril'.static.FlightFor(Instigator);
	Gravity = -950;
	if ( Instigator != None && Instigator.PhysicsVolume != None )
		Gravity = Instigator.PhysicsVolume.Gravity.Z;

	Emitters[E_CORE].StartVelocityRange.X.Min = Speed;
	Emitters[E_CORE].StartVelocityRange.X.Max = Speed;

	BodySpeed = LaunchSpeed(Speed * Flight, BodyDrag, Flight);
	Emitters[E_BODY].StartVelocityRange.X.Min = BodySpeed * 0.98;
	Emitters[E_BODY].StartVelocityRange.X.Max = BodySpeed * 1.02;
	Emitters[E_BODY].StartVelocityRange.Z.Min = Toss * 0.85;
	Emitters[E_BODY].StartVelocityRange.Z.Max = Toss * 1.15;
	Emitters[E_BODY].Acceleration.Z = Gravity;
	Emitters[E_BODY].LifetimeRange.Min = Flight * 0.92;
	Emitters[E_BODY].LifetimeRange.Max = Flight;

	LickSpeed = LaunchSpeed(0.85 * Speed * Flight, LickDrag, Flight);
	Emitters[E_LICK].StartVelocityRange.X.Min = LickSpeed * 0.95;
	Emitters[E_LICK].StartVelocityRange.X.Max = LickSpeed * 1.05;
	Emitters[E_LICK].Acceleration.Z = Gravity * 0.45;
	Emitters[E_LICK].LifetimeRange.Min = Flight * 0.9;
	Emitters[E_LICK].LifetimeRange.Max = Flight * 1.05;

	// (the soot shows only once it has slowed, three quarters of the way out)
	V = 0.85 * Speed * Flight * SootDrag;
	Emitters[E_SOOT].StartVelocityRange.X.Min = V * 0.9;
	Emitters[E_SOOT].StartVelocityRange.X.Max = V * 1.1;
	Emitters[E_SOOT].FadeInEndTime = TimeTo(0.7 * Speed * Flight, V, SootDrag);

	SetDrips(false);
	Emitters[E_DRIP].Acceleration.Z = Gravity * 1.4;
}

simulated function SetDrips( bool bDribble )
{
	if ( bDribble )
	{
		Emitters[E_DRIP].StartVelocityRange.X.Min = 40;
		Emitters[E_DRIP].StartVelocityRange.X.Max = 160;
		Emitters[E_DRIP].StartVelocityRange.Z.Min = -20;
		Emitters[E_DRIP].StartVelocityRange.Z.Max = 20;
	}
	else
	{
		Emitters[E_DRIP].StartVelocityRange.X.Min = Speed * 0.5;
		Emitters[E_DRIP].StartVelocityRange.X.Max = Speed * 0.8;
		Emitters[E_DRIP].StartVelocityRange.Z.Min = 0;
		Emitters[E_DRIP].StartVelocityRange.Z.Max = Toss;
	}
}

// (an emitter whose particles have all died with no rate is no longer ticked: woken here)
simulated function Rate( int i, float PPS )
{
	Emitters[i].ParticlesPerSecond = PPS;
	Emitters[i].InitialParticlesPerSecond = PPS;
	if ( PPS > 0 )
		Emitters[i].AllParticlesDead = false;
}

simulated function bool SeenFromEyes()
{
	local PlayerController PC;

	PC = Level.GetLocalPlayerController();
	return PC != None && PC.ViewTarget == Instigator && !PC.bBehindView;
}

simulated function SetView()
{
	local float L, B;

	bFromEyes = SeenFromEyes();
	L = 1.0;
	B = 1.0;
	if ( bFromEyes )
	{
		L = EyesLickGlow;
		B = EyesBodyGlow;
	}
	Emitters[E_LICK].ColorMultiplierRange.X.Min = L;
	Emitters[E_LICK].ColorMultiplierRange.X.Max = L;
	Emitters[E_LICK].ColorMultiplierRange.Y.Min = 0.85 * L;
	Emitters[E_LICK].ColorMultiplierRange.Y.Max = L;
	Emitters[E_LICK].ColorMultiplierRange.Z.Min = 0.7 * L;
	Emitters[E_LICK].ColorMultiplierRange.Z.Max = L;
	Emitters[E_BODY].ColorMultiplierRange.X.Min = B;
	Emitters[E_BODY].ColorMultiplierRange.X.Max = B;
	Emitters[E_BODY].ColorMultiplierRange.Y.Min = 0.9 * B;
	Emitters[E_BODY].ColorMultiplierRange.Y.Max = B;
	Emitters[E_BODY].ColorMultiplierRange.Z.Min = 0.8 * B;
	Emitters[E_BODY].ColorMultiplierRange.Z.Max = B;
	// (the last of the fuel puffs out further, clear of the eyes)
	if ( bFromEyes )
	{
		Emitters[E_PUFF].StartVelocityRange.X.Min = 260;
		Emitters[E_PUFF].StartVelocityRange.X.Max = 420;
	}
	else
		Emitters[E_PUFF].StartVelocityRange.X = default.Emitters[E_PUFF].StartVelocityRange.X;
	if ( bOn )
		OnRates();
}

simulated function OnRates()
{
	Rate(E_CORE, CoreRate);
	Rate(E_BODY, BodyRate);
	if ( bFromEyes )
	{
		Rate(E_LICK, LickRate * EyesLickShare);
		Rate(E_SOOT, SootRate * EyesSootShare);
	}
	else
	{
		Rate(E_LICK, LickRate);
		Rate(E_SOOT, SootRate);
	}
	Rate(E_DRIP, DripRate);
}

simulated function TurnOn()
{
	bOn = true;
	OnSince = Level.TimeSeconds;
	SampleCount = 0;
	NextSample = 0;
	SetFlight();
	PlaceAtNozzle();
	AddSample();
	SetView();
	OnRates();
	DribbleLeft = 0;
	Emitters[E_SPARK].SpawnParticle(10);

	PlaySound(IgniteSound, SLOT_None, 1.0,, 400);
	bRoarSlot = false;
	PlaySound(RoarSound, SLOT_Interact, RoarVolume,, RoarRadius, 0.97 + 0.06 * FRand(), false);
	NextRoar = Level.TimeSeconds + RoarAgain;

	if ( Glow == None && !Level.bDropDetail && Level.DetailMode != DM_Low )
		Glow = Spawn(class'KFFlameStreamLight', self);
	if ( EndFX == None )
		EndFX = Spawn(class'KFFlameStreamEnd', self);
}

simulated function TurnOff()
{
	bOn = false;
	bReleasing = false;
	OffSince = Level.TimeSeconds;
	Rate(E_CORE, 0);
	Rate(E_BODY, 0);
	Rate(E_LICK, 0);
	Rate(E_SOOT, 0);
	SetDrips(true);
	Rate(E_DRIP, 10);
	DribbleLeft = 0.45;
	if ( bFromEyes )
		Emitters[E_PUFF].SpawnParticle(2);
	else
		Emitters[E_PUFF].SpawnParticle(5);
	Emitters[E_SMOKE].SpawnParticle(2);
	// (in the roar's slot, so it cuts the roar)
	if ( bRoarSlot )
		PlaySound(StopSound, SLOT_Misc, RoarVolume * 0.8,, RoarRadius);
	else
		PlaySound(StopSound, SLOT_Interact, RoarVolume * 0.8,, RoarRadius);
}

simulated function PlaceAtNozzle()
{
	local vector X, Y, Z;
	local coords C;
	local FlameThrower FT;

	if ( Instigator == None )
		return;
	Aim = AimOf(Instigator);
	FT = FlameThrower(Instigator.Weapon);
	if ( FT != None && Level.TimeSeconds - FT.DrawnNozzleTime < 0.1 )
		Nozzle = FT.DrawnNozzle;
	else if ( Owner != None && Level.TimeSeconds - Owner.LastRenderTime < 0.2 )
	{
		C = Owner.GetBoneCoords('tip');
		Nozzle = C.Origin;
	}
	else
	{
		GetAxes(Aim, X, Y, Z);
		Nozzle = Instigator.Location + Instigator.EyePosition() + 50 * X + 8 * Y - 14 * Z;
	}
	SetLocation(Nozzle);
	SetRotation(Aim);
}

// Where the stream fired now stops, along its arc in three pieces; the stream's parts end there
simulated function AddSample()
{
	local vector V, P0, P1, HL, HN, Dir;
	local float T, Life, Extra;
	local Actor A;
	local int i, Tries;
	local StreamSample S;

	Dir = vector(Aim);
	V = Speed * Dir;
	V.Z += Toss;
	S.Time = Level.TimeSeconds;
	S.Start = Nozzle;
	P0 = Nozzle;
	for ( i = 1; i <= 3 && !S.bHit; i++ )
	{
		T = Flight * i / 3.0;
		P1 = Nozzle + V * T;
		P1.Z += 0.5 * Gravity * T * T;
		for ( Tries = 0; Tries < 3; Tries++ )
		{
			A = Instigator.Trace(HL, HN, P1, P0, true);
			if ( A == None )
				break;
			if ( ExtendedZCollision(A) != None && A.Owner != None )
				A = A.Owner;
			// (the fuel goes through team-mates, as the tendrils do)
			if ( Pawn(A) != None && class'KFHumanPawn'.static.OnShootersTeam(A, Instigator, Instigator.GetTeamNum()) )
			{
				S.Dist += VSize(HL - P0);
				P0 = HL + Normal(P1 - P0) * (A.CollisionRadius * 2 + 4);
				continue;
			}
			S.End = HL;
			S.Normal = HN;
			S.bHit = true;
			S.bPawn = Pawn(A) != None;
			S.Dist += VSize(HL - P0);
			break;
		}
		if ( !S.bHit )
		{
			S.Dist += VSize(P1 - P0);
			P0 = P1;
		}
	}
	if ( !S.bHit )
	{
		S.End = P0;
		S.Normal = -Dir;
	}
	Samples[SampleHead] = S;
	SampleHead = (SampleHead + 1) % ArrayCount(Samples);
	SampleCount = Min(SampleCount + 1, ArrayCount(Samples));

	// What is set off now ends where it stops: on a wall a moment longer, to spread on it
	if ( S.bHit )
	{
		if ( S.bPawn )
			Extra = 0.04;
		else if ( bFromEyes )
			Extra = 0.1 * FClamp(S.Dist / 600.0, 0.3, 1.0);
		else
			Extra = 0.1;
		Life = FMin(S.Dist / Speed + Extra, Flight);
		Emitters[E_CORE].LifetimeRange.Max = FMin(default.Emitters[E_CORE].LifetimeRange.Max, Life);
		Emitters[E_CORE].LifetimeRange.Min = FMin(default.Emitters[E_CORE].LifetimeRange.Min, Life);
		Emitters[E_BODY].LifetimeRange.Max = FMin(Flight, TimeOr(S.Dist, BodySpeed, BodyDrag, Flight) + Extra);
		Emitters[E_BODY].LifetimeRange.Min = Emitters[E_BODY].LifetimeRange.Max * 0.92;
		Emitters[E_LICK].LifetimeRange.Max = FMin(Flight * 1.05, TimeOr(S.Dist, LickSpeed, LickDrag, Flight) + Extra);
		Emitters[E_LICK].LifetimeRange.Min = Emitters[E_LICK].LifetimeRange.Max * 0.9;
	}
	else
	{
		Emitters[E_CORE].LifetimeRange = default.Emitters[E_CORE].LifetimeRange;
		Emitters[E_BODY].LifetimeRange.Min = Flight * 0.92;
		Emitters[E_BODY].LifetimeRange.Max = Flight;
		Emitters[E_LICK].LifetimeRange.Min = Flight * 0.9;
		Emitters[E_LICK].LifetimeRange.Max = Flight * 1.05;
	}
}

static function float TimeOr( float Dist, float V, float Drag, float Else )
{
	local float T;

	T = TimeTo(Dist, V, Drag);
	if ( T <= 0 )
		return Else;
	return T;
}

simulated function Tick( float DT )
{
	local int i, n, Found;
	local float Age, Arrive, Dist;

	if ( bOn && (Owner == None || Owner.bDeleteMe || Instigator == None || Instigator.Health <= 0
		|| Level.TimeSeconds - LastFeed > FeedTimeout || (bReleasing && Level.TimeSeconds >= ReleaseAt)) )
		TurnOff();
	if ( bOn && Instigator.HeadVolume != None && Instigator.HeadVolume.bWaterVolume )
		TurnOff();

	PlaceAtNozzle();
	if ( SeenFromEyes() != bFromEyes )
		SetView();

	if ( bOn && Level.TimeSeconds >= NextSample )
	{
		AddSample();
		NextSample = Level.TimeSeconds + 0.03;
	}
	if ( DribbleLeft > 0 )
	{
		DribbleLeft -= DT;
		if ( DribbleLeft <= 0 )
			Rate(E_DRIP, 0);
	}

	// The splash: at the newest place the fuel has got to and still gets to
	Found = -1;
	for ( n = 0; n < SampleCount; n++ )
	{
		i = (SampleHead - 1 - n + ArrayCount(Samples)) % ArrayCount(Samples);
		Age = Level.TimeSeconds - Samples[i].Time;
		Arrive = Samples[i].Dist / Speed;
		if ( Age >= Arrive )
		{
			if ( Age - Arrive < 0.08 )
				Found = i;
			break;
		}
	}
	if ( EndFX != None )
	{
		if ( Found >= 0 )
			EndFX.Show(Samples[Found].End, Samples[Found].Normal, Aim, Samples[Found].bHit, Samples[Found].Dist, bFromEyes);
		else
			EndFX.Hide();
	}

	// The light, a little way along the stream, flickering
	if ( Glow != None )
	{
		if ( bOn )
			LightUp = FMin(1.0, LightUp + DT * 8.0);
		else
			LightUp = FMax(0.0, LightUp - DT * 4.0);
		if ( Level.TimeSeconds >= NextFlicker )
		{
			FlickerTo = 0.6 + 0.4 * FRand();
			NextFlicker = Level.TimeSeconds + 0.04 + 0.06 * FRand();
		}
		Flicker += (FlickerTo - Flicker) * FMin(1.0, DT * 20.0);
		Dist = 220;
		if ( SampleCount > 0 )
		{
			i = (SampleHead - 1 + ArrayCount(Samples)) % ArrayCount(Samples);
			Dist = FMin(Dist, Samples[i].Dist * 0.5);
		}
		Dist = FMin(Dist, (Level.TimeSeconds - OnSince) * Speed);
		Glow.Shine(Nozzle + vector(Aim) * Dist, LightUp * Flicker);
	}

	// Sound
	if ( bOn && Level.TimeSeconds >= NextRoar )
	{
		bRoarSlot = !bRoarSlot;
		if ( bRoarSlot )
			PlaySound(RoarSound, SLOT_Misc, RoarVolume,, RoarRadius, 0.97 + 0.06 * FRand(), false);
		else
			PlaySound(RoarSound, SLOT_Interact, RoarVolume,, RoarRadius, 0.97 + 0.06 * FRand(), false);
		NextRoar = Level.TimeSeconds + RoarAgain;
	}
	if ( bOn )
		LoopLevel = FMin(1.0, LoopLevel + DT * 4.0);
	else
		LoopLevel = FMax(0.0, LoopLevel - DT * 2.5);
	if ( LoopLevel > 0.01 )
	{
		AmbientSound = LoopSound;
		SoundVolume = byte(float(LoopVolume) * LoopLevel);
	}
	else
		AmbientSound = None;

	if ( !bOn && Level.TimeSeconds - OffSince > 3.0 )
		Destroy();
}

defaultproperties
{
	FeedTimeout=0.300000
	BodyDrag=0.300000
	LickDrag=1.300000
	SootDrag=2.600000
	CoreRate=160.000000
	BodyRate=160.000000
	LickRate=75.000000
	EyesLickShare=0.450000
	EyesSootShare=0.400000
	EyesLickGlow=0.600000
	EyesBodyGlow=0.850000
	SootRate=10.000000
	DripRate=14.000000
	IgniteSound=Sound'PatchSounds.PilotLightToggle'
	RoarSound=Sound'KFWeaponSound.FlameThrowerFire'
	StopSound=Sound'PatchSounds.PilotLightToggle'
	LoopSound=Sound'GeneralAmbience.firefx13'
	RoarAgain=2.100000
	RoarVolume=1.000000
	RoarRadius=500.000000
	LoopVolume=110
	SoundRadius=60.000000
	SoundOcclusion=OCCLUSION_StaticMeshes

	Begin Object Class=SpriteEmitter Name=StreamCore
		UseDirectionAs=PTDU_Right
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=False
		UseCollision=True
		ExtentMultiplier=(X=0.300000,Y=0.300000,Z=0.300000)
		DampingFactorRange=(X=(Min=0.100000,Max=0.200000),Y=(Min=0.100000,Max=0.200000),Z=(Min=0.100000,Max=0.200000))
		UseRotationFrom=PTRS_Actor
		AddVelocityFromOwner=True
		ColorScale(0)=(Color=(B=210,G=240,R=255))
		ColorScale(1)=(RelativeTime=0.500000,Color=(B=150,G=215,R=255))
		ColorScale(2)=(RelativeTime=1.000000,Color=(B=20,G=70,R=160))
		MaxParticles=32
		ParticlesPerSecond=0.000000
		InitialParticlesPerSecond=0.000000
		SizeScale(0)=(RelativeSize=0.250000)
		SizeScale(1)=(RelativeTime=0.300000,RelativeSize=0.800000)
		SizeScale(2)=(RelativeTime=1.000000,RelativeSize=1.200000)
		StartSizeRange=(X=(Min=60.000000,Max=90.000000),Y=(Min=9.000000,Max=13.000000))
		Texture=Texture'AW-2004Particles.Weapons.HardSpot'
		LifetimeRange=(Min=0.100000,Max=0.150000)
		StartVelocityRange=(X=(Min=2300.000000,Max=2300.000000),Y=(Min=-20.000000,Max=20.000000),Z=(Min=-20.000000,Max=20.000000))
		SecondsBeforeInactive=0.000000
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFFlameStream.StreamCore'

	Begin Object Class=SpriteEmitter Name=StreamBody
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		UseCollision=True
		ExtentMultiplier=(X=0.350000,Y=0.350000,Z=0.350000)
		DampingFactorRange=(X=(Min=0.100000,Max=0.300000),Y=(Min=0.100000,Max=0.300000),Z=(Min=0.100000,Max=0.300000))
		UseRotationFrom=PTRS_Actor
		AddVelocityFromOwner=True
		Acceleration=(Z=-950.000000)
		ColorScale(0)=(Color=(B=200,G=240,R=255))
		ColorScale(1)=(RelativeTime=0.150000,Color=(B=130,G=205,R=255))
		ColorScale(2)=(RelativeTime=0.450000,Color=(B=50,G=120,R=220))
		ColorScale(3)=(RelativeTime=0.750000,Color=(B=15,G=50,R=150))
		ColorScale(4)=(RelativeTime=0.920000,Color=(B=4,G=14,R=60))
		ColorScale(5)=(RelativeTime=1.000000)
		ColorMultiplierRange=(Y=(Min=0.900000,Max=1.000000),Z=(Min=0.800000,Max=1.000000))
		MaxParticles=120
		ParticlesPerSecond=0.000000
		InitialParticlesPerSecond=0.000000
		SpinsPerSecondRange=(X=(Min=-0.300000,Max=0.300000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.060000)
		SizeScale(1)=(RelativeTime=0.150000,RelativeSize=0.200000)
		SizeScale(2)=(RelativeTime=0.500000,RelativeSize=0.600000)
		SizeScale(3)=(RelativeTime=1.000000,RelativeSize=1.000000)
		StartSizeRange=(X=(Min=40.000000,Max=55.000000))
		Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=0.550000,Max=0.600000)
		StartVelocityRange=(X=(Min=2500.000000,Max=2600.000000),Y=(Min=-70.000000,Max=70.000000),Z=(Min=100.000000,Max=260.000000))
		VelocityLossRange=(X=(Min=0.300000,Max=0.300000),Y=(Min=0.300000,Max=0.300000),Z=(Min=0.300000,Max=0.300000))
		SecondsBeforeInactive=0.000000
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFFlameStream.StreamBody'

	Begin Object Class=SpriteEmitter Name=StreamLicks
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseCollision=True
		ExtentMultiplier=(X=0.300000,Y=0.300000,Z=0.300000)
		DampingFactorRange=(X=(Min=0.150000,Max=0.300000),Y=(Min=0.150000,Max=0.300000),Z=(Min=0.150000,Max=0.300000))
		UseRotationFrom=PTRS_Actor
		AddVelocityFromOwner=True
		Acceleration=(Z=-430.000000)
		ColorScale(0)=(Color=(B=0,G=0,R=0))
		ColorScale(1)=(RelativeTime=0.100000,Color=(B=0,G=0,R=0))
		ColorScale(2)=(RelativeTime=0.350000,Color=(B=70,G=125,R=180))
		ColorScale(3)=(RelativeTime=0.700000,Color=(B=30,G=65,R=130))
		ColorScale(4)=(RelativeTime=1.000000)
		ColorMultiplierRange=(Y=(Min=0.850000,Max=1.000000),Z=(Min=0.700000,Max=1.000000))
		MaxParticles=56
		ParticlesPerSecond=0.000000
		InitialParticlesPerSecond=0.000000
		SpinsPerSecondRange=(X=(Min=-0.500000,Max=0.500000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.200000)
		SizeScale(1)=(RelativeTime=0.400000,RelativeSize=0.600000)
		SizeScale(2)=(RelativeTime=1.000000,RelativeSize=1.100000)
		StartSizeRange=(X=(Min=35.000000,Max=70.000000))
		Texture=Texture'AW-2004Particles.Fire.NapalmSpot'
		LifetimeRange=(Min=0.550000,Max=0.650000)
		StartVelocityRange=(X=(Min=2700.000000,Max=2900.000000),Y=(Min=-100.000000,Max=100.000000),Z=(Min=140.000000,Max=240.000000))
		VelocityLossRange=(X=(Min=1.300000,Max=1.300000),Y=(Min=1.300000,Max=1.300000),Z=(Min=1.300000,Max=1.300000))
		SecondsBeforeInactive=0.000000
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFFlameStream.StreamLicks'

	Begin Object Class=SpriteEmitter Name=StreamSoot
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		FadeOut=True
		FadeIn=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		UseCollision=True
		ExtentMultiplier=(X=0.250000,Y=0.250000,Z=0.250000)
		DampingFactorRange=(X=(Min=0.200000,Max=0.300000),Y=(Min=0.200000,Max=0.300000),Z=(Min=0.200000,Max=0.300000))
		UseRotationFrom=PTRS_Actor
		AddVelocityFromOwner=True
		AddVelocityMultiplierRange=(X=(Min=0.600000,Max=0.600000),Y=(Min=0.600000,Max=0.600000),Z=(Min=0.600000,Max=0.600000))
		Acceleration=(Z=70.000000)
		ColorScale(0)=(Color=(B=34,G=36,R=40,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=56,G=58,R=60,A=255))
		Opacity=0.500000
		FadeOutStartTime=0.900000
		FadeInEndTime=0.550000
		MaxParticles=20
		ParticlesPerSecond=0.000000
		InitialParticlesPerSecond=0.000000
		SpinsPerSecondRange=(X=(Min=-0.050000,Max=0.050000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.400000)
		SizeScale(1)=(RelativeTime=0.400000,RelativeSize=1.200000)
		SizeScale(2)=(RelativeTime=1.000000,RelativeSize=2.500000)
		StartSizeRange=(X=(Min=40.000000,Max=60.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Fire.MuchSmoke1'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=1.300000,Max=1.700000)
		StartVelocityRange=(X=(Min=2600.000000,Max=3000.000000),Y=(Min=-100.000000,Max=100.000000),Z=(Min=0.000000,Max=150.000000))
		VelocityLossRange=(X=(Min=2.600000,Max=2.600000),Y=(Min=2.600000,Max=2.600000),Z=(Min=2.600000,Max=2.600000))
		DetailMode=DM_High
		SecondsBeforeInactive=0.000000
	End Object
	Emitters(3)=SpriteEmitter'KFMod.KFFlameStream.StreamSoot'

	Begin Object Class=SpriteEmitter Name=StreamDrips
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UniformSize=True
		UseCollision=True
		UseMaxCollisions=True
		MaxCollisions=(Min=1.000000,Max=1.000000)
		SpawnFromOtherEmitter=5
		SpawnAmount=1
		UseRotationFrom=PTRS_Actor
		AddVelocityFromOwner=True
		Acceleration=(Z=-1330.000000)
		ColorScale(0)=(Color=(B=140,G=220,R=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=20,G=90,R=255))
		MaxParticles=16
		ParticlesPerSecond=0.000000
		InitialParticlesPerSecond=0.000000
		StartSizeRange=(X=(Min=4.000000,Max=7.000000))
		Texture=Texture'EmitterTextures.Flares.EFlareOY'
		LifetimeRange=(Min=0.500000,Max=0.900000)
		StartVelocityRange=(X=(Min=1150.000000,Max=1840.000000),Y=(Min=-80.000000,Max=80.000000),Z=(Min=0.000000,Max=200.000000))
		DetailMode=DM_High
		SecondsBeforeInactive=0.000000
	End Object
	Emitters(4)=SpriteEmitter'KFMod.KFFlameStream.StreamDrips'

	Begin Object Class=SpriteEmitter Name=DripFlare
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		Acceleration=(Z=60.000000)
		ColorScale(0)=(Color=(B=120,G=200,R=255))
		ColorScale(1)=(RelativeTime=0.500000,Color=(B=40,G=120,R=240))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=16
		ParticlesPerSecond=0.000000
		InitialParticlesPerSecond=0.000000
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.600000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.500000)
		StartSizeRange=(X=(Min=12.000000,Max=20.000000))
		Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=0.350000,Max=0.600000)
		StartVelocityRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=20.000000,Max=60.000000))
		DetailMode=DM_High
		SecondsBeforeInactive=0.000000
	End Object
	Emitters(5)=SpriteEmitter'KFMod.KFFlameStream.DripFlare'

	Begin Object Class=SpriteEmitter Name=IgniterSparks
		UseDirectionAs=PTDU_Right
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		UniformSize=False
		ScaleSizeXByVelocity=True
		UseRotationFrom=PTRS_Actor
		Acceleration=(Z=-900.000000)
		ColorScale(0)=(Color=(B=210,G=245,R=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=20,G=110,R=255))
		MaxParticles=16
		ParticlesPerSecond=0.000000
		InitialParticlesPerSecond=0.000000
		StartSizeRange=(X=(Min=1.000000,Max=1.000000),Y=(Min=1.200000,Max=2.000000))
		ScaleSizeByVelocityMultiplier=(X=0.020000)
		ScaleSizeByVelocityMax=700.000000
		Texture=Texture'AW-2004Particles.Weapons.HardSpot'
		LifetimeRange=(Min=0.150000,Max=0.350000)
		StartVelocityRange=(X=(Min=250.000000,Max=700.000000),Y=(Min=-280.000000,Max=280.000000),Z=(Min=-200.000000,Max=280.000000))
		SecondsBeforeInactive=0.000000
	End Object
	Emitters(6)=SpriteEmitter'KFMod.KFFlameStream.IgniterSparks'

	Begin Object Class=SpriteEmitter Name=ReleasePuff
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		UseRotationFrom=PTRS_Actor
		Acceleration=(Z=90.000000)
		ColorScale(0)=(Color=(B=120,G=200,R=255))
		ColorScale(1)=(RelativeTime=0.400000,Color=(B=30,G=100,R=200))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=8
		ParticlesPerSecond=0.000000
		InitialParticlesPerSecond=0.000000
		SpinsPerSecondRange=(X=(Min=-0.300000,Max=0.300000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.500000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.200000)
		StartSizeRange=(X=(Min=12.000000,Max=22.000000))
		Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=0.300000,Max=0.550000)
		StartVelocityRange=(X=(Min=80.000000,Max=220.000000),Y=(Min=-40.000000,Max=40.000000),Z=(Min=10.000000,Max=70.000000))
		VelocityLossRange=(X=(Min=2.000000,Max=2.000000),Y=(Min=2.000000,Max=2.000000),Z=(Min=2.000000,Max=2.000000))
		SecondsBeforeInactive=0.000000
	End Object
	Emitters(7)=SpriteEmitter'KFMod.KFFlameStream.ReleasePuff'

	Begin Object Class=SpriteEmitter Name=ReleaseSmoke
		UseColorScale=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		FadeOut=True
		FadeIn=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		UseRotationFrom=PTRS_Actor
		Acceleration=(Z=40.000000)
		ColorScale(0)=(Color=(B=40,G=42,R=46,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=60,G=60,R=62,A=255))
		Opacity=0.300000
		FadeOutStartTime=0.500000
		FadeInEndTime=0.200000
		MaxParticles=4
		ParticlesPerSecond=0.000000
		InitialParticlesPerSecond=0.000000
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.600000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.000000)
		StartSizeRange=(X=(Min=14.000000,Max=22.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Fire.MuchSmoke1'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=1.000000,Max=1.400000)
		StartVelocityRange=(X=(Min=30.000000,Max=90.000000),Y=(Min=-20.000000,Max=20.000000),Z=(Min=10.000000,Max=40.000000))
		VelocityLossRange=(X=(Min=1.500000,Max=1.500000),Y=(Min=1.500000,Max=1.500000),Z=(Min=1.000000,Max=1.000000))
		DetailMode=DM_High
		SecondsBeforeInactive=0.000000
	End Object
	Emitters(8)=SpriteEmitter'KFMod.KFFlameStream.ReleaseSmoke'

	bNoDelete=False
	bNotOnDedServer=True
}
