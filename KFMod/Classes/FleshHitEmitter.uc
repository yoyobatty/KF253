class FleshHitEmitter extends KFHitEmitter;
     #exec OBJ LOAD FILE=KFWeaponSound.uax

defaultproperties
{
<<<<<<< HEAD
	ImpactSounds(0)=Sound'KFPawnDamageSound.MeleeDamageSounds.bathitflesh'
	ImpactSounds(1)=Sound'KFPawnDamageSound.MeleeDamageSounds.bathitflesh'
	ImpactSounds(2)=Sound'KFPawnDamageSound.MeleeDamageSounds.bathitflesh2'
	ImpactSounds(3)=Sound'KFPawnDamageSound.MeleeDamageSounds.bathitflesh3'
	Begin Object Class=SpriteEmitter Name=SpriteEmitter0
		FadeOut=True
		RespawnDeadParticles=False
		SpawnOnlyInDirectionOfNormal=True
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		ScaleSizeYByVelocity=True
		ScaleSizeZByVelocity=True
		AutomaticInitialSpawning=False
		BlendBetweenSubdivisions=True
		UseRandomSubdivision=True
		Acceleration=(Z=-350.000000)
		ColorScale(1)=(RelativeTime=0.300000,Color=(B=255,G=255,R=255))
		ColorScale(2)=(RelativeTime=0.750000,Color=(B=96,G=160,R=255))
		ColorScale(3)=(RelativeTime=1.000000)
		ColorMultiplierRange=(Z=(Min=0.670000,Max=2.000000))
		FadeOutStartTime=0.300000
		StartLocationShape=PTLS_Sphere
		SphereRadiusRange=(Max=5.000000)
		StartMassRange=(Min=11.000000,Max=11.000000)
		UseRotationFrom=PTRS_Normal
		SpinsPerSecondRange=(X=(Min=0.100000,Max=0.120000))
		SizeScale(0)=(RelativeTime=1.000000,RelativeSize=3.500000)
		StartSizeRange=(X=(Min=8.000000,Max=12.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
		ScaleSizeByVelocityMultiplier=(X=0.000000,Y=0.000000,Z=0.000000)
		ScaleSizeByVelocityMax=3.000000
		InitialParticlesPerSecond=100.000000
		DrawStyle=PTDS_Modulated
		Texture=Texture'KFX.BloodySpray'
		TextureUSubdivisions=4
		TextureVSubdivisions=4
		LifetimeRange=(Min=0.500000,Max=0.750000)
		StartVelocityRange=(Z=(Min=120.000000,Max=150.000000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.FleshHitEmitter.SpriteEmitter0'

	LifeSpan=1.000000
=======
     ImpactSounds(0)=Sound'KFPawnDamageSound.MeleeDamageSounds.bathitflesh'
     ImpactSounds(1)=Sound'KFPawnDamageSound.MeleeDamageSounds.bathitflesh'
     ImpactSounds(2)=Sound'KFPawnDamageSound.MeleeDamageSounds.bathitflesh2'
     ImpactSounds(3)=Sound'KFPawnDamageSound.MeleeDamageSounds.bathitflesh3'
     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
         FadeOut=True
         RespawnDeadParticles=False
         SpawnOnlyInDirectionOfNormal=True
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ScaleSizeYByVelocity=True
         ScaleSizeZByVelocity=True
         AutomaticInitialSpawning=False
         BlendBetweenSubdivisions=True
         UseRandomSubdivision=True
         Acceleration=(Z=-350.000000)
         ColorScale(1)=(RelativeTime=0.300000,Color=(B=255,G=255,R=255))
         ColorScale(2)=(RelativeTime=0.750000,Color=(B=96,G=160,R=255))
         ColorScale(3)=(RelativeTime=1.000000)
         ColorMultiplierRange=(Z=(Min=0.670000,Max=2.000000))
         FadeOutStartTime=0.300000
         StartLocationShape=PTLS_Sphere
         SphereRadiusRange=(Max=5.000000)
         StartMassRange=(Min=11.000000,Max=11.000000)
         UseRotationFrom=PTRS_Normal
         SpinsPerSecondRange=(X=(Min=0.100000,Max=0.120000))
         SizeScale(0)=(RelativeTime=1.000000,RelativeSize=3.500000)
         StartSizeRange=(X=(Min=8.000000,Max=12.000000),Y=(Min=0.000000,Max=0.000000),Z=(Min=0.000000,Max=0.000000))
         ScaleSizeByVelocityMultiplier=(X=0.000000,Y=0.000000,Z=0.000000)
         ScaleSizeByVelocityMax=3.000000
         InitialParticlesPerSecond=100.000000
         DrawStyle=PTDS_Modulated
         Texture=Texture'KFX.BloodySpray'
         TextureUSubdivisions=4
         TextureVSubdivisions=4
         LifetimeRange=(Min=0.500000,Max=0.750000)
         StartVelocityRange=(Z=(Min=120.000000,Max=150.000000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.FleshHitEmitter.SpriteEmitter0'

     LifeSpan=1.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
