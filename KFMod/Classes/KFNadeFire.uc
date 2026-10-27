// A fire an incendiary grenade leaves on the ground: FuelFlameHurting's burning, its own look (upright tongues of
// LargeFlames lifted off the floor, as FlameGroundFire's: KF's fire3 is bright to its frame edges and the floor cut the
// sprites; warm colours, darker smoke, a few embers going up)
class KFNadeFire extends FuelFlameHurting;

var KFNearFade	Near;			// (each machine) kept from filling the view up close
var float		NextNear;


// Up close to the player's eyes the flames are smaller and the smoke fainter (KFNearFade)
simulated function Tick( float DT )
{
	Super.Tick(DT);
	if ( bDyingDown || bDeleteMe || Level.NetMode == NM_DedicatedServer || Level.TimeSeconds < NextNear )
		return;
	NextNear = Level.TimeSeconds + 0.1;
	if ( Near == None )
		Near = new class'KFNearFade';
	Near.Apply(self, class'KFNearFade'.static.ViewK(self, Location, 100.0, 380.0, 0.35), 2);
}

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=NadeFireFlames
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UseRandomSubdivision=True
         Acceleration=(Z=85.000000)
         ColorScale(0)=(Color=(B=40,G=90,R=200))
         ColorScale(1)=(RelativeTime=0.250000,Color=(B=150,G=225,R=255))
         ColorScale(2)=(RelativeTime=0.700000,Color=(B=40,G=135,R=255))
         ColorScale(3)=(RelativeTime=1.000000,Color=(B=10,G=30,R=110))
         ColorMultiplierRange=(Y=(Min=0.850000,Max=1.000000),Z=(Min=0.600000,Max=0.900000))
         FadeOutStartTime=0.600000
         FadeInEndTime=0.150000
         MaxParticles=18
         StartLocationOffset=(Z=17.000000)
         StartLocationRange=(X=(Min=-18.000000,Max=18.000000),Y=(Min=-18.000000,Max=18.000000),Z=(Max=8.000000))
         SpinsPerSecondRange=(X=(Min=-0.040000,Max=0.040000))
         StartSpinRange=(X=(Min=-0.060000,Max=0.060000))
         SizeScale(0)=(RelativeSize=0.700000)
         SizeScale(1)=(RelativeTime=0.250000,RelativeSize=1.000000)
         SizeScale(2)=(RelativeTime=1.000000,RelativeSize=0.400000)
         StartSizeRange=(X=(Min=26.000000,Max=36.000000),Y=(Min=40.000000,Max=56.000000))
         Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         SecondsBeforeInactive=30.000000
         LifetimeRange=(Min=0.750000,Max=1.200000)
         StartVelocityRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=18.000000,Max=55.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFNadeFire.NadeFireFlames'

     Begin Object Class=SpriteEmitter Name=NadeFireSmoke
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         UseRandomSubdivision=True
         Acceleration=(Z=20.000000)
         ColorScale(0)=(Color=(B=28,G=30,R=34,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=50,G=50,R=52,A=255))
         Opacity=0.550000
         FadeOutStartTime=1.200000
         FadeInEndTime=0.500000
         MaxParticles=7
         StartLocationOffset=(Z=70.000000)
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=15.000000)
         SpinsPerSecondRange=(X=(Min=-0.050000,Max=0.050000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.800000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.400000)
         StartSizeRange=(X=(Min=45.000000,Max=70.000000))
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'EmitterTextures.MultiFrame.smoke_a2'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         SecondsBeforeInactive=30.000000
         LifetimeRange=(Min=2.000000,Max=2.400000)
         StartVelocityRange=(X=(Min=-15.000000,Max=15.000000),Y=(Min=-15.000000,Max=15.000000),Z=(Min=50.000000,Max=90.000000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFNadeFire.NadeFireSmoke'

     Begin Object Class=SpriteEmitter Name=NadeFireEmbers
         UseColorScale=True
         FadeOut=True
         UniformSize=True
         Acceleration=(Z=60.000000)
         ColorScale(0)=(Color=(B=110,G=210,R=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=10,G=40,R=150))
         FadeOutStartTime=0.800000
         MaxParticles=6
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=25.000000)
         StartSizeRange=(X=(Min=3.000000,Max=5.000000))
         Texture=Texture'EmitterTextures.Flares.EFlareOY'
         SecondsBeforeInactive=30.000000
         LifetimeRange=(Min=1.000000,Max=1.600000)
         StartVelocityRange=(X=(Min=-30.000000,Max=30.000000),Y=(Min=-30.000000,Max=30.000000),Z=(Min=60.000000,Max=140.000000))
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFNadeFire.NadeFireEmbers'
}
