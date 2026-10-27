//=============================================================================
// KFGasSpray
// The flamethrower's gas mode as it is seen and heard (FlameAltFire): a hissing jet of unlit fuel off the nozzle that
// spreads and falls as it goes, with a mist of vapour round it. FlameThrowerAttachment feeds it at each squirt, on each
// machine that draws it; it stops when the squirts stop.
//=============================================================================
class KFGasSpray extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx

var float	LastFeed;
var bool	bOn;
var vector	Nozzle;
var rotator	Aim;
var() float	JetRate, MistRate, JetSpeed;

simulated function Feed()
{
	LastFeed = Level.TimeSeconds;
	if ( !bOn )
		TurnOn();
}

simulated function TurnOn()
{
	bOn = true;
	Rates(JetRate, MistRate);
	AmbientSound = default.AmbientSound;
}

simulated function TurnOff()
{
	bOn = false;
	Rates(0, 0);
	AmbientSound = None;
}

simulated function Rates( float Jet, float Mist )
{
	Emitters[0].ParticlesPerSecond = Jet;
	Emitters[0].InitialParticlesPerSecond = Jet;
	Emitters[1].ParticlesPerSecond = Mist;
	Emitters[1].InitialParticlesPerSecond = Mist;
	if ( Jet > 0 )
	{
		Emitters[0].AllParticlesDead = false;
		Emitters[1].AllParticlesDead = false;
	}
}

simulated function Tick( float DT )
{
	if ( bOn && (Instigator == None || Instigator.Health <= 0 || Level.TimeSeconds - LastFeed > 0.25) )
		TurnOff();
	if ( Instigator == None )
		return;
	PlaceAtNozzle();
}

// At the nozzle, the drawn one in its holder's own first-person view, aimed along the holder's aim
simulated function PlaceAtNozzle()
{
	local vector X, Y, Z;
	local FlameThrower FT;
	local rangevector R;

	Aim = class'KFFlameStream'.static.AimOf(Instigator);
	FT = FlameThrower(Instigator.Weapon);
	if ( FT != None && Level.TimeSeconds - FT.DrawnNozzleTime < 0.1 )
		Nozzle = FT.DrawnNozzle;
	else if ( Owner != None && Level.TimeSeconds - Owner.LastRenderTime < 0.2 )
		Nozzle = Owner.GetBoneCoords('tip').Origin;
	else
	{
		GetAxes(Aim, X, Y, Z);
		Nozzle = Instigator.Location + Instigator.EyePosition() + 50 * X + 8 * Y - 14 * Z;
	}
	SetLocation(Nozzle);
	GetAxes(Aim, X, Y, Z);
	R.X.Min = X.X * JetSpeed - 60;
	R.X.Max = X.X * JetSpeed + 60;
	R.Y.Min = X.Y * JetSpeed - 60;
	R.Y.Max = X.Y * JetSpeed + 60;
	R.Z.Min = X.Z * JetSpeed - 30;
	R.Z.Max = X.Z * JetSpeed + 50;
	Emitters[0].StartVelocityRange = R;
	R.X.Min = X.X * JetSpeed * 0.45 - 70;
	R.X.Max = X.X * JetSpeed * 0.45 + 70;
	R.Y.Min = X.Y * JetSpeed * 0.45 - 70;
	R.Y.Max = X.Y * JetSpeed * 0.45 + 70;
	R.Z.Min = X.Z * JetSpeed * 0.45 - 40;
	R.Z.Max = X.Z * JetSpeed * 0.45 + 50;
	Emitters[1].StartVelocityRange = R;
}

defaultproperties
{
     JetRate=55.000000
     MistRate=14.000000
     JetSpeed=820.000000

     Begin Object Class=SpriteEmitter Name=FuelJet
         UseColorScale=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         Acceleration=(Z=-520.000000)
         ColorScale(0)=(Color=(B=150,G=205,R=210,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=125,G=180,R=180,A=255))
         Opacity=0.450000
         FadeOutStartTime=0.400000
         FadeInEndTime=0.040000
         MaxParticles=60
         SpinsPerSecondRange=(X=(Min=-0.300000,Max=0.300000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.200000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.600000)
         StartSizeRange=(X=(Min=14.000000,Max=22.000000))
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         UseRandomSubdivision=True
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.550000,Max=0.750000)
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFGasSpray.FuelJet'

     Begin Object Class=SpriteEmitter Name=FuelMist
         UseColorScale=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         Acceleration=(Z=-60.000000)
         ColorScale(0)=(Color=(B=130,G=185,R=180,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=115,G=165,R=160,A=255))
         Opacity=0.200000
         FadeOutStartTime=0.800000
         FadeInEndTime=0.200000
         MaxParticles=24
         SpinsPerSecondRange=(X=(Min=-0.100000,Max=0.100000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.500000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.200000)
         StartSizeRange=(X=(Min=26.000000,Max=40.000000))
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         UseRandomSubdivision=True
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=1.200000,Max=1.600000)
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFGasSpray.FuelMist'

     AmbientSound=Sound'IndoorAmbience.hiss1'
     SoundVolume=190
     SoundRadius=260.000000
     bNoDelete=False
     bNotOnDedServer=False
}
