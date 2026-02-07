//=============================================================================
// Contact explosive nades, also sets enemies on fire
//=============================================================================
class NadeContact extends Nade;

simulated function ProcessTouch( actor Other, vector HitLocation )
{
	// more realistic interactions with karma objects.
	if (Other.IsA('NetKActor'))
		KAddImpulse(Velocity,HitLocation,);

	// Blow up when we hit an enemy that isn't one of our friends
	if ( !Other.bWorldGeometry && (Other != Instigator || bCanHitOwner) && KFPawn(Other) == None )
	{
		//Velocity = Vect(0,0,0);
		Explode(HitLocation, vect(0,0,1));
	}
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
	local PlayerController  LocalPlayer;
	local Projectile P;
	local byte i;

	bHasExploded = True;

	BlowUp(HitLocation);

	// Incendiary Effects..

    if( KFHumanPawn(Instigator)!=None )
    {

        PlaySound(sound'KFWeaponSound.Bang1',,100.5*TransientSoundVolume);

        // Shrapnel only spawns on normal grenade type, not incendiary.
	
	    for( i=Rand(6); i<6; i++ )
	    {
			P = Spawn(ShrapnelClass,,,,RotRand(True));
			if( P!=None )
				P.RemoteRole = ROLE_None;
	    }

        if ( EffectIsRelevant(Location,false) )
	  	{
			Spawn(Class'KFmod.KFNadeExplosionSmall',,, HitLocation, rotator(vect(0,0,1)));
			Spawn(ExplosionDecal,self,,HitLocation, rotator(-HitNormal));
  	   	}
  	  	

    }
	// Shake nearby players screens
	LocalPlayer = Level.GetLocalPlayerController();
	if ( (LocalPlayer != None) && (VSize(Location - LocalPlayer.ViewTarget.Location) < (DamageRadius * 1.5)) )
		LocalPlayer.ShakeView(RotMag, RotRate, RotTime, OffsetMag, OffsetRate, OffsetTime);
	Destroy();
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
	foreach CollidingActors (class 'Actor', Victims, DamageRadius, HitLocation)
	{
		// don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
		if( (Victims != self) && (Hurtwall != Victims) && (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo') && ExtendedZCollision(Victims)==None )
		{
			if( (Instigator==None || Instigator.Health<=0) && KFPawn(Victims)!=None )
				Continue;
			dir = Victims.Location - HitLocation;
			dist = FMax(1,VSize(dir));
			dir = dir/dist;
			damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
            // Incendiary Effects..
            if( KFHumanPawn(Instigator)!=None )
            {

                if ( Instigator == None || Instigator.Controller == None )
					Victims.SetDelayedDamageInstigatorController( InstigatorController );
				Victims.TakeDamage(damageScale * DamageAmount,Instigator,Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,(damageScale * Momentum * dir),DamageType);
				Victims.TakeDamage(damageScale * 25,Instigator,Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,(damageScale * Momentum * dir),Class'DamTypeFlamethrower');
				if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
					Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);
                       
            }
        }
	}
	bHurtEntry = false;
}

defaultproperties
{
     Speed=2800.000000
     MaxSpeed=3500.000000
     Damage=80.000000
     DamageRadius=210.000000
     DrawScale=0.200000
}
