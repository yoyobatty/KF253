//=============================================================================
// KFRicochet
// An upgraded round that bounced off a wall to a specimen (KFFire.Ricochet): its tracer from the wall to where it
// struck, on every machine. The server sends it once.
//=============================================================================
class KFRicochet extends Actor;

var vector EndSpot;
var bool bShown;

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		EndSpot;
}

// Made on the server: on to End
function ShowTo( vector End )
{
	EndSpot = End;
	if ( Level.NetMode != NM_DedicatedServer )
		Show();
}

simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	if ( Role < ROLE_Authority )
		Show();
}

simulated function Show()
{
	local Emitter T;
	local vector V;
	local float Dist;
	local color C;

	if ( bShown || Level.NetMode == NM_DedicatedServer )
		return;
	bShown = true;
	Dist = VSize(EndSpot - Location);
	if ( Dist < 20 )
		return;
	T = Spawn(class'KFNewTracer',,, Location);
	if ( T == None )
		return;
	T.LifeSpan = 1.0;
	V = 7500 * (EndSpot - Location) / Dist;
	T.Emitters[0].StartVelocityRange.X.Min = V.X;
	T.Emitters[0].StartVelocityRange.X.Max = V.X;
	T.Emitters[0].StartVelocityRange.Y.Min = V.Y;
	T.Emitters[0].StartVelocityRange.Y.Max = V.Y;
	T.Emitters[0].StartVelocityRange.Z.Min = V.Z;
	T.Emitters[0].StartVelocityRange.Z.Max = V.Z;
	T.Emitters[0].LifetimeRange.Min = Dist / 7500;
	T.Emitters[0].LifetimeRange.Max = Dist / 7500;
	C = class'KFWeapon'.default.UpgradeTint;
	T.Emitters[0].ColorMultiplierRange.X.Min = C.R / 255.0;
	T.Emitters[0].ColorMultiplierRange.X.Max = C.R / 255.0;
	T.Emitters[0].ColorMultiplierRange.Y.Min = C.G / 255.0;
	T.Emitters[0].ColorMultiplierRange.Y.Max = C.G / 255.0;
	T.Emitters[0].ColorMultiplierRange.Z.Min = C.B / 255.0;
	T.Emitters[0].ColorMultiplierRange.Z.Max = C.B / 255.0;
	T.SpawnParticle(1);
}

defaultproperties
{
	DrawType=DT_None
	bNetTemporary=True
	RemoteRole=ROLE_SimulatedProxy
	LifeSpan=1.000000
}
