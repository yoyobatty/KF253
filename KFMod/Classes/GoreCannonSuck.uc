//=============================================================================
// GoreCannonSuck
// The Gore Cannon's other button, held: a vacuum. On its holder's machine the bodies and giblets in the cone in front
// are dragged into the barrel and swallowed (KFGoreSuck), and the server told (GoreCannon.ServerAte). On the server the
// specimens in the cone are hurt, the more the nearer, dragged towards it (the light the more) and, once weak enough,
// torn in: killed, their bodies thrown at the barrel (DamTypeGoreSuck), which swallows them like any other. The
// Patriarch is only hurt. Others see it at the holder's barrel (GoreCannonAttachment.bSucking).
//=============================================================================
class GoreCannonSuck extends WeaponFire;

var() float	Reach;			// how far it pulls
var() float	ConeCos;		// ...in how wide a cone (beyond NearAll, which it pulls from all round)
var() float	NearAll;
var() float	SuckDamage;		// damage a second to a specimen at the barrel (a quarter of it at the edge of its reach)
var() float	PullSpeed;		// how hard a specimen of a clot's weight is dragged in
var() float	FinishRange;	// a specimen within this, weak enough, is torn in...
var() float	FinishShare;	// ...weak enough being no more than this share of its health
var() int	FinishMin;		// ...or this much
var KFGoreSuckFX	FX;
var int		GibMeat;		// (its holder's machine) giblets swallowed towards the next meat round
var float	NextLiving;

simulated function bool AllowFire()
{
	return true;
}

// (it runs while held: ModeTick)
event ModeDoFire();

// Where the barrel's mouth is, and which way it faces, as its holder aims
simulated function vector Mouth( out vector X )
{
	local vector Y, Z;

	GetAxes(Instigator.GetViewRotation(), X, Y, Z);
	return Instigator.Location + Instigator.EyePosition() + X * 70.0 + Y * 12.0 - Z * 14.0;
}

event ModeTick( float DT )
{
	local vector At, X;
	local array< class<KFMonster> > Bodies;
	local int Gibs, i;
	local GoreCannonAttachment A;

	Super.ModeTick(DT);
	if ( Instigator == None || Weapon == None )
		return;
	A = GoreCannonAttachment(Weapon.ThirdPersonActor);
	if ( Weapon.Role == ROLE_Authority && A != None && A.bSucking != bIsFiring )
		A.bSucking = bIsFiring;
	if ( !bIsFiring )
		return;
	At = Mouth(X);

	// (the server) the living
	if ( Weapon.Role == ROLE_Authority && Level.TimeSeconds >= NextLiving )
	{
		NextLiving = Level.TimeSeconds + 0.2;
		SuckLiving(At, X, 0.2);
	}

	// (its holder's machine) the bodies and giblets lying in front, and what it swallows told to the server
	if ( Instigator.IsLocallyControlled() && Level.NetMode != NM_DedicatedServer )
	{
		if ( FX == None || FX.bDeleteMe )
			FX = Weapon.Spawn(class'KFGoreSuckFX', Instigator,, At, rotator(X));
		if ( FX != None )
			FX.Feed(At, rotator(X));
		class'KFGoreSuck'.static.Suck(Weapon, At, X, DT, Reach, ConeCos, NearAll, Bodies, Gibs);
		for ( i = 0; i < Bodies.Length; i++ )
			GoreCannon(Weapon).ServerAte(Bodies[i]);
		GibMeat += Gibs;
		while ( GibMeat >= GoreCannon(Weapon).GibsPerRound )
		{
			GibMeat -= GoreCannon(Weapon).GibsPerRound;
			GoreCannon(Weapon).ServerAte(None);
		}
	}
}

// (the server) The specimens in front: hurt, dragged in, and the weak torn in
function SuckLiving( vector At, vector X, float DT )
{
	local KFMonster M;
	local array<KFMonster> Hit;
	local vector V;
	local float D, K;
	local int i, Dmg;

	foreach Instigator.VisibleCollidingActors(class'KFMonster', M, Reach, At)
		if ( M.Health > 0 && !M.bDeleteMe )
			Hit[Hit.Length] = M;
	for ( i = 0; i < Hit.Length; i++ )
	{
		M = Hit[i];
		if ( M == None || M.bDeleteMe || M.Health <= 0 )
			continue;
		V = At - M.Location;
		D = FMax(VSize(V), 1.0);
		if ( D > NearAll && (-V / D) dot X < ConeCos )
			continue;
		K = 1.0 - D / Reach;
		if ( !M.bBoss && D < FinishRange && M.Health <= Max(FinishMin, int(FinishShare * M.HealthMax)) )
		{
			M.TakeDamage(M.Health + 50, Instigator, M.Location, V / D * 40000.0, class'DamTypeGoreSuck');
			continue;
		}
		Dmg = Max(1, int(SuckDamage * (0.25 + 0.75 * K) * DT + 0.5));
		M.TakeDamage(Dmg, Instigator, M.Location, vect(0,0,0), class'DamTypeGoreSuck');
		if ( M.Health > 0 && !M.bBoss )
			M.AddVelocity(V / D * PullSpeed * (0.3 + 0.7 * K) * FMin(1.0, 300.0 / FMax(M.Mass, 1.0)) + vect(0,0,1) * 90.0 * K);
	}
}

defaultproperties
{
     Reach=1000.000000
     ConeCos=0.750000
     NearAll=140.000000
     SuckDamage=60.000000
     PullSpeed=260.000000
     FinishRange=650.000000
     FinishShare=0.300000
     FinishMin=60
     bWaitForRelease=False
     FireRate=0.200000
     AmmoPerFire=0
     BotRefireRate=0.300000
}
