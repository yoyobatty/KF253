class GUIBuyDescInfoPanel extends GUIBuyInfoPanel;

var automated GUIWeaponImage i_weapBG; //Love my black background
var automated GUILabel l_name, l_desc; //Weapon's name, description


function Display(GUIBuyable newWeapon)
{
	local GUIBuyable b;
	b =newWeapon;
	if(b == None)
	{
		l_name.Caption = "";
		l_desc.Caption = "";
	} else
	{
		l_name.Caption = b.ItemName;
		l_desc.Caption = b.Description;
	}
	i_weapBG.ChangeToWeapon(b);
}

defaultproperties
{
     Begin Object Class=GUIWeaponImage Name=WeaponBack
         Image=Texture'Engine.WhiteSquareTexture'
         ImageColor=(B=0,G=0,R=0)
         ImageStyle=ISTY_Stretched
         ImageRenderStyle=MSTY_Normal
         WinHeight=1.000000
         OnRendered=WeaponBack.PostRenderBuyMenu
     End Object
     i_weapBG=GUIWeaponImage'KFGui.GUIBuyDescInfoPanel.WeaponBack'

     Begin Object Class=GUILabel Name=nameLabel
         TextColor=(B=50,G=50,R=255)
         WinTop=0.010000
         WinLeft=0.010000
         WinHeight=0.070000
     End Object
     l_name=GUILabel'KFGui.GUIBuyDescInfoPanel.nameLabel'

     Begin Object Class=GUILabel Name=descLabel
         TextColor=(B=200,G=200,R=200,A=200)
         TextFont="UT2SmallFont"
         bMultiLine=True
         WinTop=0.110000
         WinLeft=0.010000
         WinHeight=1.000000
     End Object
     l_desc=GUILabel'KFGui.GUIBuyDescInfoPanel.descLabel'

     i_back=None

}
