// Embers rising along a lockdown's wall (KFLockdownWall sets the ring's radius)
class KFLockdownEmbers extends Emitter;

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=WallEmbers
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         Acceleration=(Z=60.000000)
         ColorScale(0)=(Color=(B=40,G=120,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=10,G=30,R=200,A=255))
         FadeOutStartTime=0.600000
         FadeInEndTime=0.150000
         MaxParticles=160
         StartLocationShape=PTLS_Polar
         StartLocationPolarRange=(X=(Max=65536.000000),Y=(Min=16384.000000,Max=16384.000000),Z=(Min=500.000000,Max=500.000000))
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=0.300000)
         StartSizeRange=(X=(Min=4.000000,Max=9.000000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'KFX.KFSparkHead'
         TextureUSubdivisions=1
         TextureVSubdivisions=2
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=1.200000,Max=2.200000)
         StartVelocityRange=(X=(Min=-10.000000,Max=10.000000),Y=(Min=-10.000000,Max=10.000000),Z=(Min=20.000000,Max=70.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFLockdownEmbers.WallEmbers'

     bNoDelete=False
     RemoteRole=ROLE_None
     bNotOnDedServer=True
}
