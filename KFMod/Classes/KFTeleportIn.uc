//=============================================================================
// A specimen on its way into a lockdown (KFLockdown): every machine shows it coming at once (KFTeleportFX); after Charge
// seconds the server makes it there, already hunting.
//=============================================================================
class KFTeleportIn extends Actor;

var() float Charge;
var class<KFMonster> ZedClass;
var KFLockdown Lock;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( Level.NetMode != NM_DedicatedServer )
		Spawn(class'KFTeleportFX',,, Location);
	if ( Role == ROLE_Authority )
		SetTimer(Charge, false);
}

function Timer()
{
	local KFMonster M;
	local vector Spot;

	if ( Role < ROLE_Authority )
		return;
	if ( ZedClass != None )
	{
		Spot = Location + vect(0,0,1) * (ZedClass.default.CollisionHeight + 4.0);
		M = Spawn(ZedClass,,, Spot, Rotation);
		if ( M == None )
			M = Spawn(ZedClass,,, Spot + vect(0,0,24), Rotation);
		if ( Lock != None )
			Lock.Arrived(M);
	}
	LifeSpan = 0.5;
}

defaultproperties
{
     Charge=0.650000
     DrawType=DT_None
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
     bNetTemporary=True
     LifeSpan=3.000000
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
}
