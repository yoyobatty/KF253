//=============================================================================
// The stock blood splat a blood jet leaves, kept off physics props
//=============================================================================
class KFBloodSplat extends BloodSplatter;

// Laid on the world only, never on a physics prop (see NetKActor.ShedDecal)
simulated function AttachProjector(optional float FadeInTime)
{
	Super.AttachProjector(FadeInTime);
	class'NetKActor'.static.ShedDecal(self);
}

defaultproperties
{
}
