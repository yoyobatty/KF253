//=============================================================================
// GoreCannon
// A LAW made into a meat gun. Held on the other button it is a vacuum (GoreCannonSuck): the bodies and giblets in front
// of it are dragged off the floor into its barrel, and specimens there are hurt, dragged in and, once weak enough, torn
// in. What it swallows is its ammunition: a body is a body round, a few giblets a meat round. The fire button throws the
// last thing it swallowed (GoreCannonFire): a body flies whole and bursts where it lands (KFGoreBodyShot), meat goes as
// a spread of giblets (KFGoreGibShot). Empty, it is still a vacuum, so it is never put away for want of ammunition.
//
// The bodies and giblets lie on each machine of their own (no server keeps them), so its holder's machine swallows them
// and tells the server what (ServerAte); the server keeps the rounds (Stored, last in first out).
//=============================================================================
class GoreCannon extends LAW;

var array< class<KFMonster> >	Stored;		// (the server) the rounds, last swallowed last: a body's class, or None for meat
var() int						GibsPerRound;	// giblets to a meat round

replication
{
	reliable if ( Role < ROLE_Authority )
		ServerAte;
}

// (the server) Its holder's machine swallowed a body (its class) or a meat round's worth of giblets (None)
function ServerAte( class<KFMonster> Body )
{
	if ( Instigator == None || Instigator.Weapon != self || AmmoAmount(0) >= MaxAmmo(0) )
		return;
	Stored[Stored.Length] = Body;
	AddAmmo(1, 0);
	ClipLeft = AmmoAmount(0);
	ClientForceKFAmmoUpdate(ClipLeft, AmmoAmount(0));
}

// (the server) The round to throw: the last swallowed; ammunition given otherwise (a power-up) throws meat
function class<KFMonster> TakeRound()
{
	local class<KFMonster> B;

	if ( Stored.Length == 0 )
		return None;
	B = Stored[Stored.Length - 1];
	Stored.Length = Stored.Length - 1;
	return B;
}

// (empty it is still a vacuum)
simulated function bool HasAmmo()
{
	return true;
}

simulated function OutOfAmmo();

simulated function bool CanZoomNow()
{
	return false;
}

function float GetAIRating()
{
	return 0.1;
}

defaultproperties
{
     GibsPerRound=3
     Element=0
     ClipCount=12
     FireModeClass(0)=Class'KFMod.GoreCannonFire'
     FireModeClass(1)=Class'KFMod.GoreCannonSuck'
     PickupClass=Class'KFMod.GoreCannonPickup'
     AttachmentClass=Class'KFMod.GoreCannonAttachment'
     Description="A L.A.W refitted as a meat gun: it vacuums up bodies and giblets and fires them back."
     ItemName="Gore Cannon"
     Weight=10.000000
     Priority=49
}
