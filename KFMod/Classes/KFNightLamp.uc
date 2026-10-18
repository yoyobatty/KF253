//=============================================================================
// KFNightLamp - the night vision's illuminator (KFNightVision). Exists only on
// the player's own machine.
//=============================================================================
class KFNightLamp extends Light
	transient;

defaultproperties
{
     LightType=LT_Steady
     LightEffect=LE_None
     LightHue=0
     LightSaturation=255
     LightBrightness=0.000000
     LightRadius=24.000000
     bStatic=False
     bNoDelete=False
     bDynamicLight=False
     RemoteRole=ROLE_None
     bMovable=True
}
