//=============================================================================
// ZombieAbomination - a boss prototype after Killing Floor 2's Abomination: a Bloat grown huge, with
//  - a toxic belch: with its bile it breathes out a cloud of gas that poisons whoever stands in it, and that gas burns
//    (it goes into the fire grid as vapour: a flame, a muzzle flash, a zap sets it off: KFFireGrid);
//  - a brood: now and then its belly splits and specimens tumble out of it, still wet;
//  - and below BerserkShare of its health it goes berserk: faster, belching and spawning more often.
// Its abilities are ticked by a KFBossBrain on the server.
//=============================================================================
class ZombieAbomination extends ZombieBloat;

var() float BelchInterval, BirthInterval, BerserkShare;
var() int MaxBrood, BroodPerBirth;
var() float GasAmount;
var() int PoisonDamage;
var() float PoisonRadius, PoisonTime;

struct GasCloud
{
	var vector Spot;
	var float Until;
};
var array<GasCloud> Clouds;
var array<KFMonster> Brood;
var float NextBelch, BelchAt, NextBirth, NextPoison;
var bool bRaving;
var KFBossBrain Brain;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( Role == ROLE_Authority )
	{
		Brain = Spawn(class'KFBossBrain', self);
		if ( Brain != None )
			Brain.Boss = self;
		NextBelch = Level.TimeSeconds + 5.0;
		NextBirth = Level.TimeSeconds + 9.0;
	}
}

function BossThink( float DT )
{
	local int i;
	local float D;
	local Pawn P;

	if ( Health <= 0 || Controller == None )
		return;
	for ( i=Brood.Length - 1; i>=0; i-- )
		if ( Brood[i] == None || Brood[i].bDeleteMe || Brood[i].Health <= 0 )
			Brood.Remove(i, 1);
	if ( !bRaving && float(Health) < HealthMax * BerserkShare )
	{
		bRaving = true;
		OriginalGroundSpeed *= 1.7;
		SetGroundSpeed(OriginalGroundSpeed);
		PlaySound(Sound'KFPlayerSound.Flesh1', SLOT_Talk, 3.0,, 3000.0, 0.6);
	}
	if ( BelchAt > 0 && Level.TimeSeconds >= BelchAt )
	{
		BelchAt = 0;
		Breathe();
	}
	if ( Controller.Enemy != None && Controller.Enemy.Health > 0 )
	{
		D = VSize(Controller.Enemy.Location - Location);
		if ( Level.TimeSeconds > NextBelch && D < 950.0 && !bShotAnim && Controller.LineOfSightTo(Controller.Enemy) )
			Belch();
		if ( Level.TimeSeconds > NextBirth && Brood.Length < MaxBrood && D < 2000.0 )
			Birth();
	}
	// the gas poisons whoever is in it
	if ( Level.TimeSeconds > NextPoison && Clouds.Length > 0 )
	{
		NextPoison = Level.TimeSeconds + 0.5;
		for ( i=Clouds.Length - 1; i>=0; i-- )
		{
			if ( Level.TimeSeconds > Clouds[i].Until )
			{
				Clouds.Remove(i, 1);
				continue;
			}
			foreach VisibleCollidingActors(class'Pawn', P, PoisonRadius, Clouds[i].Spot)
				if ( KFMonster(P) == None && P.Health > 0 )
					P.TakeDamage(PoisonDamage, self, P.Location, vect(0,0,0), class'DamTypeVomit');
		}
	}
}

function float Pace()
{
	if ( bRaving )
		return 0.6;
	return 1.0;
}

function Belch()
{
	NextBelch = Level.TimeSeconds + BelchInterval * Pace() * (0.8 + 0.4 * FRand());
	bShotAnim = true;
	SetAnimAction('ZombieBarf');
	Controller.bPreparingMove = true;
	Acceleration = vect(0,0,0);
	BelchAt = Level.TimeSeconds + 0.55;
	PlaySound(Sound'KFPlayerSound.Flesh2', SLOT_Talk, 2.5,, 2500.0, 0.55);
}

// The cloud out of its mouth, along the way it faces: poison, and vapour that burns
function Breathe()
{
	local vector Mouth, X, Y, Z, Spot;
	local int i;
	local GasCloud G;

	GetAxes(Rotation, X, Y, Z);
	Mouth = Location + (vect(30,0,64) >> Rotation) * DrawScale;
	for ( i=1; i<=6; i++ )
	{
		Spot = Mouth + X * (90.0 * i) + Y * (40.0 * (FRand() - 0.5) * i) - vect(0,0,1) * (10.0 * i);
		if ( !FastTrace(Spot, Mouth) )
			break;
		class'KFFireGrid'.static.AddGas(self, Spot, GasAmount, self);
		G.Spot = Spot;
		G.Until = Level.TimeSeconds + PoisonTime;
		Clouds[Clouds.Length] = G;
	}
	Spawn(class'KFAbomBelch',,, Mouth + X * 60.0, Rotation);
}

// Its belly splits and specimens tumble out
function Birth()
{
	local vector X, Y, Z, Belly, Spot;
	local KFMonster M;
	local class<KFMonster> C;
	local int i, n;

	NextBirth = Level.TimeSeconds + BirthInterval * Pace() * (0.8 + 0.4 * FRand());
	GetAxes(Rotation, X, Y, Z);
	Belly = Location + Z * (0.1 * CollisionHeight);
	n = Min(BroodPerBirth + Rand(2), MaxBrood - Brood.Length);
	for ( i=0; i<n; i++ )
	{
		if ( FRand() < 0.6 )
			C = class<KFMonster>(DynamicLoadObject("KFChar.ZombieCrawler", class'Class'));
		else
			C = class<KFMonster>(DynamicLoadObject("KFChar.ZombieClot", class'Class'));
		Spot = Belly + X * (CollisionRadius + 34.0) + Y * (50.0 * (float(i) - 0.5 * float(n - 1)));
		if ( C == None || !FastTrace(Spot, Belly) )
			continue;
		M = Spawn(C,,, Spot, Rotation);
		if ( M == None )
			continue;
		M.SetPhysics(PHYS_Falling);
		M.Velocity = X * (260.0 + 120.0 * FRand()) + Y * (200.0 * (FRand() - 0.5)) + vect(0,0,220);
		Brood[Brood.Length] = M;
	}
	if ( n > 0 )
		Spawn(class'KFAbomBirth',,, Belly + X * CollisionRadius * 0.9, Rotation);
}

simulated function Destroyed()
{
	if ( Brain != None )
		Brain.Destroy();
	Super.Destroyed();
}

defaultproperties
{
     BelchInterval=9.000000
     BirthInterval=13.000000
     BerserkShare=0.400000
     MaxBrood=8
     BroodPerBirth=3
     GasAmount=3.000000
     PoisonDamage=4
     PoisonRadius=170.000000
     PoisonTime=6.000000
     MenuName="Abomination"
     Health=9000
     HealthMax=9000.000000
     HeadHealth=3500
     DrawScale=1.750000
     CollisionRadius=42.000000
     CollisionHeight=74.000000
     ColOffset=(Z=105.000000)
     ColRadius=47.000000
     ColHeight=38.000000
     PrePivot=(Z=14.000000)
     GroundSpeed=85.000000
     GibScale=2.000000
     ScoringValue=200
     Mass=1500.000000
     bBoss=True
     damageConst=40
     damageRand=20
     damageForce=35000
}
