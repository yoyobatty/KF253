//=============================================================================
// KFElementDeath
// A specimen killed by an upgraded weapon dies in its element (KFMonster.DeathElement): a burst of its colour, and
//   lightning and shock: arcs crawl over the body while it jerks;
//   fire and blue fire: embers, and the body burns on where it falls (KFMonster.ElementDeath);
//   gold: a shower of gold sparks; toxic and crimson: a low mist of the colour.
// Kept small and dark. Each machine makes its own over its own body, and it follows the body.
//=============================================================================
class KFElementDeath extends KFBlastEmitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx

const L_BURST	= 0;
const L_SPARK	= 1;
const L_ARC		= 2;
const L_MIST	= 3;
const L_EMBER	= 4;

var() float	ArcTime;		// seconds the arcs crawl over the body
var() float	ArcRate;		// ...arcs a second
var() float	JerkEvery;		// seconds between the body's jerks while the arcs crawl
var() float	JerkPush;		// ...how hard each is
var byte	Element;
var float	Age, ArcDebt, NextJerk;
var bool	bArcs;

// The element of a killer's weapon, if it is an upgraded one (0: none)
static function byte ElementOf( Controller Killer )
{
	local KFWeapon W;

	if ( Killer == None || Killer.Pawn == None )
		return 0;
	W = KFWeapon(Killer.Pawn.Weapon);
	if ( W == None || !W.bUpgraded || !class'KFElement'.static.Has(W.Element) )
		return 0;
	return W.Element;
}

// (elements by number, as KFElement lists them: 1 fire, 2 blue fire, 3 lightning, 4 shock, 5 gold, 6 toxic, 7 crimson)
static function Make( Pawn Body, byte E )
{
	local KFElementDeath D;

	if ( Body == None || !class'KFElement'.static.Has(E) )
		return;
	D = Body.Spawn(class'KFElementDeath', Body,, Body.Location);
	if ( D == None )
		return;
	D.Element = E;
	D.Tint = class'KFElement'.static.Glow(E);
	D.bTint = true;
	D.bArcs = (E == 3 || E == 4);
	D.Counts[L_SPARK] = 6;
	D.Counts[L_MIST] = 0;
	D.Counts[L_EMBER] = 0;
	if ( E == 1 || E == 2 )
		D.Counts[L_EMBER] = 14;
	else if ( E == 5 )
	{
		D.Counts[L_SPARK] = 22;
		D.Counts[L_EMBER] = 8;
	}
	else if ( E == 6 || E == 7 )
		D.Counts[L_MIST] = 5;
	// (blood is kept dark: a crimson kill's mist is a dim red haze)
	if ( E == 7 )
	{
		D.Emitters[L_MIST].Opacity = 0.3;
		D.Emitters[L_MIST].ColorScale[0].Color = class'Canvas'.static.MakeColor(80, 80, 80, 255);
		D.Emitters[L_MIST].ColorScale[1].Color = class'Canvas'.static.MakeColor(55, 55, 55, 255);
		D.Emitters[L_BURST].StartSizeRange.X.Min = 35;
		D.Emitters[L_BURST].StartSizeRange.X.Max = 40;
	}
}

simulated function Tick( float DT )
{
	local int n;
	local vector Spot;

	Super.Tick(DT);
	Age += DT;
	if ( Owner == None || Owner.bDeleteMe )
		return;
	SetLocation(Owner.Location);
	if ( !bArcs || Age > ArcTime )
		return;
	// arcs crawl over the body, fewer as they die out
	ArcDebt += DT * ArcRate * (1.0 - 0.6 * Age / ArcTime);
	n = int(ArcDebt);
	if ( n > 0 )
	{
		ArcDebt -= n;
		Emitters[L_ARC].SpawnParticle(n);
	}
	// and the body jerks
	if ( Age >= NextJerk && Owner.Physics == PHYS_KarmaRagdoll )
	{
		NextJerk = Age + JerkEvery * (0.6 + 0.8 * FRand());
		Spot = Owner.Location + VRand() * 20.0;
		Owner.KAddImpulse(VRand() * JerkPush * (1.0 - 0.5 * Age / ArcTime), Spot);
	}
}

defaultproperties
{
	ArcTime=1.100000
	ArcRate=26.000000
	JerkEvery=0.090000
	JerkPush=5000.000000
	bKeepTicking=True
	Counts(0)=1
	Counts(1)=6
	LifeSpan=4.000000

	Begin Object Class=SpriteEmitter Name=DeathBurst
		UseColorScale=True
		UniformSize=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		ColorScale(0)=(Color=(B=255,G=255,R=255))
		ColorScale(1)=(RelativeTime=1.000000)
		MaxParticles=2
		StartSizeRange=(X=(Min=60.000000,Max=70.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'EpicParticles.Flares.FlashFlare1'
		LifetimeRange=(Min=0.250000,Max=0.250000)
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFElementDeath.DeathBurst'

	Begin Object Class=SpriteEmitter Name=DeathSparks
		UseDirectionAs=PTDU_Up
		UseColorScale=True
		ScaleSizeYByVelocity=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		Acceleration=(Z=-600.000000)
		ColorScale(0)=(Color=(B=255,G=255,R=255))
		ColorScale(1)=(RelativeTime=0.600000,Color=(B=190,G=190,R=190))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=40
		StartLocationRange=(X=(Min=-15.000000,Max=15.000000),Y=(Min=-15.000000,Max=15.000000),Z=(Min=-20.000000,Max=30.000000))
		StartSizeRange=(X=(Min=0.600000,Max=1.000000),Y=(Min=0.600000,Max=1.000000))
		ScaleSizeByVelocityMultiplier=(Y=0.003000)
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Energy.SparkHead'
		LifetimeRange=(Min=0.300000,Max=0.700000)
		StartVelocityRange=(X=(Min=-350.000000,Max=350.000000),Y=(Min=-350.000000,Max=350.000000),Z=(Min=50.000000,Max=450.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFElementDeath.DeathSparks'

	Begin Object Class=SpriteEmitter Name=DeathArcs
		UseColorScale=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		ColorScale(0)=(Color=(B=255,G=255,R=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=120,G=120,R=120))
		MaxParticles=40
		StartLocationRange=(X=(Min=-22.000000,Max=22.000000),Y=(Min=-22.000000,Max=22.000000),Z=(Min=-30.000000,Max=40.000000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.800000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.100000)
		StartSizeRange=(X=(Min=16.000000,Max=30.000000),Y=(Min=6.000000,Max=10.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Energy.PowerBolt'
		LifetimeRange=(Min=0.060000,Max=0.120000)
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFElementDeath.DeathArcs'

	Begin Object Class=SpriteEmitter Name=DeathMist
		FadeOut=True
		FadeIn=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		Acceleration=(Z=8.000000)
		ColorScale(0)=(Color=(B=150,G=150,R=150,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=110,G=110,R=110,A=255))
		Opacity=0.450000
		FadeOutStartTime=0.600000
		FadeInEndTime=0.150000
		MaxParticles=10
		StartLocationRange=(X=(Min=-20.000000,Max=20.000000),Y=(Min=-20.000000,Max=20.000000),Z=(Min=-25.000000,Max=10.000000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.600000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.800000)
		StartSizeRange=(X=(Min=28.000000,Max=40.000000))
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'AW-2004Particles.Fire.MuchSmoke1'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=1.400000,Max=2.000000)
		StartVelocityRange=(X=(Min=-30.000000,Max=30.000000),Y=(Min=-30.000000,Max=30.000000),Z=(Min=5.000000,Max=30.000000))
	End Object
	Emitters(3)=SpriteEmitter'KFMod.KFElementDeath.DeathMist'

	Begin Object Class=SpriteEmitter Name=DeathEmbers
		UseColorScale=True
		UniformSize=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		Acceleration=(Z=-40.000000)
		ColorScale(0)=(Color=(B=255,G=255,R=255))
		ColorScale(1)=(RelativeTime=0.500000,Color=(B=150,G=150,R=150))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=30
		StartLocationRange=(X=(Min=-20.000000,Max=20.000000),Y=(Min=-20.000000,Max=20.000000),Z=(Min=-25.000000,Max=30.000000))
		StartSizeRange=(X=(Min=0.900000,Max=1.700000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'EpicParticles.Flares.HotSpot'
		LifetimeRange=(Min=1.200000,Max=2.400000)
		StartVelocityRange=(X=(Min=-60.000000,Max=60.000000),Y=(Min=-60.000000,Max=60.000000),Z=(Min=40.000000,Max=140.000000))
		VelocityLossRange=(X=(Min=0.400000,Max=0.800000),Y=(Min=0.400000,Max=0.800000),Z=(Min=0.400000,Max=0.800000))
	End Object
	Emitters(4)=SpriteEmitter'KFMod.KFElementDeath.DeathEmbers'
}
