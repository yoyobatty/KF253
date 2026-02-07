//-----------------------------------------------------------
//
//-----------------------------------------------------------
class BullpupHealingProj extends Projectile;

var vector Dir;
var bool bRing,bHitWater,bWaterStart;

var()   sound   ExplosionSound; // The sound of the rocket exploding

var () int HealBoostAmount;

var     bool                bHitHealTarget;             // Hit a target we can heal.
var     bool                bHasExploded;
var     vector              HealLocation;
var     rotator             HealRotation;

replication
{
	reliable if(Role == ROLE_Authority)
		HealLocation, HealRotation;
}

simulated function PostNetReceive()
{
    if( bHidden && !bHitHealTarget )
    {
        if( HealLocation != vect(0,0,0) )
        {
            log("PostNetReceive calling HitHealTarget for location of "$HealLocation);
            HitHealTarget(HealLocation,vector(HealRotation));
        }
        else
        {
            log("PostNetReceive calling HitHealTarget for self location of "$HealLocation);
            HitHealTarget(Location,-vector(Rotation));
        }
    }
}

// Do a healing effect/sound instead of standard "explode"
simulated function HitHealTarget(vector HitLocation, vector HitNormal)
{
	bHitHealTarget = true;
	bHidden = true;
	SetPhysics(PHYS_None);

    HealLocation = HitLocation;
    HealRotation = rotator(HitNormal);

	if( Role == ROLE_Authority )
	{
	   SetTimer(0.1, false);
	   NetUpdateTime = Level.TimeSeconds - 1;
	}

	PlaySound(ExplosionSound,,2.0);

	if ( EffectIsRelevant(Location,false) )
	{
		Spawn(Class'KFMod.HealingFX',,, HitLocation, rotator(HitNormal));
	}
}

function Timer()
{
    Destroy();
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
    bHasExploded = True;

    // Don't do the regular effect if we healed someone
    if( bHitHealTarget )
    {
        return;
    }

    SetPhysics(PHYS_None);


    BlowUp(HitLocation);
    Destroy();
}

simulated function Destroyed()
{
	if( !bHasExploded && !bHidden )
		Explode(Location,vect(0,0,1));
	if( bHidden && !bHitHealTarget )
	{
        if( HealLocation != vect(0,0,0) )
        {
            HitHealTarget(HealLocation,vector(HealRotation));
        }
        else
        {
            HitHealTarget(Location,-vector(Rotation));
        }
    }

    Super.Destroyed();
}

/* HurtRadius()
 Hurt locally authoritative actors within the radius.
*/
simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
    return;
}

simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
	local KFPlayerReplicationInfo PRI;
	local int MedicReward;
	local KFHumanPawn Healed;
	local float HealSum; // for modifying based on perks

	if ( Other == none || Other == Instigator || Other.Base == Instigator )
		return;

    if( Role == ROLE_Authority )
    {
    	Healed = KFHumanPawn(Other);

        if( Healed != none )
        {
            HitHealTarget(HitLocation, -vector(Rotation));
        }

        if( Instigator != none && Healed != none && Healed.Health > 0 &&
            Healed.Health <  Healed.HealthMax )
        {
    		MedicReward = HealBoostAmount;

    		PRI = KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo);

    		if ( PRI != none && PRI.ClientVeteranSkill != none )
    		{
    			MedicReward *= PRI.ClientVeteranSkill.Static.GetHealPotency();
    		}

            HealSum = MedicReward;

    		if ( (Healed.Health + Healed.healthToGive + MedicReward) > Healed.HealthMax )
    		{
                MedicReward = Healed.HealthMax - (Healed.Health + Healed.healthToGive);
    			if ( MedicReward < 0 )
    			{
    				MedicReward = 0;
    			}
    		}

            Healed.GiveHealth(HealSum, Healed.HealthMax);

     		if ( PRI != None )
    		{
                // Give the medic reward money as a percentage of how much of the person's health they healed
    			MedicReward = int((FMin(float(MedicReward),Healed.HealthMax)/Healed.HealthMax) * 60); // Increased to 80 in Balance Round 6, reduced to 60 in Round 7

    			if ( KFHumanPawn(Instigator) != none )
    			{
    				KFHumanPawn(Instigator).AlphaAmount = 255;
    			}

                if( Bullpup(Instigator.Weapon) != none )
                {
                    Bullpup(Instigator.Weapon).ClientSuccessfulHeal(Healed.GetPlayerName());
                }
    		}
        }
    }
    else if( KFHumanPawn(Other) != none )
    {
    	bHidden = true;
    	SetPhysics(PHYS_None);
    	return;
    }

	Explode(HitLocation,-vector(Rotation));
}

defaultproperties
{
    HealBoostAmount=20
    Speed=10000.000000
    MaxSpeed=12500.000000
    Damage=650.000000
    DamageRadius=200.000000
    MomentumTransfer=125000.000000
    ExplosionDecal=Class'KFMod.ShotgunDecal'
    LightHue=25
    LightSaturation=100
    LightBrightness=250.000000
    LightRadius=10.000000
    DrawType=DT_StaticMesh
    StaticMesh=StaticMesh'WeaponStaticMesh.FlakChunk'
    CullDistance=3000.000000
    DrawScale=1.000000
    Style=STY_Alpha
    bNetTemporary=False
    bUpdateSimulatedPosition=True
    LifeSpan=10.000000
    bUnlit=False
    SoundVolume=128
    SoundRadius=250.000000
    TransientSoundVolume=2.000000
    TransientSoundRadius=500.000000
    bNetNotify=True
    ForceRadius=300.000000
    ForceScale=10.000000
}
