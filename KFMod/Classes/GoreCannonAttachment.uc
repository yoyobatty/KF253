//=============================================================================
// GoreCannonAttachment
// The Gore Cannon in its holder's hands, as others see it: while its vacuum runs (bSucking, from the server) each other
// machine draws the suction at its barrel and swallows its own bodies and giblets there (KFGoreSuck; nothing counted).
//=============================================================================
class GoreCannonAttachment extends LAWAttachment;

var bool			bSucking;
var KFGoreSuckFX	FX;

replication
{
	reliable if ( Role == ROLE_Authority )
		bSucking;
}

simulated function Tick( float DT )
{
	local vector At, X;
	local array< class<KFMonster> > Bodies;
	local int Gibs;

	Super.Tick(DT);
	if ( !bSucking || Level.NetMode == NM_DedicatedServer || Instigator == None || Instigator.IsLocallyControlled() )
		return;
	X = vector(Instigator.GetViewRotation());
	At = Location + X * 60.0;
	if ( FX == None || FX.bDeleteMe )
		FX = Spawn(class'KFGoreSuckFX', Instigator,, At, rotator(X));
	if ( FX != None )
		FX.Feed(At, rotator(X));
	class'KFGoreSuck'.static.Suck(self, At, X, DT, class'GoreCannonSuck'.default.Reach, class'GoreCannonSuck'.default.ConeCos,
		class'GoreCannonSuck'.default.NearAll, Bodies, Gibs);
}

simulated function Destroyed()
{
	if ( FX != None )
		FX.Destroy();
	Super.Destroyed();
}
