// The fire that gets spawned when a Fuel puddle is shot. This damages pawns and then dissipates.
class FuelFlame extends Emitter;

var () float BurnInterval; // Interval between burn damage.

simulated function PostBeginPlay()
{ 
	SetTimer(BurnInterval,True);
}

function Timer()
{
	local Material SurfaceMat;
	local int HitSurface;
	local Vector HitLocation, HitNormal;
	local rotator EffectDir;
	local Actor Other;
  
	Other = Trace(HitLocation, HitNormal, Location + vector(Rotation) * 32, Location - vector(Rotation) * 16, true,, SurfaceMat);

	EffectDir = rotator(MirrorVectorByNormal(vector(Rotation), HitNormal));

	if(Vehicle(Other) != None && Other.SurfaceType == 0)
		HitSurface = 3;
	else if(Other != None && !Other.IsA('LevelInfo') && Other.SurfaceType != 0)
		HitSurface = Other.SurfaceType;
	else if(SurfaceMat != None)
		HitSurface = SurfaceMat.SurfaceType;

	if (SurfaceMat != none)
	{
		if (KFHumanPawn(Instigator) != none)
			Kill();
	}
}

defaultproperties
{
     BurnInterval=1.000000
     Begin Object Class=SpriteEmitter Name=SpriteEmitter10
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         UseRandomSubdivision=True
         Acceleration=(Z=100.000000)
         ColorScale(1)=(RelativeTime=0.300000,Color=(B=255,G=255,R=255))
         ColorScale(2)=(RelativeTime=0.750000,Color=(B=96,G=160,R=255))
         ColorScale(3)=(RelativeTime=1.000000)
         ColorMultiplierRange=(Z=(Min=0.670000,Max=2.000000))
         MaxParticles=15
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=5.000000)
         SpinsPerSecondRange=(X=(Max=0.070000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeTime=1.000000,RelativeSize=0.500000)
         StartSizeRange=(X=(Min=56.000000,Max=45.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
         ScaleSizeByVelocityMultiplier=(X=0.000000,Y=0.000000,Z=0.000000)
         ScaleSizeByVelocityMax=0.000000
         Texture=Texture'KillingFloorTextures.LondonCommon.fire3'
         TextureUSubdivisions=2
         TextureVSubdivisions=2
         SecondsBeforeInactive=30.000000
         LifetimeRange=(Min=0.750000,Max=1.250000)
         StartVelocityRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=25.000000,Max=75.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.FuelFlame.SpriteEmitter10'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
        UseColorScale=True
        FadeOut=True
        FadeIn=True
        FadeOutStartTime=1.00000
        FadeInEndTime=0.250000
        SpinParticles=True
        UseSizeScale=True
        UseRegularSizeScale=False
        UniformSize=True
        UseRandomSubdivision=True
        Acceleration=(Z=400.000000)
        ColorScale(1)=(Color=(A=50))
        ColorScale(2)=(RelativeTime=1.000000,Color=(A=255))
        MaxParticles=8
        StartLocationOffset=(Z=20.000000)
        StartLocationShape=PTLS_Sphere
        SphereRadiusRange=(Max=10.000000)
        SpinsPerSecondRange=(X=(Max=0.070000))
        StartSpinRange=(X=(Max=1.000000))
        SizeScale(0)=(RelativeTime=1.000000,RelativeSize=1.000000)
        StartSizeRange=(X=(Min=50.000000,Max=75.000000),Y=(Min=50.000000,Max=75.000000),Z=(Min=0.000000,Max=0.000000))
        ScaleSizeByVelocityMax=0.000000
        DrawStyle=PTDS_AlphaBlend
        Texture=Texture'EmitterTextures.MultiFrame.smoke_a2'
        TextureUSubdivisions=4
        TextureVSubdivisions=4
        LifetimeRange=(Min=2.250000,Max=2.50000)
        StartVelocityRange=(X=(Min=-20.000000,Max=20.000000),Y=(Min=-20.000000,Max=20.000000),Z=(Min=25.000000,Max=50.000000))
        VelocityLossRange=(X=(Min=2.000000,Max=2.000000),Y=(Min=2.000000,Max=2.000000),Z=(Min=4.000000,Max=4.000000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.FuelFlame.SpriteEmitter0'

     LightType=LT_Pulse
     LightHue=30
     LightSaturation=100
     LightBrightness=300.000000
     LightRadius=4.000000
     bNoDelete=False
     bDynamicLight=True
     AmbientSound=Sound'GeneralAmbience.firefx12'
     //LifeSpan=6.000000
     bFullVolume=True
     SoundVolume=255
     CollisionRadius=5.000000
     CollisionHeight=5.000000
     bCollideWorld=True
     bUseCylinderCollision=True
}
