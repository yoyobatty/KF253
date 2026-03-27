// The Nice, nasty barf we'll be using for the Bloat's ranged attack.
class KFBloatVomit extends BioGlob;

simulated function PostBeginPlay()
{
<<<<<<< HEAD
	Super.PostBeginPlay();

	SetOwner(None);

=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	if (Role == ROLE_Authority)
	{
		Velocity = Vector(Rotation) * Speed;
		Velocity.Z += TossZ;
	}
<<<<<<< HEAD

	if (Role == ROLE_Authority)
		Rand3 = Rand(3);
	if ( (Level.NetMode != NM_DedicatedServer) && ((Level.DetailMode == DM_Low) || Level.bDropDetail) )
	{
		bDynamicLight = false;
		LightType = LT_None;
	}
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
    
	// Difficulty Scaling
	if (Level.Game != none)
	{
<<<<<<< HEAD
		BaseDamage *= (Level.Game.GameDifficulty / 3);
		Damage *= (Level.Game.GameDifficulty / 3);
	} 
}


=======
		BaseDamage = Max((DifficultyDamageModifer() * BaseDamage),1);
		Damage = Max((DifficultyDamageModifer() * Damage),1);
	} 
}

// Scales the damage this Zed deals by the difficulty level
function float DifficultyDamageModifer()
{
    local float AdjustedDamageModifier;

    if ( Level.Game.GameDifficulty >= 7.0 ) // Hell on Earth
    {
    	AdjustedDamageModifier = 2.0;
    }
    else if ( Level.Game.GameDifficulty >= 5.0 ) // Suicidal
    {
    	AdjustedDamageModifier = 1.5;
    }
    else if ( Level.Game.GameDifficulty >= 4.0 ) // Hard
    {
    	AdjustedDamageModifier = 1.25;
    }
    else if ( Level.Game.GameDifficulty >= 2.0 ) // Normal
    {
    	AdjustedDamageModifier = 1.0;
    }
    else //if ( GameDifficulty == 1.0 ) // Beginner
    {
    	AdjustedDamageModifier = 0.3;
    }

    return AdjustedDamageModifier;
}

function TakeDamage( int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamageType );
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

state OnGround
{
    simulated function BeginState()
    {
<<<<<<< HEAD
        //PlayAnim('hit');
        SetTimer(RestTime, false);
        BlowUp(Location);
=======
        SetTimer(RestTime, false);
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
    }

    simulated function Timer()
    {
<<<<<<< HEAD
        if (bDrip)
        {
            bDrip = false;
            SetCollisionSize(default.CollisionHeight, default.CollisionRadius);
            Velocity = PhysicsVolume.Gravity * 0.2;
            SetPhysics(PHYS_Falling);
            bCollideWorld = true;
            bCheckedsurface = false;
            bProjTarget = false;
            LoopAnim('flying', 1.0);
            GotoState('Flying');
        }
        else
=======
        BlowUp(Location);
    }

    simulated function ProcessTouch(Actor Other, Vector HitLocation)
    {
        if (Pawn(Other)!=None)
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
        {
            BlowUp(Location);
        }
    }

<<<<<<< HEAD
	simulated function ProcessTouch(Actor Other, Vector HitLocation)
	{
		if ( Other != none )
			BlowUp(Location);
	}

    function TakeDamage( int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamageType )
    {
        if (DamageType.default.bDetonatesGoop)
        {
            bDrip = false;
            SetTimer(0.1, false);
        }
    }

    simulated function AnimEnd(int Channel)
    {
        local float DotProduct;

        if (!bCheckedSurface)
        {
            DotProduct = SurfaceNormal dot Vect(0,0,-1);
            if (DotProduct > 0.7)
            {
                PlayAnim('Drip', 0.66);
                bDrip = true;
                SetTimer(DripTime, false);
                if (bOnMover)
                    BlowUp(Location);
            }
            else if (DotProduct > -0.5)
            {
                PlayAnim('Slide', 1.0);
                if (bOnMover)
                    BlowUp(Location);
            }
            bCheckedSurface = true;
        }
    }

    simulated function MergeWithGlob(int AdditionalGoopLevel)
    {
        local int NewGoopLevel, ExtraSplash;
        NewGoopLevel = AdditionalGoopLevel + GoopLevel;
        if (NewGoopLevel > MaxGoopLevel)
        {
            Rand3 = (Rand3 + 1) % 3;
            ExtraSplash = Rand3;
            if (Role == ROLE_Authority)
                SplashGlobs(NewGoopLevel - MaxGoopLevel + ExtraSplash);
            NewGoopLevel = MaxGoopLevel - ExtraSplash;
        }
        SetGoopLevel(NewGoopLevel);
        SetCollisionSize(GoopVolume*10.0, GoopVolume*10.0);
        PlaySound(ImpactSound, SLOT_Misc);
        PlayAnim('hit');
        bCheckedSurface = false;
        SetTimer(RestTime, false);
    }

}

singular function SplashGlobs(int NumGloblings)
{
    local int g;
    local KFBloatVomit NewGlob;
    local Vector VNorm;

    for (g=0; g<NumGloblings; g++)
    {
        NewGlob = Spawn(Class, self,, Location+GoopVolume*(CollisionHeight+4.0)*SurfaceNormal);
        if (NewGlob != None)
        {
            NewGlob.Velocity = (GloblingSpeed + FRand()*150.0) * (SurfaceNormal + VRand()*0.8);
            if (Physics == PHYS_Falling)
            {
                VNorm = (Velocity dot SurfaceNormal) * SurfaceNormal;
                NewGlob.Velocity += (-VNorm + (Velocity - VNorm)) * 0.1;
            }
            NewGlob.InstigatorController = InstigatorController;
        }
        //else log("unable to spawn globling");
    }
=======
    function TakeDamage( int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamageType );
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

simulated function Destroyed()
{
    if ( !bNoFX && EffectIsRelevant(Location,false) )
    {
        //Spawn(class'xEffects.GoopSmoke');
        Spawn(class'KFmod.VomGroundSplash');
    }
    if ( Fear != None )
        Fear.Destroy();
    if (Trail != None)
        Trail.Destroy();
<<<<<<< HEAD
    //Super.Destroyed();
=======
    Super(Projectile).Destroyed();
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}


auto state Flying
{
    simulated function Landed( Vector HitNormal )
    {
        local Rotator NewRot;
<<<<<<< HEAD
        local int CoreGoopLevel;
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

        if ( Level.NetMode != NM_DedicatedServer )
        {
            PlaySound(ImpactSound, SLOT_Misc);
            // explosion effects
        }

<<<<<<< HEAD
        SurfaceNormal = HitNormal;

        // spawn globlings
        CoreGoopLevel = Rand3 + MaxGoopLevel - 3;
        if (GoopLevel > CoreGoopLevel)
        {
            if (Role == ROLE_Authority)
                SplashGlobs(GoopLevel - CoreGoopLevel);
            SetGoopLevel(CoreGoopLevel);
        }
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
        spawn(class'KFMod.VomitDecal',,,, rotator(-HitNormal));

        bCollideWorld = false;
        SetCollisionSize(GoopVolume*10.0, GoopVolume*10.0);
<<<<<<< HEAD
        bProjTarget = true;
=======
        //bProjTarget = true;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

        NewRot = Rotator(HitNormal);
        NewRot.Roll += 32768;
        SetRotation(NewRot);
        SetPhysics(PHYS_None);
<<<<<<< HEAD
        bCheckedsurface = false;
        Fear = Spawn(class'AvoidMarker');
=======
        Fear = Spawn(class'AvoidMarker');
        Fear.StartleBots();
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
        GotoState('OnGround');
    }

	simulated function HitWall( Vector HitNormal, Actor Wall )
	{
		Landed(HitNormal);
		if ( !Wall.bStatic && !Wall.bWorldGeometry )
		{
			bOnMover = true;
			SetBase(Wall);
			if (Base == None)
				BlowUp(Location);
		}
	}

	simulated function ProcessTouch(Actor Other, Vector HitLocation)
	{
		if( ExtendedZCollision(Other)!=None )
			Return;
<<<<<<< HEAD
		if (Other != Instigator && (Other.IsA('Pawn') || Other.IsA('DestroyableObjective') || Other.bProjTarget))
=======
		if (Other != Instigator && (Pawn(Other)!=None))
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
			HurtRadius(Damage,DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
		else if ( Other != Instigator && Other.bBlockActors )
			HitWall( Normal(HitLocation-Location), Other );
	}
}

defaultproperties
{
<<<<<<< HEAD
	BaseDamage=3
	TouchDetonationDelay=0.000000
	Speed=400.000000
	Damage=4.000000
	MomentumTransfer=2000.000000
	MyDamageType=Class'KFMod.DamTypeVomit'
	bDynamicLight=False
	LifeSpan=1.000000
	Skins(0)=Texture'KillingFloorLabTextures.LabCommon.voidtex'
	CollisionRadius=0.000000
	CollisionHeight=0.000000
	bUseCollisionStaticMesh=False
=======
    BaseDamage=3
    TouchDetonationDelay=0.000000
    Speed=400.000000
    Damage=4.000000
    MomentumTransfer=2000.000000
    MyDamageType=Class'KFMod.DamTypeVomit'
    bDynamicLight=False
    LifeSpan=8.000000
    Skins(0)=Texture'KillingFloorLabTextures.LabCommon.voidtex'
    bUseCollisionStaticMesh=False
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
