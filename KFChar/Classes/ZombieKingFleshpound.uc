//=============================================================================
// ZombieKingFleshpound - a boss prototype after Killing Floor 2's King Fleshpound: a Fleshpound 1.4 times as big and
// eight times as tough, with
//  - a chest beam: it plants itself, its chest glows, and a red-hot beam sweeps after its target, burning what it
//    crosses (BeamPhase, replicated: every machine draws it, KFKingBeamFX);
//  - a ground pound when players crowd it: the floor blasts up round it, throwing them back (KFKingPound);
//  - shields: at three quarters, half and a quarter of its health it shuts itself in a ball of red glass that takes
//    almost nothing through it (KFShieldBubble on each machine), and Quarter Pounds teleport in to fight for it;
//    the ball breaks when it has soaked enough or its time is up;
//  - and below RageAtShare of its health it never stops raging.
// Its abilities are ticked by a KFBossBrain on the server (the Fleshpound's states have Ticks of their own).
//=============================================================================
class ZombieKingFleshpound extends ZombieFleshPound;

var() float BeamInterval, BeamCharge, BeamTime, BeamRange, BeamTurnRate;
var() int BeamDamage;						// each tenth of a second it is on someone
var() float PoundInterval, PoundRadius, PoundMomentum;
var() int PoundDamage;
var() float ShieldTime, ShieldShare, ShieldBlock;	// seconds; share of its health it soaks before it breaks; share of a hit let through
var() int QuarterPounds;					// teleported in at each shield (more with more players)
var() float RageAtShare;

var byte BeamPhase;							// (replicated) 0 none, 1 charging, 2 burning
var vector BeamDir;							// (replicated) the beam's way from the chest
var bool bShielded;							// (replicated)
var byte ShieldHits;						// (replicated) counts up as the shield is struck

var float NextBeam, BeamPhaseTime, NextBeamTick, NextPound, PoundAt, ShieldUntil, ShieldLeft;
var byte ShieldsUsed;
var Pawn BeamTarget;
var KFBossBrain Brain;

// each machine's own
var KFKingBeamFX BeamFX;
var KFKingGlow ChestGlow, BeamHit;
var KFShieldBubble Bubble;
var byte ShieldHitsSeen;

replication
{
	reliable if ( Role == ROLE_Authority )
		BeamPhase, BeamDir, bShielded, ShieldHits;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( Role == ROLE_Authority )
	{
		Brain = Spawn(class'KFBossBrain', self);
		if ( Brain != None )
			Brain.Boss = self;
		NextBeam = Level.TimeSeconds + 6.0;
		NextPound = Level.TimeSeconds + 4.0;
	}
}

simulated function vector ChestSpot()
{
	return GetBoneCoords('Bip01 Spine2').Origin + vector(Rotation) * 26.0 * DrawScale;
}

// ---- the server

function BossThink( float DT )
{
	local float D;

	if ( Level.NetMode != NM_DedicatedServer )
		KingLook();
	if ( Health <= 0 || Controller == None )
		return;
	// the shield breaks when it has soaked enough, or its time is up; one goes up at each quarter of its health
	if ( bShielded && (Level.TimeSeconds > ShieldUntil || ShieldLeft <= 0) )
		bShielded = false;
	if ( !bShielded && ShieldsUsed < 3 && float(Health) < HealthMax * (1.0 - 0.25 * float(ShieldsUsed + 1)) )
		StartShield();
	// the pound lands a moment after the blow starts
	if ( PoundAt > 0 && Level.TimeSeconds >= PoundAt )
	{
		PoundAt = 0;
		Pound();
	}
	switch ( BeamPhase )
	{
		case 0:
			if ( Controller.Enemy != None && Controller.Enemy.Health > 0 )
			{
				D = VSize(Controller.Enemy.Location - Location);
				if ( Level.TimeSeconds > NextBeam && !bChargingPlayer && D > 260.0 && D < BeamRange && Controller.LineOfSightTo(Controller.Enemy) )
					StartBeam(Controller.Enemy);
				else if ( Level.TimeSeconds > NextPound && D < PoundRadius * 0.55 && !bShotAnim )
					GroundPound();
			}
			if ( float(Health) < HealthMax * RageAtShare && !bChargingPlayer && BeamPhase == 0 && !IsInState('BeginRaging') && !bShotAnim )
				StartCharging();
			break;
		case 1:
			HoldStill();
			if ( Level.TimeSeconds - BeamPhaseTime > BeamCharge )
			{
				BeamPhase = 2;
				BeamPhaseTime = Level.TimeSeconds;
				PlaySound(Sound'WeaponSounds.BaseFiringSounds.BLightningGunFire', SLOT_Interact, 2.5,, 3000.0, 0.5);
			}
			break;
		case 2:
			HoldStill();
			Burn(DT);
			if ( Level.TimeSeconds - BeamPhaseTime > BeamTime )
				EndBeam();
			break;
	}
}

function HoldStill()
{
	Acceleration = vect(0,0,0);
	Velocity.X = 0;
	Velocity.Y = 0;
	bShotAnim = true;
	if ( BeamTarget != None )
		Controller.Focus = BeamTarget;
}

function StartBeam( Pawn Target )
{
	BeamTarget = Target;
	BeamPhase = 1;
	BeamPhaseTime = Level.TimeSeconds;
	BeamDir = Normal(Target.Location - ChestSpot());
	bShotAnim = true;
	SetAnimAction('PoundIdle');
	Controller.GoToState('WaitForAnim');
	PlaySound(Sound'WeaponSounds.LightningGun.LightningGunChargeUp', SLOT_Interact, 2.5,, 3000.0, 0.6);
	PlaySound(MoanVoice[Rand(4)], SLOT_Talk, 2.0,, 2000.0, 0.7);
}

// The beam turns after its target and burns what it crosses
function Burn( float DT )
{
	local vector Start, Want, HitLocation, HitNormal;
	local Actor A;
	local float Turn, C;

	Start = ChestSpot();
	if ( BeamTarget != None && BeamTarget.Health > 0 )
	{
		Want = Normal(BeamTarget.Location + vect(0,0,10) - Start);
		C = FClamp(BeamDir dot Want, -1.0, 1.0);
		Turn = BeamTurnRate * DT;
		if ( Acos(C) > Turn )
			BeamDir = Normal(BeamDir + Normal(Want - BeamDir * C) * Tan(Turn));
		else
			BeamDir = Want;
	}
	SetRotation(rotator(BeamDir * vect(1,1,0)));
	if ( Level.TimeSeconds < NextBeamTick )
		return;
	NextBeamTick = Level.TimeSeconds + 0.1;
	A = Trace(HitLocation, HitNormal, Start + BeamDir * BeamRange, Start, true);
	if ( A != None && Pawn(A) != None && KFMonster(A) == None )
		A.TakeDamage(BeamDamage, self, HitLocation, BeamDir * 8000.0, class'DamTypeKingBeam');
	// it sets fuel and vapour off where it burns
	if ( A != None )
		class'KFFireGrid'.static.Heat(self, HitLocation, 90.0, 2.0);
}

function EndBeam()
{
	BeamPhase = 0;
	bShotAnim = false;
	BeamTarget = None;
	NextBeam = Level.TimeSeconds + BeamInterval * (0.8 + 0.4 * FRand());
	if ( Controller != None )
		Controller.GoToState('ZombieHunt');
}

function GroundPound()
{
	NextPound = Level.TimeSeconds + PoundInterval;
	bShotAnim = true;
	SetAnimAction('PoundAttack3');
	Acceleration = vect(0,0,0);
	Controller.GoToState('WaitForAnim');
	PoundAt = Level.TimeSeconds + 0.55;
	PlaySound(MoanVoice[Rand(4)], SLOT_Talk, 2.5,, 2000.0, 0.6);
}

// Everyone but specimens near it: hurt and thrown back, the more the nearer
function Pound()
{
	local vector Ground, Dir;
	local Pawn P;
	local float D, Share;

	Ground = Location - vect(0,0,1) * CollisionHeight;
	foreach VisibleCollidingActors(class'Pawn', P, PoundRadius, Ground + vect(0,0,30))
	{
		if ( P == self || KFMonster(P) != None || P.Health <= 0 )
			continue;
		Dir = P.Location - Ground;
		D = VSize(Dir);
		Share = 1.0 - 0.6 * FClamp(D / PoundRadius, 0.0, 1.0);
		Dir = Normal(Dir * vect(1,1,0) + vect(0,0,0.6) * FMax(D, 1.0));
		P.TakeDamage(int(float(PoundDamage) * Share), self, P.Location - Dir * P.CollisionRadius, Dir * PoundMomentum * Share, class'DamTypeKingPound');
	}
	Spawn(class'KFKingPound',,, Ground + vect(0,0,6));
}

// Hits on others round it (the ground pound) spare it and its own
function bool SameSpeciesAs( Pawn P )
{
	return KFMonster(P) != None;
}

function StartShield()
{
	local int i, n;
	local vector Spot;
	local KFTeleportIn T;
	local class<KFMonster> QP;

	ShieldsUsed++;
	bShielded = true;
	ShieldUntil = Level.TimeSeconds + ShieldTime;
	ShieldLeft = HealthMax * ShieldShare;
	if ( BeamPhase != 0 )
		EndBeam();
	PlaySound(Sound'ONSBPSounds.ShockTank.ShockBallExplosion', SLOT_None, 2.5,, 3000.0, 0.45);
	// Quarter Pounds come in round it
	QP = class<KFMonster>(DynamicLoadObject("KFChar.ZombieQuarterPound", class'Class'));
	n = QuarterPounds + int(Sqrt(float(Max(1, Level.Game.NumPlayers + Level.Game.NumBots))));
	for ( i=0; i<n && QP != None; i++ )
	{
		Spot = Location + vector(rot(0,1,0) * (65536 * i / n + Rand(4000))) * (180.0 + 60.0 * FRand());
		if ( !FastTrace(Spot, Location) )
			continue;
		T = Spawn(class'KFTeleportIn',,, Spot - vect(0,0,1) * CollisionHeight + vect(0,0,4));
		if ( T != None )
			T.ZedClass = QP;
	}
}

function TakeDamage( int Damage, Pawn InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType )
{
	if ( bShielded && Damage > 0 && Health > 0 )
	{
		ShieldLeft -= Damage;
		ShieldHits++;
		Damage = Max(1, int(float(Damage) * ShieldBlock));
		Momentum = vect(0,0,0);
	}
	Super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType);
}

// ---- every machine: the beam, the glowing chest, the shield

// (on a client: on the machine that runs the game the brain does it, whatever state it is in)
simulated function Tick( float DeltaTime )
{
	Super.Tick(DeltaTime);
	if ( Role < ROLE_Authority )
		KingLook();
}

simulated function KingLook()
{
	local vector Start, End, HitNormal;

	if ( Health <= 0 || bDeleteMe )
	{
		StopLook();
		return;
	}
	Start = ChestSpot();
	// the chest glows as it charges and burns
	if ( BeamPhase != 0 )
	{
		if ( ChestGlow == None )
			ChestGlow = Spawn(class'KFKingGlow',,, Start);
		if ( ChestGlow != None )
			ChestGlow.SetLocation(Start);
	}
	else if ( ChestGlow != None )
	{
		ChestGlow.Kill();
		ChestGlow.LifeSpan = 1.0;
		ChestGlow = None;
	}
	if ( BeamPhase == 2 )
	{
		if ( Trace(End, HitNormal, Start + BeamDir * BeamRange, Start, true) == None )
			End = Start + BeamDir * BeamRange;
		if ( BeamFX == None )
			BeamFX = Spawn(class'KFKingBeamFX',,, Start);
		if ( BeamFX != None )
			BeamFX.Span(Start, End);
		if ( BeamHit == None )
			BeamHit = Spawn(class'KFKingGlow',,, End);
		if ( BeamHit != None )
			BeamHit.SetLocation(End + HitNormal * 4.0);
	}
	else
	{
		if ( BeamFX != None )
		{
			BeamFX.Destroy();
			BeamFX = None;
		}
		if ( BeamHit != None )
		{
			BeamHit.Kill();
			BeamHit.LifeSpan = 1.0;
			BeamHit = None;
		}
	}
	// the shield
	if ( bShielded && Bubble == None )
		Bubble = class'KFShieldBubble'.static.Make(self, CollisionHeight * 1.5);
	else if ( !bShielded && Bubble != None )
	{
		Spawn(class'KFTeleportFlash',,, Location);
		class'KFScreenFX'.static.Wave(Level, Location, 2.0);
		Bubble.Destroy();
		Bubble = None;
	}
	if ( Bubble != None && ShieldHits != ShieldHitsSeen )
		Bubble.Struck();
	ShieldHitsSeen = ShieldHits;
}

simulated function StopLook()
{
	if ( BeamFX != None )
		BeamFX.Destroy();
	if ( ChestGlow != None )
		ChestGlow.Destroy();
	if ( BeamHit != None )
		BeamHit.Destroy();
	if ( Bubble != None )
		Bubble.Destroy();
	BeamFX = None;
	ChestGlow = None;
	BeamHit = None;
	Bubble = None;
}

simulated function Destroyed()
{
	StopLook();
	if ( Brain != None )
		Brain.Destroy();
	Super.Destroyed();
}

defaultproperties
{
     BeamInterval=11.000000
     BeamCharge=1.100000
     BeamTime=2.600000
     BeamRange=2600.000000
     BeamTurnRate=0.550000
     BeamDamage=5
     PoundInterval=7.000000
     PoundRadius=420.000000
     PoundMomentum=160000.000000
     PoundDamage=35
     ShieldTime=12.000000
     ShieldShare=0.120000
     ShieldBlock=0.080000
     QuarterPounds=2
     RageAtShare=0.300000
     RageDamageThreshold=1200
     MenuName="King Fleshpound"
     Health=12000
     HealthMax=12000.000000
     HeadHealth=6000
     DrawScale=1.400000
     CollisionRadius=36.000000
     CollisionHeight=62.000000
     ColOffset=(Z=59.000000)
     ColRadius=50.000000
     ColHeight=64.000000
     PrePivot=(Z=11.000000)
     GroundSpeed=150.000000
     GibScale=1.800000
     ScoringValue=200
     Mass=1200.000000
     damageConst=40
     damageRand=20
     damageForce=40000
}
