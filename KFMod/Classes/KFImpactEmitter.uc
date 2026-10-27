//=============================================================================
// KFImpactEmitter
// A bullet's strike on a surface, after Ballistic Weapons' impacts: dust thrown out of the surface that slows, spreads
// and hangs, with sparks or a flash where the surface gives them. Its emitters take the actor's facing
// (UseRotationFrom PTRS_Actor: X out of the surface, as KFHitEffect spawns it). It throws Counts[i] of emitter i's
// particles at a strike of scale 1: the KFHitEffect that spawned it makes them fewer and smaller for a shotgun pellet,
// more and bigger for a Deagle round (ImpactScale), fewer when many pellets land at once (CountShare).
//=============================================================================
class KFImpactEmitter extends KFHitEmitter
	abstract;

var() int	Counts[8];

simulated function PostBeginPlay()
{
	local KFHitEffect From;
	local float K, N, G;
	local int i, Num;

	// (not KFHitEmitter's: that turns the first two emitters' speeds by hand, these take the actor's facing)
	Super(Emitter).PostBeginPlay();
	if ( ImpactSounds.Length > 0 )
		PlaySound(ImpactSounds[Rand(ImpactSounds.Length)]);

	K = 1.0;
	N = 1.0;
	From = KFHitEffect(Owner);
	if ( From != None )
	{
		K = From.ImpactScale;
		N = From.CountShare;
	}
	if ( Level.bDropDetail )
		N *= 0.6;
	G = Sqrt(K);
	for ( i = 0; i < Emitters.Length && i < ArrayCount(Counts); i++ )
	{
		if ( Emitters[i] == None || Emitters[i].Disabled )
			continue;
		if ( G != 1.0 )
		{
			Emitters[i].StartSizeRange.X.Min *= G;
			Emitters[i].StartSizeRange.X.Max *= G;
			Emitters[i].StartSizeRange.Y.Min *= G;
			Emitters[i].StartSizeRange.Y.Max *= G;
			Emitters[i].StartVelocityRange.X.Min *= G;
			Emitters[i].StartVelocityRange.X.Max *= G;
			Emitters[i].StartVelocityRange.Y.Min *= G;
			Emitters[i].StartVelocityRange.Y.Max *= G;
			Emitters[i].StartVelocityRange.Z.Min *= G;
			Emitters[i].StartVelocityRange.Z.Max *= G;
			Emitters[i].StartLocationOffset *= G;
		}
		// (a share of one is a chance of one)
		Num = int(Counts[i] * K * N + FRand());
		if ( Num > 0 )
			Emitters[i].SpawnParticle(Num);
	}
}

defaultproperties
{
	LifeSpan=4.000000
}
