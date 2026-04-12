class GUIWeaponBar extends GUIProgressBar;

function ResetColor()
{
	local float red,green;
	red = FMin((100-GetValue())*2,100);
	green = FMin(GetValue()*2,100);

	BarColor.R=red;
	BarColor.G=green;
	BarColor.B=0;
	BarColor.A=255;
}

function SetValue(float val)
{
	Value=val+20;
	ResetColor();
}

function float GetValue()
{
	return Value-20;
}

defaultproperties
{
     BarBack=Texture'KFInterfaceContent.Menu.BorderBoxD'
     BarTop=Texture'KFInterfaceContent.Menu.StatusBarInner'
     Low=20.000000
     High=120.000000
     CaptionWidth=0.000000
     ValueRightWidth=0.000000
     bShowValue=False
}
