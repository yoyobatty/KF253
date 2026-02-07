Class FootstepNoiseMaker extends Info
	transient;

var MonsterAIManager Manager;
var Pawn PawnOwner;

function PostBeginPlay()
{
	PawnOwner = Pawn(Owner);
	if( PawnOwner==none )
		Destroy();
	else SetTimer(0.35+FRand()*0.25,true);
}
function Timer()
{
	if( PawnOwner==None || PawnOwner.Health<=0 )
	{
		Destroy();
		return;
	}
	if( VSize(PawnOwner.Acceleration)<10.f || PawnOwner.Physics!=PHYS_Walking )
		return;
	if( PawnOwner.bIsCrouched || PawnOwner.bIsWalking )
		PawnOwner.MakeNoise(0.025f);
	else PawnOwner.MakeNoise(0.15f);
}

defaultproperties
{
}
