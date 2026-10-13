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
};
var() bool bSweep;
var() array<Swing> Swings;			// played in this order while the player keeps swinging
var() float ChainTime;				// longer than this between two swings and the order starts again
var() float SideDamageScale;
var() float SweepStep;				// degrees between the rays of a sweep
var() float RunHitSpeed;			// a swing begun faster than this knocks over a specimen no heavier than the player
var() float HitPunch;				// view kick of a blow that lands (rotator units), along the swing
var() float HitPause;				// seconds the weapon hangs in a body it has hit
var() bool bSwingDebug;				// each blow to the log

var int SwingIndex;
var float LastSwingTime;
var bool bSwinging, bSwingCentre, bSwingFlesh, bSwingWorld;
var float SwingFrom, SwingTo, SwingDone;	// the window, and how much of it has been swept (0 to 1)
var float SwingDamage, SwingRunSpeed;
var array<Pawn> SwingHits;			// what this swing has struck already
var name PausedAnim;
var float PausedFrame, PauseEnd;

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
}

event ModeTick( float dt )
{
	if ( PauseEnd > 0 && Level.TimeSeconds >= PauseEnd )
		EndPause();
	if ( bSwinging && Level.TimeSeconds >= SwingFrom )
		SweepSwing();
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
	Strike(V, Where, Dir, bAimed);
}

simulated function Strike( Pawn V, vector Where, vector Dir, bool bAimed )
{
	local float Dealt;
	local bool bFirst;

	Dealt = SwingDamage;
	if ( !bAimed )
	{
		Dealt *= FClamp(Normal(V.Location - Instigator.Location) dot vector(SwingAim(Instigator.Location + Instigator.EyePosition())), SideDamageScale, 1.0);
		// in level and low: the head is only for the blow that is aimed at it
		Where.Z = FMin(Where.Z, V.Location.Z + 0.3 * V.CollisionHeight);
		Dir = Normal(Dir * vect(1,1,0));
	}
	if ( Normal(V.Location - Instigator.Location) dot vector(V.Rotation) > 0 )
		Dealt *= 2; // Backstab >:P
	bFirst = !bSwingFlesh;
	bSwingFlesh = true;
	if ( bSwingDebug )
		Log("MELEE" @ Weapon.Class.Name @ FireAnim @ "hits" @ V.Name @ "for" @ int(Dealt) @ "aimed" @ bAimed @ "at height" @ int(Where.Z - V.Location.Z)
			@ "after" @ (Level.TimeSeconds - LastSwingTime) @ "health" @ V.Health @ "authority" @ (Weapon.Role == ROLE_Authority));

	if ( Weapon.Role == ROLE_Authority )
	{
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
	FleshFelt(bFirst);
}

// The line under the crosshair: what the sweep has not found there (a body lying dead, a door, a wall)
simulated function CentreRay( vector Eye, vector Aim )
{
	local Actor A;
	local Pawn V;
	local vector HL, HN;

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
			// a body on the ground. (One a client keeps for itself is unknown to the server: the blow lands here.)
			bSwingFlesh = true;
			if ( Weapon.Role == ROLE_Authority || V.bTearOff )
				V.TakeDamage(int(SwingDamage), Instigator, HL, Aim, hitDamageClass);
			if ( Weapon.Role == ROLE_Authority )
				KFMeleeGun(Weapon).PlayHitSound();
			else KFMeleeGun(Weapon).PlayHitSoundHere();
			FleshFelt(true);
		}
		break;
	}
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
		Spawn(class'KFMeleeHitEffect',,, Where, rotator(Where - Eye));

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
	local float Along, Rate;

	if ( KFMeleeGun(Weapon).BloodyMaterial != None )
	{
		Weapon.Skins[KFMeleeGun(Weapon).BloodSkinSwitchArray] = KFMeleeGun(Weapon).BloodyMaterial;
		Weapon.Texture = Weapon.default.Texture;
	}
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
	if ( HitPause > 0 && PauseEnd <= 0 && Weapon.Mesh != None )
	{
		Weapon.GetAnimParams(0, PausedAnim, PausedFrame, Rate);
		if ( PausedAnim == FireAnim && PausedFrame > 0 )
		{
			Weapon.PlayAnim(PausedAnim, 0.0, 0.0);
			Weapon.SetAnimFrame(PausedFrame);
			PauseEnd = Level.TimeSeconds + HitPause;
		}
	}
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
					Spawn(class'KFMeleeHitEffect',,, HitLocation, rotator(HitLocation - StartTrace));
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
