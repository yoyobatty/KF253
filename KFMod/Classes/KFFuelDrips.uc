//=============================================================================
// KFFuelDrips
// A specimen soaked in fuel (KFMonster.bSoaked): drops of it running off its body to the floor. KFMonster spreads it
// over the body each tick.
//=============================================================================
class KFFuelDrips extends Emitter;

#exec OBJ LOAD FILE=..\Textures\AW-2004Particles.utx

defaultproperties
{
     Begin Object Class=SpriteEmitter Name=Drops
         UseColorScale=True
         FadeOut=True
         UniformSize=True
         Acceleration=(Z=-700.000000)
         ColorScale(0)=(Color=(B=60,G=90,R=105,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=40,G=60,R=70,A=255))
         Opacity=0.700000
         FadeOutStartTime=0.400000
         MaxParticles=10
         StartSizeRange=(X=(Min=1.800000,Max=3.000000))
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'AW-2004Particles.Weapons.DustSmoke'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         UseRandomSubdivision=True
         SecondsBeforeInactive=0.000000
         LifetimeRange=(Min=0.450000,Max=0.600000)
         StartVelocityRange=(X=(Min=-12.000000,Max=12.000000),Y=(Min=-12.000000,Max=12.000000),Z=(Min=-40.000000,Max=0.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFFuelDrips.Drops'

     bNoDelete=False
     bNotOnDedServer=False
     bHardAttach=True
}
