// Zombie Monster for KF Invasion gametype
class ZombieShade extends ZombieCrawler;

// Wall run (ShadeController): it leaps onto a wall, crawls along it and leaps off again
var bool bWallLeap;			// in the air on its way onto a wall
var bool bOnWall;			// on a wall: clients loop the crawl too
var bool bWallPounce;		// in the air off the wall at its victim
var bool bWallStart;		// clung this frame: its first move along the wall still to come
var name WallAnim;			// what this machine plays on the wall: the crawl, or the idle while it waits there
var vector WallNormal, WallDir;
var float GroundDesiredSpeed;
var() float WallTurnRate;	// how fast it turns onto the wall and back upright (rotation units a second)
var() float WallSpeed;		// its speed on the wall against its speed on the ground
var() float WallPounceDamage;	// the leap off the wall at its victim hits this many times as hard as a pounce on the ground
var() float WallPounceForce;	// and throws the victim back this hard

replication
{
	reliable if(Role == ROLE_Authority)
		bOnWall;
}

// The velocity that carries it from here to Spot at Speed over the ground, or faster and flatter, so that it rises
// no more than Rise above the higher end of the leap
function vector LeapVelocity( vector Spot, float Speed, float Rise )
{
	local vector V;
	local float T, G, DZ, Up, Top;

	V = Spot - Location;
	DZ = V.Z;
	V.Z = 0;
	G = FMax(-PhysicsVolume.Gravity.Z, 1);
	T = FMax(VSize(V)/Speed, 0.2);
	Up = DZ/T + 0.5*G*T;
	Top = FMax(DZ, 0) + Rise;
	// (the top of the flight comes before Spot and is too high: launched no faster upwards than reaches that height,
	// it gets there in the time that takes)
	if( Up>0 && Up/G<T && Up*Up/(2*G)>Top )
	{
		Up = Sqrt(2*G*Top);
		T = (Up + Sqrt(FMax(Up*Up-2*G*DZ, 0)))/G;
	}
	V /= T;
	V.Z = Up;
	Return V;
}

// Leap at the wall facing N, to cling to it with the middle of the body at Spot and crawl along it towards Dir
function bool WallLeap( vector Spot, vector N, vector Dir, float Speed )
{
	if( Physics!=PHYS_Walking || bShotAnim )
		Return False;
	WallNormal = N;
	WallDir = Dir;
	bWallLeap = True;
	bDirectHitWall = True;
	Velocity = LeapVelocity(Spot, Speed, 0);
	SetPhysics(PHYS_Falling);
	ZombieSpringAnim();
	Return True;
}

event HitWall( vector HitNormal, actor Wall )
{
	if( bWallLeap && Physics==PHYS_Falling && Wall!=None && Wall.bWorldGeometry && Mover(Wall)==None && (HitNormal Dot WallNormal)>0.9 )
		ClingTo(Wall, HitNormal);
	else Super.HitWall(HitNormal, Wall);
}

function ClingTo( Actor Wall, vector N )
{
	local vector X;

	bWallLeap = False;
	bDirectHitWall = Default.bDirectHitWall;
	WallNormal = N;
	// (squeezed thin in the crowd: back to full width, out from the wall by what that adds)
	if( bCrowdRadiusShrunk )
	{
		Move(N*(PreCrowdShrinkRadius-CollisionRadius)*(Abs(N.X)+Abs(N.Y)));
		bCrowdRadiusShrunk = False;
		SetCollisionSize(PreCrowdShrinkRadius, CollisionHeight);
	}
	SetPhysics(PHYS_Spider);
	SetBase(Wall, N);
	// belly to the wall, head along it
	X = Normal(WallDir - N*(WallDir Dot N));
	bRollToDesired = True;
	RotationRate.Yaw = WallTurnRate;
	DesiredRotation = OrthoRotation(X, N Cross X, N);
	GroundDesiredSpeed = MaxDesiredSpeed;
	MaxDesiredSpeed *= WallSpeed;
	bOnWall = True;
	bWallStart = True;
}

function LeaveWall()
{
	if( bOnWall )
		MaxDesiredSpeed = GroundDesiredSpeed;
	bOnWall = False;
	bRollToDesired = False;
	DesiredRotation.Pitch = 0;
	DesiredRotation.Roll = 0;
	if( Physics==PHYS_Spider )
		SetPhysics(PHYS_Falling);
}

// Leap off the wall at Spot
function WallJump( vector Spot, float Speed, float Rise, bool bAttack )
{
	local vector V;

	V = LeapVelocity(Spot, Speed, Rise);
	LeaveWall();
	Velocity = V;
	bPouncing = bAttack;
	bWallPounce = bAttack;
	ZombieSpringAnim();
}

// The leap off the wall lands harder than a pounce from the ground, and throws its victim back
event Bump( actor Other )
{
	local KFHumanPawn P;

	P = KFHumanPawn(Other);
	if( bWallPounce && bPouncing && P!=None )
	{
		bWallPounce = False;
		bPouncing = False;
		P.TakeDamage(int((damageConst+rand(damageRand))*WallPounceDamage), Self, Location, Normal(Velocity)*WallPounceForce, class'KFmod.ZombieMeleeDamage');
		if( P.Health<=0 )
			P.SpawnGibs(Rotation, 1);
	}
	Super.Bump(Other);
}

// Done with the wall: off it if still on, and no clinging
function EndWallRun()
{
	bWallLeap = False;
	bDirectHitWall = Default.bDirectHitWall;
	if( bOnWall )
		LeaveWall();
}

event Landed( vector HitNormal )
{
	bWallLeap = False;
	bWallPounce = False;
	bDirectHitWall = Default.bDirectHitWall;
	// (the roll went out with the full position until now, so clients saw it right itself)
	if( !bOnWall )
	{
		RotationRate = Default.RotationRate;
		bUseCompressedPosition = Default.bUseCompressedPosition;
	}
	Super.Landed(HitNormal);
}

function ShrinkForCrowding()
{
	if( !bOnWall )
		Super.ShrinkForCrowding();
}

// A blast throws it off its wall
function AddVelocity( vector NewVelocity )
{
	if( bOnWall && VSize(NewVelocity)>50 )
		LeaveWall();
	Super.AddVelocity(NewVelocity);
}

simulated function StartWallAnim( name Anim, float Rate )
{
	WallAnim = Anim;
	bPhysicsAnimUpdate = False;
	LoopAnim(Anim, Rate, 0.15);
}

simulated function StopWallAnim()
{
	WallAnim = '';
	bPhysicsAnimUpdate = Default.bPhysicsAnimUpdate;
}

// (a client guesses flying for a pawn without gravity and would play it in the air; an action on channel 0 hands back to the
// movement animations when it ends)
simulated function Tick( float DeltaTime )
{
	local name Anim;

	Super.Tick(DeltaTime);
	// on along the wall level, not on up into whatever is overhead (here, before its first move on the wall: the fall
	// that brought it there sets its velocity from the way it went, after HitWall)
	if( bWallStart )
	{
		bWallStart = False;
		Velocity = WallDir*FMax(Velocity Dot WallDir, 0);
	}
	if( bOnWall )
	{
		Anim = MovementAnims[0];
		if( VSize(Velocity)<20 )
			Anim = IdleRestAnim;
		if( Anim!=WallAnim || bPhysicsAnimUpdate )
		{
			if( Anim==IdleRestAnim )
				StartWallAnim(Anim, 1.0);
			else StartWallAnim(Anim, WallSpeed);
		}
	}
	else if( WallAnim!='' )
		StopWallAnim();
}

simulated function PlayDying( class<DamageType> DamageType, vector HitLoc )
{
	bOnWall = False;
	bRollToDesired = False;
	if( WallAnim!='' )
		StopWallAnim();
	Super.PlayDying(DamageType, HitLoc);
}

defaultproperties
{
     WallTurnRate=120000.000000
     WallSpeed=1.500000
     WallPounceDamage=2.500000
     WallPounceForce=100000.000000
     PounceSpeed=500.000000
     ScoringValue=2
     MeleeRange=80.000000
     GroundSpeed=240.000000
     WaterSpeed=220.000000
     Health=80
     MenuName="Shade"
     ControllerClass=Class'KFChar.ShadeController'
     MovementAnims(0)="ZombieLeap"
     MovementAnims(1)="ZombieLeap"
     MovementAnims(2)="ZombieLeap"
     MovementAnims(3)="ZombieLeap"
     WalkAnims(0)="ZombieLeap"
     WalkAnims(1)="ZombieLeap"
     WalkAnims(2)="ZombieLeap"
     WalkAnims(3)="ZombieLeap"
}
