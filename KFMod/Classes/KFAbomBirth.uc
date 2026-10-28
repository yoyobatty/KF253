// The Abomination's belly splitting to let its brood out (ZombieAbomination.Birth), as every machine sees it: a burst of
// blood and bits, and a wet tearing sound
class KFAbomBirth extends Actor;

simulated function PostBeginPlay()
{
	local int i;
	local KFGib G;

	Super.PostBeginPlay();
	if ( Level.NetMode == NM_DedicatedServer || class'GameInfo'.static.UseLowGore() )
		return;
	class'KFBloodBlast'.static.Make(self, Location, 1.3, vector(Rotation) * 0.8);
	PlaySound(sound'PlayerSounds.NewGibs.NewGib4', SLOT_None, 2.5,, 2000.0, 0.7);
	for ( i=0; i<5; i++ )
	{
		G = Spawn(class'KFMod.KFGibBrainb',,, Location + VRand() * 12.0, rotator(VRand()));
		if ( G != None )
		{
			G.Velocity = vector(Rotation) * (200.0 + 200.0 * FRand()) + VRand() * 150.0 + vect(0,0,180);
			G.SpawnTrail();
		}
	}
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
