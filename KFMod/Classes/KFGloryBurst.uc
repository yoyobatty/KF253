// A glory kill's reward, as every machine sees it (KFMonster.GloryKill): a flash where the specimen came apart and the
// drops it gives flying out of the body to the one who made the kill (KFGloryOrb): health always, ammunition and
// armour when there is some to give. The server gives what they carry (KFEndlessGameType.GloryReward).
class KFGloryBurst extends Actor;

var byte Health, Ammo, Armour;		// how many drops of each

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		Health, Ammo, Armour;
}

simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	if ( Level.NetMode != NM_DedicatedServer )
		SetTimer(0.02, false);
}

// (a moment late, on the server's own machine: the counts are set after it is made)
simulated function Timer()
{
	local int i;
	local PlayerController PC;

	Spawn(class'KFGloryFlash',,, Location);
	// the one who made the kill feels it: the view kicks wide and shakes
	PC = Level.GetLocalPlayerController();
	if ( PC != None && PC.Pawn != None && PC.Pawn == Instigator )
	{
		if ( KFPlayerController(PC) != None )
			KFPlayerController(PC).StartWarp(14.0);
		PC.ShakeView(vect(260,260,260), vect(14000,14000,14000), 0.5, vect(0,0,6), vect(1200,1200,1200), 0.4);
	}
	for ( i=0; i<Health; i++ )
		Throw(0);
	for ( i=0; i<Ammo; i++ )
		Throw(1);
	for ( i=0; i<Armour; i++ )
		Throw(2);
}

simulated function Throw( byte Kind )
{
	local KFGloryOrb O;
	local vector Out;

	if ( Instigator == None )
		return;
	O = Spawn(class'KFGloryOrb',,, Location + VRand() * 10.0);
	if ( O == None )
		return;
	Out = VRand() * 220.0;
	Out.Z = Abs(Out.Z) + 120.0;
	O.Go(Instigator, Kind, Out);
}

defaultproperties
{
     DrawType=DT_None
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
     bNetTemporary=True
     bReplicateInstigator=True
     LifeSpan=2.000000
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
}
