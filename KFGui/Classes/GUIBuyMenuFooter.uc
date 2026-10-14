class GUIBuyMenuFooter extends ButtonFooter;

var automated GUIButton b_Buy,b_Cancel,b_Complete,b_AutoAll,b_Fill;
var automated GUIButton spacer1,spacer2;
var automated GUILabel l_score,l_weight;
var automated GUIImage i_cash;	// the HUD's pound sign: the menu's font has none

// Laid out again each frame from the buttons shown: they fit their captions, which change (the refill's price),
// and the fill button comes and goes. (They were laid out once, in fixed slots, the hidden ones keeping theirs empty.)
function bool InternalOnPreDraw(Canvas C)
{
	if ( bBoundToParent && MenuOwner != None )
		WinTop = RelativeTop( MenuOwner.ActualTop() + MenuOwner.ActualHeight() - ActualHeight(), True );
	else
		WinTop = RelativeTop( Controller.ResY - ActualHeight(), True );
	if ( ButtonsSized(C) )
	{
		ButtonLeft = GetButtonLeft();
		PositionButtons(C);
	}
	// (the pound sign as wide as it is tall, and the cash just after it)
	if( i_cash!=None && l_score!=None )
	{
		i_cash.WinWidth = i_cash.RelativeWidth(i_cash.ActualHeight(),True);
		l_score.WinLeft = i_cash.WinLeft+i_cash.WinWidth*1.25;
	}
	return true;
}

function PositionButtons (Canvas C)
{
	local int i;
	local GUIButton b;
	local float x;

	for ( i = 0; i < Controls.Length; i++ )
	{
		b = GUIButton(Controls[i]);
		if ( b != None && b.bVisible )
		{
			if ( x == 0 )
				x = ButtonLeft;
			else x += GetSpacer();
			b.WinLeft = b.RelativeLeft( x, True );
			x += b.ActualWidth();
		}
	}
}

function SetPlayerStats(int score, float weight)
{
	local float Most;

	if( l_score!=None )
		l_score.Caption = string(score);
	if( GUIBuyMenu(PageOwner)!=None )
		Most = GUIBuyMenu(PageOwner).maxweight;
	if( l_weight!=None )
		l_weight.Caption = "Weight:"@int(weight+0.5)$"/"$int(Most+0.5);
}

function SetBuyMode(string buyCaption,bool buyEnabled,bool fillVisible,bool fillEnabled,optional string FillCaption)
{
	local bool AutoAmmoEnabled;
	AutoAmmoEnabled = GUIBuyMenu(PageOwner).CanAutoAmmo();
	// (the refill button says what it will spend)
	b_AutoAll.Caption = GUIBuyMenu(PageOwner).RefillCaption();
	b_buy.Caption = buyCaption;
	if(buyEnabled && b_buy.MenuState == MSAT_Disabled)
	{
		b_buy.MenuState = MSAT_Blurry;              //    GUIBuyMenu(PageOwner).ItemsBox.List.Elements[GUIBuyMenu(PageOwner).ItemsBox.List.Index]                                   // 
             //   GUIBuyMenu(PageOwner).ItemsBox.List.MenuState = MSAT_Blurry;
        }
        else if(!buyEnabled)
	{
        	b_buy.MenuState = MSAT_Disabled;
             //   GUIBuyMenu(PageOwner).ItemsBox.List.MenuState = MSAT_Disabled;
        }

	if(fillEnabled && b_fill.MenuState == MSAT_Disabled)
		b_fill.MenuState = MSAT_Blurry;
	else if(!fillEnabled)
		b_fill.MenuState = MSAT_Disabled;
	b_fill.bVisible = fillVisible;
	if( FillCaption!="" )
		b_fill.Caption = FillCaption;

	if(AutoAmmoEnabled && b_AutoAll.MenuState == MSAT_Disabled)
		b_AutoAll.MenuState = MSAT_Blurry;
	else if(!AutoAmmoEnabled)
	   b_AutoAll.MenuState = MSAT_Disabled;
}

function bool ButtonsSized(Canvas C)
{
	local int i;
	local GUIButton b;
	local bool bResult;
	local string str;
	local float T, AH, AT;

	if ( !bPositioned )
		return false;

	bResult = true;
	str = GetLongestCaption(C);

	AH = ActualHeight();
	AT = ActualTop();

	for (i = 0; i < Controls.Length; i++ )
	{
		b = GUIButton(Controls[i]);
		if ( b != None )
		{
			if ( bAutoSize && bFixedWidth )
			{
			    if(b.Caption == "")
			        b.SizingCaption = Left(str,Len(str)/2);
				else
					b.SizingCaption = str;
			}
			else b.SizingCaption = "";

			bResult = bResult && b.bPositioned;
			if ( bFullHeight )
				b.WinHeight = b.RelativeHeight(AH,true);
			else b.WinHeight = b.RelativeHeight(ActualHeight(ButtonHeight),true);

			switch ( Justification )
			{
			case TXTA_Left:
				T = ClientBounds[1];
				break;

			case TXTA_Center:
				T = (AT + AH / 2) - (b.ActualHeight() / 2);
				break;

			case TXTA_Right:
				T = ClientBounds[3] - b.ActualHeight();
				break;
			}

			b.WinTop = b.RelativeTop(T, True );
		}
	}

	return bResult;
}

function float GetButtonLeft()
{
	local int i;
	local GUIButton b;
	local float TotalWidth, AW, AL;
	local float FooterMargin;

	AL = ActualLeft();
	AW = ActualWidth();
	FooterMargin = GetMargin();

	for (i = 0; i < Controls.Length; i++ )
	{
		b = GUIButton(Controls[i]);
		if ( b != None && b.bVisible )
		{
			if ( TotalWidth > 0 )
				TotalWidth += GetSpacer();

			TotalWidth += b.ActualWidth();
		}
	}

	if ( Alignment == TXTA_Center )
		return (AL + AW) / 2 - FooterMargin / 2 - TotalWidth / 2;

	if ( Alignment == TXTA_Right )
		return (AL + AW - FooterMargin / 2) - TotalWidth;

	return AL + (FooterMargin / 2);
}

// Finds the longest caption of all the buttons
function string GetLongestCaption(Canvas C)
{
	local int i;
	local float XL, YL, LongestW;
	local string str;
	local GUIButton b;

	if ( C == None )
		return "";

	for ( i = 0; i < Controls.Length; i++ )
	{
		b = GUIButton(Controls[i]);
		if ( b != None )
		{
			if ( b.Style != None )
				b.Style.TextSize(C, b.MenuState, b.Caption, XL, YL, b.FontScale);
			else C.StrLen( b.Caption, XL, YL );

			if ( LongestW == 0 || XL > LongestW )
			{
				str = b.Caption;
				LongestW = XL;
			}
		}
	}

	return str;
}

function bool OnFooterClick(GUIComponent Sender)
{
	if(Sender == b_Complete)
	{
		GUIBuyMenu(PageOwner).CloseSale(true);
	} else if(Sender == b_Cancel)
	{
		GUIBuyMenu(PageOwner).CloseSale(false);
	} else if(Sender == b_Buy)
	{
		GUIBuyMenu(PageOwner).BuyCurrent();
	} else if(Sender == b_Fill)
	{
		GUIBuyMenu(PageOwner).BuyFill();
	} else if(Sender == b_AutoAll)
	{
		GUIBuyMenu(PageOwner).DoAutoAmmo();
	}
	return false;
}

defaultproperties
{
     Begin Object Class=GUIButton Name=Purchase
         Caption="Buy"
         StyleName="FooterButton"
         Hint="Buy currently selected weapon"
         WinTop=-0.001953
         WinLeft=0.236407
         WinWidth=0.112219
         WinHeight=0.057242
         RenderWeight=2.000000
         TabOrder=3
         bBoundToParent=True
         OnClick=GUIBuyMenuFooter.OnFooterClick
         OnKeyEvent=Purchase.InternalOnKeyEvent
     End Object
     b_Buy=GUIButton'KFGui.GUIBuyMenuFooter.Purchase'


     Begin Object Class=GUIButton Name=Complete
         Caption="Complete"
         StyleName="FooterButton"
         Hint="Close the trader menu."
         WinTop=0.015971
         WinLeft=0.787105
         WinWidth=0.092022
         WinHeight=0.051756
         RenderWeight=2.000000
         TabOrder=6
         bBoundToParent=True
         OnClick=GUIBuyMenuFooter.OnFooterClick
         OnKeyEvent=Complete.InternalOnKeyEvent
     End Object
     b_Complete=GUIButton'KFGui.GUIBuyMenuFooter.Complete'

     Begin Object Class=GUIButton Name=AutoAmmo
         Caption="Refill all"
         StyleName="FooterButton"
         Hint="Fill every weapon's ammo (with too little cash, a share for each), and mend your armour if you have the cash for both."
         WinTop=-0.014645
         WinLeft=0.006149
         WinWidth=0.112219
         WinHeight=0.058023
         RenderWeight=2.000000
         TabOrder=0
         bBoundToParent=True
         OnClick=GUIBuyMenuFooter.OnFooterClick
         OnKeyEvent=AutoAmmo.InternalOnKeyEvent
     End Object
     b_AutoAll=GUIButton'KFGui.GUIBuyMenuFooter.AutoAmmo'

     Begin Object Class=GUIButton Name=Fill
         Caption="Fill Up"
         StyleName="FooterButton"
         Hint="Fill up on currently selected ammo."
         WinTop=0.966146
         WinLeft=0.250000
         WinWidth=0.120000
         RenderWeight=2.000000
         TabOrder=2
         bBoundToParent=True
         bVisible=False
         OnClick=GUIBuyMenuFooter.OnFooterClick
         OnKeyEvent=Fill.InternalOnKeyEvent
     End Object
     b_Fill=GUIButton'KFGui.GUIBuyMenuFooter.Fill'

     Begin Object Class=GUIButton Name=sp
         StyleName="Footerbutton"
         WinTop=0.966146
         WinLeft=0.220000
         WinWidth=0.120000
         RenderWeight=2.000000
         TabOrder=1
         bBoundToParent=True
         bVisible=False
         OnKeyEvent=sp.InternalOnKeyEvent
     End Object
     spacer1=GUIButton'KFGui.GUIBuyMenuFooter.sp'

     Begin Object Class=GUIButton Name=sp2
         StyleName="Footerbutton"
         WinTop=0.966146
         WinLeft=0.330000
         WinWidth=0.120000
         RenderWeight=2.000000
         TabOrder=4
         bBoundToParent=True
         bVisible=False
         OnKeyEvent=sp2.InternalOnKeyEvent
     End Object
     spacer2=GUIButton'KFGui.GUIBuyMenuFooter.sp2'

     Begin Object Class=GUIImage Name=CashIcon
         Image=Texture'KFKillMeNow.KFHUDIcons'
         ImageStyle=ISTY_Scaled
         ImageRenderStyle=MSTY_Alpha
         X1=193
         Y1=0
         X2=255
         Y2=63
         WinTop=0.150000
         WinLeft=0.008000
         WinWidth=0.030000
         WinHeight=0.700000
         bBoundToParent=True
         bScaleToParent=True
     End Object
     i_cash=GUIImage'KFGui.GUIBuyMenuFooter.CashIcon'

     Begin Object Class=GUILabel Name=CashLabel
         TextColor=(B=140,G=210,R=240,A=255)
         TextFont="UT2MenuFont"
         VertAlign=TXTA_Center
         WinLeft=0.040000
         WinWidth=0.100000
         WinHeight=1.000000
         bBoundToParent=True
         bScaleToParent=True
     End Object
     l_score=GUILabel'KFGui.GUIBuyMenuFooter.CashLabel'

     Begin Object Class=GUILabel Name=WeightLabel
         TextColor=(B=220,G=220,R=220,A=255)
         TextFont="UT2MenuFont"
         VertAlign=TXTA_Center
         WinLeft=0.130000
         WinWidth=0.200000
         WinHeight=1.000000
         bBoundToParent=True
         bScaleToParent=True
     End Object
     l_weight=GUILabel'KFGui.GUIBuyMenuFooter.WeightLabel'

     bFixedWidth=False
     Padding=0.070000
     Spacer=0.008000
     StyleName="EditBox"
     WinTop=0.943197
     WinLeft=0.446138
     WinWidth=0.499826
     WinHeight=0.058023
}
