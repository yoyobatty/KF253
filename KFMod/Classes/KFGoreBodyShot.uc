//=============================================================================
// KFGoreBodyShot
// A body the Gore Cannon throws (GoreCannonFire): the specimen's own model, its class sent once (BodyClass), tumbling and
// bleeding through the air. What it strikes takes the whole weight of it, and it bursts there: everything round about
// is hurt and thrown (DamTypeGoreShot, more for a heavier body), a great burst of blood (KFBloodBlast), its giblets flung
// out (to be swallowed again) and the wall or floor painted. Players are never hurt by it.
//=============================================================================
class KFGoreBodyShot extends Projectile;

#exec OBJ LOAD FILE=PlayerSounds.uax

var class<KFMonster>	BodyClass;
var bool				bDressed, bBurst;
var xEmitter			Trail;

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		BodyClass;
}

// (the server) What it is
function Carry( class<KFMonster> B )
{
	BodyClass = B;
	Dress();
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	Velocity = vector(Rotation) * Speed + vect(0,0,120);
}

simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	if ( Role < ROLE_Authority )
		Dress();
}

// Drawn as its specimen, caught mid-flinch and tumbling, bleeding as it goes
simulated function Dress()
{
	local int i;

	if ( bDressed || BodyClass == None )
		return;
	bDressed = true;
	SetCollisionSize(0.6 * BodyClass.default.CollisionRadius, 0.5 * BodyClass.default.CollisionHeight);
	if ( Level.NetMode == NM_DedicatedServer )
		return;
	LinkMesh(BodyClass.default.Mesh);
	Skins.Length = BodyClass.default.Skins.Length;
	for ( i = 0; i < Skins.Length; i++ )
		Skins[i] = BodyClass.default.Skins[i];
	SetDrawScale(BodyClass.default.DrawScale);
	PrePivot = BodyClass.default.PrePivot;
	SetDrawType(DT_Mesh);
	PlayAnim(BodyClass.default.HitAnims[Rand(3)], 0.0, 0.0);
	SetAnimFrame(0.45);
	RotationRate.Pitch = 40000 + Rand(30000);
	RotationRate.Yaw = Rand(40000) - 20000;
	RotationRate.Roll = Rand(60000) - 30000;
	Trail = Spawn(class'KFGibJet', self,, Location, Rotation);
	if ( Trail != None )
	{
		Trail.SetPhysics(PHYS_Trailer);
		Trail.LifeSpan = 4.0;
	}
}

simulated function ProcessTouch( Actor Other, vector HitLocation )
{
	if ( bBurst || Other == Instigator || Other == Owner || KFGoreBodyShot(Other) != None || KFGoreGibShot(Other) != None )
		return;
	if ( ExtendedZCollision(Other) != None && Other.Owner != None )
		Other = Other.Owner;
	if ( Pawn(Other) != None && KFMonster(Other) == None )
		return;
	Burst(HitLocation, Normal(HitLocation - Other.Location), Pawn(Other));
}

simulated function HitWall( vector HitNormal, Actor Wall )
{
	Burst(Location, HitNormal, None);
}

simulated function Landed( vector HitNormal )
{
	Burst(Location, HitNormal, None);
}

// It bursts: the one it struck takes the whole of it, everything round about is hurt and thrown
simulated function Burst( vector At, vector Facing, Pawn Struck )
{
	local KFMonster M;
	local array<KFMonster> Near;
	local float Heft, D, Reach;
	local int i;
	local vector V;
	local class<KFMonster> B;

	if ( bBurst )
		return;
	bBurst = true;
	B = BodyClass;
	if ( B == None )
		B = class'KFMonster';
	Heft = B.default.Mass;
	Reach = 200.0 + 0.12 * Heft;
	if ( Role == ROLE_Authority )
	{
		if ( KFMonster(Struck) != None && Struck.Health > 0 )
			Struck.TakeDamage(int(250.0 + 0.6 * Heft), Instigator, At, Velocity * 30.0, class'DamTypeGoreShot');
		foreach VisibleCollidingActors(class'KFMonster', M, Reach, At)
			if ( M != Struck && !M.bDeleteMe )
				Near[Near.Length] = M;
		for ( i = 0; i < Near.Length; i++ )
		{
			M = Near[i];
			if ( M == None || M.bDeleteMe )
				continue;
			V = M.Location - At;
			D = VSize(V);
			M.TakeDamage(int((150.0 + 0.3 * Heft) * (1.0 - 0.6 * D / Reach)), Instigator, M.Location - Normal(V) * M.CollisionRadius,
				Normal(V + vect(0,0,60)) * 50000.0, class'DamTypeGoreShot');
		}
	}
	if ( Level.NetMode != NM_DedicatedServer )
		Splatter(At, Facing, B);
	Destroy();
}

// (each machine that draws it) The blood, the giblets flung out, the stain, the sound
simulated function Splatter( vector At, vector Facing, class<KFMonster> B )
{
	local float S;

	S = FClamp(B.default.Mass / 300.0, 0.8, 2.2);
	class'KFBloodBlast'.static.Make(self, At + Facing * 10.0, S, Facing);
	Fling(B.default.MonsterTorsoGiblet, At, Facing);
	Fling(B.default.MonsterLowerTorsoGiblet, At, Facing);
	Fling(B.default.MonsterHeadGiblet, At, Facing);
	Fling(B.default.MonsterArmGiblet, At, Facing);
	Fling(B.default.MonsterArmGiblet, At, Facing);
	Fling(B.default.MonsterThighGiblet, At, Facing);
	Fling(B.default.MonsterLegGiblet, At, Facing);
	Fling(B.default.MonsterLegGiblet, At, Facing);
	Spawn(class'KFBloodSplatterBig',,, At + Facing * 20.0, rotator(-Facing));
	PlaySound(Sound'PlayerSounds.NewGibs.NewGib4', SLOT_None, class'KFBloodBlast'.static.GoreVol(2.5),, class'KFBloodBlast'.static.GoreRadius(2.5, 2000), 0.9);
}

simulated function Fling( class<Gib> GC, vector At, vector Facing )
{
	local Gib G;

	if ( GC == None || class'GameInfo'.static.UseLowGore() )
		return;
	G = Spawn(GC,,, At + Facing * 12.0 + VRand() * 8.0, RotRand());
	if ( G == None )
		return;
	G.Velocity = Facing * (150.0 + 250.0 * FRand()) + VRand() * 350.0 + vect(0,0,280);
	G.SpawnTrail();
}

simulated function Destroyed()
{
	if ( Trail != None )
		Trail.mRegen = false;
	Super.Destroyed();
}

defaultproperties
{
     Speed=2200.000000
     MaxSpeed=2600.000000
     MyDamageType=Class'KFMod.DamTypeGoreShot'
     Physics=PHYS_Falling
     DrawType=DT_None
     bBounce=False
     RemoteRole=ROLE_SimulatedProxy
     bNetTemporary=True
     bReplicateInstigator=True
     bFixedRotationDir=True
     LifeSpan=6.000000
     CollisionRadius=16.000000
     CollisionHeight=18.000000
     bUnlit=False
     AmbientGlow=10
}
