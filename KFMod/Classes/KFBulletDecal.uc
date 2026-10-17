class KFBulletDecal extends xScorch
	abstract;

#exec OBJ LOAD FILE=KFMaterials.utx

var() Array<Texture> Marks;

function PostBeginPlay()
{
    local Vector RX, RY, RZ;
    local Rotator R;

	if ( PhysicsVolume.bNoDecals )
	{
		Destroy();
		return;
	}
    if( RandomOrient )
    {
        R.Yaw = 0;
        R.Pitch = 0;
        R.Roll = Rand(65535);
        GetAxes(R,RX,RY,RZ);
        RX = RX >> Rotation;
        RY = RY >> Rotation;
        RZ = RZ >> Rotation;
        R = OrthoRotation(RX,RY,RZ);
        SetRotation(R);
    }
    SetLocation( Location - Vector(Rotation)*PushBack );
    Super(Projector).PostBeginPlay();

    Lifespan = FMax(0.5, LifeSpan + (Rand(4) - 2));

    if ( Level.bDropDetail )
		LifeSpan *= 0.5;
	// (attached once and left to the engine for its life, as stock scorch marks are: it used to detach and attach again
	// every frame through the moving-projector path, about 5 us a frame each, 70 to 90 at a time in a big wave)
	AbandonProjector(LifeSpan);
	Destroy();
}


simulated event PreBeginPlay()
{
  	Super.PreBeginPlay();

	if (Marks.Length < 1)
	{
		 if (ProjTexture == None)
		 {
			log ("KFBulletDecal:"$Self$" no ProjTexture", 'Warning');
			Destroy();
			return;
		 }
	}
	else
		ProjTexture = Marks[Rand(Marks.Length)];
}

// Laid on the world only, never on a physics prop (see NetKActor.ShedDecal)
simulated function AttachProjector(optional float FadeInTime)
{
	Super.AttachProjector(FadeInTime);
	class'NetKActor'.static.ShedDecal(self);
}

defaultproperties
{
    bGradient=false
    LifeSpan=8.000000
    DrawScale=0.130000
    MaterialBlendingOp=PB_none
    MaxTraceDistance=60
	bProjectBSP=true
	bProjectTerrain=true
	bProjectStaticMesh=true
    bNoDelete=false
	//bHidden=false
	bClipBSP=True
	bDetailAttachment=true
	bHardAttach=True
	bLightChanged=True
}
