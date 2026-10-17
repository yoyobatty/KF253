class ShotgunDecal extends BulletDecal;

// Laid on the world only, never on a physics prop (see NetKActor.ShedDecal)
simulated function AttachProjector(optional float FadeInTime)
{
	Super.AttachProjector(FadeInTime);
	class'NetKActor'.static.ShedDecal(self);
}

defaultproperties
{
     CullDistance=0.000000
     LifeSpan=13.000000
     DrawScale=0.290000
}
