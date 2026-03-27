class KnifeMetalHitEmitter extends KFHitEmitter;
         #exec OBJ LOAD FILE=KFWeaponSound.uax

defaultproperties
{
     ImpactSounds(0)=Sound'KFWeaponSound.KnifeHitMetal'
     ImpactSounds(1)=Sound'KFWeaponSound.KnifeHitMetal'
     ImpactSounds(2)=Sound'KFWeaponSound.KnifeHitMetal'
     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
         UseDirectionAs=PTDU_Up
         UseCollision=True
         UseColorScale=True
         RespawnDeadParticles=False
         UseSizeScale=True
         UseRegularSizeScale=False
         ScaleSizeYByVelocity=True
         AutomaticInitialSpawning=False
         BlendBetweenSubdivisions=True
         UseRandomSubdivision=True
         Acceleration=(Z=-600.000000)
         DampingFactorRange=(X=(Min=0.200000),Y=(Min=0.200000),Z=(Min=0.200000,Max=0.500000))
         ColorScale(0)=(Color=(B=200,G=255,R=255))
         ColorScale(1)=(RelativeTime=0.200000,Color=(B=190,G=220,R=242))
         ColorScale(2)=(RelativeTime=0.400000,Color=(B=90,G=91,R=90))
         ColorScale(3)=(RelativeTime=1.000000,Color=(G=40,R=102))
         DetailMode=DM_High
         SizeScale(2)=(RelativeTime=0.070000,RelativeSize=1.000000)
         SizeScale(3)=(RelativeTime=1.000000,RelativeSize=1.000000)
         StartSizeRange=(X=(Min=3.000000,Max=5.000000),Y=(Min=2.000000,Max=4.000000),Z=(Min=2.000000,Max=2.000000))
         ScaleSizeByVelocityMultiplier=(Y=0.020000)
         InitialParticlesPerSecond=100.000000
         Texture=Texture'AW-2004Particles.Energy.SparkHead'
         TextureUSubdivisions=2
         TextureVSubdivisions=2
         LifetimeRange=(Min=0.800000,Max=1.500000)
         StartVelocityRange=(X=(Min=100.000000,Max=250.000000),Y=(Min=-50.000000,Max=50.000000),Z=(Min=-50.000000,Max=50.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KnifeMetalHitEmitter.SpriteEmitter0'

}
