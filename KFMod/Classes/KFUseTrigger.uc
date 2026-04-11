//=============================================================================
// KF Use Trigger. Now with bigger messages, and Refire delays for human users.
// This shit's used for Doors in Killing Floor.
// By: Alex
//=============================================================================
class KFUseTrigger extends UseTrigger;

var array<KFDoorMover> DoorOwners;

var () int ReFireDelay;
var int LastAttempt;

var  float WeldStrength,LastMessageTimer;
var() float MaxWeldStrength;

var() float CombatSealReduction; // How much do we weaken the effectiveness of the Players' welder by when the door is being attacked?

var () bool bAlwaysShowMessage; // Show a text message to nearby players even when the doors are sealed /  the trigger is not useable
var () string LockedMessage,UnLockedMessage,WeldedShutMessage;
var () sound LockedSound,UnLockedSound ;  // The SFX for trying to open a locked door, and unlocking it.

// Hehehe
var bool bBoobyTrapped;
var Pawn BoobyTrapOwner;
var float BoobyTrapDamage, BoobyTrapRadius;
var class<DamageType> BoobyTrapDamageType;
var string BoobyTrapSetMessage, BoobyTrapAlreadySetMessage, BoobyTrapNeedGrenadeMessage;
var KFBoobyTrapDecoration BoobyTrapMesh;
var private bool bClientBoobyTrapped; // Client-side tracking for PostNetReceive

var() float BotTriggerRadius; // Hack for bots

replication
{
	reliable if( ROLE==ROLE_Authority )
		bBoobyTrapped;
}

function AddDoor( KFDoorMover Other )
{
	local int i;

	i = DoorOwners.Length;
	DoorOwners.Length = i+1;
	DoorOwners[i] = Other;
}

function bool SelfTriggered()
{
	return true;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(2.0, true);
}

function Timer()
{
	local Pawn P;
	local float ScanRadius;

	if (BotTriggerRadius > 0)
		ScanRadius = BotTriggerRadius;
	else
		ScanRadius = CollisionRadius;
	foreach CollidingActors(Class'Pawn', P, ScanRadius)
	{
		if (AIController(P.Controller) != None)
			Touch(P);
	}
}

// Check if a pawn has grenades and consume one
function bool ConsumeGrenade(Pawn User)
{
    local Inventory Inv;
    local Weapon W;

    for (Inv = User.Inventory; Inv != None; Inv = Inv.Inventory)
    {
        W = Weapon(Inv);
        if (W != None && W.IsA('Frag'))
        {
            if (W.AmmoAmount(0) > 0)
            {
                W.ConsumeAmmo(0, 1);
                return true;
            }
        }
    }
    return false;
}

function SetBoobyTrap(Pawn User)
{
    local int i;
    local bool bValidDoor;

    if (User == None || User.Controller == None)
        return;

    // Check if door is closed and not hidden
    for (i = 0; i < DoorOwners.Length; i++)
    {
        if (DoorOwners[i].bClosed && !DoorOwners[i].bHidden)
        {
            bValidDoor = true;
            break;
        }
    }

    if (!bValidDoor)
        return;

    if (bBoobyTrapped)
    {
        if (PlayerController(User.Controller) != None)
            PlayerController(User.Controller).ClientMessage(BoobyTrapAlreadySetMessage, 'CriticalEvent');
        return;
    }

    // Try to consume a grenade from the player's inventory
    if (!ConsumeGrenade(User))
    {
        if (PlayerController(User.Controller) != None)
            PlayerController(User.Controller).ClientMessage(BoobyTrapNeedGrenadeMessage, 'CriticalEvent');
        return;
    }

    // Set the trap
    bBoobyTrapped = true;
    BoobyTrapOwner = User;
    NetUpdateTime = Level.TimeSeconds - 1;

    if (PlayerController(User.Controller) != None)
        PlayerController(User.Controller).ClientMessage(BoobyTrapSetMessage, 'CriticalEvent');

    // Spawn a small visual indicator near the door
    SpawnTrapVisual();
}

function SpawnTrapVisual()
{
    local vector TraceStart, TraceEnd, HitLocation, HitNormal;
    local Actor HitActor;
    local Rotator GrenadeRot;

    TraceStart = Location;
    TraceEnd = Location - vect(0, 0, 256); 

    // Trace down to find the floor
    HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, false);

    if (HitActor != None)
    {
        // Place slightly above the hit point so it doesn't clip into the floor
        HitLocation.Z += 2.0;
    }
    else
    {
        // Fallback: use trigger location lowered by a rough estimate
        HitLocation = Location;
        HitLocation.Z -= 48.0;
    }

    // Random yaw rotation so it doesn't always face the same way
    GrenadeRot.Yaw = Rand(65536);
    GrenadeRot.Pitch = 0;
    GrenadeRot.Roll = 0;

    // Spawn a decoration actor with the grenade static mesh
    BoobyTrapMesh = Spawn(class'KFBoobyTrapDecoration', self,, HitLocation, GrenadeRot);
}

simulated event PostNetReceive()
{
	if( !bBoobyTrapped && bClientBoobyTrapped )
	{
		bClientBoobyTrapped = false;
		if( BoobyTrapMesh!=None )
		{
			BoobyTrapMesh.Destroy();
			BoobyTrapMesh = None;
		}
		Spawn(class'KFNadeExplosion',,, Location);
	}
	else if( bBoobyTrapped && !bClientBoobyTrapped )
	{
		bClientBoobyTrapped = true;
	}
}

// Detonate the booby trap
function DetonateBoobyTrap(Pawn TriggeredBy)
{
    local int i;

    if (!bBoobyTrapped)
        return;

    bBoobyTrapped = false;
    NetUpdateTime = Level.TimeSeconds - 1;

    if( Level.NetMode!=NM_DedicatedServer )
        Spawn(class'KFNadeExplosion',,, Location);
    for (i = 0; i < DoorOwners.Length; i++)
    {
        if (!DoorOwners[i].bHidden)
        {
            DoorOwners[i].GoBang(BoobyTrapOwner, Location, vect(0,0,0), BoobyTrapDamageType);
        }
    }

    //Booooom
    if (BoobyTrapOwner != None && BoobyTrapOwner.Controller != None)
    {
        HurtRadius(BoobyTrapDamage, BoobyTrapRadius, BoobyTrapDamageType, 800, Location );
    }

    if (BoobyTrapMesh != None)
    {
        BoobyTrapMesh.Destroy();
        BoobyTrapMesh = None;
    }

    BoobyTrapOwner = None;
}

// Override HurtRadius to credit the trap owner
function HurtRadius(float DamageAmount, float DamageRadius, class<DamageType> DmgType, float Momentum, vector HitLocation)
{
    local Actor Victims;
    local float DamageScale, Dist;
    local vector Dir;

    if (BoobyTrapOwner == None)
        return;

    foreach VisibleCollidingActors(class'Actor', Victims, DamageRadius, HitLocation)
    {
        if (Victims != Self && Victims != None)
        {
            Dir = Victims.Location - HitLocation;
            Dist = FMax(1, VSize(Dir));
            Dir = Dir / Dist;
            DamageScale = 1 - FMax(0, (Dist - Victims.CollisionRadius) / DamageRadius);

            if (Pawn(Victims) != None)
            {
                Pawn(Victims).TakeDamage(
                    DamageScale * DamageAmount,
                    BoobyTrapOwner,
                    Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * Dir,
                    DamageScale * Momentum * Dir,
                    DmgType
                );
            }
        }
    }
}

function UsedBy( Pawn user )
{
	local int i;
	local Inventory inv;

	if( (Level.TimeSeconds-LastAttempt)<RefireDelay || User.IsA('KFMonster') )
		Return;

    // If player is crouching and door is closed, attempt to set a booby trap
    if (user.bIsCrouched && PlayerController(user.Controller) != None)
    {
        for (i = 0; i < DoorOwners.Length; i++)
        {
            if (DoorOwners[i].bClosed && !DoorOwners[i].bHidden && !DoorOwners[i].bKeyLocked)
            {
                SetBoobyTrap(user);
                LastAttempt = Level.TimeSeconds;
                return;
            }
        }
    }

	For( i=0; i<DoorOwners.Length; i++ )
	{
		if ( !DoorOwners[i].bSealed && !DoorOwners[i].bHidden && !DoorOwners[i].bKeyLocked )
		{
			DoorOwners[i].Trigger(Self,User);
			LastAttempt = Level.TimeSeconds;
		}
		if ( DoorOwners[i].bSealed && !DoorOwners[i].bHidden && DoorOwners[i].bClosed)
		{
                    if( PlayerController(user.controller)!=None )
				PlayerController(user.controller).ClientMessage(WeldedShutMessage, 'CriticalEvent');
			LastAttempt = Level.TimeSeconds;
		}
		if( DoorOwners[i].bKeyLocked && !DoorOwners[i].bSealed && !DoorOwners[i].bHidden && DoorOwners[i].bClosed )
		{
			for( inv=user.Inventory; inv!=None; inv=inv.Inventory)
			{
				if( KFKeyInventory(inv)!=None && inv.tag==DoorOwners[i].tag )
				{
					DoorOwners[i].Trigger(Self,User);
					if( PlayerController(user.controller)!=None )
						PlayerController(user.controller).ClientMessage(UnLockedMessage, 'CriticalEvent');
					PlaySound(UnLockedSound,,255,,100);
					DoorOwners[i].bKeyLocked = false;
					LastAttempt = Level.TimeSeconds;
					KFKeyInventory(inv).UnLock();
				}
			}
		}
	}
}

// Modded to account for...Zombies, and the Sealing (removal) of the Door Movers.
function Touch( Actor Other )
{
	local int i;

	if( Pawn(Other)==None || Pawn(Other).Health<=0 )
		Return;

	For( i=0; i<DoorOwners.Length; i++ )
	{
		if( AIController(Pawn(Other).Controller) != None )
		{
			if( !DoorOwners[i].bKeyLocked && !DoorOwners[i].bSealed && !DoorOwners[i].bHidden && DoorOwners[i].KeyNum==0 )
				DoorOwners[i].GotoState( , 'Open' );
		}
		else if ( !DoorOwners[i].bSealed && !DoorOwners[i].bHidden )
		{
			// Send a string message to the toucher.
			if(PlayerController(Pawn(Other).Controller)!=none)
			{
				if( LastMessageTimer<Level.TimeSeconds && Message!="" )
				{
					LastMessageTimer = Level.TimeSeconds+0.6;
					PlayerController(Pawn(Other).Controller).ClientMessage(Message, 'CriticalEvent');
				}
			}
			else if ( DoorOwners[i].bClosed && Pawn(Other).Controller!=None )
				UsedBy(Pawn(Other));
		}
		else if( !DoorOwners[i].bHidden && bAlwaysShowMessage && LastMessageTimer<Level.TimeSeconds
		 && PlayerController(Pawn(Other).Controller)!=none && Message!="" )
		{
			LastMessageTimer = Level.TimeSeconds+0.6;
			PlayerController(Pawn(Other).Controller).ClientMessage(Message, 'CriticalEvent');
		}
	}
}

// The weld functions here are needed so that all doors for this
// trigger stay in sync
function AddWeld( float ExtraWeld, bool bZombieAttacking, Pawn WelderInst )
{
	local int i;
	local KFPlayerController PC;

	if (bZombieAttacking)
		ExtraWeld *= CombatSealReduction;

	if( (WeldStrength+ExtraWeld)>MaxWeldStrength )
		ExtraWeld = MaxWeldStrength-WeldStrength;
	if( ExtraWeld==0 )
		Return;
	if( WelderInst!=None )
	{
		PC = KFPlayerController(WelderInst.Controller);
		if( PC!=None && (PC.MyActiveStats!=None || PC.FindStatsObject()) )
			PC.MyActiveStats.ReceiveWelded(ExtraWeld); // Award for welding.
	}
	
	WeldStrength +=ExtraWeld;

	For( i=0; i<DoorOwners.Length; i++ )
		DoorOwners[i].SetWeldStrength(WeldStrength);
}

function UnWeld(float DeWeldage,bool bZombieAttacking, Pawn WelderInst)
{
	local int i;
	local KFPlayerController PC;

	if (bZombieAttacking)
		DeWeldage *= CombatSealReduction;
		

//	if( DeWeldage<WeldStrength )
	//	DeWeldage = WeldStrength;
	if( DeWeldage==0 )
		Return;

	if( WelderInst!=None )
	{
		PC = KFPlayerController(WelderInst.Controller);
		if( PC!=None && (PC.MyActiveStats!=None || PC.FindStatsObject()) )  
			PC.MyActiveStats.ReceiveWelded(DeWeldage * 0.5); // Award for unwelding.
	}

	WeldStrength -=DeWeldage;


	For( i=0; i<DoorOwners.Length; i++ )
		DoorOwners[i].SetWeldStrength(WeldStrength);
}

//TODO: store last hit parameters, and time,
//      then check in unweld if the unweld should become a damageweld
//      using the stored parameters
function DamageWeld(float WeldDamage,pawn instigatedBy, Vector hitlocation,Vector momentum, class<DamageType> damageType)
{
	local int i;

	if( WeldDamage==0 )
		Return;
	WeldStrength-=WeldDamage;

	if(DamageType == class'DamTypeFrag' || DamageType == class'DamTypeLAW')
	{
		if (bBoobyTrapped)
			DetonateBoobyTrap(instigatedBy);
	}

	if( WeldStrength<=0 )
	{
		WeldStrength = 0;
		For( i=0; i<DoorOwners.Length; i++ )
		{
			DoorOwners[i].SetWeldStrength(0);
			DoorOwners[i].GoBang(instigatedBy,hitlocation,momentum,damageType);
		}
		// If the door is booby trapped and is being damaged by zombies, detonate!
		if (bBoobyTrapped)
			DetonateBoobyTrap(instigatedBy);
	}
	else
	{
		For( i=0; i<DoorOwners.Length; i++ )
			DoorOwners[i].SetWeldStrength(WeldStrength);
	}
}

defaultproperties
{
	ReFireDelay=2
	BotTriggerRadius=150.000000
	MaxWeldStrength=400.000000
	CombatSealReduction=0.500000
	LockedMessage="This door is locked. Looks like it needs a key.."
	UnLockedMessage="Your Key unlocked the door."
	WeldedShutMessage="This door is welded shut..."
	LockedSound=Sound'PatchSounds.LockedDoorSound'
	UnLockedSound=Sound'PatchSounds.DoorUnlockSound'
	BoobyTrapDamage=500.000000
	BoobyTrapRadius=400.000000
	BoobyTrapDamageType=class'DamTypeFrag'
	BoobyTrapSetMessage="You rigged the door with a grenade. Stand clear!"
	BoobyTrapAlreadySetMessage="This door is already booby trapped."
	BoobyTrapNeedGrenadeMessage="You need a grenade to booby trap this door."
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
	bNetNotify=True
}
