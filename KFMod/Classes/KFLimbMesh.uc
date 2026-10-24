//=============================================================================
// What is seen of a limb or head off a specimen (KFLimbGib): the specimen's whole mesh, held in the pose
// it was in, with everything but the part shrunk away. It rides the giblet that carries it.
//=============================================================================
class KFLimbMesh extends Actor;

var vector Offset;		// where the mesh is drawn from, against its own axes: it stands at the part's middle, where it is lit from

// (ticked after the giblet that owns it has moved and turned it)
simulated function Tick( float DeltaTime )
{
	PrePivot = Offset >> Rotation;
}

defaultproperties
{
     DrawType=DT_Mesh
     bHardAttach=True
     RemoteRole=ROLE_None
     bUnlit=False
     bAcceptsProjectors=True
     bUseDynamicLights=True
}
