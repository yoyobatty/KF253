//-----------------------------------------------------------
//
//-----------------------------------------------------------
class KFRandomSpawn extends xPickUpBase abstract;

var() class<Pickup> PickupClasses[11];
var() int PickupWeight[11];

var() bool bSequential;

var() bool bForceDefault;

var int NumClasses;
var int CurrentClass;

var int WeightTotal;

var float InitialWaitTime;
var float ReTryWaitTime;

simulated function PostBeginPlay()
{
	local int i;

	if ( Level.NetMode!=NM_Client )
	{
		NumClasses = 0;

		if(bForceDefault)
		{
			for(i=0; i<ArrayCount(PickupClasses); ++i)
			{
				PickupClasses[i] = default.PickupClasses[i];
				PickupWeight[i] = default.PickupWeight[i];
			}
		}

		for(i=0; i<ArrayCount(PickupClasses) && PickupClasses[NumClasses] != none; ++i)
		{
			NumClasses++;
			if( PickupWeight[i]==0 )
				PickupWeight[i]=1;
			WeightTotal+=PickupWeight[i];
		}
		CurrentClass=GetWeightedRandClass();
		PowerUp = PickupClasses[CurrentClass];
	}
	if ( Level.NetMode != NM_DedicatedServer )
	{
		for ( i=0; i< NumClasses; i++ )
			PickupClasses[i].static.StaticPrecache(Level);
	}
	Super.PostBeginPlay();
	SetLocation(Location + vect(0,0,-1)); // adjust because reduced drawscale
}

function int GetWeightedRandClass()
{
	local int RandIndex;
	local int Tally;
	local int i;

	RandIndex = rand(WeightTotal+1); // rand always returns a value between 0 and max-1

	Tally = PickupWeight[0];

	while(Tally<RandIndex)
	{
		++i;
		Tally+=PickupWeight[i];
	}
	return i;
}

function TurnOn()
{
	CurrentClass=GetWeightedRandClass();

	PowerUp = PickupClasses[CurrentClass];

	if( myPickup != none )
		myPickup.Destroy();

	SpawnPickup();
	SetTimer(InitialWaitTime+InitialWaitTime*FRand(), false);
}

function SpawnPickup()
{
	local Rotator AdjustedRotation;

	AdjustedRotation = self.Rotation;
	AdjustedRotation.Pitch = rand(10000) + 1000;

	if( PowerUp == None )
		return;

	myPickUp = Spawn(PowerUp,,,Location + SpawnHeight * vect(0,0,1), AdjustedRotation);

	if (myPickUp != None)
	{
		myPickUp.PickUpBase = self;
		myPickup.Event = event;
<<<<<<< HEAD
=======
		mypickup.RespawnTime = 0;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	}

	if (myMarker != None)
	{
		myMarker.markedItem = myPickUp;
		myMarker.ExtraCost = ExtraPathCost;
		if (myPickUp != None)
			myPickup.MyMarker = MyMarker;
	}
	SetTimer(InitialWaitTime+InitialWaitTime*FRand(), false);
}

function timer()
{
	if( myPickup!=none && myPickup.IsInState('Sleeping') )
		return;

	if(!PlayersCanSeeMe())
		TurnOn();
	else SetTimer(ReTryWaitTime+ReTryWaitTime*FRand(), false);
}

function bool PlayersCanSeeMe()
{
	local controller C;

	for( C=level.ControllerList; C!=none; C=C.nextController)
	{
		if( C.bIsPlayer && C.Pawn!=none && VSize(C.Pawn.Location-Location)<2000 )
		{
			if( FastTrace(C.Pawn.Location) )
				return true;
		}
	}
	return false;
}

defaultproperties
{
<<<<<<< HEAD
	bForceDefault=True
	InitialWaitTime=20.000000
	ReTryWaitTime=5.000000
	SpawnHeight=0.000000
	DrawType=DT_Sprite
	bStatic=False
	bHidden=True
	DrawScale=0.500000
	CollisionRadius=60.000000
	CollisionHeight=6.000000
=======
     bForceDefault=True
     InitialWaitTime=20.000000
     ReTryWaitTime=5.000000
     SpawnHeight=0.000000
     DrawType=DT_Sprite
     bStatic=False
     bHidden=True
     DrawScale=0.500000
     CollisionRadius=60.000000
     CollisionHeight=6.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
