//=============================================================================
// GUIBuyUpgradeLines
// The upgrades of the gun on the trader's card (KFTraderUpgrades), as Killing Floor 2 has them in the middle: on a gun
// the player has, each with an UPGRADE button and its price, bought at once (GUIBuyMenu.AskBuy); on one for sale, their
// names and prices only. What the upgrade under the mouse does is written under them (else the first one's).
//=============================================================================
class GUIBuyUpgradeLines extends GUIComponent;

struct ShownLine
{
	var BuyableUpgrade U;
	var bool bOpen;					// the player has the gun: it can be bought here
	var string Nums;				// its numbers for this player's gun (KFTraderUpgrades.NumbersOf), under what it does
	var float BX1, BY1, BX2, BY2;	// (its button, as last drawn)
};
var array<ShownLine> Lines;
var string Heading;
var() string FontName;
var() color HeadColor, LineColor, InfoColor, NumColor;
var() float LineSpace;				// a line's height, times the font's

function Fill( GUIBuyMenu M, GUIBuyable b )
{
	local int i, n;
	local BuyableUpgrade U;
	local KFWeapon W;

	Lines.Length = 0;
	Heading = "";
	if ( M == None || BuyableWeapon(b) == None || BuyableUpgrade(b) != None || class'KFTraderUpgrades'.static.IsVariant(class<Weapon>(b.relatedInventory)) )
		return;
	W = M.OwnedGun(b);
	if ( W != None && W.bUpgraded )
	{
		if ( W.UpgradeName != "" )
			Heading = "Upgraded:" @ W.UpgradeName;
		return;
	}
	for ( i = 0; i < M.AllBuyableItems.Length; i++ )
	{
		U = BuyableUpgrade(M.AllBuyableItems[i]);
		if ( U == None || U.Base != b.relatedInventory )
			continue;
		n = Lines.Length;
		Lines.Length = n + 1;
		Lines[n].U = U;
		Lines[n].bOpen = W != None;
		Lines[n].Nums = class'KFTraderUpgrades'.static.NumbersOf(U.Line, W, M.PlayerOwner().PlayerReplicationInfo);
	}
	if ( Lines.Length == 0 )
		return;
	if ( W != None )
		Heading = "Upgrades";
	else
		Heading = "Upgrades, once it is yours";
}

function bool SetFont( Canvas C )
{
	local GUIFont F;

	F = Controller.GetMenuFont(FontName);
	if ( F == None )
		return false;
	C.Font = F.GetFont(C.ClipX);
	return C.Font != None;
}

function bool Within( float X, float Y, float X1, float Y1, float X2, float Y2 )
{
	return X >= X1 && X <= X2 && Y >= Y1 && Y <= Y2;
}

// A button as the trader's rows have them (GUIBuyMenu.DrawButton): its caption over its price
function DrawUpgradeButton( Canvas C, float X, float Y, float W, float H, int Price, bool bOn, bool bOver )
{
	local float XL, YL;
	local string P;

	C.Style = 5;
	if ( !bOn )
		C.SetDrawColor(38, 38, 38, 215);
	else if ( bOver )
		C.SetDrawColor(190, 45, 40, 245);
	else
		C.SetDrawColor(125, 22, 22, 235);
	C.SetPos(X, Y);
	C.DrawTile(Texture'Engine.WhiteTexture', W, H, 0, 0, 1, 1);
	if ( !bOn )
		C.SetDrawColor(85, 85, 85, 255);
	else
		C.SetDrawColor(230, 90, 70, 255);
	C.SetPos(X, Y);
	C.DrawTile(Texture'Engine.WhiteTexture', W, 1, 0, 0, 1, 1);
	C.SetPos(X, Y + H - 1);
	C.DrawTile(Texture'Engine.WhiteTexture', W, 1, 0, 0, 1, 1);
	C.SetPos(X, Y);
	C.DrawTile(Texture'Engine.WhiteTexture', 1, H, 0, 0, 1, 1);
	C.SetPos(X + W - 1, Y);
	C.DrawTile(Texture'Engine.WhiteTexture', 1, H, 0, 0, 1, 1);
	if ( bOn )
		C.SetDrawColor(235, 235, 235, 255);
	else
		C.SetDrawColor(130, 130, 130, 255);
	P = "UPGRADE" @ Price;
	C.TextSize(P, XL, YL);
	C.SetPos(X + (W - XL) * 0.5, Y + (H - YL) * 0.5);
	C.DrawText(P);
}

// Words written over lines no wider than W, from Y; the height used is returned
function float Wrapped( Canvas C, string S, float X, float Y, float W )
{
	local array<string> Words;
	local string Line, Try;
	local float XL, YL, Top;
	local int i;

	Split(S, " ", Words);
	Top = Y;
	for ( i = 0; i < Words.Length; i++ )
	{
		if ( Line == "" )
			Try = Words[i];
		else
			Try = Line @ Words[i];
		C.TextSize(Try, XL, YL);
		if ( XL > W && Line != "" )
		{
			C.SetPos(X, Y);
			C.DrawText(Line);
			Y += YL;
			Line = Words[i];
		}
		else
			Line = Try;
	}
	if ( Line != "" )
	{
		C.TextSize(Line, XL, YL);
		C.SetPos(X, Y);
		C.DrawText(Line);
		Y += YL;
	}
	return Y - Top;
}

function bool InternalOnDraw( Canvas C )
{
	local GUIBuyMenu M;
	local float LH, Y, XL, YL, BW, BH;
	local int i, Shown;
	local string P;
	local bool bOver;

	M = GUIBuyMenu(PageOwner);
	if ( M == None || Heading == "" || !SetFont(C) )
		return true;
	C.TextSize("Wg", XL, YL);
	LH = YL * LineSpace;
	if ( Lines.Length > 0 && Lines[0].bOpen )
		LH = YL * LineSpace * 1.6;
	C.Style = 1;
	C.DrawColor = HeadColor;
	C.SetPos(ActualLeft(), ActualTop());
	C.DrawText(Heading);
	Y = ActualTop() + YL * 1.4;
	BW = ActualWidth() * 0.42;
	BH = LH * 0.85;
	Shown = 0;
	for ( i = 0; i < Lines.Length; i++ )
	{
		if ( Y + LH > ActualTop() + ActualHeight() )
			break;
		Lines[i].BX1 = 0;
		Lines[i].BY1 = 0;
		Lines[i].BX2 = 0;
		Lines[i].BY2 = 0;
		C.Style = 1;
		if ( Lines[i].bOpen )
			C.SetDrawColor(235, 235, 235, 255);
		else
			C.DrawColor = LineColor;
		C.SetPos(ActualLeft() + ActualWidth() * 0.03, Y + (LH - YL) * 0.5);
		C.DrawText(Lines[i].U.ItemName);
		if ( Lines[i].bOpen )
		{
			Lines[i].BX1 = ActualLeft() + ActualWidth() - BW;
			Lines[i].BY1 = Y + (LH - BH) * 0.5;
			Lines[i].BX2 = Lines[i].BX1 + BW;
			Lines[i].BY2 = Lines[i].BY1 + BH;
			bOver = Within(Controller.MouseX, Controller.MouseY, Lines[i].BX1, Lines[i].BY1, Lines[i].BX2, Lines[i].BY2);
			DrawUpgradeButton(C, Lines[i].BX1, Lines[i].BY1, BW, BH, Lines[i].U.cost, M.CanAfford(Lines[i].U), bOver);
		}
		else
		{
			P = string(int(Lines[i].U.cost));
			C.TextSize(P, XL, YL);
			C.SetPos(ActualLeft() + ActualWidth() - XL, Y + (LH - YL) * 0.5);
			C.DrawText(P);
		}
		// (the line the mouse is on, or the first, says what it does)
		if ( Within(Controller.MouseX, Controller.MouseY, ActualLeft(), Y, ActualLeft() + ActualWidth(), Y + LH) )
			Shown = i;
		Y += LH;
	}
	if ( Lines.Length > 0 && Y + YL < ActualTop() + ActualHeight() )
	{
		C.Style = 1;
		C.DrawColor = InfoColor;
		Y += YL * 0.4;
		Y += Wrapped(C, Lines[Shown].U.Description, ActualLeft() + ActualWidth() * 0.03, Y, ActualWidth() * 0.94);
		// (the numbers on a line of their own, brighter, as Killing Floor 2 lists them apart)
		if ( Lines[Shown].Nums != "" && Y + YL * 1.3 < ActualTop() + ActualHeight() )
		{
			C.DrawColor = NumColor;
			Wrapped(C, Lines[Shown].Nums, ActualLeft() + ActualWidth() * 0.03, Y + YL * 0.3, ActualWidth() * 0.94);
		}
	}
	return true;
}

// An UPGRADE pressed: bought at the next frame (the card is made anew by it, this with it)
function bool InternalOnClick( GUIComponent Sender )
{
	local int i;
	local GUIBuyMenu M;

	M = GUIBuyMenu(PageOwner);
	if ( M == None )
		return true;
	for ( i = 0; i < Lines.Length; i++ )
	{
		if ( Lines[i].bOpen && Within(Controller.MouseX, Controller.MouseY, Lines[i].BX1, Lines[i].BY1, Lines[i].BX2, Lines[i].BY2)
		 && M.CanAfford(Lines[i].U) )
		{
			M.AskBuy(Lines[i].U);
			break;
		}
	}
	return true;
}

defaultproperties
{
	FontName="UT2SmallFont"
	HeadColor=(R=255,G=50,B=50,A=255)
	LineColor=(R=150,G=150,B=150,A=255)
	InfoColor=(R=190,G=190,B=190,A=255)
	NumColor=(R=240,G=240,B=240,A=255)
	LineSpace=1.350000
	bAcceptsInput=True
	bCaptureMouse=True
	bTabStop=False
	OnDraw=GUIBuyUpgradeLines.InternalOnDraw
	OnClick=GUIBuyUpgradeLines.InternalOnClick
}
