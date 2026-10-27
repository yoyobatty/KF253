class KFZombiesPowerUp extends Actor
	abstract;

var() string PickupMessage;
var() sound PickupSound;
var() float BlinkTime, BlinkInterval;

var bool bTaken;

function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(BlinkInterval, true);
}

function Timer()
{
	if( LifeSpan>0 && LifeSpan<BlinkTime )
		bHidden = !bHidden;
}

function Activate( KFHumanPawn P, KFEndlessGameType G );

function Touch( Actor Other )
{
	local KFHumanPawn P;
	local KFEndlessGameType G;

	// (Zombies and Endless both drop them: KFEndlessGameType.TryDropPowerUp)
	P = KFHumanPawn(Other);
	G = KFEndlessGameType(Level.Game);
	if( bTaken || P==None || G==None || P.Health<=0 || P.bIsDowned || P.Controller==None || !P.Controller.bIsPlayer )
		Return;

	bTaken = true;
	Activate(P, G);
	G.PowerUpMessage(PickupMessage);
	if( PickupSound!=None )
		P.PlaySound(PickupSound,,255,,500);
	Destroy();
}

defaultproperties
{
	BlinkTime=6.000000
	BlinkInterval=0.250000
	PickupSound=Sound'PickupSounds.UDamagePickup'
	DrawType=DT_StaticMesh
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
	LifeSpan=30.000000
	Physics=PHYS_Rotating
	bFixedRotationDir=True
	RotationRate=(Yaw=24000)
	bUnlit=True
	bDynamicLight=True
	LightType=LT_Steady
	LightBrightness=200.000000
	LightRadius=6.000000
	LightSaturation=60
	CollisionRadius=40.000000
	CollisionHeight=40.000000
	bCollideActors=True
}
