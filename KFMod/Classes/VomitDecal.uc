class VomitDecal extends xScorch;

#exec OBJ LOAD File=KFX.utx

simulated function BeginPlay()
{
    if ( !Level.bDropDetail && (FRand() < 0.5) )
        ProjTexture = texture'VomSplat';
    Super.BeginPlay();
}

defaultproperties
{
<<<<<<< HEAD
	ProjTexture=Texture'KFX.VomSplat'
	bClipStaticMesh=True
	CullDistance=7000.000000
	LifeSpan=5.000000
	DrawScale=0.500000
=======
     ProjTexture=Texture'KFX.VomSplat'
     bClipStaticMesh=True
     CullDistance=7000.000000
     LifeSpan=5.000000
     DrawScale=0.500000
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
