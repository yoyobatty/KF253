class VomitDecal extends xScorch;

#exec OBJ LOAD File=KFX.utx

simulated function BeginPlay()
{
    if ( !Level.bDropDetail && (FRand() < 0.5) )
        ProjTexture = texture'VomSplat';
    Super.BeginPlay();
}

// Laid on the world only, never on a physics prop (see NetKActor.ShedDecal)
simulated function AttachProjector(optional float FadeInTime)
{
	Super.AttachProjector(FadeInTime);
	class'NetKActor'.static.ShedDecal(self);
}

defaultproperties
{
     ProjTexture=Texture'KFX.VomSplat'
     bClipStaticMesh=True
     CullDistance=7000.000000
     LifeSpan=5.000000
     DrawScale=0.500000
}
