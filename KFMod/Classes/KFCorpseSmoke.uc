// What is left when the fire on a body has burnt out: embers that die down, and smoke for a while longer.
class KFCorpseSmoke extends Emitter;

var() float EmberTime, SmokeTime;
var bool bEmbersOut;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(EmberTime, false);
}

simulated function Timer()
{
	if ( !bEmbersOut )
	{
		bEmbersOut = true;
		Emitters[1].RespawnDeadParticles = false;
		SetTimer(SmokeTime - EmberTime, false);
	}
	else Kill();
}

defaultproperties
{
     EmberTime=3.500000
     SmokeTime=10.000000

     Begin Object Class=SpriteEmitter Name=Smoulder
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         UseRandomSubdivision=True
         Acceleration=(Z=25.000000)
         ColorScale(0)=(Color=(B=78,G=78,R=84,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=96,G=96,R=96,A=255))
         FadeOutStartTime=1.000000
         FadeInEndTime=0.600000
         MaxParticles=7
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=5.000000)
         SpinsPerSecondRange=(X=(Min=-0.040000,Max=0.040000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.500000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.200000)
         StartSizeRange=(X=(Min=18.000000,Max=30.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'EmitterTextures.MultiFrame.smoke_a2'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         SecondsBeforeInactive=30.000000
         LifetimeRange=(Min=2.200000,Max=3.000000)
         StartVelocityRange=(X=(Min=-5.000000,Max=5.000000),Y=(Min=-5.000000,Max=5.000000),Z=(Min=18.000000,Max=35.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFCorpseSmoke.Smoulder'

     Begin Object Class=SpriteEmitter Name=Embers
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         UseRandomSubdivision=True
         Acceleration=(Z=60.000000)
         ColorScale(0)=(Color=(B=110,G=190,R=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=10,G=50,R=160))
         FadeOutStartTime=0.200000
         FadeInEndTime=0.100000
         MaxParticles=5
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=3.000000)
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=0.500000)
         StartSizeRange=(X=(Min=6.000000,Max=12.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
         Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         SecondsBeforeInactive=30.000000
         LifetimeRange=(Min=0.350000,Max=0.700000)
         StartVelocityRange=(X=(Min=-4.000000,Max=4.000000),Y=(Min=-4.000000,Max=4.000000),Z=(Min=5.000000,Max=20.000000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFCorpseSmoke.Embers'

     bNoDelete=False
     RemoteRole=ROLE_None
}
