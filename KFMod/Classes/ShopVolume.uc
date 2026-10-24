//-----------------------------------------------------------
//
//-----------------------------------------------------------
class ShopVolume extends Volume;

var() string URL;
var array<Teleporter> TelList;
var bool bTelsInit,bHasTeles;
var NavigationPoint BotPoint;
var WeaponLocker MyTrader;
var NavigationPoint EntrySpot;	// where a walk to this trader ends (EntryPoint)
var bool bEntrySought;

function PostBeginPlay()
{
	local NavigationPoint N;

	Super.PostBeginPlay();
	for ( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
		if ( InventorySpot(N)!=None && Encompasses(N) )
		{
			N.bBlocked = true;
		}
}

function Touch( Actor Other )
{
	if( Pawn(Other)!=None && PlayerController(Pawn(Other).Controller)!=None && KFGameType(Level.Game)!=None && !KFGameType(Level.Game).bWaveInProgress )
	{
		MyTrader.SetOpen(true);
		PlayerController(Pawn(Other).Controller).ReceiveLocalizedMessage(Class'KFMainMessages',3);
	}
}
function UnTouch( Actor Other )
{
	if( Pawn(Other)!=None && PlayerController(Pawn(Other).Controller)!=None && KFGameType(Level.Game)!=None )
		MyTrader.SetOpen(false);
}
function UsedBy( Pawn user )
{
	if( KFPlayerController(user.Controller)!=None && KFGameType(Level.Game)!=None && !KFGameType(Level.Game).bWaveInProgress )
		KFPlayerController(user.Controller).ShowBuyMenu(string(MyTrader.Tag),KFHumanPawn(user).MaxCarryWeight);
}

// A path node inside the shop, the one nearest the trader; with none inside, the nearest outside that has a clear line
// to him. Looked for once.
function NavigationPoint EntryPoint()
{
	local NavigationPoint N, BestIn, BestOut;
	local float D, BestInD, BestOutD;
	local Actor T;

	if ( bEntrySought )
		return EntrySpot;
	bEntrySought = true;
	T = MyTrader;
	if ( T == None )
		T = self;
	for ( N=Level.NavigationPointList; N!=None; N=N.nextNavigationPoint )
	{
		if ( N.bBlocked || (PathNode(N) == None && PlayerStart(N) == None && InventorySpot(N) == None) )
			continue;
		D = VSize(N.Location - T.Location);
		// (inside the shop counts wherever it is: a shop with no trader has only its brush origin to measure from)
		if ( Encompasses(N) )
		{
			if ( BestIn == None || D < BestInD )
			{
				BestIn = N;
				BestInD = D;
			}
		}
		else if ( D <= 1500.f && (BestOut == None || D < BestOutD) && FastTrace(N.Location, T.Location) )
		{
			BestOut = N;
			BestOutD = D;
		}
	}
	if ( BestIn != None )
		EntrySpot = BestIn;
	else EntrySpot = BestOut;
	return EntrySpot;
}

function InitTeleports()
{
	local NavigationPoint N,BestN;
	local int i;
	local float Dist,BDist;

	bTelsInit = True;
	For( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
	{
		if( Teleporter(N)!=None && string(N.Tag)~=URL )
		{
			TelList.Length = i+1;
			TelList[i] = Teleporter(N);
			i++;
			bHasTeles = True;
		}
		Dist = VSize(N.Location-Location);
		if( Dist<2000 && (BestN==None || BDist>Dist) && FastTrace(N.Location,Location) )
		{
			BestN = N;
			BDist = Dist;
		}
	}
	BotPoint = BestN;
}

function bool BootPlayers()
{
	local KFHumanPawn Bootee;
	local int i;
	local bool bResult;

	if( !bTelsInit )
		InitTeleports();
	if( !bHasTeles )
		Return False; // Wtf?

	foreach TouchingActors(class'KFHumanPawn', Bootee)
	{
		if( PlayerController(Bootee.Controller)!=none )
		{
			PlayerController(Bootee.Controller).ReceiveLocalizedMessage(Class'KFMainMessages');
			PlayerController(Bootee.Controller).ClientCloseMenu(true, true);
		}

		// Teleport to a random teleporter in this local area, if more than one pick random.
		i = Rand(TelList.Length);
		if ( Bootee.IsA('Pawn') )
			Bootee.PlayTeleportEffect(false, true);
		TelList[i].Accept( Bootee, self );
		bResult = True;
	}
	Return bResult;
}

defaultproperties
{
}
