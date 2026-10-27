//=============================================================================
// KFElement
// The elements of upgraded weapons (Pack-a-Punch, KFWeapon.Element): each upgraded gun wears its element's moving
// camo on its metal and throws its colour in its flashes, tracers, light, hits and kills.
//   1 fire: Hellcats, Dragon's Breath, Hellfire, Executioner
//   2 blue fire: Blue Inferno
//   3 lightning (violet): Wasp, Hornet, Swarm, Overdrive
//   4 shock (white-blue): Thunderclap, Widowmaker
//   5 gold: Deadeye
//   6 toxic (green): Stinger
//   7 crimson: Bloodletter
// Materials made in play cannot be sent, so each machine makes its own, once (the camo of each gun in hand is its own,
// so that it can pulse with its shots).
//=============================================================================
class KFElement extends Object
	abstract;

#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx
#exec OBJ LOAD FILE=..\Textures\XEffectMat.utx
#exec OBJ LOAD FILE=..\Sounds\WeaponSounds.uax

const EL_NONE		= 0;
const EL_FIRE		= 1;
const EL_BLUEFIRE	= 2;
const EL_LIGHTNING	= 3;
const EL_SHOCK		= 4;
const EL_GOLD		= 5;
const EL_TOXIC		= 6;
const EL_CRIMSON	= 7;

var() Material	Patterns[8];	// the camo's picture, moving over the metal
var() color		Tints[8];		// ...times this colour
var() float		Brights[8];		// ...at this share (the pictures differ in how much of them is lit)
var() float		PanRates[8];
var() color		Glows[8];		// the element's colour: flashes, tracers, the gun's light, hits, kills
var() byte		Hues[8], Sats[8];	// ...as a light
var() Sound		FireLayer;		// the hum of energy under an upgraded gun's shot (KFFire.UpgradeLayer)
var() float		FireLayerVolume;
var() float		LayerPitches[8];	// ...pitched by element
var TexPanner	Panners[8];		// (made once on each machine)
var Material	Overlays[8];

static function bool Has( byte E )
{
	return E > EL_NONE && E < ArrayCount(default.Patterns) && default.Patterns[E] != None;
}

static function color Glow( byte E )
{
	return default.Glows[E];
}

// The camo's moving picture
static function Material Panner( byte E )
{
	local TexPanner P;

	if ( default.Panners[E] != None )
		return default.Panners[E];
	P = new class'TexPanner';
	P.Material = default.Patterns[E];
	P.PanDirection = rot(0,16384,0);
	P.PanRate = default.PanRates[E];
	default.Panners[E] = P;
	return P;
}

// A camo of its own: the moving picture times Level (set by SetLevel), for a Shader's Specular
static function Combiner Camo( byte E, ConstantColor Level )
{
	local Combiner C;

	C = new class'Combiner';
	C.CombineOperation = CO_Multiply;
	C.Material1 = Panner(E);
	C.Material2 = Level;
	return C;
}

// The camo's colour at K (1: as bright as it is made)
static function SetLevel( ConstantColor Level, byte E, float K )
{
	K *= default.Brights[E];
	Level.Color.R = Clamp(int(default.Tints[E].R * K), 0, 255);
	Level.Color.G = Clamp(int(default.Tints[E].G * K), 0, 255);
	Level.Color.B = Clamp(int(default.Tints[E].B * K), 0, 255);
	Level.Color.A = 255;
}

// Drawn over an upgraded gun in someone's hands (the whole third-person model)
static function Material Overlay( byte E )
{
	local ConstantColor CC;
	local Shader SH;

	if ( default.Overlays[E] != None )
		return default.Overlays[E];
	CC = new class'ConstantColor';
	SetLevel(CC, E, 1.6);
	SH = new class'Shader';
	SH.Specular = Camo(E, CC);
	default.Overlays[E] = SH;
	return SH;
}

defaultproperties
{
	FireLayer=Sound'WeaponSounds.BaseFiringSounds.BLinkGunFire'
	FireLayerVolume=0.550000
	LayerPitches(1)=0.750000
	LayerPitches(2)=0.900000
	LayerPitches(3)=1.250000
	LayerPitches(4)=1.100000
	LayerPitches(5)=1.000000
	LayerPitches(6)=0.850000
	LayerPitches(7)=0.800000
	Patterns(1)=Texture'EpicParticles.Smoke.FlameGradient'
	Patterns(2)=Texture'EpicParticles.PlasmaCube.PlasmaField02aw'
	Patterns(3)=Texture'XEffectMat.Shock.Shock_Elec_a'
	Patterns(4)=Texture'EpicParticles.PlasmaCube.PlasmaField02aw'
	Patterns(5)=Texture'EpicParticles.Smoke.SparkCloud_01aw'
	Patterns(6)=Texture'XEffectMat.Shield.shield_elec_green_a'
	Patterns(7)=Texture'EpicParticles.Smoke.FlameGradient'
	Tints(1)=(B=255,G=255,R=255)
	Tints(2)=(B=255,G=210,R=150)
	Tints(3)=(B=255,G=150,R=235)
	Tints(4)=(B=255,G=225,R=200)
	Tints(5)=(B=90,G=210,R=255)
	Tints(6)=(B=170,G=255,R=200)
	Tints(7)=(B=45,G=35,R=255)
	Brights(1)=0.180000
	Brights(2)=0.300000
	Brights(3)=0.450000
	Brights(4)=0.220000
	Brights(5)=0.900000
	Brights(6)=0.180000
	Brights(7)=0.220000
	PanRates(1)=0.120000
	PanRates(2)=0.080000
	PanRates(3)=0.060000
	PanRates(4)=0.080000
	PanRates(5)=0.050000
	PanRates(6)=0.070000
	PanRates(7)=0.100000
	Glows(1)=(B=60,G=150,R=255)
	Glows(2)=(B=255,G=170,R=100)
	Glows(3)=(B=255,G=120,R=200)
	Glows(4)=(B=255,G=225,R=200)
	Glows(5)=(B=90,G=205,R=255)
	Glows(6)=(B=90,G=255,R=130)
	Glows(7)=(B=40,G=25,R=230)
	Hues(1)=20
	Hues(2)=160
	Hues(3)=195
	Hues(4)=150
	Hues(5)=34
	Hues(6)=85
	Hues(7)=250
	Sats(1)=90
	Sats(2)=80
	Sats(3)=70
	Sats(4)=140
	Sats(5)=90
	Sats(6)=80
	Sats(7)=60
}
