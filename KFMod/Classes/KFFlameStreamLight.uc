//=============================================================================
// KFFlameStreamLight
// The one light of a flamethrower's stream (KFFlameStream), a little way along it, flickering.
//=============================================================================
class KFFlameStreamLight extends Effects;

simulated function Shine( vector Spot, float Level01 )
{
	SetLocation(Spot);
	LightBrightness = default.LightBrightness * Level01;
	LightRadius = default.LightRadius * (0.85 + 0.15 * Level01);
	bDynamicLight = Level01 > 0.02;
}

defaultproperties
{
	DrawType=DT_None
	LightType=LT_Steady
	LightEffect=LE_None
	LightHue=24
	LightSaturation=90
	LightBrightness=200.000000
	LightRadius=12.000000
	bDynamicLight=False
	bMovable=True
}
