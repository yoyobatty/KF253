// The Nice, nasty barf we'll be using for the Bloat's ranged attack.
class KFBloatVomit extends BioGlob;

simulated function PostBeginPlay()
{
	if (Role == ROLE_Authority)
	{
		Velocity = Vector(Rotation) * Speed;
		Velocity.Z += TossZ;
	}
    
	// Difficulty Scaling
	if (Level.Game != none)
	{
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

state OnGround
{
    simulated function BeginState()
    {
        SetTimer(RestTime, false);
    }

    simulated function Timer()
    {
        BlowUp(Location);
    }

    simulated function ProcessTouch(Actor Other, Vector HitLocation)
    {
        if (Pawn(Other)!=None)
        {
            BlowUp(Location);
        }
    }

    function TakeDamage( int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamageType );
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
    Super(Projectile).Destroyed();
}


auto state Flying
{
    simulated function Landed( Vector HitNormal )
    {
        local Rotator NewRot;

        if ( Level.NetMode != NM_DedicatedServer )
        {
            PlaySound(ImpactSound, SLOT_Misc);
            // explosion effects
        }

        spawn(class'KFMod.VomitDecal',,,, rotator(-HitNormal));

        bCollideWorld = false;
        SetCollisionSize(GoopVolume*10.0, GoopVolume*10.0);
        //bProjTarget = true;

        NewRot = Rotator(HitNormal);
        NewRot.Roll += 32768;
        SetRotation(NewRot);
        SetPhysics(PHYS_None);
        Fear = Spawn(class'AvoidMarker');
        Fear.StartleBots();
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
		if (Other != Instigator && (Pawn(Other)!=None))
			HurtRadius(Damage,DamageRadius, MyDamageType, MomentumTransfer, HitLocation );
		else if ( Other != Instigator && Other.bBlockActors )
			HitWall( Normal(HitLocation-Location), Other );
	}
}

defaultproperties
{
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
}
