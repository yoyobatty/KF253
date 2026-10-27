//=============================================================================
// KFZapConduct
// (Blue Inferno) The lightning running on from where it struck: over a metal floor to each specimen standing on it and
// off over the metal round about, or through water to all in it (FlameBurstFire.Conduct). The server sends it once;
// each machine that draws it lays the current along the floor (KFZapCrawl), sparks, a blue flash and a crack.
//=============================================================================
class KFZapConduct extends Actor;

var vector	Ends[6];
var byte	NumEnds;
var bool	bWater;
var bool	bShown;
var float	Age;

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		Ends, NumEnds, bWater;
}

// What the floor below P (within Below) is made of (3 metal; 255 no floor), and where it is
static function byte FloorSurface( Actor A, vector P, float Below, out vector Spot )
{
	local vector HN;
	local Material Mat;
	local Actor Hit;

	Hit = A.Trace(Spot, HN, P - vect(0,0,1) * Below, P, false,, Mat);
	if ( Hit == None || HN.Z < 0.6 )
		return 255;
	if ( !Hit.IsA('LevelInfo') && Hit.SurfaceType != EST_Default )
		return Hit.SurfaceType;
	if ( Mat != None )
		return Mat.SurfaceType;
	return 0;
}

// Metal floor all the way from one floor spot to another, and nothing in between
static function bool MetalPath( Actor A, vector From, vector To )
{
	local int n;
	local vector Spot;

	if ( !A.FastTrace(To + vect(0,0,20), From + vect(0,0,20)) )
		return false;
	for ( n = 1; n <= 3; n++ )
		if ( FloorSurface(A, From + (To - From) * (float(n) / 4.0) + vect(0,0,40), 110, Spot) != 3 )
			return false;
	return true;
}

simulated function Tick( float DT )
{
	Age += DT;
	if ( Level.NetMode == NM_DedicatedServer )
		return;
	if ( !bShown )
	{
		bShown = true;
		Show();
	}
	if ( LightType != LT_None )
	{
		LightBrightness = default.LightBrightness * FClamp(1.0 - Age / 0.18, 0.0, 1.0);
		if ( Age > 0.18 )
			LightType = LT_None;
	}
}

simulated function Show()
{
	local int i;

	for ( i = 0; i < NumEnds && i < ArrayCount(Ends); i++ )
		Arc(Location, Ends[i]);
	LightType = LT_Steady;
	bDynamicLight = true;
	PlaySound(Sound'KFMod.Zap.ZapFlesh', SLOT_None, 1.3,, 600, 0.55 + 0.25 * FRand());
}

// The current along the floor (or over the water) from one spot to another, in stretches that keep to the floor
simulated function Arc( vector From, vector To )
{
	local int n, Steps;
	local vector A, B, Spot;
	local KFZapCrawl C;

	Steps = Clamp(int(VSize(To - From) / 130.0) + 1, 1, 5);
	A = From;
	for ( n = 1; n <= Steps; n++ )
	{
		B = From + (To - From) * (float(n) / float(Steps));
		if ( n < Steps )
		{
			B.X += 30 * (FRand() - 0.5);
			B.Y += 30 * (FRand() - 0.5);
			if ( !bWater && FloorSurface(self, B + vect(0,0,40), 110, Spot) != 255 )
				B = Spot + vect(0,0,3);
		}
		C = Spawn(class'KFZapCrawl',,, A);
		if ( C != None )
			C.Span(A, B, n == Steps);
		A = B;
	}
}

defaultproperties
{
     DrawType=DT_None
     bHidden=True
     LightType=LT_None
     LightHue=165
     LightSaturation=70
     LightBrightness=130.000000
     LightRadius=7.000000
     RemoteRole=ROLE_SimulatedProxy
     bNetTemporary=True
     NetPriority=2.000000
     LifeSpan=0.800000
     bCollideActors=False
     bBlockActors=False
}
