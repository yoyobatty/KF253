//=============================================================================
// FlameAltFire
// The flamethrower's alternate fire. A plain one sprays its fuel unlit, as the Ballistic Weapons RX22A's gas does: the
// jet wets the floor or wall it lands on (the fuel runs down to the floor below), soaks the specimen it strikes, and
// leaves a cloud of vapour where it falls short or passes; all of it burns later, at any fire, flame, blast or
// lightning (KFFireGrid). Bots do not use it.
//=============================================================================
class FlameAltFire extends WeaponFire;

var() float	SprayRange;
var() float	SprayFuel;			// on the floor where it lands, a squirt
var() float	SprayGas;			// vapour off the jet, a squirt
var() float	SoakFuel;			// on a specimen it strikes
var() float	SpraySpread;

// (Blue Inferno) Held, it charges; let go, it discharges as an arc flash (ArcFlash)
var() float	ChargeTime;			// to full charge
var() int	ChargeAmmo, MinChargeAmmo;	// fuel a full charge takes, and the least it fires on
var() float	ChargeCooldown;
var() float	ArcRange;
var() float	ArcDamage;			// to the one struck, at full charge
var() float	ArcRadius, ArcAreaDamage;	// to all round about, at full charge (less to the edge)
var() float	ArcMomentum;
var() float	ArcCone;			// it finds a specimen this near the aim, as lightning does
var() float	ArcConductRange;	// over metal, at full charge
var() int	ArcConductDamage;
var float	ChargeStart;		// when the hold began (0: not charging)
var float	Charge;				// of the discharge now going off
var bool	bReleased;			// (ModeTick) let go: the discharge is due
var bool	bDischarged;		// (the server) it went off
var() float	OverHold;			// held this long past full charge, it goes off by itself

simulated function bool Upgraded()
{
	return KFWeapon(Weapon) != None && KFWeapon(Weapon).bUpgraded;
}

simulated function bool AllowFire()
{
	if ( KFWeapon(Weapon).bIsReloading )
		return false;
	if ( KFPawn(Instigator).SecondaryItem != None || KFPawn(Instigator).bThrowingNade )
		return false;
	if ( Instigator.HeadVolume != None && Instigator.HeadVolume.bWaterVolume )
		return false;
	if ( Upgraded() )
	{
		if ( KFWeapon(Weapon).FireClip(ThisModeNum) < MinChargeAmmo )
			return false;
		return Super.AllowFire();
	}
	if ( KFWeapon(Weapon).FireClip(ThisModeNum) < 1 )
		return false;
	return Super.AllowFire();
}

// How far charged, 0 to 1 (0 when not charging)
simulated function float ChargeFraction()
{
	if ( ChargeStart <= 0 )
		return 0;
	return FMin((Level.TimeSeconds - ChargeStart) / ChargeTime, 1.0);
}

// (Blue Inferno, on each machine) Held, it charges; let go (or held too long), it goes off. The engine's own repeat
// fire is turned away (ModeDoFire) while it charges.
simulated event ModeTick( float DT )
{
	local FlameThrowerAttachment A;

	Super.ModeTick(DT);
	if ( !Upgraded() )
	{
		ChargeStart = 0;
		return;
	}
	if ( bIsFiring && ChargeStart <= 0 && Level.TimeSeconds >= NextFireTime && AllowFire() )
		ChargeStart = Level.TimeSeconds;
	else if ( ChargeStart > 0 && (!bIsFiring || Level.TimeSeconds - ChargeStart >= ChargeTime + OverHold) )
	{
		Charge = ChargeFraction();
		ChargeStart = 0;
		bReleased = true;
		ModeDoFire();
		bReleased = false;
	}
	if ( Weapon.Role == ROLE_Authority )
	{
		A = FlameThrowerAttachment(Weapon.ThirdPersonActor);
		if ( A != None )
			A.ShowCharge(ChargeFraction());
	}
}

event ModeDoFire()
{
	local int Took;

	if ( !Upgraded() )
	{
		Super.ModeDoFire();
		return;
	}
	if ( !bReleased )
		return;
	Took = Clamp(int(float(ChargeAmmo) * FMax(Charge, 0.3)), MinChargeAmmo, Max(KFWeapon(Weapon).FireClip(ThisModeNum), MinChargeAmmo));
	Load = Took;
	bDischarged = false;
	Super.ModeDoFire();
	Load = AmmoPerFire;
	NextFireTime = Level.TimeSeconds + ChargeCooldown;
	// the clip goes down by all the fuel the charge took, not by one
	if ( bDischarged && Took > 1 && KFWeapon(Weapon) != None )
		KFWeapon(Weapon).ClipLeft = Max(0, KFWeapon(Weapon).ClipLeft - (Took - 1));
}

function DoFireEffect()
{
	if ( Upgraded() )
	{
		bDischarged = true;
		ArcFlash();
	}
	else
		Spray();
}

// (Blue Inferno) The discharge: a bolt to what is aimed at (or the specimen nearest the aim), a blast of plasma and
// current round it, the current on through metal and water, and a flash that blinds; what it kills outright it can blow
// apart (DamTypeArcFlash)
function ArcFlash()
{
	local vector Start, End, HL, HN, X, Push, Spot;
	local Actor Other;
	local KFMonster M, Struck;
	local float C, D, Best, Score, Reach;
	local KFArcFlash F;
	local FlameBurstFire Zapper;
	local int n;

	C = FClamp(Charge, 0.15, 1.0);
	Instigator.MakeNoise(1.0);
	Start = Instigator.Location + Instigator.EyePosition();
	X = vector(AdjustAim(Start, AimError));
	End = Start + X * ArcRange;
	Other = Weapon.Trace(HL, HN, End, Start, true);
	if ( Other == None )
	{
		HL = End;
		HN = -X;
	}
	Struck = KFMonster(Other);
	if ( Struck == None )
	{
		// lightning finds its way to a specimen near the aim
		foreach Weapon.VisibleCollidingActors(class'KFMonster', M, VSize(HL - Start) + 60, Start)
		{
			if ( M.Health <= 0 )
				continue;
			D = VSize(M.Location - Start);
			if ( D < 1.0 || (X dot (M.Location - Start)) / D < ArcCone )
				continue;
			Score = D * (2.0 - (X dot (M.Location - Start)) / D);
			if ( Struck == None || Score < Best )
			{
				Struck = M;
				Best = Score;
			}
		}
		if ( Struck != None )
		{
			HL = Struck.Location;
			HN = Normal(Start - HL);
		}
	}

	F = Weapon.Spawn(class'KFArcFlash', Instigator,, HL + HN * 4, rotator(HN));
	if ( F != None )
		F.Power = byte(255.0 * C);

	if ( Struck != None )
	{
		Struck.TakeDamage(int(ArcDamage * C), Instigator, Struck.Location, X * ArcMomentum * C, class'DamTypeArcFlash');
		if ( Struck != None && !Struck.bDeleteMe && Struck.Health > 0 )
			Struck.Electrocute(Instigator, 1);
	}
	Reach = ArcRadius * (0.55 + 0.45 * C);
	foreach Weapon.VisibleCollidingActors(class'KFMonster', M, Reach, HL)
	{
		if ( M == Struck || M.Health <= 0 )
			continue;
		D = VSize(M.Location - HL);
		Spot = M.Location;
		Push = Normal(Spot - HL + vect(0,0,80)) * ArcMomentum * 0.6 * C * (1.0 - 0.5 * D / Reach);
		M.TakeDamage(int(ArcAreaDamage * C * (1.0 - 0.6 * FMin(D / Reach, 1.0))), Instigator, Spot, Push, class'DamTypeArcFlash');
		// (what the blast blew apart is gone)
		if ( M != None && !M.bDeleteMe && M.Health > 0 )
			M.Electrocute(Instigator, 1);
		if ( F != None && n < 6 )
		{
			F.Ends[n] = Spot;
			n++;
		}
	}
	if ( F != None )
		F.NumEnds = n;

	// the current on through metal or water, far further than the stream's
	Zapper = FlameBurstFire(Weapon.GetFireMode(0));
	if ( Zapper != None )
		Zapper.RunOnFrom(HL, Struck, ArcConductRange * (0.5 + 0.5 * C), int(ArcConductDamage * C));

	// it sets off all vapour and fuel about it
	class'KFFireGrid'.static.Heat(Weapon, HL, 160 + 260 * C, 5.0);
}

// One squirt: where it lands, and the vapour it leaves along the way
function Spray()
{
	local vector Start, Dir, End, HL, HN, X, Y, Z;
	local Actor A;

	Instigator.MakeNoise(0.4);
	Start = Instigator.Location + Instigator.EyePosition();
	GetAxes(AdjustAim(Start, AimError), X, Y, Z);
	Dir = Normal(X + (FRand() - 0.5) * SpraySpread * Y + (FRand() - 0.5) * SpraySpread * Z);
	End = Start + Dir * SprayRange;
	A = Weapon.Trace(HL, HN, End, Start, true);
	if ( A == None )
	{
		// into the air: it falls as it goes, and hangs as a cloud where it ends
		class'KFFireGrid'.static.AddGas(Weapon, End, SprayGas * 1.8, Instigator);
		class'KFFireGrid'.static.AddFuel(Weapon, End, SprayFuel * 0.3, Instigator, 600);
		HL = End;
	}
	else if ( KFMonster(A) != None )
	{
		KFMonster(A).Soak(SoakFuel, Instigator);
		class'KFFireGrid'.static.AddFuel(Weapon, A.Location, SprayFuel * 0.4, Instigator, A.CollisionHeight + 80);
	}
	else if ( Pawn(A) == None )
		class'KFFireGrid'.static.AddFuel(Weapon, HL + HN * 8, SprayFuel, Instigator, 400);
	// vapour off the jet, the more the further it went
	class'KFFireGrid'.static.AddGas(Weapon, Start + (HL - Start) * 0.55, SprayGas, Instigator);
}

defaultproperties
{
     SprayRange=650.000000
     SprayFuel=0.350000
     SprayGas=0.200000
     SoakFuel=0.600000
     SpraySpread=0.120000
     ChargeTime=1.500000
     ChargeAmmo=30
     MinChargeAmmo=8
     ChargeCooldown=1.000000
     OverHold=2.000000
     ArcRange=2000.000000
     ArcDamage=1400.000000
     ArcRadius=480.000000
     ArcAreaDamage=420.000000
     ArcMomentum=90000.000000
     ArcCone=0.950000
     ArcConductRange=1400.000000
     ArcConductDamage=160
     FireRate=0.100000
     AmmoClass=Class'KFMod.FlameAmmo'
     AmmoPerFire=1
     bPawnRapidFireAnim=True
     BotRefireRate=0.000000
     bWaitForRelease=False
     TransientSoundVolume=0.800000
     FireForce="FlakCannonFire"
}
