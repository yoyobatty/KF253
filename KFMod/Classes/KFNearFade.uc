//=============================================================================
// KFNearFade
// Fire, smoke and fuel vapour kept from filling the player's view: what is close to the eyes of the player at this
// machine is drawn smaller and fainter, the closer the more, and as before further off. ViewK says how close something
// is; Apply does it to an emitter whose sizes and smoke are otherwise fixed (each emitter keeps one of these, which
// remembers its own sizes as first seen). bOff (for a test) leaves everything as it was.
//=============================================================================
class KFNearFade extends Object;

var() bool		bOff;
var bool		bTaken;
var float		LastK;
var array<float>	SXMin, SXMax, SYMin, SYMax, Opa;

// 1 at Far and further from the player's eyes, MinK at Near and closer, eased between
static function float ViewK( Actor A, vector Spot, float Near, float Far, float MinK )
{
	local PlayerController PC;
	local vector Eye;
	local float D;

	if ( default.bOff || A == None || A.Level.NetMode == NM_DedicatedServer )
		return 1.0;
	PC = A.Level.GetLocalPlayerController();
	if ( PC == None )
		return 1.0;
	Eye = PC.CalcViewLocation;
	if ( Eye == vect(0,0,0) && PC.ViewTarget != None )
		Eye = PC.ViewTarget.Location;
	D = VSize(Spot - Eye);
	if ( D >= Far )
		return 1.0;
	if ( D <= Near )
		return MinK;
	D = (D - Near) / (Far - Near);
	return MinK + (1.0 - MinK) * D * D * (3.0 - 2.0 * D);
}

// The emitters of E drawn for K: the flames' new particles K as big, smoke (SmokeMask, one bit an emitter) K * K as solid
function Apply( Emitter E, float K, int SmokeMask )
{
	local int i;

	if ( E == None )
		return;
	if ( !bTaken )
	{
		bTaken = true;
		for ( i = 0; i < E.Emitters.Length; i++ )
		{
			SXMin[i] = E.Emitters[i].StartSizeRange.X.Min;
			SXMax[i] = E.Emitters[i].StartSizeRange.X.Max;
			SYMin[i] = E.Emitters[i].StartSizeRange.Y.Min;
			SYMax[i] = E.Emitters[i].StartSizeRange.Y.Max;
			Opa[i] = E.Emitters[i].Opacity;
		}
		LastK = 1.0;
	}
	if ( Abs(K - LastK) < 0.03 )
		return;
	LastK = K;
	for ( i = 0; i < E.Emitters.Length && i < Opa.Length; i++ )
	{
		if ( (SmokeMask & (1 << i)) != 0 )
			E.Emitters[i].Opacity = Opa[i] * K * K;
		else
		{
			E.Emitters[i].StartSizeRange.X.Min = SXMin[i] * K;
			E.Emitters[i].StartSizeRange.X.Max = SXMax[i] * K;
			E.Emitters[i].StartSizeRange.Y.Min = SYMin[i] * K;
			E.Emitters[i].StartSizeRange.Y.Max = SYMax[i] * K;
		}
	}
}
