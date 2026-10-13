Class VSPRI extends KFPlayerReplicationInfo;

function SetGRI(GameReplicationInfo GRI);

function Timer()
{
	local Controller C;

	SetTimer(0.5 + FRand(), False);
	UpdatePlayerLocation();
	C = Controller(Owner);
	if( C==None )
		Return;
	if( C.Pawn==None )
		PlayerHealth = 0;
	else if( C.Pawn.HealthMax==100 )
		PlayerHealth = C.Pawn.Health;
	else PlayerHealth = ((float(C.Pawn.Health)/C.Pawn.HealthMax)*100.f);

	if( !bBot )
	{
		if ( !bReceivedPing )
			Ping = Min(int(0.25 * float(C.ConsoleCommand("GETPING"))),255);
	}
}

defaultproperties
{
}
