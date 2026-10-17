//=============================================================================
// KFTBody - another cone of the tactical light (KFTLight), on the same
// place. The light keeps five:
//
//   Shade  the light on players, creatures and what they carry, laid on their
//          own skins and falling away with distance. It is the kind of
//          projector that is fixed to things, and the light fixes it each
//          frame to the bodies in its beam and to nothing else. (The kind the
//          renderer looks up for itself cannot be kept off the level's own
//          surfaces, and those have their light.)
//
//   ShadeX the same for a body whose skin is made of several textures: in the
//          colours the light's own picture has of it.
//
//   Sheen  the light on what can be seen through (plastic sheeting, glass,
//          a stain on a wall), laid on its own texture and by how solid that
//          is; SheenX the same in the light's own colour, for what is made of
//          several textures. Fixed each frame to those things and nothing
//          else, as Shade is to bodies.
//
//   Fill   the half of the light that is not weighed by the way a surface
//          faces it: this one the renderer does look up for itself, on the
//          level's surfaces and its models.
//=============================================================================
class KFTBody extends Projector;

// (not put on anything as it is made, nor on whatever touches it)
simulated event PostBeginPlay();
simulated event Touch(Actor Other);
simulated event Untouch(Actor Other);

// What it throws; and its cone, as wide as Wide degrees, sized so that the cone's tip is where the light is, Reach
// behind it. (The tip is behind a projector by half its picture's width over the tangent of half its angle.)
simulated function Fit(Material Wears, float Reach, int Wide, int Far)
{
	local int Across;

	ProjTexture = Wears;
	FOV = Wide;
	MaxTraceDistance = Far;
	Across = Wears.MaterialUSize();
	if (Across < 1)
		Across = 256;
	SetDrawScale(Reach * 2.0 * Tan(float(FOV) * Pi / 360.0) / float(Across));
}

simulated event Destroyed()
{
	DetachProjector(true);
	ProjTexture = Texture'KFTorchTex.KFTCookie';
	Super.Destroyed();
}

defaultproperties
{
     MaterialBlendingOp=PB_None
     FrameBufferBlendingOp=PB_Add
     ProjTexture=Texture'KFTorchTex.KFTCookie'
     FOV=100
     MaxTraceDistance=2600
     bProjectBSP=False
     bProjectTerrain=False
     bProjectStaticMesh=False
     bProjectParticles=False
     bProjectActor=False
     bClipBSP=False
     bProjectOnUnlit=True
     bGradient=True
     GradientTexture=Texture'KFTorchTex.KFTFall'
     bProjectOnBackfaces=False
     bProjectOnAlpha=True
     bStatic=False
     bHidden=False
     DrawType=DT_None
     RemoteRole=ROLE_None
     bGameRelevant=True
     LifeSpan=0.000000
}
