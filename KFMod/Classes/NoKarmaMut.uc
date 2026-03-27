class NoKarmaMut extends Mutator;

simulated function PostBeginPlay()
{
<<<<<<< HEAD
	local KActor K;

	ForEach DynamicActors(Class'KActor',K)
	{
		K.Destroy();
		if( K==None )
			Continue;
		K.SetPhysics(PHYS_None);
		K.SetCollision(False);
		K.bHidden = True;
		K.bScriptInitialized = true;
		K.Disable('Tick');
		K.RemoteRole = ROLE_None;
=======
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	}
}

defaultproperties
{
<<<<<<< HEAD
	GroupName="KF-NoKarma"
	FriendlyName="No Karma Decorations"
	Description="Remove all those buggy karma decorations from the maps."
	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy
=======
     GroupName="KF-NoKarma"
     FriendlyName="Better karma physics"
     Description="Cleans up karma objects."
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
