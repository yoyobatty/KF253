//=============================================================================
// KFHoldPlan - the place the bots' team holds through a wave, as Killing
// Floor players do (area holding): a spot with a few ways in that the team can
// watch, each bot at a post looking down one way in. One for the level, on the
// server.
//
// The map's path network is read once (Build). For a middle node it works out:
//   Area   the nodes within AreaRadius of the middle along the paths that the
//          middle can see: the room the team stands in;
//   lanes  the separate ways specimens can come in: as many paths from the
//          spawn areas into the Area as share no node outside it (a max flow
//          with every outside node worth one), on the specimens' own network;
//   faces  for each lane, the furthest node along it, outward, that the middle
//          can still see: where a bot watching that lane looks;
//   posts  for each lane a node of the Area that sees its face, back from the
//          way in; the bots take them lane by lane, then share.
//=============================================================================
class KFHoldPlan extends Info
	config(KFHoldSpots);

const LANEMAX = 8;

// A map's camp spot, as players know them: "MapName=NodeName". StockSpots are the ones proven in test games;
// ExtraSpots (KFHoldSpots.ini, [KFMod.KFHoldPlan] ExtraSpots=KF-MyMap=PathNode12) adds or overrides others. A map
// with none is played as before (the bots roam), unless bHoldUnknownMaps lets the rules below choose a spot: most
// spots they rate well still did worse than roaming when tested.
var() array<string> StockSpots;
var() config array<string> ExtraSpots;
var() config bool bHoldUnknownMaps;

var() float AreaRadius;		// how far along the paths the held area reaches
var() float Eye;			// height above a node that sight lines are drawn from
var() float PostBack;		// a post this far back from the way in it watches, at least
var() float PostApart;		// two posts at least this far apart
var() string ForcedSpot;	// (tests) the node to hold, by name; empty: none

// the path network
var array<NavigationPoint> Nodes;
var array<int> EdgeStart, EdgeTo;	// links of node i: EdgeTo[EdgeStart[i] .. EdgeStart[i+1]-1]
var array<float> EdgeLen;
var array<byte> EdgeHuman;			// 1 where a player can go (not into a zombie-only zone, wide enough)
var array<int> RevStart, RevEdge;	// links into node i: edge numbers RevEdge[RevStart[i] .. RevStart[i+1]-1]
var array<int> EdgeFrom;
var array<int> Sources;				// the nodes next to the spawn areas
var bool bBuilt;

// the hold
var int Center;
var array<int> Area;
var array<int> LaneEntry, LaneFace;
var array<int> Posts, PostLane;
var array<Controller> PostOwner;
var bool bReady;
var int AnnouncedCenter;			// the centre a bot last told the team about

// the max flow (per spot)
var array<int> ArcTo, ArcCap, ArcNext, Head, PrevArc, Queue;
var array<byte> InArea;

// choosing the spot: every node a player can get to is scored, a few a tick
var() int MaxPosts;			// posts made, at most (a team of six)
var() bool bCoverBlindSide;		// round a player who has stopped: the free post on the way in furthest behind his back first
var() int MinRoom;			// a spot needs at least this many nodes in its area (room for the team)
var() int EvalPerTick;
var array<float> SpawnDist;	// path length from the nearest spawn area, on the specimens' network
var array<float> StartDist;	// path length from the player starts, on the players' network (-1: cannot get there)
var array<float> Clearance;	// free distance round a node, averaged over 8 directions (-1: not yet measured)
var array<float> SpotScore;
var int NextEval, BestSpot, SecondSpot;
var bool bEvaluating, bChosen;

// a player leading: once he has stayed put a while, the hold is round him (the bots cover the other ways in)
var() float LeaderSettleTime;	// seconds the player stays within LeaderSettleRadius before the bots take posts round him
var() float LeaderSettleRadius;
var() float LeaderLeaveRadius;	// once settled, the hold round him stays put until he is this far from its centre
var bool bLeaderHeld;
var float LeaderHeldTime;		// when a bot last found him still holding
var Pawn LeaderPawn;
var vector LeaderSpot;
var float LeaderSince;
var int LeaderCenter;			// the node the hold round the player is centred on (-1: none)

static function KFHoldPlan Get(Actor Ref)
{
	local KFHoldPlan P;

	if ( Ref == None || Ref.Level.NetMode == NM_Client )
		return None;
	foreach Ref.DynamicActors(class'KFHoldPlan', P)
		return P;
	return Ref.Spawn(class'KFHoldPlan');
}

// The middle node by name, for tests
final function int IndexOfName(string S)
{
	local int i;

	for ( i=0; i<Nodes.Length; i++ )
		if ( string(Nodes[i].Name) ~= S )
			return i;
	return -1;
}

final function bool HumanOnlyBlocker(BlockingVolume V)
{
	local bool bPlayers, bMonsters;
	local int i;

	if ( V == None || !V.bClassBlocker )
		return false;
	for ( i=0; i<V.BlockedClasses.Length; i++ )
	{
		bPlayers = bPlayers || ClassIsChildOf(V.BlockedClasses[i], class'KFHumanPawn');
		bMonsters = bMonsters || ClassIsChildOf(V.BlockedClasses[i], class'KFMonster');
	}
	return ( bPlayers && !bMonsters );
}

// The path network as arrays, the spawn areas' nodes
final function Build()
{
	local NavigationPoint N;
	local ReachSpec R;
	local array<BlockingVolume> Zones;
	local BlockingVolume BV;
	local ZombieVolume ZV;
	local vector HL, HN;
	local int i, k, z, Best1, Best2;
	local float D, D1, D2;
	local byte bHuman;

	bBuilt = true;
	foreach AllActors(class'BlockingVolume', BV)
		if ( HumanOnlyBlocker(BV) )
			Zones[Zones.Length] = BV;
	for ( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
	{
		N.visitedWeight = Nodes.Length;
		Nodes[Nodes.Length] = N;
	}
	for ( i=0; i<Nodes.Length; i++ )
	{
		EdgeStart[i] = EdgeTo.Length;
		for ( k=0; k<Nodes[i].PathList.Length; k++ )
		{
			R = Nodes[i].PathList[k];
			if ( R == None || R.End == None || R.bForced || LiftCenter(R.End) != None || LiftCenter(Nodes[i]) != None
				|| (R.reachFlags & (2|4|32|64|128)) != 0 )
				continue;
			bHuman = 1;
			if ( R.CollisionRadius < 25 )
				bHuman = 0;
			for ( z=0; bHuman == 1 && z<Zones.Length; z++ )
				if ( Zones[z].Encompasses(R.End) || !Zones[z].TraceThisActor(HL, HN, R.End.Location, Nodes[i].Location) )
					bHuman = 0;
			EdgeTo[EdgeTo.Length] = R.End.visitedWeight;
			EdgeFrom[EdgeFrom.Length] = i;
			EdgeLen[EdgeLen.Length] = R.Distance;
			EdgeHuman[EdgeHuman.Length] = bHuman;
		}
	}
	EdgeStart[Nodes.Length] = EdgeTo.Length;
	// the same links listed by where they end
	RevStart.Length = Nodes.Length + 1;
	for ( i=0; i<=Nodes.Length; i++ )
		RevStart[i] = 0;
	for ( k=0; k<EdgeTo.Length; k++ )
		RevStart[EdgeTo[k] + 1] += 1;
	for ( i=0; i<Nodes.Length; i++ )
		RevStart[i + 1] += RevStart[i];
	RevEdge.Length = EdgeTo.Length;
	Queue.Length = Nodes.Length;
	for ( i=0; i<Nodes.Length; i++ )
		Queue[i] = RevStart[i];
	for ( k=0; k<EdgeTo.Length; k++ )
	{
		RevEdge[Queue[EdgeTo[k]]] = k;
		Queue[EdgeTo[k]] += 1;
	}
	foreach AllActors(class'ZombieVolume', ZV)
	{
		Best1 = -1;
		Best2 = -1;
		D1 = 100000000.0;
		D2 = 100000000.0;
		for ( i=0; i<Nodes.Length; i++ )
		{
			if ( EdgeStart[i + 1] == EdgeStart[i] )
				continue;
			D = VSize(Nodes[i].Location - ZV.Location);
			if ( D < D1 )
			{
				D2 = D1;
				Best2 = Best1;
				D1 = D;
				Best1 = i;
			}
			else if ( D < D2 )
			{
				D2 = D;
				Best2 = i;
			}
		}
		if ( Best1 >= 0 )
			Sources[Sources.Length] = Best1;
		if ( Best2 >= 0 )
			Sources[Sources.Length] = Best2;
	}
}

// Path lengths from one node over the links players can use, out to Limit
final function Reach(int From, float Limit, out array<float> Dist)
{
	local array<byte> Done;
	local int i, k, u, v;
	local float Best, D;

	Dist.Length = Nodes.Length;
	Done.Length = Nodes.Length;
	for ( i=0; i<Nodes.Length; i++ )
	{
		Dist[i] = -1.0;
		Done[i] = 0;
	}
	Dist[From] = 0.0;
	while ( true )
	{
		u = -1;
		Best = 0.0;
		for ( i=0; i<Nodes.Length; i++ )
			if ( Done[i] == 0 && Dist[i] >= 0.0 && (u < 0 || Dist[i] < Best) )
			{
				u = i;
				Best = Dist[i];
			}
		if ( u < 0 || Best > Limit )
			break;
		Done[u] = 1;
		for ( k=EdgeStart[u]; k<EdgeStart[u + 1]; k++ )
		{
			if ( EdgeHuman[k] == 0 )
				continue;
			v = EdgeTo[k];
			D = Best + EdgeLen[k];
			if ( Dist[v] < 0.0 || D < Dist[v] )
				Dist[v] = D;
		}
	}
}

final function bool Sees(int A, int B)
{
	if ( A == B )
		return true;
	return FastTrace(Nodes[B].Location + Eye * vect(0,0,1), Nodes[A].Location + Eye * vect(0,0,1));
}

final function AddArc(int U, int V, int Cap)
{
	ArcTo[ArcTo.Length] = V;
	ArcCap[ArcCap.Length] = Cap;
	ArcNext[ArcNext.Length] = Head[U];
	Head[U] = ArcTo.Length - 1;
	ArcTo[ArcTo.Length] = U;
	ArcCap[ArcCap.Length] = 0;
	ArcNext[ArcNext.Length] = Head[V];
	Head[V] = ArcTo.Length - 1;
}

// The ways in: node-disjoint paths from the spawn areas into the Area (vertices: 0 source, 1 sink, 2+2i node i in,
// 3+2i node i out). For each lane, the first node outside the Area and the furthest one the middle sees.
final function FindLanes()
{
	local int i, k, v, u, a, Q, QEnd, Big, Flow, Last, Prev;
	local array<int> Path;
	local bool bVisible;

	Big = 1000;
	ArcTo.Length = 0;
	ArcCap.Length = 0;
	ArcNext.Length = 0;
	Head.Length = 2 + 2 * Nodes.Length;
	for ( i=0; i<Head.Length; i++ )
		Head[i] = -1;
	InArea.Length = Nodes.Length;
	for ( i=0; i<Nodes.Length; i++ )
		InArea[i] = 0;
	for ( i=0; i<Area.Length; i++ )
		InArea[Area[i]] = 1;
	for ( i=0; i<Nodes.Length; i++ )
	{
		if ( InArea[i] == 1 )
		{
			AddArc(2 + 2 * i, 1, Big);
			continue;
		}
		AddArc(2 + 2 * i, 3 + 2 * i, 1);
		// (links both ways: a specimen goes wherever a link goes either way)
		for ( k=EdgeStart[i]; k<EdgeStart[i + 1]; k++ )
		{
			AddArc(3 + 2 * i, 2 + 2 * EdgeTo[k], Big);
			if ( InArea[EdgeTo[k]] == 0 )
				AddArc(3 + 2 * EdgeTo[k], 2 + 2 * i, Big);
		}
	}
	for ( i=0; i<Sources.Length; i++ )
		if ( InArea[Sources[i]] == 0 )
		{
			AddArc(0, 2 + 2 * Sources[i], Big);
			AddArc(2 + 2 * Sources[i], 3 + 2 * Sources[i], Big);
		}

	LaneEntry.Length = 0;
	LaneFace.Length = 0;
	PrevArc.Length = Head.Length;
	Queue.Length = Head.Length;
	for ( Flow=0; Flow<LANEMAX; Flow++ )
	{
		for ( i=0; i<PrevArc.Length; i++ )
			PrevArc[i] = -2;
		PrevArc[0] = -1;
		Queue[0] = 0;
		Q = 0;
		QEnd = 1;
		while ( Q < QEnd && PrevArc[1] == -2 )
		{
			u = Queue[Q++];
			for ( a=Head[u]; a>=0; a=ArcNext[a] )
				if ( ArcCap[a] > 0 && PrevArc[ArcTo[a]] == -2 )
				{
					PrevArc[ArcTo[a]] = a;
					Queue[QEnd++] = ArcTo[a];
				}
		}
		if ( PrevArc[1] == -2 )
			break;
		// push one unit along it, and note its nodes (sink end first)
		Path.Length = 0;
		v = 1;
		while ( PrevArc[v] >= 0 )
		{
			a = PrevArc[v];
			ArcCap[a] -= 1;
			ArcCap[a ^ 1] += 1;
			u = ArcTo[a ^ 1];
			if ( v >= 2 && (v & 1) == 0 )
				Path[Path.Length] = (v - 2) / 2;
			v = u;
		}
		// Path runs from the Area outward: the first outside node is the way in; the face is the last one seen
		Last = -1;
		Prev = -1;
		bVisible = true;
		for ( i=0; i<Path.Length; i++ )
		{
			k = Path[i];
			if ( InArea[k] == 1 )
				continue;
			if ( Prev < 0 )
				Prev = k;
			if ( bVisible && Sees(Center, k) )
				Last = k;
			else
				bVisible = false;
		}
		if ( Prev < 0 )
			continue;
		if ( Last < 0 )
			Last = Prev;
		LaneEntry[LaneEntry.Length] = Prev;
		LaneFace[LaneFace.Length] = Last;
	}
	// (no way in found: nothing to watch but the middle)
	if ( LaneEntry.Length == 0 )
	{
		LaneEntry[0] = Center;
		LaneFace[0] = Center;
	}
}

// Posts: for each lane, the Area node that sees the lane's face, as far from the way in as is still within
// PostBack of it or more, and apart from the posts already taken; then more of them, lane by lane
final function FindPosts()
{
	local int i, j, k, Lane, Best, Round, Fewest, Count;
	local float D, BestScore, Score;
	local bool bTaken;

	Posts.Length = 0;
	PostLane.Length = 0;
	PostOwner.Length = 0;
	for ( Round=0; Round<2; Round++ )
		for ( Lane=0; Lane<LaneEntry.Length; Lane++ )
		{
			Best = -1;
			BestScore = 0.0;
			for ( i=0; i<Area.Length; i++ )
			{
				bTaken = false;
				for ( j=0; j<Posts.Length; j++ )
					if ( Posts[j] == Area[i] || VSize(Nodes[Posts[j]].Location - Nodes[Area[i]].Location) < PostApart )
						bTaken = true;
				if ( bTaken || !StandSpot(Area[i]) || !Sees(Area[i], LaneFace[Lane]) )
					continue;
				D = VSize(Nodes[Area[i]].Location - Nodes[LaneEntry[Lane]].Location);
				// back from the way in, but not so far that the middle of the room is lost
				Score = FMin(D, PostBack * 2.0) - 0.5 * VSize(Nodes[Area[i]].Location - Nodes[Center].Location);
				if ( Best < 0 || Score > BestScore )
				{
					Best = Area[i];
					BestScore = Score;
				}
			}
			if ( Best >= 0 )
			{
				Posts[Posts.Length] = Best;
				PostLane[PostLane.Length] = Lane;
				PostOwner[PostOwner.Length] = None;
			}
		}
	// room for everyone: more posts on the area's other nodes, apart from the rest, each watching the way in it sees
	// that has the fewest (players spread over a room, they do not stand on one another)
	for ( i=0; i<Area.Length && Posts.Length < MaxPosts; i++ )
	{
		if ( !StandSpot(Area[i]) )
			continue;
		bTaken = false;
		for ( j=0; j<Posts.Length; j++ )
			if ( Posts[j] == Area[i] || VSize(Nodes[Posts[j]].Location - Nodes[Area[i]].Location) < PostApart )
				bTaken = true;
		if ( bTaken )
			continue;
		Lane = -1;
		Fewest = 1000;
		for ( k=0; k<LaneFace.Length; k++ )
		{
			if ( !Sees(Area[i], LaneFace[k]) )
				continue;
			Count = 0;
			for ( j=0; j<PostLane.Length; j++ )
				if ( PostLane[j] == k )
					Count++;
			if ( Count < Fewest )
			{
				Fewest = Count;
				Lane = k;
			}
		}
		if ( Lane < 0 )
			continue;
		Posts[Posts.Length] = Area[i];
		PostLane[PostLane.Length] = Lane;
		PostOwner[PostOwner.Length] = None;
	}
	if ( Posts.Length == 0 )
	{
		Posts[0] = Center;
		PostLane[0] = 0;
		PostOwner[0] = None;
	}
}

// A node a bot can stand at and stay: not one that moves him on (a teleporter, a lift, a jump pad) or that he only
// reaches with a special jump
final function bool StandSpot(int i)
{
	local NavigationPoint N;

	N = Nodes[i];
	return !N.bBlocked && Teleporter(N) == None && LiftCenter(N) == None && LiftExit(N) == None && JumpPad(N) == None
		&& !N.IsA('JumpSpot');
}

// Hold the area round node C
final function SetCenter(int C)
{
	local array<float> Dist;
	local int i;

	Center = C;
	Reach(C, AreaRadius, Dist);
	Area.Length = 0;
	for ( i=0; i<Nodes.Length; i++ )
		if ( Dist[i] >= 0.0 && Dist[i] <= AreaRadius && Sees(C, i) )
			Area[Area.Length] = i;
	FindLanes();
	FindPosts();
	bReady = true;
	LogPlan();
}

final function LogPlan()
{
	local string S;
	local int i;

	S = "HOLD "$Nodes[Center].Name$" area="$Area.Length$" lanes="$LaneEntry.Length$" posts=";
	for ( i=0; i<Posts.Length; i++ )
		S = S$Nodes[Posts[i]].Name$"/"$Nodes[LaneFace[PostLane[i]]].Name$" ";
	log(S);
}

// Path lengths from many nodes at once (bHuman: over the links players can use, one way; else the specimens'
// network both ways), no limit
final function ReachFrom(array<int> From, bool bHuman, out array<float> Dist)
{
	local array<byte> Done;
	local int i, k, u, v, n;
	local float Best, D;

	n = Nodes.Length;
	Dist.Length = n;
	Done.Length = n;
	for ( i=0; i<n; i++ )
	{
		Dist[i] = -1.0;
		Done[i] = 0;
	}
	for ( i=0; i<From.Length; i++ )
		Dist[From[i]] = 0.0;
	while ( true )
	{
		u = -1;
		Best = 0.0;
		for ( i=0; i<n; i++ )
			if ( Done[i] == 0 && Dist[i] >= 0.0 && (u < 0 || Dist[i] < Best) )
			{
				u = i;
				Best = Dist[i];
			}
		if ( u < 0 )
			break;
		Done[u] = 1;
		for ( k=EdgeStart[u]; k<EdgeStart[u + 1]; k++ )
		{
			if ( bHuman && EdgeHuman[k] == 0 )
				continue;
			v = EdgeTo[k];
			D = Best + EdgeLen[k];
			if ( Dist[v] < 0.0 || D < Dist[v] )
				Dist[v] = D;
		}
		// (the specimens' network is taken both ways: walk the links into u too)
		if ( !bHuman )
			for ( k=RevStart[u]; k<RevStart[u + 1]; k++ )
			{
				v = EdgeFrom[RevEdge[k]];
				D = Best + EdgeLen[RevEdge[k]];
				if ( Dist[v] < 0.0 || D < Dist[v] )
					Dist[v] = D;
			}
	}
}

final function float NodeClearance(int i)
{
	local vector Dir, HL, HN;
	local float Sum, D;
	local int k;

	if ( Clearance[i] >= 0.0 )
		return Clearance[i];
	for ( k=0; k<8; k++ )
	{
		Dir.X = Cos(float(k) * 0.785398);
		Dir.Y = Sin(float(k) * 0.785398);
		Dir.Z = 0;
		if ( Trace(HL, HN, Nodes[i].Location + Dir * 600, Nodes[i].Location, false) == None )
			D = 600;
		else
			D = VSize(HL - Nodes[i].Location);
		Sum += D;
	}
	Clearance[i] = Sum / 8.0;
	return Clearance[i];
}

// How good node C is as the middle of a hold (the same rules as KFAssess/holdspots.py): two ways in is the classic
// hold, one a dead end, more an open area; long views down the ways in; room for the team, not a cramped one; not by
// a spawn area
final function float ScoreSpot(int C)
{
	local array<float> Dist;
	local int i, Lanes;
	local float Depth, Clr, S;

	if ( StartDist[C] < 0.0 || !StandSpot(C) || EdgeStart[C + 1] == EdgeStart[C] )
		return -100.0;
	Center = C;
	Reach(C, AreaRadius, Dist);
	Area.Length = 0;
	for ( i=0; i<Nodes.Length; i++ )
		if ( Dist[i] >= 0.0 && Dist[i] <= AreaRadius && Sees(C, i) )
			Area[Area.Length] = i;
	if ( Area.Length < MinRoom )
		return -100.0;
	FindLanes();
	Lanes = LaneEntry.Length;
	if ( Lanes == 0 )
		S = -3;
	else if ( Lanes == 1 )
		S = -2;
	else if ( Lanes == 2 )
		S = 2;
	else if ( Lanes == 3 )
		S = 1;
	else
		S = 4 - Lanes;
	for ( i=0; i<Lanes; i++ )
		Depth += VSize(Nodes[LaneFace[i]].Location - Nodes[LaneEntry[i]].Location);
	if ( Lanes > 0 )
		S += FMin(Depth / Lanes, 1200.0) / 400.0;
	S += FMin(Area.Length, 10) / 5.0;
	for ( i=0; i<Area.Length; i++ )
		Clr += NodeClearance(Area[i]);
	if ( Clr / Area.Length < 120.0 )
		S -= 2.0;
	if ( SpawnDist[C] >= 0.0 && SpawnDist[C] < 800.0 )
		S -= 3.0;
	else if ( SpawnDist[C] >= 0.0 && SpawnDist[C] < 1500.0 )
		S -= 1.0;
	return S;
}

// Score the next few nodes; when all are done, hold the best
final function EvaluateSome()
{
	local int i, n;
	local float S;

	for ( n=0; n<EvalPerTick && NextEval<Nodes.Length; n++ )
	{
		i = NextEval++;
		S = ScoreSpot(i);
		SpotScore[i] = S;
		if ( S > -100.0 && (BestSpot < 0 || S > SpotScore[BestSpot]) )
			BestSpot = i;
	}
	if ( NextEval < Nodes.Length )
		return;
	bEvaluating = false;
	bChosen = true;
	// the next best a good way off: where to fall back to (not used yet)
	SecondSpot = -1;
	for ( i=0; i<Nodes.Length; i++ )
		if ( i != BestSpot && SpotScore[i] > -100.0 && VSize(Nodes[i].Location - Nodes[Max(BestSpot, 0)].Location) > 1000.0
			&& (SecondSpot < 0 || SpotScore[i] > SpotScore[SecondSpot]) )
			SecondSpot = i;
	if ( BestSpot >= 0 )
	{
		log("KFHoldPlan: best spot "$Nodes[BestSpot].Name$" score "$SpotScore[BestSpot]);
		SetCenter(BestSpot);
	}
}

final function StartChoice()
{
	local array<int> From;
	local NavigationPoint N;
	local int i;

	ReachFrom(Sources, false, SpawnDist);
	for ( i=0; i<Nodes.Length; i++ )
	{
		N = Nodes[i];
		if ( PlayerStart(N) != None )
			From[From.Length] = i;
	}
	ReachFrom(From, true, StartDist);
	Clearance.Length = Nodes.Length;
	SpotScore.Length = Nodes.Length;
	for ( i=0; i<Nodes.Length; i++ )
	{
		Clearance[i] = -1.0;
		SpotScore[i] = -100.0;
	}
	NextEval = 0;
	BestSpot = -1;
	bEvaluating = true;
}

function Tick(float DeltaTime)
{
	if ( bEvaluating )
		EvaluateSome();
}

// The proven spot for this map, if there is one
final function string KnownSpotHere()
{
	local string Map, S;
	local int i;

	Map = string(Level);
	Map = Left(Map, InStr(Map, "."));
	for ( i=0; i<ExtraSpots.Length; i++ )
	{
		S = ExtraSpots[i];
		if ( Left(S, InStr(S, "=")) ~= Map )
			return Mid(S, InStr(S, "=") + 1);
	}
	for ( i=0; i<StockSpots.Length; i++ )
	{
		S = StockSpots[i];
		if ( Left(S, InStr(S, "=")) ~= Map )
			return Mid(S, InStr(S, "=") + 1);
	}
	return "";
}

// Ready to hold the team's own spot? (Builds the network the first time, then takes the forced spot, the map's proven
// spot, or (bHoldUnknownMaps) starts choosing one; after a hold round a player, back to the team's spot)
final function bool Ready()
{
	local int C;
	local string Spot;

	if ( !bBuilt )
		Build();
	if ( !bChosen && !bEvaluating )
	{
		Spot = ForcedSpot;
		if ( Spot == "" )
			Spot = KnownSpotHere();
		if ( Spot != "" )
		{
			C = IndexOfName(Spot);
			bChosen = true;
			if ( C >= 0 )
			{
				BestSpot = C;
				SetCenter(C);
			}
			else
				log("KFHoldPlan: no node named "$Spot);
		}
		else if ( bHoldUnknownMaps )
			StartChoice();
		else
			bChosen = true;
	}
	if ( !bChosen || BestSpot < 0 )
		return false;
	if ( LeaderCenter >= 0 || Center != BestSpot )
	{
		// a player's squad holds round him: the bots of other squads join it rather than pull the posts away
		if ( bLeaderHeld && LeaderPawn != None && LeaderPawn.Health > 0 && Level.TimeSeconds - LeaderHeldTime < 2.0 )
			return bReady;
		LeaderCenter = -1;
		bLeaderHeld = false;
		SetCenter(BestSpot);
	}
	return bReady;
}

// A player leads: true once he has stayed put LeaderSettleTime, with the hold centred on the node nearest him; it then
// stays there while he moves about within LeaderLeaveRadius of it. False while he moves on: the bots follow him.
final function bool LeaderSettled(Pawn P)
{
	local int i, Best;
	local float D, BestD;

	if ( !bBuilt )
		Build();
	if ( P == None || P.Health <= 0 )
		return false;
	if ( P == LeaderPawn && bLeaderHeld && bReady && LeaderCenter >= 0 && Center == LeaderCenter )
	{
		if ( VSize(P.Location - Nodes[LeaderCenter].Location) <= LeaderLeaveRadius
			&& Abs(P.Location.Z - Nodes[LeaderCenter].Location.Z) < 200.0 )
		{
			LeaderHeldTime = Level.TimeSeconds;
			return true;
		}
		bLeaderHeld = false;
		LeaderSpot = P.Location;
		LeaderSince = Level.TimeSeconds;
		return false;
	}
	if ( P != LeaderPawn || VSize(P.Location - LeaderSpot) > LeaderSettleRadius )
	{
		LeaderPawn = P;
		LeaderSpot = P.Location;
		LeaderSince = Level.TimeSeconds;
		bLeaderHeld = false;
		return false;
	}
	if ( Level.TimeSeconds - LeaderSince < LeaderSettleTime )
		return false;
	Best = -1;
	for ( i=0; i<Nodes.Length; i++ )
	{
		if ( EdgeStart[i + 1] == EdgeStart[i] || !StandSpot(i) || Abs(Nodes[i].Location.Z - P.Location.Z) > 120.0 )
			continue;
		D = VSize(Nodes[i].Location - P.Location);
		if ( (Best < 0 || D < BestD) && FastTrace(Nodes[i].Location, P.Location) )
		{
			Best = i;
			BestD = D;
		}
	}
	if ( Best < 0 )
		return false;
	if ( Best != LeaderCenter || !bReady || Center != Best )
	{
		LeaderCenter = Best;
		SetCenter(Best);
	}
	bLeaderHeld = true;
	LeaderHeldTime = Level.TimeSeconds;
	return true;
}

// The face of a way in other than Own, at random (None when there is no other)
final function NavigationPoint OtherFace(NavigationPoint Own)
{
	local int i, n, Pick;

	if ( !bReady )
		return None;
	for ( i=0; i<LaneFace.Length; i++ )
		if ( Nodes[LaneFace[i]] != Own )
			n++;
	if ( n == 0 )
		return None;
	Pick = Rand(n);
	for ( i=0; i<LaneFace.Length; i++ )
		if ( Nodes[LaneFace[i]] != Own && Pick-- == 0 )
			return Nodes[LaneFace[i]];
	return None;
}

// This bot's post and where to look from it; a post whose holder is gone is free again. Avoid: a post the bot found
// no way to, not handed to it again while another is free
final function bool PostFor(Controller C, out NavigationPoint Post, out NavigationPoint Face, optional NavigationPoint Avoid)
{
	local int i, Free;

	if ( !bReady )
		return false;
	Free = -1;
	for ( i=0; i<Posts.Length; i++ )
	{
		if ( PostOwner[i] == C )
		{
			Post = Nodes[Posts[i]];
			Face = Nodes[LaneFace[PostLane[i]]];
			return true;
		}
		if ( PostOwner[i] == None || PostOwner[i].Pawn == None || PostOwner[i].Pawn.Health <= 0 )
		{
			PostOwner[i] = None;
			if ( Free < 0 && Nodes[Posts[i]] != Avoid )
				Free = i;
		}
	}
	// all taken: share the first post of the lane that has the fewest
	if ( Free < 0 )
		Free = Rand(Posts.Length);
	else
	{
		if ( bCoverBlindSide && LeaderPawn != None && LeaderPawn.Health > 0 && PlayerController(LeaderPawn.Controller) != None
			&& LeaderCenter >= 0 )
			Free = BlindestFreePost(Free);
		PostOwner[Free] = C;
	}
	Post = Nodes[Posts[Free]];
	Face = Nodes[LaneFace[PostLane[Free]]];
	return true;
}

// C gives up its post (it found no way there)
final function DropPost(Controller C)
{
	local int i;

	for ( i=0; i<Posts.Length; i++ )
		if ( PostOwner[i] == C )
			PostOwner[i] = None;
}

// Of the free posts (First is one), the one on the way in furthest behind the leader's back: what he cannot watch himself
final function int BlindestFreePost( int First )
{
	local int i, Best;
	local float Dot, BestDot;
	local vector View;

	View = vector(LeaderPawn.Rotation);
	View.Z = 0;
	View = Normal(View);
	Best = First;
	BestDot = 2;
	for ( i=0; i<Posts.Length; i++ )
	{
		if ( PostOwner[i] != None && PostOwner[i].Pawn != None && PostOwner[i].Pawn.Health > 0 )
			continue;
		Dot = Normal(Nodes[LaneFace[PostLane[i]]].Location - LeaderPawn.Location) dot View;
		if ( Dot < BestDot )
		{
			Best = i;
			BestDot = Dot;
		}
	}
	return Best;
}

final function bool InHeldArea(vector Loc, float Slack)
{
	local int i;

	if ( !bReady )
		return false;
	for ( i=0; i<Area.Length; i++ )
		if ( VSize(Nodes[Area[i]].Location - Loc) < Slack )
			return true;
	return false;
}

defaultproperties
{
     StockSpots(0)="KF-BioticsLab=PathNode1"
     StockSpots(1)="KF-Offices=InventorySpot76"
     StockSpots(2)="KF-WestLondon=PathNode152"
     StockSpots(3)="KF-HorzineHeadquaters-V2=PathNode39"
     StockSpots(4)="KF-Wretched-b2=PathNode110"
     AreaRadius=450.000000
     Eye=20.000000
     PostBack=150.000000
     PostApart=90.000000
     MaxPosts=6
     bCoverBlindSide=True
     MinRoom=4
     EvalPerTick=4
     LeaderSettleTime=3.000000
     LeaderSettleRadius=250.000000
     LeaderLeaveRadius=500.000000
     LeaderCenter=-1
     AnnouncedCenter=-1
     bHidden=True
     RemoteRole=ROLE_None
}
