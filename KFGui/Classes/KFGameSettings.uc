class KFGameSettings extends UT2K4Tab_GameSettings;

var localized string GoreText[4];		// Gore Level, GameInfo.GoreLevel 0 to 3: the game's three and Extreme over them (KFMod.KFGoreLevel)
var localized string GoreHint;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	local int i;

	Super.InitComponent(MyController, MyOwner);
	if ( co_GoreLevel != None )
	{
		co_GoreLevel.ResetComponent();
		for ( i = 0; i < ArrayCount(GoreText); i++ )
			co_GoreLevel.AddItem(GoreText[i]);
		co_GoreLevel.SetHint(GoreHint);
	}
}

function SaveSettings()
{
	Super.SaveSettings();
	// (in a game of one's own only the game's copy was set: the effects go by the class's, and change at once)
	class'GameInfo'.default.GoreLevel = iGore;
}

defaultproperties
{
     GoreText(0)="No Gore"
     GoreText(1)="Reduced Gore"
     GoreText(2)="Normal Gore"
     GoreText(3)="Extreme Gore"
     GoreHint="Extreme: every giblet and drop of blood. Normal: fewer giblets and a little less blood, for smoother big fights. Reduced: nothing cut off or blown apart. No Gore: no blood."

     ch_Dodging=None

     ch_ClassicTrans=None

     ch_Precache=None

}
