//=============================================================================
// KFGoreGibShot
// A giblet of the Gore Cannon's meat round (GoreCannonFire): tumbling and bleeding as it flies; a specimen it strikes is
// hurt (DamTypeGibShot) and splashed, and where it lands it lies as a giblet again, to be swallowed again.
//=============================================================================
class KFGoreGibShot extends Projectile;

var byte		Kind;		// which of a clot's giblets it is (sent once)
var bool		bDressed, bDone;
var xEmitter	Trail;
var() int		HitDamage;

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		Kind;
}

simulated function class<KFGib> GibClass()
{
	switch ( Kind % 6 )
	{
		case 0:	return class'ClotGibArm';
		case 1:	return class'ClotGibLeg';
		case 2:	return class'ClotGibThigh';
		case 3:	return class'ClotGibTorso';
		case 4:	return class'ClotGibLowerTorso';
	}
	return class'KFGibBrain';
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	Velocity = vector(Rotation) * Speed * (0.85 + 0.3 * FRand()) + vect(0,0,80);
	if ( Role == ROLE_Authority )
		Kind = Rand(6);
	Dress();
}

simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	if ( Role < ROLE_Authority )
	{
		bDressed = false;
		Dress();
	}
}

simulated function Dress()
{
	local class<KFGib> GC;

	if ( bDressed || Level.NetMode == NM_DedicatedServer )
		return;
	bDressed = true;
	GC = GibClass();
	SetStaticMesh(GC.default.StaticMesh);
	if ( GC.default.Skins.Length > 0 )
		Skins[0] = GC.default.Skins[0];
	SetDrawScale(GC.default.DrawScale * 1.2);
	SetDrawType(DT_StaticMesh);
	RotationRate.Pitch = Rand(120000) - 60000;
	RotationRate.Yaw = Rand(120000) - 60000;
	RotationRate.Roll = Rand(120000) - 60000;
	if ( FRand() < 0.6 )
	{
		Trail = Spawn(class'KFGibJet', self,, Location, Rotation);
		if ( Trail != None )
		{
			Trail.SetPhysics(PHYS_Trailer);
			Trail.LifeSpan = 1.5;
		}
	}
}

simulated function ProcessTouch( Actor Other, vector HitLocation )
{
	if ( bDone || Other == Instigator || Other == Owner || KFGoreGibShot(Other) != None || KFGoreBodyShot(Other) != None )
		return;
	if ( ExtendedZCollision(Other) != None && Other.Owner != None )
		Other = Other.Owner;
	if ( KFMonster(Other) == None )
		return;
	bDone = true;
	if ( Role == ROLE_Authority )
		Other.TakeDamage(HitDamage, Instigator, HitLocation, Velocity * 20.0, class'DamTypeGibShot');
	if ( Level.NetMode != NM_DedicatedServer )
		class'KFBloodBlast'.static.Make(self, HitLocation, 0.3, Normal(Velocity));
	Destroy();
}

simulated function HitWall( vector HitNormal, Actor Wall )
{
	Lay(HitNormal);
}

simulated function Landed( vector HitNormal )
{
	Lay(HitNormal);
}

// Where it lands it lies as a giblet again, with a splash of blood
simulated function Lay( vector HitNormal )
{
	local KFGib G;

	if ( bDone )
		return;
	bDone = true;
	if ( Level.NetMode != NM_DedicatedServer )
	{
		Spawn(class'KFBloodSplat',,, Location + HitNormal * 20.0, rotator(-HitNormal));
		G = Spawn(GibClass(),,, Location + HitNormal * 6.0, Rotation);
		if ( G != None )
		{
			G.Velocity = (Velocity - 2.0 * (Velocity dot HitNormal) * HitNormal) * 0.25;
			G.SpawnTrail();
		}
	}
	Destroy();
}

simulated function Destroyed()
{
	if ( Trail != None )
		Trail.mRegen = false;
	Super.Destroyed();
}

defaultproperties
{
     HitDamage=80
     Speed=2000.000000
     MaxSpeed=2400.000000
     MyDamageType=Class'KFMod.DamTypeGibShot'
     Physics=PHYS_Falling
     DrawType=DT_None
     RemoteRole=ROLE_SimulatedProxy
     bNetTemporary=True
     bReplicateInstigator=True
     bFixedRotationDir=True
     LifeSpan=5.000000
     CollisionRadius=6.000000
     CollisionHeight=6.000000
     bUnlit=False
}
