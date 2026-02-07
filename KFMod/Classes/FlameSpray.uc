//=============================================================================
// Flame
//=============================================================================
class FlameSpray extends FlameTendril;


simulated function Explode(vector HitLocation,vector HitNormal)
{

    if ( Role == ROLE_Authority )
    {
        HurtRadius(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
    }

   	//PlaySound(ImpactSound, SLOT_Misc);
	if ( EffectIsRelevant(Location,false) )
	{
	    Spawn(ExplosionDecal,,, Location);

	    //Spawn(class'Exp',,, Location, Rotation);
	    //Spawn(class'InvisBullet',,, Location);


	}
    SetCollisionSize(0.0, 0.0);
	Destroy();
}


simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	Velocity = Speed * Vector(Rotation); // starts off slower so combo can be done closer

    SetTimer(0.4, false);
<<<<<<< HEAD
    tempStartLoc = Location;
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

    /*

    if ( Level.NetMode != NM_DedicatedServer )
    {
        if ( !PhysicsVolume.bWaterVolume )
        {

            //Trail = Spawn(class'KFMonsterFlame',self);
            Trail.Lifespan = Lifespan;
        }

    }
    */
}

defaultproperties
{
<<<<<<< HEAD
	Speed=1500.000000
	MaxSpeed=2000.000000
	Damage=10.000000
	DamageRadius=50.000000
=======
     Speed=1500.000000
     MaxSpeed=2000.000000
     Damage=10.000000
     DamageRadius=50.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
