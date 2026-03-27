//=============================================================================
// KF Use Trigger. Now with bigger messages, and Refire delays for human users.
// This shit's used for Doors in Killing Floor.
// By: Alex
//=============================================================================
class KFUseTrigger extends UseTrigger;

var array<KFDoorMover> DoorOwners;

var () int ReFireDelay;
var int LastAttempt;

var  float WeldStrength;
var() float MaxWeldStrength;

var() float CombatSealReduction; // How much do we weaken the effectiveness of the Players' welder by when the door is being attacked?

var () bool bAlwaysShowMessage; // Show a text message to nearby players even when the doors are sealed /  the trigger is not useable
var () string LockedMessage,UnLockedMessage,WeldedShutMessage;
var () sound LockedSound,UnLockedSound ;  // The SFX for trying to open a locked door, and unlocking it.



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
function UsedBy( Pawn user )
{
	local int i;
	local Inventory inv;

	if( (Level.TimeSeconds-LastAttempt)<RefireDelay || User.IsA('KFMonster') )
		Return;

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


		if( DoorOwners[i].bKeyLocked && !DoorOwners[i].bSealed && !DoorOwners[i].bHidden && DoorOwners[i].bClosed)
		{
			if( PlayerController(user.controller)!=None )
				PlayerController(user.controller).ClientMessage(LockedMessage, 'CriticalEvent');
			PlaySound(LockedSound,,255,,100);
			LastAttempt = Level.TimeSeconds;
		}
		if( DoorOwners[i].bKeyLocked && !DoorOwners[i].bSealed && !DoorOwners[i].bHidden && !DoorOwners[i].bClosed )
		{
			for( inv=user.Inventory; inv!=None; inv=inv.Inventory)
			{
				if( inv.IsA('KFKeyInventory') && inv.tag==DoorOwners[i].tag )
				{
					DoorOwners[i].Trigger(Self,User);
					if( PlayerController(user.controller)!=None )
						PlayerController(user.controller).ClientMessage(UnLockedMessage, 'CriticalEvent');
					PlaySound(UnLockedSound,,255,,100);
					DoorOwners[i].bKeyLocked = false;
					LastAttempt = Level.TimeSeconds;
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
		if( KFMonster(Other)!=none || KFInvasionBot(Pawn(Other).Controller) != none )
		{
			if( !DoorOwners[i].bKeyLocked && !DoorOwners[i].bSealed && !DoorOwners[i].bHidden )
				DoorOwners[i].GotoState( , 'Open' );
		}
		else if ( !DoorOwners[i].bSealed && !DoorOwners[i].bHidden )
		{
			// Send a string message to the toucher.
			if(PlayerController(Pawn(Other).Controller)!=none)
			{
				if( Message!="" )
					PlayerController(Pawn(Other).Controller).ClientMessage(Message, 'CriticalEvent');
			}
			else if ( DoorOwners[i].bClosed && Pawn(Other).Controller!=None )
				UsedBy(Pawn(Other));
		}
		else if( !DoorOwners[i].bHidden && bAlwaysShowMessage && PlayerController(Pawn(Other).Controller)!=none && Message!="" )
			PlayerController(Pawn(Other).Controller).ClientMessage(Message, 'CriticalEvent');
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

function UnWeld(float DeWeldage,bool bZombieAttacking)
{
	local int i;

	if (bZombieAttacking)
		DeWeldage *= CombatSealReduction;

//	if( DeWeldage<WeldStrength )
	//	DeWeldage = WeldStrength;
	if( DeWeldage==0 )
		Return;
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

	if( WeldStrength<=0 )
	{
		WeldStrength = 0;
		For( i=0; i<DoorOwners.Length; i++ )
		{
			DoorOwners[i].SetWeldStrength(0);
			DoorOwners[i].GoBang(instigatedBy,hitlocation,momentum,damageType);
		}
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
     MaxWeldStrength=400.000000
     CombatSealReduction=0.500000
     LockedMessage="This door is locked. Looks like it needs a key.."
     UnLockedMessage="Your Key unlocked the door."
     WeldedShutMessage="This door is welded shut..."
     LockedSound=Sound'PatchSounds.LockedDoorSound'
     UnLockedSound=Sound'PatchSounds.DoorUnlockSound'
}
