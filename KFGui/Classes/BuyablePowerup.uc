class BuyablePowerup extends GUIBuyable
	abstract;

function bool ShowMe(Pawn p, eSaleCat index, GUIBuyMenu ParentMenu)
{
	if(index != SALE_Equipment)
		return false;
	return CanUseThis(p);
}

function bool CanBuyMe(PlayerController pc)
{
	return Super.CanBuyMe(pc) && CanUseThis(pc.pawn);
}

function bool CanUseThis(pawn aPawn)
{
	return false;
}

defaultproperties
{
     InfoPanel=Class'KFGui.GUIBuyDescInfoPanel'
     infoDrawRotation=(Pitch=0,Yaw=-35000,Roll=0)
     infoDrawOffset=(X=50.000000,Y=0.000000,Z=-20.000000)
     infoDrawScale=0.750000
}
