// A specimen being electrocuted (KFMonster.bZapped): flashes, sparks thrown off it and small arcs crackling over it, and the
// sound of it (the Ballistic Weapons HVC Mk9's player effect). KFMonster spreads it over the body each tick.
class KFZapBody extends Emitter;

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=ZapFlash
         UseColorScale=True
         FadeOut=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=0.157143,Color=(B=255,G=255,R=128,A=255))
         ColorScale(2)=(RelativeTime=0.346429,Color=(B=255,G=192,R=64,A=255))
         ColorScale(3)=(RelativeTime=1.000000,Color=(B=255,G=128,A=255))
         ColorMultiplierRange=(X=(Min=0.350000,Max=0.350000),Y=(Min=0.550000,Max=0.550000),Z=(Min=0.900000,Max=0.900000))
         FadeOutStartTime=0.125000
         MaxParticles=1
         StartLocationRange=(Z=(Min=-20.000000,Max=20.000000))
         SizeScale(0)=(RelativeSize=1.600000)
         SizeScale(1)=(RelativeTime=0.070000,RelativeSize=1.300000)
         SizeScale(2)=(RelativeTime=0.170000,RelativeSize=1.000000)
         SizeScale(3)=(RelativeTime=1.000000,RelativeSize=1.000000)
         StartSizeRange=(X=(Min=20.000000,Max=30.000000),Y=(Min=20.000000,Max=30.000000),Z=(Min=20.000000,Max=30.000000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.FlashFlare1'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.350000,Max=0.500000)
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFZapBody.ZapFlash'

     Begin Object Class=SpriteEmitter Name=ZapStreaks
         UseDirectionAs=PTDU_Up
         UseColorScale=True
         FadeOut=True
         SpinParticles=True
         UniformSize=True
         Acceleration=(Z=-300.000000)
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=0.342857,Color=(B=255,G=160,R=64,A=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=255,A=255))
         ColorMultiplierRange=(X=(Min=0.800000),Y=(Min=0.800000),Z=(Min=0.800000))
         FadeOutStartTime=0.132000
         MaxParticles=14
         StartLocationRange=(Z=(Min=-10.000000,Max=10.000000))
         StartSpinRange=(X=(Min=0.300000,Max=0.300000))
         StartSizeRange=(X=(Min=14.000000,Max=24.000000),Y=(Min=14.000000,Max=24.000000),Z=(Min=14.000000,Max=24.000000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Beams.BeamFalloff'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.400000,Max=0.400000)
         StartVelocityRange=(X=(Min=-300.000000,Max=300.000000),Y=(Min=-300.000000,Max=300.000000),Z=(Min=-50.000000,Max=200.000000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFZapBody.ZapStreaks'

     Begin Object Class=SpriteEmitter Name=ZapSparks
         UseCollision=True
         FadeOut=True
         UniformSize=True
         Acceleration=(Z=-400.000000)
         ExtentMultiplier=(X=0.100000,Y=0.100000,Z=0.100000)
         DampingFactorRange=(X=(Min=0.400000,Max=0.400000),Y=(Min=0.400000,Max=0.400000),Z=(Min=0.400000,Max=0.400000))
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
         ColorMultiplierRange=(Z=(Min=0.500000,Max=0.500000))
         FadeOutStartTime=1.000000
         MaxParticles=40
         StartLocationRange=(Z=(Min=-20.000000,Max=20.000000))
         StartSizeRange=(X=(Min=4.000000,Max=7.000000),Y=(Min=4.000000,Max=7.000000),Z=(Min=4.000000,Max=7.000000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.FlashFlare1'
         SecondsBeforeInactive=0.000000
         MinSquaredVelocity=1000.000000
         LifetimeRange=(Min=1.500000,Max=1.500000)
         StartVelocityRange=(X=(Min=-100.000000,Max=100.000000),Y=(Min=-100.000000,Max=100.000000),Z=(Min=-50.000000,Max=80.000000))
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFZapBody.ZapSparks'

     Begin Object Class=BeamEmitter Name=ZapArcs
         BeamDistanceRange=(Min=40.000000,Max=110.000000)
         DetermineEndPointBy=PTEP_Distance
         LowFrequencyNoiseRange=(X=(Min=-30.000000,Max=30.000000),Y=(Min=-30.000000,Max=30.000000),Z=(Min=-30.000000,Max=30.000000))
         HighFrequencyNoiseRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=-10.000000,Max=10.000000))
         HighFrequencyPoints=8
         NoiseDeterminesEndPoint=True
         UseColorScale=True
         FadeOut=True
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=0.289286,Color=(B=255,G=128,R=64,A=255))
         ColorScale(2)=(RelativeTime=1.000000,Color=(B=128,G=255,R=128,A=255))
         ColorMultiplierRange=(X=(Min=0.800000,Max=0.800000),Y=(Min=0.900000,Max=0.900000))
         FadeOutStartTime=0.084000
         MaxParticles=6
         StartLocationRange=(Z=(Min=-20.000000,Max=20.000000))
         StartSizeRange=(X=(Min=5.000000,Max=7.000000),Y=(Min=5.000000,Max=7.000000),Z=(Min=5.000000,Max=7.000000))
         Texture=Texture'EpicParticles.Beams.HotBolt04aw'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.200000,Max=0.200000)
         StartVelocityRange=(X=(Min=-200.000000,Max=200.000000),Y=(Min=-200.000000,Max=200.000000),Z=(Min=-200.000000,Max=200.000000))
     End Object
     Emitters(3)=BeamEmitter'KFMod.KFZapBody.ZapArcs'

     AutoDestroy=True
     bNoDelete=False
     bNotOnDedServer=False
     bHardAttach=True
     AmbientSound=Sound'KFMod.Zap.ZapFlesh'
     SoundVolume=180
     SoundRadius=160.000000
}
