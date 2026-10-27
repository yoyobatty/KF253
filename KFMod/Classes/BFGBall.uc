//=============================================================================
// BFGBall
// The BFG 9000's shot: a slow ball of green plasma. In flight it lashes the specimens near its path with green bolts
// (ZapAround, ZapTarget[] drawn by each machine), and goes through the specimens in its way, tearing at each (Pierce),
// until it bursts in the PierceCount-th (or on a wall, or at the end of its flight). Where it bursts it tears everything
// round it apart (Blast), and then, as Doom's does, its tracers go out from the shooter in a fan the way they fired it
// and strike every specimen they meet (Tracers, KFBFGSpray). Players and their bots are never hurt by it.
//=============================================================================
class BFGBall extends Projectile;

#exec OBJ LOAD FILE=..\Sounds\ONSBPSounds.uax
#exec OBJ LOAD FILE=..\Sounds\WeaponSounds.uax

var() float	ZapEvery, ZapRange;
var() int	ZapDamage;
var() int	TracerCount, TracerDamage;
var() float	TracerFan, TracerRange;		// the fan, in rotation units across
var() float	BlindRange;
var KFMonster	ZapTarget[4];
var KFBFGBeam	Beams[4];
var vector	InitDir;
var float	NextZap;
var KFBFGBallFX	FX;
var bool	bBlown;
var KFBFGLens	Lens;			// (each machine that draws it) the view bent round it
var() float	CarryReach;		// bodies this near are dragged after it...
var() float	CarryPull, CarryLift;	// ...this hard toward it and up, each second (Karma's impulse)
var() float	ShredReach;		// they are torn apart once this near it and held HoldMin, or held HoldMax wherever they are
var() float	HoldMin, HoldMax;
var() int		PierceCount;	// it bursts in the specimen that makes this many it has met...
var() int		PierceDamage;	// ...and tears this much from each it goes through before
var() float		PierceMomentum;
var array<KFMonster> Pierced;	// (each machine) the specimens it has met

replication
{
	unreliable if ( Role == ROLE_Authority )
		ZapTarget;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	Velocity = vector(Rotation) * Speed;
	InitDir = vector(Rotation);
	NextZap = Level.TimeSeconds + 0.1;
	// it bursts at the end of its flight, wherever it is
	SetTimer(LifeSpan - 0.3, false);
	if ( Level.NetMode != NM_DedicatedServer )
	{
		FX = Spawn(class'KFBFGBallFX', self,, Location, Rotation);
		if ( FX != None )
			FX.SetBase(self);
		Lens = class'KFBFGLens'.static.Make(self);
	}
}

simulated function Tick( float DT )
{
	if ( bBlown )
		return;
	if ( Role == ROLE_Authority && Level.TimeSeconds >= NextZap )
	{
		NextZap = Level.TimeSeconds + ZapEvery;
		ZapAround();
	}
	if ( Level.NetMode != NM_DedicatedServer )
	{
		DrawZaps();
		class'KFGib'.static.Pull(self, DT);
		CarryBodies(DT);
	}
}

// (each machine that draws it) The bodies near its path are dragged after it by the middle, and shredded when they
// reach it or it has held them long enough; what is left of them its pull takes (KFGib.Pull)
simulated function CarryBodies( float DT )
{
	local KFMonster M;
	local vector C, V, Push;
	local float D, K;

	foreach CollidingActors(class'KFMonster', M, CarryReach)
	{
		if ( M.Health > 0 || M.bGibbed || M.Physics != PHYS_KarmaRagdoll )
			continue;
		C = M.GetBoneCoords('Bip01 Spine2').Origin;
		V = Location - C;
		D = VSize(V);
		if ( D > CarryReach )
			continue;
		M.WakeBody();
		M.BFGHeld += DT;
		if ( (D < ShredReach && M.BFGHeld > HoldMin) || M.BFGHeld > HoldMax )
		{
			Shred(M, C);
			continue;
		}
		K = 1.0 - D / CarryReach;
		// (by the hips and the neck: Karma's own bodies there take a push)
		Push = ((V / FMax(D, 1.0) * (0.3 + 0.7 * K) + Normal(Velocity) * (0.6 * K)) * CarryPull + vect(0,0,1) * CarryLift * K) * DT * 0.5;
		M.KAddImpulse(Push, M.GetBoneCoords('Bip01 Pelvis').Origin, 'Bip01 Pelvis');
		M.KAddImpulse(Push, M.GetBoneCoords('Bip01 Neck').Origin, 'Bip01 Neck');
	}
}

// A body torn apart in the ball's grip: its pieces, a great burst of blood along the ball's way, a green flash
simulated function Shred( KFMonster M, vector C )
{
	local KFBloodFX B;

	M.GibBody(rotator(Velocity), 1.6);
	if ( !M.bGibbed )
		return;
	M.RemoveGibbedBody();
	if ( !M.bFrozen )
	{
		B = Spawn(class'KFBloodFX',,, C, rotator(Velocity));
		if ( B != None )
		{
			B.Dir = Normal(Velocity);
			B.Size = 2.2;
			B.bHeavy = true;
		}
	}
	Spawn(class'KFBFGHitFX',,, C);
}

// (the server) Green bolts to the specimens near it that it can see
function ZapAround()
{
	local KFMonster M;
	local int n, i;

	foreach VisibleCollidingActors(class'KFMonster', M, ZapRange)
	{
		if ( M.Health <= 0 || n >= ArrayCount(ZapTarget) )
			continue;
		ZapTarget[n] = M;
		n++;
		M.TakeDamage(ZapDamage, Instigator, M.Location, Normal(M.Location - Location) * 6000, class'DamTypeBFG');
	}
	for ( i = n; i < ArrayCount(ZapTarget); i++ )
		ZapTarget[i] = None;
}

simulated function DrawZaps()
{
	local int i;
	local KFMonster T;

	for ( i = 0; i < ArrayCount(ZapTarget); i++ )
	{
		T = ZapTarget[i];
		if ( T != None && !T.bDeleteMe && !T.bPlayedDeath && VSize(T.Location - Location) < ZapRange * 1.2 )
		{
			if ( Beams[i] == None )
				Beams[i] = Spawn(class'KFBFGBeam', self,, Location);
			if ( Beams[i] != None )
				Beams[i].Span(Location, T.Location + 12 * VRand());
		}
		else if ( Beams[i] != None )
		{
			Beams[i].Kill();
			Beams[i] = None;
		}
	}
}

simulated function Timer()
{
	Explode(Location, -Normal(Velocity));
}

simulated function ProcessTouch( Actor Other, vector HitLocation )
{
	local KFMonster M;

	if ( Other == None || Other == Instigator || Other == Owner || Other.bDeleteMe || bBlown )
		return;
	if ( KFHumanPawn(Other) != None || Projectile(Other) != None )
		return;
	if ( Other.Base != None && KFHumanPawn(Other.Base) != None )
		return;
	M = KFMonster(Other);
	if ( M == None && ExtendedZCollision(Other) != None )
	{
		M = KFMonster(Other.Owner);
		if ( M == None )
			M = KFMonster(Other.Base);
	}
	if ( M != None )
	{
		Pierce(M, HitLocation);
		return;
	}
	Explode(HitLocation, Normal(HitLocation - Other.Location));
}

// A specimen in its way: it goes on through, tearing at it, and bursts in the PierceCount-th; a body it passes. (Each
// machine sees the blood and the flash; only the server counts and bursts, and a client's ball bursts where the server
// took it away: Destroyed.)
simulated function Pierce( KFMonster M, vector HitLocation )
{
	local int i;

	if ( M.Health <= 0 || M.bPlayedDeath || M.bDeleteMe )
		return;
	for ( i = 0; i < Pierced.Length; i++ )
		if ( Pierced[i] == M )
			return;
	Pierced[Pierced.Length] = M;
	if ( Level.NetMode != NM_DedicatedServer )
		PierceFX(M, HitLocation);
	if ( Role < ROLE_Authority )
		return;
	if ( Pierced.Length >= PierceCount )
	{
		Explode(HitLocation, -Normal(Velocity));
		return;
	}
	M.TakeDamage(PierceDamage, Instigator, HitLocation, Normal(Velocity) * PierceMomentum, MyDamageType);
}

simulated function PierceFX( KFMonster M, vector HitLocation )
{
	local KFBloodFX B;

	Spawn(class'KFBFGHitFX',,, HitLocation);
	if ( M.bFrozen )
		return;
	B = Spawn(class'KFBloodFX',,, HitLocation, rotator(Velocity));
	if ( B != None )
	{
		B.Dir = Normal(Velocity);
		B.Size = 1.6;
		B.bHeavy = true;
	}
}

simulated function HitWall( vector HitNormal, Actor Wall )
{
	Explode(Location + HitNormal * 4, HitNormal);
}

simulated function Explode( vector HitLocation, vector HitNormal )
{
	local int i;

	if ( bBlown )
		return;
	bBlown = true;
	if ( Role == ROLE_Authority )
	{
		Blast(HitLocation);
		Tracers(HitLocation);
		class'KFFireGrid'.static.Heat(self, HitLocation, DamageRadius, 5.0);
	}
	if ( Level.NetMode != NM_DedicatedServer )
		Burst(HitLocation, HitNormal);
	for ( i = 0; i < ArrayCount(Beams); i++ )
		if ( Beams[i] != None )
			Beams[i].Kill();
	if ( FX != None )
		FX.Kill();
	Destroy();
}

// (the server) The burst: everything round it but players and their bots, less to the edge, flung away; props too
function Blast( vector C )
{
	local Actor A;
	local float D, K;
	local vector Dir;

	foreach VisibleCollidingActors(class'Actor', A, DamageRadius, C)
	{
		if ( A == self || A.bDeleteMe || (Pawn(A) != None && KFMonster(A) == None) || KFHumanPawn(A.Base) != None )
			continue;
		if ( Projectile(A) != None || A.Role != ROLE_Authority )
			continue;
		Dir = A.Location - C;
		D = FMax(VSize(Dir) - A.CollisionRadius, 0.0);
		K = 1.0 - 0.75 * FMin(D / DamageRadius, 1.0);
		A.TakeDamage(int(Damage * K), Instigator, A.Location - 0.5 * (A.CollisionHeight + A.CollisionRadius) * Normal(Dir),
			Normal(Dir + vect(0,0,60)) * MomentumTransfer * K, MyDamageType);
	}
}

// (the server) As Doom's BFG: tracers go out from the shooter in a fan the way the ball was fired, each striking the
// first specimen it meets
function Tracers( vector C )
{
	local vector Start, Dir, HL, HN;
	local rotator R, Fired;
	local int i, k;
	local Actor A;
	local KFMonster M;
	local KFBFGSpray S;
	local bool bSeen;

	if ( Instigator != None && Instigator.Health > 0 )
		Start = Instigator.Location + Instigator.EyePosition();
	else
		Start = C;
	Fired = rotator(InitDir);
	S = Spawn(class'KFBFGSpray',,, C);
	for ( i = 0; i < TracerCount; i++ )
	{
		R = Fired;
		R.Yaw = Fired.Yaw + int(TracerFan * (float(i) / float(TracerCount - 1) - 0.5));
		Dir = vector(R);
		A = Trace(HL, HN, Start + Dir * TracerRange, Start, true);
		if ( A != None && A.IsA('ExtendedZCollision') && A.Base != None )
			A = A.Base;
		M = KFMonster(A);
		if ( M == None || M.Health <= 0 )
			continue;
		M.TakeDamage(TracerDamage, Instigator, HL, Dir * 12000, class'DamTypeBFG');
		if ( S == None || S.NumEnds >= ArrayCount(S.Ends) )
			continue;
		bSeen = false;
		for ( k = 0; k < S.NumEnds; k++ )
			if ( VSize(S.Ends[k] - HL) < 60 )
				bSeen = true;
		if ( !bSeen )
		{
			S.Ends[S.NumEnds] = HL;
			S.NumEnds++;
		}
	}
}

// (each machine that draws it) The burst as seen and felt
simulated function Burst( vector C, vector N )
{
	local PlayerController PC;
	local vector Eye;
	local float D, K;

	Spawn(class'KFBFGBlastFX',,, C + N * 12, rotator(N));
	Spawn(class'KFScorchMark', self,, C, rotator(-N));
	Spawn(class'KFScorchMark', self,, C + 40 * VRand(), rotator(-N));
	class'KFBlast'.static.Ceiling(self, C + N * 20, 1.6);
	class'KFGib'.static.Blast(self, C + N * 12, 1.6);
	if ( Lens != None )
		Lens.Burst(C + N * 12);
	Lens = None;
	class'KFScreenFX'.static.Wave(Level, C + N * 12, 1.6);
	PC = Level.GetLocalPlayerController();
	if ( PC == None || PC.ViewTarget == None )
		return;
	Eye = PC.ViewTarget.Location;
	if ( Pawn(PC.ViewTarget) != None )
		Eye += Pawn(PC.ViewTarget).EyePosition();
	D = VSize(C - Eye);
	if ( D < DamageRadius * 2.5 )
		PC.ShakeView(vect(300,300,300), vect(10000,10000,10000), 2.0, vect(16,16,16), vect(800,800,800), 2.0);
	if ( D < BlindRange && FastTrace(C + N * 16, Eye) )
	{
		K = (1.0 - D / BlindRange) * (0.4 + 0.6 * FMax(Normal(C - Eye) dot vector(PC.GetViewRotation()), 0.0));
		if ( K > 0.05 )
			PC.ClientFlash(1.0, vect(500,1000,550) * FMin(K * 0.8, 0.5));
	}
}

simulated function Destroyed()
{
	local int i;

	// (a client that never saw it strike sees it burst where the server took it away)
	if ( !bBlown && Level.NetMode == NM_Client )
	{
		bBlown = true;
		Burst(Location, -Normal(Velocity));
	}
	for ( i = 0; i < ArrayCount(Beams); i++ )
		if ( Beams[i] != None )
			Beams[i].Kill();
	if ( FX != None )
		FX.Kill();
	Super.Destroyed();
}

defaultproperties
{
     CarryReach=380.000000
     CarryPull=400000.000000
     CarryLift=150000.000000
     ShredReach=140.000000
     HoldMin=0.400000
     HoldMax=0.800000
     PierceCount=3
     PierceDamage=600
     PierceMomentum=40000.000000
     ZapEvery=0.150000
     ZapRange=600.000000
     ZapDamage=45
     TracerCount=40
     TracerDamage=130
     TracerFan=16384.000000
     TracerRange=2600.000000
     BlindRange=2400.000000
     Speed=950.000000
     MaxSpeed=950.000000
     Damage=1200.000000
     DamageRadius=600.000000
     MomentumTransfer=150000.000000
     MyDamageType=Class'KFMod.DamTypeBFG'
     DrawType=DT_None
     AmbientSound=Sound'ONSBPSounds.ShockTank.ShockBallAmbient'
     SoundRadius=900.000000
     SoundVolume=255
     LightType=LT_Steady
     LightHue=85
     LightSaturation=40
     LightBrightness=230.000000
     LightRadius=14.000000
     bDynamicLight=True
     CollisionRadius=14.000000
     CollisionHeight=14.000000
     LifeSpan=8.000000
     bAlwaysRelevant=True
     NetPriority=3.000000
     bNetTemporary=False
     RemoteRole=ROLE_SimulatedProxy
}
