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
<<<<<<< HEAD

// Shoot nades in mid-air
// Alex
simulated function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
	Explode(hitlocation,vect(0,0,1));
=======
var KFAvoidMarker Fear;

var bool bIncendiary, bHealing, bGas; // Is this an incendiary grenade?

var() class<Actor> IncendiaryGroundFireClass; // Ground fires >:)
var() int NumGroundFires; // How many ground fires to spawn

replication
{
    reliable if (Role == ROLE_Authority)
        bIncendiary, bHealing, bGas;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

// cut-n-paste to remove grenade smoke trail
simulated function PostBeginPlay()
{
<<<<<<< HEAD
	if ( Role == ROLE_Authority )
=======
	if (Role == ROLE_Authority)
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	{
		Velocity = Speed * Vector(Rotation);
		RandSpin(25000);
		bCanHitOwner = false;
		if (Instigator.HeadVolume.bWaterVolume)
		{
			bHitWater = true;
			Velocity = 0.6*Velocity;
		}
<<<<<<< HEAD
	}
}

=======
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

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated function Explode(vector HitLocation, vector HitNormal)
{
	local PlayerController  LocalPlayer;
	local Projectile P;
	local byte i;

	bHasExploded = True;

<<<<<<< HEAD

	BlowUp(HitLocation);
	

	// Incendiary Effects..

        if( KFHumanPawn(Instigator)!=None )
         {
          if(KFHumanPawn(Instigator).GetVeteran().Static.FlamingNades())
          {
           PlaySound(sound'KFWeaponSound.FlameThrowerFire',,100.5*TransientSoundVolume);

           if ( EffectIsRelevant(Location,false) )
	   {
		Spawn(Class'KFmod.KFIncendiaryExplosion',,, HitLocation, rotator(vect(0,0,1)));
		Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
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
		Spawn(Class'KFmod.KFNadeExplosion',,, HitLocation, rotator(vect(0,0,1)));
		Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
  	   }
  	  }

         }


	// Shake nearby players screens
	LocalPlayer = Level.GetLocalPlayerController();
	if ( (LocalPlayer != None) && (VSize(Location - LocalPlayer.ViewTarget.Location) < (DamageRadius * 1.5)) )
		LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);
	Destroy();
}

=======
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
		if ( EffectIsRelevant(Location,false) )
		{
			Spawn(Class'KFMod.KFNadeHealingExplosion',,, HitLocation, rotator(vect(0,0,1)));
		}
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
			Spawn(Class'KFmod.KFNadeExplosion',,, HitLocation, rotator(vect(0,0,1)));
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

    if ( IncendiaryGroundFireClass == None )
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
		//log("Spawned incendiary ground fire at " @ HitLoc @ " actor ref: " @ A);
    }
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType)
{
    // Don't allow hits on poeple on the same team
    if( Instigator.Controller.SameTeamAs(instigatedBy.Controller) && instigatedBy != Instigator && instigatedBy != None && Instigator != None )
        return;
    Explode(HitLocation, vect(0,0,0));
}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated function Destroyed()
{
	if ( Trail != None )
		Trail.mRegen = false; // stop the emitter from regenerating
<<<<<<< HEAD
=======
	if( !bHasExploded && !bHidden )
		Explode(Location,vect(0,0,1));
	if ( Fear != None )
		Fear.Destroy();
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	Super.Destroyed();
}

simulated function ProcessTouch( actor Other, vector HitLocation )
{
<<<<<<< HEAD
	// more realistic interactions with karma objects.
	if (Other.IsA('NetKActor'))
		KAddImpulse(Velocity,HitLocation,);
=======
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
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	// Stop the grenade in its tracks if it hits an enemy.
	if ( !Other.bWorldGeometry && (Other != Instigator || bCanHitOwner) )
		Velocity = Vect(0,0,0);
<<<<<<< HEAD
=======

}

simulated function HitWall( vector HitNormal, actor Wall )
{
	Super.HitWall(HitNormal, Wall);
	if( VSize(Velocity) < 20.0 && Fear == none )
	{
		Fear = Spawn(class'KFAvoidMarker');
		Fear.SetCollisionSize(DamageRadius,DamageRadius);
		Fear.StartleBots();
	}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

/* HurtRadius()
 Hurt locally authoritative actors within the radius.
*/
simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
	local actor Victims;
	local float damageScale, dist;
	local vector dir;

	if ( bHurtEntry )
		return;

	bHurtEntry = true;

	// It'll be slower, but let's see if this helps the grenades deal damage properly in a radius.
<<<<<<< HEAD
	foreach RadiusActors (class 'Actor', Victims, DamageRadius, HitLocation)
	{
		// don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
		if( (Victims != self) && (Hurtwall != Victims) && (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo')
		 && ExtendedZCollision(Victims)==None )
=======
	foreach VisibleCollidingActors (class 'Actor', Victims, DamageRadius, HitLocation)
	{
		// don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
		if( Victims !=None && Victims != self && Hurtwall != Victims && Victims.Role == ROLE_Authority && !Victims.IsA('FluidSurfaceInfo') && !Victims.IsA('ExtendedZCollision') )
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		{
			if( (Instigator==None || Instigator.Health<=0) && KFPawn(Victims)!=None )
				Continue;
			dir = Victims.Location - HitLocation;
			dist = FMax(1,VSize(dir));
			dir = dir/dist;
			damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
<<<<<<< HEAD


                       // Incendiary Effects..

                       if( KFHumanPawn(Instigator)!=None )
                       {
                         if(KFHumanPawn(Instigator).GetVeteran().Static.FlamingNades())
                          Victims.TakeDamage(damageScale * 60,Instigator,Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,(damageScale * Momentum * dir),Class'DamTypeFlamethrower');
                         else
                         {
                         if ( Instigator == None || Instigator.Controller == None )
				Victims.SetDelayedDamageInstigatorController( InstigatorController );
			Victims.TakeDamage(damageScale * DamageAmount,Instigator,
				Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,(damageScale * Momentum * dir),DamageType);
			if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
				Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);
                         }

                       
                       }



        	}
=======
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
				Victims.TakeDamage(damageScale * DamageAmount,Instigator,Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,(damageScale * Momentum * dir),DamageType);
				if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
					Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);
			}         
        }
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
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
<<<<<<< HEAD
	Speed=160.000000
	MaxSpeed=350.000000
	Damage=250.000000
	DamageRadius=350.000000
=======
	NumGroundFires=8
	Speed=160.000000
	MaxSpeed=850.000000
	Damage=300.000000
	DamageRadius=420.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	MomentumTransfer=150000.000000
	MyDamageType=Class'KFMod.DamTypeFrag'
	ExplosionDecal=Class'KFMod.KFScorchMark'
	StaticMesh=StaticMesh'KillingFloorStatics.FragProjectile'
	DrawScale=0.400000
	AmbientGlow=0
	bUnlit=False
	TransientSoundVolume=200.000000
<<<<<<< HEAD
=======
	bNetTemporary=False
	bNetNotify=true
	IncendiaryGroundFireClass=Class'KFMod.FuelFlameHurting'
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
