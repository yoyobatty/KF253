//-----------------------------------------------------------
//
//-----------------------------------------------------------
class ShopVolume extends Volume;

var() string URL;
var array<Teleporter> TelList;
var bool bTelsInit,bHasTeles;
<<<<<<< HEAD

function InitTeleports()
{
	local NavigationPoint N;
	local int i;
=======
var NavigationPoint BotPoint;
var WeaponLocker MyTrader;

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

function InitTeleports()
{
	local NavigationPoint N,BestN;
	local int i;
	local float Dist,BDist;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

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
<<<<<<< HEAD
	}
=======
		Dist = VSize(N.Location-Location);
		if( Dist<2000 && (BestN==None || BDist>Dist) && FastTrace(N.Location,Location) )
		{
			BestN = N;
			BDist = Dist;
		}
	}
	BotPoint = BestN;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
