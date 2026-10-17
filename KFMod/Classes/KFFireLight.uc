//=============================================================================
// KFFireLight
// Ground fires share their light. A flamethrower sweep lays dozens of fires a few units apart, each with a flickering
// dynamic light, and every light makes each surface it reaches be drawn again: 32 ground fires cost about 1.1 ms a
// frame on KF-lockdown_v2, and a flamethrower fight had 80 or more lights in view. A fire that starts within
// ShareRadius of a lit one stays dark and makes that one brighter instead (its reach stays the same: the reach is
// what costs), and a lit fire that dies down hands its light on to the nearest dark one still burning.
//=============================================================================
class KFFireLight extends Object
	abstract
	config;

var config float ShareRadius;	// 0: every fire gives light, as before (config only so that the console's set can change it)

var config float ShareBrighten;	// a lit fire is this much brighter for each dark one sharing it
var config int MaxShared;		// up to this many

// The lit ground fire near a new one that the new one should share, if any
static function FuelFlameHurting LitNear(FuelFlameHurting Fire)
{
	local FuelFlameHurting F;

	if ( default.ShareRadius <= 0 || Fire.LightType == LT_None )
		return None;
	foreach Fire.RadiusActors(class'FuelFlameHurting', F, default.ShareRadius)
		if ( F != Fire && !F.bDeleteMe && !F.bDyingDown && F.LightType != LT_None )
			return F;
	return None;
}

// A lit ground fire is dying down: the nearest dark one near it that still burns takes its light
static function HandOver(FuelFlameHurting Fire)
{
	local FuelFlameHurting F, Best;
	local float D, BestD;

	if ( default.ShareRadius <= 0 )
		return;
	BestD = default.ShareRadius * 1.5;
	foreach Fire.RadiusActors(class'FuelFlameHurting', F, BestD)
		if ( F != Fire && F.bLightShared && !F.bDyingDown && !F.bDeleteMe && F.LightType == LT_None )
		{
			D = VSize(F.Location - Fire.Location);
			if ( D < BestD )
			{
				Best = F;
				BestD = D;
			}
		}
	if ( Best != None )
		Best.TakeLight();
}

defaultproperties
{
	ShareRadius=70.000000
	ShareBrighten=0.350000
	MaxShared=3
}
