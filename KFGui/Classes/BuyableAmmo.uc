class BuyableAmmo extends GUIBuyable;

var bool bHasAmmo;
var int maxAmmoCount;
var class<Ammunition> ammoType;

// Function to initialise values when player is buying a new gun,
// but has not completed purchase, therefore the weapon is not in the players
// inventory (and therefore InitOwnedQuantity is useless)
function InitNewPurchase( Pawn P )
{
	bHasAmmo = ShowMe(p,SALE_Ammo,None);
}

function int BuyMoreClips()
{
	Return 0;
}
function int NumClips()
{
	Return 0;
}

// What the pawn holds of this ammo, the most it may hold, and how many rounds the trader sells as a clip: all as
// KFPawn.PurchaseAmmo has them
function bool Holding( Pawn P, out int Have, out int Most, out int Clip )
{
	local Inventory I;
	local Ammunition AM;
	local KFWeapon KW;
	local class<KFWeaponPickup> PC;

	if( P==None )
		Return False;
	For( I=P.Inventory; I!=None; I=I.Inventory )
	{
		if( I.Class==ammoType )
			AM = Ammunition(I);
		else if( KW==None && KFWeapon(I)!=None && (Weapon(I).AmmoClass[0]==ammoType || Weapon(I).AmmoClass[1]==ammoType) )
			KW = KFWeapon(I);
	}
	if( AM==None || KW==None )
		Return False;
	Have = AM.AmmoAmount;
	Most = AM.default.MaxAmmo;
	if( KFPawn(P)!=None )
		Most = int(float(Most) * KFPawn(P).GetVeteran().Static.AddExtraAmmoFor(ammoType));
	Clip = KW.default.ClipCount;
	PC = class<KFWeaponPickup>(KW.PickupClass);
	if( KW.AmmoClass[1]==ammoType && PC!=None && PC.default.SecondaryAmmoCost>0 && PC.default.SecondaryClipCount>0 )
		Clip = PC.default.SecondaryClipCount;
	Return (Clip>0);
}

// What filling up costs
function int FillCost( Pawn P )
{
	local int Have,Most,Clip;

	if( !Holding(P,Have,Most,Clip) || Have>=Most )
		Return 0;
	Return int(float(Most-Have)/float(Clip)*cost);
}

function string GetBuyCaption(eSaleCat index)
{
	return "Clip";
}

//Consider ourselves bought
function BuyMe( KFPawn P )
{
	P.ServerBuyAmmo(ammoType,True);
}

//Consider ourselves sold
function SellMe( KFPawn P )
{
	P.ServerSellAmmo(ammoType);
}

//Fill up the weapon
function FillMe( KFPawn P )
{
	P.ServerBuyAmmo(ammoType,False);
}

function bool ShowMe(Pawn p, eSaleCat index, GuiBuyMenu ParentMenu )
{
	local Inventory I;

	if(index != SALE_Ammo)
		return false;

	For( I=P.Inventory; I!=None; I=I.Inventory )
	{
		if( I.Class==relatedInventory )
			Return True;
		else if( Weapon(I)!=None && (Weapon(I).AmmoClass[0]==ammoType || Weapon(I).AmmoClass[1]==ammoType) )
			Return True;
	}
	return false;
}

defaultproperties
{
     InfoPanel=Class'KFGui.GUIBuyAmmoInfoPanel'
     infoDrawRotation=(Pitch=0,Yaw=-35000,Roll=0)
     infoDrawOffset=(X=50.000000,Y=0.000000,Z=-5.000000)
     infoDrawScale=0.800000
}
