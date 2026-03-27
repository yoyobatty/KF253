//=============================================================================
// Shotgun Bullet
//=============================================================================
class ShotgunBulletFire  extends ShotgunBullet;

simulated function PostBeginPlay()
{

	Super(Projectile).PostBeginPlay();

	Velocity = Speed * Vector(Rotation); // starts off slower so combo can be done closer

    SetTimer(0.4, false);

    if ( Level.NetMode != NM_DedicatedServer )
    {
        if ( !PhysicsVolume.bWaterVolume )
        {
            //Trail = Spawn(class'KFTracer',self);
            //Trail.Lifespan = Lifespan;
            Trail = Spawn(class'FlameThrowerFlame',self);
        }
    }
}
/* 
simulated function Explode(vector HitLocation,vector HitNormal)
{
   	PlaySound(ImpactSound, SLOT_Misc);
	if (KFHumanPawn(Instigator) != none)
	{
		if ( EffectIsRelevant(Location,false) )
		{
			//Spawn(ExplosionDecal,,, Location);
			//Spawn(class'FlameThrowerFlameB',Instigator,,Location);
            Spawn(class'ShotgunFlame',,,HitLocation,rotator(HitNormal));
		}
	}
	SetCollisionSize(0.0, 0.0);
    BlowUp(HitLocation);
	Destroy();
}
*/
simulated singular function HitWall(vector HitNormal, actor Wall)
{
	local PlayerController PC;

	 if(Level.NetMode != NM_DedicatedServer)
     {
		Spawn(class'KFHitEffect',,,Location,rotator(-HitNormal));
        Spawn(class'ShotgunFlame');
        Spawn(class'InvisBullet',,, Location);
     }
    if ( Role == ROLE_Authority )
	{
		if ( !Wall.bStatic && !Wall.bWorldGeometry )
		{
			if ( Instigator == None || Instigator.Controller == None )
				Wall.SetDelayedDamageInstigatorController( InstigatorController );
			Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);
			if (DamageRadius > 0 && Vehicle(Wall) != None && Vehicle(Wall).Health > 0)
				Vehicle(Wall).DriverRadiusDamage(Damage, DamageRadius, InstigatorController, MyDamageType, MomentumTransfer, Location);
			HurtWall = Wall;
		}
		MakeNoise(1.0);
	}
	Explode(Location + ExploWallOut * HitNormal, HitNormal);
	if ( (ExplosionDecal != None) && (Level.NetMode != NM_DedicatedServer)  )
	{
		if ( ExplosionDecal.Default.CullDistance != 0 )
		{
			PC = Level.GetLocalPlayerController();
			if ( !PC.BeyondViewDistance(Location, ExplosionDecal.Default.CullDistance) )
				Spawn(ExplosionDecal,self,,Location, rotator(-HitNormal));
			else if ( (Instigator != None) && (PC == Instigator.Controller) && !PC.BeyondViewDistance(Location, 2*ExplosionDecal.Default.CullDistance) )
				Spawn(ExplosionDecal,self,,Location, rotator(-HitNormal));
		}
		else
			//Spawn(class'ShotgunWallHitEffect',self,,Location, rotator(-HitNormal));
            Spawn(class'InvisBullet',,, Location);
	}
	HurtWall = None;


    if (Trail != None)
    {
        Trail.mRegen=False;
        Trail.SetPhysics(PHYS_None);
        //Trail.mRegenRange[0] = 0.0;//trail.mRegenRange[0] * 0.6;
        //Trail.mRegenRange[1] = 0.0;//trail.mRegenRange[1] * 0.6;
    }
}

simulated function Timer()
{
	Velocity =  Default.Speed * Normal(Velocity);

	if (Trail != none)
	{
		Trail.mSizeRange[0] *= 1.5;
		Trail.mSizeRange[1] *= 1.5;
	}
}

simulated function Destroyed()
{
	if ( Trail != none )
	{
		Trail.mRegen=False;
		Trail.SetPhysics(PHYS_None);
		Trail.GotoState('');
	}
    Super.Destroyed();
}

defaultproperties
{
     Speed=3500.000000
     MaxSpeed=4000.000000
     Damage=19.000000
     DamageRadius=5.000000
     MyDamageType=Class'KFMod.DamTypeShotgunFire'
}
