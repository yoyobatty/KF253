//=============================================================================
// GUIBuyTabs
// The trader's shop tabs, across the top of its list: All, Melee, Power, Speed, Range. What is chosen stays a row of the menu's
// category list (GUIBuyMenu.myCategories, which is not shown): a tab picks its row, and the tab of the row chosen is lit.
//=============================================================================
class GUIBuyTabs extends GUIComponent;

var() array<int> Order;		// the list's rows in the order of the tabs
var() float Gap;			// between the tabs, a share of the row's width

function GUIList Cats()
{
	if ( GUIBuyMenu(PageOwner) == None )
		return None;
	return GUIBuyMenu(PageOwner).myCategories;
}

function float TabWidth()
{
	return (ActualWidth() - ActualWidth() * Gap * (Order.Length - 1)) / Order.Length;
}

// The tab under a point of the screen, or -1
function int TabAt( float MX, float MY )
{
	local float W, D;
	local int i;

	if ( Order.Length == 0 || MX < ActualLeft() || MX > ActualLeft() + ActualWidth()
	 || MY < ActualTop() || MY > ActualTop() + ActualHeight() )
		return -1;
	W = TabWidth();
	D = W + ActualWidth() * Gap;
	i = int((MX - ActualLeft()) / D);
	if ( i < 0 || i >= Order.Length || MX - ActualLeft() - i * D > W )
		return -1;
	return i;
}

function bool InternalOnDraw( Canvas C )
{
	local GUIList L;
	local int i, Over;
	local float W, D;
	local eMenuState S;

	L = Cats();
	if ( L == None || Style == None || Order.Length == 0 )
		return true;
	Over = TabAt(Controller.MouseX, Controller.MouseY);
	W = TabWidth();
	D = W + ActualWidth() * Gap;
	for ( i = 0; i < Order.Length; i++ )
	{
		if ( L.Index == Order[i] )
			S = MSAT_Watched;
		else if ( i == Over )
			S = MSAT_Focused;
		else
			S = MSAT_Blurry;
		Style.Draw(C, S, ActualLeft() + i * D, ActualTop(), W, ActualHeight());
		Style.DrawText(C, S, ActualLeft() + i * D, ActualTop(), W, ActualHeight(), TXTA_Center, L.GetItemAtIndex(Order[i]), FontScale);
	}
	return true;
}

function bool InternalOnClick( GUIComponent Sender )
{
	local int i;

	i = TabAt(Controller.MouseX, Controller.MouseY);
	if ( i >= 0 && Cats() != None && Cats().Index != Order[i] )
		Cats().SetIndex(Order[i]);
	return true;
}

defaultproperties
{
	Order(0)=0
	Order(1)=1
	Order(2)=2
	Order(3)=3
	Order(4)=4
	Gap=0.005000
	StyleName="ItemBoxInfo"
	FontScale=FNS_Small
	bAcceptsInput=True
	bCaptureMouse=True
	bTabStop=False
	OnDraw=GUIBuyTabs.InternalOnDraw
	OnClick=GUIBuyTabs.InternalOnClick
}
