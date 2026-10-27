//=============================================================================
// KFAmmoMod
// A re-packed weapon's special ammo (KFWeapon.AmmoMod, KFPackAPunchMachine): now and then a hit on a living specimen
// sets it off (on the server; KFMonster.TakeDamage), then it rests a while.
//   1 Dead Wire: lightning jumps from the specimen through those near it, hurting and jolting each.
//   2 Blast Furnace: the specimen and those round it burst into flame.
//   3 Thunder Wall: a wall of force throws back everything in front of the one who fired.
//   4 Turned: a small specimen fights for the players a while, then falls (a big one is only jolted).
// What everyone sees of it is KFAmmoModFX's.
//=============================================================================
class KFAmmoMod extends Info;

var byte		Mod;				// (one going off: what, on whom and where, by whom)
var KFMonster	First;
var vector		Spot;
var Pawn		Shooter;
var class<DamageType> HitType;

var() string	Names[5];
var() color		Colors[5];
var() float		Chances[5];			// of a hit setting it off
var() float		Cooldowns[5];		// seconds it then rests
var() float		WireDamage, WireReach;
var() int		WireJumps;
var() float		FurnaceDamage, FurnaceReach;
var() float		ThunderDamage, ThunderReach, ThunderPush, ThunderCone;
var() float		TurnedTime;
var() int		TurnedMaxHealth;	// the biggest specimen it turns (its own full health)

static function string NameOf( byte Mod )
{
	if ( Mod >= ArrayCount(default.Names) )
		return "";
	return default.Names[Mod];
}

static function color ColourOf( byte Mod )
{
	local color C;

	C = default.Colors[Min(Mod, ArrayCount(default.Colors) - 1)];
	C.A = 255;
	return C;
}

// A living specimen hit by the weapon in Shooter's hands (KFMonster.TakeDamage)
static function Hit( KFMonster M, Pawn Shooter, vector HitLoc, class<DamageType> DT )
{
	local KFWeapon W;
	local byte Mod;
	local KFAmmoMod A;

	if ( M == None || Shooter == None || M.Health <= 0 || M.Level.NetMode == NM_Client || M.IsTurned() )
		return;
	W = KFWeapon(Shooter.Weapon);
	if ( W == None || !W.bUpgraded || W.AmmoMod == 0 || W.AmmoMod >= ArrayCount(default.Names) )
		return;
	Mod = W.AmmoMod;
	if ( M.Level.TimeSeconds < W.ModReadyAt || FRand() > default.Chances[Mod] )
		return;
	W.ModReadyAt = M.Level.TimeSeconds + default.Cooldowns[Mod];
	// (it goes off after the hit that set it off is done with, not inside it)
	A = M.Spawn(class'KFAmmoMod',,, M.Location);
	if ( A != None )
	{
		A.Mod = Mod;
		A.First = M;
		A.Spot = M.Location;
		A.Shooter = Shooter;
		A.HitType = DT;
	}
}

// (the specimen hit may already be dead of the rest of the shot, or of a burst: it goes off there all the same, from
// the nearest one living)
function Tick( float DT )
{
	local KFWeapon W;

	if ( First != None && (First.bDeleteMe || First.Health <= 0) )
		First = Nearest(self, Spot, 250.0, Mod == 4);
	if ( Shooter != None && Shooter.Health > 0 )
	{
		if ( Mod == 3 )
			Thunder(Shooter, HitType);
		else if ( First == None )
		{
			// (nothing left to set it off on: it is not spent)
			W = KFWeapon(Shooter.Weapon);
			if ( W != None )
				W.ModReadyAt = 0.0;
		}
		else if ( Mod == 1 )
			DeadWire(First, Shooter, HitType);
		else if ( Mod == 2 )
			Furnace(First, Shooter);
		else
			Turn(First, Shooter);
	}
	Destroy();
}

static function KFMonster Nearest( Actor From, vector Spot, float Reach, bool bSmall )
{
	local KFMonster M, Best;

	foreach From.CollidingActors(class'KFMonster', M, Reach, Spot)
	{
		if ( M.Health <= 0 || M.bDeleteMe || M.IsTurned() || (bSmall && M.default.Health > default.TurnedMaxHealth) )
			continue;
		if ( Best == None || VSize(M.Location - Spot) < VSize(Best.Location - Spot) )
			Best = M;
	}
	return Best;
}

static function KFAmmoModFX Show( Actor At, byte Kind )
{
	local KFAmmoModFX FX;

	FX = At.Spawn(class'KFAmmoModFX',,, At.Location);
	if ( FX != None )
		FX.Kind = Kind;
	return FX;
}

static function DeadWire( KFMonster First, Pawn Shooter, class<DamageType> DT )
{
	local KFMonster Chain[6], M, Best;
	local int n, i;
	local float D, BestD;
	local KFAmmoModFX FX;

	Chain[0] = First;
	n = 1;
	while ( n <= default.WireJumps && n < ArrayCount(Chain) )
	{
		Best = None;
		foreach First.CollidingActors(class'KFMonster', M, default.WireReach, Chain[n - 1].Location)
		{
			if ( M.Health <= 0 || M.bDeleteMe || M.IsTurned() )
				continue;
			for ( i = 0; i < n; i++ )
				if ( Chain[i] == M )
					break;
			if ( i < n )
				continue;
			D = VSize(M.Location - Chain[n - 1].Location);
			if ( Best == None || D < BestD )
			{
				Best = M;
				BestD = D;
			}
		}
		if ( Best == None )
			break;
		Chain[n++] = Best;
	}
	FX = Show(First, 1);
	if ( FX != None )
	{
		FX.Count = n;
		for ( i = 0; i < n; i++ )
			FX.Points[i] = Chain[i].Location + vect(0,0,1) * Chain[i].CollisionHeight * 0.3;
		FX.Begin();
	}
	for ( i = 0; i < n; i++ )
	{
		if ( Chain[i] == None || Chain[i].Health <= 0 )
			continue;
		Chain[i].TakeDamage(default.WireDamage, Shooter, Chain[i].Location, vect(0,0,0), DT);
		if ( Chain[i] != None && Chain[i].Health > 0 )
			Chain[i].BlastStagger(Chain[i].Location + VRand() * 30.0);
	}
}

static function Furnace( KFMonster First, Pawn Shooter )
{
	local KFMonster M;
	local KFAmmoModFX FX;
	local int n;

	FX = Show(First, 2);
	foreach First.CollidingActors(class'KFMonster', M, default.FurnaceReach, First.Location)
	{
		if ( M.Health <= 0 || M.bDeleteMe || M.IsTurned() )
			continue;
		if ( FX != None && n < ArrayCount(FX.Points) )
			FX.Points[n++] = M.Location;
		M.TakeIncendiary(12, Shooter);
		M.TakeDamage(default.FurnaceDamage, Shooter, M.Location, vect(0,0,0), class'DamTypeFlamethrower');
	}
	if ( FX != None )
	{
		FX.Count = n;
		FX.Begin();
	}
}

static function Thunder( Pawn Shooter, class<DamageType> DT )
{
	local KFMonster M;
	local KFAmmoModFX FX;
	local vector Aim, Way;

	Aim = vector(Shooter.GetViewRotation());
	Aim.Z = 0;
	Aim = Normal(Aim);
	FX = Show(Shooter, 3);
	if ( FX != None )
	{
		FX.Count = 2;
		FX.Points[0] = Shooter.Location + Aim * 160 + vect(0,0,10);
		FX.Points[1] = Aim;
	}
	foreach Shooter.CollidingActors(class'KFMonster', M, default.ThunderReach, Shooter.Location)
	{
		if ( M.Health <= 0 || M.bDeleteMe || M.IsTurned() )
			continue;
		Way = M.Location - Shooter.Location;
		Way.Z = 0;
		if ( (Normal(Way) dot Aim) < default.ThunderCone )
			continue;
		if ( FX != None && FX.Count < ArrayCount(FX.Points) )
			FX.Points[FX.Count++] = M.Location - vect(0,0,1) * M.CollisionHeight;
		M.TakeDamage(default.ThunderDamage, Shooter, M.Location, vect(0,0,0), DT);
		if ( M == None || M.Health <= 0 )
			continue;
		// (a small one is thrown, a big one only staggered)
		if ( M.default.Health < 400 )
		{
			M.FlipOver();
			M.AddVelocity(Normal(Way) * default.ThunderPush + vect(0,0,220));
		}
		else
			M.BlastStagger(Shooter.Location);
	}
	if ( FX != None )
		FX.Begin();
}

static function Turn( KFMonster M, Pawn Shooter )
{
	local Controller Old, C;
	local FriendlyMonsterAI NewC;
	local KFAmmoModFX FX;

	FX = Show(M, 4);
	if ( FX != None )
	{
		FX.Target = M;
		FX.Count = 1;
		FX.Points[0] = M.Location;
	}
	// a big one is only jolted
	if ( M.default.Health > default.TurnedMaxHealth || M.IsA('ZombieBoss') )
	{
		M.BlastStagger(Shooter.Location);
		if ( FX != None )
			FX.Begin();
		return;
	}
	NewC = M.Spawn(class'FriendlyMonsterAI');
	if ( NewC == None )
		return;
	Old = M.Controller;
	if ( Old != None )
	{
		Old.UnPossess();
		Old.Destroy();
	}
	NewC.Possess(M);
	M.TurnedUntil = M.Level.TimeSeconds + default.TurnedTime;
	// (it fights fresh)
	M.Health = Max(M.Health, int(M.HealthMax));
	// (the bots let it be)
	for ( C = M.Level.ControllerList; C != None; C = C.NextController )
		if ( Bot(C) != None && Bot(C).Squad != None && C.Enemy == M )
			Bot(C).Squad.RemoveEnemy(M);
	if ( FX != None )
	{
		FX.TurnTime = default.TurnedTime;
		FX.Begin();
	}
}

defaultproperties
{
	Names(1)="Dead Wire"
	Names(2)="Blast Furnace"
	Names(3)="Thunder Wall"
	Names(4)="Turned"
	Colors(1)=(B=255,G=150,R=120)
	Colors(2)=(B=40,G=120,R=255)
	Colors(3)=(B=255,G=235,R=200)
	Colors(4)=(B=90,G=255,R=120)
	Chances(1)=0.200000
	Chances(2)=0.200000
	Chances(3)=0.150000
	Chances(4)=0.120000
	Cooldowns(1)=4.000000
	Cooldowns(2)=5.000000
	Cooldowns(3)=8.000000
	Cooldowns(4)=15.000000
	WireDamage=120.000000
	WireReach=350.000000
	WireJumps=4
	FurnaceDamage=60.000000
	FurnaceReach=300.000000
	ThunderDamage=80.000000
	ThunderReach=650.000000
	ThunderPush=900.000000
	ThunderCone=0.600000
	TurnedTime=10.000000
	TurnedMaxHealth=600
	RemoteRole=ROLE_None
}
