// Zombies mode: a ZombieVolume that can be turned on/off, e.g. by a buyable door.
// Inactive volumes are rejected as spawn candidates by KFGameType.RateZombieVolume.
class KFZombieSpawnVolume extends ZombieVolume placeable;

var() bool bStartActive;
var bool bActive;

function PostBeginPlay()
{
	bActive = bStartActive;
	Super.PostBeginPlay();
}

function Activate()
{
	bActive = true;
}

function Deactivate()
{
	bActive = false;
}

defaultproperties
{
	bStartActive=True
}
