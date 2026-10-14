//=============================================================================
// KFGlassBlocker: a pane of glass's unseen stand-in for trader time. Players do not block anything then (so that they
// cannot block one another at the trader), and the glass only stops what blocks: this is world geometry, which holds
// back all that collides with the world. It takes the glass's own shape and lets traces through, so shots still meet
// the glass. Each machine makes its own (KFGlassMover.UpdateBlocker).
//=============================================================================
class KFGlassBlocker extends Actor;

var KFGlassMover Glass;

defaultproperties
{
	DrawType=DT_StaticMesh
	bHidden=True
	bWorldGeometry=True
	bCollideActors=False
	bBlockActors=True
	bBlockPlayers=True
	bBlockZeroExtentTraces=False
	bBlockNonZeroExtentTraces=True
	bUseCylinderCollision=False
	bProjTarget=False
	bBlockKarma=False
	bAcceptsProjectors=False
	bShadowCast=False
	bStatic=False
	bNoDelete=False
	bCollideWorld=False
	Physics=PHYS_None
	RemoteRole=ROLE_None
}
