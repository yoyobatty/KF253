//=============================================================================
// KFHitEffectPellet
// A shotgun pellet's strike: a small one, and fewer of its particles when many land at once (the double barrel's
// two shells throw 40 pellets): past the first eight pellets in 0.15 s each throws less.
//=============================================================================
class KFHitEffectPellet extends KFHitEffect;

var float	BurstStart;
var int		InBurst;

simulated function PostNetBeginPlay()
{
	if ( Level.TimeSeconds < default.BurstStart || Level.TimeSeconds - default.BurstStart > 0.15 )
	{
		default.BurstStart = Level.TimeSeconds;
		default.InBurst = 0;
	}
	default.InBurst++;
	CountShare = FMin(1.0, 8.0 / default.InBurst);
	Super.PostNetBeginPlay();
}

defaultproperties
{
	ImpactScale=0.450000
}
