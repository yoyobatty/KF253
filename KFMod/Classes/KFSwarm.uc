//=============================================================================
// KFSwarm
//
// What the specimens of a wave know about each other, so that they come at the
// players as a crowd and not as a queue:
//  - how many are after each player, and which player has strayed from the rest
//    (a specimen choosing its victim spreads the crowd over the players);
//  - the free places round a player, for one that finds its way blocked by its
//    own kind (it goes round the outside of the others to a place of its own).
// With a swarm, a new specimen also makes for its victim at once instead of
// walking to a random place first.
// One per game, server only; KFGameType makes it when SwarmStrength is above 0.
//=============================================================================
class KFSwarm extends Info;

struct Prey
{
	var Pawn P;
	var int Hunters;
	var bool bAstray;
};

var array<Prey> Preys;

var float Strength;				// 0 to 1, KFGameType.SwarmStrength
var int NumPlaces, NumSidesteps;	// how often each thing was done, for whoever is tuning it

var() bool bStepRound;			// specimens step round each other and take places round a victim (off to try the rest without it)

// what the difficulty decides, set from the two lists below at the start of each wave
var() float StraightShare;		// this share of new specimens make for their victim at once, not first for a random place
var() float AstrayPull;			// a player who has strayed from the rest seems this much nearer
// Easy, Normal, Skilled, Elite, Suicidal
var() float StraightByDifficulty[5];
var() float AstrayByDifficulty[5];

// victims
var() float SpreadPerHunter;	// each specimen already after a player makes that player seem this much further
var() float SpreadMax;
var() float AstrayDist;			// a player this far from every other has strayed
// places round a victim
var() float SurroundRange;		// a blocked specimen this near its victim looks for a place round the victim
var() float SlotFill;			// how much of its own width a specimen is given on the ring (they squeeze: see KFMonster.ShrinkForCrowding)
var() int SlotTries;			// places tried to either side

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(1.0, true);
}

// The game's difficulty picks this wave's figures (GameDifficulty: 1.5 Easy, 3 Normal, 4 Skilled, 5 Elite, 7 Suicidal)
function SetDifficulty(float Difficulty)
{
	local int i;

	if ( Difficulty < 3 )
		i = 0;
	else if ( Difficulty < 4 )
		i = 1;
	else if ( Difficulty < 5 )
		i = 2;
	else if ( Difficulty < 7 )
		i = 3;
	else
		i = 4;
	StraightShare = StraightByDifficulty[i];
	AstrayPull = AstrayByDifficulty[i];
}

// Once a second: who is after whom, and who has strayed
function Timer()
{
	local Controller C;
	local KFMonsterController M;
	local int i, j, n;
	local vector D;
	local float Nearest;

	Preys.Length = 0;
	n = 0;
	for ( C=Level.ControllerList; C!=None; C=C.NextController )
		if ( C.bIsPlayer && C.Pawn != None && C.Pawn.Health > 0 && KFMonster(C.Pawn) == None )
		{
			Preys.Length = n + 1;
			Preys[n].P = C.Pawn;
			n++;
		}
	if ( n == 0 )
		return;
	for ( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		M = KFMonsterController(C);
		if ( M == None || M.Pawn == None || M.Pawn.Health <= 0 || M.Enemy == None )
			continue;
		for ( i=0; i<n; i++ )
			if ( Preys[i].P == M.Enemy )
			{
				Preys[i].Hunters++;
				break;
			}
	}
	for ( i=0; n>1 && i<n; i++ )
	{
		Nearest = 1000000.0;
		for ( j=0; j<n; j++ )
			if ( j != i )
			{
				D = Preys[j].P.Location - Preys[i].P.Location;
				Nearest = FMin(Nearest, VSize(D));
			}
		Preys[i].bAstray = (Nearest > AstrayDist);
	}
}

// How much further (or nearer) a player seems to a specimen choosing its victim
function float PreyBias(Pawn P, bool bMine)
{
	local int i, n;
	local float Bias;

	for ( i=0; i<Preys.Length; i++ )
		if ( Preys[i].P == P )
		{
			n = Preys[i].Hunters;
			if ( bMine )
				n--;
			Bias = FMin(float(Max(n, 0)) * SpreadPerHunter, SpreadMax);
			if ( Preys[i].bAstray )
				Bias -= AstrayPull;
			return Bias * Strength;
		}
	return 0;
}

// A specimen has run into another of its kind. True if it was given somewhere to step to.
function bool StepRound(KFMonsterController C, Pawn Blocker)
{
	local Pawn P, E;
	local vector Away, Spot, Side, Ahead;
	local float Ring, Dist, Out;
	local KFMonster M;
	local int Taken[16];
	local int NumTaken, Mine, Yaw, i, j, Try, Gap, SlotYaw;
	local bool bFree;

	P = C.Pawn;
	E = C.Enemy;
	if ( E != None )
	{
		Away = P.Location - E.Location;
		Away.Z = 0;
		Dist = VSize(Away);
	}
	if ( E != None && Dist < SurroundRange && Abs(P.Location.Z - E.Location.Z) < 100
		 && VSize(Blocker.Location - E.Location) < Dist )
	{
		// a free place on the ring round the victim, the nearest to either side of where it stands now
		Ring = E.CollisionRadius + P.CollisionRadius + 0.7 * KFMonster(P).MeleeRange;
		// (the angle one specimen takes up on that ring)
		SlotYaw = int(2.0 * Asin(FMin(0.9, SlotFill * P.default.CollisionRadius / Ring)) * 32768.0 / Pi);
		foreach P.CollidingActors(class'KFMonster', M, Ring + 60, E.Location)
		{
			// (one that has ended up on the victim's head stands in nobody's place)
			Spot = M.Location - E.Location;
			Spot.Z = 0;
			if ( M != P && M.Health > 0 && NumTaken < ArrayCount(Taken) && VSize(Spot) > 0.5 * Ring )
				Taken[NumTaken++] = rotator(Spot).Yaw & 65535;
		}
		Mine = rotator(Away).Yaw & 65535;
		for ( Try=1; Try<=SlotTries*2; Try++ )
		{
			// 1, -1, 2, -2, ...
			if ( (Try & 1) == 1 )
				Yaw = Mine + ((Try + 1) / 2) * SlotYaw;
			else
				Yaw = Mine - (Try / 2) * SlotYaw;
			Yaw = Yaw & 65535;
			bFree = true;
			for ( j=0; j<NumTaken; j++ )
			{
				Gap = Abs(Yaw - Taken[j]);
				if ( Gap > 32768 )
					Gap = 65536 - Gap;
				if ( Gap < (SlotYaw * 3) / 4 )
				{
					bFree = false;
					break;
				}
			}
			if ( !bFree )
				continue;
			Out = Ring;
			if ( Try > 2 )
			{
				// not the place next door: round the outside of those already there, one place at a time
				if ( (Try & 1) == 1 )
					Yaw = (Mine + SlotYaw) & 65535;
				else
					Yaw = (Mine - SlotYaw) & 65535;
				Out = FMax(Dist, Ring + 2.0 * P.CollisionRadius + 10.0);
			}
			Away.X = Cos(float(Yaw) * Pi / 32768.0);
			Away.Y = Sin(float(Yaw) * Pi / 32768.0);
			Spot = E.Location + Away * Out;
			Spot.Z = P.Location.Z;
			if ( P.FastTrace(Spot, P.Location) && P.FastTrace(Spot, E.Location) )
			{
				NumPlaces++;
				C.bAdjusting = true;
				C.AdjustLoc = Spot;
				return true;
			}
		}
		return false;
	}

	// on the way: round the one in front, on the side that is open
	if ( VSize(P.Acceleration) < 1 )
		return false;
	Ahead = Normal(P.Acceleration);
	Ahead.Z = 0;
	Away = Blocker.Location - P.Location;
	Away.Z = 0;
	if ( (Ahead Dot Normal(Away)) < 0.5 )
		return false;
	Side.X = Ahead.Y;
	Side.Y = -Ahead.X;
	if ( (Side Dot Away) > 0 )
		Side *= -1;
	Dist = Blocker.CollisionRadius + P.CollisionRadius + 10;
	for ( i=0; i<2; i++ )
	{
		Spot = P.Location + Dist * Side + 0.6 * Dist * Ahead;
		if ( P.FastTrace(Spot, P.Location) )
		{
			NumSidesteps++;
			C.bAdjusting = true;
			C.AdjustLoc = Spot;
			return true;
		}
		Side *= -1;
	}
	return false;
}

defaultproperties
{
	Strength=1.000000
	bStepRound=True
	StraightShare=0.500000
	AstrayPull=600.000000
	StraightByDifficulty(0)=0.100000
	StraightByDifficulty(1)=0.250000
	StraightByDifficulty(2)=0.500000
	StraightByDifficulty(3)=0.750000
	StraightByDifficulty(4)=1.000000
	AstrayByDifficulty(0)=0.000000
	AstrayByDifficulty(1)=300.000000
	AstrayByDifficulty(2)=600.000000
	AstrayByDifficulty(3)=800.000000
	AstrayByDifficulty(4)=1000.000000
	SpreadPerHunter=120.000000
	SpreadMax=1500.000000
	AstrayDist=1200.000000
	SurroundRange=350.000000
	SlotFill=0.800000
	SlotTries=4
}
