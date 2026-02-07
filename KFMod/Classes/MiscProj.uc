class MiscProj extends Projectile;

var ONSBluePlasmaFireEffect ShockBallEffect;
var float DamageAtten;
var sound ImpactSounds[6];

<<<<<<< HEAD

var Vector tempStartLoc;

=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated event PreBeginPlay()
{
    Super.PreBeginPlay();

    if( Pawn(Owner) != None )
        Instigator = Pawn( Owner );
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
}

simulated function PostNetBeginPlay()
{
	local PlayerController PC;

	Super.PostNetBeginPlay();

	if ( Level.NetMode == NM_DedicatedServer )
		return;

	PC = Level.GetLocalPlayerController();
	if ( (Instigator != None) && (PC == Instigator.Controller) )
		return;
	if ( Level.bDropDetail || (Level.DetailMode == DM_Low) )
	{
		bDynamicLight = false;
		LightType = LT_None;
	}
	else if ( (PC == None) || (PC.ViewTarget == None) || (VSize(PC.ViewTarget.Location - Location) > 3000) )
	{
		bDynamicLight = false;
		LightType = LT_None;
	}
}

function Timer()
{
    SetCollisionSize(20, 20);
}

simulated function Destroyed()
{
    if (ShockBallEffect != None)
    {
		if ( bNoFX )
			ShockBallEffect.Destroy();
		else
			ShockBallEffect.Kill();
	}

	Super.Destroyed();
}

simulated function DestroyTrails()
{

}

simulated function Explode(vector HitLocation,vector HitNormal)
{
    if ( Role == ROLE_Authority )
    {
        HurtRadius(Damage, DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
    }

   	PlaySound(ImpactSound, SLOT_Misc);
	if ( EffectIsRelevant(Location,false) )
	{
	    Spawn(class'KFHitEffect',,, Location);
	    //Spawn(class'Exp',,, Location, Rotation);
	    Spawn(class'InvisBullet',,, Location);


	}
    SetCollisionSize(0.0, 0.0);
	Destroy();
}
simulated singular function HitWall(vector HitNormal, actor Wall)
{
	local PlayerController PC;

	 if(Level.NetMode != NM_DedicatedServer)
        Spawn(class'KFHitEffect');
        Spawn(class'InvisBullet',,, Location);
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
}

defaultproperties
{
<<<<<<< HEAD
	DamageAtten=5.000000
	Speed=10000.000000
	MaxSpeed=10100.000000
	bSwitchToZeroCollision=True
	Damage=20.000000
	DamageRadius=12.000000
	MomentumTransfer=40000.000000
	MyDamageType=Class'KFMod.DamTypeShotgun'
	ExplosionDecal=Class'KFMod.ShotgunDecal'
	DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'WeaponStaticMesh.FlakChunk'
	CullDistance=3000.000000
	LifeSpan=0.034000
	DrawScale=14.000000
	Style=STY_Alpha
=======
     DamageAtten=5.000000
     Speed=10000.000000
     MaxSpeed=10100.000000
     bSwitchToZeroCollision=True
     Damage=20.000000
     DamageRadius=12.000000
     MomentumTransfer=40000.000000
     MyDamageType=Class'KFMod.DamTypeShotgun'
     ExplosionDecal=Class'KFMod.ShotgunDecal'
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'WeaponStaticMesh.FlakChunk'
     CullDistance=3000.000000
     LifeSpan=0.034000
     DrawScale=14.000000
     Style=STY_Alpha
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
