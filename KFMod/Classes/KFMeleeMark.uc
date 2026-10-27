//=============================================================================
// KFMeleeMark
// What a melee blow leaves on a wall or floor (KFMeleeHitEffect): a blade's gash or a blunt weapon's crushed spot, not
// a bullet's hole. It is laid along the swing (the hit effect turns it so), and stays a while.
//=============================================================================
class KFMeleeMark extends KFBulletDecal
	abstract;

#exec TEXTURE IMPORT NAME=MeleeGash FILE=..\KFMod254\KFMod\Textures\MeleeGash.tga MIPS=ON UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP
#exec TEXTURE IMPORT NAME=MeleeScratch FILE=..\KFMod254\KFMod\Textures\MeleeScratch.tga MIPS=ON UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP
#exec TEXTURE IMPORT NAME=MeleeDent FILE=..\KFMod254\KFMod\Textures\MeleeDent.tga MIPS=ON UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP

defaultproperties
{
     RandomOrient=False
     LifeSpan=20.000000
     DrawScale=0.340000
}
