//=============================================================================
// KFBlastEmitter
// A piece of a blast's dressing (KFBlast): its layers throw their Counts once, scaled by the blast's Size, in its
// first update (an emitter's layers are made then; what is thrown before is lost).
//=============================================================================
class KFBlastEmitter extends Emitter;

var() int	Counts[8];		// what each layer throws
var float	Size;			// the blast's (set by KFBlast before the first update)
var bool	bThrown;
var color	Tint;			// every layer times this colour, if bTint
var bool	bTint;
var bool	bKeepTicking;	// (a child that keeps working after the first update)

simulated function Tick( float DT )
{
	local int i, n;

	if ( bThrown )
	{
		if ( !bKeepTicking )
			Disable('Tick');
		return;
	}
	bThrown = true;
	for ( i = 0; i < Emitters.Length && i < ArrayCount(Counts); i++ )
	{
		Scale(i, Size);
		if ( bTint )
		{
			Emitters[i].ColorMultiplierRange.X.Min = Tint.R / 255.0;
			Emitters[i].ColorMultiplierRange.X.Max = Tint.R / 255.0;
			Emitters[i].ColorMultiplierRange.Y.Min = Tint.G / 255.0;
			Emitters[i].ColorMultiplierRange.Y.Max = Tint.G / 255.0;
			Emitters[i].ColorMultiplierRange.Z.Min = Tint.B / 255.0;
			Emitters[i].ColorMultiplierRange.Z.Max = Tint.B / 255.0;
		}
		n = Counts[i];
		if ( n > 1 && (Level.bDropDetail || Level.DetailMode == DM_Low) )
			n = (n + 1) / 2;
		if ( n > 0 )
			Emitters[i].SpawnParticle(n);
	}
}

// A layer made for a blast of Size 1, at K
simulated function Scale( int i, float K )
{
	Emitters[i].StartSizeRange.X.Min *= K;
	Emitters[i].StartSizeRange.X.Max *= K;
	Emitters[i].StartSizeRange.Y.Min *= K;
	Emitters[i].StartSizeRange.Y.Max *= K;
	Emitters[i].StartVelocityRange.X.Min *= K;
	Emitters[i].StartVelocityRange.X.Max *= K;
	Emitters[i].StartVelocityRange.Y.Min *= K;
	Emitters[i].StartVelocityRange.Y.Max *= K;
	Emitters[i].StartVelocityRange.Z.Min *= K;
	Emitters[i].StartVelocityRange.Z.Max *= K;
	Emitters[i].StartLocationRange.X.Min *= K;
	Emitters[i].StartLocationRange.X.Max *= K;
	Emitters[i].StartLocationRange.Y.Min *= K;
	Emitters[i].StartLocationRange.Y.Max *= K;
	Emitters[i].StartLocationRange.Z.Min *= K;
	Emitters[i].StartLocationRange.Z.Max *= K;
}

defaultproperties
{
	Size=1.000000
	bNoDelete=False
	RemoteRole=ROLE_None
	LifeSpan=6.000000
}
