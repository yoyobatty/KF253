//=============================================================================
// KFFireGrid
// Fire as SS13's atmospherics have it, on the server. The floor is cut into cells (CellSize across, on whatever floor
// is there), each holding liquid fuel (the flamethrower's gas mode, a soaked specimen's drips, a burning body's fat),
// fuel vapour (the gas mode's cloud) and heat. Every StepTime the vapour spreads into the cells beside and thins;
// ground fires, burning specimens and bodies, the flamethrower's flames, blasts and lightning (Heat, HeatLine) heat
// the cells round them, and a burning cell heats the cells beside. A cell that gets hot enough with something to burn
// catches: its vapour goes up at once (Flash), hurting and lighting all in it, and passes its heat on to the vapour
// beside, so a cloud burns through in a rolling front; its fuel, and a wooden or grassy floor, burns as a ground fire
// (KFGridFire) for as long as it lasts. Burning specimens light those they touch, as SS13's fire stacks do. Only the
// server keeps the grid; what it shows goes to the clients as KFGasPuff (vapour), KFFuelPool (fuel), KFGasFlash (a
// flash) and KFGridFire (a fire).
//=============================================================================
class KFFireGrid extends Info;

struct FireCell
{
	var int		Key;
	var bool	bLive;
	var vector	Loc;			// the floor point in it
	var vector	Normal;
	var byte	Surface;
	var bool	bBurnable;		// wood or grass: the floor itself burns, once
	var bool	bBurnt;
	var float	Fuel;			// liquid fuel, in seconds of burning
	var float	Gas;			// vapour
	var float	Heat;			// catches at 1
	var int		Primed;			// heat from a flash beside, this step: it catches the next (a front, not all at once)
	var int		Nb[4];			// the cells beside: -1 not looked for yet, -2 nothing to spread to (a wall, a drop),
								// -3 plain floor with no cell yet
	var KFGridFire	Fire;
	var KFGasPuff	Puff;
	var KFFuelPool	Pool;
	var Pawn	Starter;		// whose fuel or vapour it is (its fire's harm is theirs)
	var float	Touched;		// when anything last happened in it
};
struct CellBucket
{
	var array<int> Ids;
};

var() float	CellSize, StepTime;
var() int	MaxCells, MaxFires;
var() float	GasSpread;			// share of the difference that flows into a cell beside, a step
var() float	GasKeep;			// share of the vapour left after a step
var() float	GasMake;			// vapour that spreads onto new floor beside
var() float	FuelFlow;			// share of the difference in fuel that runs into a cell beside, a step...
var() float	FuelFlowMin;		// ...from a cell holding more than this (a puddle spreads, a film stays)
var() float	HeatKeep;			// share of a cold cell's heat left after a step
var() float	HeatSpread;			// a burning cell's heat to each cell beside, a step
var() float	FlashSpread;		// a flash's heat to each cell beside
var() float	FlashDamage, FlashRadius, FlashPush;
var() float	BurnableFuel;		// what a wooden or grassy floor gives its fire
var() float	MinFireFuel, MaxCellFuel;
var() float	FuelBurnTime;		// seconds a ground fire burns on a unit of the grid's fuel
var() float	FireHeat;			// a ground fire's heat on its cell, a step, at size 1
var() float	BodyHeat, CorpseHeat, CorpseFat;
var() float	SoakDrip;			// fuel a soaked specimen drips on its cell, a step
var() float	ContactChance;		// a burning specimen lights one it touches, a step
var() float	EmptyFree;			// seconds an empty cell is kept
var() bool	bDebugLog;

var array<FireCell>	Cells;
var CellBucket		Buckets[128];
var array<float>	GasIn, HeatIn, FuelIn;
var KFFlameFireControl	FireControl;
var int				StepCount, NumFires, NumFlashes;
var float			NextLog;

// The grid, made by the first thing that needs it (bMake); the server's only
static function KFFireGrid Get( Actor A, optional bool bMake )
{
	local KFGameType G;

	if ( A == None || A.Level.NetMode == NM_Client )
		return None;
	G = KFGameType(A.Level.Game);
	if ( G == None )
		return None;
	if ( G.FireGrid == None || G.FireGrid.bDeleteMe )
	{
		if ( !bMake )
			return None;
		G.FireGrid = A.Spawn(class'KFFireGrid');
	}
	return G.FireGrid;
}

// ---- What the rest of the game tells it ---------------------------------------------------------------------------

// Fuel on the floor below P (the gas mode where it lands, a wall's runs down)
static function AddFuel( Actor A, vector P, float Amount, Pawn Starter, optional float Below )
{
	local KFFireGrid G;
	local int i;

	G = Get(A, true);
	if ( G == None )
		return;
	if ( Below <= 0 )
		Below = 260;
	i = G.CellAt(P, true, Below);
	if ( i >= 0 )
		G.FuelTo(i, Amount, Starter);
}

// Vapour over the floor below P
static function AddGas( Actor A, vector P, float Amount, Pawn Starter )
{
	local KFFireGrid G;
	local int i;

	G = Get(A, true);
	if ( G == None )
		return;
	i = G.CellAt(P, true, 400);
	if ( i < 0 )
		return;
	G.Cells[i].Gas = FMin(G.Cells[i].Gas + Amount, 4.0);
	if ( Starter != None )
		G.Cells[i].Starter = Starter;
	G.Cells[i].Touched = A.Level.TimeSeconds;
}

// Heat on the cells within Radius of P, less towards the edge (flames, blasts, lightning: they set off what is there)
static function Heat( Actor A, vector P, float Radius, float Amount )
{
	local KFFireGrid G;
	local int i;
	local float D;

	G = Get(A, false);
	if ( G == None )
		return;
	for ( i = 0; i < G.Cells.Length; i++ )
		if ( G.Cells[i].bLive && (G.Cells[i].Gas > 0 || G.Cells[i].Fuel > 0 || (G.Cells[i].bBurnable && !G.Cells[i].bBurnt)) )
		{
			D = VSize(G.Cells[i].Loc + vect(0,0,40) - P);
			if ( D < Radius + G.CellSize * 0.5 )
				G.Cells[i].Heat += Amount * FClamp(1.25 - D / (Radius + G.CellSize * 0.5), 0.3, 1.0);
		}
}

// ...along a line (a stream of flame)
static function HeatLine( Actor A, vector From, vector To, float Amount )
{
	local int n, Steps;

	if ( Get(A, false) == None )
		return;
	Steps = Clamp(int(VSize(To - From) / 120.0), 2, 10);
	for ( n = 1; n <= Steps; n++ )
		Heat(A, From + (To - From) * (float(n) / float(Steps)), 110, Amount);
}

// ---- Cells ---------------------------------------------------------------------------------------------------------

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(StepTime, true);
}

static final function int FloorDiv( float V, float Size )
{
	local int i;

	i = int(V / Size);
	if ( V < 0 && float(i) * Size != V )
		i--;
	return i;
}

// The floor below P within Below, and what it is made of; false for none, water or a wall
final function bool FloorUnder( vector P, float Below, out vector Spot, out vector Normal, out byte Surf )
{
	local Actor A;
	local Material Mat;
	local PhysicsVolume V;

	A = Trace(Spot, Normal, P - vect(0,0,1) * Below, P + vect(0,0,8), false,, Mat);
	if ( A == None || Normal.Z < 0.6 )
		return false;
	Surf = 0;
	if ( !A.IsA('LevelInfo') && A.SurfaceType != EST_Default )
		Surf = A.SurfaceType;
	else if ( Mat != None )
		Surf = Mat.SurfaceType;
	if ( Surf == 9 )
		return false;
	V = Level.GetPhysicsVolume(Spot + vect(0,0,8));
	return V == None || !V.bWaterVolume;
}

final function int KeyFor( vector Spot, out int B )
{
	local int X, Y, Z;

	X = FloorDiv(Spot.X, CellSize);
	Y = FloorDiv(Spot.Y, CellSize);
	Z = FloorDiv(Spot.Z + 24, 64);
	B = ((X * 31 + Y) * 17 + Z) & 127;
	return (X & 1023) | ((Y & 1023) << 10) | ((Z & 1023) << 20);
}

final function int Find( int Key, int B )
{
	local int i, n;

	for ( n = 0; n < Buckets[B].Ids.Length; n++ )
	{
		i = Buckets[B].Ids[n];
		if ( Cells[i].bLive && Cells[i].Key == Key )
			return i;
	}
	return -1;
}

// The cell on the floor below P (bMake: made if there is none yet); -1 if no floor there
final function int CellAt( vector P, bool bMake, optional float Below )
{
	local vector Spot, N;
	local byte Surf;
	local int Key, B, i;

	if ( Below <= 0 )
		Below = 200;
	if ( !FloorUnder(P, Below, Spot, N, Surf) )
		return -1;
	Key = KeyFor(Spot, B);
	i = Find(Key, B);
	if ( i >= 0 || !bMake )
		return i;
	return NewCell(Key, B, Spot, N, Surf);
}

final function int NewCell( int Key, int B, vector Spot, vector N, byte Surf )
{
	local int i, k, d;

	for ( i = 0; i < Cells.Length; i++ )
		if ( !Cells[i].bLive )
			break;
	if ( i == Cells.Length && Cells.Length >= MaxCells )
	{
		i = Stalest();
		if ( i < 0 )
			return -1;
		Free(i);
	}
	if ( i >= Cells.Length )
	{
		Cells.Length = i + 1;
		GasIn.Length = Cells.Length;
		HeatIn.Length = Cells.Length;
		FuelIn.Length = Cells.Length;
	}
	Cells[i].Key = Key;
	Cells[i].bLive = true;
	Cells[i].Loc = Spot;
	Cells[i].Normal = N;
	Cells[i].Surface = Surf;
	Cells[i].bBurnable = (Surf == 4 || Surf == 5);
	Cells[i].bBurnt = false;
	Cells[i].Fuel = 0;
	Cells[i].Gas = 0;
	Cells[i].Heat = 0;
	Cells[i].Primed = 0;
	for ( d = 0; d < 4; d++ )
		Cells[i].Nb[d] = -1;
	Cells[i].Fire = None;
	Cells[i].Puff = None;
	Cells[i].Pool = None;
	Cells[i].Starter = None;
	Cells[i].Touched = Level.TimeSeconds;
	Buckets[B].Ids[Buckets[B].Ids.Length] = i;
	// the cells beside that took this floor for bare look again
	for ( k = 0; k < Cells.Length; k++ )
		if ( Cells[k].bLive && k != i && VSize(Cells[k].Loc - Spot) < CellSize * 1.6 )
			for ( d = 0; d < 4; d++ )
				if ( Cells[k].Nb[d] == -3 )
					Cells[k].Nb[d] = -1;
	return i;
}

// The longest empty cell, to make room (-1: all in use)
final function int Stalest()
{
	local int i, Best;
	local float T;

	Best = -1;
	for ( i = 0; i < Cells.Length; i++ )
		if ( Cells[i].bLive && IsEmpty(i) && (Best < 0 || Cells[i].Touched < T) )
		{
			Best = i;
			T = Cells[i].Touched;
		}
	return Best;
}

final function bool IsEmpty( int i )
{
	return Cells[i].Gas <= 0 && Cells[i].Fuel <= 0 && Cells[i].Heat < 0.05 && !IsBurning(i);
}

final function Free( int i )
{
	local int B, n, k, d;

	KeyFor(Cells[i].Loc, B);
	for ( n = Buckets[B].Ids.Length - 1; n >= 0; n-- )
		if ( Buckets[B].Ids[n] == i )
			Buckets[B].Ids.Remove(n, 1);
	for ( k = 0; k < Cells.Length; k++ )
		for ( d = 0; d < 4; d++ )
			if ( Cells[k].Nb[d] == i )
				Cells[k].Nb[d] = -1;
	if ( Cells[i].Puff != None )
		Cells[i].Puff.Fade();
	if ( Cells[i].Pool != None )
		Cells[i].Pool.Destroy();
	Cells[i].Puff = None;
	Cells[i].Pool = None;
	Cells[i].Fire = None;
	Cells[i].bLive = false;
}

// The cell beside i in direction d (0 +X, 1 -X, 2 +Y, 3 -Y). Mode 0: one already there; 1: made if the floor goes on
// there; 2: made only if that floor burns (wood, grass). -1 if none.
final function int Beside( int i, int d, int Mode )
{
	local vector Off, From, To, Spot, N;
	local byte Surf;
	local int j, Key, B;

	j = Cells[i].Nb[d];
	if ( j >= 0 )
	{
		if ( Cells[j].bLive )
			return j;
		Cells[i].Nb[d] = -1;
		j = -1;
	}
	if ( j == -2 || (j == -3 && Mode != 1) )
		return -1;
	Off = vect(0,0,0);
	switch ( d )
	{
		case 0: Off.X = CellSize; break;
		case 1: Off.X = -CellSize; break;
		case 2: Off.Y = CellSize; break;
		default: Off.Y = -CellSize;
	}
	From = Cells[i].Loc + vect(0,0,40);
	To = From + Off;
	if ( !FastTrace(To, From) || !FloorUnder(To, 110, Spot, N, Surf) )
	{
		Cells[i].Nb[d] = -2;
		return -1;
	}
	Key = KeyFor(Spot, B);
	j = Find(Key, B);
	if ( j < 0 )
	{
		if ( Mode == 0 || (Mode == 2 && Surf != 4 && Surf != 5) )
		{
			Cells[i].Nb[d] = -3;
			return -1;
		}
		j = NewCell(Key, B, Spot, N, Surf);
		if ( j < 0 )
			return -1;
	}
	if ( j == i )
	{
		Cells[i].Nb[d] = -2;
		return -1;
	}
	Cells[i].Nb[d] = j;
	return j;
}

final function bool IsBurning( int i )
{
	return Cells[i].Fire != None && !Cells[i].Fire.bDeleteMe && !Cells[i].Fire.bDyingDown;
}

final function FuelTo( int i, float Amount, Pawn Starter )
{
	Cells[i].Fuel = FMin(Cells[i].Fuel + Amount, MaxCellFuel);
	if ( Starter != None )
		Cells[i].Starter = Starter;
	Cells[i].Touched = Level.TimeSeconds;
}

// ---- The step -------------------------------------------------------------------------------------------------------

function Timer()
{
	local int i, d, j;
	local float F;

	StepCount++;
	if ( FireControl == None || FireControl.bDeleteMe )
		foreach DynamicActors(class'KFFlameFireControl', FireControl)
			break;
	GasIn.Length = Cells.Length;
	HeatIn.Length = Cells.Length;
	FuelIn.Length = Cells.Length;
	for ( i = 0; i < Cells.Length; i++ )
	{
		GasIn[i] = 0;
		HeatIn[i] = 0;
		FuelIn[i] = 0;
	}

	HeatFromFires();
	FromBodies();

	NumFires = 0;
	for ( i = 0; i < Cells.Length; i++ )
	{
		if ( !Cells[i].bLive )
			continue;
		if ( Cells[i].Gas > 0 )
			for ( d = 0; d < 4; d++ )
			{
				if ( Cells[i].Gas > GasMake )
					j = Beside(i, d, 1);
				else
					j = Beside(i, d, 0);
				if ( j < 0 )
					continue;
				F = GasSpread * (Cells[i].Gas - Cells[j].Gas);
				if ( F > 0 )
				{
					GasIn[i] -= F;
					GasIn[j] += F;
				}
			}
		// a puddle runs out over the floor round it
		if ( Cells[i].Fuel > FuelFlowMin && !IsBurning(i) )
			for ( d = 0; d < 4; d++ )
			{
				j = Beside(i, d, 1);
				if ( j < 0 )
					continue;
				F = FuelFlow * (Cells[i].Fuel - Cells[j].Fuel);
				if ( F > 0.02 )
				{
					FuelIn[i] -= F;
					FuelIn[j] += F;
				}
			}
		if ( IsBurning(i) )
		{
			NumFires++;
			for ( d = 0; d < 4; d++ )
			{
				j = Beside(i, d, 2);
				if ( j >= 0 )
					HeatIn[j] += HeatSpread;
			}
		}
	}

	NumFlashes = 0;
	for ( i = 0; i < Cells.Length; i++ )
	{
		if ( !Cells[i].bLive )
			continue;
		Cells[i].Gas = (Cells[i].Gas + GasIn[i]) * GasKeep;
		if ( Cells[i].Gas < 0.015 )
			Cells[i].Gas = 0;
		if ( FuelIn[i] != 0 )
		{
			Cells[i].Fuel = FMax(Cells[i].Fuel + FuelIn[i], 0);
			if ( FuelIn[i] > 0 )
				Cells[i].Touched = Level.TimeSeconds;
		}
		if ( IsBurning(i) )
		{
			Cells[i].Heat = FMax(Cells[i].Heat * HeatKeep + HeatIn[i], 1.5);
			Cells[i].Touched = Level.TimeSeconds;
			if ( Cells[i].Gas >= 0.06 )
				Flash(i);
			if ( Cells[i].Fuel > 0.05 )
			{
				Cells[i].Fire.GridFeed(Cells[i].Fuel * FuelBurnTime);
				Cells[i].Fuel = 0;
			}
		}
		else
		{
			Cells[i].Fire = None;
			Cells[i].Heat += HeatIn[i];
			// (one a flash beside has just heated waits a step, so a cloud burns through as a front)
			if ( Cells[i].Primed <= StepCount )
			{
				if ( Cells[i].Heat >= 1.0 )
					Catch(i);
				if ( !IsBurning(i) )
					Cells[i].Heat *= HeatKeep;
			}
		}
		Show(i);
		if ( IsEmpty(i) && Level.TimeSeconds - Cells[i].Touched > EmptyFree )
			Free(i);
	}

	if ( bDebugLog && Level.TimeSeconds >= NextLog )
	{
		NextLog = Level.TimeSeconds + 1.0;
		Log("FIREGRID"@Summary(), 'KFFireGrid');
	}
}

final function string Summary()
{
	local int i, Live;
	local float G, F, H;

	for ( i = 0; i < Cells.Length; i++ )
		if ( Cells[i].bLive )
		{
			Live++;
			G += Cells[i].Gas;
			F += Cells[i].Fuel;
			H = FMax(H, Cells[i].Heat);
		}
	return "cells="$Live$" gas="$G$" fuel="$F$" maxheat="$H$" fires="$NumFires$" flashes="$NumFlashes$" t="$Level.TimeSeconds;
}

// Hot enough: its vapour flashes over, its fuel or floor burns; with nothing to burn it cools
final function Catch( int i )
{
	if ( Cells[i].Gas >= 0.06 )
		Flash(i);
	if ( Cells[i].Fuel >= MinFireFuel || (Cells[i].bBurnable && !Cells[i].bBurnt) )
		Burn(i);
	else if ( !IsBurning(i) && Cells[i].Gas <= 0 )
		Cells[i].Heat = FMin(Cells[i].Heat, 0.9);
}

// Its vapour goes up at once: a ball of flame, harm and fire to all in it, a push out, and its heat to the vapour beside
final function Flash( int i )
{
	local float G, R, D, Harm;
	local KFGasFlash F;
	local Pawn P;
	local vector C, Dir;
	local int k, j;

	G = FMin(Cells[i].Gas, 2.5);
	C = Cells[i].Loc + vect(0,0,40);
	R = FlashRadius * (0.8 + 0.3 * FMin(G, 1.5));
	F = Spawn(class'KFGasFlash',,, C, rotator(Cells[i].Normal));
	if ( F != None )
		F.SetSize(G);
	foreach VisibleCollidingActors(class'Pawn', P, R, C)
	{
		if ( P.Health <= 0 )
			continue;
		D = VSize(P.Location - C);
		Harm = FlashDamage * FMin(G, 1.5) * (1.0 - 0.6 * FMax(0, (D - P.CollisionRadius) / R));
		Dir = Normal(P.Location - C + vect(0,0,40));
		P.TakeDamage(Max(1, int(Harm)), Cells[i].Starter, P.Location, Dir * FlashPush * FMin(G, 1.5), class'DamTypeGasFlash');
	}
	Cells[i].Gas = 0;
	Cells[i].Heat = 2.0;
	Cells[i].Touched = Level.TimeSeconds;
	NumFlashes++;
	for ( k = 0; k < 4; k++ )
	{
		j = Beside(i, k, 0);
		if ( j >= 0 && Cells[j].Gas > 0 )
		{
			Cells[j].Heat += FlashSpread;
			Cells[j].Primed = StepCount + 1;
		}
	}
}

// Its fuel, and a wooden or grassy floor, burn as a ground fire
final function Burn( int i )
{
	local float F;

	if ( NumFires >= MaxFires )
		return;
	F = FMax(Cells[i].Fuel, MinFireFuel) * FuelBurnTime;
	if ( Cells[i].bBurnable && !Cells[i].bBurnt )
	{
		F += BurnableFuel;
		Cells[i].bBurnt = true;
	}
	Cells[i].Fire = Spawn(class'KFGridFire', Cells[i].Starter,, Cells[i].Loc + Cells[i].Normal * 2, rotator(Cells[i].Normal));
	if ( Cells[i].Fire == None || Cells[i].Fire.bDeleteMe )
	{
		Cells[i].Fire = None;
		return;
	}
	Cells[i].Fire.Instigator = Cells[i].Starter;
	Cells[i].Fire.GridFeed(F, true);
	Cells[i].Fuel = 0;
	Cells[i].Heat = 2.0;
	Cells[i].Touched = Level.TimeSeconds;
	NumFires++;
}

// The flamethrower's own ground fires heat their cells
final function HeatFromFires()
{
	local int n, i;
	local FlameGroundFire F;

	if ( FireControl == None )
		return;
	for ( n = 0; n < FireControl.Fires.Length; n++ )
	{
		F = FireControl.Fires[n];
		if ( F == None || F.bDeleteMe || F.bDyingDown || KFGridFire(F) != None )
			continue;
		i = CellAt(F.Location + vect(0,0,30), false, 120);
		if ( i >= 0 )
			HeatIn[i] += FireHeat * F.Size;
	}
}

// Specimens: soaked ones drip fuel where they go; burning ones heat their cells and light those they touch; burning
// bodies heat theirs, and their fat burns
final function FromBodies()
{
	local KFMonster M, O;
	local int i;
	local float Drip;

	foreach DynamicActors(class'KFMonster', M)
	{
		if ( M.bDeleteMe )
			continue;
		if ( M.Health > 0 )
		{
			if ( M.SoakFuel > 0 )
			{
				Drip = FMin(SoakDrip, M.SoakFuel);
				i = CellAt(M.Location, true, M.CollisionHeight + 80);
				if ( i >= 0 )
					FuelTo(i, Drip, M.SoakStarter);
				M.DripSoak(Drip);
			}
			if ( !M.bBurnified )
				continue;
			i = CellAt(M.Location, false, M.CollisionHeight + 80);
			if ( i >= 0 )
				HeatIn[i] += BodyHeat;
			foreach M.VisibleCollidingActors(class'KFMonster', O, M.CollisionRadius * 2 + 24, M.Location)
				if ( O != M && O.Health > 0 && !O.bBurnified && FRand() < ContactChance )
					O.TakeIncendiary(5, M.BurnInstigator);
		}
		else if ( M.bBurnified || M.CorpseBurnEnd > Level.TimeSeconds )
		{
			i = CellAt(M.Location + vect(0,0,20), true, 120);
			if ( i >= 0 )
			{
				HeatIn[i] += CorpseHeat;
				FuelTo(i, CorpseFat, None);
			}
		}
	}
}

// What the clients see of it
final function Show( int i )
{
	if ( Cells[i].Gas >= 0.05 )
	{
		if ( Cells[i].Puff == None || Cells[i].Puff.bDeleteMe )
			Cells[i].Puff = Spawn(class'KFGasPuff',,, Cells[i].Loc + vect(0,0,6), rotator(vect(0,0,1)));
		if ( Cells[i].Puff != None )
			Cells[i].Puff.SetThick(Cells[i].Gas);
	}
	else if ( Cells[i].Puff != None )
	{
		Cells[i].Puff.Fade();
		Cells[i].Puff = None;
	}
	if ( Cells[i].Fuel >= 0.2 && !IsBurning(i) )
	{
		if ( Cells[i].Pool == None || Cells[i].Pool.bDeleteMe )
			Cells[i].Pool = Spawn(class'KFFuelPool',,, Cells[i].Loc + Cells[i].Normal * 4, rotator(-Cells[i].Normal));
		if ( Cells[i].Pool != None )
			Cells[i].Pool.SetAmount(Cells[i].Fuel);
	}
	else if ( Cells[i].Pool != None )
	{
		Cells[i].Pool.Destroy();
		Cells[i].Pool = None;
	}
}

defaultproperties
{
     CellSize=96.000000
     StepTime=0.200000
     MaxCells=420
     MaxFires=48
     GasSpread=0.110000
     GasKeep=0.988000
     GasMake=0.120000
     FuelFlow=0.070000
     FuelFlowMin=0.800000
     HeatKeep=0.700000
     HeatSpread=0.400000
     FlashSpread=1.300000
     FlashDamage=40.000000
     FlashRadius=130.000000
     FlashPush=25000.000000
     BurnableFuel=3.000000
     MinFireFuel=0.250000
     MaxCellFuel=14.000000
     FuelBurnTime=5.000000
     FireHeat=0.350000
     BodyHeat=0.400000
     CorpseHeat=0.400000
     CorpseFat=0.050000
     SoakDrip=0.060000
     ContactChance=0.350000
     EmptyFree=25.000000
}
