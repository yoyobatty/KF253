// A specimen carrying a power-up in Endless (KFEndlessGameType's loot specimen): gold sparks rising off its body and a slow
// gold pulse of light round it, so that it is found in the dark and in a crowd. KFMonster spreads the sparks over the body.
class KFLootGlow extends Emitter;

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=LootSparks
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         Acceleration=(Z=30.000000)
         ColorScale(0)=(Color=(B=150,G=235,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=30,G=170,R=255,A=255))
         FadeOutStartTime=0.600000
         FadeInEndTime=0.150000
         MaxParticles=24
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=4.000000)
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=0.300000)
         StartSizeRange=(X=(Min=5.000000,Max=8.000000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'KFX.KFSparkHead'
         TextureUSubdivisions=1
         TextureVSubdivisions=2
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=1.000000,Max=1.600000)
         StartVelocityRange=(X=(Min=-8.000000,Max=8.000000),Y=(Min=-8.000000,Max=8.000000),Z=(Min=15.000000,Max=45.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFLootGlow.LootSparks'

     Begin Object Class=SpriteEmitter Name=LootHalo
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         UniformSize=True
         ColorScale(0)=(Color=(B=25,G=85,R=135,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=10,G=55,R=110,A=255))
         FadeOutStartTime=0.400000
         FadeInEndTime=0.300000
         MaxParticles=4
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=6.000000)
         StartSizeRange=(X=(Min=30.000000,Max=46.000000))
         DrawStyle=PTDS_Brighten
         Texture=Texture'EpicParticles.Flares.SoftFlare'
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.700000,Max=1.000000)
         StartVelocityRange=(Z=(Min=0.000000,Max=10.000000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFLootGlow.LootHalo'

     LightType=LT_SubtlePulse
     LightHue=32
     LightSaturation=40
     LightBrightness=255.000000
     LightRadius=9.000000
     LightPeriod=40
     bNoDelete=False
     bDynamicLight=True
     bOnlyDrawIfAttached=True
     bNotOnDedServer=False
}
