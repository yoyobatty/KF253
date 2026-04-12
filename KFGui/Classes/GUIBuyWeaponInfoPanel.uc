class GUIBuyWeaponInfoPanel extends GUIBuyDescInfoPanel;

var automated GUILabel l_power,l_range,l_speed; //Weapon stats captions
var automated GUIWeaponBar b_power,b_range,b_speed; //Weapon stats bars

function InitComponent( GUIController MyController, GUIComponent MyOwner )
{
	Super.InitComponent(MyController,MyOwner);
	b_power.SetValue(0);
	b_speed.SetValue(0);
	b_range.SetValue(0);
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
}

defaultproperties
{
     Begin Object Class=GUILabel Name=PowerCap
         Caption="Power:"
         TextColor=(B=200,G=200,R=200,A=100)
         WinTop=0.700000
         WinLeft=0.450000
         WinWidth=0.500000
         WinHeight=0.070000
     End Object
     l_power=GUILabel'KFGui.GUIBuyWeaponInfoPanel.PowerCap'

     Begin Object Class=GUILabel Name=RangeCap
         Caption="Range:"
         TextColor=(B=200,G=200,R=200,A=100)
         WinTop=0.800000
         WinLeft=0.450000
         WinWidth=0.500000
         WinHeight=0.070000
     End Object
     l_range=GUILabel'KFGui.GUIBuyWeaponInfoPanel.RangeCap'

     Begin Object Class=GUILabel Name=SpeedCap
         Caption="Speed:"
         TextColor=(B=200,G=200,R=200,A=100)
         WinTop=0.900000
         WinLeft=0.450000
         WinWidth=0.500000
         WinHeight=0.070000
     End Object
     l_speed=GUILabel'KFGui.GUIBuyWeaponInfoPanel.SpeedCap'

     Begin Object Class=GUIWeaponBar Name=PowerBar
         WinTop=0.700000
         WinLeft=0.650000
         WinWidth=0.330000
         WinHeight=0.070000
     End Object
     b_power=GUIWeaponBar'KFGui.GUIBuyWeaponInfoPanel.PowerBar'

     Begin Object Class=GUIWeaponBar Name=RangeBar
         WinTop=0.800000
         WinLeft=0.650000
         WinWidth=0.330000
         WinHeight=0.070000
     End Object
     b_range=GUIWeaponBar'KFGui.GUIBuyWeaponInfoPanel.RangeBar'

     Begin Object Class=GUIWeaponBar Name=SpeedBar
         WinTop=0.900000
         WinLeft=0.650000
         WinWidth=0.330000
         WinHeight=0.070000
     End Object
     b_speed=GUIWeaponBar'KFGui.GUIBuyWeaponInfoPanel.SpeedBar'

}
