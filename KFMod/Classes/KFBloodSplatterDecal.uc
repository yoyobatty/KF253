// KFs very own higher-res Bloodstains
class KFBloodSplatterDecal extends BloodSplatter;

#exec OBJ LOAD File=KFX.utx

var() float Size;		// against the usual stain

simulated function PostBeginPlay()
{
    ProjTexture = splats[Rand(3)];
    FOV = Rand(6);
    SetDrawScale(((Rand(2)-0.7) + (Rand(1)+0.05)) * Size);
    Super.PostBeginPlay();
}

defaultproperties
{
     Size=1.000000
     Splats(0)=Texture'KFX.BloodSplat1'
     Splats(1)=Texture'KFX.BloodSplat2'
     Splats(2)=Texture'KFX.BloodSplat3'
     ProjTexture=Texture'KFX.BloodSplat1'
     LifeSpan=60.000000
}
