class GUIBuyAmmoInfoPanel extends GUIBuyInfoPanel;

var automated GUIWeaponImage i_weapBG;    //Picture of ammo!
var automated GUILabel l_name,l_clipcost,l_fillcost,l_clips;

function Display(GUIBuyable newWeapon)
{
	local BuyableAmmo b;
	b = BuyableAmmo(newWeapon);
	if(b == None)
	{
		l_name.Caption = "";
		l_clipcost.Caption="";
		l_fillcost.Caption="";
		l_clips.Caption="";
	} else
	{
		l_name.Caption = b.ItemName;
		l_clipcost.Caption = "Clip cost:"@(b.Cost);
		l_fillcost.Caption = "Full Ammo:"@(b.Cost*B.BuyMoreClips());
		l_clips.Caption = "Have:"@B.NumClips()@"clips";
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
     i_weapBG=GUIWeaponImage'KFGui.GUIBuyAmmoInfoPanel.WeaponBack'

     Begin Object Class=GUILabel Name=nameLabel
         TextColor=(B=200,G=200,R=200,A=100)
         WinTop=0.010000
         WinLeft=0.010000
         WinHeight=0.070000
     End Object
     l_name=GUILabel'KFGui.GUIBuyAmmoInfoPanel.nameLabel'

     Begin Object Class=GUILabel Name=clipcost
         TextColor=(B=200,G=200,R=200,A=100)
         WinTop=0.900000
         WinLeft=0.010000
         WinHeight=0.070000
     End Object
     l_clipcost=GUILabel'KFGui.GUIBuyAmmoInfoPanel.clipcost'

     Begin Object Class=GUILabel Name=fillcost
         TextAlign=TXTA_Right
         TextColor=(B=200,G=200,R=200,A=100)
         WinTop=0.900000
         WinLeft=0.010000
         WinWidth=0.950000
         WinHeight=0.070000
     End Object
     l_fillcost=GUILabel'KFGui.GUIBuyAmmoInfoPanel.fillcost'

     Begin Object Class=GUILabel Name=clips
         TextAlign=TXTA_Right
         TextColor=(B=200,G=200,R=200,A=100)
         WinTop=0.600000
         WinLeft=0.350000
         WinWidth=0.500000
         WinHeight=0.070000
     End Object
     l_clips=GUILabel'KFGui.GUIBuyAmmoInfoPanel.clips'

     i_back=None

}
