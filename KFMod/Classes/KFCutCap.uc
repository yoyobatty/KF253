//=============================================================================
// The face a cut leaves (KFCutPiece, KFCutBody): a flat oval of bone, brain or gut lying on the cut, worn on the part.
// The mesh is a square two units across facing +X; DrawScale3D's Y and Z are the oval's half widths.
//=============================================================================
class KFCutCap extends Actor;

#exec NEW StaticMesh File="..\KFMod254\KFMod\Models\KFCutCap.ase" Name="KFCutCap"

defaultproperties
{
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'KFCutCap'
     bHardAttach=True
     RemoteRole=ROLE_None
     bUnlit=False
     bUseDynamicLights=True
     bAcceptsProjectors=False
     bShadowCast=False
     bCollideActors=False
     bCollideWorld=False
     bBlockActors=False
     bBlockPlayers=False
     AmbientGlow=70
}
