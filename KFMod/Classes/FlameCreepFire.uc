//=============================================================================
// FlameCreepFire
// A flamethrower fire that spread to the wood or grass beside another (FlameGroundFire.Creep). The server chooses
// where, so it is sent to the clients.
//=============================================================================
class FlameCreepFire extends FlameGroundFire;

defaultproperties
{
	StartFuel=1.500000
	RemoteRole=ROLE_SimulatedProxy
	bNetTemporary=True
	bReplicateMovement=True
	NetPriority=1.000000
}
