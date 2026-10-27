//=============================================================================
// KFAxeVoidSlash
// The Void Executioner's flying cut: the Executioner's (KFAxeSlash), violet, faster and shorter. It goes on through what
// it does not kill; on the first specimen it kills it stops, and there (the server) its thrower arrives in a blink, the
// floor under the spot found and room made, in a shock wave that kills every specimen in sight within ShockRadius (the
// Patriarch only takes BossShockDamage) and throws the bodies already down, and is turned to face the nearest specimen
// still standing in sight, for the next throw. KFVoidArrival shows it. A cut that kills nothing just goes out.
//=============================================================================
class KFAxeVoidSlash extends KFAxeSlash;

var() float	ShockRadius;
var() int	ShockDamage, BossShockDamage, CorpseShockDamage;
var() float	ShockMomentum;
var bool	bArrived;
var bool	bKilled;		// (the server) it has killed: the thrower comes to KillSpot
var vector	KillSpot;
var() float	FaceRange;		// how far off the specimen the thrower is turned to may be
var bool	bFaceDebug;		// logs what the turn after a blink found

// (each machine that draws it) violet trails
simulated function Dress()
{
	local int i;

	Super.Dress();
	for ( i = 0; i < ArrayCount(Trails); i++ )
		if ( Trails[i] != None )
		{
			Tint(Trails[i], 0, 0.65, 0.30, 1.00);
			Tint(Trails[i], 1, 0.80, 0.55, 1.00);
		}
}

static function Tint( Emitter E, int k, float R, float G, float B )
{
	if ( k >= E.Emitters.Length || E.Emitters[k] == None )
		return;
	E.Emitters[k].ColorMultiplierRange.X.Min = R;
	E.Emitters[k].ColorMultiplierRange.X.Max = R;
	E.Emitters[k].ColorMultiplierRange.Y.Min = G;
	E.Emitters[k].ColorMultiplierRange.Y.Max = G;
	E.Emitters[k].ColorMultiplierRange.Z.Min = B;
	E.Emitters[k].ColorMultiplierRange.Z.Max = B;
}

simulated function Tick( float DT )
{
	local vector X;

	X = vector(Rotation);
	Super.Tick(DT);
	// (the server) it lands on the first specimen it kills
	if ( Role == ROLE_Authority && !bArrived && bKilled )
		Arrive(KillSpot, X);
}

// (the server) The first kill is where the thrower comes
function Cut( Pawn P, vector Spot )
{
	if ( bKilled )
		return;
	if ( P == None || P.bDeleteMe || P.Health <= 0 )
	{
		bKilled = true;
		KillSpot = Spot;
	}
}

// (the server) The thrower arrives at Spot, which the cut reached going along X
function Arrive( vector Spot, vector X )
{
	local Pawn P;
	local vector From, Dest, HL, HN;
	local KFVoidArrival A;
	local bool bMoved;

	if ( bArrived )
		return;
	bArrived = true;
	P = Instigator;
	if ( P == None || P.Health <= 0 || P.Controller == None )
	{
		Fade();
		return;
	}
	From = P.Location;
	// a body's width short of what stopped it, standing on the floor under it
	Dest = Spot - X * (P.CollisionRadius + 8.0);
	if ( Trace(HL, HN, Dest - vect(0,0,500), Dest, false) != None )
		Dest = HL + vect(0,0,1) * (P.CollisionHeight + 4.0);
	Shock(Dest);
	bMoved = PlaceAt(P, Dest, X);
	if ( bMoved )
	{
		P.Velocity = vect(0,0,0);
		P.Acceleration = vect(0,0,0);
		if ( !P.PhysicsVolume.bWaterVolume )
			P.SetPhysics(PHYS_Falling);
	}
	else
		Dest = Spot;
	A = Spawn(class'KFVoidArrival', P,, Dest);
	if ( A != None )
	{
		A.From = From;
		A.bMoved = bMoved;
	}
	FaceNext(P);
	Fade();
}

// (the server) The thrower turned for the next throw, of the same kind as this one, to where it would kill most: for
// each specimen standing in sight, the throw aimed at it is worked out as it would go (the cut widening, stopped by
// walls, on through what it would not kill, as far as its first kill), with the shock wave there; the aim that kills
// most wins, then the smallest turn. A specimen with its head off is dying, and no mark.
function FaceNext( Pawn P )
{
	local KFMonster M, Best;
	local array<KFMonster> Live;
	local vector Eye, Mouth, Look;
	local float Score, BestScore, Turn, BestTurn;
	local int i;
	local rotator R;
	local bool bUpright;

	if ( P == None || P.Controller == None )
		return;
	Eye = P.Location + P.EyePosition();
	bUpright = Abs(Up.Z) < 0.5;
	Mouth = Eye - vect(0,0,24);
	Look = vector(P.Controller.GetViewRotation());
	foreach CollidingActors(class'KFMonster', M, FaceRange, P.Location)
		if ( Standing(M) && FastTrace(Chest(M), Mouth) )
			Live[Live.Length] = M;
	for ( i = 0; i < Live.Length; i++ )
	{
		Score = ThrowScore(Mouth, Normal(Chest(Live[i]) - Mouth), bUpright, Live);
		if ( Score <= 0 )
			continue;
		Turn = 1.0 - (Normal(Chest(Live[i]) - Eye) dot Look);
		if ( Best == None || Score > BestScore || (Score == BestScore && Turn < BestTurn) )
		{
			Best = Live[i];
			BestScore = Score;
			BestTurn = Turn;
		}
	}
	if ( bFaceDebug )
		log("VOIDFACE" @ Live.Length @ "standing in sight; upright" @ bUpright @ "-> " $ Best @ "kills" @ BestScore);
	if ( Best == None )
		return;
	R = rotator(Chest(Best) - Eye);
	R.Roll = 0;
	if ( PlayerController(P.Controller) != None )
	{
		P.Controller.SetRotation(R);
		P.Controller.ClientSetRotation(R);
	}
	else
		P.Controller.Focus = Best;
}

static function bool Standing( KFMonster M )
{
	return M != None && !M.bDeleteMe && M.Health > 0 && !M.bDecapitated;
}

static function vector Chest( Pawn M )
{
	return M.Location + vect(0,0,1) * 0.3 * M.CollisionHeight;
}

// How many specimens a throw from Mouth along Dir would kill: those it cuts down to its first kill (the cut kills what
// has no more than SlashDamage health), and those the shock wave there would; none if it would kill nothing
function float ThrowScore( vector Mouth, vector Dir, bool bUpright, array<KFMonster> Live )
{
	local rotator R;
	local vector X, A, U, D, KillAt;
	local float T, W, TKill;
	local int i, n;
	local array<byte> Hit;
	local bool bKill;

	R = rotator(Dir);
	if ( bUpright )
		R.Roll = 16384;
	GetAxes(R, X, A, U);
	Hit.Length = Live.Length;
	TKill = Reach;
	for ( i = 0; i < Live.Length; i++ )
	{
		D = Live[i].Location - Mouth;
		T = D dot X;
		if ( T < 0.0 || T > Reach )
			continue;
		W = StartWidth + (EndWidth - StartWidth) * FMin(T / Speed / GrowTime, 1.0);
		if ( Abs(D dot A) > 0.5 * W + Extent(Live[i], A) || Abs(D dot U) > Extent(Live[i], U) + 6.0 )
			continue;
		if ( !FastTrace(Mouth + X * T, Mouth) )
			continue;
		Hit[i] = 1;
		if ( Live[i].Health <= SlashDamage && T < TKill )
		{
			TKill = T;
			KillAt = Live[i].Location;
			bKill = true;
		}
	}
	if ( !bKill )
		return 0;
	for ( i = 0; i < Live.Length; i++ )
	{
		if ( Hit[i] != 0 && (Live[i].Location - Mouth) dot X <= TKill )
			n++;
		else if ( VSize(Live[i].Location - KillAt) < ShockRadius && FastTrace(Live[i].Location, KillAt) )
			n++;
	}
	return n;
}

// Puts P at Dest, or as near it as there is room, back along the way the cut came
function bool PlaceAt( Pawn P, vector Dest, vector X )
{
	local int i;
	local vector Try;

	if ( P.SetLocation(Dest) || P.SetLocation(Dest + vect(0,0,24)) )
		return true;
	X.Z = 0;
	X = Normal(X);
	for ( i = 1; i <= 8; i++ )
	{
		Try = Dest - X * (24.0 * i);
		if ( FastTrace(Try, Dest) && (P.SetLocation(Try) || P.SetLocation(Try + vect(0,0,24))) )
			return true;
	}
	Try = Dest + P.CollisionRadius * vect(1,1,0);
	if ( P.SetLocation(Try) )
		return true;
	Try = Dest + P.CollisionRadius * vect(-1,-1,0);
	if ( P.SetLocation(Try) )
		return true;
	Try = Dest + P.CollisionRadius * vect(1,-1,0);
	if ( P.SetLocation(Try) )
		return true;
	Try = Dest + P.CollisionRadius * vect(-1,1,0);
	return P.SetLocation(Try);
}

// (the server) The shock wave at Centre: every specimen in sight within ShockRadius killed, the bodies down thrown
function Shock( vector Centre )
{
	local KFMonster M;
	local array<KFMonster> Hit;
	local vector Dir;
	local int i, Dmg;

	foreach CollidingActors(class'KFMonster', M, ShockRadius, Centre)
		if ( FastTrace(M.Location, Centre) )
			Hit[Hit.Length] = M;
	for ( i = 0; i < Hit.Length; i++ )
	{
		M = Hit[i];
		if ( M == None || M.bDeleteMe )
			continue;
		Dir = Normal(M.Location - Centre + vect(0,0,40));
		if ( M.Health <= 0 )
			Dmg = CorpseShockDamage;
		else if ( M.bBoss )
			Dmg = BossShockDamage;
		else
			Dmg = Max(ShockDamage, 3 * M.Health);
		M.TakeDamage(Dmg, Instigator, M.Location - Dir * M.CollisionRadius, Dir * ShockMomentum, class'DamTypeVoidBlast');
	}
}

defaultproperties
{
     FaceRange=3000.000000
     ShockRadius=520.000000
     ShockDamage=5000
     BossShockDamage=1500
     CorpseShockDamage=400
     ShockMomentum=90000.000000
     BladeClass=Class'KFMod.KFAxeVoidBlade'
     Reach=2200.000000
     Speed=2700.000000
     MaxSpeed=2700.000000
}
