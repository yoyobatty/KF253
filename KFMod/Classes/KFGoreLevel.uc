//=============================================================================
// KFGoreLevel - how much gore this machine draws, by the player's Gore Level (Settings, Game: GameInfo.GoreLevel, kept
// in the mod's ini, each machine its own; KFGui.KFGameSettings):
//   3 Extreme  every giblet, loose scrap and drop of blood
//   2 Normal   (the usual) fewer giblets and loose bits, lying about a shorter while, a little less blood in the air,
//              and no more than NormalBodies bodies (NormalGibs, NormalLife, NormalBlood, NormalBodies)
//   1 Reduced  nothing cut off or blown apart, no great bursts of blood: small puffs where a round goes in (the game's
//              own low gore, GameInfo.UseLowGore)
//   0 None     no blood at all: a faint puff of dust where a round goes in (KFNoBloodHit, the gib groups' no-blood hit)
//=============================================================================
class KFGoreLevel extends Object
	abstract;

var() float NormalGibs;			// at Normal: the share of giblets and loose bits made
var() float NormalBlood;		// ...and of the blood thrown in the air
var() float NormalLife;			// ...and how long giblets and limbs lie about, against Extreme's
var() int NormalBodies;			// ...and how many bodies may lie about: past it the oldest sink away (KFMonster.SinkBody)

static function int Level()
{
	if ( class'GameInfo'.static.UseLowGore() )
		return Min(class'GameInfo'.default.GoreLevel, 1);
	return Min(class'GameInfo'.default.GoreLevel, 3);
}

// The share of giblets and loose bits made
static function float Gibs()
{
	if ( Level() >= 3 )
		return 1.0;
	return default.NormalGibs;
}

// The share of the blood thrown in the air
static function float Blood()
{
	if ( Level() >= 3 )
		return 1.0;
	return default.NormalBlood;
}

// How long giblets and limbs lie about, against Extreme's
static function float Life()
{
	if ( Level() >= 3 )
		return 1.0;
	return default.NormalLife;
}

// How many bodies may lie about (0: as many as there are)
static function int MaxBodies()
{
	if ( Level() == 2 )
		return default.NormalBodies;
	return 0;
}

// N giblets or bits, fewer at Normal (a share of one is a chance of one)
static function int SomeGibs( float N )
{
	return int(N * Gibs() + FRand());
}

defaultproperties
{
     NormalGibs=0.500000
     NormalBlood=0.700000
     NormalLife=0.600000
     NormalBodies=40
}
