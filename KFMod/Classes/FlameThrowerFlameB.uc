// The fire that gets spawned when a Fuel puddle is shot. This damages pawns and then dissipates.

class FlameThrowerFlameB extends Emitter;

defaultproperties
{
<<<<<<< HEAD
	Begin Object Class=SpriteEmitter Name=SpriteEmitter2
		UseColorScale=True
		FadeOut=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		UseRandomSubdivision=True
		ColorScale(1)=(RelativeTime=0.300000,Color=(B=255,G=255,R=255))
		ColorScale(2)=(RelativeTime=0.750000,Color=(B=255,G=255,R=255))
		ColorScale(3)=(RelativeTime=1.000000)
		ColorMultiplierRange=(Z=(Min=0.670000,Max=2.000000))
		FadeOutStartTime=0.501500
		MaxParticles=30
		StartLocationShape=PTLS_Sphere
		SphereRadiusRange=(Max=1.000000)
		SpinsPerSecondRange=(X=(Max=0.070000))
		StartSpinRange=(X=(Max=1.000000))
		SizeScale(0)=(RelativeTime=1.000000,RelativeSize=1.250000)
		StartSizeRange=(X=(Min=1.000000,Max=15.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
		ScaleSizeByVelocityMultiplier=(X=0.000000,Y=0.000000,Z=0.000000)
		ScaleSizeByVelocityMax=0.000000
		Texture=Texture'KillingFloorWeapons.FlameThrower.FlameThrowerFire'
		TextureUSubdivisions=1
		TextureVSubdivisions=1
		SecondsBeforeInactive=30.000000
		LifetimeRange=(Min=0.450000,Max=0.850000)
		StartVelocityRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=2.000000,Max=25.000000))
		MaxAbsVelocity=(X=100.000000,Y=100.000000,Z=100.000000)
	End Object
	Emitters(0)=SpriteEmitter'KFMod.FlameThrowerFlameB.SpriteEmitter2'

	LightType=LT_Flicker
	LightHue=30
	LightSaturation=100
	LightBrightness=300.000000
	LightRadius=4.000000
	bNoDelete=False
	bDynamicLight=True
	bNetTemporary=True
	Physics=PHYS_Trailer
=======
     Begin Object Class=SpriteEmitter Name=SpriteEmitter2
         UseColorScale=True
         FadeOut=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         UseRandomSubdivision=True
         ColorScale(1)=(RelativeTime=0.300000,Color=(B=255,G=255,R=255))
         ColorScale(2)=(RelativeTime=0.750000,Color=(B=255,G=255,R=255))
         ColorScale(3)=(RelativeTime=1.000000)
         ColorMultiplierRange=(Z=(Min=0.670000,Max=2.000000))
         FadeOutStartTime=0.501500
         MaxParticles=15
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=1.000000)
         SpinsPerSecondRange=(X=(Max=0.070000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeTime=1.000000,RelativeSize=1.150000)
         StartSizeRange=(X=(Min=1.000000,Max=15.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
         ScaleSizeByVelocityMultiplier=(X=0.000000,Y=0.000000,Z=0.000000)
         ScaleSizeByVelocityMax=0.000000
         Texture=Texture'KillingFloorWeapons.FlameThrower.FlameThrowerFire'
         TextureUSubdivisions=1
         TextureVSubdivisions=1
         SecondsBeforeInactive=30.000000
         LifetimeRange=(Min=0.450000,Max=0.850000)
         StartVelocityRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=2.000000,Max=25.000000))
         MaxAbsVelocity=(X=100.000000,Y=100.000000,Z=100.000000)
     End Object
     Emitters(0)=SpriteEmitter'KFMod.FlameThrowerFlameB.SpriteEmitter2'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         UseRandomSubdivision=True
         Acceleration=(Z=400.000000)
         ColorScale(1)=(Color=(A=50))
         ColorScale(2)=(RelativeTime=1.000000,Color=(A=255))
         FadeOutStartTime=1.000000
         FadeInEndTime=0.3500000
         MaxParticles=8
         StartLocationOffset=(Z=20.000000)
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=5.000000)
         SpinsPerSecondRange=(X=(Max=0.070000))
         StartSpinRange=(X=(Max=1.000000))
         SizeScale(0)=(RelativeTime=1.000000,RelativeSize=1.000000)
         StartSizeRange=(X=(Min=50.000000,Max=65.000000),Y=(Min=50.000000,Max=65.000000),Z=(Min=0.000000,Max=0.000000))
         ScaleSizeByVelocityMax=0.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'EmitterTextures.MultiFrame.smoke_a2'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         LifetimeRange=(Min=2.000000,Max=2.5000)
         StartVelocityRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=25.000000,Max=50.000000))
         VelocityLossRange=(X=(Min=2.000000,Max=2.000000),Y=(Min=2.000000,Max=2.000000),Z=(Min=4.000000,Max=4.000000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.FlameThrowerFlameB.SpriteEmitter0'

     LightType=LT_Pulse
     LightHue=30
     LightSaturation=100
     LightBrightness=300.000000
     LightRadius=4.000000
     bNoDelete=False
     bDynamicLight=True
     bNetTemporary=True
     Physics=PHYS_Trailer
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
