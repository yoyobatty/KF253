class GUIBuyItemsList extends GUIVertList;

var array< GUIBuyable > Elements;
var float RowShare;		// each row's share of the list's height
var color Unbuyable;	// the colour of what stops a row being bought


event InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	OnDrawItem=DrawBuyItem;
	Super.InitComponent(MyController,MyOwner);
}

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

function SelectNewItem(GUIComponent Sender)
{
	if(GUIBuyMenu(PageOwner) == None)
		return;
	if(Elements.Length <= 0)
		GUIBuyMenu(PageOwner).NewInfo(None);
	else
		GUIBuyMenu(PageOwner).NewInfo(Elements[Index]);


}

function bool OnDblClick(GUIComponent Sender)
{
	// HAHAH typecasting nightmare.
	// All we're doing here is hacking the Items in the buymenu list so when you
	// double clickem, it runs a quick check to see if you can buy / sell this, and acts
	// like you had clicked the footer.
	// Because the Sender (the actual button we're double clicking) has fuck all to do with the GUIBuyable itself, 
	// we've gotta route everything back through the BuyMenu... 
	// Care of Alex
	if (GUIBuyMenu(PageOwner).CanAfford(GUIBuyMenu(PageOwner).ItemsBox.List.Elements[GUIBuyMenu(PageOwner).ItemsBox.List.Index] )
	 && GUIBuyMenu(PageOwner).ItemsBox.List.Elements[GUIBuyMenu(PageOwner).ItemsBox.List.Index].CanButtonMe(PlayerOwner()
	 ,GUIBuyMenu(PageOwner).myCategories.Index!=0) )
		GUIBuyMenuFooter(GUIBuyMenu(PageOwner).t_Footer).OnFooterClick(GUIBuyMenuFooter(GUIBuyMenu(PageOwner).t_Footer).b_Buy);
	Return False;
}


function DrawBuyItem(Canvas c, int Item, float X, float Y, float W, float HT, bool bSelected, bool bPending)
{
	local string Left, Right;
	local float Iheight,Itop,Ileft,Iwidth,Half,Gap;
	local eMenuState drawState;
	local GUIBuyMenu M;
	local GUIBuyable b;
	local int Have,Most,Clip;
	local bool bDear,bHeavy;

	M = GUIBuyMenu(PageOwner);
	b = Elements[Item];
	if(!bSelected)
		drawState = MSAT_Blurry;
	else
		drawState = MSAT_Watched;

	Iheight = HT*0.86;
	Itop = Y+(HT-Iheight)/2;
	SectionStyle.Draw(c,drawState,X,Itop,W,Iheight);
	Ileft = X+W*0.04;
	Iwidth = W-W*0.08;

	// below the name: what it costs (or sells for) and weighs; for ammo, a clip's price and the rounds held
	if( M!=None && M.myCategories.Index==0 )
	{
		Left = "Sells for:"@int(b.sellValue);
		Right = "Weight:"@int(b.weight);
	}
	else if( BuyableAmmo(b)!=None )
	{
		Left = "Clip:"@int(b.cost);
		if( BuyableAmmo(b).Holding(PlayerOwner().Pawn,Have,Most,Clip) )
			Right = "Rounds:"@Have$"/"$Most;
	}
	else
	{
		Left = "Cost:"@int(b.cost);
		if( b.weight>0 )
			Right = "Weight:"@int(b.weight);
	}
	if( M!=None )
	{
		bDear = M.TooDear(b);
		bHeavy = M.TooHeavy(b);
	}
	// (what cannot be bought is dimmed, and what stops it is in red)
	if( bDear || bHeavy )
	{
		c.Style = 5;
		c.SetDrawColor(0,0,0,110);
		c.SetPos(X,Itop);
		c.DrawTile(Texture'Engine.WhiteTexture',W,Iheight,0,0,1,1);
		c.SetDrawColor(255,255,255,255);
	}
	SectionStyle.DrawText(c,MSAT_Blurry,Ileft,Itop,Iwidth,Iheight*0.55,TXTA_Center,b.ItemName,FNS_Medium);
	if( Right=="" )
		LineText(c,Ileft,Itop+Iheight*0.45,Iwidth,Iheight*0.45,TXTA_Center,Left,bDear);
	else
	{
		Half = Iwidth*0.5;
		Gap = Iwidth*0.03;
		LineText(c,Ileft,Itop+Iheight*0.45,Half-Gap,Iheight*0.45,TXTA_Right,Left,bDear);
		LineText(c,Ileft+Half+Gap,Itop+Iheight*0.45,Half-Gap,Iheight*0.45,TXTA_Left,Right,bHeavy);
	}
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
     RowShare=0.142857
     Unbuyable=(R=255,G=70,B=60,A=255)
     GetItemHeight=GUIBuyItemsList.BuyItemHeight
     StyleName="ItemBoxInfo"
     bMouseOverSound=True
     OnClickSound=CS_Click
     OnDblClick=GUIBuyItemsList.OnDblClick
     OnChange=GUIBuyItemsList.SelectNewItem
}
