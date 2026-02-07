//-----------------------------------------------------------
//
//-----------------------------------------------------------
class ShopVolume extends Volume;

var() string URL;
var array<Teleporter> TelList;
var bool bTelsInit,bHasTeles;

function InitTeleports()
{
	local NavigationPoint N;
	local int i;

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
	}
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
