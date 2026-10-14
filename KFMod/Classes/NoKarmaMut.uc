class NoKarmaMut extends Mutator;

// Every physics prop: the GoodKarma ones and the engine's own, which some maps use. Each machine hides its own copy
// (the mutator is sent to every client), out of the physics of dead bodies too, and the server stops sending them.
simulated function PostBeginPlay()
{
	local KActor K;
	local int Count;

	ForEach AllActors(Class'KActor', K)
	{
		if(K == None)
			continue;

		K.SetPhysics(PHYS_None);
		K.SetCollision(false,false,false);
		// (a body falling where a hidden prop stood could land on it)
		K.KSetBlockKarma(false);
		K.bCollideWorld = false;
		K.bHidden = true;
		K.SetCollisionSize(0,0);
		K.Disable('Tick');
		if( NetKActor(K)!=None )
		{
			NetKActor(K).bKActorShadows = false;
			if( NetKActor(K).PlayerShadow != None )
				NetKActor(K).PlayerShadow.Destroy();
		}
		// (props are part of the map on every machine: once hidden on each, there is nothing more to send)
		if( Level.NetMode!=NM_Client )
			K.RemoteRole = ROLE_None;
		Count++;
	}
	Log("NoKarmaMut: Disabled"@Count@"physics prop(s)");
}

defaultproperties
{
	GroupName="KF-NoKarma"
	FriendlyName="No Karma"
	Description="Cleans up karma objects."
	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy
}
