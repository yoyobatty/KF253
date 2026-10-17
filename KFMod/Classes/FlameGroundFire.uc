//=============================================================================
// FlameGroundFire
// The fire a flamethrower tendril leaves where it hits something or burns out: it burns for a shorter time than a
// fire nade's and gives off less smoke (6 puffs at a time, not 8).
//=============================================================================
class FlameGroundFire extends FuelFlameHurting;

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=FlameGroundSmoke
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
        MaxParticles=6
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
     Emitters(1)=SpriteEmitter'KFMod.FlameGroundFire.FlameGroundSmoke'

     BurnTime=2.100000
     DieDownTime=1.800000
}
