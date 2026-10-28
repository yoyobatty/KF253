// (server) Ticks a boss prototype's abilities (ZombieKingFleshpound, ZombieAbomination) every frame, whatever state
// its own class is in: the specimens' states each have their own Tick.
class KFBossBrain extends Info;

var KFMonster Boss;

function Tick( float DeltaTime )
{
	if ( Boss == None || Boss.bDeleteMe || Boss.Health <= 0 )
	{
		Destroy();
		return;
	}
	Boss.BossThink(DeltaTime);
}

defaultproperties
{
     RemoteRole=ROLE_None
}
