//=============================================================================
<<<<<<< HEAD
// © 2003 Matt 'SquirrelZero' Farber
=======
// ï¿½ 2003 Matt 'SquirrelZero' Farber
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
//=============================================================================
// "UT2k3 Ultimate Flashlight"
// I wrote this using _both_ a dynamic projector and a dynamic light, with the
// dynamic projector as the focal point and lightsource providing general 
// ambient illumination.  Either one by itself is pretty dull, but combine the 
// two and you've got yourself a really nice effect if done correctly.
//=============================================================================
class Effect_TacLightProjector extends DynamicProjector;

// add a light too, there seems to be a problem with the projector darkening terrain sometimes
var Effect_TacLightGlow TacLightGlow;
var Weapon ValidWeapon;

var Pawn LightPawn;
var bool bHasLight;
var WeaponAttachment AssignedAttach;

var byte LightRot[2];

<<<<<<< HEAD
=======
var KFPlayerController AssignedPC;
var bool bIsAssigned;

var vector WallHitLocation;

var()   float   ProjectorPullbackDist;

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
replication
{
	// relevant variables needed by the client
	reliable if (Role == ROLE_Authority)
		LightPawn,bHasLight;
	unreliable if( Role == ROLE_Authority && !bNetOwner && bHasLight )
		LightRot;
}

// setup the pawn and controller variables, spawn the dynamic light
simulated function PostBeginPlay()
{
	SetCollision(True, False, False);
	if (Owner != None)
	{
		LightPawn = Pawn(Owner);
		ValidWeapon = LightPawn.Weapon;
	}
	if( Level.NetMode==NM_DedicatedServer )
		Return;
	if( TacLightGlow==None )
		TacLightGlow = spawn(class'Effect_TacLightGlow');
}
<<<<<<< HEAD
=======
simulated function AddProjecting()
{
	bIsAssigned = True;
	AssignedPC.LightSources[AssignedPC.LightSources.Length] = Self;
}
simulated function RemoveProjecting()
{
	local int i,l;

	bIsAssigned = False;
	l = AssignedPC.LightSources.Length;
	for( i=0; i<l; i++ )
		if( AssignedPC.LightSources[i]==Self )
		{
			AssignedPC.LightSources.Remove(i,1);
			return;
		}
}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
simulated function Destroyed()
{
	Super.Destroyed();
	if( TacLightGlow!=None )
		TacLightGlow.Destroy();
	if( KFWeaponAttachment(AssignedAttach)!=None )
	{
		KFWeaponAttachment(AssignedAttach).TacBeamGone();
		AssignedAttach = None;
	}
<<<<<<< HEAD
=======
	if( bIsAssigned )
	{
		RemoveProjecting();
		AssignedPC = None;
	}
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

// updates the taclight projector and dynamic light positions
simulated function Tick(float DeltaTime)
{
	local vector StartTrace,EndTrace,X,HitLocation,HitNormal,AdjustedLocation;
	local float BeamLength;
	local rotator R;
<<<<<<< HEAD
=======
	local coords LightBonePosition;
	local KFWeapon KFWeap;
	local Actor HitActor;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	if( Level.NetMode==NM_DedicatedServer )
	{
		if( LightPawn==none || LightPawn.Weapon==None || LightPawn.Weapon!=ValidWeapon )
		{
			Destroy();
			return;
		}
		SetLocation(LightPawn.Location);
		if( !bHasLight || LightPawn.Controller==None )
			Return;
		LightRot[0] = LightPawn.Controller.Rotation.Yaw/256;
		LightRot[1] = LightPawn.Controller.Rotation.Pitch/256;
		Return;
	}
	if (TacLightGlow == None)
		return;

	if( Level.NetMode!=NM_Client && (LightPawn == none || LightPawn.Weapon==None || LightPawn.Weapon!=ValidWeapon) )
	{
		DetachProjector();
		Destroy();
		return;
	}

	// we're changing its location and rotation, so detach it
	DetachProjector();

	// fallback
	if( LightPawn==None || !bHasLight )
	{
		if (TacLightGlow != None)
			TacLightGlow.bDynamicLight = false;
		if( AssignedAttach!=None )
		{
			if( KFWeaponAttachment(AssignedAttach)!=None )
				KFWeaponAttachment(AssignedAttach).TacBeamGone();
			AssignedAttach = None;
		}
<<<<<<< HEAD
=======
		if( bIsAssigned )
			RemoveProjecting();
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		return;
	}

	if( Level.NetMode!=NM_Client || PlayerController(LightPawn.Controller)!=None )
	{
		if( PlayerController(LightPawn.Controller)==None || PlayerController(LightPawn.Controller).bBehindView || LightPawn.Weapon==None )
		{
			if( XPawn(LightPawn)!=None && XPawn(LightPawn).WeaponAttachment!=None )
				StartTrace = XPawn(LightPawn).WeaponAttachment.Location;
			else StartTrace = LightPawn.Location+LightPawn.EyePosition();
		}
<<<<<<< HEAD
		else StartTrace = LightPawn.Location+LightPawn.CalcDrawOffset(LightPawn.Weapon);
		R = LightPawn.Controller.Rotation;
=======
		else
        {
            KFWeap = KFWeapon(LightPawn.Weapon);

            LightBonePosition = KFWeap.GetBoneCoords('LightBone');
            StartTrace = LightBonePosition.Origin - KFWeap.Location;
        	StartTrace = StartTrace * 0.2;
        	StartTrace = StartTrace + LightBonePosition.XAxis * KFWeap.FirstPersonFlashlightOffset.X
                + LightBonePosition.YAxis * KFWeap.FirstPersonFlashlightOffset.Y
                + LightBonePosition.ZAxis * KFWeap.FirstPersonFlashlightOffset.Z;
        	StartTrace = KFWeap.Location + StartTrace;
        }

		if ( LightPawn.IsLocallyControlled() && PlayerController(LightPawn.Controller) != none && !PlayerController(LightPawn.Controller).bBehindView )
		{
			X = LightPawn.Weapon.GetBoneCoords('LightBone').XAxis;
			R = rotator(X);
		}
		else if ( XPawn(LightPawn) != none && XPawn(LightPawn).WeaponAttachment != none )
		{
			if ( DualiesAttachment(XPawn(LightPawn).WeaponAttachment) != none )
			{
				if ( DualiesAttachment(XPawn(LightPawn).WeaponAttachment).Mesh == DualiesAttachment(XPawn(LightPawn).WeaponAttachment).BrotherMesh )
				{
					X = DualiesAttachment(XPawn(LightPawn).WeaponAttachment).Brother.GetBoneCoords('FlashLight').XAxis;
					R = rotator(X);
				}
				else
				{
					X = XPawn(LightPawn).WeaponAttachment.GetBoneCoords('FlashLight').XAxis;
					R = rotator(X);
				}
			}
			else
			{
				X = XPawn(LightPawn).WeaponAttachment.GetBoneCoords('FlashLight').XAxis;
				R = rotator(X);
			}
		}
		else
		{
			R = LightPawn.Controller.Rotation;
			X = vector(R);
		}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		if( Level.NetMode!=NM_Client )
		{
			LightRot[0] = R.Yaw/256;
			LightRot[1] = R.Pitch/256;
		}
<<<<<<< HEAD
		X = vector(R);
=======
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	}
	else
	{
		if( XPawn(LightPawn)!=None && XPawn(LightPawn).WeaponAttachment!=None && (Level.TimeSeconds-LightPawn.LastRenderTime)<1 )
			StartTrace = XPawn(LightPawn).WeaponAttachment.Location;
		else StartTrace = LightPawn.Location+LightPawn.EyePosition();
<<<<<<< HEAD
=======

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
		R.Yaw = LightRot[0]*256;
		R.Pitch = LightRot[1]*256;
		X = vector(R);
	}

	// not too far out, we don't want a flashlight that can shine across the map
	EndTrace = StartTrace + 1800*X;

<<<<<<< HEAD
	if( Trace(HitLocation,HitNormal,EndTrace,StartTrace,true)==None )
		HitLocation = EndTrace;

=======
    HitActor = Trace(HitLocation,HitNormal,EndTrace,StartTrace,true,vect(2,2,2));

	if( HitActor == none )
		HitLocation = EndTrace;

	WallHitLocation = HitLocation;

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	// find out how far the first hit was
	BeamLength = VSize(StartTrace-HitLocation);

	// this makes a neat focus effect when you get close to a wall
	if (BeamLength <= 90)
		SetDrawScale(FMax(0.02,(BeamLength/90))*Default.DrawScale);
	else SetDrawScale(Default.DrawScale);
<<<<<<< HEAD
	SetLocation(StartTrace);
=======

	FOV = Lerp((BeamLength / 1800.0),(default.FOV * 0.6),default.FOV);

    // Don't let the projector penetrate the wall
    if (BeamLength <= ProjectorPullbackDist)
    {
        SetLocation(StartTrace - X * (ProjectorPullbackDist - BeamLength));
    }
    else
    {
        SetLocation(StartTrace);
    }

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	SetRotation(R);

	// reattach it
	AttachProjector();

	// turns the dynamic light on if it's off
	if (!TacLightGlow.bDynamicLight)
<<<<<<< HEAD
		TacLightGlow.bDynamicLight = true;
=======
		TacLightGlow.bDynamicLight = True;
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92

	// again, neat focus effect up close, starts earlier than the dynamic projector
	if (BeamLength <= 100)
	{
<<<<<<< HEAD
		TacLightGlow.LightBrightness = TacLightGlow.Default.LightBrightness * (1.0 + (1.0 - (BeamLength/100)));
		TaclightGlow.LightRadius = TacLightGlow.Default.LightRadius * FMax(0.3,(BeamLength/100));
=======
		TacLightGlow.LightBrightness = TacLightGlow.Default.LightBrightness;
		TacLightGlow.LightRadius = Lerp((BeamLength / 100.0),0.0,(TacLightGlow.Default.LightRadius * 1.25));
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	} // else we scale its radius and brightness depending on distance from the material
	else
	{
		// fades the lightsource out as it moves farther away
<<<<<<< HEAD
		if (BeamLength >= 1300)
			TacLightGlow.LightBrightness = TacLightGlow.Default.LightBrightness * ((1800-BeamLength)/500);
		else // else normal brightness
			TacLightGlow.LightBrightness = TacLightGlow.Default.LightBrightness;

		// this makes the light act more like a spotlight, resizing depending on distance
		TacLightGlow.LightRadius = TacLightGlow.Default.LightRadius + (4.5 * (BeamLength/1900));
	}
	AdjustedLocation = HitLocation;
	AdjustedLocation.Z += 0.5 * LightPawn.CollisionHeight;
	TacLightGlow.SetLocation(AdjustedLocation - 50*X );
=======
		TacLightGlow.LightBrightness = TacLightGlow.Default.LightBrightness * (1.0 - (BeamLength / 1800.0));

		// this makes the light act more like a spotlight, resizing depending on distance
		TacLightGlow.LightRadius = FMin((TacLightGlow.Default.LightRadius * 4),Lerp((BeamLength / 900.0),TacLightGlow.Default.LightRadius,TacLightGlow.Default.LightRadius * 4));
	}
	AdjustedLocation = HitLocation;

	// Pull back a bit so the light doesn't go through the terrain
	if( HitActor != none && HitActor.IsA('TerrainInfo') )
	{
	   TacLightGlow.SetLocation(AdjustedLocation - 50 * X );
	}
	else
	{
	   	//TacLightGlow.SetLocation(AdjustedLocation);
		if(PlayerController(LightPawn.Controller) != none){
	   		TacLightGlow.SetLocation(HitLocation-vector(PlayerController(LightPawn.Controller).GetViewRotation())*64);
    		TacLightGlow.SetRotation(rotator(HitLocation-StartTrace));
		}
	}

>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
	if( XPawn(LightPawn)!=None && XPawn(LightPawn).WeaponAttachment!=AssignedAttach )
	{
		if( KFWeaponAttachment(AssignedAttach)!=None )
			KFWeaponAttachment(AssignedAttach).TacBeamGone();
		AssignedAttach = XPawn(LightPawn).WeaponAttachment;
	}
	if( KFWeaponAttachment(AssignedAttach)!=None )
		KFWeaponAttachment(AssignedAttach).UpdateTacBeam(BeamLength);
<<<<<<< HEAD
=======
	if( !bIsAssigned && AssignedPC!=None )
		AddProjecting();
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}

defaultproperties
{
<<<<<<< HEAD
	MaterialBlendingOp=PB_Modulate
	FrameBufferBlendingOp=PB_Add
	ProjTexture=Texture'KillingFloorWeapons.Dualies.LightCircle'
	FOV=1
	MaxTraceDistance=1600
	bClipBSP=True
	bProjectOnUnlit=True
	bGradient=True
	bProjectOnAlpha=True
	bProjectOnParallelBSP=True
	bNoProjectOnOwner=True
	DrawType=DT_None
	bLightChanged=True
	bHidden=False
	bSkipActorPropertyReplication=True
	RemoteRole=ROLE_SimulatedProxy
	DrawScale=0.610000
=======
     ProjectorPullbackDist=25.000000
     MaterialBlendingOp=PB_Modulate
     FrameBufferBlendingOp=PB_Add
     ProjTexture=Texture'KillingFloorWeapons.Dualies.LightCircle'
     FOV=50
     MaxTraceDistance=1600
     bClipBSP=True
     bProjectOnUnlit=True
     bGradient=True
     bProjectOnAlpha=True
	 bProjectOnBackfaces = false
     bProjectOnParallelBSP=True
     bNoProjectOnOwner=True
     DrawType=DT_None
     bLightChanged=True
     bHidden=False
     bSkipActorPropertyReplication=True
     RemoteRole=ROLE_SimulatedProxy
     DrawScale=0.300000
	 bNotOnDedServer=False
>>>>>>> 5492ba9971464e8a4fa56f166d61815486915c92
}
