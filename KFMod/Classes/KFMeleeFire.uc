// KFMeleeFireto
class KFMeleeFire extends WeaponFire;

var int damageConst;
var int maxAdditionalDamage;
var float ProxySize;

var int NumConHits; // Number of successful strikes before a combo.
var bool bComboTime; // Are we combo-ing?
var int LastComboStartTime;
var int LastConHitTime;
var float ComboConDecay;

var float StopFireTime;
var float f;
var float StartFireTime;

var int dmg;
var int i;

var Name IdleAnim;
var float IdleAnimRate;
var float weaponRange;

var float DamagedelayMin;
var float DamagedelayMax;

var bool bCanHit ;
var Vector EndTraceS;

var class<damageType> hitDamageClass;

var() vector ImpactShakeRotMag;		   // how far to rot view
var() vector ImpactShakeRotRate;		  // how fast to rot view
var() float  ImpactShakeRotTime;		  // how much time to rot the instigator's view
var() vector ImpactShakeOffsetMag;		// max view offset vertically
var() vector ImpactShakeOffsetRate;	   // how fast to offset view vertically
var() float  ImpactShakeOffsetTime;	   // how much time to offset view

var vector SpawnTrace;
var Bool bTrigger;
var Actor SpawnActor;

var float WideDamageMinHitAngle; // The angle to do sweeping strikes in front of the player. If zero do no strikes

// A swept swing (bSweep) lands over the part of its animation where the blade is in front of the player,
// along the line the blade takes across the view. What the crosshair is on is struck where it is aimed
// with the whole blow; what else the blade meets is struck in the body, and the less the further it stands
// from the aim (down to SideDamageScale).
struct Swing
{
	var() name Anim;
	var() float From, To;			// when the blade is in front, seconds into the animation at normal speed
	var() float StartYaw, StartPitch, EndYaw, EndPitch;	// its line across the view, degrees (right and up are positive)
	var() float Across;				// its reach to each side of that line, degrees
	var() float DamageScale;
	var() name BodyAnim;			// the body's swing (third person), seen by everyone and struck by its blade in behind view
	var() float BodyFrom, BodyTo;	// when that blade is in front, fractions of BodyAnim
	var() float Lunge;				// how far the first-person view is pushed forward with the blade
};
var() bool bSweep;
var() byte MeleeKind;				// what its blows on the world look like (KFMeleeHitEffect): 0 a blade, 1 a heavy blade, 2 blunt
var() array<Swing> Swings;			// played in this order while the player keeps swinging
var() float ChainTime;				// longer than this between two swings and the order starts again
var() float SideDamageScale;
var() float UpgradeSideDamageScale;	// the same, upgraded (0: as before)
var() float SweepStep;				// degrees between the rays of a sweep
var() float RunHitSpeed;			// a swing begun faster than this knocks over a specimen no heavier than the player
var() float HitPunch;				// view kick of a blow that lands (rotator units), along the swing
var() float HitPause;				// seconds the weapon hangs in a body it has hit
var() bool bSwingDebug;				// each blow to the log
var() float CamSway;				// degrees the first-person view follows the blade along its line
var() float BladeSpacing;			// units the blade may travel between two tests of it (behind view)
var() float KillPause;				// seconds the weapon hangs longer in a body its blow has killed

var int SwingIndex;
var float LastSwingTime;
var bool bSwinging, bSwingCentre, bSwingFlesh, bSwingWorld;
var float SwingFrom, SwingTo, SwingDone;	// the window, and how much of it has been swept (0 to 1)
var float SwingDamage, SwingRunSpeed;
var array<Pawn> SwingHits;			// what this swing has struck already
var name PausedAnim;
var float PausedFrame, PauseEnd;

// A swing in behind view is struck by the blade of the body's swing (BladeSwing) instead of rays from the eye
var bool bBlade, bBladeWas;
var float BladeEndBy, BladeRate;
var vector BladePivotWas, BladeBaseWas, BladeTipWas;	// where the arm and blade were at the last test
var float BodyPauseEnd, BodyPausedFrame;

// The blow being struck: which way the blade goes, and the line of its edge (KFMonster.NoteBlade)
var vector StrikeMotion, StrikeEdge;

static final function vector GetAimPos( Actor Other )
{
	local KFMonster P;
	local Coords C;

	P = KFMonster(Other);
	if( P==None || P.Health<=0 )
		return Other.Location;
	if( P.HeadBone=='' || SkeletalMesh(P.Mesh)==None )
		return P.Location + vect(0,0,0.9)*P.CollisionHeight;

	C = P.GetBoneCoords(P.HeadBone);
	return C.Origin + (P.HeadHeight * P.HeadScale * C.XAxis);
}

// ---- swept swings

simulated function StartSwing()
{
	local Swing S;
	local float Along;

	// (a swing in behind view not yet over is ended first, while SwingIndex is still its own)
	if ( bBlade )
		EndBlade();
	if ( Level.TimeSeconds - LastSwingTime > ChainTime || SwingIndex + 1 >= Swings.Length )
		SwingIndex = 0;
	else SwingIndex++;
	LastSwingTime = Level.TimeSeconds;

	S = Swings[SwingIndex];
	FireAnim = S.Anim;
	// (the weapon takes TweenTime to reach the animation's first frame)
	SwingFrom = Level.TimeSeconds + TweenTime + S.From / FireAnimRate;
	SwingTo = Level.TimeSeconds + TweenTime + S.To / FireAnimRate;
	SwingDone = 0;
	bSwinging = true;
	bSwingCentre = false;
	bSwingFlesh = false;
	bSwingWorld = false;
	SwingHits.Length = 0;
	SwingDamage = (damageConst + Rand(maxAdditionalDamage)) * S.DamageScale;
	// (taken before the swing brakes the player)
	SwingRunSpeed = VSize(Instigator.Velocity);
	PauseEnd = 0;

	BladeRate = FireAnimRate / default.FireAnimRate;
	if ( KFMeleeAttachment(Weapon.ThirdPersonActor) != None && S.BodyAnim != '' )
	{
		KFMeleeAttachment(Weapon.ThirdPersonActor).SwingAnim = S.BodyAnim;
		KFMeleeAttachment(Weapon.ThirdPersonActor).SwingRate = BladeRate;
	}
	bBlade = BladeFits(S);
	if ( bBlade )
		StartBlade(S);
	else if ( KFPlayerController(Instigator.Controller) != None && Instigator.IsLocallyControlled() )
	{
		Along = FMax(Sqrt(Square(S.EndYaw - S.StartYaw) + Square(S.EndPitch - S.StartPitch)), 1.0);
		KFPlayerController(Instigator.Controller).StartSwingSway(SwingFrom - Level.TimeSeconds, SwingTo - Level.TimeSeconds,
			CamSway * (S.EndYaw - S.StartYaw) / Along, CamSway * (S.EndPitch - S.StartPitch) / Along, S.Lunge);
	}
}

event ModeTick( float dt )
{
	if ( PauseEnd > 0 && Level.TimeSeconds >= PauseEnd )
		EndPause();
	if ( BodyPauseEnd > 0 && Level.TimeSeconds >= BodyPauseEnd )
		EndBodyPause();
	if ( bSwinging && bBlade )
		BladeSwing();
	else if ( bSwinging && Level.TimeSeconds >= SwingFrom )
		SweepSwing();
}

// ---- swings in behind view, struck by the body's blade

// A player in behind view who holds a weapon whose blade is known, on a body that has this swing
simulated function bool BladeFits( Swing S )
{
	local PlayerController PC;

	PC = PlayerController(Instigator.Controller);
	return S.BodyAnim != '' && PC != None && PC.bBehindView && KFPawn(Instigator) != None && Instigator.HasAnim(S.BodyAnim)
		&& KFMeleeAttachment(Weapon.ThirdPersonActor) != None && KFMeleeAttachment(Weapon.ThirdPersonActor).BladeTip != vect(0,0,0);
}

simulated function StartBlade( Swing S )
{
	bBladeWas = false;
	BladeEndBy = Level.TimeSeconds + FireRate + HitPause + 0.3;
	// (the bones place the weapon every tick only while this is set)
	Instigator.bForceSkelUpdate = true;
	// a dedicated server plays no third-person effects, so the swing is played here
	if ( Level.NetMode == NM_DedicatedServer )
		KFPawn(Instigator).PlayMeleeSwing(S.BodyAnim, BladeRate);
	BendBody();
}

simulated function EndBlade()
{
	bBlade = false;
	bSwinging = false;
	if ( Instigator != None )
		Instigator.bForceSkelUpdate = Instigator.default.bForceSkelUpdate;
	if ( BodyPauseEnd > 0 )
		EndBodyPause();
}

// Where the blade is, each tick from the start of the body's swing; struck along the way it went while in front
simulated function BladeSwing()
{
	local Swing S;
	local KFMeleeAttachment W;
	local name Seq;
	local float Frame, Rate;
	local vector Pivot, Base, Tip;

	if ( Weapon != None )
		W = KFMeleeAttachment(Weapon.ThirdPersonActor);
	if ( W == None || Instigator == None || Instigator.Health <= 0 || KFWeapon(Weapon).bNoHit || Level.TimeSeconds > BladeEndBy )
	{
		EndBlade();
		return;
	}
	S = Swings[SwingIndex];
	Instigator.GetAnimParams(1, Seq, Frame, Rate);
	if ( Seq != S.BodyAnim )
	{
		// (another animation has taken its place)
		if ( bBladeWas )
			EndBlade();
		return;
	}
	BendBody();
	W.BladeEnds(Base, Tip);
	Pivot = Shoulder();
	if ( bBladeWas && Frame >= S.BodyFrom )
	{
		if ( bSwingDebug )
			Log("MELEE blade" @ Seq @ "frame" @ Frame @ "tip" @ ((Tip - Instigator.Location) << Instigator.Rotation) @ "authority" @ (Weapon.Role == ROLE_Authority));
		BladeSweep(Pivot, Base, Tip);
		if ( !bSwinging )
			return;
	}
	BladePivotWas = Pivot;
	BladeBaseWas = Base;
	BladeTipWas = Tip;
	bBladeWas = true;
	if ( Frame >= S.BodyTo )
		EndBlade();
}

// The upper body leans with the aim only while it is drawn; where it is not (a server), it is leant here, as
// Pawn.IsHeadShot does
simulated function BendBody()
{
	local int Look;

	if ( Level.TimeSeconds - Instigator.LastRenderTime <= 0.5 || !Instigator.bDoTorsoTwist )
		return;
	Instigator.SmoothViewYaw = Instigator.Rotation.Yaw;
	Instigator.SmoothViewPitch = Instigator.ViewPitch;
	Look = (256 * Instigator.ViewPitch) & 65535;
	if ( Look > 32768 )
		Look -= 65536;
	Instigator.SetTwistLook(0, Look);
}

// The middle the arm swings about
simulated function vector Shoulder()
{
	local rotator R;

	R.Yaw = Instigator.Rotation.Yaw;
	return Instigator.Location + 12.0 * (vect(0,1,0) >> R) + vect(0,0,0.6) * Instigator.CollisionHeight;
}

// A point of the blade between two tests, taken round the shoulder rather than straight across
static final function vector ArcPoint( vector PivotA, vector A, vector PivotB, vector B, float T )
{
	return PivotA + (PivotB - PivotA) * T + Normal(Normal(A - PivotA) * (1.0 - T) + Normal(B - PivotB) * T)
		* (VSize(A - PivotA) * (1.0 - T) + VSize(B - PivotB) * T);
}

// The arm and blade from where they were at the last test to where they are, no more than BladeSpacing apart
simulated function BladeSweep( vector Pivot, vector Base, vector Tip )
{
	local int n, Steps;
	local float T;
	local vector B, P, BWas, PWas;

	Steps = Clamp(int(FMax(VSize(Tip - BladeTipWas), VSize(Base - BladeBaseWas)) / BladeSpacing + 0.99), 1, 16);
	BWas = BladeBaseWas;
	PWas = BladeTipWas;
	for ( n=1; n<=Steps && bSwinging; n++ )
	{
		T = float(n) / float(Steps);
		B = ArcPoint(BladePivotWas, BladeBaseWas, Pivot, Base, T);
		P = ArcPoint(BladePivotWas, BladeTipWas, Pivot, Tip, T);
		BladeRay(BladePivotWas + (Pivot - BladePivotWas) * T, B, P, B - BWas, P - PWas);
		BWas = B;
		PWas = P;
	}
}

// The arm (shoulder to hand) and the blade at one moment: the first thing on them, from the shoulder out, is met
simulated function BladeRay( vector From, vector Base, vector Tip, vector BaseMove, vector TipMove )
{
	local Actor A;
	local Pawn V;
	local vector HL, HN, Start, End;
	local int Leg;

	for ( Leg=0; Leg<2; Leg++ )
	{
		Start = From;
		End = Base;
		if ( Leg == 1 )
		{
			Start = Base;
			End = Tip;
		}
		foreach Instigator.TraceActors(class'Actor', A, HL, HN, End, Start)
		{
			V = SwingBody(A);
			if ( V == None )
			{
				if ( !SwingStops(A) )
					continue;
				if ( !bSwingFlesh )
					WorldHit(A, HL, From, Normal(End - Start));
				return;
			}
			if ( V == Instigator || SwingPasses(V) )
				continue;
			if ( V.Health <= 0 )
			{
				if ( !bSwingFlesh )
				{
					StrikeEdge = Normal(Tip - Base);
					StrikeMotion = Normal(TipMove);
					CorpseHit(V, HL, Normal(TipMove));
				}
			}
			else if ( !SwingHas(V) )
				BladeStrike(V, HL, Base, Tip, BaseMove, TipMove);
			return;
		}
	}
}

// The blade meets a body where it is, going the way it goes; if it is on its way through the head, the head is struck
simulated function BladeStrike( Pawn V, vector Where, vector Base, vector Tip, vector BaseMove, vector TipMove )
{
	local vector Dir, P, D;
	local float U, W;
	local int n;

	SwingHits[SwingHits.Length] = V;
	U = FClamp(((Where - Base) dot (Tip - Base)) / FMax((Tip - Base) dot (Tip - Base), 1.0), 0.0, 1.0);
	Dir = BladeMove(V, BaseMove, TipMove, U);
	if ( !BladeMeetsHead(V, Where, Dir) )
	{
		// (or another part of the blade, further out, is)
		for ( n=1; n<=4; n++ )
		{
			W = U + (1.0 - U) * float(n) / 4.0;
			P = Base + (Tip - Base) * W;
			D = BladeMove(V, BaseMove, TipMove, W);
			if ( BladeMeetsHead(V, P, D) )
			{
				Where = P;
				Dir = D;
				break;
			}
		}
	}
	StrikeEdge = Normal(Tip - Base);
	StrikeMotion = Dir;
	Strike(V, Where, Dir, false, true);
}

// Which way a point of the blade (U along it, 0 at the hand) is going
simulated function vector BladeMove( Pawn V, vector BaseMove, vector TipMove, float U )
{
	local vector M;

	M = BaseMove * (1.0 - U) + TipMove * U;
	if ( VSize(M) < 0.5 )
		return Normal(V.Location - Instigator.Location);
	return Normal(M);
}

// The specimen's own headshot test (KFMonster.IsHeadShot, as for a melee blow): from P along Dir
simulated function bool BladeMeetsHead( Pawn V, vector P, vector Dir )
{
	local KFMonster M;
	local coords C;
	local vector Head, Ray, D;
	local float Scale, T;

	M = KFMonster(V);
	if ( M == None || M.HeadBone == '' || M.bDecapitated )
		return false;
	Scale = 1.0;
	if ( class<DamTypeMelee>(hitDamageClass) != None )
		Scale = 1.25;
	C = M.GetBoneCoords(M.HeadBone);
	Head = C.Origin + M.HeadHeight * M.HeadScale * Scale * C.XAxis;
	Ray = Dir * 2.0 * (M.CollisionHeight + M.CollisionRadius);
	D = Head - P;
	T = FClamp((Ray dot D) / (Ray dot Ray), 0.0, 1.0);
	return VSize(D - T * Ray) < M.HeadRadius * M.HeadScale * Scale;
}

// The body's swing stops for Seconds in what it has hit, as the first-person weapon does (HangWeapon)
simulated function BodyHang( float Seconds )
{
	local name Seq;
	local float Rate;

	if ( Seconds <= 0 )
		return;
	if ( BodyPauseEnd > 0 )
	{
		BodyPauseEnd = FMax(BodyPauseEnd, Level.TimeSeconds + Seconds);
		return;
	}
	Instigator.GetAnimParams(1, Seq, BodyPausedFrame, Rate);
	if ( Seq != Swings[SwingIndex].BodyAnim )
		return;
	// (not quite still: KFPawn.AnimEnd puts the idle on an upper body that has stopped)
	Instigator.PlayAnim(Seq, 0.001, 0.0, 1);
	Instigator.SetAnimFrame(BodyPausedFrame, 1);
	BodyPauseEnd = Level.TimeSeconds + Seconds;
}

simulated function EndBodyPause()
{
	local name Seq;
	local float Frame, Rate;

	BodyPauseEnd = 0;
	if ( Instigator == None )
		return;
	Instigator.GetAnimParams(1, Seq, Frame, Rate);
	if ( Seq == Swings[SwingIndex].BodyAnim && Rate < 0.01 )
	{
		Instigator.PlayAnim(Seq, BladeRate, 0.0, 1);
		Instigator.SetAnimFrame(Frame, 1);
	}
}

// Where the swing is aimed: bots swing at their target's head
simulated function rotator SwingAim( vector Eye )
{
	if ( Instigator.Controller != None && !Instigator.IsHumanControlled() && Instigator.Controller.Target != None )
		return rotator(GetAimPos(Instigator.Controller.Target) - Eye);
	return Instigator.GetViewRotation();
}

// The part of the blade's line passed since the last tick, as rays from the eye
simulated function SweepSwing()
{
	local Swing S;
	local vector Eye, X, Y, Z;
	local float U, A, Along, Yaw, Pitch, AcrossYaw, AcrossPitch, Side;
	local int n, j, k, Steps, Sides;

	if ( Weapon == None || Instigator == None || Instigator.Health <= 0 || KFWeapon(Weapon).bNoHit )
	{
		bSwinging = false;
		return;
	}
	S = Swings[SwingIndex];
	U = FClamp((Level.TimeSeconds - SwingFrom) / FMax(SwingTo - SwingFrom, 0.01), 0.0, 1.0);
	Eye = Instigator.Location + Instigator.EyePosition();
	GetAxes(SwingAim(Eye), X, Y, Z);

	// the line under the crosshair itself, as the blade crosses the middle
	if ( !bSwingCentre && U >= 0.5 )
	{
		bSwingCentre = true;
		CentreRay(Eye, X);
	}

	Yaw = S.EndYaw - S.StartYaw;
	Pitch = S.EndPitch - S.StartPitch;
	Along = FMax(Sqrt(Yaw * Yaw + Pitch * Pitch), 1.0);
	AcrossYaw = -Pitch / Along;
	AcrossPitch = Yaw / Along;
	Steps = Max(1, int((U - SwingDone) * Along / SweepStep + 0.99));
	Sides = int(S.Across / 12.0 + 0.99);
	for ( n=1; n<=Steps && bSwinging; n++ )
	{
		A = SwingDone + (U - SwingDone) * float(n) / float(Steps);
		// (the middle of the blade first, then outward to each side)
		for ( j=0; j<=2*Sides; j++ )
		{
			if ( Sides > 0 )
			{
				k = (j + 1) / 2;
				Side = S.Across * float(k) / float(Sides);
				if ( (j & 1) == 1 )
					Side = -Side;
			}
			SweepRay(Eye, Normal(X + Y * Tan((S.StartYaw + A * Yaw + Side * AcrossYaw) * Pi / 180.0)
				+ Z * Tan((S.StartPitch + A * Pitch + Side * AcrossPitch) * Pi / 180.0)));
		}
	}
	SwingDone = U;
	if ( U >= 1.0 )
		bSwinging = false;
}

// The body an actor stands for: itself, or the specimen whose hit zone it is
simulated function Pawn SwingBody( Actor A )
{
	if ( Vehicle(A) != None )
		return None;
	if ( Pawn(A) != None )
		return Pawn(A);
	if ( ExtendedZCollision(A) != None )
		return Pawn(A.Base);
	return None;
}

simulated function bool SwingStops( Actor A )
{
	return A.bWorldGeometry || A.bBlockActors || A.bProjTarget;
}

// A team-mate the blow cannot hurt does not stop it. (Only the server knows the rule; a client lets it through.)
simulated function bool SwingPasses( Pawn V )
{
	if ( KFHumanPawn(V) == None || KFHumanPawn(Instigator) == None )
		return false;
	return Level.Game == None || TeamGame(Level.Game) == None || TeamGame(Level.Game).FriendlyFireScale <= 0;
}

simulated function bool SwingHas( Pawn V )
{
	local int n;

	for ( n=0; n<SwingHits.Length; n++ )
		if ( SwingHits[n] == V )
			return true;
	return false;
}

// One ray of the sweep: the first living body on it is struck, unless this swing has struck it already
simulated function SweepRay( vector Eye, vector Dir )
{
	local Actor A;
	local Pawn V;
	local vector HL, HN;

	foreach Instigator.TraceActors(class'Actor', A, HL, HN, Eye + Dir * weaponRange, Eye)
	{
		V = SwingBody(A);
		if ( V == None )
		{
			if ( SwingStops(A) )
				break;
			continue;
		}
		if ( V == Instigator || V.Health <= 0 || SwingPasses(V) )
			continue;
		if ( !SwingHas(V) )
			LandOn(V, Eye, Dir, HL);
		break;
	}
}

// The first thing a line from the eye meets is this body: where
simulated function bool RayMeets( Pawn Body, vector Eye, vector Dir, float Reach, out vector Where )
{
	local Actor A;
	local Pawn V;
	local vector HL, HN;

	foreach Instigator.TraceActors(class'Actor', A, HL, HN, Eye + Dir * Reach, Eye)
	{
		V = SwingBody(A);
		if ( V == Body )
		{
			Where = HL;
			return true;
		}
		if ( V == None )
		{
			if ( SwingStops(A) )
				return false;
			continue;
		}
		if ( V == Instigator || V.Health <= 0 || SwingPasses(V) )
			continue;
		return false;
	}
	return false;
}

// The blade has reached a body. Under the crosshair it is struck where the player aims; otherwise where the
// blade crosses its middle, at the height the blade passes.
simulated function LandOn( Pawn V, vector Eye, vector Dir, vector Where )
{
	local vector Aim, At, Spot;
	local bool bAimed;

	SwingHits[SwingHits.Length] = V;
	Aim = vector(SwingAim(Eye));
	if ( RayMeets(V, Eye, Aim, weaponRange, Spot) )
	{
		bAimed = true;
		Where = Spot;
		Dir = Aim;
	}
	else
	{
		At = V.Location;
		At.Z = Eye.Z + Dir.Z / FMax(VSize(Dir * vect(1,1,0)), 0.01) * VSize((At - Eye) * vect(1,1,0));
		At.Z = FClamp(At.Z, V.Location.Z - V.CollisionHeight, V.Location.Z + V.CollisionHeight);
		if ( RayMeets(V, Eye, Normal(At - Eye), weaponRange + V.CollisionRadius, Spot) )
		{
			Where = Spot;
			Dir = Normal(At - Eye);
		}
	}
	StrikeEdge = Dir;
	StrikeMotion = SwingMotion();
	Strike(V, Where, Dir, bAimed);
}

// What the blow's mark and impact on the world go by (KFMeleeHitEffect, read as it is spawned): which way the blade was
// going, and what kind of weapon it is
simulated function NoteWorldHit()
{
	if ( bSweep && Swings.Length > 0 && Instigator != None )
		class'KFMeleeHitEffect'.default.SwingDir = SwingMotion();
	else
		class'KFMeleeHitEffect'.default.SwingDir = VRand();
	class'KFMeleeHitEffect'.default.Kind = MeleeKind;
}

// Which way the first-person blade is crossing the view, in the world
simulated function vector SwingMotion()
{
	local Swing S;
	local vector X, Y, Z;

	S = Swings[SwingIndex];
	GetAxes(SwingAim(Instigator.Location + Instigator.EyePosition()), X, Y, Z);
	return Normal(Y * (S.EndYaw - S.StartYaw) + Z * (S.EndPitch - S.StartPitch));
}

// Which way a body this blow kills is thrown, away from the player and along the blade; longer than one for a
// blow from behind or at a run, which throw harder
simulated function vector BodyThrow( Pawn V, bool bBehind )
{
	local float Scale;

	Scale = 1.0;
	if ( bBehind )
		Scale *= 1.25;
	if ( SwingRunSpeed > RunHitSpeed )
		Scale *= 1.25;
	return Normal(Normal((V.Location - Instigator.Location) * vect(1,1,0)) + 0.6 * StrikeMotion) * Scale;
}

// Blood flicked off along the blade, seen by the player swinging
simulated function BladeSpray( Pawn V, vector Where )
{
	if ( Level.NetMode == NM_DedicatedServer || !Instigator.IsLocallyControlled() || class'GameInfo'.static.NoBlood()
		|| (KFMonster(V) == None && KFHumanPawn(V) == None) )
		return;
	Spawn(class'KFBladeSpray',,, Where, rotator(Normal(StrikeMotion + 0.4 * Normal(V.Location - Instigator.Location))));
}

// bBladeHit: struck by the body's blade (BladeStrike), where it met the body and going the way it went
simulated function Strike( Pawn V, vector Where, vector Dir, bool bAimed, optional bool bBladeHit )
{
	local float Dealt;
	local bool bFirst, bBehind;
	local vector Spot;

	// (where the blade really met it, before the side blow is kept off the head)
	Spot = Where;
	Dealt = SwingDamage;
	if ( bBladeHit )
	{
		// the first body it meets takes the whole blow
		if ( SwingHits.Length > 1 )
			Dealt *= SideScale();
	}
	else if ( !bAimed )
	{
		Dealt *= FClamp(Normal(V.Location - Instigator.Location) dot vector(SwingAim(Instigator.Location + Instigator.EyePosition())), SideScale(), 1.0);
		// in level and low: the head is only for the blow that is aimed at it
		Where.Z = FMin(Where.Z, V.Location.Z + 0.3 * V.CollisionHeight);
		Dir = Normal(Dir * vect(1,1,0));
	}
	bBehind = Normal(V.Location - Instigator.Location) dot vector(V.Rotation) > 0;
	if ( bBehind )
		Dealt *= 2; // Backstab >:P
	bFirst = !bSwingFlesh;
	bSwingFlesh = true;
	if ( bSwingDebug )
		Log("MELEE" @ Weapon.Class.Name @ FireAnim @ "hits" @ V.Name @ "for" @ int(Dealt) @ "aimed" @ bAimed @ "blade" @ bBladeHit @ "at height" @ int(Where.Z - V.Location.Z)
			@ "after" @ (Level.TimeSeconds - LastSwingTime) @ "health" @ V.Health @ "authority" @ (Weapon.Role == ROLE_Authority));

	if ( Weapon.Role == ROLE_Authority )
	{
		if ( KFMonster(V) != None )
			KFMonster(V).NoteBlade(Spot, StrikeMotion, StrikeEdge, BodyThrow(V, bBehind));
		V.TakeDamage(int(Dealt), Instigator, Where, Dir, hitDamageClass);
		if ( SwingHits.Length <= 2 )
			KFMeleeGun(Weapon).PlayHitSound();
		// a blow struck at a run knocks the first one over
		if ( bFirst && KFMonster(V) != None && V.Health > 0 && SwingRunSpeed > RunHitSpeed && V.Mass <= Instigator.Mass )
		{
			if ( bSwingDebug )
				Log("MELEE" @ Weapon.Class.Name @ "knocks over" @ V.Class.Name @ "begun at speed" @ int(SwingRunSpeed));
			KFMonster(V).FlipOver();
		}
	}
	else if ( SwingHits.Length <= 2 )
		KFMeleeGun(Weapon).PlayHitSoundHere();
	BladeSpray(V, Spot);
	FleshFelt(bFirst);
	if ( Weapon.Role == ROLE_Authority && V.Health <= 0 )
	{
		// an upgraded blade gives its holder some health for each kill
		if ( KFMonster(V) != None && KFWeapon(Weapon).bUpgraded && KFWeapon(Weapon).UpgradeKillHeal > 0 )
			Instigator.GiveHealth(KFWeapon(Weapon).UpgradeKillHeal, Instigator.HealthMax);
		if ( Instigator.IsLocallyControlled() )
			KillFelt();
		else
			KFMeleeGun(Weapon).ClientKillFelt(ThisModeNum);
	}
}

// The line under the crosshair: what the sweep has not found there (a body lying dead, a door, a wall)
simulated function CentreRay( vector Eye, vector Aim )
{
	local Actor A;
	local Pawn V;
	local vector HL, HN;

	// (giblets lying where the blade goes)
	class'KFGib'.static.Chop(Instigator, Eye, Aim, weaponRange + 30.0, MeleeKind);
	foreach Instigator.TraceActors(class'Actor', A, HL, HN, Eye + Aim * weaponRange, Eye)
	{
		V = SwingBody(A);
		if ( V == None )
		{
			if ( !SwingStops(A) )
				continue;
			if ( !bSwingFlesh )
				WorldHit(A, HL, Eye, Aim);
			break;
		}
		if ( V == Instigator || SwingPasses(V) )
			continue;
		if ( V.Health > 0 )
		{
			if ( !SwingHas(V) )
				LandOn(V, Eye, Aim, HL);
		}
		else if ( !bSwingFlesh )
		{
			StrikeEdge = Aim;
			StrikeMotion = SwingMotion();
			CorpseHit(V, HL, Aim);
		}
		break;
	}
}

// A body on the ground. (One a client keeps for itself is unknown to the server: the blow lands here.)
simulated function CorpseHit( Pawn V, vector Where, vector Dir )
{
	bSwingFlesh = true;
	if ( bSwingDebug )
		Log("MELEE" @ Weapon.Class.Name @ FireAnim @ "hits the body of" @ V.Name @ "health" @ V.Health @ "torn off" @ V.bTearOff @ "after" @ (Level.TimeSeconds - LastSwingTime) @ "authority" @ (Weapon.Role == ROLE_Authority));
	if ( Weapon.Role == ROLE_Authority || V.bTearOff )
	{
		if ( KFMonster(V) != None )
			KFMonster(V).NoteBlade(Where, StrikeMotion, StrikeEdge, BodyThrow(V, false));
		V.TakeDamage(int(SwingDamage), Instigator, Where, Dir, hitDamageClass);
	}
	if ( Weapon.Role == ROLE_Authority )
		KFMeleeGun(Weapon).PlayHitSound();
	else KFMeleeGun(Weapon).PlayHitSoundHere();
	BladeSpray(V, Where);
	FleshFelt(true);
}

simulated function WorldHit( Actor A, vector Where, vector Eye, vector Aim )
{
	local Swing S;
	local KFPlayerController PC;
	local float Along;

	if ( bSwingWorld )
		return;
	bSwingWorld = true;
	if ( bSwingDebug )
		Log("MELEE" @ Weapon.Class.Name @ FireAnim @ "meets" @ A.Class.Name @ "after" @ (Level.TimeSeconds - LastSwingTime) @ "authority" @ (Weapon.Role == ROLE_Authority));
	if ( Weapon.Role == ROLE_Authority )
		A.TakeDamage(int(SwingDamage), Instigator, Where, Aim, hitDamageClass);
	if ( Weapon.Role == ROLE_Authority || Instigator.IsLocallyControlled() )
	{
		NoteWorldHit();
		Spawn(class'KFMeleeHitEffect',,, Where, rotator(Where - Eye));
	}

	// the blade jars back off it
	PC = KFPlayerController(Instigator.Controller);
	if ( PC == None || !Instigator.IsLocallyControlled() )
		return;
	S = Swings[SwingIndex];
	Along = FMax(Sqrt(Square(S.EndYaw - S.StartYaw) + Square(S.EndPitch - S.StartPitch)), 1.0);
	PC.PunchDamping = PC.default.PunchDamping;
	PC.PunchSpring = PC.default.PunchSpring;
	PC.ViewPunch(-0.5 * HitPunch * (S.EndPitch - S.StartPitch) / Along, -0.5 * HitPunch * (S.EndYaw - S.StartYaw) / Along, HitPunch, HitPunch);
}

// What the player swinging sees and feels of a blow on flesh
simulated function FleshFelt( bool bFirst )
{
	local Swing S;
	local KFPlayerController PC;
	local float Along;

	if ( KFMeleeGun(Weapon).BloodyMaterial != None )
	{
		Weapon.Skins[KFMeleeGun(Weapon).BloodSkinSwitchArray] = KFMeleeGun(Weapon).BloodyMaterial;
		Weapon.Texture = Weapon.default.Texture;
	}
	if ( bFirst && bBlade && (Weapon.Role == ROLE_Authority || Instigator.IsLocallyControlled()) )
		BodyHang(HitPause);
	PC = KFPlayerController(Instigator.Controller);
	if ( !bFirst || PC == None || !Instigator.IsLocallyControlled() )
		return;

	// the view is dragged the way the blade goes
	S = Swings[SwingIndex];
	Along = FMax(Sqrt(Square(S.EndYaw - S.StartYaw) + Square(S.EndPitch - S.StartPitch)), 1.0);
	PC.PunchDamping = PC.default.PunchDamping;
	PC.PunchSpring = PC.default.PunchSpring;
	PC.ViewPunch(HitPunch * (S.EndPitch - S.StartPitch) / Along, HitPunch * (S.EndYaw - S.StartYaw) / Along, HitPunch, HitPunch);

	// and the weapon hangs in the body for a moment
	if ( bBlade )
		return;
	PC.HoldSwingSway(HitPause);
	HangWeapon(HitPause);
}

// The first-person weapon stands still in the body until Seconds from now
simulated function HangWeapon( float Seconds )
{
	local float Rate;

	if ( Seconds <= 0 || Weapon.Mesh == None )
		return;
	if ( PauseEnd > 0 )
	{
		PauseEnd = FMax(PauseEnd, Level.TimeSeconds + Seconds);
		return;
	}
	Weapon.GetAnimParams(0, PausedAnim, PausedFrame, Rate);
	if ( PausedAnim == FireAnim && PausedFrame > 0 )
	{
		Weapon.PlayAnim(PausedAnim, 0.0, 0.0);
		Weapon.SetAnimFrame(PausedFrame);
		PauseEnd = Level.TimeSeconds + Seconds;
	}
}

// A blow that kills hangs on in the body a little longer. bLate: the server's word, come after the hit was felt here,
// so only a hold still going is drawn out.
simulated function KillFelt( optional bool bLate )
{
	local KFPlayerController PC;

	if ( KillPause <= 0 || Instigator == None || Weapon == None )
		return;
	if ( bLate )
	{
		if ( bBlade && BodyPauseEnd > 0 )
			BodyPauseEnd += KillPause;
		else if ( !bBlade && PauseEnd > 0 )
			PauseEnd += KillPause;
		else
			return;
	}
	else if ( bBlade )
		BodyHang(HitPause + KillPause);
	else
		HangWeapon(HitPause + KillPause);
	PC = KFPlayerController(Instigator.Controller);
	if ( PC != None && !bBlade )
		PC.HoldSwingSway(FMax(PauseEnd - Level.TimeSeconds, 0.0));
}

simulated function EndPause()
{
	local name Seq;
	local float Frame, Rate;

	PauseEnd = 0;
	if ( Weapon == None || Weapon.Mesh == None )
		return;
	Weapon.GetAnimParams(0, Seq, Frame, Rate);
	if ( Seq == PausedAnim && Rate == 0 )
	{
		Weapon.PlayAnim(PausedAnim, FireAnimRate, 0.0);
		Weapon.SetAnimFrame(PausedFrame);
	}
}

// ---- the single line of the weapons that do not sweep

simulated function Timer()
{
	DoTrace();
}

simulated function DoTrace()
{
	local Actor HitActor;
	local vector StartTrace, EndTrace, HitLocation, HitNormal;
	local rotator PointRot;
	local int MyDamage;

	local Pawn Victims;
	local vector dir, lookdir;
	local float DiffAngle, VictimDist;

	MyDamage = damageConst + Rand(MaxAdditionalDamage);

	If( Weapon!=None && Instigator!=None && !KFWeapon(Weapon).bNoHit )
	{
		MyDamage = damageConst + Rand(MaxAdditionalDamage);
		StartTrace = Instigator.Location + Instigator.EyePosition();
		if( Instigator.Controller!=None && !Instigator.IsHumanControlled() && Instigator.Controller.Target!=None )
			PointRot = rotator(GetAimPos(Instigator.Controller.Target)-StartTrace); // Give aimbot for bots.
		else 
			PointRot = Instigator.GetViewRotation();
		EndTrace = StartTrace + vector(PointRot)*weaponRange;
		HitActor = Instigator.Trace( HitLocation, HitNormal, EndTrace, StartTrace, true);
	
		if (HitActor!=None)  
		{
			ImpactShakeView();

			if( HitActor.IsA('ExtendedZCollision') && HitActor.Base != none &&
                HitActor.Base.IsA('KFMonster') )
            {
                HitActor = HitActor.Base;
            }

			if ( (HitActor.IsA('KFMonster') || HitActor.IsA('KFHumanPawn')) && KFMeleeGun(Weapon).BloodyMaterial!=none )
			{
				Weapon.Skins[KFMeleeGun(Weapon).BloodSkinSwitchArray] = KFMeleeGun(Weapon).BloodyMaterial;
				Weapon.texture = Weapon.default.Texture;
			}
			if( Level.NetMode==NM_Client )
			{
				if( KFMonster(HitActor)==None )
				{
					NoteWorldHit();
					Spawn(class'KFMeleeHitEffect',,, HitLocation, rotator(HitLocation - StartTrace));
				}
				// a body this machine is keeping: the server has none, so the blow lands here
				else if ( HitActor.bTearOff && KFMonster(HitActor).Health <= 0 )
					HitActor.TakeDamage(MyDamage, Instigator, HitLocation, vector(PointRot), hitDamageClass);
				Return;
			}
			if( HitActor.IsA('Pawn') && !HitActor.IsA('Vehicle') && (Normal(HitActor.Location-Instigator.Location) Dot vector(HitActor.Rotation)) > 0 )
			{
				MyDamage*=2; // Backstab >:P
				//Level.Game.Broadcast(Instigator, "Backstabbed enemy");
			}
			if( (KFMonster(HitActor)!=none) )
			{
			//	log(VSize(Instigator.Velocity));

                HitActor.TakeDamage(MyDamage, Instigator, HitLocation, vector(PointRot), hitDamageClass) ;
				//Spawn(class'KFMeleeHitEffect',,, HitLocation, rotator(HitLocation - (Instigator.Location + Instigator.EyePosition())));
				KFMeleeGun(Weapon).playServerSound();

				if(VSize(Instigator.Velocity) > 300 && KFMonster(HitActor).Mass <= Instigator.Mass)
					KFMonster(HitActor).FlipOver();

			}
			else
			{
				HitActor.TakeDamage(MyDamage, Instigator, HitLocation, vector(PointRot), hitDamageClass) ;
				NoteWorldHit();
				Spawn(class'KFMeleeHitEffect',,, HitLocation, rotator(HitLocation - StartTrace));
			}
		}
		if( WideDamageMinHitAngle > 0 )
		{
            foreach Weapon.VisibleCollidingActors( class 'Pawn', Victims, (weaponRange * 3), StartTrace ) //, RadiusHitLocation
    		{
			if( Victims==HitActor || Victims.Health<=0 || Victims==Instigator )
				continue;

				VictimDist = Vsize(Instigator.Location - Victims.Location);

				if( VictimDist > ((weaponRange * 1.1) + Victims.CollisionRadius) )
					continue;

				lookdir = Normal(Vector(Instigator.GetViewRotation()));
				dir = Normal(Victims.Location - Instigator.Location);

				DiffAngle = lookdir dot dir;

				if( DiffAngle > WideDamageMinHitAngle )
				{
					//Instigator.DrawStayingDebugLine( Victims.Location + vect(0,0,10), Instigator.Location,255, 0, 0);
					//log("Shot would hit "$Victims$" DiffAngle = "$DiffAngle$" WideDamageMinHitAngle = "$WideDamageMinHitAngle$" for damage of: "$(MyDamage*DiffAngle));
					Victims.TakeDamage(MyDamage*DiffAngle, Instigator, (Victims.Location + Victims.CollisionHeight * vect(0,0,0.7)), vector(PointRot), hitDamageClass) ;

					//HitActor.TakeDamage(MyDamage, Instigator, HitLocation, vector(PointRot), hitDamageClass) ;
					Spawn(class'KFMeleeHitEffect',,, (Victims.Location + Victims.CollisionHeight * vect(0,0,0.7)), rotator(Victims.Location - (Instigator.Location + Instigator.EyePosition())));
					KFMeleeGun(Weapon).playServerSound();
				}
				//else
				//{
				//    Instigator.DrawStayingDebugLine( Victims.Location, Instigator.Location,255, 255, 0);
				//    log("Shot would miss "$Victims$" DiffAngle = "$DiffAngle$" WideDamageMinHitAngle = "$WideDamageMinHitAngle);
				//}
    			
    		}
		}
	}
}

function float GetFireSpeed()
{
	if( KFPawn(Instigator)!=None )
		Return KFPawn(Instigator).GetVeteran().Static.GetFireSpeedMod(Weapon);
	Return 1;
}

simulated event ModeDoFire()
{
	local float Rec;

	if (!AllowFire())
		return;

	Rec = GetFireSpeed();
	FireRate = default.FireRate/Rec;
	FireAnimRate = default.FireAnimRate*Rec;
	ReloadAnimRate = default.ReloadAnimRate*Rec;
	if ( bSweep && Swings.Length > 0 )
		StartSwing();
	else
		SetTimer(DamagedelayMin/Rec, False);

	if (MaxHoldTime > 0.0)
		HoldTime = FMin(HoldTime, MaxHoldTime);

	// server
	if (Weapon.Role == ROLE_Authority)
	{
		Weapon.ConsumeAmmo(ThisModeNum, Load);
		DoFireEffect();

		HoldTime = 0;   // if bot decides to stop firing, HoldTime must be reset first
		if ( (Instigator == None) || (Instigator.Controller == None) )
			return;

		if ( AIController(Instigator.Controller) != None )
			AIController(Instigator.Controller).WeaponFireAgain(BotRefireRate, true);

		Instigator.DeactivateSpawnProtection();
	}

	// client
	if (Instigator.IsLocallyControlled())
	{
		ShakeView();
		PlayFiring();
		FlashMuzzleFlash();
		StartMuzzleSmoke();
		ClientPlayForceFeedback(FireForce);
	}
	else // server
		ServerPlayFiring();

	Weapon.IncrementFlashCount(ThisModeNum);

	// set the next firing time. must be careful here so client and server do not get out of sync
	if (bFireOnRelease)
	{
		if (bIsFiring)
			NextFireTime += MaxHoldTime + FireRate;
		else
			NextFireTime = Level.TimeSeconds + FireRate;
	}
	else
	{
		NextFireTime += FireRate;
		NextFireTime = FMax(NextFireTime, Level.TimeSeconds);
	}

	Load = AmmoPerFire;
	HoldTime = 0;

	if (Instigator.PendingWeapon != Weapon && Instigator.PendingWeapon != None)
	{
		bIsFiring = false;
		Weapon.PutDown();
	}

    if( Weapon.Owner != none && Weapon.Owner.Physics != PHYS_Falling )
    {
        if ( KFPawn(Weapon.Owner) != None )
            KFPawn(Weapon.Owner).WeaponBrake(KFMeleeGun(Weapon).ChopSlowRate);
        else
        {
            Weapon.Owner.Velocity.x *= KFMeleeGun(Weapon).ChopSlowRate;
            Weapon.Owner.Velocity.y *= KFMeleeGun(Weapon).ChopSlowRate;
        }
    }
}

function DoFireEffect()
{
	local KFMeleeGun kf;
	local int damage ;

	if(KFMeleeGun(Weapon) == none)
		return;

	kf = KFMeleeGun(Weapon);

	damage = damageConst + Rand(MaxAdditionalDamage) ;
}


simulated function ShakeView()
{
	local PlayerController P;

	if (Instigator == None)
		return;

	P = PlayerController(Instigator.Controller);
	if (P != None )
		P.WeaponShakeView(ShakeRotMag, ShakeRotRate, ShakeRotTime, ShakeOffsetMag, ShakeOffsetRate, ShakeOffsetTime);
}

function SlowDown();

function SpeedUp();

function ResetRate();

function ImpactShakeView()
{
	local PlayerController P;

	P = PlayerController(Instigator.Controller);
	if ( P != None )
		P.WeaponShakeView(ImpactShakeRotMag, ImpactShakeRotRate, ImpactShakeRotTime,ImpactShakeOffsetMag,ImpactShakeOffsetRate,ImpactShakeOffsetTime);
}

// The share of a blow taken by a body other than the first, or beside the aim
simulated function float SideScale()
{
	if ( UpgradeSideDamageScale > 0 && KFWeapon(Weapon) != None && KFWeapon(Weapon).bUpgraded )
		return UpgradeSideDamageScale;
	return SideDamageScale;
}

defaultproperties
{
     maxAdditionalDamage=5
     ProxySize=0.200000
     IdleAnim="Idle"
     IdleAnimRate=1.000000
     weaponRange=75.000000
     DamagedelayMin=0.300000
     DamagedelayMax=0.400000
     hitDamageClass=Class'KFMod.DamTypeMelee'
     ChainTime=0.900000
     SideDamageScale=0.500000
     SweepStep=6.000000
     BladeSpacing=6.000000
     KillPause=0.015000
     RunHitSpeed=280.000000
     ImpactShakeRotMag=(X=50.000000,Y=50.000000,Z=50.000000)
     ImpactShakeRotRate=(X=10000.000000,Y=10000.000000,Z=10000.000000)
     ImpactShakeRotTime=2.000000
     ImpactShakeOffsetMag=(X=10.000000,Y=10.000000,Z=10.000000)
     ImpactShakeOffsetRate=(X=1000.000000,Y=1000.000000,Z=1000.000000)
     ImpactShakeOffsetTime=2.000000
     FireEndAnim=
     FireForce="ShockRifleFire"
     aimerror=100.000000
}
