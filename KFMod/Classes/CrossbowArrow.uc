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

// Kill-cam additions
var() float KillCamDuration;
var bool bKillCamTriggered;

// Cache original collision so we can restore after detaching from base
var float OrigCollisionRadius;
var float OrigCollisionHeight;

var CrossbowArrowDummyPickup DummyPickupRef;

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

simulated function Tick( float DeltaTime )
{
	//local vector HN, HL;
	//local Actor P;
	
	Super.Tick(DeltaTime);
	/* 
	P = Trace(HL,HN,Location+Vector(Rotation)*Velocity*20.f,Location,True);
	if(P!=None && KFMonster(P)!=None)
	{
		if (KFMonster(P).Health - Damage <= 0 && KFMonster(P).Health > 0)
		{
			TriggerKillCam();
		}
	}
	*/
	if( Physics==PHYS_Falling )
		SetRotation(rotator(Velocity));
	else if( Physics==PHYS_Projectile )
		Velocity.Z -= DeltaTime * 100.0; // gravity	
}
/* 
// Start and restore the kill-cam for the shooter
function TriggerKillCam()
{
    local PlayerController PC;

    if (bKillCamTriggered || Instigator == None)
        return;

    PC = PlayerController(Instigator.Controller);
    if (PC == None)
        return;

    bKillCamTriggered = true;

	Level.Game.SetGameSpeed(0.2);

    // Tell the owning client to view this arrow
	PC.ClientSetFixedCamera(true);
	PC.ClientSetBehindView(true);
    PC.ClientSetViewTarget(self);

    // After Duration, restore view
    SetTimer(KillCamDuration, false);
}

function Timer()
{
    local PlayerController PC;

	Level.Game.SetGameSpeed(1.0);
    PC = PlayerController(Instigator.Controller);
    if (PC != None)
    {
        if (Instigator != None)
            PC.ClientSetViewTarget(Instigator);
        else if (PC.Pawn != None)
            PC.ClientSetViewTarget(PC.Pawn);
        else
            PC.ClientSetViewTarget(PC);
		PC.ClientSetBehindView(false);
		PC.ClientSetFixedCamera(false);
		bKillCamTriggered = false;
    }
}
*/
simulated state OnWall
{
Ignores HitWall;

	function ProcessTouch (Actor Other, vector HitLocation)
	{
		/* 
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
		*/
	}
    simulated function Tick( float Delta )
    {
        Super.Tick(Delta);

        //Fixes arrows sticking to objects that get destroyed or hidden
        if( (Base!=None && (NetKActor(Base)!=None || Decoration(Base)!=None) && (Base.bDeleteMe || Base.bHidden)) )
        {
            bCollideWorld = True;
            if (OrigCollisionRadius == 0) OrigCollisionRadius = default.CollisionRadius;
            if (OrigCollisionHeight == 0) OrigCollisionHeight = default.CollisionHeight;
            SetCollisionSize(OrigCollisionRadius, OrigCollisionHeight);

            // make sure we are visible on clients
            if( Level.NetMode==NM_Client )
                bHidden = False;

            SetBase(None);
            SetPhysics(PHYS_Projectile);
			Velocity = Vect(0,0,-1) * 100.f;
			SetRotation(rotator(Velocity));
            GotoState(''); 
        }
    }

    simulated function BeginState()
    {
        // save current collision before enlarging it for pickup-on-wall
        OrigCollisionRadius = CollisionRadius;
        OrigCollisionHeight = CollisionHeight;

        bCollideWorld = False;
        if( Level.NetMode!=NM_DedicatedServer )
            AmbientSound = None;
        if( Trail!=None )
            Trail.mRegen = False;
		DummyPickupRef = Spawn(class'CrossbowArrowDummyPickup',,,Location-Vector(Rotation)*10);
		if( DummyPickupRef != None )
		{
			DummyPickupRef.ArrowRef = self;
			DummyPickupRef.InitDroppedPickupFor(DummyPickupRef.Inventory);
			DummyPickupRef.SetBase(self); //Keep it attached 
			DummyPickupRef.AddToNavigation();
		}
		// Enlarge collision size to make it easier to pick up arrows stuck in walls/f
        SetCollisionSize(25,25);
    }
}

simulated function Explode(vector HitLocation, vector HitNormal);

simulated function ProcessTouch (Actor Other, vector HitLocation)
{
	local vector X,End,HL,HN;

	if ( Other == none || Other == Instigator || Other.Base == Instigator || Other==IgnoreImpactPawn ||
        (IgnoreImpactPawn != none && Other.Base == IgnoreImpactPawn) )
		return;

	// Don't allow hits on poeple on the same team
    if ( KFHumanPawn(Other) != None
         && Instigator != None && Instigator.Controller != None
         && KFHumanPawn(Other).Controller != None
         && KFHumanPawn(Other).Controller.SameTeamAs(Instigator.Controller) )
    {
        return;
    }

	X = Normal(Velocity);

	if( Level.NetMode!=NM_Client )
		PlayhitNoise(Pawn(Other)!=none && Pawn(Other).ShieldStrength>0);

	if( Level.NetMode!=NM_DedicatedServer && SkeletalMesh(Other.Mesh)!=None && Other.DrawType==DT_Mesh && Pawn(Other)!=None )
	{ // Attach victim to the wall behind if it dies.
		End = Other.Location+X*600;
		if( Other.Trace(HL,HN,End,Other.Location,False)!=None )
			Spawn(Class'BodyAttacher',Other,,HitLocation).AttachEndPoint = HL-HN;
	}
    if ( KFGlassMover(Other) != None )
    {
        if( Level.NetMode!=NM_Client )
            Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);

        PlaySound(Arrow_rico[Rand(2)],,2.0*TransientSoundVolume);
        Spawn(class'KFHitEffect');
        return;
    }
	if( Physics==PHYS_Projectile && Pawn(Other)!=None && Vehicle(Other)==None )
	{
		IgnoreImpactPawn = Pawn(Other);
		if( IgnoreImpactPawn.IsHeadShot(HitLocation, X, 1.0) )
			Other.TakeDamage(Damage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * X, DamageTypeHeadShot);
		else Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
		//SetPhysics(PHYS_Falling);
		Damage/=1.25;
		Velocity*=0.85;
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
		//SetPhysics(PHYS_Falling);
		Damage/=1.25;
		Velocity*=0.85;
		Return;
	}
	Stick(Other,HitLocation);
	if( Level.NetMode!=NM_Client )
	{
		if (Pawn(Other) != none && Pawn(Other).IsHeadShot(HitLocation, X, 1.0))
			Pawn(Other).TakeDamage(Damage * HeadShotDamageMult, Instigator, HitLocation, MomentumTransfer * X, DamageTypeHeadShot);
		else Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * X, MyDamageType);
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
        if ( (!Wall.bStatic && !Wall.bWorldGeometry) )
        {
            if ( Instigator == None || Instigator.Controller == None )
                Wall.SetDelayedDamageInstigatorController(InstigatorController);
            Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);
            HurtWall = Wall;
        }
		MakeNoise(1.0);
	}
	PlaySound(Arrow_hitwall[Rand(3)],,2.5*TransientSoundVolume);
	if( Physics!=PHYS_Falling && (Normal(Velocity) Dot HitNormal)>-0.1 )
	{
		Velocity = MirrorVectorByNormal(Velocity,HitNormal);
		SetPhysics(PHYS_Falling);
		Return;
	}
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
    if (DummyPickupRef != None)
    {
        DummyPickupRef.ArrowRef = None;
        DummyPickupRef.Destroy();
    }
	Super.Destroyed();
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
	HeadShotDamageMult=4.000000
	Speed=6000.000000
	MaxSpeed=80000.000000
	Damage=300.000000
	MomentumTransfer=10000.000000
	MyDamageType=Class'KFMod.DamTypeCrossbow'
	ExplosionDecal=Class'KFMod.ShotgunDecal'
	CullDistance=3000.000000
	bNetTemporary=False
	AmbientSound=Sound'PatchSounds.ArrowZip'
	LifeSpan=25.000000
	Mesh=SkeletalMesh'KFWeaponModels.XbowBolt'
	DrawScale=15.000000
	AmbientGlow=30
	Style=STY_Alpha
	bUnlit=False
	bFullVolume=True
	KillCamDuration=1.500000
}
