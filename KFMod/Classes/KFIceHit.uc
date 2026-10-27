//=============================================================================
// KFIceHit
// A shot striking a frozen specimen (KFMonster.PlayHit while frozen): chips of ice and frost off it instead of blood,
// with a glassy tick. The server sends it once; each machine that draws it makes the chips (KFImpactSnow).
//=============================================================================
class KFIceHit extends Actor;

#exec OBJ LOAD FILE=PatchSounds.uax

var bool bShown;

simulated function Tick( float DT )
{
	if ( bShown || Level.NetMode == NM_DedicatedServer )
		return;
	bShown = true;
	Spawn(class'KFImpactSnow', self,, Location, Rotation);
	PlaySound(Sound'PatchSounds.GlassImpact3', SLOT_None, 0.9,, 500, 1.4 + 0.3 * FRand());
}

defaultproperties
{
     DrawType=DT_None
     bHidden=True
     RemoteRole=ROLE_SimulatedProxy
     bNetTemporary=True
     LifeSpan=0.600000
     bCollideActors=False
     bBlockActors=False
}
