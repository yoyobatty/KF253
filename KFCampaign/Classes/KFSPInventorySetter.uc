// Training: when triggered, takes up to two items from the player and gives up to two (KFMod 1.0).
class KFSPInventorySetter extends Actor
	placeable;

var() class<Inventory> toDelOne, toDelTwo, toAddOne, toAddTwo;

function Trigger( Actor Other, Pawn EventInstigator )
{
	local Controller C;

	for( C=Level.ControllerList; C!=None; C=C.NextController )
		if( PlayerController(C)!=None && C.Pawn!=None && C.Pawn.Health>0 )
		{
			TakeItem(C.Pawn, toDelOne);
			TakeItem(C.Pawn, toDelTwo);
			if( toAddOne!=None )
				C.Pawn.CreateInventory(string(toAddOne));
			if( toAddTwo!=None )
				C.Pawn.CreateInventory(string(toAddTwo));
		}
}

function TakeItem( Pawn P, class<Inventory> IC )
{
	local Inventory Inv;

	if( IC==None )
		return;
	Inv = P.FindInventoryType(IC);
	if( Inv!=None )
		Inv.Destroy();
}

defaultproperties
{
	bHidden=True
	DrawScale=1.500000
}
