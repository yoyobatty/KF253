// KFs very own higher-res Bloodstains

class KFBloodSplatterDecal extends BloodSplatter;

#exec OBJ LOAD File=KFX.utx

simulated function PostBeginPlay()
{
    ProjTexture = splats[Rand(3)];
    FOV = Rand(6);
    SetDrawScale((Rand(2)-0.7) + (Rand(1)+0.05));
    Super.PostBeginPlay();
}

defaultproperties
{
<<<<<<< HEAD
	Splats(0)=Texture'KFX.BloodSplat1'
	Splats(1)=Texture'KFX.BloodSplat2'
	Splats(2)=Texture'KFX.BloodSplat3'
	ProjTexture=Texture'KFX.BloodSplat1'
	LifeSpan=10.000000
=======
     Splats(0)=Texture'KFX.BloodSplat1'
     Splats(1)=Texture'KFX.BloodSplat2'
     Splats(2)=Texture'KFX.BloodSplat3'
     ProjTexture=Texture'KFX.BloodSplat1'
     LifeSpan=60.000000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
