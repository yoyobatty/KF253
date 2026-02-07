class KFRocketExplosion extends emitter;

#exec OBJ LOAD FILE=ONSstructureTextures.utx

defaultproperties
{
<<<<<<< HEAD
	Begin Object Class=SpriteEmitter Name=SpriteEmitter0
		UseColorScale=True
		RespawnDeadParticles=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		AutomaticInitialSpawning=False
		StartLocationShape=PTLS_Sphere
		SphereRadiusRange=(Min=-200.000000,Max=200.000000)
		StartSpinRange=(X=(Min=1.055000,Max=2.355000))
		SizeScale(0)=(RelativeTime=3.000000,RelativeSize=5.000000)
		StartSizeRange=(X=(Min=150.000000,Max=150.000000))
		InitialParticlesPerSecond=1500.000000
		Texture=Texture'VMparticleTextures.VehicleExplosions.VMExp2_framesANIM'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=0.500000,Max=0.500000)
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFRocketExplosion.SpriteEmitter0'

	Begin Object Class=SpriteEmitter Name=SpriteEmitter3
		UseColorScale=True
		FadeOut=True
		RespawnDeadParticles=False
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		AutomaticInitialSpawning=False
		FadeOutStartTime=0.100000
		MaxParticles=1
		SizeScale(0)=(RelativeTime=1.000000,RelativeSize=10.000000)
		InitialParticlesPerSecond=20.000000
		Texture=Texture'ONSstructureTextures.CoreGroup.CoreBreachShockRINGorange'
		LifetimeRange=(Min=0.500000,Max=0.500000)
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFRocketExplosion.SpriteEmitter3'

	AutoDestroy=True
	bNoDelete=False
	bNetTemporary=True
	RemoteRole=ROLE_DumbProxy
=======
     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
         UseColorScale=True
         RespawnDeadParticles=False
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Min=-200.000000,Max=200.000000)
         StartSpinRange=(X=(Min=1.055000,Max=2.355000))
         SizeScale(0)=(RelativeTime=3.000000,RelativeSize=5.000000)
         StartSizeRange=(X=(Min=150.000000,Max=150.000000))
         InitialParticlesPerSecond=1500.000000
         Texture=Texture'VMParticleTextures.VehicleExplosions.VMExp2_framesANIM'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         LifetimeRange=(Min=0.500000,Max=0.500000)
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFRocketExplosion.SpriteEmitter0'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter3
         UseColorScale=True
         FadeOut=True
         RespawnDeadParticles=False
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         FadeOutStartTime=0.100000
         MaxParticles=1
         SizeScale(0)=(RelativeTime=1.000000,RelativeSize=10.000000)
         InitialParticlesPerSecond=20.000000
         Texture=Texture'ONSstructureTextures.CoreGroup.CoreBreachShockRINGorange'
         LifetimeRange=(Min=0.500000,Max=0.500000)
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFRocketExplosion.SpriteEmitter3'

     AutoDestroy=True
     bNoDelete=False
     bNetTemporary=True
     RemoteRole=ROLE_DumbProxy
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
