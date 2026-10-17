class KFPlankRegrowEffect extends Emitter;

var() float HoldTime;	// how long the grown copy waits at full size for the plank itself to show (a client hears of it a ping late)

simulated function PreBeginPlay()
{
	local MeshEmitter M;
	local float GrowTime;

	Super.PreBeginPlay();

	M = MeshEmitter(Emitters[0]);
	GrowTime = class'KFBarricadePlank'.default.RegrowEffectDuration;
	if( Owner!=None )
	{
		SetLocation(Owner.Location);
		SetRotation(Owner.Rotation);
		if( Owner.StaticMesh!=None )
		{
			// the plank's own shape: its scale on each axis, grown to its draw scale
			M.StaticMesh = Owner.StaticMesh;
			M.StartSizeRange.X.Min = Owner.DrawScale3D.X;
			M.StartSizeRange.X.Max = Owner.DrawScale3D.X;
			M.StartSizeRange.Y.Min = Owner.DrawScale3D.Y;
			M.StartSizeRange.Y.Max = Owner.DrawScale3D.Y;
			M.StartSizeRange.Z.Min = Owner.DrawScale3D.Z;
			M.StartSizeRange.Z.Max = Owner.DrawScale3D.Z;
			M.SizeScale[1].RelativeSize = Owner.DrawScale;
			M.SizeScale[2].RelativeSize = Owner.DrawScale;
		}
		if( KFBarricadePlank(Owner)!=None )
			GrowTime = KFBarricadePlank(Owner).RegrowEffectDuration;
	}

	// fully grown when the plank's timer shows it, then held until it does
	M.LifetimeRange.Min = GrowTime + HoldTime;
	M.LifetimeRange.Max = GrowTime + HoldTime;
	M.SizeScale[1].RelativeTime = GrowTime / (GrowTime + HoldTime);
}

// gone the moment the plank itself shows
simulated function Tick( float DeltaTime )
{
	if( Owner==None || !Owner.bHidden )
		Destroy();
}

defaultproperties
{
	Begin Object Class=MeshEmitter Name=PlankRegrowMesh
		RespawnDeadParticles=False
		UseSizeScale=True
		UseRegularSizeScale=False
		AutomaticInitialSpawning=False
		CoordinateSystem=PTCS_Relative
		MaxParticles=1
		SpinCCWorCW=(X=0.000000)
		SizeScale(0)=(RelativeSize=0.000000)
		SizeScale(1)=(RelativeTime=0.440000,RelativeSize=1.000000)
		SizeScale(2)=(RelativeTime=1.000000,RelativeSize=1.000000)
		InitialParticlesPerSecond=9999999.000000
		LifetimeRange=(Min=1.800000,Max=1.800000)
	End Object
	Emitters(0)=MeshEmitter'KFMod.KFPlankRegrowEffect.PlankRegrowMesh'
	HoldTime=1.000000
	AutoDestroy=True
	bNoDelete=False
}
