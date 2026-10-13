// KFFloorMap - parts of the path network that only a KFElevator joins.
class KFFloorMap extends Info;

const NOFLOOR = 255;
const UNUSABLE_REACH = 642;

struct PawnFloorInfo
{
	var Pawn P;
	var byte Floor;
	var float Time;
};

var int NumFloors;
var array<NavigationPoint> Spots;
var array<byte> SpotFloor;
var array<NavigationPoint> LiftSpots;
var array<int> Parent;
var array<PawnFloorInfo> PawnFloors;
var array<byte> Occupied;
var bool bAnyOccupied;
var float OccupiedTime;

static final function bool IsLiftCenter(NavigationPoint N)
{
	return ( LiftCenter(N) != None && KFElevator(LiftCenter(N).MyLift) != None );
}

static final function bool IsLiftExit(NavigationPoint N)
{
	return ( LiftExit(N) != None && KFElevator(LiftExit(N).MyLift) != None );
}

static final function bool OtherFloor(byte A, byte B)
{
	return ( A != NOFLOOR && B != NOFLOOR && A != B );
}

final function int Root(int i)
{
	while ( Parent[i] != i )
	{
		Parent[i] = Parent[Parent[i]];
		i = Parent[i];
	}
	return i;
}

function Build()
{
	local NavigationPoint N;
	local array<NavigationPoint> Navs;
	local array<byte> RootFloor;
	local ReachSpec R;
	local int i, j, a, b;

	for ( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
	{
		N.visitedWeight = Navs.Length;
		Parent[Navs.Length] = Navs.Length;
		Navs[Navs.Length] = N;
	}
	for ( i=0; i<Navs.Length; i++ )
	{
		if ( IsLiftCenter(Navs[i]) )
			continue;
		for ( j=0; j<Navs[i].PathList.Length; j++ )
		{
			R = Navs[i].PathList[j];
			if ( R == None || R.End == None || (R.reachFlags & UNUSABLE_REACH) != 0 || IsLiftCenter(R.End) )
				continue;
			a = Root(i);
			b = Root(R.End.visitedWeight);
			if ( a != b )
				Parent[a] = b;
		}
	}
	RootFloor.Length = Navs.Length;
	for ( i=0; i<Navs.Length; i++ )
		RootFloor[i] = NOFLOOR;
	for ( i=0; i<Navs.Length; i++ )
	{
		if ( !IsLiftExit(Navs[i]) )
			continue;
		a = Root(i);
		if ( RootFloor[a] == NOFLOOR && NumFloors < NOFLOOR )
			RootFloor[a] = NumFloors++;
	}
	for ( i=0; i<Navs.Length; i++ )
	{
		a = RootFloor[Root(i)];
		if ( IsLiftCenter(Navs[i]) )
			LiftSpots[LiftSpots.Length] = Navs[i];
		else if ( a == NOFLOOR )
			continue;
		Spots[Spots.Length] = Navs[i];
		SpotFloor[SpotFloor.Length] = a;
	}
	Parent.Length = 0;
	Occupied.Length = NumFloors;
}

function SetLiftsBlocked(bool bBlock)
{
	local int i;

	for ( i=0; i<LiftSpots.Length; i++ )
		LiftSpots[i].bBlocked = bBlock;
}

function byte FloorAt(vector Loc)
{
	local vector Dir;
	local float D, BestD;
	local int i, Best;

	if ( NumFloors < 2 )
		return NOFLOOR;
	Best = -1;
	for ( i=0; i<Spots.Length; i++ )
	{
		Dir = Spots[i].Location - Loc;
		D = 4.f * Abs(Dir.Z);
		Dir.Z = 0;
		D += VSize(Dir);
		if ( Best < 0 || D < BestD )
		{
			Best = i;
			BestD = D;
		}
	}
	if ( Best < 0 )
		return NOFLOOR;
	return SpotFloor[Best];
}

function byte FloorOf(Pawn P)
{
	local int i;

	if ( NumFloors < 2 || P == None )
		return NOFLOOR;
	for ( i=PawnFloors.Length-1; i>=0; i-- )
	{
		if ( PawnFloors[i].P == None )
			PawnFloors.Remove(i, 1);
		else if ( PawnFloors[i].P == P )
			break;
	}
	if ( i < 0 )
	{
		i = PawnFloors.Length;
		PawnFloors.Length = i + 1;
		PawnFloors[i].P = P;
		PawnFloors[i].Time = -1.f;
	}
	if ( Level.TimeSeconds - PawnFloors[i].Time > 0.5f )
	{
		PawnFloors[i].Floor = FloorAt(P.Location);
		PawnFloors[i].Time = Level.TimeSeconds;
	}
	return PawnFloors[i].Floor;
}

function UpdateOccupied()
{
	local Controller C;
	local byte F;
	local int i;

	if ( OccupiedTime == Level.TimeSeconds )
		return;
	OccupiedTime = Level.TimeSeconds;
	bAnyOccupied = false;
	for ( i=0; i<NumFloors; i++ )
		Occupied[i] = 0;
	for ( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if ( MonsterController(C) != None || C.Pawn == None || C.Pawn.Health <= 0 )
			continue;
		F = FloorOf(C.Pawn);
		if ( F != NOFLOOR )
		{
			Occupied[F] = 1;
			bAnyOccupied = true;
		}
	}
}

function bool FloorOccupied(byte F)
{
	if ( NumFloors < 2 || F == NOFLOOR )
		return true;
	UpdateOccupied();
	return ( !bAnyOccupied || Occupied[F] != 0 );
}
