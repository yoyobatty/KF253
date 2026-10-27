//=============================================================================
// GUITraderRefill
// Refill all, above the trader's list of what the player has: every gun's ammo filled, and the armour mended when the
// cash pays for both (GUIBuyMenu.DoAutoAmmo). Drawn as the rows' buttons are, with what it will spend; grey when there
// is nothing to fill or no cash.
//=============================================================================
class GUITraderRefill extends GUIComponent;

function bool InternalOnDraw( Canvas C )
{
	local GUIBuyMenu M;

	M = GUIBuyMenu(PageOwner);
	if ( M == None || M.myInv == None || M.myInv.SectionStyle == None )
		return true;
	M.DrawBox(C, M.myInv.SectionStyle, ActualLeft(), ActualTop(), ActualWidth(), ActualHeight(), Caps(M.RefillCaption()), -1,
	 M.CanAutoAmmo(), 0, FNS_Medium);
	return true;
}

function bool InternalOnClick( GUIComponent Sender )
{
	local GUIBuyMenu M;

	M = GUIBuyMenu(PageOwner);
	if ( M != None && M.CanAutoAmmo() )
		M.DoAutoAmmo();
	return true;
}

defaultproperties
{
	Hint="Fill every weapon's ammo (with too little cash, a share for each), and mend your armour if you have the cash for both."
	bAcceptsInput=True
	bCaptureMouse=True
	bTabStop=False
	OnClickSound=CS_Click
	OnDraw=GUITraderRefill.InternalOnDraw
	OnClick=GUITraderRefill.InternalOnClick
}
