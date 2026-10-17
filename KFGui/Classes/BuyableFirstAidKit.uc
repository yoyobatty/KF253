//-----------------------------------------------------------
//
//-----------------------------------------------------------
class BuyableFirstAidKit extends BuyablePowerup;

function bool CanUseThis(Pawn p)
{
    if (p == None)
      return false;

    return( p.Health<p.HealthMax);
}
function bool HasMe(Pawn p)
{
	return True;
}
function BuyMe( KFPawn P )
{
	P.ServerBuyFirstAid();
}

defaultproperties
{
     myShowMesh=StaticMesh'KillingFloorStatics.FirstAidKit'
     cost=150
     ItemName="First Aid Kit"
     Description="Contains morphine, bandages, anti-biotics, and a variety of other goodies to bring a wounded soldier back up to speed.                                                                                Heals to full health. The price depends on how much health is missing."
}
