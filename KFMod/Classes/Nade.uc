//=============================================================================
// Nade
//=============================================================================
class Nade extends Grenade;

var() vector RotMag;            // how far to rot view
var() vector RotRate;           // how fast to rot view
var() float  RotTime;           // how much time to rot the instigator's view
var() vector OffsetMag;         // max view offset vertically
var() vector OffsetRate;        // how fast to offset view vertically
var() float  OffsetTime;        // how much time to offset view
var() class<Projectile> ShrapnelClass;
var bool bHasExploded;
var KFAvoidMarker Fear;

var bool bIncendiary, bHealing, bGas; // Is this an incendiary grenade?

var() class<Actor> IncendiaryGroundFireClass; // Ground fires >:)
var() int NumGroundFires; // How many ground fires to spawn

var() float CoreDamage;       // more damage close in, falling to none at CoreRadius: a frag at a specimen's feet kills it
var() float CoreRadius;
var() int   CoreBigHealth;    // specimens with this much default health or more (Scrake, Fleshpound, Patriarch) take only the outer blast
var() bool  bZedsFear;        // specimens steer around a frag lying still, as bots do
var() bool  bFragCover;       // the fragments go by lines to the top, middle and bottom of each body: cover stops them
var() bool  bBodyShield;      // and so do other bodies and props on the way (off: it took too much from a grenade in a crowd)
var() float StaggerRadius;    // a specimen left standing this close stumbles (KFMonster.BlastStagger); the big ones do not

replication
{
    reliable if (Role == ROLE_Authority)
        bIncendiary, bHealing, bGas;
}

// cut-n-paste to remove grenade smoke trail
simulated function PostBeginPlay()
{
	if (Role == ROLE_Authority)
	{
		Velocity = Speed * Vector(Rotation);
		RandSpin(25000);
		bCanHitOwner = false;
		if (Instigator.HeadVolume.bWaterVolume)
		{
			bHitWater = true;
			Velocity = 0.6*Velocity;
		}
		if(KFHumanPawn(Instigator)!=None && KFHumanPawn(Instigator).GetVeteran().Static.FlamingNades())
			bIncendiary = true;
		else if(KFHumanPawn(Instigator)!=None && KFHumanPawn(Instigator).GetVeteran().Static.HealingNades())
			bHealing = true;
		//else if(KFHumanPawn(Instigator)!=None && KFHumanPawn(Instigator).GetVeteran() == class'KFVetSupportSpec')
		//	bGas = true;
	}
}

simulated function PostNetBeginPlay()
{
	SetTimer(ExplodeTimer, false);
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
	local PlayerController  LocalPlayer;
	local Projectile P;
	local Actor FX;
	local byte i;

	bHasExploded = True;

	BlowUp(HitLocation);

	if(bIncendiary)
	{
		PlaySound(sound'KFWeaponSound.FlameThrowerFire',,100.5*TransientSoundVolume);
		if ( EffectIsRelevant(Location,false) )
		{
			Spawn(Class'KFmod.KFIncendiaryExplosion',,, HitLocation, rotator(vect(0,0,1)));
			Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
		}
		SpawnIncendiaryGroundFires(HitLocation);
		//log("Nade: Spawned incendiary ground fires.");

	}
	else if(bHealing)
	{
		PlaySound(sound'KFWeaponSound.FlameThrowerFire',,80.5*TransientSoundVolume);
		if ( Role == ROLE_Authority )
			Spawn(Class'KFMod.KFNadeHealingExplosion',,, HitLocation, rotator(vect(0,0,1)));
	}
	else if(bGas)
	{
		if ( EffectIsRelevant(Location,false) )
		{
			Spawn(Class'KFMod.KFGasEmitter',,, HitLocation, rotator(vect(0,0,1)));
		}
	}
	else
	{
		PlaySound(sound'KFWeaponSound.Bang1',,100.5*TransientSoundVolume);

		// Shrapnel only spawns on normal grenade type, not incendiary.

		for( i=Rand(6); i<10; i++ )
		{
			P = Spawn(ShrapnelClass,,,,RotRand(True));
			if( P!=None )
				P.RemoteRole = ROLE_None;
		}

		if ( EffectIsRelevant(Location,false) )
		{
			FX = Spawn(Class'KFmod.KFNadeExplosion',,, HitLocation);
			if( FX!=None )
				FX.RemoteRole = ROLE_None;
			Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
		}
		// Shake nearby players screens
		LocalPlayer = Level.GetLocalPlayerController();
		if ( (LocalPlayer != None) && (VSize(Location - LocalPlayer.ViewTarget.Location) < (DamageRadius * 1.5)) )
			LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);
	}
	Destroy();
}

simulated function SpawnIncendiaryGroundFires(vector BlastLoc)
{
    local int i;
    local float Angle, StepAngle, Dist;
    local vector Dir, TestLoc, TraceStart, TraceEnd, HitLoc, HitNorm;
    local Actor A;

    if ( IncendiaryGroundFireClass == None || Role < ROLE_Authority )
        return;

    StepAngle = 2 * Pi / NumGroundFires;

    for ( i = 0; i < NumGroundFires; i++ )
    {
        Angle = (StepAngle * i) + (FRand() - 0.5) * (StepAngle * 0.4);
		Dist = RandRange(50.0, 150.0);

        Dir   = vect(1,0,0) * Cos(Angle) + vect(0,1,0) * Sin(Angle);
        TestLoc = BlastLoc + Dir * Dist;

        TraceStart = TestLoc + vect(0,0,128);
        TraceEnd   = TestLoc - vect(0,0,512);
        HitLoc = TestLoc;
        HitNorm = vect(0,0,1);

        if ( Trace(HitLoc, HitNorm, TraceEnd, TraceStart, true) == None )
        {
            HitLoc = TestLoc;
            HitNorm = vect(0,0,1);
        }

        HitLoc.Z += 5.0;

        A = Spawn(IncendiaryGroundFireClass,Instigator,, HitLoc,
                  rotator( HitNorm));
        if ( A != None )
            A.RemoteRole = ROLE_SimulatedProxy;
		//log("Spawned incendiary ground fire at " @ HitLoc @ " actor ref: " @ A);
    }
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
    // Don't allow hits on poeple on the same team
    // (thrower and shooter tested before they are used: either may be gone)
    if( Instigator != None && instigatedBy != None && instigatedBy != Instigator && Instigator.Controller != None
     && Instigator.Controller.SameTeamAs(instigatedBy.Controller) )
        return;
    Explode(HitLocation, vect(0,0,0));
}

simulated function Destroyed()
{
	if ( Trail != None )
		Trail.mRegen = false; // stop the emitter from regenerating
	if( !bHasExploded && !bHidden )
		Explode(Location,vect(0,0,1));
	if ( Fear != None )
		Fear.Destroy();
	Super.Destroyed();
}

// Touching a body does it no harm. Stock would have a client's own bodies take the full Damage.
simulated function ClientSideTouch(Actor Other, Vector HitLocation);

simulated function ProcessTouch( actor Other, vector HitLocation )
{
    // Don't allow hits on poeple on the same team
    if ( KFHumanPawn(Other) != None )
        return;

    if ( KFGlassMover(Other) != None )
    {
        if( Level.NetMode!=NM_Client )
            Other.TakeDamage(Damage, Instigator, HitLocation, vect(0,0,0), MyDamageType);
        return;
    }

	// more realistic interactions with karma objects.
	if (Other.IsA('NetKActor'))
		KAddImpulse(Velocity,HitLocation);

	// Stop the grenade in its tracks if it hits an enemy.
	if ( !Other.bWorldGeometry && (Other != Instigator || bCanHitOwner) )
		Velocity = Vect(0,0,0);

}

simulated function HitWall( vector HitNormal, actor Wall )
{
	Super.HitWall(HitNormal, Wall);
	if( VSize(Velocity) < 20.0 )
	{
		Fear = Spawn(class'KFAvoidMarker', self);
		Fear.SetCollisionSize(DamageRadius,DamageRadius);
		Fear.StartleBots();
	}
}

// The close-in part of the blast a specimen takes; people and the big ones take none
simulated final function float CoreBlast( Actor Victim, float Dist )
{
	if ( KFMonster(Victim) == None || CoreRadius <= 0 || class<KFMonster>(Victim.Class).default.Health >= CoreBigHealth )
		return 0;
	return CoreDamage * FMax(0, 1 - FMax(0, Dist - Victim.CollisionRadius)/CoreRadius);
}

// The share of a body the fragments reach: lines from just over the blast to its top, middle and bottom (0.4, 0.3, 0.3),
// each stopped by cover and, with bBodyShield, by another body or prop on the way, though not by one standing over the
// blast (they fly out under and around it). Walls gets the share no cover stops, for the blast itself.
simulated final function float FragReach( Actor Victim, vector HitLocation, out float Walls )
{
	local vector From, Spot, HL, HN, D;
	local Actor A;
	local float W, Reach;
	local int i;
	local bool bStopped;

	From = HitLocation + vect(0,0,15);
	Walls = 0;
	for ( i = 0; i < 3; i++ )
	{
		Spot = Victim.Location;
		W = 0.3;
		if ( i == 0 )
		{
			Spot.Z += 0.8 * Victim.CollisionHeight;
			W = 0.4;
		}
		else if ( i == 2 )
			Spot.Z -= 0.8 * Victim.CollisionHeight;
		if ( !FastTrace(Spot, From) )
			continue;
		Walls += W;
		bStopped = false;
		if ( bBodyShield )
		{
			foreach TraceActors(class'Actor', A, HL, HN, Spot, From)
			{
				if ( A == Victim || (ExtendedZCollision(A) != None && A.Owner == Victim) )
					break;
				if ( Pawn(A) == None && ExtendedZCollision(A) == None && KActor(A) == None )
					continue;
				D = From - A.Location;
				D.Z = 0;
				if ( VSize(D) <= A.CollisionRadius && Abs(From.Z - A.Location.Z) <= A.CollisionHeight )
					continue;
				bStopped = true;
				break;
			}
		}
		if ( !bStopped )
			Reach += W;
	}
	return Reach;
}

/* HurtRadius()
 Hurt locally authoritative actors within the radius.
*/
simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
	local actor Victims;
	local float damageScale, dist, Reach, Walls;
	local vector dir;
	local bool bOnFeet;

	if ( bHurtEntry )
		return;

	bHurtEntry = true;

	// Each actor in reach whose middle the blast point sees; with bFragCover each body by the lines FragReach draws, so one
	// whose middle is hidden can still be caught at its head or feet
	foreach CollidingActors (class 'Actor', Victims, DamageRadius, HitLocation)
	{
		// don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
		if( Victims !=None && Victims != self && Hurtwall != Victims && Victims.Role == ROLE_Authority && !Victims.IsA('FluidSurfaceInfo') && !Victims.IsA('ExtendedZCollision') )
		{
			if( (Instigator==None || Instigator.Health<=0) && KFPawn(Victims)!=None )
				Continue;
			Reach = 1;
			Walls = 1;
			if ( bFragCover && Pawn(Victims) != None && !bIncendiary && !bHealing )
				Reach = FragReach(Victims, HitLocation, Walls);
			else if ( !FastTrace(Victims.Location, HitLocation) )
				Walls = 0;
			if ( Walls <= 0 )
				Continue;
			dir = Victims.Location - HitLocation;
			dist = FMax(1,VSize(dir));
			dir = dir/dist;
			damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
            // Incendiary Effects..
			if(bIncendiary)
				Victims.TakeDamage(damageScale * 80,Instigator,Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,Vect(0,0,0),Class'DamTypeFlamethrower');
			else if(bHealing)
			{
				if(!Victims.IsA('KFHumanPawn'))
					Victims.TakeDamage(damageScale * 100,Instigator,Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,Vect(0,0,0),Class'DamTypeMedicNade');
				else KFHumanPawn(Victims).GiveHealth(50, KFHumanPawn(Victims).HealthMax);
			}
			else
			{
				if ( Instigator == None || Instigator.Controller == None )
					Victims.SetDelayedDamageInstigatorController( InstigatorController );
				bOnFeet = Victims.Physics == PHYS_Walking;
				Victims.TakeDamage(damageScale * DamageAmount * Reach + CoreBlast(Victims, dist) * Walls,Instigator,Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,(damageScale * Walls * Momentum * dir),DamageType);
				// what it leaves on its feet near it stumbles (one the hit knocked over stays down: FlipOver)
				if ( bOnFeet && KFMonster(Victims) != None && KFMonster(Victims).Health > 0 && dist - Victims.CollisionRadius <= StaggerRadius
				 && class<KFMonster>(Victims.Class).default.Health < CoreBigHealth )
					KFMonster(Victims).BlastStagger(HitLocation);
				if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
					Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);
			}         
        }
	}
	bHurtEntry = false;
}

defaultproperties
{
	RotMag=(X=100.000000,Y=100.000000,Z=100.000000)
	RotRate=(X=500.000000,Y=500.000000,Z=500.000000)
	RotTime=3.000000
	OffsetMag=(X=40.000000,Y=40.000000,Z=40.000000)
	OffsetRate=(X=500.000000,Y=500.000000,Z=500.000000)
	OffsetTime=3.000000
	ShrapnelClass=Class'KFMod.KFShrapnel'
	DampenFactor=0.250000
	DampenFactorParallel=0.400000
	HitEffectClass=None
	NumGroundFires=8
	Speed=160.000000
	MaxSpeed=850.000000
	Damage=400.000000
	DamageRadius=420.000000
	MomentumTransfer=150000.000000
	MyDamageType=Class'KFMod.DamTypeFrag'
	ExplosionDecal=Class'KFMod.KFScorchMark'
	StaticMesh=StaticMesh'KillingFloorStatics.FragProjectile'
	DrawScale=0.400000
	AmbientGlow=0
	bUnlit=False
	TransientSoundVolume=200.000000
	bNetTemporary=False
	bNetNotify=true
	IncendiaryGroundFireClass=Class'KFMod.KFNadeFire'
	CoreDamage=300.000000
	CoreRadius=160.000000
	CoreBigHealth=1000
	bFragCover=True
	StaggerRadius=250.000000
}
