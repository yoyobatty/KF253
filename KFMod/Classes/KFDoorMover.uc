// This is a special Door mover which can be "sealed" if in a closed state.
// By: Alex
// Fixed by .:..:
class KFDoorMover extends Mover;

#exec OBJ LOAD FILE="..\StaticMeshes\PatchStatics.usx"

var bool bSealed;
var float WeldStrength;
var float MaxWeld;
var float Health;  // How much life does the door have when Unwelded?
var () bool bNoSeal;
var () bool bElevOuterDoorTop, bElevOuterDoorBottom;
var () bool bStartSealed;  // Just like it sounds.
var () float StartSealedWeldPrc; // Start welded percent.
var () bool bSmallArmsDamage; // If true, this door will take damage from non explosive weapons 
var () bool bKeyLocked; // Is the door locked to a specific key item?
var() edfindable NavigationPoint DoorPathNode;
var () bool bDisallowWeld; // no welding..

var KFUseTrigger MyTrigger;

var float LastZombieHitSoundTime;   // The last time we played a zombie hit sound for this door.
var Sound ZombieHitSound[4]; // Randomize

var() class<DoorExplode> ExplodeClass;
var DoorExplode DoorBoom;


var () float ZombieDamageReductionFactor; // Multiply the base damage the door takes by this amount (less than one, or it will take MORE dmg)
var bool bZedHittingDoor; // when true, our welder is ALOT less effective at sealing the door shut. This will help
						   // resolve a noted issue where a small team is able to keep a door up against a hoard of zombies - indefinitely.

var float LastZombieDamageTime; // when was the last time we took damage from a zed? (used to resolve bZedHittingDoor in the timer func)
var float PathUdpTimer;
var int InitExtraCost;

var vector DieVect;

var () bool bZombiesIgnore;  // if true, zombies ignore this door, when its welded.
var bool bShouldBeOpen;

replication
{
	reliable if( ROLE==ROLE_AUTHORITY )
		WeldStrength,MaxWeld,DieVect;
}

function PostBeginPlay()
{
	local KFUseTrigger KFUTit;
	local NavigationPoint N;
	local int i;
	local float D;
	local vector HL,HN;

	if( DoorPathNode==None ) // Attempt to find one passing through this doorway.
	{
		For( N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint )
		{
			D = VSize(N.Location-Location);
			if( D<800 )
			{
				For( i=0; i<N.PathList.Length; i++ )
				{
					if( N.PathList[i].End==None )
						Continue; // Should happen.. but what the heck...
					if( TraceThisActor(HL,HN,N.PathList[i].End.Location,N.Location) )
						Continue; // This path isnt passing through this doorway..
					if( D<VSize(N.PathList[i].End.Location-Location) )
						DoorPathNode = N;
					else DoorPathNode = N.PathList[i].End; // Pick the node closer to door.
					Break;
				}
				if( DoorPathNode!=None )
					Break;
			}
		}
	}
	if( DoorPathNode!=None )
	{
		InitExtraCost = DoorPathNode.ExtraCost;
		PathUdpTimer = Level.TimeSeconds+FRand(); // Randomize this to improve preformace.
	}
	else Disable('Tick');

	foreach DynamicActors(class'KFUseTrigger', KFUTit)
	{
		if( KFUTit.Event==Tag )
		{
			if(MyTrigger!=none)
				Warn("Multiple triggers found!");
			MyTrigger = KFUTit;
			KFUTit.AddDoor(Self);
			MaxWeld = MyTrigger.MaxWeldStrength;
			Health = MaxWeld;
		}
	}

	// Establish hit Sounds based on material
	if (SurfaceType == EST_Metal)
	{
		ZombieHitSound[0] = Sound 'PatchSounds.DHitMetal1';
		ZombieHitSound[1] = Sound 'PatchSounds.DHitMetal2';
		ZombieHitSound[2] = Sound 'PatchSounds.DHitMetal3';
		ZombieHitSound[3] = Sound 'PatchSounds.DHitMetal4';
	}

	if( bStartSealed )
	{
		bSealed = true;
		MyTrigger.WeldStrength = 0;
		MyTrigger.AddWeld(MaxWeld*(StartSealedWeldPrc/100.f),False,None);
	}
	super.PostBeginPlay();
}
function PlayZombieHitSound()
{
	LastZombieHitSoundTime = Level.TimeSeconds;
	PlaySound(ZombieHitSound[rand(ArrayCount(ZombieHitSound))],SLOT_None, 255, false,200,,true); //, SoundPitch / 64.0);
}
function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,Vector momentum, class<DamageType> damageType)
{
	if( bHidden || instigatedBy==None || MyTrigger==None )
		Return; // Or else we see a lot of warnings on log.
	if (bNoSeal)
	{
		if ( bDamageTriggered && (Damage >= DamageThreshold) )
		{
			if ( (AIController(instigatedBy.Controller) != None)
			 && (instigatedBy.Controller.Focus == self) )
				instigatedBy.Controller.StopFiring();
			Trigger(self, instigatedBy);
			if ( (AIController(instigatedBy.Controller) != None) && (instigatedBy.Controller.Target == self) )
				instigatedBy.Controller.StopFiring();
			
			if (bTriggerOnceOnly)
				bDamageTriggered = false;
		}
	}
	if (!instigatedBy.IsA('KFMonster') && damageType != class'DamTypeWelder' && damageType != class'DamTypeUnWeld')
	{
		if(!bSmallArmsDamage && damageType != class'DamTypeFrag' || Damage < DamageThreshold )
			return;
	}

	// Hack for damage reduction with zombies : Alex
	if ( instigatedBy.IsA('KFMonster') && instigatedBy!=none )
	{
		Damage*= ZombieDamageReductionFactor;
		Damage = Max(3,Damage); // Do at LEAST 3 damage per hit.
		LastZombieDamageTime = Level.TimeSeconds;
		bZedHittingDoor = true;
		if ((Level.TimeSeconds - LastZombieHitSoundTime) >= 0.5)
			PlayZombieHitSound();
	}
	//Unsealed damage-dealing.
	if (!bSealed)
	{
		Damage *= 0.5;
		Health -= Damage;
	
		if( Damage >= Health )
			GoBang(instigatedBy,hitlocation,momentum,damageType);
	}

	if ( bClosed && damageType == class 'DamTypeWelder'  && !bDisallowWeld)
	{
		bSealed = true;
		MyTrigger.AddWeld(damage,bZedHittingDoor,instigatedBy);
	}
	else if(bSealed)
	{
		if( damageType==class'DamTypeUnWeld' )
			MyTrigger.UnWeld(damage,bZedHittingDoor,instigatedBy);
		else MyTrigger.DamageWeld(damage,instigatedBy,hitlocation,momentum,damageType);
	}
}
function Bump( Actor Other )
{
	Super.Bump(Other);
	if( (bSealed || bClosed) && KFMonster(Other)!=None ) // Notify zombie to break this door.
		KFMonsterController(KFMonster(Other).Controller).BreakUpDoor(Self);
	else if( bSealed && bStartSealed && Pawn(Other)!=None && KFInvasionBot(Pawn(Other).Controller)!=None )
		KFInvasionBot(Pawn(Other).Controller).SealUpDoor(Self);
}
function SetWeldStrength(float NewStrength)
{
	WeldStrength = NewStrength;
	if(WeldStrength>0)
		bSealed = true;
	else 
        {
          bSealed = false;
          if (UV2Texture != none)
           UV2Texture = none;
        }
}

function GoBang(pawn instigatedBy, vector hitlocation,Vector momentum, class<DamageType> damageType)
{
	SetCollision(false,false,false);
	bHidden = true;
	DieVect = hitlocation-instigatedBy.location;
	if( Level.NetMode==NM_DedicatedServer || (Level.TimeSeconds-LastRenderTime)>5 )
		Return;
	ExplodeClass.Static.Boom(Self,rotator(momentum));
}

simulated event PostNetReceive()
{
	if( DieVect!=vect(0,0,0) )
	{
		ExplodeClass.Static.Boom(Self,rotator(DieVect));
		DieVect = vect(0,0,0);
	}
}
simulated function Timer()
{
	Super.Timer();
	if(Level.TimeSeconds - LastZombieDamageTime > 1.0) // reset our bool if it's not taking anymore dmg after one second.
		bZedHittingDoor = false;
}
function Tick( float Delta )
{
	if( DoorPathNode!=None && PathUdpTimer<Level.TimeSeconds )
	{
		PathUdpTimer = Level.TimeSeconds+0.5;
		DoorPathNode.ExtraCost = InitExtraCost;
		if( bSealed )
		{
			if(MyTrigger != none)
				DoorPathNode.ExtraCost+=500+MyTrigger.WeldStrength*6;
		}                  
	}
}

function RespawnDoor()
{
	if( bHidden )
	{
		bHidden = false;
		SetCollision(true, true, true);
		DieVect = vect(0,0,0);
		Reset();
		if( bShouldBeOpen )
		{
			if( KeyNum!=(NumKeys-1) )
				InterpolateTo(NumKeys-1,0.001);
		}
		else if( KeyNum!=0 )
			InterpolateTo(0,0.001);
		if( bStartSealed )
		{
			bSealed = true;
			MyTrigger.WeldStrength = 0;
			MyTrigger.AddWeld(MaxWeld*(StartSealedWeldPrc/100.f),False,None);
		}
	}
	Health = MaxWeld;
}

function MakeGroupStop()
{
	MakeGroupReturn();
}
function DoOpen()
{
	if( bSealed || bHidden )
	{
		bShouldBeOpen = True;
		Return;
	}
	Super.DoOpen();
}
function DoClose()
{
	if( bSealed || bHidden )
	{
		bShouldBeOpen = False;
		Return;
	}
	Super.DoClose();
}
function FinishedOpening()
{
	if( bSealed || bHidden )
		FinishNotify();
	else Super.FinishedOpening();
}
function FinishedClosing()
{
	if( bSealed || bHidden )
		FinishNotify();
	else Super.FinishedClosing();
}

defaultproperties
{
	StartSealedWeldPrc=50.000000
	ZombieHitSound(0)=Sound'PatchSounds.DHitMetal1'
	ZombieHitSound(1)=Sound'PatchSounds.DHitMetal2'
	ZombieHitSound(2)=Sound'PatchSounds.DHitMetal3'
	ZombieHitSound(3)=Sound'PatchSounds.DHitMetal4'
	ExplodeClass=Class'KFMod.DoorExplodeMetalStandard'
	ZombieDamageReductionFactor=0.750000
	MoverEncroachType=ME_IgnoreWhenEncroach
	StayOpenTime=5.000000
	DamageThreshold=50.000000
	InitialState="TriggerToggle"
	CollisionRadius=0.000000
	CollisionHeight=0.000000
	bBlockKarma=True
	bNetNotify=True
	bPathColliding=False
}
