// A specimen staggered and open to a glory kill (KFMonster.bGloryReady), Doom style: it flashes blue, and orange once the
// one watching is near enough to finish it by hand (Near). KFMonster spreads the glow over the body.
class KFGloryGlow extends Emitter;

var bool bNear;

// Blue far off, orange in reach
simulated function Near( bool bIn )
{
	if ( bIn == bNear )
		return;
	bNear = bIn;
	if ( bNear )
	{
		Emitters[0].ColorScale[0].Color = class'Canvas'.static.MakeColor(255, 170, 40, 255);
		Emitters[0].ColorScale[1].Color = class'Canvas'.static.MakeColor(255, 90, 10, 255);
		Emitters[1].ColorScale[0].Color = class'Canvas'.static.MakeColor(200, 90, 15, 255);
		Emitters[1].ColorScale[1].Color = class'Canvas'.static.MakeColor(140, 45, 5, 255);
		LightHue = 22;
		LightSaturation = 30;
	}
	else
	{
		Emitters[0].ColorScale[0].Color = class'Canvas'.static.MakeColor(120, 190, 255, 255);
		Emitters[0].ColorScale[1].Color = class'Canvas'.static.MakeColor(40, 110, 255, 255);
		Emitters[1].ColorScale[0].Color = class'Canvas'.static.MakeColor(40, 90, 200, 255);
		Emitters[1].ColorScale[1].Color = class'Canvas'.static.MakeColor(15, 40, 150, 255);
		LightHue = 160;
		LightSaturation = 40;
	}
}

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=GlorySparks
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         Acceleration=(Z=40.000000)
         ColorScale(0)=(Color=(B=255,G=190,R=120,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=110,R=40,A=255))
         FadeOutStartTime=0.400000
         FadeInEndTime=0.100000
         MaxParticles=36
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=6.000000)
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=0.300000)
         StartSizeRange=(X=(Min=5.000000,Max=9.000000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'KFX.KFSparkHead'
         TextureUSubdivisions=1
         TextureVSubdivisions=2
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.600000,Max=1.000000)
         StartVelocityRange=(X=(Min=-14.000000,Max=14.000000),Y=(Min=-14.000000,Max=14.000000),Z=(Min=10.000000,Max=40.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFGloryGlow.GlorySparks'

     Begin Object Class=SpriteEmitter Name=GloryHalo
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         UniformSize=True
         ColorScale(0)=(Color=(B=200,G=90,R=40,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=150,G=40,R=15,A=255))
         FadeOutStartTime=0.200000
         FadeInEndTime=0.150000
         MaxParticles=6
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=8.000000)
         StartSizeRange=(X=(Min=40.000000,Max=60.000000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.350000,Max=0.500000)
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFGloryGlow.GloryHalo'

     LightType=LT_Pulse
     LightHue=160
     LightSaturation=40
     LightBrightness=220.000000
     LightRadius=7.000000
     LightPeriod=18
     bNoDelete=False
     bDynamicLight=True
     bOnlyDrawIfAttached=True
     bNotOnDedServer=False
}
