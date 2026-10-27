//=============================================================================
// KFPaPShow
// The upgrade machine at work (KFPackAPunchMachine): it hums, crackles and glows in the element of the weapon in it
// (KFElement) while the weapon is in it, and gives it back with a burst of light. Sent once from the server; each
// machine makes its own.
//=============================================================================
class KFPaPShow extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=..\Textures\EpicParticles.utx
#exec OBJ LOAD FILE=..\Sounds\PickupSounds.uax
#exec OBJ LOAD FILE=..\Sounds\ONSVehicleSounds-S.uax

var byte	ShowElement;		// the weapon's element
var float	ShowTime;			// seconds the weapon is in the machine
var float	Age;
var bool	bDressed, bDone;
var() Sound	StartSound, EndSound;

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		ShowElement, ShowTime;
}

simulated function Tick( float DT )
{
	local int i;
	local color C;

	if ( !bDressed )
	{
		bDressed = true;
		if ( class'KFElement'.static.Has(ShowElement) )
		{
			C = class'KFElement'.static.Glow(ShowElement);
			for ( i = 0; i < Emitters.Length; i++ )
			{
				Emitters[i].ColorMultiplierRange.X.Min = C.R / 255.0;
				Emitters[i].ColorMultiplierRange.X.Max = C.R / 255.0;
				Emitters[i].ColorMultiplierRange.Y.Min = C.G / 255.0;
				Emitters[i].ColorMultiplierRange.Y.Max = C.G / 255.0;
				Emitters[i].ColorMultiplierRange.Z.Min = C.B / 255.0;
				Emitters[i].ColorMultiplierRange.Z.Max = C.B / 255.0;
			}
			LightHue = class'KFElement'.default.Hues[ShowElement];
			LightSaturation = class'KFElement'.default.Sats[ShowElement];
		}
		PlaySound(StartSound, SLOT_None, 1.5,, 600.0);
	}
	Age += DT;
	// the glow swells as the work goes on, and the last light dies with the burst
	if ( !bDone )
		LightBrightness = 50 + 70 * FMin(Age / FMax(ShowTime, 0.1), 1.0) * (0.7 + 0.3 * Sin(Age * 18.0));
	else
		LightBrightness = FMax(0.0, LightBrightness - DT * 300.0);
	if ( !bDone && Age >= ShowTime )
	{
		bDone = true;
		AmbientSound = None;
		PlaySound(EndSound, SLOT_None, 2.0,, 900.0);
		Emitters[3].SpawnParticle(2);
		Emitters[4].SpawnParticle(30);
		Emitters[0].ParticlesPerSecond = 0;
		Emitters[0].InitialParticlesPerSecond = 0;
		Emitters[1].ParticlesPerSecond = 0;
		Emitters[1].InitialParticlesPerSecond = 0;
		Emitters[2].ParticlesPerSecond = 0;
		Emitters[2].InitialParticlesPerSecond = 0;
		LightBrightness = 150;
		LightRadius = default.LightRadius * 1.3;
		LifeSpan = 1.2;
	}
}

defaultproperties
{
	ShowTime=3.000000
	StartSound=Sound'ONSVehicleSounds-S.PRV.PRVChargeUp'
	EndSound=Sound'PickupSounds.UDamagePickup'
	AmbientSound=Sound'ONSVehicleSounds-S.RV.RVChargeLoop01'
	SoundVolume=200
	SoundRadius=120.000000

	// the glow at the machine
	Begin Object Class=SpriteEmitter Name=ShowGlow
		UseColorScale=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		ColorScale(0)=(Color=(B=255,G=255,R=255))
		ColorScale(1)=(RelativeTime=1.000000)
		MaxParticles=6
		ParticlesPerSecond=8.000000
		InitialParticlesPerSecond=8.000000
		SizeScale(0)=(RelativeSize=0.700000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.300000)
		StartSizeRange=(X=(Min=26.000000,Max=34.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'EpicParticles.Flares.SoftFlare'
		LifetimeRange=(Min=0.500000,Max=0.700000)
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFPaPShow.ShowGlow'

	// sparks thrown up out of it
	Begin Object Class=SpriteEmitter Name=ShowSparks
		UseDirectionAs=PTDU_Up
		UseColorScale=True
		ScaleSizeYByVelocity=True
		Acceleration=(Z=-500.000000)
		ColorScale(0)=(Color=(B=255,G=255,R=255))
		ColorScale(1)=(RelativeTime=1.000000)
		MaxParticles=40
		ParticlesPerSecond=14.000000
		InitialParticlesPerSecond=14.000000
		StartLocationRange=(X=(Min=-20.000000,Max=20.000000),Y=(Min=-20.000000,Max=20.000000),Z=(Min=0.000000,Max=30.000000))
		StartSizeRange=(X=(Min=0.600000,Max=1.000000),Y=(Min=0.600000,Max=1.000000))
		ScaleSizeByVelocityMultiplier=(Y=0.003000)
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Energy.SparkHead'
		LifetimeRange=(Min=0.400000,Max=0.800000)
		StartVelocityRange=(X=(Min=-120.000000,Max=120.000000),Y=(Min=-120.000000,Max=120.000000),Z=(Min=150.000000,Max=380.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFPaPShow.ShowSparks'

	// arcs crackling round it
	Begin Object Class=SpriteEmitter Name=ShowArcs
		UseColorScale=True
		SpinParticles=True
		ColorScale(0)=(Color=(B=255,G=255,R=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=120,G=120,R=120))
		MaxParticles=20
		ParticlesPerSecond=16.000000
		InitialParticlesPerSecond=16.000000
		StartLocationRange=(X=(Min=-30.000000,Max=30.000000),Y=(Min=-30.000000,Max=30.000000),Z=(Min=-10.000000,Max=40.000000))
		StartSpinRange=(X=(Max=1.000000))
		StartSizeRange=(X=(Min=20.000000,Max=34.000000),Y=(Min=6.000000,Max=10.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Energy.PowerBolt'
		LifetimeRange=(Min=0.060000,Max=0.120000)
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFPaPShow.ShowArcs'

	// the burst as it gives the weapon back
	Begin Object Class=SpriteEmitter Name=ShowBurst
		UseColorScale=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		ColorScale(0)=(Color=(B=255,G=255,R=255))
		ColorScale(1)=(RelativeTime=1.000000)
		MaxParticles=4
		SizeScale(0)=(RelativeSize=0.500000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.000000)
		StartSizeRange=(X=(Min=26.000000,Max=32.000000))
		DrawStyle=PTDS_Brighten
		Texture=Texture'EpicParticles.Flares.FlashFlare1'
		LifetimeRange=(Min=0.400000,Max=0.400000)
	End Object
	Emitters(3)=SpriteEmitter'KFMod.KFPaPShow.ShowBurst'

	// sparks flung out with the burst
	Begin Object Class=SpriteEmitter Name=ShowBurstSparks
		UseDirectionAs=PTDU_Up
		UseColorScale=True
		ScaleSizeYByVelocity=True
		RespawnDeadParticles=False
		AutomaticInitialSpawning=False
		Acceleration=(Z=-600.000000)
		ColorScale(0)=(Color=(B=255,G=255,R=255))
		ColorScale(1)=(RelativeTime=1.000000)
		MaxParticles=30
		StartSizeRange=(X=(Min=0.700000,Max=1.200000),Y=(Min=0.700000,Max=1.200000))
		ScaleSizeByVelocityMultiplier=(Y=0.003000)
		DrawStyle=PTDS_Brighten
		Texture=Texture'AW-2004Particles.Energy.SparkHead'
		LifetimeRange=(Min=0.500000,Max=0.900000)
		StartVelocityRange=(X=(Min=-320.000000,Max=320.000000),Y=(Min=-320.000000,Max=320.000000),Z=(Min=60.000000,Max=420.000000))
	End Object
	Emitters(4)=SpriteEmitter'KFMod.KFPaPShow.ShowBurstSparks'

	LightType=LT_Steady
	LightEffect=LE_None
	LightHue=30
	LightSaturation=120
	LightBrightness=150.000000
	LightRadius=6.000000
	bDynamicLight=True
	bNoDelete=False
	RemoteRole=ROLE_SimulatedProxy
	bNetTemporary=True
	bAlwaysRelevant=True
	bReplicateMovement=False
	LifeSpan=8.000000
}
