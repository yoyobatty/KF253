class KFBarricade extends Trigger
	placeable;

var() name PlankTag;
var array<KFBarricadePlank> Planks;
var float ScanInterval;
var() int RepairReward;
var() float FirstRepairDelay;
var() float RepairInterval;
var float LastMessageTimer;
var bool bBeingRepaired;
var Pawn Repairer;
var float LastAccumulateUseTime;
var float NextRepairTime;
var KFBarricadePlank PendingPlank;
var() string RepairPromptMessage;

function ShowRepairPrompt( Pawn P )
{
	if( P.Health<=0 || PlayerController(P.Controller)==None )
		Return;

	if( KFHumanPawnZombies(P)!=None )
	{
		if( !KFHumanPawnZombies(P).bIsDowned )
			KFHumanPawnZombies(P).SetUsePrompt(RepairPromptMessage);
	}
	else if( LastMessageTimer<Level.TimeSeconds )
	{
		LastMessageTimer = Level.TimeSeconds + 0.6;
		PlayerController(P.Controller).ClientMessage(RepairPromptMessage, 'CriticalEvent');
	}
}

function Touch( Actor Other )
{
	local Pawn P;

	P = Pawn(Other);
	if( P == None || P.IsA('KFMonster') || AllPlanksFull() )
		Return;

	ShowRepairPrompt(P);
}

function AccumulateUse( Pawn user, float DeltaTime )
{
	if( user == None || user.Health <= 0 || user.IsA('KFMonster') || AllPlanksFull() )
		Return;
	if( KFHumanPawn(user)!=None && KFHumanPawn(user).bIsDowned )
		Return;

	if( !bBeingRepaired || Repairer!=user )
	{
		Repairer = user;
		bBeingRepaired = true;
		NextRepairTime = Level.TimeSeconds + FirstRepairDelay;
		PendingPlank = None;
	}

	LastAccumulateUseTime = Level.TimeSeconds;

	if( PendingPlank==None )
		PendingPlank = FindWorstPlank();

	if( PendingPlank==None )
		Return;

	if( PendingPlank.Health<=0 )
	{
		if( Level.TimeSeconds >= NextRepairTime )
			PendingPlank.StartRegrow(user);
		Return;
	}

	if( Level.TimeSeconds >= NextRepairTime )
	{
		PendingPlank.FinishRepair(PendingPlank.MaxHealth);
		AwardRepair();
		PendingPlank = None;
		NextRepairTime = Level.TimeSeconds + RepairInterval;
	}
}

function OnRegrowComplete(KFBarricadePlank P)
{
	AwardRepair(P.RegrowRepairer);

	if( P==PendingPlank )
	{
		PendingPlank = None;
		NextRepairTime = Level.TimeSeconds + RepairInterval;
	}
}

function AwardRepair( optional Pawn ForRepairer )
{
	local Pawn R;

	R = ForRepairer;
	if( R==None )
		R = Repairer;

	if( RepairReward<=0 || R==None || R.Controller==None || R.Controller.PlayerReplicationInfo==None )
		Return;
	if( KFZombiesGameType(Level.Game)!=None )
		KFZombiesGameType(Level.Game).AwardPoints(R.Controller, RepairReward);
	else R.Controller.PlayerReplicationInfo.Score += RepairReward;
}

function KFBarricadePlank FindWorstPlank()
{
	local int i, worstIndex;
	local float worstHealth;

	worstIndex = -1;
	worstHealth = 999999;
	For( i=0; i<Planks.Length; i++ )
	{
		if( Planks[i].Health < Planks[i].MaxHealth && Planks[i].Health < worstHealth )
		{
			worstHealth = Planks[i].Health;
			worstIndex = i;
		}
	}

	if( worstIndex==-1 )
		Return None;

	Return Planks[worstIndex];
}

function PostBeginPlay()
{
	local KFBarricadePlank P;

	Super.PostBeginPlay();

	if( PlankTag!='' )
	{
		foreach DynamicActors(class'KFBarricadePlank', P)
		{
			if( P.Tag==PlankTag )
			{
				Planks[Planks.Length] = P;
				P.OwningBarricade = Self;
			}
		}
	}

	SetTimer(ScanInterval, true);
}

function OnPlankDestroyed(KFBarricadePlank P)
{
}

function bool AllPlanksFull()
{
	local int i;

	For( i=0; i<Planks.Length; i++ )
	{
		if( Planks[i].Health < Planks[i].MaxHealth )
			Return false;
	}
	Return true;
}

function bool AllPlanksDestroyed()
{
	local int i;

	if( Planks.Length==0 )
		Return true;

	For( i=0; i<Planks.Length; i++ )
	{
		if( !Planks[i].bDestroyed )
			Return false;
	}
	Return true;
}

function KFBarricadePlank NearestIntactPlank(vector FromLoc)
{
	local int i;
	local KFBarricadePlank Best;
	local float BestDist, D;

	BestDist = 999999999.0;
	For( i=0; i<Planks.Length; i++ )
	{
		if( Planks[i].bDestroyed || Planks[i].bHidden )
			Continue;
		D = VSize(Planks[i].Location - FromLoc);
		if( D < BestDist )
		{
			BestDist = D;
			Best = Planks[i];
		}
	}
	Return Best;
}

function ScanForZombies()
{
	local KFMonster ZM;
	local KFMonsterController C;
	local KFBarricadePlank Target;

	foreach CollidingActors(class'KFMonster', ZM, CollisionRadius)
	{
		if( ZM.Health<=0 )
			Continue;

		C = KFMonsterController(ZM.Controller);
		if( C==None )
			Continue;

		if( C.TargetPlank!=None && !C.TargetPlank.bDestroyed && C.TargetPlank.OwningBarricade==Self && C.IsInState('BarricadeBashing') )
			Continue;

		Target = NearestIntactPlank(ZM.Location);
		if( Target!=None )
			C.BreakUpBarricade(Target);
	}
}

function StopRepairing()
{
	bBeingRepaired = false;
	Repairer = None;

	if( PendingPlank!=None && !PendingPlank.bRegrowing )
		PendingPlank = None;
}

function Timer()
{
	local KFHumanPawnZombies ZP;

	ScanForZombies();

	if( bBeingRepaired && (Repairer==None || Repairer.Health<=0 || (Level.TimeSeconds-LastAccumulateUseTime) > 0.6) )
		StopRepairing();

	if( !AllPlanksFull() )
	{
		ForEach TouchingActors(class'KFHumanPawnZombies', ZP)
			ShowRepairPrompt(ZP);
	}
}

defaultproperties
{
	RepairPromptMessage="Hold [USE] to repair"
	RepairReward=10
	FirstRepairDelay=0.700000
	RepairInterval=0.500000
	CollisionRadius=70.000000
	ScanInterval=0.500000
}
