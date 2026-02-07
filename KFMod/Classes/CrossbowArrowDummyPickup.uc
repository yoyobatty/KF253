class CrossbowArrowDummyPickup extends CrossbowAmmoPickup
	cacheexempt;

var CrossbowArrow ArrowRef;

simulated function PostBeginPlay()
{
    default.PickupMSG1 = "Found ("$AmmoAmount$") ";
}

function AnnouncePickup( Pawn Receiver )
{
	Super.AnnouncePickup( Receiver );
	if(ArrowRef != None)
	{
		ArrowRef.DummyPickupRef = None;
		ArrowRef.Destroy();
	}
}

function InitDroppedPickupFor(Inventory Inv)
{
	SetPhysics(PHYS_None);
	Inventory = Inv;
	bAlwaysRelevant = false;
	bOnlyReplicateHidden = false;
	bUpdateSimulatedPosition = true;
    bDropped = true;
	bIgnoreEncroachers = false; // handles case of dropping stuff on lifts etc
	NetUpdateFrequency = 8;
	LifeSpan = ArrowRef.Lifespan;
	SetCollisionSize(25,20);
}

defaultproperties
{
    AmmoAmount=1
	Physics=PHYS_None
	StaticMesh=None 
	DrawType=DT_None
	CollisionRadius=0.000000
	CollisionHeight=0.000000
}