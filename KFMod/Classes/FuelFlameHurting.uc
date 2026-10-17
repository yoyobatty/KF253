// The fire that gets spawned when a Fuel puddle is shot. This damages pawns and then dissipates.
class FuelFlameHurting extends FuelFlame;

var () int FlameDamage; // How much dmg the touchee takes.
var () float BurnTime; // How long it burns for.
var () float DamageRadius;
var () float DieDownTime;	// once the burn time is over: how long the flames alight take to burn out and the smoke to go
var bool bDyingDown;
var float DownLeft;
var bool bLightShared;		// dark because a lit fire burns near it (KFFireLight); it may take that one's light later
var float LightUpLeft;		// fading in a light handed on to it
var int SharedBy;			// lit: how many dark fires near it share its light
var float LitBrightness;	// lit: its brightness with them

simulated function PostBeginPlay()
{
    // Dedicated servers + Emitters + AutoDestroy is a bad combo for gameplay actors.
    // Run damage ticking on the server explicitly and self-destruct after BurnTime.
    if (Level.NetMode != NM_Client)
        SetTimer(BurnInterval, true);
}

simulated function PostNetBeginPlay()
{
	local PlayerController PC;
	local FuelFlameHurting Lit;

	Super.PostNetBeginPlay();
	LitBrightness = default.LightBrightness;

	if ( Level.bDropDetail || (Level.DetailMode == DM_Low) )
	{
		bDynamicLight = false;
		LightType = LT_None;
	}
	else
	{
		PC = Level.GetLocalPlayerController();
		if ( (Instigator == None) || (PC != Instigator.Controller) )
		{
			if ( (PC == None) || (PC.ViewTarget == None) || (VSize(PC.ViewTarget.Location - Location) > 3000) )
			{
				bDynamicLight = false;
				LightType = LT_None;
			}
		}
		Lit = class'KFFireLight'.static.LitNear(self);
		if ( Lit != None )
		{
			bDynamicLight = false;
			LightType = LT_None;
			bLightShared = true;
			Lit.Shared();
		}
	}
}

// A fire near by stays dark and shares this one's light: it gets brighter
simulated function Shared()
{
	if ( SharedBy >= class'KFFireLight'.default.MaxShared )
		return;
	SharedBy++;
	LitBrightness = default.LightBrightness * (1.0 + class'KFFireLight'.default.ShareBrighten * SharedBy);
	if ( LightUpLeft <= 0 )
		LightBrightness = LitBrightness;
}

// The light of a fire near by that is dying down, faded in
simulated function TakeLight()
{
	bLightShared = false;
	LightType = default.LightType;
	bDynamicLight = true;
	LightUpLeft = 0.6;
	LightBrightness = 0;
	SharedBy = 0;
	LitBrightness = default.LightBrightness;
}

simulated function Tick(float DT)
{
	super.Tick(DT);
	if( LightUpLeft > 0 && !bDyingDown )
	{
		LightUpLeft -= DT;
		LightBrightness = LitBrightness * FClamp(1.0 - LightUpLeft / 0.6, 0.0, 1.0);
	}
	if( bDyingDown )
	{
		// (the light and the crackle go down with the flames)
		DownLeft -= DT;
		LightBrightness = LitBrightness * FClamp(DownLeft/(DieDownTime*0.5),0.0,1.0);
		SoundVolume = byte(float(default.SoundVolume) * FClamp(DownLeft/(DieDownTime*0.6),0.0,1.0));
		return;
	}
	BurnTime-=DT;
	if (BurnTime <= 0)
		DieDown();
}

// The fire dies down: no more harm and no more flames; those alight burn out and the smoke drifts off, and then it
// is gone. (It was destroyed when its time was up, and every flame and wisp of smoke vanished in the same frame.)
simulated function DieDown()
{
	bDyingDown = true;
	DownLeft = DieDownTime;
	if ( LightType != LT_None && Level.NetMode != NM_DedicatedServer )
		class'KFFireLight'.static.HandOver(self);
	SetTimer(0.0, false);
	Kill();
	// (and gone for certain then, a dedicated server too, which does not run the particles that would end it; not before
	// the last smoke, which lives up to 2.5 s)
	LifeSpan = FMax(DieDownTime, 2.5) + 0.5;
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
	BurnInterval=0.500000
    BurnTime=5.000000
    DieDownTime=2.600000
    FlameDamage=12
	DamageRadius=60.000000
    DrawScale=0.400000
    LifeSpan=0.000000
	//Physics=PHYS_Falling
    AutoDestroy=True
	bNotOnDedServer=False
	bGameRelevant=True
}
