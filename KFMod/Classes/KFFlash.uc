//=============================================================================
// KFFlash
// A gun's muzzle flash: a hot core, a star, petals of flame, a tongue ahead, a burst of fire, sparks, embers and a
// glow, each shot throwing the counts its gun's recipe asks for (Counts). One is kept for each muzzle: in first person
// the gun draws it at its muzzle (KFWeapon.MuzzleFlashFX), seen from outside it rides the third-person gun's tip
// (KFWeaponAttachment.DoFlashEmitter). X is ahead along the barrel.
//=============================================================================
class KFFlash extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx
#exec OBJ LOAD FILE=..\Textures\EmitterTextures.utx

const E_CORE	= 0;
const E_STAR	= 1;
const E_PETAL	= 2;
const E_TONGUE	= 3;
const E_FIRE	= 4;
const E_SPARK	= 5;
const E_EMBER	= 6;
const E_GLOW	= 7;

var() float	Size;			// the whole flash (the layers below are made for a 9mm at 1)
var() int	Counts[8];		// what each layer throws a shot
var() color	Tint;			// the flame's colour, over every layer but the white heat of the core and sparks
var() float	PetalSide;		// petals: 0 a cone ahead, 1 straight out to the sides (a muzzle brake's jets)
var() float	TongueLen;		// the tongue of flame ahead
var() float	ThirdSize;		// as seen on someone else's gun
var() float	Forward;		// how far ahead of the muzzle bone it is drawn (first person)
var() byte	FlashHue, FlashSat;	// the light it throws on the gun and the hands that hold it
var name	FlashBone;		// (first person: the bone of the gun it is drawn at)
var float	LiveUntil;		// (until when it has something to draw)
var bool	bThird, bDressed;
var bool	bReady, bPending;	// (a new one's layers are made in its first update: a shot before then waits for it)

// The recipe put on the layers (each made for Size 1 in first person)
simulated function Dress()
{
	local float K;
	local int i;

	bDressed = true;
	K = Size;
	if ( bThird )
		K *= ThirdSize;
	for ( i = 0; i < Emitters.Length; i++ )
	{
		Emitters[i].StartSizeRange.X.Min = default.Emitters[i].StartSizeRange.X.Min * K;
		Emitters[i].StartSizeRange.X.Max = default.Emitters[i].StartSizeRange.X.Max * K;
		Emitters[i].StartSizeRange.Y.Min = default.Emitters[i].StartSizeRange.Y.Min * K;
		Emitters[i].StartSizeRange.Y.Max = default.Emitters[i].StartSizeRange.Y.Max * K;
		Emitters[i].StartVelocityRange.X.Min = default.Emitters[i].StartVelocityRange.X.Min * K;
		Emitters[i].StartVelocityRange.X.Max = default.Emitters[i].StartVelocityRange.X.Max * K;
		Emitters[i].StartVelocityRange.Y.Min = default.Emitters[i].StartVelocityRange.Y.Min * K;
		Emitters[i].StartVelocityRange.Y.Max = default.Emitters[i].StartVelocityRange.Y.Max * K;
		Emitters[i].StartVelocityRange.Z.Min = default.Emitters[i].StartVelocityRange.Z.Min * K;
		Emitters[i].StartVelocityRange.Z.Max = default.Emitters[i].StartVelocityRange.Z.Max * K;
		Emitters[i].StartLocationOffset = default.Emitters[i].StartLocationOffset * K;
		Emitters[i].StartLocationRange.X.Min = default.Emitters[i].StartLocationRange.X.Min * K;
		Emitters[i].StartLocationRange.X.Max = default.Emitters[i].StartLocationRange.X.Max * K;
		if ( i != E_CORE && i != E_SPARK && i != E_EMBER )
		{
			Emitters[i].ColorMultiplierRange.X.Min = Tint.R / 255.0;
			Emitters[i].ColorMultiplierRange.X.Max = Tint.R / 255.0;
			Emitters[i].ColorMultiplierRange.Y.Min = Tint.G / 255.0;
			Emitters[i].ColorMultiplierRange.Y.Max = Tint.G / 255.0;
			Emitters[i].ColorMultiplierRange.Z.Min = Tint.B / 255.0;
			Emitters[i].ColorMultiplierRange.Z.Max = Tint.B / 255.0;
		}
	}
	// petals: jets out round the muzzle, leaning ahead less the more they go to the sides (a streak drawn along its
	// way is drawn its whole length whatever the angle, so none goes straight ahead, where it would be seen end on)
	Emitters[E_PETAL].StartVelocityRange.X.Min = (160 - 140 * PetalSide) * K;
	Emitters[E_PETAL].StartVelocityRange.X.Max = (260 - 200 * PetalSide) * K;
	Emitters[E_PETAL].StartVelocityRange.Y.Min = -(450 + 350 * PetalSide) * K;
	Emitters[E_PETAL].StartVelocityRange.Y.Max = (450 + 350 * PetalSide) * K;
	Emitters[E_PETAL].StartVelocityRange.Z.Min = -(450 + 350 * PetalSide) * K;
	Emitters[E_PETAL].StartVelocityRange.Z.Max = (450 + 350 * PetalSide) * K;
	// the tongue: beads of flame along the line of the barrel, so it is short seen from behind and long from the side
	Emitters[E_TONGUE].StartLocationRange.X.Min = TongueLen * 0.1 * K;
	Emitters[E_TONGUE].StartLocationRange.X.Max = TongueLen * 0.55 * K;
	Emitters[E_TONGUE].StartVelocityRange.X.Min = TongueLen * 1.0 * K;
	Emitters[E_TONGUE].StartVelocityRange.X.Max = TongueLen * 2.0 * K;
}

// A shot
simulated function Flash()
{
	local int i, n;

	LiveUntil = Level.TimeSeconds + 1.0;
	if ( !bReady )
	{
		bPending = true;
		return;
	}
	if ( !bDressed )
		Dress();
	for ( i = 0; i < Emitters.Length && i < ArrayCount(Counts); i++ )
	{
		n = Counts[i];
		if ( n > 1 && (i == E_SPARK || i == E_EMBER) && (Level.bDropDetail || Level.DetailMode == DM_Low) )
			n = (n + 1) / 2;
		if ( n > 0 )
		{
			Emitters[i].AllParticlesDead = false;
			Emitters[i].SpawnParticle(n);
		}
	}
	LiveUntil = Level.TimeSeconds + 1.0;
}

simulated function Tick( float DT )
{
	bReady = true;
	if ( bPending )
	{
		bPending = false;
		Flash();
	}
}

// In another colour (an upgraded gun's element: KFElement), from the next shot
simulated function SetTint( color C )
{
	if ( C == Tint )
		return;
	Tint = C;
	bDressed = false;
}

simulated function bool IsLive()
{
	return Level.TimeSeconds < LiveUntil;
}

defaultproperties
{
	Size=1.000000
	Counts(0)=1
	Counts(1)=1
	Counts(2)=3
	Counts(3)=3
	Counts(5)=2
	Counts(7)=1
	Tint=(B=150,G=215,R=255)
	PetalSide=0.400000
	TongueLen=16.000000
	ThirdSize=0.800000
	Forward=1.000000
	FlashHue=28
	FlashSat=110

	// white heat at the muzzle
	Begin Object Class=SpriteEmitter Name=FlashCore
		UseColorScale=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		CoordinateSystem=PTCS_Relative
		UseRotationFrom=PTRS_Actor
		ColorScale(0)=(Color=(B=235,G=250,R=255))
		ColorScale(1)=(RelativeTime=0.400000,Color=(B=120,G=200,R=255))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=6
		StartLocationOffset=(X=1.000000)
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.700000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.300000)
		StartSizeRange=(X=(Min=7.000000,Max=9.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Weapons.PlasmaFlare'
		LifetimeRange=(Min=0.040000,Max=0.050000)
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFFlash.FlashCore'

	// the star seen down the barrel
	Begin Object Class=SpriteEmitter Name=FlashStar
		UseColorScale=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		CoordinateSystem=PTCS_Relative
		UseRotationFrom=PTRS_Actor
		ColorScale(0)=(Color=(B=200,G=240,R=255))
		ColorScale(1)=(RelativeTime=0.500000,Color=(B=90,G=170,R=255))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=6
		StartLocationOffset=(X=3.000000)
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.600000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.200000)
		StartSizeRange=(X=(Min=12.000000,Max=16.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'EpicParticles.Flares.Sharpstreaks2'
		LifetimeRange=(Min=0.030000,Max=0.045000)
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFFlash.FlashStar'

	// petals of flame (Dress sets where they go)
	Begin Object Class=SpriteEmitter Name=FlashPetal
		UseDirectionAs=PTDU_Right
		UseColorScale=True
		UseSizeScale=True
		UseRegularSizeScale=False
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		CoordinateSystem=PTCS_Relative
		UseRotationFrom=PTRS_Actor
		ColorScale(0)=(Color=(B=170,G=235,R=255))
		ColorScale(1)=(RelativeTime=0.450000,Color=(B=60,G=160,R=255))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=24
		StartLocationOffset=(X=2.000000)
		SizeScale(0)=(RelativeSize=0.500000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.300000)
		StartSizeRange=(X=(Min=8.000000,Max=12.000000),Y=(Min=2.500000,Max=3.500000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Weapons.TracerShot'
		LifetimeRange=(Min=0.030000,Max=0.045000)
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFFlash.FlashPetal'

	// the tongue of flame ahead: beads along the barrel's line (Dress sets how far)
	Begin Object Class=SpriteEmitter Name=FlashTongue
		UseColorScale=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		CoordinateSystem=PTCS_Relative
		UseRotationFrom=PTRS_Actor
		ColorScale(0)=(Color=(B=190,G=245,R=255))
		ColorScale(1)=(RelativeTime=0.400000,Color=(B=70,G=175,R=255))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=30
		StartLocationRange=(X=(Min=2.000000,Max=16.000000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.700000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.250000)
		StartSizeRange=(X=(Min=3.500000,Max=5.500000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'EmitterTextures.MultiFrame.LargeFlames-grey'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=0.035000,Max=0.055000)
		StartVelocityRange=(X=(Min=30.000000,Max=60.000000))
	End Object
	Emitters(3)=SpriteEmitter'KFMod.KFFlash.FlashTongue'

	// a burst of fire rolling out (big guns)
	Begin Object Class=SpriteEmitter Name=FlashFire
		UseColorScale=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		CoordinateSystem=PTCS_Relative
		UseRotationFrom=PTRS_Actor
		ColorScale(0)=(Color=(B=200,G=245,R=255))
		ColorScale(1)=(RelativeTime=0.300000,Color=(B=70,G=175,R=255))
		ColorScale(2)=(RelativeTime=0.700000,Color=(B=10,G=45,R=130))
		ColorScale(3)=(RelativeTime=1.000000)
		MaxParticles=40
		StartLocationOffset=(X=4.000000)
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeSize=0.500000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.200000)
		StartSizeRange=(X=(Min=6.000000,Max=9.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'EmitterTextures.MultiFrame.LargeFlames-grey'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=0.050000,Max=0.080000)
		StartVelocityRange=(X=(Min=40.000000,Max=120.000000),Y=(Min=-55.000000,Max=55.000000),Z=(Min=-55.000000,Max=55.000000))
	End Object
	Emitters(4)=SpriteEmitter'KFMod.KFFlash.FlashFire'

	// sparks thrown ahead
	Begin Object Class=SpriteEmitter Name=FlashSpark
		UseDirectionAs=PTDU_Up
		UseColorScale=True
		ScaleSizeYByVelocity=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		CoordinateSystem=PTCS_Relative
		UseRotationFrom=PTRS_Actor
		Acceleration=(Z=-500.000000)
		ColorScale(0)=(Color=(B=210,G=245,R=255))
		ColorScale(1)=(RelativeTime=0.600000,Color=(B=40,G=150,R=255))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=40
		StartLocationOffset=(X=2.000000)
		StartSizeRange=(X=(Min=0.500000,Max=0.800000),Y=(Min=0.500000,Max=0.800000))
		ScaleSizeByVelocityMultiplier=(Y=0.002500)
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Energy.SparkHead'
		LifetimeRange=(Min=0.080000,Max=0.180000)
		StartVelocityRange=(X=(Min=700.000000,Max=1300.000000),Y=(Min=-220.000000,Max=220.000000),Z=(Min=-160.000000,Max=260.000000))
	End Object
	Emitters(5)=SpriteEmitter'KFMod.KFFlash.FlashSpark'

	// burning bits that drop away (shotguns' wads)
	Begin Object Class=SpriteEmitter Name=FlashEmber
		UseColorScale=True
		UniformSize=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		CoordinateSystem=PTCS_Relative
		UseRotationFrom=PTRS_Actor
		Acceleration=(Z=-350.000000)
		ColorScale(0)=(Color=(B=140,G=225,R=255))
		ColorScale(1)=(RelativeTime=0.500000,Color=(B=30,G=130,R=245))
		ColorScale(2)=(RelativeTime=1.000000)
		MaxParticles=40
		StartLocationOffset=(X=3.000000)
		StartSizeRange=(X=(Min=0.600000,Max=1.100000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'EpicParticles.Flares.HotSpot'
		LifetimeRange=(Min=0.250000,Max=0.550000)
		StartVelocityRange=(X=(Min=180.000000,Max=480.000000),Y=(Min=-110.000000,Max=110.000000),Z=(Min=-60.000000,Max=140.000000))
	End Object
	Emitters(6)=SpriteEmitter'KFMod.KFFlash.FlashEmber'

	// the glow round it
	Begin Object Class=SpriteEmitter Name=FlashGlow
		UseColorScale=True
		UniformSize=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		CoordinateSystem=PTCS_Relative
		UseRotationFrom=PTRS_Actor
		ColorScale(0)=(Color=(B=60,G=110,R=170))
		ColorScale(1)=(RelativeTime=1.000000)
		MaxParticles=4
		StartLocationOffset=(X=3.000000)
		StartSizeRange=(X=(Min=26.000000,Max=30.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'EpicParticles.Flares.SoftFlare'
		LifetimeRange=(Min=0.035000,Max=0.045000)
	End Object
	Emitters(7)=SpriteEmitter'KFMod.KFFlash.FlashGlow'

	bNoDelete=False
	bHardAttach=True
	RemoteRole=ROLE_None
}
