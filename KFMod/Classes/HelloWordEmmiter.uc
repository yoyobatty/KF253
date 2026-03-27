class HelloWordEmmiter extends xscorch;

var texture Splats[3];

simulated function PostBeginPlay()
{
    ProjTexture = splats[Rand(3)];
    Super.PostBeginPlay();
}

defaultproperties
{
<<<<<<< HEAD
	Splats(0)=Texture'XEffects.BloodSplat1'
	Splats(1)=Texture'XEffects.BloodSplat2'
	Splats(2)=Texture'XEffects.BloodSplat3'
	ProjTexture=Texture'XEffects.BloodSplat1'
	FOV=6
	bClipStaticMesh=True
	CullDistance=7000.000000
	LifeSpan=10.000000
=======
     Splats(0)=Texture'XEffects.BloodSplat1'
     Splats(1)=Texture'XEffects.BloodSplat2'
     Splats(2)=Texture'XEffects.BloodSplat3'
     ProjTexture=Texture'XEffects.BloodSplat1'
     FOV=6
     bClipStaticMesh=True
     CullDistance=7000.000000
     LifeSpan=10.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
