class KFPlankRegrowEffect extends Emitter;

simulated function PreBeginPlay()
{
	Super.PreBeginPlay();

	if( Owner!=None )
	{
		SetLocation(Owner.Location);
		SetRotation(Owner.Rotation);
		if( Owner.StaticMesh!=None )
		{
			MeshEmitter(Emitters[0]).StaticMesh = Owner.StaticMesh;
			MeshEmitter(Emitters[0]).SizeScale[1].RelativeSize = Owner.DrawScale;
		}
	}
}

defaultproperties
{
	Begin Object Class=MeshEmitter Name=PlankRegrowMesh
		RespawnDeadParticles=False
		UseSizeScale=True
		UseRegularSizeScale=False
		AutomaticInitialSpawning=True
		CoordinateSystem=PTCS_Relative
		MaxParticles=1
		SpinCCWorCW=(X=0.000000)
		SizeScale(0)=(RelativeSize=0.000000)
		SizeScale(1)=(RelativeTime=1.000000,RelativeSize=1.000000)
		InitialParticlesPerSecond=9999999.000000
		LifetimeRange=(Min=0.700000,Max=0.700000)
	End Object
	Emitters(0)=MeshEmitter'KFMod.KFPlankRegrowEffect.PlankRegrowMesh'
	AutoDestroy=True
	bNoDelete=False
}
