class GUIBuyItemsList extends GUIVertList;

// What the trader sells, down the right of its menu (GUITraderInvList, a subclass, is what the player has, down the left).
// A row's buttons are drawn by the menu (GUIBuyMenu.DrawButton), which notes where; a press on one does its job.

var array< GUIBuyable > Elements;
var float RowShare;		// each row's share of the list's height
var color Unbuyable;	// the colour of what stops a row being bought

struct HitBox
{
	var int Item;
	var byte Act;
	var float X1, Y1, X2, Y2;
};
var array<HitBox> Hits;	// the buttons as last drawn

const ACT_BUY=10;


function Clear()
{
	if (Elements.Length == 0)
		return;

	Elements.Remove(0,Elements.Length);
	ItemCount = 0;
	IndexChanged(self);
	Super.Clear();
}

function Add(GUIBuyable Item)
{
	local int NewIndex,PointValue,ComparePointValue;

        PointValue=Item.cost;


   	if (Elements.Length > 0)
	{
		while (NewIndex < Elements.Length)
		{
		    ComparePointValue=Elements[NewIndex].cost;
			if(ComparePointValue >= PointValue)
				break;
			NewIndex++;
		}
	}
	else NewIndex = Elements.Length;

	Elements.Insert(NewIndex, 1);
	Elements[NewIndex] = Item;

	ItemCount = Elements.Length;

	if (NewIndex == 0)
		SetIndex(0);
 	else if ( bNotify )
		CheckLinkedObjects(Self);

	if (MyScrollBar != None)
		MyScrollBar.AlignThumb();

}

function string GetItemAtIndex( int idx )
{
	return Elements[idx].ItemName;
}

// (a row chosen again, as one on the other list was chosen in between, is shown again)
function int SetIndex(int NewIndex)
{
	local int R;

	R = Super.SetIndex(NewIndex);
	if ( GUIBuyMenu(PageOwner) != None )
		GUIBuyMenu(PageOwner).ListChose(self);
	return R;
}

function SelectNewItem(GUIComponent Sender)
{
	if(GUIBuyMenu(PageOwner) != None)
		GUIBuyMenu(PageOwner).ListChose(self);
}

function bool OnDblClick(GUIComponent Sender)
{
	if ( GUIBuyMenu(PageOwner) != None && Index >= 0 && Index < Elements.Length )
		GUIBuyMenu(PageOwner).BuyGun(Elements[Index]);
	Return False;
}

// (each frame the buttons are noted again as they are drawn)
function bool HitsPreDraw(Canvas C)
{
	Hits.Length = 0;
	return false;
}

function AddHit(int Item, byte Act, float X, float Y, float W, float H)
{
	local int n;

	n = Hits.Length;
	Hits.Length = n + 1;
	Hits[n].Item = Item;
	Hits[n].Act = Act;
	Hits[n].X1 = X;
	Hits[n].Y1 = Y;
	Hits[n].X2 = X + W;
	Hits[n].Y2 = Y + H;
}

// The button under a point of the screen, or -1
function int HitAt(float MX, float MY)
{
	local int i;

	for (i = 0; i < Hits.Length; i++)
	{
		if (MX >= Hits[i].X1 && MX <= Hits[i].X2 && MY >= Hits[i].Y1 && MY <= Hits[i].Y2)
			return i;
	}
	return -1;
}

// (the list's own click chooses the row first)
function bool BuyClick(GUIComponent Sender)
{
	local int i;

	InternalOnClick(Sender);
	i = HitAt(Controller.MouseX, Controller.MouseY);
	if ( i < 0 || GUIBuyMenu(PageOwner) == None || Hits[i].Item >= Elements.Length )
		return false;
	GUIBuyMenu(PageOwner).BuyGun(Elements[Hits[i].Item]);
	return true;
}

// A row: its BUY (UPGRADE) button, then its name, and what it costs and weighs (in red when that is why it cannot be bought;
// an upgrade says whose gun it is for)
function DrawBuyItem(Canvas c, int Item, float X, float Y, float W, float HT, bool bSelected, bool bPending)
{
	local string Left, Right, Cap;
	local float L, BW, BH, TH;
	local GUIBuyMenu M;
	local GUIBuyable b;
	local bool bDear,bHeavy;

	M = GUIBuyMenu(PageOwner);
	if ( M == None || Item >= Elements.Length )
		return;
	b = Elements[Item];
	bDear = M.TooDear(b);
	bHeavy = M.TooHeavy(b);

	BW = W * 0.2;
	BH = HT * 0.62;
	Cap = "BUY";
	if ( BuyableUpgrade(b) != None )
		Cap = "UPGRADE";
	M.DrawButton(c, self, X, Y + (HT - BH) * 0.5, BW, BH, Cap, -1, M.CanAfford(b), 0, Item, ACT_BUY);

	L = X + BW + W * 0.02;
	TH = HT * 0.86;
	if ( bSelected && !M.bOwnChosen )
		SectionStyle.Draw(c, MSAT_Watched, L, Y + (HT - TH) * 0.5, X + W - L, TH);
	else
		SectionStyle.Draw(c, MSAT_Blurry, L, Y + (HT - TH) * 0.5, X + W - L, TH);

	Left = "Cost:"@int(b.cost);
	if ( BuyableUpgrade(b) != None )
	{
		Right = "Your"@BuyableUpgrade(b).Base.default.ItemName;
		if ( bHeavy )
			Right = "Weight: +"$int(b.weight);
	}
	else if ( b.weight > 0 )
		Right = "Weight:"@int(b.weight);
	// (what cannot be bought is dimmed, and what stops it is in red)
	if( bDear || bHeavy )
	{
		c.Style = 5;
		c.SetDrawColor(0,0,0,110);
		c.SetPos(L,Y + (HT - TH) * 0.5);
		c.DrawTile(Texture'Engine.WhiteTexture',X + W - L,TH,0,0,1,1);
		c.SetDrawColor(255,255,255,255);
	}
	SectionStyle.DrawText(c,MSAT_Blurry,L + W * 0.03,Y + HT * 0.1,X + W - L - W * 0.06,HT * 0.45,TXTA_Left,b.ItemName,FNS_Medium);
	LineText(c,L + W * 0.03,Y + HT * 0.5,X + W - L - W * 0.06,HT * 0.4,TXTA_Left,Left,bDear);
	if( Right!="" )
		LineText(c,L + W * 0.03,Y + HT * 0.5,X + W - L - W * 0.06,HT * 0.4,TXTA_Right,Right,bHeavy);
}

// A row's second line, in red when it is why the row cannot be bought. (The style is shared with other lists: its
// colour is borrowed for the line and put back. Its disabled state was dimmed in the drawing.)
function LineText(Canvas c, float X, float Y, float W, float H, eTextAlign A, string S, bool bRed)
{
	local color Was;

	if( !bRed )
	{
		SectionStyle.DrawText(c,MSAT_Blurry,X,Y,W,H,A,S,FNS_Small);
		return;
	}
	Was = SectionStyle.FontColors[0];
	SectionStyle.FontColors[0] = Unbuyable;
	SectionStyle.DrawText(c,MSAT_Blurry,X,Y,W,H,A,S,FNS_Small);
	SectionStyle.FontColors[0] = Was;
}

function float BuyItemHeight(Canvas c)
{
	if(GUIBuyItemsBox(MenuOwner) != None)
		 return MenuOwner.ActualHeight() * RowShare;
	else
		 return 0;
}

defaultproperties
{
     RowShare=0.083000
     Unbuyable=(R=255,G=70,B=60,A=255)
     GetItemHeight=GUIBuyItemsList.BuyItemHeight
     StyleName="ItemBoxInfo"
     bMouseOverSound=True
     OnClickSound=CS_Click
     OnDrawItem=GUIBuyItemsList.DrawBuyItem
     OnPreDraw=GUIBuyItemsList.HitsPreDraw
     OnClick=GUIBuyItemsList.BuyClick
     OnDblClick=GUIBuyItemsList.OnDblClick
     OnChange=GUIBuyItemsList.SelectNewItem
}
