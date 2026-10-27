// A keycard, disk or other story item: taken by touch, it fires its Event. (1.0 made these ammo pickups, which
// KFMod254 only lets a player take with a gun for that ammo.)
class CampaignKeyCard extends Pickup;

function bool CanTake( Actor Other )
{
	local Pawn P;

	P = Pawn(Other);
	return P!=None && P.Health>0 && PlayerController(P.Controller)!=None;
}

function Take( Pawn P )
{
	PlayerController(P.Controller).ClientMessage(PickupMessage, 'CriticalEvent');
	PlaySound(PickupSound, SLOT_Interact);
	TriggerEvent(Event, self, P);
	Destroy();
}

// (also by reach, checked ten times a second: a player who lands on the card does not always touch it)
function Pawn PlayerInReach()
{
	local Controller C;
	local vector D;

	for( C=Level.ControllerList; C!=None; C=C.NextController )
		if( PlayerController(C)!=None && C.Pawn!=None && C.Pawn.Health>0 )
		{
			D = C.Pawn.Location - Location;
			if( Abs(D.Z)<=C.Pawn.CollisionHeight+CollisionHeight && D.X*D.X+D.Y*D.Y<=Square(C.Pawn.CollisionRadius+CollisionRadius) )
				return C.Pawn;
		}
	return None;
}

auto state Pickup
{
	function Touch( Actor Other )
	{
		if( CanTake(Other) )
			Take(Pawn(Other));
	}

	function Timer()
	{
		local Pawn P;

		P = PlayerInReach();
		if( P!=None )
			Take(P);
	}

Begin:
	SetTimer(0.1, true);
}

defaultproperties
{
	PickupMessage="You got the Sector B keycard"
	PickupSound=Sound'KF10PlayerSound.getweaponout3'
	DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'KF10LabStatics.KeyCard1'
	DrawScale=0.150000
	CollisionRadius=30.000000
	CollisionHeight=30.000000
	AmbientGlow=40
	bStasis=False
}
