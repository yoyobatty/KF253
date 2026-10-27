//=============================================================================
// KFBlastLight
// A blast lighting up the room round it, bright at once and dying away (KFBlast)
//=============================================================================
class KFBlastLight extends Effects;

var() float	Duration;		// seconds to die away
var float	Size;			// the blast's
var float	Age;

simulated function Tick( float DT )
{
	local float K;

	Age += DT;
	K = 1.0 - Age / Duration;
	if ( K <= 0.0 )
	{
		Destroy();
		return;
	}
	LightBrightness = default.LightBrightness * K * K;
	LightRadius = default.LightRadius * Size * (0.75 + 0.25 * K);
}

defaultproperties
{
	Duration=0.450000
	Size=1.000000
	DrawType=DT_None
	LightType=LT_Steady
	LightEffect=LE_None
	LightHue=26
	LightSaturation=110
	LightBrightness=255.000000
	LightRadius=16.000000
	bDynamicLight=True
	bMovable=True
	RemoteRole=ROLE_None
}
