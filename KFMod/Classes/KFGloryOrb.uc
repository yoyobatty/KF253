// What a glory kill gives (KFGloryBurst): a glowing drop that leaps out of the body and flies to the one who made the
// kill: green for health, gold for ammunition, blue for armour. On their own machine each that lands gives a flash.
class KFGloryOrb extends Emitter;

var Pawn Taker;
var float Age, Delay;
var vector Drift;
var byte Kind;					// 0 health, 1 ammunition, 2 armour

simulated function Go( Pawn To, byte K, vector Out )
{
	Taker = To;
	Kind = K;
	Drift = Out;
	Delay = 0.12 + 0.18 * FRand();
	switch ( Kind )
	{
		case 0:
			Emitters[0].ColorScale[0].Color = class'Canvas'.static.MakeColor(120, 255, 120, 255);
			Emitters[0].ColorScale[1].Color = class'Canvas'.static.MakeColor(20, 200, 40, 255);
			Emitters[1].ColorScale[0].Color = class'Canvas'.static.MakeColor(40, 220, 60, 255);
			Emitters[1].ColorScale[1].Color = class'Canvas'.static.MakeColor(10, 120, 20, 255);
			break;
		case 1:
			Emitters[0].ColorScale[0].Color = class'Canvas'.static.MakeColor(255, 230, 110, 255);
			Emitters[0].ColorScale[1].Color = class'Canvas'.static.MakeColor(255, 160, 20, 255);
			Emitters[1].ColorScale[0].Color = class'Canvas'.static.MakeColor(230, 170, 30, 255);
			Emitters[1].ColorScale[1].Color = class'Canvas'.static.MakeColor(140, 90, 10, 255);
			break;
		default:
			Emitters[0].ColorScale[0].Color = class'Canvas'.static.MakeColor(140, 200, 255, 255);
			Emitters[0].ColorScale[1].Color = class'Canvas'.static.MakeColor(40, 120, 255, 255);
			Emitters[1].ColorScale[0].Color = class'Canvas'.static.MakeColor(50, 120, 240, 255);
			Emitters[1].ColorScale[1].Color = class'Canvas'.static.MakeColor(15, 50, 160, 255);
	}
}

simulated function Tick( float DeltaTime )
{
	local vector To, D;
	local float Dist, Speed;
	local PlayerController PC;

	Age += DeltaTime;
	if ( Taker == None || Taker.bDeleteMe || Age > 2.5 )
	{
		Kill();
		LifeSpan = 1.0;
		Disable('Tick');
		return;
	}
	// out of the body first, then to the taker, faster and faster
	if ( Age < Delay )
	{
		SetLocation(Location + Drift * DeltaTime);
		Drift *= 0.9;
		return;
	}
	To = Taker.Location + vect(0,0,1) * (0.4 * Taker.CollisionHeight);
	D = To - Location;
	Dist = VSize(D);
	Speed = 350.0 + 1600.0 * (Age - Delay);
	if ( Dist <= Speed * DeltaTime + 8.0 )
	{
		PC = Level.GetLocalPlayerController();
		if ( PC != None && PC.Pawn == Taker && PC.Pawn != None )
		{
			switch ( Kind )
			{
				case 0:		PC.ClientFlash(0.86, vect(160,420,160));	break;
				case 1:		PC.ClientFlash(0.88, vect(420,340,120));	break;
				default:	PC.ClientFlash(0.86, vect(150,260,500));
			}
			Taker.PlaySound(Sound'PickupSounds.HealthPack', SLOT_None, 0.5 + 0.2 * FRand(),, 200.0, 1.4 + 0.3 * FRand());
		}
		Kill();
		LifeSpan = 0.6;
		Disable('Tick');
		return;
	}
	SetLocation(Location + D / Dist * Speed * DeltaTime);
}

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=OrbTrail
         UseColorScale=True
         FadeOut=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ColorScale(0)=(Color=(B=120,G=255,R=120,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=40,G=200,R=20,A=255))
         FadeOutStartTime=0.050000
         MaxParticles=30
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=0.200000)
         StartSizeRange=(X=(Min=4.000000,Max=6.000000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'KFX.KFSparkHead'
         TextureUSubdivisions=1
         TextureVSubdivisions=2
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.250000,Max=0.350000)
         ParticlesPerSecond=80.000000
         InitialParticlesPerSecond=80.000000
         AutomaticInitialSpawning=False
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFGloryOrb.OrbTrail'

     Begin Object Class=SpriteEmitter Name=OrbCore
         UseColorScale=True
         UniformSize=True
         ColorScale(0)=(Color=(B=60,G=220,R=40,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=20,G=120,R=10,A=255))
         MaxParticles=2
         StartSizeRange=(X=(Min=14.000000,Max=18.000000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.200000,Max=0.200000)
         ParticlesPerSecond=12.000000
         InitialParticlesPerSecond=12.000000
         AutomaticInitialSpawning=False
         UseVelocityScale=False
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFGloryOrb.OrbCore'

     bNoDelete=False
     RemoteRole=ROLE_None
     bNotOnDedServer=True
}
