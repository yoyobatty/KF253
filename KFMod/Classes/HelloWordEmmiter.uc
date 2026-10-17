class HelloWordEmmiter extends xscorch;

var texture Splats[3];

simulated function PostBeginPlay()
{
    ProjTexture = splats[Rand(3)];
    Super.PostBeginPlay();
}

// Laid on the world only, never on a physics prop (see NetKActor.ShedDecal)
simulated function AttachProjector(optional float FadeInTime)
{
	Super.AttachProjector(FadeInTime);
	class'NetKActor'.static.ShedDecal(self);
}

defaultproperties
{
     Splats(0)=Texture'XEffects.BloodSplat1'
     Splats(1)=Texture'XEffects.BloodSplat2'
     Splats(2)=Texture'XEffects.BloodSplat3'
     ProjTexture=Texture'XEffects.BloodSplat1'
     FOV=6
     bClipStaticMesh=True
     CullDistance=7000.000000
     LifeSpan=10.000000
}
