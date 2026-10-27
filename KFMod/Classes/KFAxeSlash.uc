//=============================================================================
// KFAxeSlash
// The Executioner's flying cut (AxeSlashFire): the blade's edge thrown on through the air, flat across the way it was
// swung. Every specimen it passes through takes a cleaving blow, and one it kills is cut in two at the waist, the top
// half flying on along the cut (KFMonster.DeathGore, CutInTwo). It widens as it flies, bends the air along it
// (KFAxeSlashWarp), and stops at a wall with a long gash. Players are never hurt by it.
//=============================================================================
class KFAxeSlash extends Projectile;

#exec OBJ LOAD FILE=KFWeaponSound.uax
#exec OBJ LOAD FILE=..\Sounds\WeaponSounds.uax

var() float		StartWidth, EndWidth, GrowTime;	// how wide it cuts at the start and once it has grown, and how soon
var() float		Reach;							// how far it flies
var() int		SlashDamage;
var() float		SlashMomentum;
var vector		Start, LastSpot, Across, Up;
var float		Age;
var bool		bDone;
var array<Pawn>	Struck;
var KFAxeSlashBlade		Blade;
var KFAxeSlashTrail		Trails[3];
var KFAxeSlashWarp		Warp;

simulated function PostBeginPlay()
{
	local vector X;

	Super.PostBeginPlay();
	Velocity = vector(Rotation) * Speed;
	Start = Location;
	LastSpot = Location;
	GetAxes(Rotation, X, Across, Up);
	if ( Level.NetMode != NM_DedicatedServer )
		Dress();
	PlaySound(Sound'KFWeaponSound.axe-swish', SLOT_None, 2.8,, 1600, 0.55);
	PlaySound(Sound'WeaponSounds.BaseFiringSounds.BShockRifleAltFire', SLOT_None, 1.4,, 1600, 1.4);
}

// (each machine that draws it) the glowing edge, its trails and the air bent along it
simulated function Dress()
{
	local int i;

	Blade = Spawn(class'KFAxeSlashBlade', self,, Location, Rotation);
	if ( Blade != None )
		Blade.SetBase(self);
	for ( i = 0; i < ArrayCount(Trails); i++ )
		Trails[i] = Spawn(class'KFAxeSlashTrail', self,, Location, Rotation);
	Warp = class'KFAxeSlashWarp'.static.MakeFor(self);
}

simulated function float WidthNow()
{
	return StartWidth + (EndWidth - StartWidth) * FMin(Age / GrowTime, 1.0);
}

simulated function Tick( float DT )
{
	local float W;
	local int i;
	local vector X;

	if ( bDone )
		return;
	Age += DT;
	W = WidthNow();
	X = vector(Rotation);
	if ( Role == ROLE_Authority )
		Sweep(LastSpot, Location, W);
	LastSpot = Location;
	if ( Level.NetMode != NM_DedicatedServer )
	{
		if ( Blade != None )
			Blade.SetDrawScale(W / 182.0);
		// (the trails at the middle and the two tips, which trail back)
		for ( i = 0; i < ArrayCount(Trails); i++ )
			if ( Trails[i] != None )
				Trails[i].SetLocation(Location + Across * float(i - 1) * 0.47 * W - X * Abs(float(i - 1)) * 0.27 * W);
	}
	if ( VSize(Location - Start) > Reach )
		Fade();
}

// (the server) The specimens the blade passed through since the last tick, each once
function Sweep( vector A, vector B, float W )
{
	local Pawn P;
	local vector X, D;
	local float L, T, S, H;
	local int i;
	local bool bHad;

	X = vector(Rotation);
	L = VSize(B - A);
	foreach CollidingActors(class'Pawn', P, 0.5 * W + L + 120.0, 0.5 * (A + B))
	{
		if ( KFMonster(P) == None || P.Health <= 0 )
			continue;
		D = P.Location - A;
		T = D dot X;
		if ( T < -P.CollisionRadius || T > L + P.CollisionRadius )
			continue;
		S = D dot Across;
		if ( Abs(S) > 0.5 * W + Extent(P, Across) )
			continue;
		H = D dot Up;
		if ( Abs(H) > Extent(P, Up) + 6.0 )
			continue;
		bHad = false;
		for ( i = 0; i < Struck.Length; i++ )
			if ( Struck[i] == P )
			{
				bHad = true;
				break;
			}
		if ( bHad )
			continue;
		Struck[Struck.Length] = P;
		KFMonster(P).NoteSlash(A + X * FClamp(T, 0.0, L), Up, Across, 0.5 * W, X);
		P.TakeDamage(SlashDamage, Instigator, P.Location - X * 0.8 * P.CollisionRadius - Up * H, X * SlashMomentum,
			class'DamTypeAxeSlash');
	}
}

// How far a pawn's cylinder reaches along V
static function float Extent( Pawn P, vector V )
{
	return Abs(V.Z) * P.CollisionHeight + Sqrt(FMax(0.0, 1.0 - V.Z * V.Z)) * P.CollisionRadius;
}

simulated function ProcessTouch( Actor Other, vector HitLocation );

// A wall stops it: a gash across it as wide as the cut, sparks, the ring of steel
simulated function HitWall( vector HitNormal, Actor Wall )
{
	local int i;
	local vector X, P, HL, HN;
	local float W;

	if ( bDone )
		return;
	if ( Level.NetMode != NM_DedicatedServer )
	{
		X = vector(Rotation);
		W = WidthNow();
		for ( i = -1; i <= 1; i++ )
		{
			P = Location + Across * float(i) * 0.33 * W;
			if ( Trace(HL, HN, P + X * 90.0, P - X * 60.0, false) != None )
			{
				class'KFMeleeHitEffect'.default.SwingDir = Across;
				class'KFMeleeHitEffect'.default.Kind = 1;
				Spawn(class'KFMeleeHitEffect',,, HL, rotator(X));
			}
		}
		PlaySound(Sound'KFWeaponSound.KnifeHitMetal', SLOT_None, 2.5,, 1500, 0.7);
		PlaySound(Sound'KFWeaponSound.MetalHitMelee2', SLOT_None, 2.2,, 1500, 0.55);
	}
	Fade();
}

// Spent: it stops and goes out
simulated function Fade()
{
	local int i;

	if ( bDone )
		return;
	bDone = true;
	Velocity = vect(0,0,0);
	SetPhysics(PHYS_None);
	SetCollision(false, false, false);
	if ( Blade != None )
		Blade.Fade();
	Blade = None;
	for ( i = 0; i < ArrayCount(Trails); i++ )
		if ( Trails[i] != None )
			Trails[i].Kill();
	LifeSpan = 0.5;
}

simulated function Destroyed()
{
	local int i;

	if ( Blade != None )
		Blade.Fade();
	for ( i = 0; i < ArrayCount(Trails); i++ )
		if ( Trails[i] != None )
			Trails[i].Kill();
	Super.Destroyed();
}

defaultproperties
{
     StartWidth=170.000000
     EndWidth=270.000000
     GrowTime=0.900000
     Reach=3200.000000
     SlashDamage=900
     SlashMomentum=30000.000000
     Speed=2200.000000
     MaxSpeed=2200.000000
     Damage=0.000000
     MyDamageType=Class'KFMod.DamTypeAxeSlash'
     DrawType=DT_None
     RemoteRole=ROLE_SimulatedProxy
     bNetTemporary=True
     bReplicateInstigator=True
     LifeSpan=3.000000
     CollisionRadius=2.000000
     CollisionHeight=2.000000
     bCollideActors=False
     bBlockZeroExtentTraces=False
     bBlockNonZeroExtentTraces=False
     bProjTarget=False
}
