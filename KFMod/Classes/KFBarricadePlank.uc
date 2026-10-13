class KFBarricadePlank extends Actor
	placeable;

var() float MaxHealth;
var float Health;
var bool bDestroyed;
var KFBarricade OwningBarricade;
var float ZombieDamageReductionFactor;
var bool bInitialCollideActors, bInitialBlockActors;
var() class<Emitter> RegrowEffectClass;
var() float RegrowEffectDuration;
var bool bRegrowing;
var Pawn RegrowRepairer;
var bool bClientRegrowShown;

replication
{
	reliable if( ROLE==ROLE_AUTHORITY )
		bDestroyed, Health, bRegrowing;
}

simulated function PostNetReceive()
{
	if( bRegrowing && !bClientRegrowShown )
	{
		bClientRegrowShown = true;
		Spawn(RegrowEffectClass, Self,, Location, Rotation);
	}
	else if( !bRegrowing )
		bClientRegrowShown = false;
}

function PostBeginPlay()
{
	Super.PostBeginPlay();
	bInitialCollideActors = bCollideActors;
	bInitialBlockActors = bBlockActors;
	Health = MaxHealth;
}

function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation, Vector momentum, class<DamageType> damageType )
{
	if( bHidden || bDestroyed || instigatedBy==None )
		Return;

	if( instigatedBy.IsA('KFMonster') )
	{
		Damage = Max(10, Damage);
	}
	else return;

	Health -= Damage;
	if( Health<=0 )
		DestroyPlank();
}

function DestroyPlank()
{
	Health = 0;
	bDestroyed = true;
	bHidden = true;
	SetCollision(false, false, false);
	NetUpdateTime = Level.TimeSeconds - 1;
	if( OwningBarricade!=None )
		OwningBarricade.OnPlankDestroyed(Self);
}

function StartRegrow( optional Pawn User )
{
	if( Health>0 || bRegrowing || !bDestroyed )
		Return;

	bRegrowing = true;
	bDestroyed = false;
	bHidden = true;
	RegrowRepairer = User;
	SetCollision(false, false, false);
	if( Level.NetMode!=NM_DedicatedServer )
		Spawn(RegrowEffectClass, Self,, Location, Rotation);
	NetUpdateTime = Level.TimeSeconds - 1;
	SetTimer(RegrowEffectDuration, false);
}

function FinishRepair(float Amount)
{
	Health = FMin(MaxHealth, Health+Amount);
	NetUpdateTime = Level.TimeSeconds - 1;
}

function Timer()
{
	bHidden = false;
	SetCollision(bInitialCollideActors, bInitialBlockActors, bInitialBlockActors);
	bDestroyed = false;
	bRegrowing = false;
	FinishRepair(MaxHealth);
	if( OwningBarricade!=None )
		OwningBarricade.OnRegrowComplete(Self);
}

function InstantRepair()
{
	if( bRegrowing )
	{
		SetTimer(0, false);
		Timer();
		Return;
	}

	if( bDestroyed )
	{
		bHidden = false;
		SetCollision(bInitialCollideActors, bInitialBlockActors, bInitialBlockActors);
		bDestroyed = false;
	}
	FinishRepair(MaxHealth);
}

function Bump( Actor Other )
{
	Super.Bump(Other);

	if( bDestroyed )
		Return;

	if( KFMonster(Other)!=None && KFMonsterController(KFMonster(Other).Controller)!=None )
		KFMonsterController(KFMonster(Other).Controller).BreakUpBarricade(Self);
	else if( ExtendedZCollision(Other)!=None && Other.Base!=None && KFMonster(Other.Base)!=None && KFMonsterController(KFMonster(Other.Base).Controller)!=None )
		KFMonsterController(KFMonster(Other.Base).Controller).BreakUpBarricade(Self);
}

defaultproperties
{
	RegrowEffectClass=class'KFMod.KFPlankRegrowEffect'
	RegrowEffectDuration=0.800000
	MaxHealth=50.000000
	bCollideActors=True
	bBlockActors=True
	bBlockPlayers=True
	bPathColliding=False
	bStatic=False
	bNoDelete=True
	bAlwaysRelevant=True
	bNetNotify=True
}
