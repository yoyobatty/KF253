// The Abomination's toxic belch (ZombieAbomination.Breathe), as every machine sees it: a sick green cloud rolling out of
// its mouth and settling, poisonous to stand in (the server deals that) and, as vapour in the fire grid, ready to burn
class KFAbomBelch extends Actor;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( Level.NetMode != NM_DedicatedServer )
		Spawn(class'KFAbomGasCloud',,, Location, Rotation);
}

defaultproperties
{
     DrawType=DT_None
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
     bNetTemporary=True
     LifeSpan=1.000000
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
}
