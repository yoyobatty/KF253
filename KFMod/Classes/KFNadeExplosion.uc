class KFNadeExplosion extends NewExplosionC;

var     bool    bFlashed;

replication
{
    // Things the server should send to the client.
    reliable if( bNetDirty && (!bNetOwner || bDemoRecording || bRepClientDemo) && (Role==ROLE_Authority) )
        bFlashed;

}

simulated function PostBeginPlay()
{
   Super.Postbeginplay();
   NadeLight();
}



simulated function NadeLight()
{
    if ( !bFlashed && !Level.bDropDetail && (Instigator != None)
        && ((Level.TimeSeconds - LastRenderTime < 0.2) || (PlayerController(Instigator.Controller) != None)) )
    {
        bDynamicLight = true;
        SetTimer(0.25, false);
    }
    else 
        Timer();
}


simulated function Timer()
{
    bDynamicLight = false;
}

defaultproperties
{
<<<<<<< HEAD
	Begin Object Class=SpriteEmitter Name=SpriteEmitter0
		UseDirectionAs=PTDU_Up
		FadeOut=True
		FadeIn=True
		RespawnDeadParticles=False
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		ScaleSizeYByVelocity=True
		AutomaticInitialSpawning=False
		UseRandomSubdivision=True
		ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
		FadeOutStartTime=0.100000
		FadeInEndTime=0.100000
		MaxParticles=80
		DetailMode=DM_High
		AddLocationFromOtherEmitter=0
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=12.000000)
		StartSizeRange=(X=(Min=4.000000,Max=8.000000))
		ScaleSizeByVelocityMultiplier=(X=0.150000,Y=0.150000,Z=0.150000)
		InitialParticlesPerSecond=150.000000
		DrawStyle=PTDS_Darken
		Texture=Texture'EpicParticles.Smoke.SparkCloud_01aw'
		LifetimeRange=(Min=3.000000,Max=1.000000)
		InitialDelayRange=(Min=0.250000,Max=0.250000)
		VelocityLossRange=(X=(Min=0.900000,Max=0.900000),Y=(Min=0.900000,Max=0.900000),Z=(Min=0.900000,Max=0.900000))
		AddVelocityFromOtherEmitter=0
		AddVelocityMultiplierRange=(X=(Min=0.100000,Max=0.100000),Y=(Min=0.100000,Max=0.100000),Z=(Min=0.100000,Max=0.100000))
	End Object
	Emitters(0)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter0'

	Begin Object Class=SpriteEmitter Name=SpriteEmitter1
		FadeOut=True
		RespawnDeadParticles=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		AutomaticInitialSpawning=False
		UseRandomSubdivision=True
		Acceleration=(Z=-600.000000)
		FadeOutStartTime=3.500000
		MaxParticles=50
		DetailMode=DM_High
		UseRotationFrom=PTRS_Actor
		SpinsPerSecondRange=(X=(Min=-4.000000,Max=4.000000))
		StartSpinRange=(X=(Min=-1.000000,Max=1.000000))
		StartSizeRange=(X=(Min=2.000000,Max=25.000000))
		InitialParticlesPerSecond=1000.000000
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'EmitterTextures.MultiFrame.rockchunks02'
		TextureUSubdivisions=2
		TextureVSubdivisions=2
		StartVelocityRange=(X=(Min=-400.000000,Max=400.000000),Y=(Min=-400.000000,Max=400.000000),Z=(Min=100.000000,Max=1600.000000))
	End Object
	Emitters(1)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter1'

	Begin Object Class=SpriteEmitter Name=SpriteEmitter2
		UseColorScale=True
		FadeOut=True
		FadeIn=True
		RespawnDeadParticles=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		AutomaticInitialSpawning=False
		ColorScale(0)=(Color=(B=155,G=180,R=205,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=155,G=180,R=205,A=255))
		FadeOutStartTime=1.000000
		FadeInEndTime=0.100000
		CoordinateSystem=PTCS_Relative
		MaxParticles=15
		StartLocationRange=(X=(Min=-200.000000,Max=200.000000),Y=(Min=-200.000000,Max=200.000000))
		StartLocationShape=PTLS_Polar
		StartLocationPolarRange=(X=(Min=-128.000000,Max=128.000000),Y=(Min=-128.000000,Max=128.000000))
		AlphaRef=4
		SpinsPerSecondRange=(X=(Min=-0.100000,Max=0.100000))
		StartSpinRange=(X=(Min=-1.000000,Max=1.000000))
		SizeScale(0)=(RelativeSize=1.500000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=6.000000)
		StartSizeRange=(X=(Min=50.000000))
		InitialParticlesPerSecond=1000.000000
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'BenTex01.Textures.SmokePuff01'
		LifetimeRange=(Min=1.500000)
		InitialDelayRange=(Max=0.100000)
		StartVelocityRange=(X=(Min=-600.000000,Max=600.000000),Y=(Min=-600.000000,Max=600.000000),Z=(Max=50.000000))
		StartVelocityRadialRange=(Min=100.000000,Max=200.000000)
		VelocityLossRange=(X=(Min=1.000000,Max=3.000000),Y=(Min=1.000000,Max=3.000000))
		RotateVelocityLossRange=True
		GetVelocityDirectionFrom=PTVD_AddRadial
	End Object
	Emitters(2)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter2'

	Begin Object Class=SpriteEmitter Name=SpriteEmitter3
		UseColorScale=True
		FadeOut=True
		FadeIn=True
		RespawnDeadParticles=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		AutomaticInitialSpawning=False
		Acceleration=(Z=-10.000000)
		ColorScale(0)=(Color=(B=155,G=180,R=205,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=155,G=180,R=205,A=255))
		FadeOutStartTime=1.000000
		FadeInEndTime=0.100000
		CoordinateSystem=PTCS_Relative
		StartLocationRange=(Z=(Min=-32.000000,Max=128.000000))
		AlphaRef=4
		SpinsPerSecondRange=(X=(Min=-0.100000,Max=0.100000))
		StartSpinRange=(X=(Min=-1.000000,Max=1.000000))
		SizeScale(0)=(RelativeSize=1.000000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=12.000000)
		StartSizeRange=(X=(Min=30.000000,Max=60.000000))
		InitialParticlesPerSecond=500.000000
		DrawStyle=PTDS_AlphaBlend
		Texture=Texture'BenTex01.Textures.SmokePuff01'
		LifetimeRange=(Min=1.500000)
		StartVelocityRange=(X=(Min=-100.000000,Max=100.000000),Y=(Min=-100.000000,Max=100.000000),Z=(Min=50.000000,Max=1400.000000))
		VelocityLossRange=(X=(Min=1.000000,Max=2.000000),Y=(Min=1.000000,Max=2.000000),Z=(Min=1.000000,Max=2.000000))
		RotateVelocityLossRange=True
	End Object
	Emitters(3)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter3'

	Begin Object Class=SpriteEmitter Name=SpriteEmitter4
		UseDirectionAs=PTDU_Right
		UseColorScale=True
		FadeOut=True
		FadeIn=True
		RespawnDeadParticles=False
		UniformSize=True
		ScaleSizeXByVelocity=True
		AutomaticInitialSpawning=False
		Acceleration=(Z=-400.000000)
		ColorScale(0)=(Color=(B=179,G=236,R=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=20,G=97,R=167))
		FadeOutStartTime=0.500000
		FadeInEndTime=0.100000
		MaxParticles=20
		DetailMode=DM_SuperHigh
		UseRotationFrom=PTRS_Actor
		StartSizeRange=(X=(Min=4.000000,Max=10.000000))
		ScaleSizeByVelocityMultiplier=(X=0.006000)
		InitialParticlesPerSecond=1000.000000
		Texture=Texture'AW-2004Particles.Weapons.HardSpot'
		LifetimeRange=(Min=0.750000,Max=1.250000)
		StartVelocityRange=(X=(Min=-1200.000000,Max=1200.000000),Y=(Min=-1200.000000,Max=1200.000000),Z=(Min=400.000000,Max=1400.000000))
	End Object
	Emitters(4)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter4'

	Begin Object Class=SpriteEmitter Name=SpriteEmitter5
		FadeOut=True
		RespawnDeadParticles=False
		SpinParticles=True
		UseSizeScale=True
		UseRegularSizeScale=False
		UniformSize=True
		AutomaticInitialSpawning=False
		ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
		ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
		FadeOutStartTime=0.128180
		MaxParticles=1
		StartLocationOffset=(Z=30.000000)
		SpinsPerSecondRange=(X=(Min=-65513.000000,Max=-65440.000000))
		SizeScale(0)=(RelativeTime=1.000000,RelativeSize=-3.000000)
		StartSizeRange=(X=(Min=80.000000,Max=80.000000),Y=(Min=80.000000,Max=80.000000),Z=(Min=80.000000,Max=80.000000))
		InitialParticlesPerSecond=5000.000000
		Texture=Texture'25Tex.Common.NadeBoom'
		LifetimeRange=(Min=0.221000,Max=0.221000)
	End Object
	Emitters(5)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter5'

	LightType=LT_Steady
	LightHue=30
	LightSaturation=100
	LightBrightness=500.000000
	LightRadius=8.000000
	RemoteRole=ROLE_SimulatedProxy
	bNotOnDedServer=False
=======
     Begin Object Class=SpriteEmitter Name=SpriteEmitter0
         UseDirectionAs=PTDU_Up
         FadeOut=True
         FadeIn=True
         RespawnDeadParticles=False
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         ScaleSizeYByVelocity=True
         AutomaticInitialSpawning=False
         UseRandomSubdivision=True
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
         FadeOutStartTime=0.100000
         FadeInEndTime=0.100000
         MaxParticles=80
         DetailMode=DM_High
         AddLocationFromOtherEmitter=0
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=12.000000)
         StartSizeRange=(X=(Min=4.000000,Max=8.000000))
         ScaleSizeByVelocityMultiplier=(X=0.150000,Y=0.150000,Z=0.150000)
         InitialParticlesPerSecond=150.000000
         DrawStyle=PTDS_Darken
         Texture=Texture'EpicParticles.Smoke.SparkCloud_01aw'
         LifetimeRange=(Min=3.000000,Max=1.000000)
         InitialDelayRange=(Min=0.250000,Max=0.250000)
         VelocityLossRange=(X=(Min=0.900000,Max=0.900000),Y=(Min=0.900000,Max=0.900000),Z=(Min=0.900000,Max=0.900000))
         AddVelocityFromOtherEmitter=0
         AddVelocityMultiplierRange=(X=(Min=0.100000,Max=0.100000),Y=(Min=0.100000,Max=0.100000),Z=(Min=0.100000,Max=0.100000))
     End Object
     Emitters(0)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter0'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter1
         FadeOut=True
         RespawnDeadParticles=False
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         UseRandomSubdivision=True
         Acceleration=(Z=-600.000000)
         FadeOutStartTime=3.500000
         MaxParticles=50
         DetailMode=DM_High
         UseRotationFrom=PTRS_Actor
         SpinsPerSecondRange=(X=(Min=-4.000000,Max=4.000000))
         StartSpinRange=(X=(Min=-1.000000,Max=1.000000))
         StartSizeRange=(X=(Min=2.000000,Max=25.000000))
         InitialParticlesPerSecond=1000.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'EmitterTextures.MultiFrame.rockchunks02'
         TextureUSubdivisions=2
         TextureVSubdivisions=2
         StartVelocityRange=(X=(Min=-400.000000,Max=400.000000),Y=(Min=-400.000000,Max=400.000000),Z=(Min=100.000000,Max=1600.000000))
     End Object
     Emitters(1)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter1'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter2
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         RespawnDeadParticles=False
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=155,G=180,R=205,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=155,G=180,R=205,A=255))
         FadeOutStartTime=1.000000
         FadeInEndTime=0.100000
         CoordinateSystem=PTCS_Relative
         MaxParticles=15
         StartLocationRange=(X=(Min=-200.000000,Max=200.000000),Y=(Min=-200.000000,Max=200.000000))
         StartLocationShape=PTLS_Polar
         StartLocationPolarRange=(X=(Min=-128.000000,Max=128.000000),Y=(Min=-128.000000,Max=128.000000))
         AlphaRef=4
         SpinsPerSecondRange=(X=(Min=-0.100000,Max=0.100000))
         StartSpinRange=(X=(Min=-1.000000,Max=1.000000))
         SizeScale(0)=(RelativeSize=1.500000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=6.000000)
         StartSizeRange=(X=(Min=50.000000))
         InitialParticlesPerSecond=1000.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'BenTex01.textures.SmokePuff01'
         LifetimeRange=(Min=1.500000)
         InitialDelayRange=(Max=0.100000)
         StartVelocityRange=(X=(Min=-600.000000,Max=600.000000),Y=(Min=-600.000000,Max=600.000000),Z=(Max=50.000000))
         StartVelocityRadialRange=(Min=100.000000,Max=200.000000)
         VelocityLossRange=(X=(Min=1.000000,Max=3.000000),Y=(Min=1.000000,Max=3.000000))
         RotateVelocityLossRange=True
         GetVelocityDirectionFrom=PTVD_AddRadial
     End Object
     Emitters(2)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter2'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter3
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         RespawnDeadParticles=False
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         Acceleration=(Z=-10.000000)
         ColorScale(0)=(Color=(B=155,G=180,R=205,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=155,G=180,R=205,A=255))
         FadeOutStartTime=1.000000
         FadeInEndTime=0.100000
         CoordinateSystem=PTCS_Relative
         StartLocationRange=(Z=(Min=-32.000000,Max=128.000000))
         AlphaRef=4
         SpinsPerSecondRange=(X=(Min=-0.100000,Max=0.100000))
         StartSpinRange=(X=(Min=-1.000000,Max=1.000000))
         SizeScale(0)=(RelativeSize=1.000000)
         SizeScale(1)=(RelativeTime=1.000000,RelativeSize=12.000000)
         StartSizeRange=(X=(Min=30.000000,Max=60.000000))
         InitialParticlesPerSecond=500.000000
         DrawStyle=PTDS_AlphaBlend
         Texture=Texture'BenTex01.textures.SmokePuff01'
         LifetimeRange=(Min=1.500000)
         StartVelocityRange=(X=(Min=-100.000000,Max=100.000000),Y=(Min=-100.000000,Max=100.000000),Z=(Min=50.000000,Max=1400.000000))
         VelocityLossRange=(X=(Min=1.000000,Max=2.000000),Y=(Min=1.000000,Max=2.000000),Z=(Min=1.000000,Max=2.000000))
         RotateVelocityLossRange=True
     End Object
     Emitters(3)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter3'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter4
         UseDirectionAs=PTDU_Right
         UseColorScale=True
         FadeOut=True
         FadeIn=True
         RespawnDeadParticles=False
         UniformSize=True
         ScaleSizeXByVelocity=True
         AutomaticInitialSpawning=False
         Acceleration=(Z=-400.000000)
         ColorScale(0)=(Color=(B=179,G=236,R=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=20,G=97,R=167))
         FadeOutStartTime=0.500000
         FadeInEndTime=0.100000
         MaxParticles=20
         DetailMode=DM_SuperHigh
         UseRotationFrom=PTRS_Actor
         StartSizeRange=(X=(Min=4.000000,Max=10.000000))
         ScaleSizeByVelocityMultiplier=(X=0.006000)
         InitialParticlesPerSecond=1000.000000
         Texture=Texture'AW-2004Particles.Weapons.HardSpot'
         LifetimeRange=(Min=0.750000,Max=1.250000)
         StartVelocityRange=(X=(Min=-1200.000000,Max=1200.000000),Y=(Min=-1200.000000,Max=1200.000000),Z=(Min=400.000000,Max=1400.000000))
     End Object
     Emitters(4)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter4'

     Begin Object Class=SpriteEmitter Name=SpriteEmitter5
         FadeOut=True
         RespawnDeadParticles=False
         SpinParticles=True
         UseSizeScale=True
         UseRegularSizeScale=False
         UniformSize=True
         AutomaticInitialSpawning=False
         ColorScale(0)=(Color=(B=255,G=255,R=255,A=255))
         ColorScale(1)=(RelativeTime=1.000000,Color=(B=255,G=255,R=255,A=255))
         FadeOutStartTime=0.128180
         MaxParticles=1
         StartLocationOffset=(Z=30.000000)
         SpinsPerSecondRange=(X=(Min=-65513.000000,Max=-65440.000000))
         SizeScale(0)=(RelativeTime=1.000000,RelativeSize=-3.000000)
         StartSizeRange=(X=(Min=80.000000,Max=80.000000),Y=(Min=80.000000,Max=80.000000),Z=(Min=80.000000,Max=80.000000))
         InitialParticlesPerSecond=5000.000000
         Texture=Texture'25Tex.Common.NadeBoom'
         LifetimeRange=(Min=0.221000,Max=0.221000)
     End Object
     Emitters(5)=SpriteEmitter'KFMod.KFNadeExplosion.SpriteEmitter5'

     LightType=LT_Steady
     LightHue=30
     LightSaturation=100
     LightBrightness=500.000000
     LightRadius=8.000000
     RemoteRole=ROLE_SimulatedProxy
     bNotOnDedServer=False
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
