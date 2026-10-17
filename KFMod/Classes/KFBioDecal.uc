//=============================================================================
// The stock vomit splat, kept off physics props
//=============================================================================
class KFBioDecal extends BioDecal;

// Laid on the world only, never on a physics prop (see NetKActor.ShedDecal)
simulated function AttachProjector(optional float FadeInTime)
{
	Super.AttachProjector(FadeInTime);
	class'NetKActor'.static.ShedDecal(self);
}

defaultproperties
{
}
