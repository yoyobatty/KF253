//=============================================================================
// KFGasPuff
// How a cell of the fire grid's fuel vapour looks (KFFireGrid): a low, slow haze hanging over the floor, as thick as
// the vapour is (Thick, sent from the server).
//=============================================================================
class KFGasPuff extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx

var byte	Thick;
var byte	ShownThick;
var bool	bFading;
var bool	bShownFade;

replication
{
	unreliable if ( Role == ROLE_Authority )
		Thick, bFading;
}

// (the server) As thick as the vapour
function SetThick( float Gas )
{
	local byte T;

	T = byte(FClamp(Gas * 100.0, 1.0, 255.0));
	if ( Abs(int(T) - int(Thick)) >= 6 || Thick == 0 )
		Thick = T;
}

// (the server) Gone: the haze thins away
function Fade()
{
	bFading = true;
	LifeSpan = 4.0;
}

simulated function Tick( float DT )
{
	local float T;

	if ( Level.NetMode == NM_DedicatedServer )
		return;
	if ( bFading )
	{
		if ( !bShownFade )
		{
			bShownFade = true;
			Emitters[0].ParticlesPerSecond = 0;
			Emitters[0].InitialParticlesPerSecond = 0;
		}
		return;
	}
	if ( Thick == ShownThick )
		return;
	ShownThick = Thick;
	T = FMin(float(Thick) / 100.0, 2.0);
	Emitters[0].Opacity = FClamp(0.20 + 0.30 * T, 0.20, 0.65);
	Emitters[0].ParticlesPerSecond = 1.2 + 2.0 * T;
	Emitters[0].InitialParticlesPerSecond = Emitters[0].ParticlesPerSecond;
	Emitters[0].AllParticlesDead = false;
}

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=Vapour
         UseColorScale=True
         RespawnDeadParticles=False
         AutomaticInitialSpawning=False
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         Acceleration=(Z=2.000000)
         ColorScale(0)=(Color=(B=110,G=182,R=178,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=105,G=160,R=150,A=255))
         Opacity=0.250000
         FadeOutStartTime=2.200000
         FadeInEndTime=0.900000
         MaxParticles=11
         StartLocationRange=(X=(Min=-42.000000,Max=42.000000),Y=(Min=-42.000000,Max=42.000000),Z=(Min=4.000000,Max=34.000000))
         SpinsPerSecondRange=(X=(Min=-0.040000,Max=0.040000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.700000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.300000)
         StartSizeRange=(X=(Min=70.000000,Max=110.000000))
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         UseRandomSubdivision=True
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=3.000000,Max=4.000000)
         StartVelocityRange=(X=(Min=-8.000000,Max=8.000000),Y=(Min=-8.000000,Max=8.000000),Z=(Min=0.000000,Max=4.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFGasPuff.Vapour'

     bNoDelete=False
     bNotOnDedServer=False
     RemoteRole=ROLE_SimulatedProxy
     NetUpdateFrequency=3.000000
}
