// The fire that gets spawned when a Fuel puddle is shot. This damages pawns and then dissipates.
class FuelFlameHurting extends FuelFlame;

var () int FlameDamage; // How much dmg the touchee takes.
var () float BurnTime; // How long it burns for.
var () float DamageRadius;

simulated function PostBeginPlay()
{
    // Dedicated servers + Emitters + AutoDestroy is a bad combo for gameplay actors.
    // Run damage ticking on the server explicitly and self-destruct after BurnTime.
    if (Role == ROLE_Authority)
        SetTimer(BurnInterval, true);
}

simulated function PostNetBeginPlay()
{
	local PlayerController PC;

	Super.PostNetBeginPlay();

	if ( Level.bDropDetail || (Level.DetailMode == DM_Low) )
	{
		bDynamicLight = false;
		LightType = LT_None;
	}
	else
	{
		PC = Level.GetLocalPlayerController();
		if ( (Instigator != None) && (PC == Instigator.Controller) )
		{
			return;
		}

		if ( (PC == None) || (PC.ViewTarget == None) || (VSize(PC.ViewTarget.Location - Location) > 3000) )
		{
			bDynamicLight = false;
			LightType = LT_None;
		}
	}
}

simulated function Tick(float DT)
{
	super.Tick(DT);
	BurnTime-=DT;
	//log("FuelFlameHurting: BurnTime remaining: " @ BurnTime);
	if (BurnTime <= 0)
	{
		//log("FuelFlameHurting: BurnTime expired, destroying flame.");
        // Server destruction replicates to clients; client-side Kill() is optional fluff.
        if (Role == ROLE_Authority)
		{
			//log("FuelFlameHurting: BurnTime expired, destroying flame (server).");
            Destroy();
		}
        else
		{
			//log("FuelFlameHurting: BurnTime expired, destroying flame (client).");
            Kill();
		}

        return;
	}
}

function Timer()
{
	//if (level.netMode == NM_DedicatedServer)
	//	Destroy();

	if (PhysicsVolume.bWaterVolume)
		return;

	if ( Role == Role_Authority )
		HurtRadius(FlameDamage, DamageRadius, class'KFMod.DamTypeFlamethrower', 0.f, Location );
}

simulated function PhysicsVolumeChange( PhysicsVolume NewVolume )
{
	if ( NewVolume.bWaterVolume )
	{
		if (level.netMode == NM_DedicatedServer)
			Destroy();
		else
			Kill();
	}
}

defaultproperties
{
	BurnInterval=0.250000
    BurnTime=5.000000
    FlameDamage=6
	DamageRadius=60.000000
    DrawScale=0.400000
    LifeSpan=0.000000
	//Physics=PHYS_Falling
    AutoDestroy=True
	bNotOnDedServer=False
	bGameRelevant=True
}
