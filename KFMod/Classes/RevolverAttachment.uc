//=============================================================================
// RevolverAttachment
// The magnum revolver in its holder's hand as others see it: its own third-person model (KFAnim\Revolver:
// build_revolver3p.py), on the Deagle's third-person skeleton, with the Deagle's muzzle flash, tracer and handling.
//=============================================================================
class RevolverAttachment extends DeagleAttachment;

#exec TEXTURE IMPORT NAME=RevSteel FILE=..\KFMod254\KFMod\Textures\RevSteel.tga MIPS=ON
#exec TEXTURE IMPORT NAME=RevWood FILE=..\KFMod254\KFMod\Textures\RevWood.tga MIPS=ON
#exec TEXTURE IMPORT NAME=RevBrass FILE=..\KFMod254\KFMod\Textures\RevBrass.tga MIPS=ON
#exec MESH MODELIMPORT MESH=RevolverMesh3P MODELFILE=..\KFMod254\KFMod\Models\Revolver3P.psk LODSTYLE=10
#exec MESH ORIGIN MESH=RevolverMesh3P X=0 Y=0 Z=0 YAW=0 PITCH=0 ROLL=0
#exec MESHMAP SCALE MESHMAP=RevolverMesh3P X=1.0 Y=1.0 Z=1.0
#exec MESHMAP SETTEXTURE MESHMAP=RevolverMesh3P NUM=0 TEXTURE=RevSteel
#exec MESHMAP SETTEXTURE MESHMAP=RevolverMesh3P NUM=1 TEXTURE=RevWood
#exec MESHMAP SETTEXTURE MESHMAP=RevolverMesh3P NUM=2 TEXTURE=RevBrass

defaultproperties
{
     Mesh=SkeletalMesh'KFMod.RevolverMesh3P'
     Skins(0)=Texture'KFMod.RevSteel'
     Skins(1)=Texture'KFMod.RevWood'
     Skins(2)=Texture'KFMod.RevBrass'
}
