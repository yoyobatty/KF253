//=============================================================================
// KFFrostMark
// Frost where a cryo bolt burst (CryoBolt): crystals spreading over the floor or wall, melting away after a while.
//=============================================================================
class KFFrostMark extends xScorch;

#exec TEXTURE IMPORT NAME=FrostMark FILE=..\KFMod254\KFMod\Textures\FrostMark.tga MIPS=ON ALPHA=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP

// Laid on the world only, never on a physics prop (see NetKActor.ShedDecal)
simulated function AttachProjector(optional float FadeInTime)
{
	Super.AttachProjector(FadeInTime);
	class'NetKActor'.static.ShedDecal(self);
}

defaultproperties
{
     ProjTexture=Texture'KFMod.FrostMark'
     FrameBufferBlendingOp=PB_AlphaBlend
     DrawScale=1.300000
     LifeSpan=14.000000
     bClipStaticMesh=True
     CullDistance=5000.000000
}
