class CrossbowArrow extends Projectile;

var xEmitter Trail;
var() class<DamageType> DamageTypeHeadShot;
var sound Arrow_hitwall[3];
var sound Arrow_rico[2];
var sound Arrow_hitarmor;
var sound Arrow_hitflesh;

var() float HeadShotDamageMult;

var Actor ImpactActor;
var Pawn IgnoreImpactPawn;

replication
{
	reliable if ( Role==ROLE_Authority && bNetInitial )
		ImpactActor;
}

simulated function PostNetBeginPlay()
{
	if( Level.NetMode!=NM_DedicatedServer && (Level.NetMode!=NM_Client || Physics==PHYS_Projectile) )
	{
		if ( !PhysicsVolume.bWaterVolume )
		{
			Trail = Spawn(class'KFArrowTracer',self);
			Trail.Lifespan = Lifespan;
		}
	}
	else if( Level.NetMode==NM_Client )
	{
		if( ImpactActor!=None )
			SetBase(ImpactActor);
		GoToState('OnWall');
	}
}
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	Velocity = Speed * Vector(Rotation);
	if( PhysicsVolume.bWaterVolume )
		Velocity*=0.65;
}

simulated state OnWall
{
Ignores HitWall;

	function ProcessTouch (Actor Other, vector HitLocation)
	{
		local Inventory inv;

		if( Pawn(Other)!=None && Pawn(Other).Inventory!=None )
		{
			for( inv=Pawn(Other).Inventory; inv!=None; inv=inv.Inventory )
			{
				if( Crossbow(Inv)!=None && Weapon(inv).AmmoAmount(0)<Weapon(inv).MaxAmmo(0) )
				{
					KFweapon(Inv).AddAmmo(1,0) ;
					PlaySound(Sound'KFWeaponSound.AmmoPickupSound', SLOT_Pain,2*TransientSoundVolume,,400);
					if(PlayerController(Instigator.Controller)!=none)
						PlayerController(Instigator.Controller).ClientMessage( "You picked up a bolt" );
					Destroy();
				}
			}
		}
	}
	simulated function Tick( float Delta )
	{
		if( Base==None )
		{
			if( Level.NetMode==NM_Client )
				bHidden = True;
			else Destroy();
		}
	}
	simulated function BeginState()
	{
		bCollideWorld = False;
		if( Level.NetMode!=NM_DedicatedServer )
			AmbientSound = None;
		if( Trail!=None )
			Trail.mRegen = False;
		SetCollisionSize(25,25);
	}
}

simulated function Explode(vector HitLocation, vector HitNormal);

simulated function ProcessTouch (Actor Other, vector HitLocation)
{
	local vector X,End,HL,HN;

	if ( Other!=none && Other!=Instigator && Other!=IgnoreImpactPawn ) // dont want to hit ourself (nor we want to hit same target twice) :)
	{
		X = Normal(Velocity);

		if( Level.NetMode!=NM_Client )
			PlayhitNoise(Pawn(Other)!=none && Pawn(Other).ShieldStrength>0);

		if( Physics==PHYS_Projectile && Pawn(Other)!=None && Vehicle(Other)==None )
		{
			IgnoreImpactPawn = Pawn(Other);
			if( IgnoreImpactPawn.IsHeadShot(HitLocation, X, 1.0) )
				Other.TakeDamage(Damage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * X, DamageTypeHeadShot);
			else Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
			SetPhysics(PHYS_Falling);
			Damage/=1.5;
			Velocity*=0.7;
			Return;
		}
		else if( ExtendedZCollision(Other)!=None && Pawn(Other.Owner)!=None )
		{
			if( Other.Owner==IgnoreImpactPawn )
				Return;
			IgnoreImpactPawn = Pawn(Other.Owner);
			if ( IgnoreImpactPawn.IsHeadShot(HitLocation, X, 1.0))
				Other.TakeDamage(Damage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * X, DamageTypeHeadShot);
			else Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
			SetPhysics(PHYS_Falling);
			Damage/=1.5;
			Velocity*=0.7;
			Return;
		}
		if( Level.NetMode!=NM_DedicatedServer && SkeletalMesh(Other.Mesh)!=None && Other.DrawType==DT_Mesh && Pawn(Other)!=None )
		{ // Attach victim to the wall behind if it dies.
			End = Other.Location+X*600;
			if( Other.Trace(HL,HN,End,Other.Location,False)!=None )
				Spawn(Class'BodyAttacher',Other,,HitLocation).AttachEndPoint = HL-HN;
		}
		Stick(Other,HitLocation);
		if( Level.NetMode!=NM_Client )
		{
			if (Pawn(Other) != none && Pawn(Other).IsHeadShot(HitLocation, X, 1.0))
				Pawn(Other).TakeDamage(Damage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * X, DamageTypeHeadShot);
			else Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
		}
	}
}
function PlayhitNoise( bool bArmored )
{
	if( bArmored )
		PlaySound(Arrow_hitarmor);   // implies hit a target with shield/armor
	else PlaySound(Arrow_hitflesh); 
}
simulated function HitWall( vector HitNormal, actor Wall )
{
	speed = VSize(Velocity);
      
	if ( Role==ROLE_Authority && Wall!=none )
	{
		if ( !Wall.bStatic && !Wall.bWorldGeometry )
		{
			if ( Instigator == None || Instigator.Controller == None )
				Wall.SetDelayedDamageInstigatorController(InstigatorController);
			Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);
			HurtWall = Wall;
		}
		MakeNoise(1.0);
	}
	PlaySound(Arrow_hitwall[Rand(3)],,2.5*TransientSoundVolume);
	Spawn(class'KFHitEffect');
	if( Instigator!=None && Level.NetMode!=NM_Client )
		MakeNoise(0.3);
	Stick(Wall, Location+HitNormal);
}
simulated function Landed(vector HitNormal)
{
	HitWall(HitNormal, None);
}
simulated function Stick(actor HitActor, vector HitLocation)
{
	local name NearestBone;
	local float dist;

	SetPhysics(PHYS_None);
	
	if (pawn(HitActor) != none)
	{
		NearestBone = GetClosestBone(HitLocation, HitLocation, dist , 'spine' , 15 );
		HitActor.AttachToBone(self,NearestBone);
	}
	else SetBase(HitActor);

	ImpactActor = HitActor;

	if (Base==None)
		Destroy();
	else GoToState('OnWall');
}
simulated function PhysicsVolumeChange( PhysicsVolume Volume )
{
	if( Volume.bWaterVolume && !PhysicsVolume.bWaterVolume )
	{
		if ( Trail != None )
			Trail.mRegen=False;
		Velocity*=0.65;
	}
}
simulated function Destroyed()
{
	if (Trail !=None)
		Trail.mRegen = False;
	Super.Destroyed();
}
simulated function Tick( float Delta )
{
	if( Physics==PHYS_Falling )
		SetRotation(rotator(Velocity));
}

defaultproperties
{
	DamageTypeHeadShot=Class'KFMod.DamTypeCrossbowHeadShot'
	Arrow_hitwall(0)=Sound'KFWeaponSound.bullethitflesh2'
	Arrow_hitwall(1)=Sound'KFWeaponSound.bullethitflesh3'
	Arrow_hitwall(2)=Sound'KFWeaponSound.bullethitflesh4'
	Arrow_rico(0)=Sound'KFWeaponSound.bullethitmetal'
	Arrow_rico(1)=Sound'KFWeaponSound.bullethitmetal3'
	Arrow_hitarmor=Sound'KFWeaponSound.bullethitflesh4'
	Arrow_hitflesh=Sound'KFWeaponSound.bullethitflesh4'
	HeadShotDamageMult=6.000000
	Speed=15000.000000
	MaxSpeed=20000.000000
	Damage=120.000000
	MomentumTransfer=150000.000000
	MyDamageType=Class'KFMod.DamTypeCrossbow'
	ExplosionDecal=Class'KFMod.ShotgunDecal'
	CullDistance=3000.000000
	bNetTemporary=False
	AmbientSound=Sound'PatchSounds.ArrowZip'
	LifeSpan=10.000000
	Mesh=SkeletalMesh'KFWeaponModels.XbowBolt'
	DrawScale=15.000000
	AmbientGlow=30
	Style=STY_Alpha
	bUnlit=False
	bFullVolume=True
}
