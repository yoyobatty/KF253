//=============================================================================
// KFGasFlash
// A cell of fuel vapour going up at once (KFFireGrid.Flash): a ball of flame rolling up off the floor, a flash, a
// whoosh, a puff of black smoke; as big as the vapour was (Big). Bodies in it catch on each machine.
//=============================================================================
class KFGasFlash extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx
#exec OBJ LOAD FILE=KFnewSounds.uax

var byte	Big;
var bool	bShown;
var float	Age;

replication
{
	reliable if ( bNetInitial && Role == ROLE_Authority )
		Big;
}

// (the server) As much vapour as went up
function SetSize( float Gas )
{
	Big = byte(FClamp(Gas * 100.0, 10.0, 255.0));
}

simulated function Tick( float DT )
{
	local float S;
	local int i;
	local KFGasFlash O;

	Age += DT;
	if ( Level.NetMode == NM_DedicatedServer )
		return;
	if ( !bShown )
	{
		bShown = true;
		// one light for a front of flashes going up together (more washed the room out white)
		foreach DynamicActors(class'KFGasFlash', O)
			if ( O != self && O.LightType != LT_None && O.Age < 0.4 && VSize(O.Location - Location) < 450 )
			{
				LightType = LT_None;
				bDynamicLight = false;
				break;
			}
		S = 0.75 + 0.35 * FMin(float(Big) / 100.0, 2.0);
		class'KFGib'.static.Blast(self, Location, 0.25 * S, 0.6, true);
		for ( i = 0; i < Emitters.Length; i++ )
		{
			Emitters[i].StartSizeRange.X.Min *= S;
			Emitters[i].StartSizeRange.X.Max *= S;
			Emitters[i].StartSizeRange.Y.Min *= S;
			Emitters[i].StartSizeRange.Y.Max *= S;
		}
		PlaySound(Sound'KFnewSounds.GunShots.bangWhoosh', SLOT_None, 0.9 + 0.3 * FMin(float(Big) / 100.0, 1.0),, 900, 0.85 + 0.3 * FRand());
		class'KFMonster'.static.IgniteBodiesNear(self, 140, Location);
	}
	if ( LightType == LT_None )
		return;
	LightBrightness = default.LightBrightness * FClamp(1.0 - Age / 0.6, 0.0, 1.0);
	if ( Age > 0.6 )
		LightType = LT_None;
}

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=FlashBall
         UseColorScale=True
         RespawnDeadParticles=False
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         UseRandomSubdivision=True
         Acceleration=(Z=160.000000)
         ColorScale(0)=(Color=(B=90,G=190,R=255,A=255))
         ColorScale(1)=(RelativeTime=0.300000,Color=(B=30,G=130,R=245,A=255))
         ColorScale(2)=(RelativeTime=0.750000,Color=(B=20,G=80,R=210,A=255))
         ColorScale(3)=(RelativeTime=1.000000,Color=(B=5,G=20,R=60,A=255))
         FadeOutStartTime=0.350000
         FadeInEndTime=0.050000
         MaxParticles=14
         StartLocationRange=(X=(Min=-40.000000,Max=40.000000),Y=(Min=-40.000000,Max=40.000000),Z=(Min=-25.000000,Max=25.000000))
         SpinsPerSecondRange=(X=(Min=-0.300000,Max=0.300000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.500000)
         SizeScale(1)=(RelativeTime=0.400000,RelativeSize=1.100000)
         SizeScale(2)=(RelativeTime=1.000000,RelativeSize=1.400000)
         StartSizeRange=(X=(Min=45.000000,Max=80.000000))
         InitialParticlesPerSecond=400.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.550000,Max=0.900000)
         StartVelocityRange=(X=(Min=-90.000000,Max=90.000000),Y=(Min=-90.000000,Max=90.000000),Z=(Min=20.000000,Max=140.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFGasFlash.FlashBall'

     Begin Object Class=SpriteEmitter Name=FlashCore
         UseColorScale=True
         RespawnDeadParticles=False
         FadeOut=True
         UniformSize=True
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=60,G=160,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=10,G=60,R=200,A=255))
         FadeOutStartTime=0.050000
         MaxParticles=1
         StartSizeRange=(X=(Min=80.000000,Max=110.000000))
         InitialParticlesPerSecond=100.000000
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.220000,Max=0.300000)
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFGasFlash.FlashCore'

     Begin Object Class=SpriteEmitter Name=FlashSmoke
         UseColorScale=True
         RespawnDeadParticles=False
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         Acceleration=(Z=45.000000)
         ColorScale(0)=(Color=(B=30,G=30,R=34,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=40,G=40,R=42,A=255))
         Opacity=0.550000
         FadeOutStartTime=0.900000
         FadeInEndTime=0.300000
         MaxParticles=5
         StartLocationRange=(X=(Min=-30.000000,Max=30.000000),Y=(Min=-30.000000,Max=30.000000),Z=(Min=10.000000,Max=50.000000))
         SpinsPerSecondRange=(X=(Min=-0.100000,Max=0.100000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.600000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.600000)
         StartSizeRange=(X=(Min=55.000000,Max=80.000000))
         InitialParticlesPerSecond=8.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         UseRandomSubdivision=True
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=1.400000,Max=2.000000)
         InitialDelayRange=(Min=0.250000,Max=0.400000)
         StartVelocityRange=(X=(Min=-25.000000,Max=25.000000),Y=(Min=-25.000000,Max=25.000000),Z=(Min=20.000000,Max=60.000000))
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFGasFlash.FlashSmoke'

     LightType=LT_Steady
     LightHue=24
     LightSaturation=60
     LightBrightness=150.000000
     LightRadius=11.000000
     bDynamicLight=True
     AutoDestroy=True
     bNoDelete=False
     bNotOnDedServer=False
     RemoteRole=ROLE_SimulatedProxy
     bNetTemporary=True
     LifeSpan=3.500000
}
