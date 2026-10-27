//=============================================================================
// Where a blast's own sound plays from once the rocket or grenade that made it is gone, so that walls, static meshes
// too, go on muffling it while it rings out.
//=============================================================================
class KFBlastSound extends Actor;

// Plays S where Maker is, as Maker.PlaySound(S,,Volume) would (nothing on a dedicated server).
simulated static function Play( Actor Maker, Sound S, float Volume )
{
	local KFBlastSound B;

	if( Maker==None || S==None || Maker.Level.NetMode==NM_DedicatedServer )
		return;
	B = Maker.Spawn(class'KFBlastSound',,, Maker.Location);
	if( B==None )
	{
		Maker.PlaySound(S,, Volume,, Maker.TransientSoundRadius);
		return;
	}
	B.LifeSpan = B.GetSoundDuration(S) + 0.5;
	B.PlaySound(S,, Volume,, Maker.TransientSoundRadius);
}

defaultproperties
{
	bHidden=True
	DrawType=DT_None
	bCollideActors=False
	bCollideWorld=False
	bBlockActors=False
	RemoteRole=ROLE_None
	LifeSpan=10.000000
	SoundOcclusion=OCCLUSION_StaticMeshes
}
