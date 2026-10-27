//=============================================================================
// KFGridFire
// A ground fire the fire grid lit (KFFireGrid.Burn): its fuel comes from the grid, which goes on feeding it while fuel
// comes, so it is sent to the clients with its fuel (RepFuel). The grid spreads fire itself: no creeping of its own.
//=============================================================================
class KFGridFire extends FlameGroundFire;

var float RepFuel;

replication
{
	reliable if ( Role == ROLE_Authority )
		RepFuel;
}

// (the server) Its fuel set (bSet), or more of it
function GridFeed( float Amount, optional bool bSet )
{
	if ( bSet )
		Fuel = FMin(Amount, MostFuel());
	else
		AddFuel(Amount);
	RepFuel = Fuel;
	NetUpdateTime = Level.TimeSeconds - 1;
}

simulated function float MostFuel()
{
	if ( Face == 0 )
		return 14.0;
	return WallMaxFuel;
}

simulated function PostNetReceive()
{
	Super.PostNetReceive();
	if ( Role < ROLE_Authority && Abs(RepFuel - Fuel) > 0.5 )
		Fuel = RepFuel;
}

defaultproperties
{
     Generation=2
     StartFuel=2.000000
     MaxFuel=14.000000
     RemoteRole=ROLE_SimulatedProxy
     bNetNotify=True
     NetUpdateFrequency=2.000000
     NetPriority=1.000000
}
