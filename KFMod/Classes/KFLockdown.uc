//=============================================================================
// KFLockdown - an Endless lockdown (KFEndlessGameType's EWT_Lockdown wave), Doom 2016 style: the players are shut in a
// ring of red energy where they stand (KFLockdownWall) and fight it out in stages, the specimens teleporting in round
// them (KFTeleportIn); glory kills give more in here (KFEndlessGameType.GloryReward). When the last stage is dead the
// wall sinks, everyone is paid, and the wave ends.
//
// The server runs it and keeps every player inside the wall; each player's own machine keeps its own player inside as
// well, so that the wall does not jerk them back. Every machine draws the wall and the HUD's word of it.
//=============================================================================
class KFLockdown extends Actor;

var() float MinRadius, MaxRadius;		// the ring's size, from the room it is made in
var() float SpotMinDist;				// a specimen teleports in no nearer than this to a player
var() int MaxAlive;						// ...and no more than this many of a stage at once (more with more players)
var() int ClearPay;						// dosh each player is paid when it is cleared, and this much again a wave
var() float StageGap;					// seconds between stages
var() float StragglerTime;				// with nothing killed for this long, the stage's last few are brought to the players

// (replicated) where it is, how big, how far on: Phase 0 rising, 1 fighting, 2 cleared, 3 between stages
var vector Center;
var float Radius;
var byte Stage, Stages, Remaining, Phase;

var KFEndlessGameType Game;
var float PhaseTime, NextSpawn, LastProgress;
var int LastCount;
var int ToSpawn, Pending;
var array<NavigationPoint> Spots;
var array<KFMonster> StageZeds;

var KFLockdownWall Wall;				// (each machine that draws it)

replication
{
	reliable if ( Role == ROLE_Authority )
		Center, Radius, Stage, Stages, Remaining, Phase;
}

// ---- the server

function Begin( KFEndlessGameType G )
{
	local NavigationPoint N, Best;
	local float D, BestD;

	Game = G;
	Center = G.PlayersMiddle();
	BestD = 900.0;
	for ( N = Level.NavigationPointList; N != None; N = N.NextNavigationPoint )
	{
		D = VSize(N.Location - Center);
		if ( D < BestD && PathNode(N) != None && FastTrace(N.Location, Center) )
		{
			BestD = D;
			Best = N;
		}
	}
	if ( Best != None )
		Center = Best.Location;
	Radius = MeasureRoom(Center);
	FindSpots();
	if ( Spots.Length < 4 )
	{
		Radius = MaxRadius;
		FindSpots();
	}
	SetLocation(Center);
	Stages = 3;
	if ( G.WaveNum >= 11 )
		Stages = 4;
	Phase = 0;
	PhaseTime = Level.TimeSeconds;
	PullPlayersIn();
	SetTimer(0.2, true);
}

// The ring's radius: the room's reach round C, looked at in sixteen directions (the most distant three not counted)
function float MeasureRoom( vector C )
{
	local array<float> Reach;
	local vector Dir, HitLocation, HitNormal;
	local float R;
	local int i, j;

	for ( i=0; i<16; i++ )
	{
		Dir.X = Cos(float(i) * Pi / 8.0);
		Dir.Y = Sin(float(i) * Pi / 8.0);
		Dir.Z = 0;
		if ( Trace(HitLocation, HitNormal, C + Dir * MaxRadius * 1.3, C, false) != None )
			R = VSize(HitLocation - C);
		else
			R = MaxRadius * 1.3;
		j = 0;
		while ( j < Reach.Length && Reach[j] < R )
			j++;
		Reach.Insert(j, 1);
		Reach[j] = R;
	}
	return FClamp(Reach[12] * 0.95, MinRadius, MaxRadius);
}

function FindSpots()
{
	local NavigationPoint N;

	Spots.Length = 0;
	for ( N = Level.NavigationPointList; N != None; N = N.NextNavigationPoint )
		if ( (PathNode(N) != None || PlayerStart(N) != None) && VSize((N.Location - Center) * vect(1,1,0)) < Radius - 70.0
			&& Abs(N.Location.Z - Center.Z) < 300.0 )
			Spots[Spots.Length] = N;
}

// Anyone outside the ring when it closes is pulled into it
function PullPlayersIn()
{
	local Controller C;
	local vector D;
	local int i, Tries;

	for ( C = Level.ControllerList; C != None; C = C.NextController )
	{
		if ( C.Pawn == None || C.Pawn.Health <= 0 || KFHumanPawn(C.Pawn) == None || Spots.Length == 0 )
			continue;
		D = (C.Pawn.Location - Center) * vect(1,1,0);
		if ( VSize(D) < Radius - 40.0 && Abs(C.Pawn.Location.Z - Center.Z) < 400.0 )
			continue;
		for ( Tries = 0; Tries < 8; Tries++ )
		{
			i = Rand(Spots.Length);
			if ( C.Pawn.SetLocation(Spots[i].Location + vect(0,0,10)) )
			{
				C.Pawn.Velocity = vect(0,0,0);
				Spawn(class'KFTeleportIn',,, C.Pawn.Location - vect(0,0,1) * C.Pawn.CollisionHeight);
				break;
			}
		}
	}
}

function int PlayersIn()
{
	local Controller C;
	local int n;

	for ( C = Level.ControllerList; C != None; C = C.NextController )
		if ( C.bIsPlayer && C.Pawn != None && C.Pawn.Health > 0 && KFHumanPawn(C.Pawn) != None )
			n++;
	return Max(n, 1);
}

function Timer()
{
	local int i;

	if ( Role < ROLE_Authority )
		return;
	for ( i=StageZeds.Length - 1; i>=0; i-- )
		if ( StageZeds[i] == None || StageZeds[i].bDeleteMe || StageZeds[i].Health <= 0 )
			StageZeds.Remove(i, 1);
	switch ( Phase )
	{
		case 0:
			if ( Level.TimeSeconds - PhaseTime > 2.5 )
				StartStage(1);
			break;
		case 1:
			if ( ToSpawn > 0 && Level.TimeSeconds > NextSpawn && StageZeds.Length + Pending < MaxAlive + 2 * PlayersIn() )
			{
				SpawnOne();
				NextSpawn = Level.TimeSeconds + 0.25 + 0.45 * FRand();
				if ( FRand() < 0.35 )
					NextSpawn = Level.TimeSeconds + 0.05;
			}
			if ( ToSpawn <= 0 && Pending <= 0 && StageZeds.Length == 0 )
			{
				if ( Stage < Stages )
				{
					Phase = 3;
					PhaseTime = Level.TimeSeconds;
				}
				else
					Clear();
			}
			break;
		case 3:
			if ( Level.TimeSeconds - PhaseTime > StageGap )
				StartStage(Stage + 1);
			break;
	}
	Remaining = Clamp(ToSpawn + Pending + StageZeds.Length, 0, 255);
	if ( Remaining != LastCount )
	{
		LastCount = Remaining;
		LastProgress = Level.TimeSeconds;
	}
	// a stage's last few stuck somewhere, or wandered off: they teleport in next to the players
	if ( Phase == 1 && ToSpawn <= 0 && Pending <= 0 && StageZeds.Length > 0 && StageZeds.Length <= 3
		&& Level.TimeSeconds - LastProgress > StragglerTime )
	{
		LastProgress = Level.TimeSeconds;
		for ( i=StageZeds.Length - 1; i>=0; i-- )
			BringIn(StageZeds[i]);
	}
}

// A straggler brought to the players, out of their sight to where they can see it, with a teleport's flash at each end;
// one that cannot be placed dies
function BringIn( KFMonster M )
{
	local NavigationPoint N, Best;
	local float Score, BestScore;
	local int Tries;

	if ( M == None || M.Health <= 0 || M.PlayerCanSeeMe() )
		return;
	BestScore = -100000.0;
	for ( Tries = 0; Tries < 12 && Spots.Length > 0; Tries++ )
	{
		N = Spots[Rand(Spots.Length)];
		Score = SpotScore(N.Location);
		if ( Score > BestScore )
		{
			BestScore = Score;
			Best = N;
		}
	}
	Spawn(class'KFTeleportIn',,, M.Location - vect(0,0,1) * M.CollisionHeight);
	if ( Best != None && BestScore > -50000.0 && M.SetLocation(Best.Location + vect(0,0,1) * (M.CollisionHeight * 0.5 + 10.0)) )
	{
		M.Velocity = vect(0,0,0);
		Spawn(class'KFTeleportIn',,, Best.Location - vect(0,0,30));
	}
	else
		M.KilledBy(M);
}

function StartStage( int N )
{
	Stage = N;
	Phase = 1;
	PhaseTime = Level.TimeSeconds;
	ToSpawn = Clamp(int((4.0 + 2.5 * float(N) + 0.6 * float(Game.WaveNum)) * Sqrt(float(PlayersIn()))), 5, 32);
	NextSpawn = Level.TimeSeconds;
}

function class<KFMonster> PickClass()
{
	local float R;
	local int W;
	local string C;

	W = Game.WaveNum + 1;
	R = FRand();
	// the last stage's first arrivals are the heavy ones, later on
	if ( Stage == Stages && ToSpawn > 0 && StageZeds.Length + Pending < 2 && W >= 6 )
	{
		if ( W >= 9 && FRand() < 0.5 )
			C = "KFChar.ZombieFleshPound";
		else
			C = "KFChar.ZombieScrake";
	}
	else if ( R < 0.30 )
		C = "KFChar.ZombieClot";
	else if ( R < 0.46 )
		C = "KFChar.ZombieGorefast";
	else if ( R < 0.62 )
		C = "KFChar.ZombieCrawler";
	else if ( R < 0.74 )
		C = "KFChar.ZombieStalker";
	else if ( R < 0.84 && W >= 4 )
		C = "KFChar.ZombieBloat";
	else if ( R < 0.92 && W >= 4 )
		C = "KFChar.ZombieSiren";
	else if ( R < 0.97 && W >= 6 )
		C = "KFChar.ZombieShade";
	else
		C = "KFChar.ZombieClot";
	return class<KFMonster>(DynamicLoadObject(C, class'Class'));
}

// One more specimen on its way in: at a spot in the ring not too near anyone, if it can be in someone's sight
function SpawnOne()
{
	local class<KFMonster> Z;
	local NavigationPoint N, Best;
	local KFTeleportIn T;
	local vector Floor, HitNormal, Face;
	local float Score, BestScore;
	local int Tries;

	Z = PickClass();
	if ( Z == None || Spots.Length == 0 )
	{
		ToSpawn--;
		return;
	}
	BestScore = -100000.0;
	for ( Tries = 0; Tries < 10; Tries++ )
	{
		N = Spots[Rand(Spots.Length)];
		Score = SpotScore(N.Location);
		if ( Score > BestScore )
		{
			BestScore = Score;
			Best = N;
		}
	}
	if ( Best == None || BestScore < -50000.0 )
		return;
	if ( Trace(Floor, HitNormal, Best.Location - vect(0,0,300), Best.Location, false) == None )
		Floor = Best.Location - vect(0,0,40);
	Face = NearestPlayer(Best.Location) - Best.Location;
	Face.Z = 0;
	T = Spawn(class'KFTeleportIn',,, Floor + vect(0,0,4), rotator(Face));
	if ( T == None )
		return;
	T.ZedClass = Z;
	T.Lock = self;
	Pending++;
	ToSpawn--;
}

// How good a spot is to come in at: not too near a player, best somewhere they are looking
function float SpotScore( vector Spot )
{
	local Controller C;
	local float D, Score, Near;
	local vector Dir;

	Near = 100000.0;
	for ( C = Level.ControllerList; C != None; C = C.NextController )
	{
		if ( C.Pawn == None || C.Pawn.Health <= 0 || KFHumanPawn(C.Pawn) == None )
			continue;
		D = VSize(Spot - C.Pawn.Location);
		Near = FMin(Near, D);
		Dir = Normal(Spot - C.Pawn.Location);
		if ( (Dir dot vector(C.Rotation)) > 0.5 )
			Score += 200.0;
	}
	if ( Near < SpotMinDist )
		return -100000.0;
	return Score + FMin(Near, 700.0) * 0.2 + FRand() * 150.0;
}

function vector NearestPlayer( vector Spot )
{
	local Controller C;
	local float D, Best;
	local vector Where;

	Best = 100000.0;
	Where = Center;
	for ( C = Level.ControllerList; C != None; C = C.NextController )
		if ( C.Pawn != None && C.Pawn.Health > 0 && KFHumanPawn(C.Pawn) != None )
		{
			D = VSize(Spot - C.Pawn.Location);
			if ( D < Best )
			{
				Best = D;
				Where = C.Pawn.Location;
			}
		}
	return Where;
}

// (KFTeleportIn) A specimen has come in (None if it could not be made)
function Arrived( KFMonster M )
{
	Pending = Max(0, Pending - 1);
	if ( M != None )
		StageZeds[StageZeds.Length] = M;
}

function Clear()
{
	local Controller C;
	local int Pay;

	Phase = 2;
	Remaining = 0;
	Pay = ClearPay + ClearPay * Game.WaveNum / 4;
	for ( C = Level.ControllerList; C != None; C = C.NextController )
		if ( C.bIsPlayer && C.PlayerReplicationInfo != None && C.Pawn != None && C.Pawn.Health > 0 )
		{
			C.PlayerReplicationInfo.Score += Pay;
			if ( C.Pawn.ShieldStrength < 100 )
				C.Pawn.AddShieldStrength(25);
		}
	if ( Game.bPowerUps )
		Game.DropPowerUp(Center + vect(0,0,20));
	Game.LockdownDone(self);
	LifeSpan = 6.0;
	SetTimer(0.0, false);
}

// ---- every machine

simulated function Tick( float DeltaTime )
{
	local PlayerController PC;
	local Controller C;

	if ( Radius <= 0.0 )
		return;
	if ( Level.NetMode != NM_DedicatedServer )
	{
		if ( Wall == None && Phase != 2 )
			MakeWall();
		else if ( Wall != None && Phase == 2 )
		{
			Wall.Sink();
			Wall = None;
		}
	}
	if ( Phase == 2 )
		return;
	// held inside: the server holds everyone, a player's own machine its own player
	if ( Role == ROLE_Authority )
	{
		for ( C = Level.ControllerList; C != None; C = C.NextController )
			if ( C.Pawn != None && C.Pawn.Health > 0 && KFHumanPawn(C.Pawn) != None )
				HoldIn(C.Pawn);
	}
	else
	{
		PC = Level.GetLocalPlayerController();
		if ( PC != None && PC.Pawn != None && PC.Pawn.Health > 0 )
			HoldIn(PC.Pawn);
	}
}

simulated function HoldIn( Pawn P )
{
	local vector D, N;
	local float Dist, Lim, Out;

	D = (P.Location - Center) * vect(1,1,0);
	Dist = VSize(D);
	Lim = Radius - P.CollisionRadius - 6.0;
	if ( Dist <= Lim || Dist > Radius + 500.0 || Abs(P.Location.Z - Center.Z) > 500.0 )
		return;
	N = D / Dist;
	P.SetLocation(P.Location - N * (Dist - Lim));
	Out = P.Velocity dot N;
	if ( Out > 0 )
		P.Velocity -= N * Out * 1.6;
}

simulated function MakeWall()
{
	local vector Floor, HitNormal;

	if ( Trace(Floor, HitNormal, Center - vect(0,0,400), Center, false) == None )
		Floor = Center - vect(0,0,44);
	Wall = Spawn(class'KFLockdownWall',,, Floor - vect(0,0,4));
	if ( Wall != None )
		Wall.Setup(Radius);
}

simulated function Destroyed()
{
	if ( Wall != None )
		Wall.Sink();
	Super.Destroyed();
}

defaultproperties
{
     MinRadius=520.000000
     MaxRadius=1050.000000
     SpotMinDist=330.000000
     MaxAlive=10
     ClearPay=250
     StageGap=2.500000
     StragglerTime=15.000000
     DrawType=DT_None
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
     NetUpdateFrequency=4.000000
}
