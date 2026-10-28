// The Abomination's gas (KFAbomBelch): yellow-green clouds thrown forward along its breath, spreading and settling low
class KFAbomGasCloud extends Emitter;

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=AbomGas
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         RespawnDeadParticles=False
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         Acceleration=(Z=-12.000000)
         DampingFactorRange=(X=(Min=0.400000,Max=0.400000),Y=(Min=0.400000,Max=0.400000),Z=(Min=0.400000,Max=0.400000))
         UseVelocityScale=False
         ColorScale(0)=(Color=(B=40,G=150,R=120,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=20,G=90,R=70,A=255))
         FadeOutStartTime=3.500000
         FadeInEndTime=0.300000
         MaxParticles=34
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=30.000000)
         SizeScale(0)=(RelativeSize=0.400000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=2.200000)
         StartSizeRange=(X=(Min=90.000000,Max=140.000000))
         InitialParticlesPerSecond=200.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         UseRandomSubdivision=True
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=5.000000,Max=6.500000)
         StartVelocityRange=(X=(Min=150.000000,Max=650.000000),Y=(Min=-160.000000,Max=160.000000),Z=(Min=-80.000000,Max=40.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFAbomGasCloud.AbomGas'

     AutoDestroy=True
     bNoDelete=False
     RemoteRole=ROLE_None
     LifeSpan=8.000000
}
