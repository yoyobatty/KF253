class NoKarmaMut extends Mutator;

simulated function PostBeginPlay()
{
	local NetKActor K;
	local int Count;

	ForEach AllActors(Class'GoodKarma.NetKActor', K)
	{
		if(K == None)
			continue;
		K.SetPhysics(PHYS_None);
		K.SetCollision(false,false,false);
		K.bCollideWorld = false;
		K.bHidden = true;
		K.SetCollisionSize(0,0);
		K.bKActorShadows = false;
		K.Disable('Tick');
		if(K.PlayerShadow != None)
			K.PlayerShadow.Destroy();
		Count++;
	}
	Log("NoKarmaMut: Disabled"@Count@"NetKActor(s)");
}

defaultproperties
{
	GroupName="KF-NoKarma"
	FriendlyName="No Karma"
	Description="Cleans up karma objects."
	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy
}
