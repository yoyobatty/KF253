class NoKarmaMut extends Mutator;

simulated function PostBeginPlay()
{
	local NetKActor K;

	ForEach DynamicActors(Class'GoodKarma.NetKActor', K)
	{
		if(K == None)
			continue;
		//K.bCollideActors = false;
		K.SetCollision(false,false,false);
		K.bCollideWorld = false;
		K.bHidden = true;
		K.SetCollisionSize(0,0);
		K.Disable('Tick');
	}
}

defaultproperties
{
     GroupName="KF-NoKarma"
     FriendlyName="Better karma physics"
     Description="Cleans up karma objects."
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
}
