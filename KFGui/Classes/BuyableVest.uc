//-----------------------------------------------------------
//
//-----------------------------------------------------------
class BuyableVest extends BuyablePowerup;

function bool CanUseThis(Pawn p)
{
	if (p == None)
		return false;
	return (p.ShieldStrength<100);
}

function bool HasMe(Pawn p)
{
	return (p.ShieldStrength>0);
}

function BuyMe( KFPawn P )
{
	P.ServerBuyKevlar();
}

defaultproperties
{
     myShowMesh=StaticMesh'KillingFloorStatics.Vest'
     cost=300
     ItemName="Combat armour"
     Description="Kevlar vest. Affords the wearer limited protection from most forms of attack.                                                                                ARMOUR + 50"
}
