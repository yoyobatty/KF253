//=============================================================================
// KFVoidArrival
// The Void Executioner's wielder arriving (KFAxeVoidSlash.Arrive), as each machine sees it: the shock wave's burst of
// violet light, ring and sparks (KFVoidBurst), the air bent by it (KFScreenFX.Wave), giblets thrown, dust off the
// ceiling, a violet wisp where they left (KFVoidDepart), the crack of it; the wielder's own view flashes violet and
// shakes, others' near it shake. The cuts that brought them stop here.
//=============================================================================
class KFVoidArrival extends Actor;

#exec OBJ LOAD FILE=..\Sounds\WeaponSounds.uax
#exec OBJ LOAD FILE=..\Sounds\ONSBPSounds.uax

var vector	From;		// where they came from
var bool	bMoved;		// (false: there was no room, and they stayed)
var bool	bShown;

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		From, bMoved;
}

simulated function Tick( float DT )
{
	local PlayerController PC;
	local KFAxeVoidSlash S;
	local KFVoidBurst B;
	local float D, K;
	local bool bMine;
	local KFScreenFX FX;

	if ( bShown || Level.NetMode == NM_DedicatedServer )
		return;
	bShown = true;
	foreach DynamicActors(class'KFAxeVoidSlash', S)
		if ( S.Instigator == Instigator && !S.bDone )
			S.Fade();
	PC = Level.GetLocalPlayerController();
	bMine = PC != None && Instigator != None && PC.Pawn == Instigator;
	// (on the floor; round the one who arrived it is thinner, or they would see nothing for a moment)
	B = Spawn(class'KFVoidBurst',,, Location - vect(0,0,40), rotator(vect(0,0,1)));
	if ( B != None && bMine )
		B.Inside();
	if ( bMoved )
		Spawn(class'KFVoidDepart',,, From);
	class'KFScreenFX'.static.Wave(Level, Location, 2.4);
	class'KFGib'.static.Blast(self, Location, 1.4);
	class'KFBlast'.static.Ceiling(self, Location, 1.0);
	PlaySound(Sound'WeaponSounds.BaseFiringSounds.BTranslocatorFire', SLOT_None, 2.5,, 2500, 0.55);
	PlaySound(Sound'ONSBPSounds.ShockTank.ShockBallExplosion', SLOT_None, 2.8,, 5000, 0.65);
	PlaySound(Sound'WeaponSounds.BaseImpactAndExplosions.BExplosion3', SLOT_None, 2.2,, 5000, 0.55);

	if ( PC == None || PC.ViewTarget == None )
		return;
	if ( bMine )
	{
		// the view flares wide, streaks rush out, the edge goes violet, and the frame blurs for a moment
		if ( KFPlayerController(PC) != None )
			KFPlayerController(PC).StartWarp();
		if ( HUDKillingFloor(PC.myHUD) != None )
			HUDKillingFloor(PC.myHUD).AddVoidWarp();
		FX = class'KFFrameTap'.static.GetFX(PC);
		if ( FX != None )
		{
			FX.BlurLevel = FMax(FX.BlurLevel, 0.3);
			FX.BlurHoldUntil = Level.TimeSeconds + 0.04;
		}
		PC.ClientFlash(0.9, vect(260,90,420));
		PC.ShakeView(vect(500,500,500), vect(12000,12000,12000), 1.2, vect(20,20,20), vect(900,900,900), 1.2);
		return;
	}
	D = VSize(PC.ViewTarget.Location - Location);
	if ( D < 1500.0 )
	{
		K = 1.0 - D / 1500.0;
		PC.ShakeView(vect(300,300,300) * K, vect(10000,10000,10000), 1.5, vect(14,14,14) * K, vect(800,800,800), 1.5);
	}
}

defaultproperties
{
     DrawType=DT_None
     bHidden=True
     RemoteRole=ROLE_SimulatedProxy
     bNetTemporary=True
     bReplicateInstigator=True
     bAlwaysRelevant=True
     NetPriority=3.000000
     LifeSpan=1.000000
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
}
