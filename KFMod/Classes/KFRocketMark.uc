//=============================================================================
// The stock blast mark, kept off physics props
//=============================================================================
class KFRocketMark extends RocketMark;

// Laid on the world only, never on a physics prop (see NetKActor.ShedDecal)
simulated function AttachProjector(optional float FadeInTime)
{
	Super.AttachProjector(FadeInTime);
	class'NetKActor'.static.ShedDecal(self);
}

defaultproperties
{
}
