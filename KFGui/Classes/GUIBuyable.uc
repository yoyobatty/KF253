class GUIBuyable extends Object;

var Mesh showMesh;              //Mesh to show in Info
var StaticMesh myShowMesh;      //Actual staticmesh to show in info
var float cost;                   //Cost to buy
var float weight;                 //Heaviness
var class<GUIPanel> InfoPanel;  //Panel to show Info in- should actually be KFInfoPanel
var class<Inventory> relatedInventory; //For inventory sellables,
									   //the associated class.

var rotator infoDrawRotation;          //Rotation in the Info panel
var vector infoDrawOffset;             //Offset in the info panel
var float infoDrawScale;               //Generally, size
var int infoSpinRate;                  //rate our weapon spins at.  0 by default.
                                        //alex, change the damn default.

var string ItemName;            //Sale name of object
var string Description;         //Flavor text, etc.

enum eSaleCat
{
	SALE_Personal,
	SALE_Melee,
	SALE_Power,
	SALE_Speed,
	SALE_Range,
	SALE_Ammo,
	SALE_Equipment,
	SALE_Upgrades
};

//We might want different panel types for different
//categories.
function class<GUIPanel> GetPanelType(eSaleCat category)
{
	return InfoPanel;
}

function bool CanButtonMe(PlayerController pc,bool buying)
{
	if(buying)
		return CanBuyMe(pc);
	else
		return CanSellMe(pc);
}

function bool CanBuyMe(PlayerController pc)
{
	if(KFPlayerController(pc) == None || KFHumanPawn(pc.Pawn) == None)
		return false;
	return true;
}

function bool CanSellMe(PlayerController pc)
{
	if(KFPlayerController(pc) == None || KFHumanPawn(pc.Pawn) == None)
		return false;
	return true;
}

function string GetBuyCaption(eSaleCat index)
{
	if(index == SALE_Personal)
		return "Sell";
	else
		return "Buy";
		
	if(index == SALE_Upgrades)
		return "UnTrain";
	else
		return "Train";
}

//Consider ourselves bought
function BuyMe( KFPawn P );

//Consider ourselves sold
function SellMe( KFPawn P );

//Subclasses should return true if the buyable
//should show up under the index'th list for pawn p.
//This implementation just returns whether or not the pawn
//already has an item of class relatedInventory.

// ParentMenu parameter is a kludge so ammo can find out if any stuff
// has been bought and sold in the main buy menu. It is a relatively
// well contained kludge however, so I won't panic
function bool ShowMe(Pawn p, eSaleCat index, GUIBuyMenu ParentMenu)
{
	return true;
}

function bool HasMe(Pawn p)
{
	local Inventory I;

	For( I=P.Inventory; I!=None; I=I.Inventory )
	{
		if( I.Class==relatedInventory )
			Return True;
	}
	Return False;
}

defaultproperties
{
     myShowMesh=StaticMesh'KillingFloorStatics.DeagleAmmo'
     InfoPanel=Class'XInterface.GUIPanel'
     infoDrawRotation=(Pitch=-5461,Yaw=-16384,Roll=32768)
     infoDrawOffset=(X=100.000000,Y=-20.000000,Z=-10.000000)
     infoDrawScale=0.700000
     infoSpinRate=20000
     ItemName="Buyable Object"
     Description="This object appears to be for sale."
}
