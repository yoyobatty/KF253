// The fire on a burning body: soft flame over it, tongues licking up off it, and a little smoke.
// (The one before drew tiles of a sheet whose flames overrun their tiles, so they had straight edges.)
class KFMonsterFlame extends Emitter;

var KFNearFade	Near;			// (each machine) kept from filling the view up close
var float		NextNear;


// Up close to the player's eyes the flames are smaller and the smoke fainter (KFNearFade)
simulated function Tick( float DT )
{
	local vector At;

	if ( Level.NetMode == NM_DedicatedServer || Level.TimeSeconds < NextNear )
		return;
	NextNear = Level.TimeSeconds + 0.1;
	if ( Near == None )
		Near = new class'KFNearFade';
	At = Location;
	if ( Base != None )
		At = Base.Location;
	Near.Apply(self, class'KFNearFade'.static.ViewK(self, At, 70.0, 280.0, 0.35), 4);
}

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=BodyFire
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         Acceleration=(Z=90.000000)
         ColorScale(0)=(Color=(B=170,G=225,R=255))
         ColorScale(1)=(RelativeTime=0.450000,Color=(B=90,G=170,R=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=8,G=30,R=80))
         FadeOutStartTime=0.250000
         FadeInEndTime=0.080000
         MaxParticles=12
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=6.000000)
         SpinsPerSecondRange=(X=(Min=-0.080000,Max=0.080000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.600000)
         SizeScale(1)=(RelativeTime=0.300000,RelativeSize=1.000000)
         SizeScale(2)=(RelativeTime=1.000000,RelativeSize=0.550000)
         StartSizeRange=(X=(Min=13.000000,Max=22.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
         Texture=Texture'KillingFloorWeapons.FlameThrower.FlameThrowerFire'
         SecondsBeforeInactive=30.000000
         LifetimeRange=(Min=0.500000,Max=0.800000)
         StartVelocityRange=(X=(Min=-8.000000,Max=8.000000),Y=(Min=-8.000000,Max=8.000000),Z=(Min=20.000000,Max=55.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFMonsterFlame.BodyFire'

     Begin Object Class=SpriteEmitter Name=Tongues
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         UseRandomSubdivision=True
         Acceleration=(Z=160.000000)
         ColorScale(0)=(Color=(B=255,G=255,R=255))
         ColorScale(1)=(RelativeTime=0.600000,Color=(B=120,G=190,R=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=10,G=35,R=90))
         FadeOutStartTime=0.250000
         FadeInEndTime=0.060000
         MaxParticles=8
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=5.000000)
         SizeScale(0)=(RelativeSize=0.700000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.300000)
         StartSizeRange=(X=(Min=12.000000,Max=22.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
         Texture=Texture'EmitterTextures.MultiFrame.LargeFlames'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         SecondsBeforeInactive=30.000000
         LifetimeRange=(Min=0.350000,Max=0.600000)
         StartVelocityRange=(X=(Min=-6.000000,Max=6.000000),Y=(Min=-6.000000,Max=6.000000),Z=(Min=40.000000,Max=90.000000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFMonsterFlame.Tongues'

     Begin Object Class=SpriteEmitter Name=BodySmoke
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         UseRandomSubdivision=True
         Acceleration=(Z=40.000000)
         ColorScale(0)=(Color=(B=82,G=82,R=88,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=70,G=70,R=70,A=255))
         FadeOutStartTime=0.800000
         FadeInEndTime=0.500000
         MaxParticles=4
         StartLocationOffset=(Z=20.000000)
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=6.000000)
         SpinsPerSecondRange=(X=(Min=-0.050000,Max=0.050000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeSize=0.600000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.800000)
         StartSizeRange=(X=(Min=22.000000,Max=34.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'EmitterTextures.MultiFrame.smoke_a2'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         SecondsBeforeInactive=30.000000
         LifetimeRange=(Min=1.400000,Max=2.000000)
         StartVelocityRange=(X=(Min=-8.000000,Max=8.000000),Y=(Min=-8.000000,Max=8.000000),Z=(Min=30.000000,Max=60.000000))
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFMonsterFlame.BodySmoke'

     LightType=LT_Flicker
     LightHue=30
     LightSaturation=100
     LightBrightness=300.000000
     LightRadius=4.000000
     bNoDelete=False
     bDynamicLight=True
     bOnlyDrawIfAttached=True
     AmbientSound=Sound'GeneralAmbience.firefx12'
     bFullVolume=True
     SoundVolume=255
     bNotOnDedServer=False
}
