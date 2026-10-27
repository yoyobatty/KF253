class GUIBuyWeaponInfoPanel extends GUIBuyDescInfoPanel;

var automated GUILabel l_power,l_range,l_speed; //Weapon stats captions
var automated GUIWeaponBar b_power,b_range,b_speed; //Weapon stats bars
var automated GUIImage i_backdrop;					// the panel black behind its words; the gun is drawn in a part of it
var automated GUIBuyUpgradeLines lu_upgrades;		// its upgrades, with their prices

// (laid out down the tall panel the trader has at its right: the name and what it is, the gun turning, its bars, its
// upgrades)
function InitComponent( GUIController MyController, GUIComponent MyOwner )
{
	Super.InitComponent(MyController,MyOwner);
	b_power.SetValue(0);
	b_speed.SetValue(0);
	b_range.SetValue(0);
	l_name.WinTop = 0.010;
	l_name.WinHeight = 0.050;
	l_desc.WinTop = 0.065;
	l_desc.WinHeight = 0.200;
	l_desc.WinLeft = 0.020;
	l_desc.WinWidth = 0.960;
	i_weapBG.WinTop = 0.220;
	i_weapBG.WinHeight = 0.290;
	i_weapBG.ImageColor.A = 0;
}

function Display(GUIBuyable newWeapon)
{
	local BuyableWeapon b;
	b = BuyableWeapon(newWeapon);
	if(b == None)
	{
		b_power.SetValue(-20);
		b_speed.SetValue(-20);
		b_range.SetValue(-20);
	} else
	{
		b_power.SetValue(b.PowerValue);
		b_speed.SetValue(b.SpeedValue);
		b_range.SetValue(b.RangeValue);
	}
	Super.Display(newWeapon);
	lu_upgrades.Fill(GUIBuyMenu(PageOwner), newWeapon);
}

defaultproperties
{
     Begin Object Class=GUIImage Name=Backdrop
         Image=Texture'Engine.WhiteSquareTexture'
         ImageColor=(B=0,G=0,R=0)
         ImageStyle=ISTY_Stretched
         ImageRenderStyle=MSTY_Normal
         WinHeight=1.000000
         RenderWeight=0.050000
     End Object
     i_backdrop=GUIImage'KFGui.GUIBuyWeaponInfoPanel.Backdrop'

     Begin Object Class=GUIBuyUpgradeLines Name=UpgradeLines
         WinTop=0.670000
         WinLeft=0.040000
         WinWidth=0.920000
         WinHeight=0.320000
         RenderWeight=0.600000
     End Object
     lu_upgrades=GUIBuyUpgradeLines'KFGui.GUIBuyWeaponInfoPanel.UpgradeLines'

     Begin Object Class=GUILabel Name=PowerCap
         Caption="Power:"
         TextColor=(B=200,G=200,R=200,A=100)
         WinTop=0.520000
         WinLeft=0.060000
         WinWidth=0.300000
         WinHeight=0.038000
     End Object
     l_power=GUILabel'KFGui.GUIBuyWeaponInfoPanel.PowerCap'

     Begin Object Class=GUILabel Name=RangeCap
         Caption="Range:"
         TextColor=(B=200,G=200,R=200,A=100)
         WinTop=0.565000
         WinLeft=0.060000
         WinWidth=0.300000
         WinHeight=0.038000
     End Object
     l_range=GUILabel'KFGui.GUIBuyWeaponInfoPanel.RangeCap'

     Begin Object Class=GUILabel Name=SpeedCap
         Caption="Speed:"
         TextColor=(B=200,G=200,R=200,A=100)
         WinTop=0.610000
         WinLeft=0.060000
         WinWidth=0.300000
         WinHeight=0.038000
     End Object
     l_speed=GUILabel'KFGui.GUIBuyWeaponInfoPanel.SpeedCap'

     Begin Object Class=GUIWeaponBar Name=PowerBar
         WinTop=0.520000
         WinLeft=0.380000
         WinWidth=0.560000
         WinHeight=0.038000
     End Object
     b_power=GUIWeaponBar'KFGui.GUIBuyWeaponInfoPanel.PowerBar'

     Begin Object Class=GUIWeaponBar Name=RangeBar
         WinTop=0.565000
         WinLeft=0.380000
         WinWidth=0.560000
         WinHeight=0.038000
     End Object
     b_range=GUIWeaponBar'KFGui.GUIBuyWeaponInfoPanel.RangeBar'

     Begin Object Class=GUIWeaponBar Name=SpeedBar
         WinTop=0.610000
         WinLeft=0.380000
         WinWidth=0.560000
         WinHeight=0.038000
     End Object
     b_speed=GUIWeaponBar'KFGui.GUIBuyWeaponInfoPanel.SpeedBar'

}
