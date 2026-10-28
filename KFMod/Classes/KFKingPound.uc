// The King Fleshpound's ground pound (ZombieKingFleshpound.GroundPound), as every machine sees it: the floor blasts up
// round its fists (KFBlast: dust and the ceiling shaken down, no wave in the air: those are the weapons' alone), and the
// view shakes for anyone near
class KFKingPound extends Actor;

simulated function PostBeginPlay()
{
	local PlayerController PC;
	local float D;

	Super.PostBeginPlay();
	if ( Level.NetMode == NM_DedicatedServer )
		return;
	class'KFBlast'.static.Go(self, Location, vect(0,0,1), 1.8, true);
	PlaySound(Sound'WeaponSounds.BaseImpactAndExplosions.BExplosion3', SLOT_None, 2.5,, 3000.0, 0.6);
	PC = Level.GetLocalPlayerController();
	if ( PC != None && PC.ViewTarget != None )
	{
		D = VSize(PC.ViewTarget.Location - Location);
		if ( D < 1200.0 )
			PC.ShakeView(vect(500,500,500) * (1.0 - D / 1200.0), vect(12000,12000,12000), 1.2,
				vect(0,0,18) * (1.0 - D / 1200.0), vect(1000,1000,1000), 1.0);
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
