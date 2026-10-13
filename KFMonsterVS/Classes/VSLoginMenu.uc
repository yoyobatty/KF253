class VSLoginMenu extends KFInvasionLoginMenu;

function InitComponent(GUIController MyController, GUIComponent MyComponent)
{
	Super(UT2K4PlayerLoginMenu).InitComponent(MyController, MyComponent);

	// Remove Perks tab
	c_Main.RemoveTab(Panels[1].Caption);
	c_Main.ActivateTabByName(Panels[0].Caption, true);
}

defaultproperties
{
     Panels(0)=(ClassName="KFMonsterVS.VSLoginControls")
}
