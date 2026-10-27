//=============================================================================
// GUITraderInvList
// What the player has, down the left of the trader: the armour, a medical kit's health, the grenades, and each gun
// with its ammo. A row's buttons do their job at once: MAG (or 1X) a clip of its ammo, FILL its ammo to full (or the
// armour mended, the health made whole); beside the gun chosen, SELL. (Its upgrades are on the card in the middle.)
//=============================================================================
class GUITraderInvList extends GUIBuyItemsList;

const ACT_CLIP=1;
const ACT_FILL=2;
const ACT_SELL=3;

var array<BuyableAmmo> AmmoOf;		// a row's ammo (a gun's, or the grenades')
var array<KFWeapon> GunOf;			// the gun a row stands for

function Clear()
{
	Super.Clear();
	AmmoOf.Length = 0;
	GunOf.Length = 0;
}

// (in the order given: armour, health, grenades, then the guns)
function AddRow( GUIBuyable b, BuyableAmmo A, KFWeapon W )
{
	local int n;

	n = Elements.Length;
	Elements[n] = b;
	AmmoOf[n] = A;
	GunOf[n] = W;
	ItemCount = Elements.Length;
	if ( MyScrollBar != None )
		MyScrollBar.AlignThumb();
}

function string GetItemAtIndex( int idx )
{
	if ( GUIBuyMenu(PageOwner) != None )
		return GUIBuyMenu(PageOwner).InvName(idx);
	return Elements[idx].ItemName;
}

function DrawInvRow( Canvas c, int Item, float X, float Y, float W, float HT, bool bSelected, bool bPending )
{
	local GUIBuyMenu M;
	local GUIBuyable b;
	local BuyableAmmo A;
	local float BH, BY, BW, Gap, L, R, TH;
	local int Have, Most, Clip, Cost;
	local string Count;
	local bool bChosen;

	M = GUIBuyMenu(PageOwner);
	if ( M == None || Item >= Elements.Length )
		return;
	b = Elements[Item];
	A = AmmoOf[Item];
	bChosen = bSelected && M.bOwnChosen;
	BH = HT * 0.62;
	BY = Y + (HT - BH) * 0.5;
	BW = W * 0.165;
	Gap = W * 0.015;

	// the buttons on the left
	if ( BuyableVest(b) != None )
	{
		Cost = M.VestCost();
		M.DrawButton(c, self, X, BY, BW * 2 + Gap, BH, "FILL", Cost, Cost > 0 && M.playerscore > 0, 0, Item, ACT_FILL);
	}
	else if ( BuyableFirstAidKit(b) != None )
	{
		Cost = M.HealCost();
		M.DrawButton(c, self, X, BY, BW * 2 + Gap, BH, "HEAL", Cost, Cost > 0 && M.playerscore > 0, 0, Item, ACT_FILL);
	}
	else if ( A != None )
	{
		A.Holding(M.PlayerOwner().Pawn, Have, Most, Clip);
		Cost = A.cost;
		if ( BuyableWeapon(b) == None )
			M.DrawButton(c, self, X, BY, BW, BH, "1X", Cost, Have < Most && M.playerscore >= Cost, 0, Item, ACT_CLIP);
		else
			M.DrawButton(c, self, X, BY, BW, BH, "MAG", Cost, Have < Most && M.playerscore >= Cost, 0, Item, ACT_CLIP);
		Cost = A.FillCost(M.PlayerOwner().Pawn);
		M.DrawButton(c, self, X + BW + Gap, BY, BW, BH, "FILL", Cost, Cost > 0 && M.playerscore > 0, 0, Item, ACT_FILL);
	}

	// (the gun chosen: SELL beside it on the right, the row shorter for it)
	L = X + BW * 2 + Gap * 2;
	R = X + W;
	if ( bChosen && M.CanSell(b) )
	{
		BW = W * 0.18;
		M.DrawButton(c, self, R - BW, BY, BW, BH, "SELL", M.SellValueOf(b), true, 1, Item, ACT_SELL);
		R -= BW + Gap;
	}

	// the row itself: its name, and what is held
	TH = HT * 0.86;
	if ( bChosen )
		SectionStyle.Draw(c, MSAT_Watched, L, Y + (HT - TH) * 0.5, R - L, TH);
	else
		SectionStyle.Draw(c, MSAT_Blurry, L, Y + (HT - TH) * 0.5, R - L, TH);
	if ( BuyableVest(b) != None )
		Count = "Armour:"@int(M.PlayerOwner().Pawn.ShieldStrength)$"/100";
	else if ( BuyableFirstAidKit(b) != None )
		Count = "Health:"@M.PlayerOwner().Pawn.Health$"/"$int(M.PlayerOwner().Pawn.HealthMax);
	else if ( A != None )
		Count = "Ammo:"@Have$"/"$Most;
	SectionStyle.DrawText(c, MSAT_Blurry, L + W * 0.03, Y + HT * 0.1, R - L - W * 0.05, HT * 0.45, TXTA_Left, GetItemAtIndex(Item), FNS_Medium);
	if ( Count != "" )
		SectionStyle.DrawText(c, MSAT_Blurry, L + W * 0.03, Y + HT * 0.5, R - L - W * 0.05, HT * 0.4, TXTA_Left, Count, FNS_Small);
}

// A press: the button under it does its job (the list's own click chooses the row first). A row's name double-clicked
// does what its FILL (HEAL) does; and as SELL appears beside a gun once it is chosen, the second click of a double-click
// that lands on it is not a sale.
function bool InvClick( GUIComponent Sender )
{
	local GUIBuyMenu M;
	local int i;

	M = GUIBuyMenu(PageOwner);
	if ( M == None )
		return false;
	InternalOnClick(Sender);
	i = HitAt(Controller.MouseX, Controller.MouseY);
	if ( i >= 0 && Hits[i].Act == ACT_SELL && SecondClick() )
		i = -1;
	if ( i < 0 )
	{
		if ( DoubleClicked() )
			M.BuyCurrent();
		return false;
	}
	ClickedItem = None;
	M.InvAction(Hits[i].Item, Hits[i].Act);
	return true;
}

function SelectNewItem( GUIComponent Sender )
{
	if ( GUIBuyMenu(PageOwner) != None )
		GUIBuyMenu(PageOwner).ListChose(self);
}

defaultproperties
{
	RowShare=0.110000
	OnDrawItem=GUITraderInvList.DrawInvRow
	OnClick=GUITraderInvList.InvClick
	OnChange=GUITraderInvList.SelectNewItem
}
