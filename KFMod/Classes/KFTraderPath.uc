//=============================================================================
// KFTraderPath - the way to the nearest trader, for the Dead Space style line
// on the floor. The server finds it when a player presses the stock "show the
// path" key (BasePath, M; KFGameType.ShowPathTo) and sends it to that player
// alone, whose own machine draws it (KFTraderTrail).
//=============================================================================
class KFTraderPath extends Actor;

var vector Points[48];		// the player, the path nodes walked through, then the spot before the trader's counter
var byte NumPoints;			// 0: no way there; 1: already at the trader

var() float StraightLeg;	// path nodes this close to the line between their neighbours are left out
var() Sound FoundSound, NoWaySound;
var() float LocatorVolume;

replication
{
	reliable if ( Role == ROLE_Authority )
		Points, NumPoints;
}

function PostBeginPlay()
{
	local PlayerController P;
	local KFGameType G;
	local ShopVolume S, Best;
	local NavigationPoint Entry;
	local array<NavigationPoint> Route;
	local float Dist, BestDist;
	local vector Spot;
	local int i;

	Super.PostBeginPlay();
	P = PlayerController(Owner);
	G = KFGameType(Level.Game);
	if ( P == None || P.Pawn == None || G == None )
		return;
	// the trader with the shortest walk; one the player stands in needs none
	for ( i=0; i<G.ShopList.Length; i++ )
	{
		S = G.ShopList[i];
		if ( S.Encompasses(P.Pawn) )
		{
			Best = S;
			BestDist = 0;
			break;
		}
		Entry = S.EntryPoint();
		if ( Entry == None )
			continue;
		Dist = WalkTo(P, Entry);
		if ( Dist >= 0 && (Best == None || Dist < BestDist) )
		{
			Best = S;
			BestDist = Dist;
		}
	}
	if ( Best == None )
		return;
	Points[0] = P.Pawn.Location;
	NumPoints = 1;
	if ( BestDist > 0 )
	{
		// (searched again: what the nodes hold is the last search's)
		Entry = Best.EntryPoint();
		WalkTo(P, Entry);
		ReadRoute(P, Entry, Route);
		for ( i=0; i<Route.Length && NumPoints<ArrayCount(Points)-1; i++ )
		{
			if ( i < Route.Length-1 && OffLine(Points[NumPoints-1], Route[i+1].Location, Route[i].Location) < StraightLeg )
				continue;
			Points[NumPoints] = Route[i].Location;
			NumPoints++;
		}
		if ( NumPoints<ArrayCount(Points)-1 && Route.Length>0 && TraderSpot(Best, Points[NumPoints-1], Spot) )
		{
			Points[NumPoints] = Spot;
			NumPoints++;
		}
	}
	else if ( TraderSpot(Best, Points[0], Spot) )
	{
		Points[1] = Spot;
		NumPoints = 2;
	}
}

// How far the walk to N is, -1 for no way there. The route stays in the path nodes for ReadRoute.
function float WalkTo( PlayerController P, NavigationPoint N )
{
	P.RouteGoal = None;
	if ( P.FindPathToward(N) == None )
		return -1;
	// (the engine skips the search when the player is already by it)
	if ( P.RouteGoal != N )
		return VSize(N.Location - P.Pawn.Location);
	return P.RouteDist;
}

// The path nodes from the player to N, after WalkTo(P, N): back from N the way the search came, as far as the first
// node the player heads for.
function ReadRoute( PlayerController P, NavigationPoint N, out array<NavigationPoint> Route )
{
	local NavigationPoint Step;

	Route.Length = 0;
	if ( P.RouteGoal != N )
	{
		if ( NavigationPoint(P.RouteCache[0]) != None && P.RouteCache[0] != N )
			Route[0] = NavigationPoint(P.RouteCache[0]);
		Route[Route.Length] = N;
		return;
	}
	for ( Step=N; Step!=None && Route.Length<500; Step=Step.previousPath )
	{
		Route.Insert(0, 1);
		Route[0] = Step;
		if ( Step == P.RouteCache[0] )
			break;
	}
}

// How far X is from the stretch between A and B
static function float OffLine( vector A, vector B, vector X )
{
	local vector Dir;
	local float Len, Along;

	Dir = B - A;
	Len = VSize(Dir);
	if ( Len < 1 )
		return VSize(X - A);
	Dir /= Len;
	Along = FClamp((X - A) Dot Dir, 0, Len);
	return VSize(X - (A + Dir * Along));
}

// Where the line stops, coming from From: in front of the trader's counter
function bool TraderSpot( ShopVolume S, vector From, out vector Spot )
{
	local vector HitLocation, HitNormal, Dir, To;
	local Actor T;
	local float Radius;

	// (a shop with no trader in it: on toward the shop itself)
	T = S.MyTrader;
	if ( T == None )
		T = S;
	else Radius = T.CollisionRadius;
	Dir = T.Location - From;
	Dir.Z = 0;
	if ( VSize(Dir) < Radius + 60 )
		return false;
	Dir = Normal(Dir);
	// (as far as a body could walk towards him: counters are often held by blocking volumes, which a line passes)
	To = T.Location;
	To.Z = From.Z;
	if ( Trace(HitLocation, HitNormal, To, From, false, vect(20,20,30)) != None )
		Spot = HitLocation - 16 * Dir;
	else Spot = To - (Radius + 40) * Dir;
	return true;
}

simulated function PostNetBeginPlay()
{
	local PlayerController P;
	local KFTraderTrail Trail;
	local array<vector> Route;
	local int i;

	if ( Level.NetMode == NM_DedicatedServer )
		return;
	P = Level.GetLocalPlayerController();
	if ( P == None || (Level.NetMode == NM_ListenServer && Owner != P) )
		return;
	foreach DynamicActors(class'KFTraderTrail', Trail)
		Trail.Stop();
	if ( P.ViewTarget != None )
	{
		if ( NumPoints > 0 )
			P.ViewTarget.PlaySound(FoundSound, SLOT_None, LocatorVolume, false, 200.0, 1.0, false);
		else P.ViewTarget.PlaySound(NoWaySound, SLOT_None, LocatorVolume, false, 200.0, 1.0, false);
	}
	if ( NumPoints < 2 )
		return;
	for ( i=0; i<NumPoints; i++ )
		Route[i] = Points[i];
	// (where this player is now, not where the server last had him)
	if ( P.Pawn != None )
		Route[0] = P.Pawn.Location;
	Trail = Spawn(class'KFTraderTrail', P,, Route[0]);
	if ( Trail != None )
		Trail.Lay(Route);
}

defaultproperties
{
	StraightLeg=24.000000
	FoundSound=Sound'MenuSounds.select3'
	NoWaySound=Sound'MenuSounds.denied1'
	LocatorVolume=0.600000
	bHidden=True
	RemoteRole=ROLE_SimulatedProxy
	bNetTemporary=True
	bOnlyRelevantToOwner=True
	bAlwaysRelevant=False
	bReplicateMovement=False
	bSkipActorPropertyReplication=True
	NetPriority=3.000000
	LifeSpan=2.000000
}
