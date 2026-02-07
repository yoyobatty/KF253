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
    //AbandonProjector(LifeSpan*Level.DecalStayScale);
    //Destroy();
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

function Tick(float DeltaTime)
{
	DetachProjector();
	AttachProjector();
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
	bDynamicAttach=True
	bDetailAttachment=true
	bHardAttach=True
	bLightChanged=True
}
