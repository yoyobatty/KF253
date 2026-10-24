// The Shade: a Crawler that takes to the walls
class ShadeController extends CrawlerController;

// Wall run: with bodies in the way to its victim and a long flat wall beside the way, it leaps onto the wall,
// crawls along it over their heads, level with its victim, and leaps off at it (or down, when it cannot reach it)
var() bool bWallRun;
var() int WallCrowd;					// bodies in the way it takes
var() int WallShare;					// how many on the walls in one place at once
var() float WallMinDist, WallMaxDist;	// its victim at least this far off, and no farther than this
var() float WallReach;					// farthest leap onto the wall (and the first body in the way no farther)
var() float WallMinHeight, WallMaxHeight;	// the middle of its body above the floor while on the wall
var() float WallMinRun, WallMaxRun;		// shortest and longest crawl
var() float WallOverrun;				// how far past its victim it may follow it along the wall
var() float WallLeapSpeed;
var() float WallPounceDist;				// on the wall, its victim this near with nothing between: it leaps at it
var() float WallLongPounce;				// level with its victim at last, it leaps at it from this far, bodies or not
var() float WallCheckGap, WallRestTime;	// seconds between looks for a wall run; after one, before the next
var() bool bWallDebug;
var vector WallStart, WallLine, WallNormal, WallDir;
var float WallA0, WallA1;				// how far along WallLine (in WallDir) it lands on the wall, and the wall's far end
var float NextWallCheck, WallTimeOut;
var bool bCrawling;

state ZombieCharge
{
ignores SeePlayer, HearNoise;

	function Timer()
	{
		if( Level.TimeSeconds>=NextWallCheck && FindWallRun() )
			GotoState('WallRun');
		else Super.Timer();
	}
}

// Quiet on the wall
function ZombieMoan()
{
	if( ZombieShade(Pawn)==None || !ZombieShade(Pawn).bOnWall )
		Super.ZombieMoan();
}

function bool IsWorldWall( Actor A )
{
	Return A!=None && A.bWorldGeometry && Mover(A)==None;
}

// Looks for a wall run past the bodies in the way to its victim (WallStart, WallLine, WallA0, WallA1, WallNormal, WallDir)
function bool FindWallRun()
{
	local vector R, Across, D, Start, HitL, NormL, HitR, NormR, HitLocation, HitNormal;
	local float Dist, Along, Near, Far, Top, FloorZ, GapL, GapR;
	local int Count, Busy;
	local Pawn P;

	NextWallCheck = Level.TimeSeconds + WallCheckGap;
	if( !bWallRun || Enemy==None || ZombieShade(Pawn)==None || Pawn.Physics!=PHYS_Walking || KFM.bShotAnim || KFM.bDecapitated || CanAttack(Enemy) )
		Return False;
	R = Enemy.Location - Pawn.Location;
	if( Abs(R.Z)>WallMaxHeight )
		Return False;
	R.Z = 0;
	Dist = VSize(R);
	if( Dist<WallMinDist || Dist>WallMaxDist )
		Return False;
	R /= Dist;
	Across = R Cross vect(0,0,1);
	FloorZ = Pawn.Location.Z - Pawn.CollisionHeight;
	Near = Dist;
	foreach CollidingActors(class'Pawn', P, Dist*0.5+100, Pawn.Location+R*(Dist*0.5))
	{
		if( P==Pawn || P==Enemy || P.Health<=0 || !P.bBlockActors )
			continue;
		if( ZombieShade(P)!=None && (ZombieShade(P).bOnWall || ZombieShade(P).bWallLeap) && ++Busy>=WallShare )
			Return False;
		D = P.Location - Pawn.Location;
		Along = D Dot R;
		if( Along<0 || Along>Dist-Enemy.CollisionRadius || Abs(D Dot Across)>P.CollisionRadius+Pawn.CollisionRadius+16
		 || Abs(D.Z)>P.CollisionHeight+Pawn.CollisionHeight+30 )
			continue;
		Count++;
		Near = FMin(Near, Along-P.CollisionRadius);
		Far = FMax(Far, Along+P.CollisionRadius);
		Top = FMax(Top, P.Location.Z+P.CollisionHeight-FloorZ);
	}
	if( Count<WallCrowd || Near>WallReach )
		Return False;
	// high enough to pass over them, with room overhead to get up there
	Start = Pawn.Location;
	Start.Z = FloorZ + FMax(WallMinHeight, Top+Pawn.CollisionHeight+4);
	if( Start.Z-FloorZ>WallMaxHeight || Pawn.Trace(HitLocation, HitNormal, Start, Pawn.Location, False, Pawn.GetCollisionExtent())!=None )
		Return False;
	// the nearer wall first
	GapL = SideWall(Start, Across, HitL, NormL);
	GapR = SideWall(Start, -Across, HitR, NormR);
	if( GapR>0 && (GapL<=0 || GapR<GapL) )
	{
		if( PlanWallRun(Start, HitR, NormR, R, Near, Far, Count) )
			Return True;
		Return GapL>0 && PlanWallRun(Start, HitL, NormL, R, Near, Far, Count);
	}
	if( GapL>0 && PlanWallRun(Start, HitL, NormL, R, Near, Far, Count) )
		Return True;
	Return GapR>0 && PlanWallRun(Start, HitR, NormR, R, Near, Far, Count);
}

// How far a wall beside the way stands off to Side (0: none)
function float SideWall( vector Start, vector Side, out vector HitLocation, out vector HitNormal )
{
	local Actor HitActor;

	HitActor = Pawn.Trace(HitLocation, HitNormal, Start+Side*WallReach, Start, False);
	if( IsWorldWall(HitActor) && Abs(HitNormal.Z)<0.1 && (HitNormal Dot Side)<-0.7 )
		Return VSize(HitLocation-Start);
	Return 0;
}

function bool PlanWallRun( vector Start, vector WallHit, vector N, vector R, float Near, float Far, int Count )
{
	local vector A, Line, Extent, HitLocation, HitNormal;
	local float Off, Gap, A0, A1, AMin, Pos;
	local Pawn P;

	A = R - N*(R Dot N);
	A.Z = 0;
	if( VSize(A)<0.5 )
		Return False;
	A = Normal(A);
	// (the line its middle keeps to on the wall, at full width however squeezed it is now: its collision box, not its
	// cylinder, meets the wall)
	Off = Pawn.Default.CollisionRadius*(Abs(N.X)+Abs(N.Y)) + 2;
	Line = WallHit + N*Off;
	Gap = (Start-Line) Dot N;
	// where it lands on the wall, how far on it might follow its victim, and the least that gets it past the last body
	A0 = FClamp(FMin(Gap, Near), 48, WallReach);
	A1 = FMin(((Enemy.Location-Line) Dot A) + WallOverrun, A0+WallMaxRun);
	AMin = FMax(((Pawn.Location+R*(Far+Pawn.CollisionRadius))-Line) Dot A, A0+WallMinRun);
	if( A1<AMin || Sqrt(Gap*Gap+A0*A0)>WallReach )
		Return False;
	// flat as far as it goes, and nothing on it in the way (with a little headroom), not even a tall body by the wall
	for( Pos=A0-32; Pos<A1+32; Pos+=48 )
		if( !FlatWallAt(Line+A*Pos, N, Off) )
		{
			A1 = Pos - 72;
			break;
		}
	Extent = Pawn.Default.CollisionRadius*vect(1,1,0) + Pawn.CollisionHeight*vect(0,0,1) + vect(-2,-2,4);
	// (from short of where it lands, as a trace does not see what it starts inside)
	if( Pawn.Trace(HitLocation, HitNormal, Line+A*A1, Line+A*(A0-48), False, Extent)!=None )
		A1 = ((HitLocation-Line) Dot A) - 8;
	Extent.Z = Pawn.CollisionHeight;
	foreach Pawn.TraceActors(class'Pawn', P, HitLocation, HitNormal, Line+A*A1, Line+A*A0, Extent)
		if( P!=None && P!=Pawn )
			A1 = FMin(A1, ((P.Location-Line) Dot A) - P.CollisionRadius - Pawn.Default.CollisionRadius - 8);
	if( A1<AMin )
		Return False;
	// a clear leap onto it, bodies and all
	Extent = Pawn.GetCollisionExtent() - vect(2,2,2);
	if( !ClearWay(Line+A*A0, Pawn.Location, Extent, None) || !ClearWay(Line+A*A0, Start, Extent, None) )
		Return False;
	WallNormal = N;
	WallDir = A;
	WallLine = Line;
	WallA0 = A0;
	WallA1 = A1;
	WallStart = Line + A*A0;
	if( bWallDebug )
		log("WALL plan"@Pawn@"bodies"@Count@"height"@int(Start.Z-Pawn.Location.Z+Pawn.CollisionHeight)@"wall off"@int(Gap)@"crawl"@int(A1-A0)@"victim"@int(VSize(Enemy.Location-Pawn.Location)));
	Return True;
}

// Nothing in the way from Start to End that would stop it (the world, a prop, a body), but Goal and bodies crowding it,
// or any body when bThroughBodies
function bool ClearWay( vector End, vector Start, vector Extent, Pawn Goal, optional bool bThroughBodies )
{
	local Actor A;
	local vector HitLocation, HitNormal;

	if( Pawn.Trace(HitLocation, HitNormal, End, Start, False, Extent)!=None )
		Return False;
	foreach Pawn.TraceActors(class'Actor', A, HitLocation, HitNormal, End, Start, Extent)
		if( A.bBlockActors && A!=Pawn && A.Owner!=Pawn && A!=Goal && !(bThroughBodies && Pawn(A)!=None)
		 && (Goal==None || Pawn(A)==None || VSize(A.Location-Goal.Location)>A.CollisionRadius+Goal.CollisionRadius+40) )
			Return False;
	Return True;
}

// The wall is there and flat at P, over the height of the body
function bool FlatWallAt( vector P, vector N, float Off )
{
	local vector HitLocation, HitNormal, Up;
	local int i;

	Up = vect(0,0,1)*(Pawn.CollisionHeight-4);
	for( i=-1; i<2; i+=2 )
	{
		if( !IsWorldWall(Pawn.Trace(HitLocation, HitNormal, P+Up*i-N*(Off+16), P+Up*i, False)) || (HitNormal Dot N)<0.97
		 || Abs(((P+Up*i-HitLocation) Dot N)-Off)>8 )
			Return False;
	}
	Return True;
}

// Room over its head, up to 300
function float Headroom()
{
	local vector HitLocation, HitNormal;

	if( Pawn.Trace(HitLocation, HitNormal, Pawn.Location+vect(0,0,300), Pawn.Location, False, Pawn.GetCollisionExtent())==None )
		Return 300;
	Return FMax(HitLocation.Z-Pawn.Location.Z-2, 0);
}

// On the wall: its victim within Reach to leap at under the ceiling, no faster than twice its pounce, with nothing in
// between (bodies aside when bThroughBodies: it lands on whoever is in the way)
function bool CanLeapAt( Pawn Victim, float Reach, optional bool bThroughBodies )
{
	local vector V;

	if( Victim==None || Victim.Health<=0 || VSize(Victim.Location-Pawn.Location)>Reach )
		Return False;
	V = ZombieShade(Pawn).LeapVelocity(PounceSpot(Victim), ZombieShade(Pawn).PounceSpeed, Headroom());
	V.Z = 0;
	Return VSize(V)<=2*ZombieShade(Pawn).PounceSpeed && ClearWay(Victim.Location, Pawn.Location, vect(0,0,0), Victim, bThroughBodies);
}

// Where on the wall to make for: level with its victim, within the stretch of wall it found
function vector CrawlSpot()
{
	local float Pos;

	Pos = WallA1;
	if( Enemy!=None )
		Pos = FClamp((Enemy.Location-WallLine) Dot WallDir, WallA0, WallA1);
	Return WallLine + WallDir*Pos;
}

// Where to drop to off the wall: out from it, towards its victim, else straight out, else back, on a spot nobody stands on
function vector DropSpot()
{
	local vector Dir[3], Spot, First, HitLocation, HitNormal;
	local Pawn P;
	local int i;
	local bool bTaken;

	Dir[0] = WallDir;
	if( Enemy!=None )
		Dir[0] = Enemy.Location-Pawn.Location;
	Dir[0].Z = 0;
	Dir[0] = Normal(Normal(Dir[0]) + WallNormal);
	Dir[1] = WallNormal;
	Dir[2] = Normal(WallNormal - WallDir);
	First = Pawn.Location + WallNormal*80;
	for( i=0; i<3; i++ )
	{
		Spot = Pawn.Location + Dir[i]*160;
		if( !FastTrace(Spot, Pawn.Location) || Pawn.Trace(HitLocation, HitNormal, Spot-vect(0,0,1000), Spot, False)==None )
			continue;
		Spot = HitLocation + vect(0,0,1)*Pawn.CollisionHeight;
		if( i==0 )
			First = Spot;
		bTaken = False;
		foreach CollidingActors(class'Pawn', P, 2*Pawn.CollisionRadius+16, Spot)
			if( P!=Pawn && P.Health>0 )
				bTaken = True;
		if( !bTaken )
			Return Spot;
	}
	Return First;
}

state WallRun
{
ignores SeePlayer, HearNoise, EnemyNotVisible, NotifyBump, DamageAttitudeTo;

	function BeginState()
	{
		bCrawling = False;
		bNotifyFallingHitWall = True;
		SetTimer(0.1, True);
	}
	function EndState()
	{
		bCrawling = False;
		bNotifyFallingHitWall = Default.bNotifyFallingHitWall;
		NextWallCheck = Level.TimeSeconds + WallRestTime;
		if( ZombieShade(Pawn)!=None )
			ZombieShade(Pawn).EndWallRun();
	}
	function Timer()
	{
		if( !bCrawling )
			Return;
		if( Pawn.Physics!=PHYS_Spider || (Pawn.Floor Dot WallNormal)<0.9 )
		{
			bCrawling = False;
			GotoState('WallRun','Fallen');
		}
		else if( CanLeapAt(Enemy, WallPounceDist) )
		{
			bCrawling = False;
			GotoState('WallRun','LeapOff');
		}
		else if( Level.TimeSeconds>WallTimeOut )
		{
			bCrawling = False;
			GotoState('WallRun','DropOff');
		}
		else if( VSize(CrawlSpot()-Destination)>64 )
			GotoState('WallRun','Crawl');
	}
	function SetFall();
	function bool NotifyHitWall( vector HitNormal, actor Wall )
	{
		Return True;
	}
	function bool NotifyLanded( vector HitNormal )
	{
		Return False;
	}

Begin:
	Pawn.Acceleration = vect(0,0,0);
	Focus = None;
	FocalPoint = WallStart;
	if( !ZombieShade(Pawn).WallLeap(WallStart-WallNormal*6, WallNormal, WallDir, WallLeapSpeed) )
		Goto('Done');
	WaitForLanding();
	if( Pawn.Physics!=PHYS_Spider )
	{
		if( bWallDebug )
			log("WALL missed"@Pawn@Pawn.Physics);
		Goto('Done');
	}
	if( bWallDebug )
		log("WALL cling"@Pawn@"off the line"@int(VSize(Pawn.Location-WallStart)));
	bCrawling = True;
	WallTimeOut = Level.TimeSeconds + 1.0 + 1.5*(WallA1-WallA0)/Pawn.GroundSpeed;
Crawl:
	Destination = CrawlSpot();
	MoveTo(Destination);
	if( VSize(CrawlSpot()-Destination)>48 )
		Goto('Crawl');
DropOff:
	bCrawling = False;
	if( Pawn.Physics==PHYS_Spider )
	{
		if( CanLeapAt(Enemy, WallLongPounce, True) )
			Goto('LeapOff');
		if( bWallDebug )
			log("WALL drop"@Pawn@"victim"@int(VSize(Enemy.Location-Pawn.Location)));
		Destination = DropSpot();
		FocalPoint = Destination;
		Focus = Enemy;
		ZombieShade(Pawn).WallJump(Destination, WallLeapSpeed*0.5, Headroom(), False);
	}
	Goto('Fallen');
LeapOff:
	if( Enemy==None )
		Goto('DropOff');
	if( bWallDebug )
		log("WALL leap"@Pawn@"at"@Enemy@int(VSize(Enemy.Location-Pawn.Location)));
	Focus = Enemy;
	ZombieShade(Pawn).WallJump(PounceSpot(Enemy), ZombieShade(Pawn).PounceSpeed, Headroom(), True);
Fallen:
	if( bWallDebug && ZombieShade(Pawn).bOnWall )
		log("WALL fell"@Pawn@Pawn.Physics@Pawn.Floor);
	ZombieShade(Pawn).EndWallRun();
	WaitForLanding();
Done:
	WhatToDoNext(161);
}

defaultproperties
{
     bWallRun=True
     WallCrowd=1
     WallShare=2
     WallMinDist=250.000000
     WallMaxDist=1000.000000
     WallReach=420.000000
     WallMinHeight=110.000000
     WallMaxHeight=200.000000
     WallMinRun=120.000000
     WallMaxRun=1000.000000
     WallOverrun=200.000000
     WallLeapSpeed=550.000000
     WallPounceDist=450.000000
     WallLongPounce=700.000000
     WallCheckGap=0.500000
     WallRestTime=2.000000
}
