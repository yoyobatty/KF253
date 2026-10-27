//
//=============================================================================
class FlameBurstFire extends CrossbowFire;

var byte FlockIndex;
var int MaxLoad;
// (Blue Inferno) lightning with the fire, every ZapInterval: at the specimen nearest the aim within ZapRange and ZapCone,
// then on to the nearest within ZapChainRange of the last, twice
var() float ZapInterval, ZapRange, ZapCone, ZapChainRange;
var() int ZapDamage, ZapChainDamage;
var float NextZapTime;
var() bool bConduct;			// the lightning runs on through a metal floor and through water (Conduct)
var() float ConductInterval, ConductRange, WaterRange;
var() int ConductDamage, WaterDamage;
var float NextConduct;

function Recoil( float Multi );

simulated function bool AllowFire()
{
	if(KFWeapon(Weapon).bIsReloading)
		return false;
	if(KFPawn(Instigator).SecondaryItem!=none)
		return false;
	if(KFPawn(Instigator).bThrowingNade)
		return false;
	if(KFWeapon(Weapon).FireClip(ThisModeNum) < 1)
	{
		if(Level.TimeSeconds - LastClickTime > FireRate)
		{
            LastClickTime = Level.TimeSeconds;
			Weapon.PlayOwnedSound(NoAmmoSound, SLOT_Interact, TransientSoundVolume,,,, false);
			if(Weapon.HasAnim(EmptyAnim))
				weapon.PlayAnim(EmptyAnim, EmptyAnimRate, 0.0);
		}
		if( AIController(Instigator.Controller)!=None )
			KFWeapon(Weapon).ReloadMeNow();
		return false;
	}
	
	return Super.AllowFire();
}

// (the fire grid) Vapour and fuel along the stream catch, as far as the stream goes
function GridHeat()
{
	local vector Start, End, HitLocation, HitNormal;

	if ( Instigator == None || Weapon == None )
		return;
	Start = Instigator.Location + Instigator.EyePosition();
	End = Start + vector(Instigator.GetViewRotation()) * MaxRange() * 0.85;
	if ( Weapon.Trace(HitLocation, HitNormal, End, Start, false) != None )
		End = HitLocation;
	class'KFFireGrid'.static.HeatLine(Weapon, Start, End, 1.2);
}

function DoFireEffect()
{
    local Vector StartProj, StartTrace, X,Y,Z;
    local Rotator Aim;
    local Vector HitLocation, HitNormal,FireLocation;
    local Actor Other;
    local int p, SpawnCount;
    local FlameTendril FiredRockets[4];

    if ( Upgraded() && Level.TimeSeconds >= NextZapTime )
    {
        NextZapTime = Level.TimeSeconds + ZapInterval;
        Zap();
    }

    GridHeat();

    if ( (SpreadStyle == SS_Line) || (Load < 2) )
    {
        Super.DoFireEffect();
        return;
    }
    
    Instigator.MakeNoise(1.0);
    Weapon.GetViewAxes(X,Y,Z);

    StartTrace = Instigator.Location + Instigator.EyePosition();
    StartProj = StartTrace + X*ProjSpawnOffset.X + Z*ProjSpawnOffset.Z;
    if ( !Weapon.WeaponCentered() )
        StartProj = StartProj + Weapon.Hand * Y*ProjSpawnOffset.Y;

    // check if projectile would spawn through a wall and adjust start location accordingly
    Other = Weapon.Trace(HitLocation, HitNormal, StartProj, StartTrace, false);
    if (Other != None)
    {
        StartProj = HitLocation;
    }
    
    Aim = AdjustAim(StartProj, AimError);


	SpawnCount = Max(1, int(Load));

	for ( p=0; p<SpawnCount; p++ )
	{
		Firelocation = StartProj - 2*((Sin(p*2*PI/MaxLoad)*8 - 7)*Y - (Cos(p*2*PI/MaxLoad)*8 - 7)*Z) - X * 8 * FRand();
		FiredRockets[p] = FlameTendril(SpawnProjectile(FireLocation, Aim));
	}
}

// (Blue Inferno) Each one struck is hurt and held shaking for a moment (KFMonster.Electrocute); the attachment tells every
// machine where the bolts go
function Zap()
{
	local vector Start, X, D;
	local KFMonster M, Best, Hit[3];
	local float Dist, Score, BestScore;
	local int i;
	local FlameThrowerAttachment A;

	Start = Instigator.Location + Instigator.EyePosition();
	X = vector(Instigator.GetViewRotation());
	foreach Weapon.VisibleCollidingActors(class'KFMonster', M, ZapRange, Start)
	{
		if ( M.Health <= 0 )
			continue;
		D = M.Location - Start;
		Dist = VSize(D);
		if ( Dist < 1.0 || (D dot X) / Dist < ZapCone )
			continue;
		Score = Dist * (2.0 - (D dot X) / Dist);
		if ( Best == None || Score < BestScore )
		{
			Best = M;
			BestScore = Score;
		}
	}
	Hit[0] = Best;
	for ( i=1; i<3 && Hit[i-1] != None; i++ )
	{
		Best = None;
		foreach Weapon.VisibleCollidingActors(class'KFMonster', M, ZapChainRange, Hit[i-1].Location)
		{
			if ( M.Health <= 0 || M == Hit[0] || M == Hit[1] )
				continue;
			Dist = VSize(M.Location - Hit[i-1].Location);
			if ( Best == None || Dist < BestScore )
			{
				Best = M;
				BestScore = Dist;
			}
		}
		Hit[i] = Best;
	}
	A = FlameThrowerAttachment(Weapon.ThirdPersonActor);
	for ( i=0; i<3; i++ )
	{
		if ( A != None )
			A.ZapTarget[i] = Hit[i];
		if ( Hit[i] == None )
			continue;
		// (lightning sets off vapour and fuel where it strikes)
		class'KFFireGrid'.static.Heat(Weapon, Hit[i].Location, 120, 1.5);
		if ( i == 0 )
			Hit[i].Electrocute(Instigator, ZapDamage);
		else
			Hit[i].Electrocute(Instigator, ZapChainDamage);
	}
	if ( bConduct && Level.TimeSeconds >= NextConduct )
	{
		NextConduct = Level.TimeSeconds + ConductInterval;
		Conduct(Start, X, Hit[0], Hit[1], Hit[2], A);
	}
	else if ( A != None && Hit[0] != None )
		A.bZapSpot = false;
}

// The lightning runs on from where it strikes: from under the first one struck that stands on metal or in water, or
// with no one to strike, from the metal floor or the water it strikes ahead instead
function Conduct( vector Start, vector X, KFMonster H0, KFMonster H1, KFMonster H2, FlameThrowerAttachment A )
{
	local KFMonster M;
	local vector Spot, HL, HN;
	local Material Mat;
	local Actor Other;
	local PhysicsVolume V;
	local byte Surf;
	local int i;

	if ( A != None )
		A.bZapSpot = false;
	if ( H0 == None )
	{
		Other = Weapon.Trace(HL, HN, Start + X * ZapRange * 0.7, Start, true,, Mat);
		if ( Other == None || Pawn(Other) != None )
			return;
		V = Level.GetPhysicsVolume(HL + HN * 4);
		if ( V != None && V.bWaterVolume )
		{
			RunOn(HL, None, None, None, V);
			if ( A != None )
			{
				A.ZapSpot = HL;
				A.bZapSpot = true;
			}
			return;
		}
		if ( !Other.IsA('LevelInfo') && Other.SurfaceType != EST_Default )
			Surf = Other.SurfaceType;
		else if ( Mat != None )
			Surf = Mat.SurfaceType;
		if ( Surf != 3 )
			return;
		// a metal wall: down to the floor at its foot
		if ( HN.Z < 0.6 && class'KFZapConduct'.static.FloorSurface(Weapon, HL + HN * 24, 300, Spot) == 3 )
			HL = Spot;
		else if ( HN.Z < 0.6 )
			return;
		RunOn(HL + vect(0,0,3), None, None, None, None);
		if ( A != None )
		{
			A.ZapSpot = HL;
			A.bZapSpot = true;
		}
		return;
	}
	for ( i = 0; i < 3; i++ )
	{
		if ( i == 0 )
			M = H0;
		else if ( i == 1 )
			M = H1;
		else
			M = H2;
		if ( M == None || M.bDeleteMe )
			break;
		if ( M.PhysicsVolume != None && M.PhysicsVolume.bWaterVolume )
		{
			RunOn(M.Location, H0, H1, H2, M.PhysicsVolume);
			return;
		}
		if ( class'KFZapConduct'.static.FloorSurface(Weapon, M.Location, M.CollisionHeight + 40, Spot) == 3 )
		{
			RunOn(Spot + vect(0,0,3), H0, H1, H2, None);
			return;
		}
	}
}

// (the arc flash, FlameAltFire) The current on from where it struck, over Range and with Damage: through water if it
// struck in water, or over the metal floor below if there is metal there
function RunOnFrom( vector P, KFMonster Struck, float Range, int Damage )
{
	local PhysicsVolume V;
	local vector Spot;

	V = Level.GetPhysicsVolume(P);
	if ( V != None && V.bWaterVolume )
	{
		RunOn(P, Struck, None, None, V, Range, Damage);
		return;
	}
	if ( class'KFZapConduct'.static.FloorSurface(Weapon, P + vect(0,0,10), 220, Spot) == 3 )
		RunOn(Spot + vect(0,0,3), Struck, None, None, None, Range, Damage);
}

// Through the water V to all in it, or over the metal floor from From to all standing on it, and off over the metal
// round about; those already struck are passed over. Range and Damage: the stream's own when not given
function RunOn( vector From, KFMonster H0, KFMonster H1, KFMonster H2, PhysicsVolume V, optional float Range, optional int Damage )
{
	local KFMonster M;
	local KFZapConduct C;
	local vector Spot, Ends[6], Dir;
	local int n, k;

	if ( V != None )
	{
		if ( Range <= 0 )
			Range = WaterRange;
		if ( Damage <= 0 )
			Damage = WaterDamage;
		foreach Weapon.CollidingActors(class'KFMonster', M, Range, From)
			if ( M.Health > 0 && M != H0 && M != H1 && M != H2 && n < 6 && (M.PhysicsVolume == V || M.HeadVolume == V) )
			{
				Ends[n] = M.Location;
				n++;
				M.Electrocute(Instigator, Damage);
			}
	}
	else
	{
		if ( Range <= 0 )
			Range = ConductRange;
		if ( Damage <= 0 )
			Damage = ConductDamage;
		foreach Weapon.CollidingActors(class'KFMonster', M, Range, From)
		{
			if ( M.Health <= 0 || M == H0 || M == H1 || M == H2 || n >= 6 )
				continue;
			if ( class'KFZapConduct'.static.FloorSurface(Weapon, M.Location, M.CollisionHeight + 40, Spot) != 3 )
				continue;
			if ( !class'KFZapConduct'.static.MetalPath(Weapon, From, Spot) )
				continue;
			Ends[n] = Spot + vect(0,0,3);
			n++;
			M.Electrocute(Instigator, Damage);
		}
		// and off over the metal round about
		for ( k = 0; k < 8 && n < 6 && n < 4; k++ )
		{
			Dir = VRand();
			Dir.Z = 0;
			Spot = From + Normal(Dir) * (140 + 220 * FRand());
			if ( class'KFZapConduct'.static.FloorSurface(Weapon, Spot + vect(0,0,40), 110, Spot) == 3
				&& class'KFZapConduct'.static.MetalPath(Weapon, From, Spot) )
			{
				Ends[n] = Spot + vect(0,0,3);
				n++;
			}
		}
	}
	if ( n == 0 )
		return;
	C = Weapon.Spawn(class'KFZapConduct',,, From);
	if ( C == None )
		return;
	for ( k = 0; k < n; k++ )
		C.Ends[k] = Ends[k];
	C.NumEnds = n;
	C.bWater = V != None;
}

// As far as the stream reaches (at 2000 bots sprayed specimens it could not reach)
function float MaxRange()
{
    return class'FlameTendril'.default.Speed * class'FlameTendril'.static.FlightFor(Instigator) + ProjSpawnOffset.X;
}

// An upgraded flamethrower's fuel burns hotter
function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
	local Projectile P;

	P = Super.SpawnProjectile(Start, Dir);
	if ( FlameTendril(P) != None && Upgraded() )
		FlameTendril(P).bHot = true;
	return P;
}

defaultproperties
{
    bNoShotLight=True
    MaxLoad=3
    ZapInterval=0.120000
    bConduct=True
    ConductInterval=0.220000
    ConductRange=650.000000
    WaterRange=1000.000000
    ConductDamage=12
    WaterDamage=14
    ZapRange=900.000000
    ZapCone=0.800000
    ZapChainRange=300.000000
    ZapDamage=15
    ZapChainDamage=10
    ProjSpawnOffset=(X=65.000000,Y=10.000000,Z=-15.000000)
    bSplashDamage=True
    bRecommendSplashDamage=True
    bAttachSmokeEmitter=True
    TransientSoundVolume=95.000000
    TransientSoundRadius=500.000000
    FireSound=None
    FireRate=0.070000
    AmmoClass=Class'KFMod.FlameAmmo'
    ShakeRotMag=(X=0.000000,Y=0.000000,Z=0.000000)
    ShakeRotRate=(X=0.000000,Y=0.000000,Z=0.000000)
    ShakeOffsetMag=(X=0.000000,Y=0.000000,Z=0.000000)
    ShakeOffsetRate=(X=0.000000,Y=0.000000,Z=0.000000)
    ProjectileClass=Class'KFMod.FlameTendril'
    BotRefireRate=0.990000
    FlashEmitterClass=None
    aimerror=0.000000
    Spread=0.000000
    SpreadStyle=SS_Random
    bWaitForRelease=False
    ViewPunchDamping=4.000000
    ViewPunchSpring=50.000000
}
