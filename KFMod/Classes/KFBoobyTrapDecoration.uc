//=============================================================================
// KFBoobyTrapDecoration - Visual grenade mesh for door booby traps
//=============================================================================
class KFBoobyTrapDecoration extends Actor
    placeable;

defaultproperties
{
    DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'KillingFloorStatics.FragProjectile'
	DrawScale=0.400000
	bUnlit=False
    bStatic=false
    bStasis=false
    bCollideActors=false
    bCollideWorld=false
    bBlockActors=false
    bBlockPlayers=false
    bBlockZeroExtentTraces=false
    bBlockNonZeroExtentTraces=false
    Physics=PHYS_None
    RemoteRole=ROLE_SimulatedProxy
    AmbientGlow=64
}