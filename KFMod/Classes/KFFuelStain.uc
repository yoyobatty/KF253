//=============================================================================
// KFFuelStain
// Fuel lying on the floor (KFFuelPool): a dark wet stain, darker at its edge, with an oily sheen. It stays as long as
// its pool (unlike a scorch, which is let go at once).
//=============================================================================
class KFFuelStain extends Projector;

#exec TEXTURE IMPORT NAME=FuelStain FILE=..\KFMod254\KFMod\Textures\FuelStain.tga MIPS=ON ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP

// Laid on the world only, never on a physics prop (see NetKActor.ShedDecal)
simulated function AttachProjector(optional float FadeInTime)
{
	Super.AttachProjector(FadeInTime);
	class'NetKActor'.static.ShedDecal(self);
}

defaultproperties
{
     ProjTexture=Texture'KFMod.FuelStain'
     FrameBufferBlendingOp=PB_AlphaBlend
     FOV=1
     MaxTraceDistance=60
     bProjectActor=False
     bProjectParticles=False
     bClipBSP=True
     bClipStaticMesh=True
     FadeInTime=0.250000
     GradientTexture=Texture'Engine.GRADIENT_Clip'
     CullDistance=6000.000000
     bStatic=False
     bGameRelevant=True
     DrawScale=0.600000
}
